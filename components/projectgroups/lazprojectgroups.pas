{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit lazprojectgroups;

interface

uses
  ProjectGroupIntf, ProjectGroup, ProjectGroupEditor, RegProjectGroup, 
  ProjectGroupStrConst, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('RegProjectGroup', @RegProjectGroup.Register);
end;

initialization
  RegisterPackage('lazprojectgroups', @Register);
end.
