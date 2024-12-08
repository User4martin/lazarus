{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit IdeProjectDsgn;

{$warn 5023 off : no warning about unused units}
interface

uses
  LazProjPackWorkSpaceOptionsDsgn, project_workspace_options, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('IdeProjectDsgn', @Register);
end.
