{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit TurboPowerIPro;

interface

uses
  IpAnim, IpConst, Ipfilebroker, IpHtml, {$IFDEF Html_Print}IpHtmlPv,{$ENDIF} IpMsg, IpStrms, IpUtils,
  IpHtmlTabList, iphtmlprop, ipHtmlBlockLayout, ipHtmlTableLayout, 
  LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('Ipfilebroker', @Ipfilebroker.Register);
  RegisterUnit('IpHtml', @IpHtml.Register);
end;

initialization
  RegisterPackage('TurboPowerIPro', @Register);
end.
