{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit LazDebuggerFpGdbmi;

interface

uses
  FpGdbmiDebugger, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('FpGdbmiDebugger', @FpGdbmiDebugger.Register);
end;

initialization
  RegisterPackage('LazDebuggerFpGdbmi', @Register);
end.
