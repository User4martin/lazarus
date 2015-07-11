unit FpImgReaderMacho;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, contnrs,
  macho, FpImgReaderMachoFile, FpImgReaderBase, LazLoggerBase,
  DbgIntfBaseTypes,
  lazfglhash,
  fpDbgSymTable;

type

  { TDbgMachoDataSource }

  TDbgMachoDataSource = class(TDbgImageReader)
  private
    fSource     : TDbgFileLoader;
    FSections: TStringList;
    fSubFiles: TStringList;
    fAddressMapList: TDbgAddressMapList;
    fOwnSource  : Boolean;
    fFile       : TMachoFile;
    hasSymTable : Boolean;
    StabsCmd    : symtab_command;
    fileRead    : Boolean;
    function GetSectionInfo(const SectionName: AnsiString; var Size: int64): Boolean;
    function GetSectionData(const SectionName: AnsiString; Offset, {%H-}Size: Int64; var Buf: array of byte): Int64;
    procedure ParseMainAppleDwarfDataMap;
    procedure ParseSubAppleDwarfDataMap(ADebugMap: TObject);
  protected
    procedure ReadFile;
    function GetSubFiles: TStrings; override;
    function GetAddressMapList: TDbgAddressMapList; override;
    function GetSymTableSectionInfo({%H-}StabStr: Boolean; var {%H-}SectionOffset, {%H-}SectionSize: Int64): Boolean;
    function GetSectionIndex(const SectionName: AnsiString): Integer;

    function GetSection(const AName: String): PDbgImageSection; override;
  public
    class function isValid(ASource: TDbgFileLoader): Boolean; override;
    class function UserName: AnsiString; override;
    class procedure LoadSubFiles(ASubFiles: TStrings; ALoaderList: TFPObjectList);
    procedure ParseSymbolTable(AfpSymbolInfo: TfpSymbolList); override;
  public
    constructor Create(ASource: TDbgFileLoader; ADebugMap: TObject; OwnSource: Boolean); override;
    destructor Destroy; override;
  end;

implementation

uses
  FpDbgLoader;

type
  PnlistArray = ^TnlistArray;
  TnlistArray = array[0..maxSmallint] of nlist;

const
  // Symbol-map section name
  _symbol        = '.symbols';
  _symbolstrings = '.symbolsstrings';

type
  TDebugTableState = (dtsDir, dtsSource, dtsObjectFile, dtsProc, dtsProcLen, dtsProcEnd, dtsEnd);
  TDebugTableEntry = record
    Dir: string;
    SourceFile: string;
    ObjectFile: string;
    ObjFileAge: longint;
    Offset: TDBGPtr;
  end;

  { TAppleDwarfDebugMap }

  TAppleDwarfDebugMap = class(TObject)
  private
    FAddressMap: TDbgAddressMapList;
    FDir: string;
    FGlobalList: TDbgAddressMapHashList;
    FObjectFile: string;
    FObjFileAge: longint;
    FOffset: TDBGPtr;
    FSourceFile: string;
  public
    constructor create;
    destructor destroy; override;
    property Offset: TDBGPtr read FOffset write FOffset;
    property Dir: string read FDir write FDir;
    property ObjectFile: string read FObjectFile write FObjectFile;
    property SourceFile: string read FSourceFile write FSourceFile;
    property ObjFileAge: longint read FObjFileAge write FObjFileAge;
    // This list contains the locations for all symbols in the executable,
    // parsed from the 'stabs'-debuginfo in the executable.
    // This property is only available in the debug-map for the main
    // executable.
    property GlobalList: TDbgAddressMapHashList read FGlobalList;
    // This list maps addresses in an object-file to the addresses
    // in the main executable.
    // This property is only available in the debug-map for a specific
    // object-file.
    property AddressMap: TDbgAddressMapList read FAddressMap;
  end;

function isValidMachoStream(ASource: TDbgFileLoader): Boolean;
var
  header  : mach_header;
begin
  try
    Result := Assigned(ASource);
    if not Result then Exit;
    Result := ASource.Read(0, sizeof(header), @header) = sizeof(header);
    if not Result then Exit;
    Result := (header.magic = MH_CIGAM) or (header.magic = MH_MAGIC) or
              (header.magic = MH_CIGAM_64) or (header.magic = MH_MAGIC_64);
  except
    Result := false;
  end;
end;

function FixMachoName(const macsectionname: String): String;
begin
  if Copy(macsectionName, 1, 2) = '__' then
    Result:= '.'+Copy(macsectionName, 3, length(macsectionName)-2)
  else
    Result := macsectionname;
end;

constructor TAppleDwarfDebugMap.create;
begin
  FGlobalList := TDbgAddressMapHashList.Create;
  FAddressMap := TDbgAddressMapList.Create;
end;

destructor TAppleDwarfDebugMap.destroy;
begin
  FAddressMap.Free;
  FGlobalList.Free;
  inherited destroy;
end;

{ TDbgMachoDataSource }

class function TDbgMachoDataSource.isValid(ASource: TDbgFileLoader): Boolean;
begin
  Result := isValidMachoStream(ASource);
end;

class function TDbgMachoDataSource.UserName: AnsiString;
begin
  Result:='mach-o file';
end;

class procedure TDbgMachoDataSource.LoadSubFiles(ASubFiles: TStrings; ALoaderList: TFPObjectList);
var
  DwarfDebugMap: TAppleDwarfDebugMap;
  Loader: TDbgImageLoader;
  i: Integer;
begin
  if assigned(ASubFiles) then
    begin
    for i := 0 to ASubFiles.Count -1 do
      begin
      if (ASubFiles.Objects[i] is TAppleDwarfDebugMap) and FileExists(ASubFiles[i]) then
        begin
        DwarfDebugMap:=TAppleDwarfDebugMap(ASubFiles.Objects[i]);
        if FileAge(ASubFiles[i]) <> DwarfDebugMap.ObjFileAge then
          debugln(Format('The timestamp of the object-file "%s" does not correspond to the timestamp (%s) stored inside the executable. The debug-info in this file is not loaded.', [DwarfDebugMap.ObjectFile, DateTimeToStr(FileDatetoDateTime(DwarfDebugMap.ObjFileAge))]))
        else
          begin
          Loader := TDbgImageLoader.Create(DwarfDebugMap.ObjectFile, DwarfDebugMap);
          ALoaderList.Add(Loader);
          end;
        end
      else
        DebugLn('File with debug-info "'+DwarfDebugMap.ObjectFile+'" does not exist. This could lead to missing debug-information.');
      end;
    end;
end;

procedure TDbgMachoDataSource.ParseSymbolTable(AfpSymbolInfo: TfpSymbolList);
var
  p: PDbgImageSection;
  ps: PDbgImageSection;
  SymbolArr: PnlistArray;
  SymbolStr: pointer;
  i: integer;
  SymbolCount: integer;
begin
  p := Section[_symbol];
  ps := Section[_symbolstrings];
  if assigned(p) and assigned(ps) then
  begin
    SymbolArr:=PDbgImageSectionEx(p)^.Sect.RawData;
    SymbolStr:=PDbgImageSectionEx(ps)^.Sect.RawData;
    SymbolCount := PDbgImageSectionEx(p)^.Sect.Size div sizeof(nlist);
    for i := 0 to SymbolCount-1 do
    begin
      if (SymbolArr^[i].n_type and $e0)<>0 then
        // This is a stabs-entry. Ignore.
        Continue;
      if (SymbolArr^[i].n_type and $0e)=$e then
      begin
        // Section-index is ignored for now...
        AfpSymbolInfo.AddObject(pchar(SymbolStr+SymbolArr^[i].n_un.n_strx), TObject(PtrUInt(SymbolArr^[i].n_value)));
      end
    end;
  end;

end;

procedure TDbgMachoDataSource.ReadFile;
var
  i : Integer;
begin
  if Assigned(fFile) then fFile.Free;
  fFile:=TMachOFile.Create;
  fFile.LoadFromFile(fSource);
  for i := 0 to fFile.header.ncmds - 1 do begin
    hasSymTable := fFile.commands[i]^.cmd = LC_SYMTAB;
    if hasSymTable then begin
      StabsCmd := psymtab_command(fFile.commands[i])^;
      Break;
    end;
  end;
  SetImage64Bit((fFile.header.cputype and CPU_ARCH_ABI64)=CPU_ARCH_ABI64);
  SetUUID(fFile.UUID);
  fileRead := true;
end;

function TDbgMachoDataSource.GetSubFiles: TStrings;
begin
  if not assigned(fSubFiles) then
    begin
    fSubFiles:=TStringList.Create;
    fSubFiles.OwnsObjects:=true;
    end;
  Result:=fSubFiles;
end;

function TDbgMachoDataSource.GetAddressMapList: TDbgAddressMapList;
begin
  if not assigned(fAddressMapList) then
    begin
    fAddressMapList:=TDbgAddressMapList.Create;
    end;
  Result:=fAddressMapList;
end;

function TDbgMachoDataSource.GetSymTableSectionInfo(StabStr: Boolean;
  var SectionOffset, SectionSize: Int64): Boolean;
begin
  Result := hasSymTable;
  if not Result then Exit;
  if StabStr then begin
    SectionOffset := StabsCmd.stroff;
    SectionSize := StabsCmd.strsize;
  end else begin
    SectionOffset := StabsCmd.symoff;
    SectionSize := Int64(StabsCmd.nsyms * sizeof(nlist));
  end;
end;

function TDbgMachoDataSource.GetSectionIndex(const SectionName: AnsiString): Integer;
var
  i     : Integer;
  Name  : AnsiString;
begin
  //todo: hash-table
  for i := 0 to fFile.Sections.Count - 1 do begin
    with TMachoSection(fFile.sections[i]) do
      if is32
        then Name := FixMachoName(sec32.sectname)
        else Name := FixMachoName(sec64.sectname);
    if Name = SectionName then begin
      Result := i;
      Exit;
    end;
  end;
  Result := -1;
end;

function TDbgMachoDataSource.GetSection(const AName: String): PDbgImageSection;
var
  i: Integer;
  ex: PDbgImageSectionEx;
begin
  Result := nil;
  i := FSections.IndexOf(AName);
  if i < 0 then
    exit;
  ex := PDbgImageSectionEx(FSections.Objects[i]);
  Result := @ex^.Sect;
  if ex^.Loaded then
    exit;
  ex^.Loaded  := True;
  fSource.LoadMemory(ex^.Offs, Result^.Size, Result^.RawData);
end;

constructor TDbgMachoDataSource.Create(ASource: TDbgFileLoader; ADebugMap: TObject; OwnSource: Boolean);
const
  SymbolsSectionName : array [Boolean] of AnsiString = (_symbol, _symbolstrings);
var
  p: PDbgImageSectionEx;
  fs: TMachOsection;
  i: Integer;
  Name: String;
  soffset: int64;
  ssize: int64;
begin
  fSource := ASource;
  fOwnSource := OwnSource;

  ReadFile;

  FSections := TStringList.Create;
  FSections.Sorted := True;
  FSections.Duplicates := dupAccept;
  FSections.CaseSensitive := False;

  for i := 0 to fFile.sections.Count - 1 do begin
    fs := TMachoSection(fFile.sections[i]);
    New(p);

    if fs.is32 then begin
      Name := FixMachoName(fs.sec32.sectname);
      P^.Offs := fs.sec32.offset;
      p^.Sect.Size := fs.sec32.size;
    end
    else begin
      Name := FixMachoName(fs.sec64.sectname);
      P^.Offs := fs.sec64.offset;
      p^.Sect.Size := fs.sec64.size;
    end;
DebugLn(Name);

    p^.Sect.VirtualAddress := 0; // Todo?
    p^.Loaded := False;
    FSections.AddObject(Name, TObject(p));
  end;

  if GetSymTableSectionInfo(false, soffset, ssize) then begin
    new(p);
    p^.Offs:=soffset;
    p^.Sect.Size:=ssize;
    p^.Sect.VirtualAddress:=0;
    p^.Loaded:=false;
    FSections.AddObject(SymbolsSectionName[false], TObject(p));
  end;

  if GetSymTableSectionInfo(true, soffset, ssize) then begin
    new(p);
    p^.Offs:=soffset;
    p^.Sect.Size:=ssize;
    p^.Sect.VirtualAddress:=0;
    p^.Loaded:=false;
    FSections.AddObject(SymbolsSectionName[true], TObject(p));
  end;

  if assigned(ADebugMap) then
    ParseSubAppleDwarfDataMap(ADebugMap)
  else
    ParseMainAppleDwarfDataMap;

  inherited Create(ASource, ADebugMap, OwnSource);
end;

destructor TDbgMachoDataSource.Destroy;
begin
  if assigned(fSubFiles) then
    fSubFiles.Free;
  if assigned(fAddressMapList) then
    fAddressMapList.Free;
  if Assigned(fFile) then fFile.Free;
  if fOwnSource then fSource.Free;
  while FSections.Count > 0 do begin
    Freemem(FSections.Objects[0]);
    FSections.Delete(0);
  end;
  FreeAndNil(FSections);
  inherited Destroy;
end;

{function TDbgMachoDataSource.SectionsCount: Integer;
begin
  if not Assigned(fFile) then ReadFile;
  Result := fFile.Sections.Count;
  if isStabs then inc(Result, 2);
end;

function TDbgMachoDataSource.GetSection(Index: Integer; var Name: AnsiString; var Size: Int64): Boolean;
var
  cnt   : Integer;
  sstr  : Boolean;
const
  StabSectionName : array [Boolean] of AnsiString = (_stab, _stabstr);
begin
  if not Assigned(fFile) then ReadFile;
  cnt := fFile.Sections.Count;
  if isStabs then inc(cnt, 2);
  Result := (Index >= 0) and (Index < cnt);
  if not Result then Exit;

  if Index < fFile.Sections.Count then begin
    with TMachoSection(fFile.sections[index]) do
      if is32 then begin
        Name := FixMachoName(sec32.sectname);
        Size := sec32.size;
      end else begin
        Name := FixMachoName(sec64.sectname);
        Size := sec64.size;
      end;
  end else begin
    sstr := Index = cnt - 1;
    Name := StabSectionName[sstr];
    Result := GetStabSectionInfo(sstr, Size);
  end;
end;

function TDbgMachoDataSource.GetSectionData(index: Integer; outStream: TStream): Boolean;
var
  ofs : Int64;
  sz  : Int64;
begin
  //todo: method will be removed
  if not Assigned(outStream) then begin
    Result := false;
    Exit;
  end;
  if not Assigned(fFile) then ReadFile;
  Result := (Index >= 0) and (Index < fFile.Sections.Count);
  if not Result then Exit;

  with TMachOsection(fFile.sections[index]) do begin
    if is32 then begin
      ofs := sec32.offset;
      sz := sec32.size;
    end else begin
      ofs := sec64.offset;
      sz := sec64.size;
    end;
  end;
  if ofs > 0 then begin
    fSource.Position:=ofs;
    outStream.CopyFrom(fSource, sz);
  end;
end;}

function TDbgMachoDataSource.GetSectionInfo(const SectionName: AnsiString; var Size: int64): Boolean;
var
  idx     : integer;
  symtablestr : Boolean;
  dummy   : int64;
begin
  if not fileRead then ReadFile;

  symtablestr := (SectionName = _symbolstrings);
  if symtablestr or (SectionName = _symbol) then
    Result := GetSymTableSectionInfo(symtablestr, dummy, Size)
  else begin
    idx := GetSectionIndex(SectionName);
    Result := idx >= 0;
    if not Result then Exit;

    with TMachOsection(fFile.sections[idx]) do
      if is32
        then Size := sec32.size
        else Size := sec64.size;
  end;
end;

function TDbgMachoDataSource.GetSectionData(const SectionName: AnsiString; Offset, Size: Int64; var Buf: array of byte): Int64;
var
  idx     : Integer;
  sofs    : int64;
  ssize   : int64;
  symstr : Boolean;
  sz      : Int64;
  s       : TMachOsection;
begin
  if not fileRead then ReadFile;

  Result := 0;
  symstr := SectionName = _symbolstrings;
  if symstr or (SectionName = _symbol)  then begin
    if not GetSymTableSectionInfo(symstr, sofs, ssize) then
      Exit;
  end else begin
    idx := GetSectionIndex(SectionName);
    s := TMachOsection(fFile.sections[idx]);
    if s.is32 then begin
      ssize := s.sec32.size;
      sofs := s.sec32.offset;
    end else begin
      sofs := s.sec64.offset;
      ssize := s.sec64.size;
    end;
  end;

  sz := ssize - Offset;
  if sz < 0 then Exit;

  //fSource.Position := sofs + Offset;
  //Result := fSource.Read(Buf[0], sz);
  Result := fSource.Read(sofs + Offset, sz, @Buf[0]);
end;

procedure TDbgMachoDataSource.ParseMainAppleDwarfDataMap;
var
  p: PDbgImageSection;
  ps: PDbgImageSection;
  SymbolArr: PnlistArray;
  SymbolStr: pointer;
  i: integer;
  SymbolCount: integer;
  State: TDebugTableState;
  AddressMap: TDbgAddressMap;
  ProcName: string;
  DwarfDebugMap: TAppleDwarfDebugMap;
begin
  DwarfDebugMap:=nil;
  p := Section[_symbol];
  ps := Section[_symbolstrings];
  if assigned(p) and assigned(ps) then
  begin
    SymbolArr:=PDbgImageSectionEx(p)^.Sect.RawData;
    SymbolStr:=PDbgImageSectionEx(ps)^.Sect.RawData;
    SymbolCount := PDbgImageSectionEx(p)^.Sect.Size div sizeof(nlist);
    state := dtsEnd;
    for i := 0 to SymbolCount-1 do
    begin
      case state of
        dtsEnd:
          begin
            if SymbolArr^[i].n_type = N_SO then
            begin
              if assigned(DwarfDebugMap) then
                DwarfDebugMap.Free;
              DwarfDebugMap := TAppleDwarfDebugMap.Create;
              DwarfDebugMap.Dir := pchar(SymbolStr+SymbolArr^[i].n_un.n_strx);
              state := dtsDir;
            end;
          end;
        dtsDir:
          begin
            if SymbolArr^[i].n_type = N_SO then
            begin
              DwarfDebugMap.SourceFile:=pchar(SymbolStr+SymbolArr^[i].n_un.n_strx);
              inc(state);
            end
            else
              state := dtsEnd;
          end;
        dtsSource:
          begin
            if SymbolArr^[i].n_type = N_OSO then
            begin
              DwarfDebugMap.ObjectFile:=pchar(SymbolStr+SymbolArr^[i].n_un.n_strx);
              DwarfDebugMap.ObjFileAge:=SymbolArr^[i].n_value;
              inc(state);
            end;
          end;
        dtsObjectFile:
          begin
            if (SymbolArr^[i].n_type = N_BNSYM) then
            begin
              inc(state);
            end
            else if (SymbolArr^[i].n_type = N_STSYM) then
            begin
              AddressMap.NewAddr:=SymbolArr^[i].n_value;
              AddressMap.OrgAddr:=0;
              AddressMap.Length:=0;
              DwarfDebugMap.GlobalList.Add(pchar(SymbolStr+SymbolArr^[i].n_un.n_strx), AddressMap);
            end
            else if (SymbolArr^[i].n_type = N_SO) and (SymbolArr^[i].n_sect=1) then
            begin
              state := dtsEnd;
              SubFiles.AddObject(DwarfDebugMap.ObjectFile, DwarfDebugMap);
              DwarfDebugMap:=nil;
            end;
          end;
        dtsProc:
          begin
            if (SymbolArr^[i].n_type = N_FUN) and (SymbolArr^[i].n_sect=1) then
            begin
              AddressMap.NewAddr:=SymbolArr^[i].n_value;
              ProcName:=pchar(SymbolStr+SymbolArr^[i].n_un.n_strx);
              inc(state);
            end;
          end;
        dtsProcLen:
          begin
            if (SymbolArr^[i].n_type = N_FUN) and (SymbolArr^[i].n_sect=0) then
            begin
              AddressMap.Length:=SymbolArr^[i].n_value;
              inc(state);
            end;
          end;
        dtsProcEnd:
          begin
            if (SymbolArr^[i].n_type = N_ENSYM) and (SymbolArr^[i].n_sect=1) then
            begin
              DwarfDebugMap.GlobalList.Add(ProcName, AddressMap);
              state := dtsObjectFile;
            end;
          end;
      end;
    end;
  end;
end;

procedure TDbgMachoDataSource.ParseSubAppleDwarfDataMap(ADebugMap: TObject);
var
  p: PDbgImageSection;
  ps: PDbgImageSection;
  SymbolArr: PnlistArray;
  SymbolStr: pointer;
  i: integer;
  SymbolCount: integer;
  MainDwarfDebugMap: TAppleDwarfDebugMap;
  ind: THTCustomNode;
  AddressMap: TDbgAddressMap;
  s: string;
begin
  MainDwarfDebugMap:=TAppleDwarfDebugMap(ADebugMap);
  p := Section[_symbol];
  ps := Section[_symbolstrings];
  if assigned(p) and assigned(ps) then
  begin
    SymbolArr:=PDbgImageSectionEx(p)^.Sect.RawData;
    SymbolStr:=PDbgImageSectionEx(ps)^.Sect.RawData;
    SymbolCount := PDbgImageSectionEx(p)^.Sect.Size div sizeof(nlist);
    for i := 0 to SymbolCount-1 do
    begin
      if SymbolArr^[i].n_type = N_SECT then
      begin
        s := pchar(SymbolStr+SymbolArr^[i].n_un.n_strx);
        ind := MainDwarfDebugMap.GlobalList.Find(s);
        if assigned(ind) then
          begin
            AddressMap:=MainDwarfDebugMap.GlobalList.Items[s];
            AddressMap.OrgAddr:=SymbolArr^[i].n_value;
            AddressMapList.Add(AddressMap);
          end;
      end;
      if SymbolArr^[i].n_type = N_SECT+N_EXT then
      begin
        s := pchar(SymbolStr+SymbolArr^[i].n_un.n_strx);
        ind := MainDwarfDebugMap.GlobalList.Find(s);
        if assigned(ind) then
          begin
            AddressMap:=MainDwarfDebugMap.GlobalList.Items[s];
            AddressMap.OrgAddr:=SymbolArr^[i].n_value;
            AddressMapList.Add(AddressMap);
          end;
      end;
    end;
  end;
end;

initialization
  RegisterImageReaderClass( TDbgMachoDataSource );

end.

