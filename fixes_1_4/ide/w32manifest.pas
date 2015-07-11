{
 /***************************************************************************
                        w32manifest.pas  -  Lazarus IDE unit
                        ---------------------------------------
              TProjectXPManifest is responsible for the inclusion of the 
                   manifest in windows executables.


 ***************************************************************************/

 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************

  The manifest file is needed for windows XP themes.
  The file is created in the directory, where the project exe is created.
}
unit W32Manifest;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Laz2_XMLCfg, Process, LCLProc, Controls, Forms,
  CodeToolManager, LazConf, LResources,
  ProjectResourcesIntf, resource;
   
type
  TXPManifestExecutionLevel = (
    xmelAsInvoker,
    xmelHighestAvailable,
    xmelRequireAdministrator
  );

  { TProjectXPManifest }

  TProjectXPManifest = class(TAbstractProjectResource)
  private
    FExecutionLevel: TXPManifestExecutionLevel;
    FIsDpiaAware: boolean;
    FUIAccess: Boolean;
    FUseManifest: boolean;
    procedure SetDpiAware(const AValue: boolean);
    procedure SetExecutionLevel(AValue: TXPManifestExecutionLevel);
    procedure SetUIAccess(AValue: Boolean);
    procedure SetUseManifest(const AValue: boolean);
  public
    constructor Create; override;
    function UpdateResources(AResources: TAbstractProjectResources; const {%H-}MainFilename: string): Boolean; override;
    procedure WriteToProjectFile(AConfig: {TXMLConfig}TObject; Path: String); override;
    procedure ReadFromProjectFile(AConfig: {TXMLConfig}TObject; Path: String); override;

    property UseManifest: boolean read FUseManifest write SetUseManifest;
    property DpiAware: boolean read FIsDpiaAware write SetDpiAware;
    property ExecutionLevel: TXPManifestExecutionLevel read FExecutionLevel write SetExecutionLevel;
    property UIAccess: Boolean read FUIAccess write SetUIAccess;
  end;

const
  ExecutionLevelToStr: array[TXPManifestExecutionLevel] of String = (
    'asInvoker',
    'highestAvailable',
    'requireAdministrator'
  );
implementation

const
  sManifestFileDataStart: String =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'#$D#$A+
    '<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">'#$D#$A+
    ' <assemblyIdentity version="1.0.0.0" processorArchitecture="*" name="CompanyName.ProductName.YourApp" type="win32"/>'#$D#$A+
    ' <description>Your application description here.</description>'#$D#$A+
    ' <dependency>'#$D#$A+
    '  <dependentAssembly>'#$D#$A+
    '   <assemblyIdentity type="win32" name="Microsoft.Windows.Common-Controls" version="6.0.0.0" processorArchitecture="*" publicKeyToken="6595b64144ccf1df" language="*"/>'#$D#$A+
    '  </dependentAssembly>'#$D#$A+
    ' </dependency>'#$D#$A+
    ' <trustInfo xmlns="urn:schemas-microsoft-com:asm.v3">'#$D#$A+
    '  <security>'#$D#$A+
    '   <requestedPrivileges>'#$D#$A+
    '    <requestedExecutionLevel level="%s" uiAccess="%s"/>'#$D#$A+
    '   </requestedPrivileges>'#$D#$A+
    '  </security>'#$D#$A+
    ' </trustInfo>'#$D#$A;
  sManifestFileDataEnd: String =
    '</assembly>';
  sManifestFileDataDpiAware: String =
    ' <asmv3:application xmlns:asmv3="urn:schemas-microsoft-com:asm.v3">'#$D#$A+
    '  <asmv3:windowsSettings xmlns="http://schemas.microsoft.com/SMI/2005/WindowsSettings">'#$D#$A+
    '   <dpiAware>true</dpiAware>'#$D#$A+
    '  </asmv3:windowsSettings>'#$D#$A+
    ' </asmv3:application>'#$D#$A;

procedure TProjectXPManifest.SetUseManifest(const AValue: boolean);
begin
  if FUseManifest = AValue then exit;
  FUseManifest := AValue;
  Modified := True;
end;

procedure TProjectXPManifest.SetDpiAware(const AValue: boolean);
begin
  if FIsDpiaAware = AValue then exit;
  FIsDpiaAware := AValue;
  Modified := True;
end;

procedure TProjectXPManifest.SetExecutionLevel(AValue: TXPManifestExecutionLevel);
begin
  if FExecutionLevel = AValue then Exit;
  FExecutionLevel := AValue;
  Modified := True;
end;

procedure TProjectXPManifest.SetUIAccess(AValue: Boolean);
begin
  if FUIAccess = AValue then Exit;
  FUIAccess := AValue;
  Modified := True;
end;

constructor TProjectXPManifest.Create;
begin
  inherited Create;
  UseManifest := False;
  DpiAware := False;
  ExecutionLevel := xmelAsInvoker;
  UIAccess := False;
end;

function TProjectXPManifest.UpdateResources(AResources: TAbstractProjectResources;
  const MainFilename: string): Boolean;
var
  Res: TGenericResource;
  RName, RType: TResourceDesc;
  ManifestFileData: String;
begin
  Result := True;
  if UseManifest then
  begin
    RType := TResourceDesc.Create(RT_MANIFEST);
    RName := TResourceDesc.Create(1);
    Res := TGenericResource.Create(RType, RName);
    RType.Free; //no longer needed
    RName.Free;
    ManifestFileData := Format(sManifestFileDataStart, [ExecutionLevelToStr[ExecutionLevel], BoolToStr(UIAccess, 'true', 'false')]);
    if DpiAware then
      ManifestFileData := ManifestFileData + sManifestFileDataDpiAware;
    ManifestFileData := ManifestFileData + sManifestFileDataEnd;
    Res.RawData.Write(ManifestFileData[1], Length(ManifestFileData));
    AResources.AddSystemResource(Res);
  end;
end;

procedure TProjectXPManifest.WriteToProjectFile(AConfig: TObject; Path: String);
begin
  TXMLConfig(AConfig).SetDeleteValue(Path+'General/UseXPManifest/Value', UseManifest, False);
  TXMLConfig(AConfig).SetDeleteValue(Path+'General/XPManifest/DpiAware/Value', DpiAware, False);
  TXMLConfig(AConfig).SetDeleteValue(Path+'General/XPManifest/ExecutionLevel/Value', Ord(ExecutionLevel), 0);
  TXMLConfig(AConfig).SetDeleteValue(Path+'General/XPManifest/UIAccess/Value', UIAccess, False);
end;

procedure TProjectXPManifest.ReadFromProjectFile(AConfig: TObject; Path: String);
begin
  UseManifest := TXMLConfig(AConfig).GetValue(Path+'General/UseXPManifest/Value', False);
  DpiAware := TXMLConfig(AConfig).GetValue(Path+'General/XPManifest/DpiAware/Value', False);
  ExecutionLevel := TXPManifestExecutionLevel(TXMLConfig(AConfig).GetValue(Path+'General/XPManifest/ExecutionLevel/Value', 0));
  UIAccess := TXMLConfig(AConfig).GetValue(Path+'General/XPManifest/UIAccess/Value', False);
end;

initialization
  RegisterProjectResource(TProjectXPManifest);

end.

