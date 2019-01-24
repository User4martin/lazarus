unit FpImgReaderBase;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface
{$ifdef CD_Cocoa}{$DEFINE MacOS}{$ENDIF}
{$IFDEF Darwin}{$DEFINE MacOS}{$ENDIF}

uses
  {$ifdef windows}
  Windows, // After LCLType
  {$endif}
  fgl, lazfglhash,
  fpDbgSymTable,
  Classes, SysUtils, LazUTF8Classes, contnrs;

type
  TDbgImageSection = record
    RawData: Pointer;
    Size: QWord;
    VirtualAddress: QWord;
  end;
  PDbgImageSection = ^TDbgImageSection;

  TDbgImageSectionEx = record
    Sect: TDbgImageSection;
    Offs: QWord;
    Loaded: Boolean;
  end;
  PDbgImageSectionEx = ^TDbgImageSectionEx;

type
  TDbgAddressMap = record
    OrgAddr: QWord;
    Length: QWord;
    NewAddr: QWord;
    class operator =(r1,r2: TDbgAddressMap) : boolean;
  end;
  PDbgAddressMap = ^TDbgAddressMap;
  TDbgAddressMapList = specialize TFPGList<TDbgAddressMap>;

  { TDbgAddressMapHashList }

  TDbgAddressMapHashList = class(specialize TLazFPGHashTable<TDbgAddressMap>)
  public
    function ItemFromNode(ANode: THTCustomNode): TDbgAddressMap;
    function ItemPointerFromNode(ANode: THTCustomNode): PDbgAddressMap;
  end;

  { TDbgAddressMapPointerHashList }

  TDbgAddressMapPointerHashList = class(specialize TLazFPGHashTable<PDbgAddressMap>)
  public
    function ItemPointerFromNode(ANode: THTCustomNode): PDbgAddressMap;
  end;

  { TDbgFileLoader }
  {$ifdef windows}
    {$define USE_WIN_FILE_MAPPING}
  {$endif}

  TDbgFileLoader = class(TObject)
  private
    {$ifdef USE_WIN_FILE_MAPPING}
    FFileHandle: THandle;
    FMapHandle: THandle;
    FModulePtr: Pointer;
    {$else}
    FFileName: String;
    FStream: TStream;
    FList: TList;
    {$endif}
  public
    constructor Create(AFileName: String);
    {$ifdef USE_WIN_FILE_MAPPING}
    constructor Create(AFileHandle: THandle);
    {$endif}
    destructor Destroy; override;
    procedure Close;
    function  Read(AOffset, ASize: QWord; AMem: Pointer): QWord;
    function  LoadMemory(AOffset, ASize: QWord; out AMem: Pointer): QWord;
    procedure UnloadMemory({%H-}AMem: Pointer);
  end;

  { TDbgImageReader }

  TDbgImageReader = class(TObject) // executable parser
  private
    FImage64Bit: Boolean;
    FImageBase: QWord;
    FUUID: TGuid;
  protected
    function GetSubFiles: TStrings; virtual;
    function GetAddressMapList: TDbgAddressMapList; virtual;
    function GetSection(const AName: String): PDbgImageSection; virtual; abstract;
    procedure SetUUID(AGuid: TGuid);
    procedure SetImageBase(ABase: QWord);
    procedure SetImage64Bit(AValue: Boolean);
  public
    class function isValid(ASource: TDbgFileLoader): Boolean; virtual; abstract;
    class function UserName: AnsiString; virtual; abstract;
    procedure ParseSymbolTable(AFpSymbolInfo: TfpSymbolList); virtual;
    constructor Create({%H-}ASource: TDbgFileLoader; {%H-}ADebugMap: TObject; OwnSource: Boolean); virtual;
    procedure AddSubFilesToLoaderList(ALoaderList: TObject; PrimaryLoader: TObject); virtual;

    property ImageBase: QWord read FImageBase;
    Property Image64Bit: Boolean read FImage64Bit;
    property UUID: TGuid read FUUID;
    property Section[const AName: String]: PDbgImageSection read GetSection;
    property SubFiles: TStrings read GetSubFiles;
    property AddressMapList: TDbgAddressMapList read GetAddressMapList;
  end;
  TDbgImageReaderClass = class of TDbgImageReader;

function GetImageReader(ASource: TDbgFileLoader; ADebugMap: TObject; OwnSource: Boolean): TDbgImageReader; overload;
procedure RegisterImageReaderClass(DataSource: TDbgImageReaderClass);

implementation

var
  RegisteredImageReaderClasses  : TFPList;

{ TDbgAddressMapPointerHashList }

function TDbgAddressMapPointerHashList.ItemPointerFromNode(ANode: THTCustomNode
  ): PDbgAddressMap;
begin
  Result := THTGNode(ANode).Data;
end;

{ TDbgAddressMapHashList }

function TDbgAddressMapHashList.ItemFromNode(ANode: THTCustomNode
 ): TDbgAddressMap;
begin
  Result := THTGNode(ANode).Data;
end;

function TDbgAddressMapHashList.ItemPointerFromNode(ANode: THTCustomNode
  ): PDbgAddressMap;
begin
  Result := @THTGNode(ANode).Data;
end;

 class operator TDbgAddressMap.=(r1,r2: TDbgAddressMap) : boolean;
 begin
   result := (r1.OrgAddr=r2.OrgAddr) and (r1.Length=r2.Length) and (r1.NewAddr=r2.NewAddr);
 end;

function GetImageReader(ASource: TDbgFileLoader; ADebugMap: TObject; OwnSource: Boolean): TDbgImageReader;
var
  i   : Integer;
  cls : TDbgImageReaderClass;
begin
  Result := nil;
  if not Assigned(ASource) then Exit;

  for i := 0 to RegisteredImageReaderClasses.Count - 1 do begin
    cls :=  TDbgImageReaderClass(RegisteredImageReaderClasses[i]);
    try
      if cls.isValid(ASource) then begin
        Result := cls.Create(ASource, ADebugMap, OwnSource);
        ASource.Close;
        Exit;
      end
      else
        ;
    except
      on e: exception do begin
        //writeln('exception! WHY? ', e.Message);
      end;
    end;
  end;
  ASource.Close;
  Result := nil;
end;

procedure RegisterImageReaderClass( DataSource: TDbgImageReaderClass);
begin
  if Assigned(DataSource) and (RegisteredImageReaderClasses.IndexOf(DataSource) < 0) then
    RegisteredImageReaderClasses.Add(DataSource)
end;


{ TDbgFileLoader }

constructor TDbgFileLoader.Create(AFileName: String);
{$IFDEF MacOS}
var
  s: String;
{$ENDIF}
begin
  {$ifdef USE_WIN_FILE_MAPPING}
  FFileHandle := CreateFile(PChar(AFileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  Create(FFileHandle);
  {$else}
  FList := TList.Create;
  {$IFDEF MacOS}
  if (RightStr(AFileName,4) = '.app') then begin
    s := ExtractFileName(AFileName);
    s := AFileName + PathDelim + 'Contents' + PathDelim + 'MacOs' + PathDelim + copy(s, 1, Length(s) - 4);
    if (FileExists(s)) then AFileName := s
  end;
  {$ENDIF}
  FFileName := AFileName;
  FStream := TFileStreamUTF8.Create(AFileName, fmOpenRead or fmShareDenyNone);
  inherited Create;
  {$endif}
end;

{$ifdef USE_WIN_FILE_MAPPING}
constructor TDbgFileLoader.Create(AFileHandle: THandle);
begin
  FFileHandle := AFileHandle;
  if FFileHandle = INVALID_HANDLE_VALUE
  then begin
    raise Exception.Create('Invalid file handle');
  end;

  FMapHandle := CreateFileMapping(FFileHandle, nil, PAGE_READONLY{ or SEC_IMAGE}, 0, 0, nil);
  if FMapHandle = 0
  then begin
    raise Exception.Create('Could not create module mapping');
    Exit;
  end;

  FModulePtr := MapViewOfFile(FMapHandle, FILE_MAP_READ, 0, 0, 0);
  if FModulePtr = nil
  then begin
    raise Exception.Create('Could not map view');
    Exit;
  end;

  inherited Create;
end;
{$endif}

destructor TDbgFileLoader.Destroy;
begin
  {$ifdef USE_WIN_FILE_MAPPING}
  if FModulePtr <> nil
  then UnmapViewOfFile(FModulePtr);
  if FMapHandle <> 0
  then CloseHandle(FMapHandle);
  if FFileHandle <> INVALID_HANDLE_VALUE
  then CloseHandle(FFileHandle);
  {$else}
  while FList.Count > 0 do
    UnloadMemory(FList[0]);
  FreeAndNil(FList);
  FreeAndNil(FStream);
  inherited Destroy;
  {$endif}
end;

procedure TDbgFileLoader.Close;
begin
  {$ifNdef USE_WIN_FILE_MAPPING}
  FreeAndNil(FStream);
  {$endif}
end;

function TDbgFileLoader.Read(AOffset, ASize: QWord; AMem: Pointer): QWord;
begin
  {$ifdef USE_WIN_FILE_MAPPING}
  move((FModulePtr + AOffset)^, AMem^, ASize);
  Result := ASize;
  {$else}
  Result := 0;
  if AMem = nil then
    exit;
  if FStream = nil then
    FStream := TFileStreamUTF8.Create(FFileName, fmOpenRead or fmShareDenyNone);
  FStream.Position := AOffset;
  Result := FStream.Read(AMem^, ASize);
  {$endif}
end;

function TDbgFileLoader.LoadMemory(AOffset, ASize: QWord; out AMem: Pointer): QWord;
begin
  {$ifdef USE_WIN_FILE_MAPPING}
  AMem := FModulePtr + AOffset;
  Result := ASize;
  {$else}
  Result := 0;
  AMem := AllocMem(ASize);
  if AMem = nil then
    exit;
  if FStream = nil then
    FStream := TFileStreamUTF8.Create(FFileName, fmOpenRead or fmShareDenyNone);
  FList.Add(AMem);
  FStream.Position := AOffset;
  Result := FStream.Read(AMem^, ASize);
  {$endif}
end;

procedure TDbgFileLoader.UnloadMemory(AMem: Pointer);
begin
  {$ifdef USE_WIN_FILE_MAPPING}
  {$else}
  FList.Remove(AMem);
  Freemem(AMem);
  {$endif}
end;

{ TDbgImageReader }

function TDbgImageReader.GetAddressMapList: TDbgAddressMapList;
begin
  result := nil;
end;

function TDbgImageReader.GetSubFiles: TStrings;
begin
  result := nil;
end;

procedure TDbgImageReader.SetUUID(AGuid: TGuid);
begin
  FUUID := AGuid;
end;

procedure TDbgImageReader.SetImageBase(ABase: QWord);
begin
  FImageBase := ABase;
end;

procedure TDbgImageReader.SetImage64Bit(AValue: Boolean);
begin
  FImage64Bit := AValue;
end;

procedure TDbgImageReader.ParseSymbolTable(AFpSymbolInfo: TfpSymbolList);
begin
  // The format of the symbol-table-section(s) can be different on each
  // platform. That's why parsing the data is done in TDbgImageReader.
end;

constructor TDbgImageReader.Create(ASource: TDbgFileLoader; ADebugMap: TObject; OwnSource: Boolean);
begin
  inherited Create;
end;

procedure TDbgImageReader.AddSubFilesToLoaderList(ALoaderList: TObject;
  PrimaryLoader: TObject);
begin
  //
end;


procedure InitDebugInfoLists;
begin
  RegisteredImageReaderClasses := TFPList.Create;
end;

procedure ReleaseDebugInfoLists;
begin
  FreeAndNil(RegisteredImageReaderClasses);
end;

initialization
  InitDebugInfoLists;

finalization
  ReleaseDebugInfoLists;

end.

