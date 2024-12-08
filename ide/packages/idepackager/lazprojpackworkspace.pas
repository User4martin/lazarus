unit LazProjPackWorkSpace;

{$mode objfpc}{$H+}

interface

uses SysUtils, Classes, fgl, ProjPackWorkSpaceIntf, FileUtil;

type

  TLazProjPackWorkSpaceFileList = class;

  { TLazProjPackWorkSpaceFile }

  TLazProjPackWorkSpaceFile = class(TProjPackWorkSpaceFile)
  private
    FFileName: String;
    FData: TObject;
  protected
    procedure SetData(AValue: TObject); override;
    function GetData: TObject; override;
    function GetFileName: String; override;
  public
    constructor Create(AFileName: String);
    //procedure PrepareRename(ANewFileName: String; ANewPath: String = ''); override;
    //procedure FinishRename; override;
  end;

  { TLazProjPackWorkSpaceFileList }

  TLazProjPackWorkSpaceFileList = class(TProjPackWorkSpaceFileList)
  private type
    TInternalLazProjPackWorkSpaceFileList = specialize TFPGObjectList<TLazProjPackWorkSpaceFile>;
  private
    FList: TInternalLazProjPackWorkSpaceFileList;
  protected
    function GetFiles(AnIndex: integer): TProjPackWorkSpaceFile; override;
    procedure Clear;
  public
    constructor Create;
    destructor Destroy; override;
    function Count: Integer; override;
  end;

  { TLazProjPackWorkSpace }

  TLazProjPackWorkSpace = class(TProjPackWorkSpace)
  private
    FFolder: String;
    FPatterns: TStringList;
    FFiles: TLazProjPackWorkSpaceFileList;
    FOnSettingsChanged: TNotifyEvent;
    FOnFilesFound: TProjPackWorkSpaceFilesFound;
    FOnFilesRemoved: TProjPackWorkSpaceFilesRemoved;
    FUpdateing: integer;
    FSettingsChanged: boolean;
    procedure DoPatternsChanged(Sender: TObject);
  protected
    procedure DoSettingsChanged;
    function GetFolder: String; override;
    function GetPatterns: TStrings; override;
    function GetEnabled: Boolean; override;
    function GetFiles: TProjPackWorkSpaceFileList; override;
    function GetOnSettingsChanged: TNotifyEvent; override;
    function GetOnFilesFound: TProjPackWorkSpaceFilesFound; override;
    function GetOnFilesRemoved: TProjPackWorkSpaceFilesRemoved; override;
    procedure SetFolder(AValue: String); override;
    procedure SetOnSettingsChanged(AValue: TNotifyEvent); override;
    procedure SetOnFilesFound(AValue: TProjPackWorkSpaceFilesFound); override;
    procedure SetOnFilesRemoved(AValue: TProjPackWorkSpaceFilesRemoved); override;

    procedure ClearFiles;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Scan; override;
    procedure Assign(AnOtherWorkspace: TProjPackWorkSpace); override;
    procedure BeginUpdate; override;
    procedure EndUpdate; override;
  end;

implementation

{ TLazProjPackWorkSpaceFile }

procedure TLazProjPackWorkSpaceFile.SetData(AValue: TObject);
begin
  FData := AValue;
end;

function TLazProjPackWorkSpaceFile.GetData: TObject;
begin
  Result := FData;
end;

function TLazProjPackWorkSpaceFile.GetFileName: String;
begin
  Result := FFileName;
end;

constructor TLazProjPackWorkSpaceFile.Create(AFileName: String);
begin
  FFileName := AFileName;
end;

{ TLazProjPackWorkSpaceFileList }

function TLazProjPackWorkSpaceFileList.GetFiles(AnIndex: integer): TProjPackWorkSpaceFile;
begin
  Result := FList[AnIndex];
end;

procedure TLazProjPackWorkSpaceFileList.Clear;
var
  i: Integer;
begin
  for i := 0 to FList.Count - 1 do
    FList[i].Free;
  FList.Clear;
end;

constructor TLazProjPackWorkSpaceFileList.Create;
begin
  FList := TInternalLazProjPackWorkSpaceFileList.Create(False);
end;

destructor TLazProjPackWorkSpaceFileList.Destroy;
begin
  inherited Destroy;
  FList.Free;
end;

function TLazProjPackWorkSpaceFileList.Count: Integer;
begin
  Result := FList.Count;
end;

{ TLazProjPackWorkSpace }

procedure TLazProjPackWorkSpace.DoPatternsChanged(Sender: TObject);
begin
  DoSettingsChanged;
end;

procedure TLazProjPackWorkSpace.DoSettingsChanged;
begin
  FSettingsChanged := FUpdateing > 0;
  if FSettingsChanged then
    exit;

  if FOnSettingsChanged <> nil then
    FOnSettingsChanged(Self);
end;

function TLazProjPackWorkSpace.GetFolder: String;
begin
  Result := FFolder;
end;

function TLazProjPackWorkSpace.GetPatterns: TStrings;
begin
  Result := FPatterns;
end;

function TLazProjPackWorkSpace.GetEnabled: Boolean;
begin
  Result := FFolder <> '';
end;

function TLazProjPackWorkSpace.GetFiles: TProjPackWorkSpaceFileList;
begin
  Result := FFiles;
end;

function TLazProjPackWorkSpace.GetOnSettingsChanged: TNotifyEvent;
begin
  Result := FOnSettingsChanged;
end;

function TLazProjPackWorkSpace.GetOnFilesFound: TProjPackWorkSpaceFilesFound;
begin
  Result := FOnFilesFound;
end;

function TLazProjPackWorkSpace.GetOnFilesRemoved: TProjPackWorkSpaceFilesRemoved;
begin
  Result := FOnFilesRemoved;
end;

procedure TLazProjPackWorkSpace.SetFolder(AValue: String);
begin
  if FFolder = AValue then
    exit;

  ClearFiles;
  FFolder := AValue;
  DoSettingsChanged;
end;

procedure TLazProjPackWorkSpace.SetOnSettingsChanged(AValue: TNotifyEvent);
begin
  FOnSettingsChanged := AValue;
end;

procedure TLazProjPackWorkSpace.SetOnFilesFound(AValue: TProjPackWorkSpaceFilesFound);
begin
  FOnFilesFound := AValue;
end;

procedure TLazProjPackWorkSpace.SetOnFilesRemoved(AValue: TProjPackWorkSpaceFilesRemoved);
begin
  FOnFilesRemoved := AValue;
end;

procedure TLazProjPackWorkSpace.ClearFiles;
begin
  FFiles.Clear;
end;

constructor TLazProjPackWorkSpace.Create;
begin
  FPatterns := TStringList.Create;
  FPatterns.OnChange := @DoPatternsChanged;
  FFiles    := TLazProjPackWorkSpaceFileList.Create;
end;

destructor TLazProjPackWorkSpace.Destroy;
begin
  ClearFiles;
  inherited Destroy;
  FPatterns.Free;
  FFiles.Free;
end;

type
  TLazProjPackFileSearcher = class(TFileSearcher)
  private
    FFiles: TLazProjPackWorkSpaceFileList;
  protected
    procedure DoFileFound; override;
  public
    constructor Create(AFiles: TLazProjPackWorkSpaceFileList);
  end;

{ TLazProjPackFileSearcher }

procedure TLazProjPackFileSearcher.DoFileFound;
begin
  FFiles.FList.Add(TLazProjPackWorkSpaceFile.Create(FileName));
  inherited DoFileFound;
end;

constructor TLazProjPackFileSearcher.Create(AFiles: TLazProjPackWorkSpaceFileList);
begin
  FFiles := AFiles;
  inherited Create;
end;

procedure TLazProjPackWorkSpace.Scan;
var
  s: TLazProjPackFileSearcher;
begin
  ClearFiles;
  s := TLazProjPackFileSearcher.Create(FFiles);
  s.MaskSeparator := ';';
  s.Search(FFolder, '*.pas;*.pp;*.lpr;*.inc', True);
  s.Destroy;
end;

procedure TLazProjPackWorkSpace.Assign(AnOtherWorkspace: TProjPackWorkSpace);
begin
  BeginUpdate;
  ClearFiles;
  if AnOtherWorkspace = nil then begin
    FFolder := '';
    FPatterns.Clear;
  end
  else begin
    FFolder := AnOtherWorkspace.Folder;
    FPatterns.Assign(AnOtherWorkspace.Patterns);
  end;
  DoSettingsChanged;
  EndUpdate;
end;

procedure TLazProjPackWorkSpace.BeginUpdate;
begin
  inc(FUpdateing);
end;

procedure TLazProjPackWorkSpace.EndUpdate;
begin
  dec(FUpdateing);
  if FUpdateing = 0 then begin
    if FSettingsChanged then
      DoSettingsChanged;
  end;
end;

initialization
  TProjPackWorkSpace.LazarusIdeSetInstanceClass(TLazProjPackWorkSpace);

end.

