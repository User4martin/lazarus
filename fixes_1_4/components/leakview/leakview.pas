{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit leakview;

interface

uses
  HeapTrcView, leakinfo, DbgInfoReader, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('HeapTrcView', @HeapTrcView.Register);
end;

initialization
  RegisterPackage('leakview', @Register);
end.
