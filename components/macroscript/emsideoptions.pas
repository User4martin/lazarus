unit EMSIdeOptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls, IDEOptionsIntf,
  {$IFnDEF PasScriptNotAvail}
  SrcEditorIntf,
  {$ENDIF}
  EMScriptMacro, EMSStrings;

type

  { TEMSIdeOptionsFrame }

  TEMSIdeOptionsFrame = class(TAbstractIDEOptionsEditor)
    btnActivate: TButton;
    lblStatus: TLabel;
    procedure btnActivateClick(Sender: TObject);
  private

  public
    function GetTitle: String; override;
    procedure Setup({%H-}ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings({%H-}AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings({%H-}AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

{$R *.lfm}

{ EMSIdeOptionsFrame }

procedure TEMSIdeOptionsFrame.btnActivateClick(Sender: TObject);
var
  cfg: TEMSConfig;
begin
  cfg := GetEMSConf;
  cfg.SelfTestFailed := 0;
  cfg.SelfTestActive := False;
  cfg.Save;
  ReadSettings(nil);
end;

function TEMSIdeOptionsFrame.GetTitle: String;
begin
  Result := EMSStatusTitle;
end;

procedure TEMSIdeOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  btnActivate.Caption := EMSBtnTestAgain;
end;

procedure TEMSIdeOptionsFrame.ReadSettings(AOptions: TAbstractIDEOptions);
{$IFnDEF PasScriptNotAvail}
var
  cfg: TEMSConfig;
{$ENDIF}
begin
{$IFDEF PasScriptNotAvail}
  lblStatus.Caption := EMSNotSupported;
  btnActivate.Enabled := True;
{$ELSE}
  cfg := GetEMSConf;
  if cfg.SelfTestFailed >= EMSVersion then begin
    lblStatus.Caption := EMSNotActive;
    btnActivate.Enabled := True;
  end
  else
  if EditorMacroPlayerClass = TEMSEditorMacro then begin
    lblStatus.Caption := EMSActive;
    btnActivate.Enabled := False;
  end
  else
  begin
    lblStatus.Caption := EMSPending;
    btnActivate.Enabled := False;
  end;
{$ENDIF}
end;

procedure TEMSIdeOptionsFrame.WriteSettings(AOptions: TAbstractIDEOptions);
begin
  //
end;

class function TEMSIdeOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TEMSConfig;
end;

end.

