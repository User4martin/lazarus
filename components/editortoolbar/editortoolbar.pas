{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit editortoolbar;

interface

uses
  editortoolbar_impl, EdtTbConfigFrm, editortoolbar_str, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('editortoolbar_impl', @editortoolbar_impl.Register);
end;

initialization
  RegisterPackage('editortoolbar', @Register);
end.
