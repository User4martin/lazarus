{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit favorites;

interface

uses
  favorites_impl, favoritesstr, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('favorites_impl', @favorites_impl.Register);
end;

initialization
  RegisterPackage('favorites', @Register);
end.
