{ This file was automatically created by Lazarus. Do not edit!
This source is only used to compile and install the package.
 }

unit SynUni; 

interface

uses
  SynUniDesigner, SynUniHighlighter, SynUniReg, LazarusPackageIntf; 

implementation

procedure Register; 
begin
  RegisterUnit('SynUniHighlighter', @SynUniHighlighter.Register); 
  RegisterUnit('SynUniReg', @SynUniReg.Register); 
end; 

initialization
  RegisterPackage('SynUni', @Register); 
end.
