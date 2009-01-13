unit BreakPropertyDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Buttons, DebuggerDlg, Debugger, ButtonPanel, EditBtn,
  BaseDebugManager, IDEContextHelpEdit, LazarusIDEStrConsts;

type

  { TBreakPropertyDlg }

  TBreakPropertyDlg = class(TDebuggerDlg)
    ButtonPanel: TButtonPanel;
    chkEnableGroups: TCheckBox;
    chkDisableGroups: TCheckBox;
    chkEvalExpression: TCheckBox;
    chkLogMessage: TCheckBox;
    chkActionBreak: TCheckBox;
    cmbGroup: TComboBox;
    edtEvalExpression: TEdit;
    edtLogMessage: TEdit;
    edtEnableGroups: TEditButton;
    edtDisableGroups: TEditButton;
    edtAutocontinueMS: TEdit;
    edtCondition: TEdit;
    edtCounter: TEdit;
    edtFilename: TEdit;
    edtLine: TEdit;
    gbActions: TGroupBox;
    lblMS: TLabel;
    lblFileName: TLabel;
    lblLine: TLabel;
    lblCondition: TLabel;
    lblHitCount: TLabel;
    lblGroup: TLabel;
    lblAutoContinue: TLabel;
    procedure btnHelpClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure BreakPointRemove(const ASender: TIDEBreakPoints;
      const ABreakpoint: TIDEBreakPoint);
    procedure BreakPointUpdate(const ASender: TIDEBreakPoints;
      const ABreakpoint: TIDEBreakPoint);
    procedure edtDisableGroupsButtonClick(Sender: TObject);
    procedure edtEnableGroupsButtonClick(Sender: TObject);
  private
    FBreakpointsNotification : TIDEBreakPointsNotification;
    FBreakpoint: TIDEBreakPoint;
  protected
    procedure DoEndUpdate; override;
    procedure UpdateInfo;
  public
    constructor Create(AOwner: TComponent; ABreakPoint: TIDEBreakPoint);overload;
    destructor Destroy; override;
  end;

implementation

{ TBreakPropertyDlg }

procedure TBreakPropertyDlg.BreakPointUpdate(
  const ASender: TIDEBreakPoints; const ABreakpoint: TIDEBreakPoint);
begin
  UpdateInfo;
end;

procedure TBreakPropertyDlg.btnHelpClick(Sender: TObject);
begin
  ShowContextHelpForIDE(Self);
end;

procedure TBreakPropertyDlg.BreakPointRemove(
  const ASender: TIDEBreakPoints; const ABreakpoint: TIDEBreakPoint);
begin
  if ABreakpoint = FBreakpoint
  then ModalResult := mrCancel;
end;

procedure TBreakPropertyDlg.btnOKClick(Sender: TObject);
var
  Actions: TIDEBreakPointActions;
begin
  if FBreakpoint = nil then Exit;

  FBreakpointsNotification.OnUpdate := nil;
  // filename
  // line
  FBreakpoint.SetLocation(edtFilename.Text, StrToIntDef(edtLine.Text, 1));
  // expression
  FBreakpoint.Expression := edtCondition.Text;
  // hitcount
  FBreakpoint.BreakHitCount := StrToIntDef(edtCounter.Text, FBreakpoint.HitCount);
  //auto continue
  FBreakpoint.AutoContinueTime := StrToIntDef(edtAutocontinueMS.Text, FBreakpoint.AutoContinueTime);
  // group
  FBreakpoint.Group := DebugBoss.BreakPointGroups.GetGroupByName(cmbGroup.Text);
  // actions
  Actions := [];
  if chkActionBreak.Checked then Include(Actions, bpaStop);
  if chkDisableGroups.Checked then Include(Actions, bpaDisableGroup);
  if chkEnableGroups.Checked then Include(Actions, bpaEnableGroup);
//  if chkEvalExpression.Checked then Include(Actions, bpaEValExpression);
//  if chkLogMessage.Checked then Include(Actions, bpaLogMessage);
  FBreakpoint.Actions := Actions;
end;

procedure TBreakPropertyDlg.DoEndUpdate;
begin
  inherited DoEndUpdate;
  UpdateInfo;
end;

procedure TBreakPropertyDlg.edtDisableGroupsButtonClick(Sender: TObject);
begin

end;

procedure TBreakPropertyDlg.edtEnableGroupsButtonClick(Sender: TObject);
begin

end;

procedure TBreakPropertyDlg.UpdateInfo;
var
  Actions: TIDEBreakPointActions;
begin
  if FBreakpoint = nil then Exit;
  // filename
  edtFilename.text := FBreakpoint.Source;
  // line
  if FBreakpoint.Line > 0
  then edtLine.Text := IntToStr(FBreakpoint.SourceLine)
  else edtLine.Text := '';
  // expression
  edtCondition.Text := FBreakpoint.Expression;
  // hitcount
  edtCounter.Text := IntToStr(FBreakpoint.BreakHitCount);
  // auto continue
  edtAutocontinueMS.Text := IntToStr(FBreakpoint.AutoContinueTime);
  // group
  if FBreakpoint.Group = nil
  then cmbGroup.Text := ''
  else cmbGroup.Text := FBreakpoint.Group.Name;

  // actions
  Actions := FBreakpoint.Actions;
  chkActionBreak.Checked := bpaStop in Actions;
  chkDisableGroups.Checked := bpaDisableGroup in Actions;
  chkEnableGroups.Checked := bpaEnableGroup in Actions;
//  chkEvalExpression.Checked := bpaEValExpression in Actions;
//  chkLogMessage.Checked := bpaLogMessage in Actions;
end;

constructor TBreakPropertyDlg.Create(AOwner: TComponent; ABreakPoint: TIDEBreakPoint);
begin
  inherited Create(AOwner);
  FBreakpoint := ABreakPoint;
  FBreakpointsNotification := TIDEBreakPointsNotification.Create;
  FBreakpointsNotification.AddReference;
  FBreakpointsNotification.OnUpdate := @BreakPointUpdate;
  FBreakpointsNotification.OnRemove := @BreakPointRemove;
  UpdateInfo;

  ButtonPanel.OKButton.Caption:= lisOkBtn;
  ButtonPanel.CancelButton.Caption:= dlgCancel;
  ButtonPanel.HelpButton.Caption:= lisPckEditHelp;

  ButtonPanel.OKButton.OnClick := @btnOKClick;
  ButtonPanel.HelpButton.OnClick := @btnHelpClick;
end;

destructor TBreakPropertyDlg.Destroy;
begin
  FBreakpointsNotification.OnUpdate := nil;
  FBreakpointsNotification.OnRemove := nil;
  FBreakpointsNotification.ReleaseReference;
  FBreakpointsNotification := nil;
  inherited Destroy;
end;

initialization
  {$I breakpropertydlg.lrs}

end.

