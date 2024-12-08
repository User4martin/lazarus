unit project_workspace_options;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  // LCL
  Forms, Controls, LazProjPackWorkSpaceOptionsDsgn,
  // IdeIntf
  IDEOptEditorIntf, IDEOptionsIntf,
  // IdeProject
  Project;

type

  { TProjectWorkspaceOptionsFrame }

  TProjectWorkspaceOptionsFrame = class(TAbstractIDEOptionsEditor)
    LazProjPackWorkSpaceOptionsFrame1: TLazProjPackWorkSpaceOptionsFrame;
  private

  public
    function GetTitle: string; override;
    procedure Setup({%H-}ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

{$R *.lfm}

{ TProjectWorkspaceOptionsFrame }

function TProjectWorkspaceOptionsFrame.GetTitle: string;
begin
  Result := 'Workspace';
end;

procedure TProjectWorkspaceOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  LazProjPackWorkSpaceOptionsFrame1.SetUp;
end;

procedure TProjectWorkspaceOptionsFrame.ReadSettings(AOptions: TAbstractIDEOptions);
begin
  with (AOptions as TProjectIDEOptions) do begin
    LazProjPackWorkSpaceOptionsFrame1.TheWorkSpace := Project.WorkSpace;
  end;
end;

procedure TProjectWorkspaceOptionsFrame.WriteSettings(AOptions: TAbstractIDEOptions);
begin
  with (AOptions as TProjectIDEOptions) do begin
    Project.WorkSpace.Assign(LazProjPackWorkSpaceOptionsFrame1.TheWorkSpace);
  end;
end;

class function TProjectWorkspaceOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TProjectIDEOptions;
end;

initialization
  RegisterIDEOptionsEditor(GroupProject, TProjectWorkspaceOptionsFrame, ProjectOptionsWorkspace);

end.

