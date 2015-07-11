unit ResultDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, Buttons, ClipBrd, LCLType, LCLProc, SynEdit, SynHighlighterPo,
  PoFamilies, GraphStat, PoCheckerConsts, PoCheckerSettings;

type

  { TResultDlgForm }

  TResultDlgForm = class(TForm)
    GraphStatBtn: TBitBtn;
    CopyBtn: TBitBtn;
    SaveBtn: TBitBtn;
    CloseBtn: TBitBtn;
    Panel1: TPanel;
    SaveDialog: TSaveDialog;
    FLog: TStringList;
    LogMemo: TSynEdit;
    procedure CopyBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure GraphStatBtnClick(Sender: TObject);
    procedure SaveBtnClick(Sender: TObject);
  private
    PoHL: TSynPoSyn;
    FPoFamilyStats: TPoFamilyStats;
    FSettings: TPoCheckerSettings;
    procedure SaveToFile;
    procedure LoadConfig;
    procedure SaveConfig;
  public
    property Log: TStringList read FLog write FLog;
    property PoFamilyStats: TPoFamilyStats read FPoFamilyStats write FPoFamilyStats;
    property Settings: TPoCheckerSettings read FSettings write FSettings;
  end; 

implementation

{$R *.lfm}

{ TResultDlgForm }

procedure TResultDlgForm.FormCreate(Sender: TObject);
begin
  Caption := sResults;
  LogMemo.Lines.Clear;
  LogMemo.Align := alClient;
  FLog := TStringList.Create;
  PoHL := TSynPoSyn.Create(Self);
  LogMemo.Highlighter := PoHL;
  SaveBtn.Caption := sSaveCaption;
  CopyBtn.Caption := sCopyCaption;
  GraphStatBtn.Caption := sShowStatGraph;
end;

procedure TResultDlgForm.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  FLog.Clear;
end;

procedure TResultDlgForm.CopyBtnClick(Sender: TObject);
begin
  ClipBoard.AsText := LogMemo.Text;
end;

procedure TResultDlgForm.FormDestroy(Sender: TObject);
begin
  FLog.Free;
  SaveConfig;
end;

procedure TResultDlgForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_Tab) and (Shift = []) and LogMemo.Focused then
  begin
    //Workaroud: cannot tab out of LogMemo
    CopyBtn.SetFocus;
    //debugln('Tab');
    Key := 0;
  end;
end;

procedure TResultDlgForm.FormShow(Sender: TObject);
begin
  LogMemo.Lines.Assign(FLog);
  GraphStatBtn.Visible := (PoFamilyStats <> nil) and (PoFamilyStats.Count > 0);
  LoadConfig;
  WindowState := Settings.ResultsFormWindowState;
end;

procedure TResultDlgForm.GraphStatBtnClick(Sender: TObject);
var
  mr: TModalResult;
begin
  GraphStatForm := TGraphStatForm.Create(nil);
  try
    GraphStatForm.PoFamilyStats := Self.PoFamilyStats;
    GraphStatForm.Settings := Self.Settings;
    mr := GraphStatForm.ShowModal;
    if mr = mrOpenEditorFile then ModalResult := mr; // To inform pocheckermain
  finally
    FreeAndNil(GraphStatForm);
  end;
end;

procedure TResultDlgForm.SaveBtnClick(Sender: TObject);
begin
  if SaveDialog.Execute then
  begin
    try
      LogMemo.Lines.SaveToFile(SaveDialog.FileName);
    except
      on E: EStreamError do MessageDlg('Po-checker',Format(sSaveError,[SaveDialog.FileName]),mtError, [mbOk],0);
    end;
  end;
end;

procedure TResultDlgForm.SaveToFile;
begin
  if SaveDialog.Execute then
  begin
    try
      LogMemo.Lines.SaveToFile(SaveDialog.FileName);
    except
      MessageDlg('Po-checker',Format(sSaveError,[SaveDialog.FileName]), mtError, [mbOk], 0);
    end;
  end;
end;

procedure TResultDlgForm.LoadConfig;
var
  ARect: TRect;
begin
  if not Assigned(FSettings) then Exit;
  ARect := FSettings.ResultsFormGeometry;
  //debugln('TResultDlgForm.LoadConfig: ARect = ',dbgs(ARect));
  if not IsDefaultRect(ARect) and IsValidRect(ARect) then
  begin
    ARect := FitToRect(ARect, Screen.WorkAreaRect);
    BoundsRect := ARect;
  end;
end;

procedure TResultDlgForm.SaveConfig;
begin
  //debugln('TResultDlgForm.SaveConfig: BoundsRect = ',dbgs(BoundsRect));
  if not Assigned(FSettings) then Exit;
  Settings.ResultsFormWindowState := WindowState;
  if (WindowState = wsNormal) then
    Settings.ResultsFormGeometry := BoundsRect
  else
    Settings.ResultsFormGeometry := Rect(RestoredLeft, RestoredTop, RestoredLeft + RestoredWidth, RestoredTop + RestoredHeight);
end;

end.

