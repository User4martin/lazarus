{
 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************

  Author: Mattias Gaertner

  Abstract:
    Caches for directories.
    The codetools work directory based, that means all define templates are the
    same for all files in a directory.
    That's why all the units in a directory use the same search paths and find
    the same files.
    
}
unit DirectoryCacher;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileProcs, AVL_Tree, CodeToolsStructs;

// verbosity
{ $DEFINE CTDEBUG}
{ $DEFINE ShowTriedFiles}
{ $DEFINE ShowTriedUnits}

{$ifdef MSWindows}
{$define CaseInsensitiveFilenames}
{$endif}
{$IF defined(CaseInsensitiveFilenames) or defined(darwin)}
{$DEFINE NotLiteralFilenames}
{$ENDIF}

type
  TCTDirCacheString = (
    ctdcsUnitPath,
    ctdcsSrcPath,
    ctdcsIncludePath,
    ctdcsCompleteSrcPath, // including unit path, src path and compiled src paths
    ctdcsUnitLinks,
    ctdcsFPCUnitPath  // unit paths reported by FPC
    );

  TCTDirCacheStringRecord = record
    Value: string;
    ConfigTimeStamp: cardinal;
  end;
  
  TCTDirectoryUnitSources = (
    ctdusUnitNormal, // e.g. unitname (case depends on OS) -> filename
    ctdusUnitCaseInsensitive, // unitname case insensitive -> filename
    ctdusInFilenameNormal, // unit 'in' filename -> filename
    ctdusInFilenameCaseInsensitive, // unit 'in' filename case insensitive -> filename
    ctdusUnitFileNormal, // unitname.ext (case depends on OS) -> filename
    ctdusUnitFileCaseInsensitive // unitname.ext case insensitive -> filename
    );

const
  ctdusCaseNormal      = [ctdusUnitNormal,
                          ctdusInFilenameNormal,
                          ctdusUnitFileNormal];
  ctdusCaseInsensitive = [ctdusUnitCaseInsensitive,
                          ctdusInFilenameCaseInsensitive,
                          ctdusUnitFileCaseInsensitive];

type
  TCTDirCacheUnitSrcRecord = record
    Files: TStringToStringTree;
    ConfigTimeStamp: Cardinal;
    FileTimeStamp: cardinal;
  end;

  { TCTDirectoryListing }

  TCTDirectoryListing = class
  public
    FileTimeStamp: cardinal;
    Names: PChar; // all filenames separated with #0
    NameCount: integer; // number of filenames
    NamesLength: PtrInt; // length of Names in bytes
    NameStarts: PInteger; // offsets in 'Names'
    destructor Destroy; override;
    procedure Clear;
    function CalcMemSize: PtrUInt;
  end;
  
  TCTDirectoryCachePool = class;


  { TCTDirectoryCache }

  TCTDirectoryCache = class
  private
    FDirectory: string;
    FPool: TCTDirectoryCachePool;
    FRefCount: integer;
    FStrings: array[TCTDirCacheString] of TCTDirCacheStringRecord;
    FUnitLinksTree: TAVLTree; // tree of TUnitNameLink
    FUnitLinksTreeTimeStamp: cardinal;
    FListing: TCTDirectoryListing;
    FUnitSources: array[TCTDirectoryUnitSources] of TCTDirCacheUnitSrcRecord;
    function GetStrings(const AStringType: TCTDirCacheString): string;
    procedure SetStrings(const AStringType: TCTDirCacheString;
      const AValue: string);
    procedure ClearUnitLinks;
    procedure UpdateListing;
    function GetUnitSourceCacheValue(const UnitSrc: TCTDirectoryUnitSources;
                           const Search: string; var Filename: string): boolean;
    procedure AddToCache(const UnitSrc: TCTDirectoryUnitSources;
                         const Search, Filename: string);
  public
    constructor Create(const TheDirectory: string;
                       ThePool: TCTDirectoryCachePool);
    destructor Destroy; override;
    procedure CalcMemSize(Stats: TCTMemStats);
    procedure Reference;
    procedure Release;
    function FindUnitLink(const UnitName: string): string;
    function FindFile(const ShortFilename: string;
                      const FileCase: TCTSearchFileCase): string;
    function FindUnitSource(const UnitName: string; AnyCase: boolean): string;
    function FindUnitSourceInCleanSearchPath(const Unitname,
                                  SearchPath: string; AnyCase: boolean): string;
    function FindUnitSourceInCompletePath(var UnitName, InFilename: string;
                                          AnyCase: boolean): string;
    function FindCompiledUnitInCompletePath(var ShortFilename: string;
                                            AnyCase: boolean): string;
    procedure WriteListing;
  public
    property Directory: string read FDirectory;
    property RefCount: integer read FRefCount;
    property Pool: TCTDirectoryCachePool read FPool;
    property Strings[const AStringType: TCTDirCacheString]: string read GetStrings write SetStrings;
  end;
  
  { TCTDirectoryCachePool }
  
  TCTDirCacheGetString = function(const ADirectory: string;
                                  const AStringType: TCTDirCacheString
                                  ): string of object;
  TCTDirCacheFindVirtualFile = function(const Filename: string): string of object;

  TCTDirectoryCachePool = class
  private
    FConfigTimeStamp: cardinal;
    FFileTimeStamp: cardinal;
    FDirectories: TAVLTree;// tree of TCTDirectoryCache
    FOnFindVirtualFile: TCTDirCacheFindVirtualFile;
    FOnGetString: TCTDirCacheGetString;
    procedure DoRemove(ACache: TCTDirectoryCache);
    procedure OnFileStateCacheChangeTimeStamp(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
    procedure CalcMemSize(Stats: TCTMemStats);
    function GetCache(const Directory: string;
                      CreateIfNotExists: boolean = true;
                      DoReference: boolean = true): TCTDirectoryCache;
    function GetString(const Directory: string; AStringType: TCTDirCacheString;
                       UseCache: boolean = true): string;
    procedure IncreaseFileTimeStamp;
    procedure IncreaseConfigTimeStamp;
    function FindUnitInUnitLinks(const Directory, UnitName: string): string;
    function FindDiskFilename(const Filename: string): string;
    function FindUnitInDirectory(const Directory, UnitName: string;
                                 AnyCase: boolean = false): string;
    function FindVirtualFile(const Filename: string): string;
    function FindVirtualUnit(const UnitName: string): string;
    function FindUnitSourceInCompletePath(const Directory: string;
                                          var UnitName, InFilename: string;
                                          AnyCase: boolean = false): string;
    function FindCompiledUnitInCompletePath(const Directory: string;
                                            var ShortFilename: string;
                                            AnyCase: boolean = false): string;
    property FileTimeStamp: cardinal read FFileTimeStamp;
    property ConfigTimeStamp: cardinal read FConfigTimeStamp;
    property OnGetString: TCTDirCacheGetString read FOnGetString write FOnGetString;
    property OnFindVirtualFile: TCTDirCacheFindVirtualFile read FOnFindVirtualFile
                                                   write FOnFindVirtualFile;
  end;
  
function CompareCTDirectoryCaches(Data1, Data2: Pointer): integer;
function ComparePAnsiStringAndDirectoryCache(Dir, Cache: Pointer): integer;

function ComparePCharFirstCaseInsThenCase(Data1, Data2: Pointer): integer;
function ComparePCharCaseInsensitive(Data1, Data2: Pointer): integer;
function ComparePCharCaseSensitive(Data1, Data2: Pointer): integer;

type

  { TUnitNameLink }

  TUnitNameLink = class
  public
    UnitName: string;
    Filename: string;
    function CalcMemSize: PtrUInt;
  end;

function SearchUnitInUnitLinks(const UnitLinks, TheUnitName: string;
  var UnitLinkStart, UnitLinkEnd: integer; out Filename: string): boolean;
function CreateUnitLinksTree(const UnitLinks: string): TAVLTree;
function CompareUnitLinkNodes(NodeData1, NodeData2: pointer): integer;
function CompareUnitNameWithUnitLinkNode(UnitName: Pointer;
  NodeData: pointer): integer;


implementation

function CompareCTDirectoryCaches(Data1, Data2: Pointer): integer;
begin
  Result:=CompareFilenames(TCTDirectoryCache(Data1).FDirectory,
                           TCTDirectoryCache(Data2).FDirectory);
end;

function ComparePAnsiStringAndDirectoryCache(Dir, Cache: Pointer): integer;
begin
  Result:=CompareFilenames(PAnsiString(Dir)^,TCTDirectoryCache(Cache).FDirectory);
end;

function ComparePCharFirstCaseInsThenCase(Data1, Data2: Pointer): integer;
begin
  Result:=ComparePCharCaseInsensitive(Data1,Data2);
  if Result=0 then
    Result:=ComparePCharCaseSensitive(Data1,Data2);
end;

function ComparePCharCaseInsensitive(Data1, Data2: Pointer): integer;
var
  p1: PChar absolute Data1;
  p2: PChar absolute Data2;
begin
  while (FPUpChars[p1^]=FPUpChars[p2^]) and (p1^<>#0) do begin
    inc(p1);
    inc(p2);
  end;
  Result:=ord(FPUpChars[p1^])-ord(FPUpChars[p2^]);
end;

function ComparePCharCaseInsensitive(Data1, Data2: Pointer;
  MaxCount: PtrInt): integer;
var
  p1: PChar absolute Data1;
  p2: PChar absolute Data2;
begin
  while (FPUpChars[p1^]=FPUpChars[p2^]) and (p1^<>#0) and (MaxCount>0) do begin
    inc(p1);
    inc(p2);
    dec(MaxCount);
  end;
  if MaxCount=0 then
    Result:=0
  else
    Result:=ord(FPUpChars[p1^])-ord(FPUpChars[p2^]);
end;

function ComparePCharCaseSensitive(Data1, Data2: Pointer): integer;
var
  p1: PChar absolute Data1;
  p2: PChar absolute Data2;
begin
  while (p1^=p2^) and (p1^<>#0) do begin
    inc(p1);
    inc(p2);
  end;
  Result:=ord(p1^)-ord(p2^);
end;

function ComparePCharUnitNameWithFilename(UnitNameP, FilenameP: Pointer): integer;
var
  UnitName: PChar absolute UnitNameP;
  Filename: PChar absolute FilenameP;
begin
  while (FPUpChars[UnitName^]=FPUpChars[Filename^]) and (UnitName^<>#0) do begin
    inc(UnitName);
    inc(Filename);
  end;
  if (UnitName^=#0) then
     if (Filename^='.') then
        Result:=0
     else
        Result:=ord('.')-ord(Filename^) // TG 2007-10-21
  else
    Result:=ord(FPUpChars[UnitName^])-ord(FPUpChars[Filename^]);
end;

function SearchUnitInUnitLinks(const UnitLinks, TheUnitName: string;
  var UnitLinkStart, UnitLinkEnd: integer; out Filename: string): boolean;
var
  UnitLinkLen: integer;
  pe: TCTPascalExtType;
  AliasFilename: String;
begin
  Result:=false;
  Filename:='';
  if TheUnitName='' then exit;
  {$IFDEF ShowTriedFiles}
  DebugLn(['SearchUnitInUnitLinks length(UnitLinks)=',length(UnitLinks)]);
  {$ENDIF}
  if UnitLinkStart<1 then
    UnitLinkStart:=1;
  while UnitLinkStart<=length(UnitLinks) do begin
    while (UnitLinkStart<=length(UnitLinks))
    and (UnitLinks[UnitLinkStart] in [#10,#13]) do
      inc(UnitLinkStart);
    UnitLinkEnd:=UnitLinkStart;
    while (UnitLinkEnd<=length(UnitLinks)) and (UnitLinks[UnitLinkEnd]<>' ')
    do
      inc(UnitLinkEnd);
    UnitLinkLen:=UnitLinkEnd-UnitLinkStart;
    if UnitLinkLen>0 then begin
      {$IFDEF ShowTriedFiles}
      DebugLn(['  unit "',copy(UnitLinks,UnitLinkStart,UnitLinkEnd-UnitLinkStart),'" ',
        ComparePCharCaseInsensitive(Pointer(TheUnitName),@UnitLinks[UnitLinkStart],UnitLinkLen)]);
      {$ENDIF}
      if (UnitLinkLen=length(TheUnitName))
      and (ComparePCharCaseInsensitive(Pointer(TheUnitName),@UnitLinks[UnitLinkStart],
           UnitLinkLen)=0)
      then begin
        // unit found -> parse filename
        UnitLinkStart:=UnitLinkEnd+1;
        UnitLinkEnd:=UnitLinkStart;
        while (UnitLinkEnd<=length(UnitLinks))
        and (not (UnitLinks[UnitLinkEnd] in [#10,#13])) do
          inc(UnitLinkEnd);
        if UnitLinkEnd>UnitLinkStart then begin
          Filename:=copy(UnitLinks,UnitLinkStart,UnitLinkEnd-UnitLinkStart);
          if FileExistsCached(Filename) then begin
            Result:=true;
            exit;
          end;
          // try also different extensions
          for pe:=Low(TCTPascalExtType) to High(TCTPascalExtType) do begin
            if CompareFileExt(Filename,CTPascalExtension[pe],false)<>0 then
            begin
              AliasFilename:=ChangeFileExt(Filename,'.pas');
              if FileExistsCached(AliasFilename) then begin
                Filename:=AliasFilename;
                Result:=true;
                exit;
              end;
            end;
          end;
        end;
        UnitLinkStart:=UnitLinkEnd;
      end else begin
        UnitLinkStart:=UnitLinkEnd+1;
        while (UnitLinkStart<=length(UnitLinks))
        and (not (UnitLinks[UnitLinkStart] in [#10,#13])) do
          inc(UnitLinkStart);
      end;
    end else
      break;
  end;
end;

function CreateUnitLinksTree(const UnitLinks: string): TAVLTree;
var
  UnitLinksTree: TAVLTree;
  UnitLinkLen: integer;
  UnitLinkStart: Integer;
  UnitLinkEnd: Integer;
  TheUnitName: String;
  Filename: String;
  NewNode: TUnitNameLink;
begin
  UnitLinksTree:=TAVLTree.Create(@CompareUnitLinkNodes);
  UnitLinkStart:=1;
  while UnitLinkStart<=length(UnitLinks) do begin
    while (UnitLinkStart<=length(UnitLinks))
    and (UnitLinks[UnitLinkStart] in [#10,#13]) do
      inc(UnitLinkStart);
    UnitLinkEnd:=UnitLinkStart;
    while (UnitLinkEnd<=length(UnitLinks)) and (UnitLinks[UnitLinkEnd]<>' ')
    do
      inc(UnitLinkEnd);
    UnitLinkLen:=UnitLinkEnd-UnitLinkStart;
    if UnitLinkLen>0 then begin
      TheUnitName:=copy(UnitLinks,UnitLinkStart,UnitLinkLen);
      if IsValidIdent(TheUnitName) then begin
        UnitLinkStart:=UnitLinkEnd+1;
        UnitLinkEnd:=UnitLinkStart;
        while (UnitLinkEnd<=length(UnitLinks))
        and (not (UnitLinks[UnitLinkEnd] in [#10,#13])) do
          inc(UnitLinkEnd);
        if UnitLinkEnd>UnitLinkStart then begin
          Filename:=copy(UnitLinks,UnitLinkStart,UnitLinkEnd-UnitLinkStart);
          NewNode:=TUnitNameLink.Create;
          NewNode.UnitName:=TheUnitName;
          NewNode.Filename:=Filename;
          UnitLinksTree.Add(NewNode);
        end;
        UnitLinkStart:=UnitLinkEnd;
      end else begin
        UnitLinkStart:=UnitLinkEnd+1;
        while (UnitLinkStart<=length(UnitLinks))
        and (not (UnitLinks[UnitLinkStart] in [#10,#13])) do
          inc(UnitLinkStart);
      end;
    end else
      break;
  end;
  Result:=UnitLinksTree;
end;

function CompareUnitLinkNodes(NodeData1, NodeData2: pointer): integer;
var Link1, Link2: TUnitNameLink;
begin
  Link1:=TUnitNameLink(NodeData1);
  Link2:=TUnitNameLink(NodeData2);
  Result:=CompareText(Link1.UnitName,Link2.UnitName);
end;

function CompareUnitNameWithUnitLinkNode(UnitName: Pointer;
  NodeData: pointer): integer;
begin
  Result:=CompareText(String(UnitName),TUnitNameLink(NodeData).UnitName);
end;

{ TCTDirectoryCache }

function TCTDirectoryCache.GetStrings(const AStringType: TCTDirCacheString
  ): string;
begin
  //if AStringType=ctdcsUnitPath then DebugLn(['TCTDirectoryCache.GetStrings ctdcsUnitPath ',Directory,' ',FStrings[AStringType].ConfigTimeStamp,' ',Pool.ConfigTimeStamp]);
  if FStrings[AStringType].ConfigTimeStamp<>Pool.ConfigTimeStamp then begin
    Strings[AStringType]:=Pool.GetString(Directory,AStringType,false);
  end;
  Result:=FStrings[AStringType].Value;
end;

procedure TCTDirectoryCache.SetStrings(const AStringType: TCTDirCacheString;
  const AValue: string);
begin
  FStrings[AStringType].Value:=AValue;
  FStrings[AStringType].ConfigTimeStamp:=Pool.ConfigTimeStamp;
end;

procedure TCTDirectoryCache.ClearUnitLinks;
begin
  if FUnitLinksTree=nil then exit;
  FUnitLinksTree.FreeAndClear;
  FUnitLinksTree.Free;
  FUnitLinksTree:=nil
end;

procedure TCTDirectoryCache.UpdateListing;
var
  WorkingListing: PAnsiString;
  WorkingListingCapacity, WorkingListingCount: integer;
  FileInfo: TSearchRec;
  TotalLen: Integer;
  i: Integer;
  p: Integer;
  CurFilenameLen: Integer;
  NewCapacity: Integer;
begin
  if (FListing<>nil) and (FListing.FileTimeStamp=Pool.FileTimeStamp) then exit;
  if FListing=nil then
    FListing:=TCTDirectoryListing.Create;
  FListing.Clear;
  FListing.FileTimeStamp:=Pool.FileTimeStamp;
  if Directory='' then exit;// virtual directory
  
  // Note: do not add a 'if not DirectoryExistsUTF8 then exit'. This will not
  // work on automounted directories. You must use FindFirstUTF8.

  // read the directory
  WorkingListing:=nil;
  WorkingListingCapacity:=0;
  WorkingListingCount:=0;
  try
    if FindFirstUTF8(Directory+FileMask,faAnyFile,FileInfo)=0 then begin
      repeat
        // check if special file
        if (FileInfo.Name='.') or (FileInfo.Name='..') or (FileInfo.Name='')
        then
          continue;
        // add file
        if WorkingListingCount=WorkingListingCapacity then begin
          // grow WorkingListing
          if WorkingListingCapacity>0 then
            NewCapacity:=WorkingListingCapacity*2
          else
            NewCapacity:=8;
          ReAllocMem(WorkingListing,SizeOf(Pointer)*NewCapacity);
          FillChar(WorkingListing[WorkingListingCount],
                   SizeOf(Pointer)*(NewCapacity-WorkingListingCapacity),0);
          WorkingListingCapacity:=NewCapacity;
        end;
        WorkingListing[WorkingListingCount]:=FileInfo.Name;
        inc(WorkingListingCount);
      until FindNextUTF8(FileInfo)<>0;
    end;
    FindCloseUTF8(FileInfo);

    if WorkingListingCount=0 then exit;

    // sort the files
    MergeSort(PPointer(WorkingListing),WorkingListingCount,
              @ComparePCharFirstCaseInsThenCase);

    // create listing
    TotalLen:=0;
    for i:=0 to WorkingListingCount-1 do
      inc(TotalLen,length(WorkingListing[i])+1);
    GetMem(FListing.Names,TotalLen);
    FListing.NamesLength:=TotalLen;
    FListing.NameCount:=WorkingListingCount;
    GetMem(FListing.NameStarts,SizeOf(PChar)*WorkingListingCount);
    p:=0;
    for i:=0 to WorkingListingCount-1 do begin
      CurFilenameLen:=length(WorkingListing[i]);
      if CurFilenameLen>0 then begin
        FListing.NameStarts[i]:=p;
        System.Move(WorkingListing[i][1],FListing.Names[p],CurFilenameLen);
        inc(p,CurFilenameLen);
      end;
      FListing.Names[p]:=#0;
      inc(p);
    end;
  finally
    for i:=0 to WorkingListingCount-1 do
      WorkingListing[i]:='';
    ReAllocMem(WorkingListing,0);
  end;
end;

function TCTDirectoryCache.GetUnitSourceCacheValue(
  const UnitSrc: TCTDirectoryUnitSources; const Search: string;
  var Filename: string): boolean;
var
  Files: TStringToStringTree;
begin
  Files:=FUnitSources[UnitSrc].Files;
  if (FUnitSources[UnitSrc].FileTimeStamp<>Pool.FileTimeStamp)
  or (FUnitSources[UnitSrc].ConfigTimeStamp<>Pool.ConfigTimeStamp) then begin
    // cache is invalid -> clear to make it valid
    if Files<>nil then
      Files.Clear;
    FUnitSources[UnitSrc].FileTimeStamp:=Pool.FileTimeStamp;
    FUnitSources[UnitSrc].ConfigTimeStamp:=Pool.ConfigTimeStamp;
    Result:=false;
  end else begin
    // cache is valid
    if Files<>nil then begin
      Result:=Files.GetString(Search,Filename);
    end else begin
      Result:=false;
    end;
  end;
end;

procedure TCTDirectoryCache.AddToCache(const UnitSrc: TCTDirectoryUnitSources;
  const Search, Filename: string);
var
  Files: TStringToStringTree;
begin
  Files:=FUnitSources[UnitSrc].Files;
  if Files=nil then begin
    case UnitSrc of
    ctdusUnitNormal:               Files:=TStringToStringTree.Create(FilenamesCaseSensitive);
    ctdusUnitCaseInsensitive:      Files:=TStringToStringTree.Create(false);
    ctdusInFilenameNormal:         Files:=TFilenameToStringTree.Create(false);
    ctdusInFilenameCaseInsensitive:Files:=TFilenameToStringTree.Create(true);
    ctdusUnitFileNormal:           Files:=TFilenameToStringTree.Create(false);
    ctdusUnitFileCaseInsensitive:  Files:=TFilenameToStringTree.Create(true);
    end;
    FUnitSources[UnitSrc].Files:=Files;
  end;
  Files[Search]:=Filename;
end;

constructor TCTDirectoryCache.Create(const TheDirectory: string;
  ThePool: TCTDirectoryCachePool);
  
  procedure RaiseDirNotAbsolute;
  begin
    raise Exception.Create('directory not absolute "'+FDirectory+'"');
  end;
  
begin
  FDirectory:=AppendPathDelim(TrimFilename(TheDirectory));
  if FDirectory='.' then FDirectory:='';
  if (FDirectory<>'') and not FilenameIsAbsolute(FDirectory) then
    RaiseDirNotAbsolute;
  FPool:=ThePool;
  FRefCount:=1;
end;

destructor TCTDirectoryCache.Destroy;
var
  UnitSrc: TCTDirectoryUnitSources;
begin
  ClearUnitLinks;
  if Pool<>nil then Pool.DoRemove(Self);
  FreeAndNil(FListing);
  for UnitSrc:=Low(TCTDirectoryUnitSources) to High(TCTDirectoryUnitSources) do
    FreeAndNil(FUnitSources[UnitSrc].Files);
  inherited Destroy;
end;

procedure TCTDirectoryCache.CalcMemSize(Stats: TCTMemStats);
var
  cs: TCTDirCacheString;
  us: TCTDirectoryUnitSources;
  Node: TAVLTreeNode;
  m: PtrUInt;
begin
  Stats.Add('TCTDirectoryCache',PtrUInt(InstanceSize)
    +MemSizeString(FDirectory));

  m:=0;
  for cs:=Low(FStrings) to high(FStrings) do begin
    inc(m,SizeOf(TCTDirCacheStringRecord));
    inc(m,MemSizeString(FStrings[cs].Value));
  end;
  Stats.Add('TCTDirectoryCache.FStrings',m);

  m:=0;
  for us:=Low(FUnitSources) to high(FUnitSources) do begin
    inc(m,SizeOf(TCTDirectoryUnitSources));
    if FUnitSources[us].Files<>nil then
      inc(m,FUnitSources[us].Files.CalcMemSize);
  end;
  Stats.Add('TCTDirectoryCache.FUnitSources',m);

  if FUnitLinksTree<>nil then begin
    m:=PtrUInt(FUnitLinksTree.InstanceSize)
      +SizeOf(TAVLTreeNode)*PtrUInt(FUnitLinksTree.Count);
    Node:=FUnitLinksTree.FindLowest;
    while Node<>nil do begin
      inc(m,TUnitNameLink(Node.Data).CalcMemSize);
      Node:=FUnitLinksTree.FindSuccessor(Node);
    end;
    Stats.Add('TCTDirectoryCache.FUnitLinksTree',m);
  end;

  if FListing<>nil then
    Stats.Add('TCTDirectoryCache.FListing',FListing.CalcMemSize);
end;

procedure TCTDirectoryCache.Reference;
begin
  inc(FRefCount);
end;

procedure TCTDirectoryCache.Release;
begin
  if FRefCount<=0 then
    raise Exception.Create('TCTDirectoryCache.Release');
  dec(FRefCount);
  if FRefCount=0 then Free;
end;

function TCTDirectoryCache.FindUnitLink(const UnitName: string): string;
var
  Node: TAVLTreeNode;
  Link: TUnitNameLink;
  AliasFilename: String;
  pe: TCTPascalExtType;
begin
  if (FUnitLinksTree=nil) or (FUnitLinksTreeTimeStamp<>Pool.FileTimeStamp) then
  begin
    ClearUnitLinks;
    FUnitLinksTreeTimeStamp:=Pool.FileTimeStamp;
    FUnitLinksTree:=CreateUnitLinksTree(Strings[ctdcsUnitLinks]);
  end;
  Node:=FUnitLinksTree.FindKey(Pointer(UnitName),
                               @CompareUnitNameWithUnitLinkNode);
  if Node<>nil then begin
    Link:=TUnitNameLink(Node.Data);
    Result:=Link.Filename;
    if FileExistsCached(Result) then begin
      exit;
    end;
    // try different extensions too
    for pe:=Low(TCTPascalExtType) to High(TCTPascalExtType) do begin
      if CompareFileExt(Result,CTPascalExtension[pe],false)<>0 then
      begin
        AliasFilename:=ChangeFileExt(Result,CTPascalExtension[pe]);
        if FileExistsCached(AliasFilename) then begin
          Link.Filename:=AliasFilename;
          Result:=AliasFilename;
          exit;
        end;
      end;
    end;
  end;
  Result:='';
end;

function TCTDirectoryCache.FindFile(const ShortFilename: string;
  const FileCase: TCTSearchFileCase): string;
  
  procedure RaiseDontKnow;
  begin
    raise Exception.Create('dont know FileCase '+IntToStr(ord(FileCase)));
  end;
  
var
  l: Integer;
  r: Integer;
  m: Integer;
  cmp: LongInt;
  CurFilename: PChar;
begin
  Result:='';
  if ShortFilename='' then exit;
  if Directory<>'' then begin
    UpdateListing;
    if (FListing.Names=nil) then exit;
    l:=0;
    r:=FListing.NameCount-1;
    while r>=l do begin
      m:=(l+r) shr 1;
      CurFilename:=@FListing.Names[FListing.NameStarts[m]];
      case FileCase of
      ctsfcDefault:
        {$IFDEF CaseInsensitiveFilenames}
        cmp:=ComparePCharCaseInsensitive(Pointer(ShortFilename),CurFilename);// pointer type cast avoids #0 check
        {$ELSE}
        cmp:=ComparePCharCaseSensitive(Pointer(ShortFilename),CurFilename);
        {$ENDIF}
      ctsfcAllCase,ctsfcLoUpCase:
        cmp:=ComparePCharCaseInsensitive(Pointer(ShortFilename),CurFilename);
      else RaiseDontKnow;
      end;
      if cmp>0 then
        l:=m+1
      else if cmp<0 then
        r:=m-1
      else begin
        Result:=CurFilename;
        exit;
      end;
    end;
  end else begin
    // this is a virtual directory
    Result:=Pool.FindVirtualFile(ShortFilename);
  end;
end;

function TCTDirectoryCache.FindUnitSource(const UnitName: string;
  AnyCase: boolean): string;
var
  l: Integer;
  r: Integer;
  m: Integer;
  cmp: LongInt;
  CurFilename: PChar;
  CurFilenameLen: LongInt;
begin
  Result:='';
  //if (CompareText(UnitName,'AddFileToAPackageDlg')=0) {and (System.Pos('packager',directory)>0)} then
  //  DebugLn('TCTDirectoryCache.FindUnitSource UnitName="',Unitname,'" AnyCase=',dbgs(AnyCase),' Directory=',Directory);
  if UnitName='' then exit;
  if Directory<>'' then begin
    UpdateListing;
    if (FListing.Names=nil) then exit;
    // binary search the nearest filename
    //if (CompareText(UnitName,'AddFileToAPackageDlg')=0) and (System.Pos('packager',directory)>0) then
    //  WriteListing;
    
    l:=0;
    r:=FListing.NameCount-1;
    while r>=l do begin
      m:=(l+r) shr 1;
      CurFilename:=@FListing.Names[FListing.NameStarts[m]];
      cmp:=ComparePCharUnitNameWithFilename(Pointer(UnitName),CurFilename);
      if cmp>0 then
        l:=m+1
      else if cmp<0 then
        r:=m-1
      else
        break;
    end;
    if cmp<>0 then exit;
    // m is now on a filename with the right unit name, but maybe no the right
    // extension
    // go to the first filename with the right unit name
    while (m>0)
    and (ComparePCharUnitNameWithFilename(Pointer(UnitName),
                      @FListing.Names[FListing.NameStarts[m-1]])=0)
    do
      dec(m);
    // -> now find a filename with correct case and extension
    while m<FListing.NameCount do begin
      CurFilename:=@FListing.Names[FListing.NameStarts[m]];
      // check if filename has the right unitname
      if (ComparePCharUnitNameWithFilename(Pointer(UnitName),CurFilename)<>0)
      then
        break;
      //if (CompareText(UnitName,'AddFileToAPackageDlg')=0) {and (System.Pos('packager',directory)>0)} then
      //  DebugLn('TCTDirectoryCache.FindUnitSource NEXT ',CurFilename);

      // check if the filename fits
      CurFilenameLen:=strlen(CurFilename);
      if FilenameIsPascalUnit(CurFilename,CurFilenameLen,false) then
      begin
        // the unitname is ok and the extension is ok
        Result:=CurFilename;
        if AnyCase then begin
          exit;
        end else begin
          // check case platform dependent
          {$IFDEF CaseInsensitiveFilenames}
          exit;
          {$ELSE}
          if (Result=lowercase(Result))
          or (Result=uppercase(Result))
          or (ExtractFileNameOnly(Result)=UnitName) then
            exit;
          {$ENDIF}
        end;
      end;
      inc(m);
    end;
    //if m<FListing.NameCount then
    //  if (CompareText(UnitName,'AddFileToAPackageDlg')=0) and (System.Pos('packager',directory)>0) then
    //    DebugLn('TCTDirectoryCache.FindUnitSource LAST ',CurFilename);
  end else begin
    // this is a virtual directory
    Result:=Pool.FindVirtualUnit(UnitName);
    if Result<>'' then exit;
  end;
  Result:='';
end;

function TCTDirectoryCache.FindUnitSourceInCleanSearchPath(const Unitname,
  SearchPath: string; AnyCase: boolean): string;
var
  p, StartPos, l: integer;
  CurPath: string;
  IsAbsolute: Boolean;
begin
  //if (CompareText(Unitname,'UnitDependencies')=0) then
  //  DebugLn('TCTDirectoryCache.FindUnitSourceInCleanSearchPath UnitName="',Unitname,'" SearchPath="',SearchPath,'"');
  StartPos:=1;
  l:=length(SearchPath);
  while StartPos<=l do begin
    p:=StartPos;
    while (p<=l) and (SearchPath[p]<>';') do inc(p);
    CurPath:=Trim(copy(SearchPath,StartPos,p-StartPos));
    if CurPath<>'' then begin
      IsAbsolute:=FilenameIsAbsolute(CurPath);
      if (not IsAbsolute) and (Directory<>'') then begin
        CurPath:=Directory+CurPath;
        IsAbsolute:=true;
      end;
      //DebugLn('TCTDirectoryCache.FindUnitSourceInCleanSearchPath CurPath="',CurPath,'"');
      if IsAbsolute then begin
        CurPath:=AppendPathDelim(CurPath);
        Result:=Pool.FindUnitInDirectory(CurPath,UnitName,AnyCase);
      end else if (CurPath='.') and (Directory='') then begin
        Result:=Pool.FindVirtualUnit(Unitname);
      end;
      if Result<>'' then exit;
    end;
    StartPos:=p+1;
  end;
  Result:='';
end;

function TCTDirectoryCache.FindUnitSourceInCompletePath(
  var UnitName, InFilename: string; AnyCase: boolean): string;

  function FindInFilename(aFilename: string): string;
  var
    Ext: String;
  begin
    Ext:=ExtractFileExt(aFilename);
    if Ext='' then
      aFilename:=aFilename+'.pp'; // append default extension
    if AnyCase then
      Result:=Pool.FindDiskFilename(aFilename)
    else
      Result:=aFilename;
    if (not FileExistsCached(Result)) then begin
      if (Ext<>'') then begin
        Result:='';
        exit;
      end;
      // search for secondary extension
      aFilename:=ChangeFileExt(aFilename,'.pas');
      if AnyCase then
        Result:=Pool.FindDiskFilename(aFilename)
      else
        Result:=aFilename;
      if (not FileExistsCached(Result)) then begin
        Result:='';
        exit;
      end;
    end;
    InFilename:=CreateRelativePath(Result,Directory);
  end;

var
  UnitSrc: TCTDirectoryUnitSources;
  CurDir: String;
  SrcPath: string;
  NewUnitName: String;
begin
  Result:='';
  {$IFDEF ShowTriedUnits}
  DebugLn('TCTDirectoryCache.FindUnitSourceInCompletePath UnitName="',Unitname,'" InFilename="',InFilename,'" Directory="',Directory,'"');
  {$ENDIF}
  if InFilename<>'' then begin
    // uses IN parameter
    InFilename:=TrimFilename(SetDirSeparators(InFilename));
    if AnyCase then
      UnitSrc:=ctdusInFilenameCaseInsensitive
    else
      UnitSrc:=ctdusInFilenameNormal;
    if GetUnitSourceCacheValue(UnitSrc,InFilename,Result) then begin
      // found in cache
      if Result<>'' then begin
        // unit found
        if Directory<>'' then
          InFilename:=CreateRelativePath(Result,Directory);
      end else begin
        // unit not found
      end;
    end else begin
      // not found in cache -> search
      if FilenameIsAbsolute(InFilename) then begin
        // absolute filename
        Result:=FindInFilename(InFilename);
      end else begin
        // 'in'-filename has no complete path
        // -> search file relative to current directory
        CurDir:=Directory;
        if CurDir<>'' then begin
          Result:=FindInFilename(TrimFilename(CurDir+InFilename));
        end else begin
          // this is a virtual directory -> search virtual unit
          InFilename:=Pool.FindVirtualFile(InFilename);
          Result:=InFilename;
        end;
      end;
      AddToCache(UnitSrc,InFilename,Result);
    end;
  end else begin
    // normal unit name

    if AnyCase then
      UnitSrc:=ctdusUnitCaseInsensitive
    else
      UnitSrc:=ctdusUnitNormal;
    if GetUnitSourceCacheValue(UnitSrc,UnitName,Result) then begin
      // found in cache
      if Result<>'' then begin
        // unit found
      end else begin
        // unit not found
      end;
    end else begin
      // not found in cache -> search in complete source path

      SrcPath:=Strings[ctdcsCompleteSrcPath];

      // search in search path
      Result:=FindUnitSourceInCleanSearchPath(UnitName,SrcPath,AnyCase);
      if Result='' then begin
        // search in unit links
        {$IFDEF ShowTriedUnits}
        DebugLn(['TCTDirectoryCache.FindUnitSourceInCompletePath unit ',UnitName,' not found in SrcPath="',SrcPath,'"  Directory="',Directory,'"']);
        {$ENDIF}
        Result:=FindUnitLink(UnitName);
        {$IFDEF ShowTriedUnits}
        if Result='' then begin
          DebugLn(['TCTDirectoryCache.FindUnitSourceInCompletePath unit ',UnitName,' not found in unitlinks. Directory="',Directory,'"']);
        end;
        {$ENDIF}
      end;
      if Result<>'' then begin
        // improve unit name
        NewUnitName:=ExtractFileNameOnly(Result);
        if (NewUnitName<>lowercase(NewUnitName))
        and (UnitName<>NewUnitName) then
          UnitName:=NewUnitName;
      end;

      AddToCache(UnitSrc,UnitName,Result);
    end;
  end;
  //DebugLn('TCTDirectoryCache.FindUnitSourceInCompletePath RESULT UnitName="',UnitName,'" InFilename="',InFilename,'" Result=',Result);
end;

function TCTDirectoryCache.FindCompiledUnitInCompletePath(
  var ShortFilename: string; AnyCase: boolean): string;
var
  UnitPath: string;
  NewShortFilename: String;
  UnitSrc: TCTDirectoryUnitSources;
  CurDir: String;
  SearchCase: TCTSearchFileCase;
begin
  Result:='';
  if AnyCase then
    UnitSrc:=ctdusUnitFileCaseInsensitive
  else
    UnitSrc:=ctdusUnitFileNormal;
  if GetUnitSourceCacheValue(UnitSrc,ShortFilename,Result) then begin
    // found in cache
    if Result<>'' then begin
      // unit found
    end else begin
      // unit not found
    end;
  end else begin
    // not found in cache -> search

    CurDir:=Directory;

    if AnyCase then
      SearchCase:=ctsfcAllCase
    else
      SearchCase:=ctsfcLoUpCase;

    // search in unit, src and compiled src path
    UnitPath:=Strings[ctdcsUnitPath];
    Result:=SearchPascalFileInPath(ShortFilename,CurDir,UnitPath,';',SearchCase);
    if Result='' then begin
      // search in fpc unit path
      UnitPath:=Strings[ctdcsFPCUnitPath];
      Result:=SearchPascalFileInPath(ShortFilename,'',UnitPath,';',SearchCase);
    end;
    if Result<>'' then begin
      NewShortFilename:=ExtractFileName(Result);
      if (NewShortFilename<>lowercase(NewShortFilename))
      and (ShortFilename<>NewShortFilename) then
        ShortFilename:=NewShortFilename;
    end;

    AddToCache(UnitSrc,ShortFilename,Result);
  end;
end;

procedure TCTDirectoryCache.WriteListing;
var
  i: Integer;
  Filename: PChar;
begin
  writeln('TCTDirectoryCache.WriteListing Count=',FListing.NameCount,' TextLen=',FListing.NamesLength);
  for i:=0 to FListing.NameCount-1 do begin
    Filename:=@FListing.Names[FListing.NameStarts[i]];
    writeln(i,' "',Filename,'"');
  end;
end;

{ TCTDirectoryCachePool }

procedure TCTDirectoryCachePool.DoRemove(ACache: TCTDirectoryCache);
begin
  FDirectories.Remove(ACache);
end;

procedure TCTDirectoryCachePool.OnFileStateCacheChangeTimeStamp(Sender: TObject
  );
begin
  IncreaseFileTimeStamp;
end;

constructor TCTDirectoryCachePool.Create;
begin
  FDirectories:=TAVLTree.Create(@CompareCTDirectoryCaches);
  FFileTimeStamp:=1;
  FConfigTimeStamp:=1;
  if FileStateCache<>nil then
    FileStateCache.AddChangeTimeStampHandler(@OnFileStateCacheChangeTimeStamp);
end;

destructor TCTDirectoryCachePool.Destroy;
var
  Cache: TCTDirectoryCache;
begin
  if FileStateCache<>nil then
    FileStateCache.RemoveChangeTimeStampHandler(@OnFileStateCacheChangeTimeStamp);
  while FDirectories.Root<>nil do begin
    Cache:=TCTDirectoryCache(FDirectories.Root.Data);
    if Cache.RefCount<>1 then
      raise Exception.Create('TCTDirectoryCachePool.Destroy');
    Cache.Release;
  end;
  FDirectories.Free;
  inherited Destroy;
end;

procedure TCTDirectoryCachePool.CalcMemSize(Stats: TCTMemStats);
var
  Node: TAVLTreeNode;
begin
  Stats.Add('TCTDirectoryCachePool',PtrUInt(InstanceSize));
  Stats.Add('TCTDirectoryCachePool.Count',FDirectories.Count);
  Node:=FDirectories.FindLowest;
  while Node<>nil do begin
    TCTDirectoryCache(Node.Data).CalcMemSize(Stats);
    Node:=FDirectories.FindSuccessor(Node);
  end;
end;

function TCTDirectoryCachePool.GetCache(const Directory: string;
  CreateIfNotExists: boolean; DoReference: boolean): TCTDirectoryCache;
var
  Node: TAVLTreeNode;
  Dir: String;
begin
  Dir:=AppendPathDelim(TrimFilename(Directory));
  Node:=FDirectories.FindKey(@Dir,@ComparePAnsiStringAndDirectoryCache);
  if Node<>nil then begin
    Result:=TCTDirectoryCache(Node.Data);
    if DoReference then
      Result.Reference;
  end else if DoReference or CreateIfNotExists then begin
    Result:=TCTDirectoryCache.Create(Directory,Self);
    FDirectories.Add(Result);
    if DoReference then
      Result.Reference;
  end else
    Result:=nil;
end;

function TCTDirectoryCachePool.GetString(const Directory: string;
  AStringType: TCTDirCacheString; UseCache: boolean): string;
var
  Cache: TCTDirectoryCache;
begin
  if UseCache then begin
    Cache:=GetCache(Directory,true,false);
    if Cache<>nil then
      Result:=Cache.Strings[AStringType]
    else
      Result:='';
  end else begin
    Result:=OnGetString(Directory,AStringType);
  end;
end;

procedure TCTDirectoryCachePool.IncreaseFileTimeStamp;
begin
  //DebugLn(['TCTDirectoryCachePool.IncreaseTimeStamp ']);
  if FFileTimeStamp<>High(FFileTimeStamp) then
    inc(FFileTimeStamp)
  else
    FFileTimeStamp:=Low(FFileTimeStamp);
end;

procedure TCTDirectoryCachePool.IncreaseConfigTimeStamp;
begin
  //DebugLn(['TCTDirectoryCachePool.IncreaseConfigTimeStamp ']);
  if FConfigTimeStamp<>High(FConfigTimeStamp) then
    inc(FConfigTimeStamp)
  else
    FConfigTimeStamp:=Low(FConfigTimeStamp);
end;

function TCTDirectoryCachePool.FindUnitInUnitLinks(const Directory,
  UnitName: string): string;
  
  procedure RaiseDirNotAbsolute;
  begin
    raise Exception.Create('TCTDirectoryCachePool.FindUnitInUnitLinks not absolute Directory="'+Directory+'"');
  end;
  
var
  Cache: TCTDirectoryCache;
begin
  if (Directory<>'') and not FilenameIsAbsolute(Directory) then
    RaiseDirNotAbsolute;
  Cache:=GetCache(Directory,true,false);
  Result:=Cache.FindUnitLink(UnitName);
end;

function TCTDirectoryCachePool.FindDiskFilename(const Filename: string
  ): string;
var
  ADirectory: String;
  Cache: TCTDirectoryCache;
  ShortFilename: String;
begin
  Result:=TrimFilename(Filename);
  ADirectory:=ExtractFilePath(Result);
  Cache:=GetCache(ADirectory,true,false);
  ShortFilename:=ExtractFileName(Result);
  Result:=Cache.FindFile(ShortFilename,ctsfcAllCase);
  if Result='' then exit;
  Result:=Cache.Directory+Result;
end;

function TCTDirectoryCachePool.FindUnitInDirectory(const Directory,
  UnitName: string; AnyCase: boolean): string;
var
  Cache: TCTDirectoryCache;
begin
  Cache:=GetCache(Directory,true,false);
  Result:=Cache.FindUnitSource(UnitName,AnyCase);
  if Result='' then exit;
  Result:=Cache.Directory+Result;
end;

function TCTDirectoryCachePool.FindVirtualFile(const Filename: string): string;
begin
  if Assigned(OnFindVirtualFile) then
    Result:=OnFindVirtualFile(Filename)
  else
    Result:='';
end;

function TCTDirectoryCachePool.FindVirtualUnit(const UnitName: string): string;
var
  e: TCTPascalExtType;
begin
  for e:=Low(CTPascalExtension) to High(CTPascalExtension) do begin
    if CTPascalExtension[e]='' then continue;
    Result:=FindVirtualFile(UnitName+CTPascalExtension[e]);
    if Result<>'' then exit;
  end;
  Result:='';
end;

function TCTDirectoryCachePool.FindUnitSourceInCompletePath(
  const Directory: string; var UnitName, InFilename: string; AnyCase: boolean
  ): string;
var
  Cache: TCTDirectoryCache;
begin
  Cache:=GetCache(Directory,true,false);
  Result:=Cache.FindUnitSourceInCompletePath(UnitName,InFilename,AnyCase);
end;

function TCTDirectoryCachePool.FindCompiledUnitInCompletePath(
  const Directory: string; var ShortFilename: string; AnyCase: boolean
    ): string;
var
  Cache: TCTDirectoryCache;
begin
  Cache:=GetCache(Directory,true,false);
  Result:=Cache.FindCompiledUnitInCompletePath(ShortFilename,AnyCase);
end;

{ TCTDirectoryListing }

destructor TCTDirectoryListing.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TCTDirectoryListing.Clear;
begin
  if NameStarts<>nil then begin
    FreeMem(NameStarts);
    NameStarts:=nil;
    NamesLength:=0;
    FreeMem(Names);
    Names:=nil;
    NameCount:=0;
  end;
end;

function TCTDirectoryListing.CalcMemSize: PtrUInt;
begin
  Result:=PtrUInt(InstanceSize)
    +PtrUInt(NamesLength);
end;

{ TUnitNameLink }

function TUnitNameLink.CalcMemSize: PtrUInt;
begin
  Result:=PtrUInt(InstanceSize)
    +MemSizeString(UnitName)
    +MemSizeString(Filename);
end;

end.

