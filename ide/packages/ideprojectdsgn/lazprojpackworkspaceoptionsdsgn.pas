unit LazProjPackWorkSpaceOptionsDsgn;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, EditBtn, ProjPackWorkSpaceIntf;

type

  { TLazProjPackWorkSpaceOptionsFrame }

  TLazProjPackWorkSpaceOptionsFrame = class(TFrame)
    edFolder: TDirectoryEdit;
    lbFolder: TLabel;
  private
    FTheWorkSpace: TProjPackWorkSpace;
    function GetTheWorkSpace: TProjPackWorkSpace;
    procedure SetTheWorkSpace(AValue: TProjPackWorkSpace);

  public
    destructor Destroy; override;
    property TheWorkSpace: TProjPackWorkSpace read GetTheWorkSpace write SetTheWorkSpace;
    procedure SetUp;
  end;

implementation

{$R *.lfm}

{ TLazProjPackWorkSpaceOptionsFrame }

function TLazProjPackWorkSpaceOptionsFrame.GetTheWorkSpace: TProjPackWorkSpace;
begin
  if FTheWorkSpace = nil then
    FTheWorkSpace := TProjPackWorkSpace.CreateInstance;

  FTheWorkSpace.Folder := edFolder.Directory;
  Result := FTheWorkSpace;
end;

procedure TLazProjPackWorkSpaceOptionsFrame.SetTheWorkSpace(AValue: TProjPackWorkSpace);
begin
  if FTheWorkSpace = nil then
    FTheWorkSpace := TProjPackWorkSpace.CreateInstance;

  FTheWorkSpace.Assign(AValue);
  edFolder.Directory := FTheWorkSpace.Folder;
end;

destructor TLazProjPackWorkSpaceOptionsFrame.Destroy;
begin
  FTheWorkSpace.Free;
  inherited Destroy;
end;

procedure TLazProjPackWorkSpaceOptionsFrame.SetUp;
begin
  lbFolder.Caption := 'Workspace folder';
end;

end.

