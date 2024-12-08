unit ProjPackWorkSpaceIntf;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type

  TProjPackWorkSpaceFileList = class;

  //TProjPackWorkSpaceCheckFileBeforeAdd = procedure(AFileName: String): boolean of object;
  TProjPackWorkSpaceFilesFound   = procedure(AFileList: TProjPackWorkSpaceFileList) of object;
  TProjPackWorkSpaceFilesRemoved = procedure(AFileList: TProjPackWorkSpaceFileList) of object;


  { TProjPackWorkSpaceFile }

  TProjPackWorkSpaceFile = class abstract
  protected
    procedure SetData(AValue: TObject); virtual; abstract;
    function GetData: TObject; virtual; abstract;
    function GetFileName: String; virtual; abstract;
  public
    //procedure PrepareRename(ANewFileName: String; ANewPath: String = ''); virtual; abstract;
    //procedure FinishRename; virtual; abstract;
    property FileName: String read GetFileName;
    property Data: TObject read GetData write SetData;
  end;

  { TProjPackWorkSpaceFileList }

  TProjPackWorkSpaceFileList = class abstract
  protected
    function GetFiles(AnIndex: integer): TProjPackWorkSpaceFile; virtual; abstract;
  public
    function Count: Integer; virtual; abstract;
    property Files [AnIndex: integer]: TProjPackWorkSpaceFile read GetFiles; default;
  end;

  { TProjPackWorkSpace }

  TProjPackWorkSpace = class;
  TProjPackWorkSpaceClass = class of TProjPackWorkSpace;

  TProjPackWorkSpace = class abstract
  strict private class var
    FInstanceClass: TProjPackWorkSpaceClass;
  protected
    function GetFolder: String; virtual; abstract;
    function GetPatterns: TStrings; virtual; abstract;
    function GetEnabled: Boolean; virtual; abstract;
    function GetFiles: TProjPackWorkSpaceFileList; virtual; abstract;
    function GetOnSettingsChanged: TNotifyEvent; virtual; abstract;
    function GetOnFilesFound: TProjPackWorkSpaceFilesFound; virtual; abstract;
    function GetOnFilesRemoved: TProjPackWorkSpaceFilesRemoved; virtual; abstract;
    procedure SetFolder(AValue: String); virtual; abstract;
    procedure SetOnSettingsChanged(AValue: TNotifyEvent); virtual; abstract;
    procedure SetOnFilesFound(AValue: TProjPackWorkSpaceFilesFound); virtual; abstract;
    procedure SetOnFilesRemoved(AValue: TProjPackWorkSpaceFilesRemoved); virtual; abstract;
  public
    class procedure LazarusIdeSetInstanceClass(AClass: TProjPackWorkSpaceClass);
    class function CreateInstance: TProjPackWorkSpace;
  public
    constructor Create; virtual; abstract;

    procedure Scan; virtual; abstract;
    procedure Assign(AnOtherWorkspace: TProjPackWorkSpace); virtual; abstract;
    procedure BeginUpdate; virtual; abstract;
    procedure EndUpdate; virtual; abstract;

    property Folder: String read GetFolder write SetFolder;
    property Patterns: TStrings read GetPatterns;
    property Enabled: Boolean read GetEnabled;
    property Files: TProjPackWorkSpaceFileList read GetFiles;
    property OnSettingsChanged: TNotifyEvent read GetOnSettingsChanged write SetOnSettingsChanged;
    property OnFilesFound: TProjPackWorkSpaceFilesFound read GetOnFilesFound write SetOnFilesFound;
    property OnFilesRemoved: TProjPackWorkSpaceFilesRemoved read GetOnFilesRemoved write SetOnFilesRemoved;
  end;


implementation

class procedure TProjPackWorkSpace.LazarusIdeSetInstanceClass(AClass: TProjPackWorkSpaceClass);
begin
  if FInstanceClass <> nil then raise Exception.Create('Only called by IDE');
  FInstanceClass := AClass;
end;

class function TProjPackWorkSpace.CreateInstance: TProjPackWorkSpace;
begin
  Result := FInstanceClass.Create;
end;

end.

