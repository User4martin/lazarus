{ $Id: carbonwsstdctrls.pp 15309 2008-06-04 22:12:59Z vincents $}
{
 *****************************************************************************
 *                              CocoaWSStdCtrls.pp                           *
 *                              ---------------                              *
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit CocoaWSStdCtrls;

{$mode objfpc}{$H+}
{$modeswitch objectivec1}
{$modeswitch objectivec2}

interface

uses
  // Libs
  MacOSAll, CocoaAll, Classes, sysutils,
  // LCL
  Controls, StdCtrls, Graphics, LCLType, LMessages, LCLProc, LCLMessageGlue,
  LazUtf8Classes,
  // Widgetset
  WSStdCtrls, WSLCLClasses, WSControls, WSProc,
  // LCL Cocoa
  CocoaWSCommon, CocoaPrivate, CocoaUtils;

type

  { TCocoaWSScrollBar }

  TCocoaWSScrollBar = class(TWSScrollBar)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure SetKind(const AScrollBar: TCustomScrollBar; const AIsHorizontal: Boolean); override;
    class procedure SetParams(const AScrollBar: TCustomScrollBar); override;
  end;

  { TCocoaWSCustomGroupBox }

  TCocoaWSCustomGroupBox = class(TWSCustomGroupBox)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
  end;

  { TLCLComboboxCallback }

  TLCLComboboxCallback = class(TLCLCommonCallback, IComboBoxCallback)
    procedure ComboBoxWillPopUp;
    procedure ComboBoxWillDismiss;
    procedure ComboBoxSelectionDidChange;
    procedure ComboBoxSelectionIsChanging;
  end;

  { TCocoaWSCustomComboBox }

  TCocoaWSCustomComboBox = class(TWSCustomComboBox)
  published
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
    {class function  GetSelStart(const ACustomComboBox: TCustomComboBox): integer; override;
    class function  GetSelLength(const ACustomComboBox: TCustomComboBox): integer; override;}
    class function  GetItemIndex(const ACustomComboBox: TCustomComboBox): integer; override;
    {class function  GetMaxLength(const ACustomComboBox: TCustomComboBox): integer; override;

    class procedure SetSelStart(const ACustomComboBox: TCustomComboBox; NewStart: integer); override;
    class procedure SetSelLength(const ACustomComboBox: TCustomComboBox; NewLength: integer); override;}
    class procedure SetItemIndex(const ACustomComboBox: TCustomComboBox; NewIndex: integer); override;
    {class procedure SetMaxLength(const ACustomComboBox: TCustomComboBox; NewLength: integer); override;
    class procedure SetStyle(const ACustomComboBox: TCustomComboBox; NewStyle: TComboBoxStyle); override;}
    class procedure SetReadOnly(const ACustomComboBox: TCustomComboBox; NewReadOnly: boolean); override;
    class procedure SetDropDownCount(const ACustomComboBox: TCustomComboBox; NewCount: Integer); override;

    class function  GetItems(const ACustomComboBox: TCustomComboBox): TStrings; override;
    {class procedure Sort(const ACustomComboBox: TCustomComboBox; AList: TStrings; IsSorted: boolean); override;}

    class function GetItemHeight(const ACustomComboBox: TCustomComboBox): Integer; override;
    class procedure SetItemHeight(const ACustomComboBox: TCustomComboBox; const AItemHeight: Integer); override;
    class procedure GetPreferredSize(
       const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer;
       WithThemeSpace: Boolean); override;

  end;

  { TCocoaWSCustomListBox }

  TCocoaWSCustomListBox = class(TWSCustomListBox)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
    {class function GetIndexAtXY(const ACustomListBox: TCustomListBox; X, Y: integer): integer; override;  }
    class function GetItemIndex(const ACustomListBox: TCustomListBox): integer; override;
    class function GetItemRect(const ACustomListBox: TCustomListBox; Index: integer; var ARect: TRect): boolean; override;
   { class function GetSelCount(const ACustomListBox: TCustomListBox): integer; override;
    class function GetSelected(const ACustomListBox: TCustomListBox; const AIndex: integer): boolean; override;}
    class function GetStrings(const ACustomListBox: TCustomListBox): TStrings; override;
    {class function GetTopIndex(const ACustomListBox: TCustomListBox): integer; override;

    class procedure SelectItem(const ACustomListBox: TCustomListBox; AIndex: integer; ASelected: boolean); override;
    class procedure SetBorderStyle(const AWinControl: TWinControl; const ABorderStyle: TBorderStyle); override;
    //class procedure SetBorder(const ACustomListBox: TCustomListBox); override;
    class procedure SetItemIndex(const ACustomListBox: TCustomListBox; const AIndex: integer); override;
    class procedure SetSelectionMode(const ACustomListBox: TCustomListBox; const AExtendedSelect, AMultiSelect: boolean); override;
    class procedure SetStyle(const ACustomListBox: TCustomListBox); override;
    class procedure SetSorted(const ACustomListBox: TCustomListBox; AList: TStrings; ASorted: boolean); override;
    class procedure SetTopIndex(const ACustomListBox: TCustomListBox; const NewTopIndex: integer); override;}
  end;

  { TCocoaWSCustomEdit }

  TCocoaWSCustomEdit = class(TWSCustomEdit)
  published
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;

    class function  GetSelStart(const ACustomEdit: TCustomEdit): integer; override;
    class function  GetSelLength(const ACustomEdit: TCustomEdit): integer; override;

    {class procedure SetCharCase(const ACustomEdit: TCustomEdit; NewCase: TEditCharCase); override;
    class procedure SetEchoMode(const ACustomEdit: TCustomEdit; NewMode: TEchoMode); override;
    class procedure SetMaxLength(const ACustomEdit: TCustomEdit; NewLength: integer); override;}
    class procedure SetPasswordChar(const ACustomEdit: TCustomEdit; NewChar: char); override;
    class procedure SetReadOnly(const ACustomEdit: TCustomEdit; NewReadOnly: boolean); override;
    {class procedure SetSelStart(const ACustomEdit: TCustomEdit; NewStart: integer); override;
    class procedure SetSelLength(const ACustomEdit: TCustomEdit; NewLength: integer); override;}
  end;
  
  { TCocoaWSCustomMemo }

  TCocoaWSCustomMemo = class(TWSCustomMemo)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
    class function GetStrings(const ACustomMemo: TCustomMemo): TStrings; override;

    class function GetSelStart(const ACustomEdit: TCustomEdit): integer; override;
    class function GetSelLength(const ACustomEdit: TCustomEdit): integer; override;

    class procedure AppendText(const ACustomMemo: TCustomMemo; const AText: string); override;
    class procedure SetScrollbars(const ACustomMemo: TCustomMemo; const NewScrollbars: TScrollStyle); override;
    class procedure SetWordWrap(const ACustomMemo: TCustomMemo; const NewWordWrap: boolean); override;
    class procedure SetReadOnly(const ACustomEdit: TCustomEdit; NewReadOnly: boolean); override;

    class procedure SetText(const AWinControl: TWinControl; const AText: String); override;
    class function GetText(const AWinControl: TWinControl; var AText: String): Boolean; override;
  end;

  { TLCLButtonCallback }

  TLCLButtonCallback = class(TLCLCommonCallback, IButtonCallback)
  public
    procedure ButtonClick; virtual;
  end;
  TLCLButtonCallBackClass = class of TLCLButtonCallBack;

  { TLCLListBoxCallback }

  TLCLListBoxCallback = class(TLCLCommonCallback, IListBoxCallback)
  public
    procedure SelectionChanged; virtual;
  end;
  TLCLListBoxCallBackClass = class of TLCLListBoxCallBack;

  { TCocoaWSButton }

  TCocoaWSButton = class(TWSButton)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure SetDefault(const AButton: TCustomButton; ADefault: Boolean); override;
    class procedure SetText(const AWinControl: TWinControl; const AText: String); override;
  end;

  { TLCLCheckBoxCallback }

  TLCLCheckBoxCallback = class(TLCLButtonCallBack)
  public
    procedure ButtonClick; override;
  end;

  { TCocoaWSCustomCheckBox }

  TCocoaWSCustomCheckBox = class(TWSCustomCheckBox)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
    class function RetrieveState(const ACustomCheckBox: TCustomCheckBox): TCheckBoxState; override;
    class procedure SetState(const ACustomCheckBox: TCustomCheckBox; const NewState: TCheckBoxState); override;
    //
    class procedure GetPreferredSize(const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer; {%H-}WithThemeSpace: Boolean); override;
    class procedure SetText(const AWinControl: TWinControl; const AText: String); override;
  end;

  { TCocoaWSToggleBox }

  TCocoaWSToggleBox = class(TWSToggleBox)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
  end;

  { TLCLRadioButtonCallback }

  TLCLRadioButtonCallback = class(TLCLCheckBoxCallback)
  public
    procedure ButtonClick; override;
  end;

  { TCocoaWSRadioButton }

  TCocoaWSRadioButton = class(TWSRadioButton)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
  end;

  { TCocoaWSCustomStaticText }

  TCocoaWSCustomStaticText = class(TWSCustomStaticText)
  private
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
//    class procedure SetAlignment(const ACustomStaticText: TCustomStaticText; const NewAlignment: TAlignment); override;
  end;

function AllocTextView(ATarget: TWinControl; const AParams: TCreateParams; fieldEditor: Boolean): NSTextView;
function AllocButton(const ATarget: TWinControl; const ACallBackClass: TLCLButtonCallBackClass; const AParams: TCreateParams; btnBezel: NSBezelStyle; btnType: NSButtonType): NSButton;
function AllocTextField(ATarget: TWinControl; const AParams: TCreateParams): TCocoaTextField;
function AllocSecureTextField(ATarget: TWinControl; const AParams: TCreateParams): TCocoaSecureTextField;

function GetListBox(AWinControl: TWinControl): TCocoaListBox;

implementation

const
  VerticalScrollerVisible: array[TScrollStyle] of boolean = (
 {ssNone          } false,
 {ssHorizontal    } false,
 {ssVertical      } true,
 {ssBoth          } true,
 {ssAutoHorizontal} false,
 {ssAutoVertical  } true,
 {ssAutoBoth      } true
  );

  HorizontalScrollerVisible: array[TScrollStyle] of boolean = (
 {ssNone          } false,
 {ssHorizontal    } true,
 {ssVertical      } false,
 {ssBoth          } true,
 {ssAutoHorizontal} true,
 {ssAutoVertical  } false,
 {ssAutoBoth      } true
  );

  ScrollerAutoHide: array[TScrollStyle] of boolean = (
 {ssNone          } false,
 {ssHorizontal    } false,
 {ssVertical      } false,
 {ssBoth          } false,
 {ssAutoHorizontal} true,
 {ssAutoVertical  } true,
 {ssAutoBoth      } true
  );

function AllocButton(const ATarget: TWinControl; const ACallBackClass: TLCLButtonCallBackClass; const AParams: TCreateParams; btnBezel: NSBezelStyle; btnType: NSButtonType): NSButton;
var
  titel:string;
  cap: NSString;
begin
  Result := TCocoaButton.alloc.lclInitWithCreateParams(AParams);
  if Assigned(Result) then
  begin
    TCocoaButton(Result).callback := ACallBackClass.Create(Result, ATarget);
    titel:=aParams.Caption;
    DeleteAmpersands(titel);
    cap := NSStringUTF8(titel);

    Result.setTitle(cap);
    cap.release;
    if btnBezel <> 0 then
      Result.setBezelStyle(btnBezel);
    Result.setButtonType(btnType);
  end;
end;

function AllocTextView(ATarget: TWinControl; const AParams: TCreateParams; fieldEditor: Boolean): NSTextView;
begin
  Result := TCocoaTextView.alloc.lclInitWithCreateParams(AParams);
  if Assigned(Result) then
  begin
    TCocoaTextView(Result).callback := TLCLCommonCallback.Create(Result, ATarget);
  end;
end;

function AllocTextField(ATarget: TWinControl; const AParams: TCreateParams): TCocoaTextField;
begin
  Result := TCocoaTextField.alloc.lclInitWithCreateParams(AParams);
  if Assigned(Result) then
  begin
    Result.callback := TLCLCommonCallback.Create(Result, ATarget);
    SetNSControlValue(Result, AParams.Caption);
  end;
end;

function AllocSecureTextField(ATarget: TWinControl; const AParams: TCreateParams): TCocoaSecureTextField;
begin
  Result := TCocoaSecureTextField.alloc.lclInitWithCreateParams(AParams);
  if Assigned(Result) then
  begin
    TCocoaSecureTextField(Result).callback := TLCLCommonCallback.Create(Result, ATarget);
    SetNSText(Result.currentEditor, AParams.Caption);
  end;
end;

{ TLCLRadioButtonCallback }

procedure TLCLRadioButtonCallback.ButtonClick;
var
  SubView: NSView;
begin
  if not Owner.lclIsEnabled() then Exit;
  if NSButton(Owner).state = NSOnState then
  begin
    for SubView in NSButton(Owner).superView.subviews do
      if (SubView <> Owner) and (SubView.lclGetTarget is TRadioButton) then
        NSButton(SubView).setState(NSOffState);
  end;
  inherited ButtonClick;
end;

{ TLCLButtonCallback }

procedure TLCLButtonCallback.ButtonClick;
begin
  if not Owner.lclIsEnabled() then Exit;
  SendSimpleMessage(Target, LM_CLICKED);
end;

{ TLCLListBoxCallback }

procedure TLCLListBoxCallback.SelectionChanged;
begin
  SendSimpleMessage(Target, LM_SELCHANGE);
end;

{ TLCLCheckBoxCallback }

procedure TLCLCheckBoxCallback.ButtonClick;
begin
  inherited;
  if not Owner.lclIsEnabled() then Exit;
  SendSimpleMessage(Target, LM_CHANGED);
  // todo: win32 has something about dbcheckbox handling here. so maybe we need to handle it special too
end;

{ TLCLComboboxCallback }

procedure TLCLComboboxCallback.ComboBoxWillPopUp;
begin
  LCLSendDropDownMsg(Target);
end;

procedure TLCLComboboxCallback.ComboBoxWillDismiss;
begin
  LCLSendCloseUpMsg(Target);
end;

procedure TLCLComboboxCallback.ComboBoxSelectionDidChange;
begin
  // todo: send correct messages here. LM_CHANGED must be sent on editbox change
  SendSimpleMessage(Target, LM_CHANGED);
  SendSimpleMessage(Target, LM_SELCHANGE);
end;

procedure TLCLComboboxCallback.ComboBoxSelectionIsChanging;
begin

end;


{ TCocoaWSButton }

{------------------------------------------------------------------------------
  Method:  TCocoaWSButton.CreateHandle
  Params:  AWinControl - LCL control
           AParams     - Creation parameters
  Returns: Handle to the control in Cocoa interface

  Creates new button control in Cocoa interface with the specified parameters
 ------------------------------------------------------------------------------}
class function TCocoaWSButton.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
var
  btn: NSButton;
begin
  btn := AllocButton(AWinControl, TLCLButtonCallback, AParams, NSRoundedBezelStyle, NSMomentaryPushInButton);
  Result := TLCLIntfHandle(btn);
end;

{------------------------------------------------------------------------------
  Method:  TCocoaWSButton.SetDefault
  Params:  AButton  - LCL button control
           ADefault

  Sets button default indication in Cocoa interface
 ------------------------------------------------------------------------------}
class procedure TCocoaWSButton.SetDefault(const AButton: TCustomButton; ADefault: Boolean);
var
  cf: NSString;
const
  DefEq: array [Boolean] of String = (#0, #13);
begin
  if not AButton.HandleAllocated then
    Exit;
  cf := NSStringUtf8(DefEq[ADefault]);
  NSButton(AButton.Handle).setKeyEquivalent(cf);
  cf.release;
end;


class procedure TCocoaWSButton.SetText(const AWinControl: TWinControl; const AText: String);
var
  titel:string;
  cap: NSString;
begin
  titel:=AText;
  DeleteAmpersands(titel);
  cap := NSStringUTF8(titel);
  NSButton(AWinControl.Handle).setTitle(cap);
  cap.release;
end;

{ TCocoaWSCustomCheckBox }

{------------------------------------------------------------------------------
  Method:  TCocoaWSCustomCheckBox.CreateHandle
  Params:  AWinControl - LCL control
           AParams     - Creation parameters
  Returns: Handle to the control in Cocoa interface

  Creates new check box in Cocoa interface with the specified parameters
 ------------------------------------------------------------------------------}
class function TCocoaWSCustomCheckBox.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
var
  btn: NSButton;
begin
  btn := AllocButton(AWinControl, TLCLCheckBoxCallBack, AParams, 0, NSSwitchButton);
  Result := TLCLIntfHandle(btn);
end;

{------------------------------------------------------------------------------
  Method:  TCocoaWSCustomCheckBox.RetrieveState
  Params:  ACustomCheckBox - LCL custom check box
  Returns: State of check box

  Retrieves the state of check box in Cocoa interface
 ------------------------------------------------------------------------------}
class function TCocoaWSCustomCheckBox.RetrieveState(const ACustomCheckBox: TCustomCheckBox): TCheckBoxState;
var
  state : NSInteger;
begin
  Result := cbUnchecked;
  if not ACustomCheckBox.HandleAllocated then
    Exit;
  state := NSButton(ACustomCheckBox.Handle).state;
  case state of
    NSOnState: Result := cbChecked;
    NSMixedState: Result := cbGrayed;
  end;
end;

{------------------------------------------------------------------------------
  Method:  TCocoaWSCustomCheckBox.SetState
  Params:  ACustomCheckBox - LCL custom check box
           NewState        - New state of check box

  Sets the new state of check box in Cocoa interface
 ------------------------------------------------------------------------------}
class procedure TCocoaWSCustomCheckBox.SetState(
  const ACustomCheckBox: TCustomCheckBox; const NewState: TCheckBoxState);
const
  buttonState: array [TcheckBoxState] of NSInteger = (NSOffState, NSOnState, NSMixedState);
begin
  if ACustomCheckBox.HandleAllocated then
    NSButton(ACustomCheckBox.Handle).setState(buttonState[NewState]);
end;

class procedure TCocoaWSCustomCheckBox.GetPreferredSize(
  const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer;
  WithThemeSpace: Boolean);
var
  lButton: NSButton;
  lOldSize: NSSize;
begin
  if not AWinControl.HandleAllocated then Exit;
  lButton := NSButton(AWinControl.Handle);

  lOldSize := lButton.bounds.size;
  lButton.sizeToFit();
  PreferredWidth := round(lButton.bounds.size.width);
  PreferredHeight := round(lButton.bounds.size.height);
  //lButton.setBoundsSize(lOldSize); This causes problems in SetText
end;

class procedure TCocoaWSCustomCheckBox.SetText(const AWinControl: TWinControl;
  const AText: String);
begin
  TCocoaWSButton.SetText(AWinControl, AText);
end;

{ TCocoaWSRadioButton }

class function TCocoaWSRadioButton.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
var
  btn: NSButton;
begin
  btn := AllocButton(AWinControl, TLCLRadioButtonCallback, AParams, 0, NSRadioButton);
  Result := TLCLIntfHandle(btn);
end;

{ TCocoaWSCustomStaticText }

class function TCocoaWSCustomStaticText.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
var
  field: NSTextField;
begin
  field := NSTextField(AllocTextField(AWinControl, AParams));
  field.setBezeled(False);
  field.setDrawsBackground(False);
  field.setEditable(False);
  field.setSelectable(False);
  Result:=TLCLIntfHandle(field);
end;

{ TCocoaWSCustomEdit }

class function TCocoaWSCustomEdit.CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle;
var
  field : NSTextField;
begin
  if TCustomEdit(AWinControl).PasswordChar=#0
    then field:=NSTextField(AllocTextField(AWinControl, AParams))
    else field:=NSTextField(AllocSecureTextField(AWinControl, AParams));
  NSCell(field.cell).setWraps(false);
  NSCell(field.cell).setScrollable(true);
  Result:=TLCLIntfHandle(field);
end;

class function TCocoaWSCustomEdit.GetSelStart(const ACustomEdit: TCustomEdit): integer;
var
  field : TCocoaTextField;
  txt   :  NSText;
begin
  Result:=0;
  field:=TCocoaTextField(ACustomEdit.Handle);
  if not Assigned(field) then Exit;
  txt:=NSText(field.currentEditor);
  if not Assigned(txt) then Exit;

  Result:=txt.selectedRange.location;
end;

class function TCocoaWSCustomEdit.GetSelLength(const ACustomEdit: TCustomEdit): integer;
var
  field : TCocoaTextField;
  txt   :  NSText;
begin
  Result:=0;
  field:=TCocoaTextField(ACustomEdit.Handle);
  if not Assigned(field) then Exit;
  txt:=NSText(field.currentEditor);
  if not Assigned(txt) then Exit;

  Result:=txt.selectedRange.length;
end;

class procedure TCocoaWSCustomEdit.SetPasswordChar(const ACustomEdit: TCustomEdit; NewChar: char);
begin
  if (NewChar<>#0) xor TCocoaTextField(ACustomEdit.Handle).isKindOfClass_(NSSecureTextField) then
    RecreateWnd(ACustomEdit);
end;


class procedure TCocoaWSCustomEdit.SetReadOnly(const ACustomEdit: TCustomEdit; NewReadOnly: boolean);
begin
//  NSTextField(ACustomEdit.Handle).setEditable(not NewReadOnly);
end;


type

  { TCocoaMemoStrings }

  TCocoaMemoStrings = class(TStrings)
  private
    FTextView: NSTextView;
  protected
    function GetTextStr: string; override;
    procedure SetTextStr(const Value: string); override;
    function GetCount: Integer; override;
    function Get(Index: Integer): string; override;
  public
    constructor Create(ATextView: NSTextView);
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    procedure Insert(Index: Integer; const S: string); override;
    procedure LoadFromFile(const FileName: string); override;
    procedure SaveToFile(const FileName: string); override;
  end;

{ TCocoaMemoStrings }

constructor TCocoaMemoStrings.Create(ATextView: NSTextView);
begin
  inherited Create;
  FTextView := ATextView;
end;

function TCocoaMemoStrings.GetTextStr: string;
begin
  Result := NSStringToString(FTextView.string_);
end;

procedure TCocoaMemoStrings.SetTextStr(const Value: string);
var
  ns: NSString;
begin
  ns := NSStringUtf8(Value);
  FTextView.setString(ns);
  ns.release;
end;

procedure GetLineStart(const s: AnsiString; LineIndex: Integer; var Offset, LinesSkipped: Integer);
var
  i : Integer;
begin
  i:=1;
  LinesSkipped:=0;
  while (LinesSkipped<>LineIndex) and (i<=length(s)) do begin
    if s[i] in [#10, #13] then begin
      inc(i);
      inc(LinesSkipped);
      if (i<=length(s)) and (s[i] in [#10,#13]) and (s[i-1]<>s[i]) then
        inc(i);
    end else
      inc(i);
  end;
  Offset:=i;
end;

function GetLinesCount(const s: AnsiString): Integer;
var
  ofs : Integer;
begin
  Result:=0;
  ofs:=0;
  GetLineStart(s, -1, ofs, Result);
end;

function TCocoaMemoStrings.GetCount:Integer;
begin
  Result:=GetLinesCount(GetTextStr);
  inc(Result);
end;

function TCocoaMemoStrings.Get(Index:Integer):string;
var
  s     : AnsiString;
  ofs   : Integer;
  eofs  : Integer;
  t     : Integer;
begin
  s:=GetTextStr;
  t:=0;
  ofs:=0;
  GetLineStart(s, Index, ofs, t);
  eofs:=ofs;
  while (eofs<=length(s)) and not (s[eofs] in [#10,#13]) do
    inc(eofs);
  Result:=Copy(s, ofs, eofs-ofs);
end;

procedure TCocoaMemoStrings.Clear;
begin
  SetTextStr('');
end;

procedure TCocoaMemoStrings.Delete(Index:Integer);
var
  s     : AnsiString;
  ofs   : Integer;
  eofs  : Integer;
  t     : Integer;
begin
  s:=GetTextStr;
  GetLineStart(s, Index, ofs, t);
  eofs:=ofs;
  while (eofs<=length(s)) and not (s[eofs] in [#10,#13]) do
    inc(eofs);
  if eofs<=length(s) then begin
    inc(eofs);
    if (eofs<=length(s)) and (s[eofs] in [#10,#13]) and (s[eofs-1]<>s[eofs]) then
      inc(eofs);
  end;
  System.Delete(s, ofs, eofs-ofs);
  SetTextStr(s);
end;

procedure TCocoaMemoStrings.Insert(Index:Integer;const S:string);
var
  txt   : AnsiString;
  ofs   : Integer;
  t     : Integer;
begin
  txt:=GetTextStr;
  GetLineStart(txt, Index, ofs, t);
  System.Insert(s+LineEnding, txt, ofs);
  SetTextStr(txt)
end;

procedure TCocoaMemoStrings.LoadFromFile(const FileName: string);
var
  TheStream: TFileStreamUTF8;
begin
  TheStream:=TFileStreamUtf8.Create(FileName,fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(TheStream);
  finally
    TheStream.Free;
  end;
end;

procedure TCocoaMemoStrings.SaveToFile(const FileName: string);
var
  TheStream: TFileStreamUTF8;
begin
  TheStream:=TFileStreamUtf8.Create(FileName,fmCreate);
  try
    SaveToStream(TheStream);
  finally
    TheStream.Free;
  end;
end;

{ TCocoaWSCustomMemo }

function MemoTextView(AWinControl: TWinControl): TCocoaTextView;
begin
  if not Assigned(AWinControl) or (AWinControl.Handle=0) then
    Result := nil
  else
    Result := TCocoaTextView(NSScrollView(AWinControl.Handle).documentView);
end;

class function TCocoaWSCustomMemo.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams):TLCLIntfHandle;
var
  txt: TCocoaTextView;
  ns: NSString;
  scr: TCocoaScrollView;
  nr:NSRect;
  r:TRect;
begin
  scr := TCocoaScrollView(NSView(TCocoaScrollView.alloc).lclInitWithCreateParams(AParams));

  nr.origin.x:=0;
  nr.origin.x:=0;
  nr.size.height:=0;
  nr.size.width:=AParams.Width;

  txt := TCocoaTextView.alloc.initwithframe(nr);
  scr.setDocumentView(txt);

  scr.setHasVerticalScroller(VerticalScrollerVisible[TMemo(AWinControl).ScrollBars]);
  scr.setHasHorizontalScroller(HorizontalScrollerVisible[TMemo(AWinControl).ScrollBars]);
  scr.setAutohidesScrollers(ScrollerAutoHide[TMemo(AWinControl).ScrollBars]);

  if TCustomMemo(AWinControl).BorderStyle=bsSingle then
     scr.setBorderType(NSBezelBorder);

  nr:=scr.documentVisibleRect;
  txt.setFrame(nr);
  txt.textContainer.setLineFragmentPadding(0);

  txt.callback := TLCLCommonCallback.Create(txt, AWinControl);
  ns := NSStringUtf8(AParams.Caption);
  txt.setString(ns);
  ns.release;

  scr.callback := txt.callback;
  Result := TLCLIntfHandle(scr);
end;

class function TCocoaWSCustomMemo.GetStrings(const ACustomMemo: TCustomMemo): TStrings;
var
  txt: TCocoaTextView;
begin
  txt := MemoTextView(ACustomMemo);
  if Assigned(txt) then
    Result := TCocoaMemoStrings.Create(txt)
  else
    Result := nil
end;

class function TCocoaWSCustomMemo.GetSelStart(const ACustomEdit: TCustomEdit
  ): integer;
var
  txt: TCocoaTextView;
begin
  txt := MemoTextView(ACustomEdit);
  if not Assigned(txt) then Exit;
  Result := txt.selectedRange.location;
end;

class function TCocoaWSCustomMemo.GetSelLength(const ACustomEdit: TCustomEdit
  ): integer;
var
  txt: TCocoaTextView;
  ns: NSArray;
begin
  txt := MemoTextView(ACustomEdit);
  if not Assigned(txt) then Exit;
  Result := txt.selectedRange.length;
end;

class procedure TCocoaWSCustomMemo.AppendText(const ACustomMemo: TCustomMemo;
  const AText: string);
begin
  //todo:
end;

class procedure TCocoaWSCustomMemo.SetReadOnly(const ACustomEdit:TCustomEdit;
  NewReadOnly:boolean);
var
  txt: TCocoaTextView;
begin
  txt := MemoTextView(ACustomEdit);
  if Assigned(txt) then
    txt.setEditable(not NewReadOnly);
end;

class procedure TCocoaWSCustomMemo.SetScrollbars(const ACustomMemo: TCustomMemo; const NewScrollbars: TScrollStyle);
begin
  TCocoaScrollView(ACustomMemo.Handle).setHasVerticalScroller(VerticalScrollerVisible[NewScrollbars]);
  TCocoaScrollView(ACustomMemo.Handle).setHasHorizontalScroller(HorizontalScrollerVisible[NewScrollbars]);
  TCocoaScrollView(ACustomMemo.Handle).setAutohidesScrollers(ScrollerAutoHide[NewScrollbars]);

end;

class procedure  TCocoaWSCustomMemo.SetWordWrap(const ACustomMemo: TCustomMemo; const NewWordWrap: boolean);
begin
  //todo:
end;

class procedure TCocoaWSCustomMemo.SetText(const AWinControl:TWinControl;const AText:String);
var
  txt: TCocoaTextView;
  ns: NSString;
begin
  txt := MemoTextView(AWinControl);
  if not Assigned(txt) then Exit;
  ns := NSStringUtf8(AText);
  txt.setString(ns);
  ns.release;
end;

class function TCocoaWSCustomMemo.GetText(const AWinControl: TWinControl; var AText: String): Boolean;
var
  txt: TCocoaTextView;
begin
  txt := MemoTextView(AWinControl);
  Result := Assigned(txt);
  if Result then
    AText := NSStringToString(txt.string_);
end;

{ TCocoaWSCustomComboBox }

class function TCocoaWSCustomComboBox.CreateHandle(const AWinControl:TWinControl;
  const AParams:TCreateParams):TLCLIntfHandle;
var
  cmb: TCocoaComboBox;
  rocmb: TCocoaReadOnlyComboBox;
begin
  Result:=0;

  if TCustomComboBox(AWinControl).ReadOnly then
  begin
    rocmb := NSView(TCocoaReadOnlyComboBox.alloc).lclInitWithCreateParams(AParams);
    if not Assigned(rocmb) then Exit;
    rocmb.Owner := TCustomComboBox(AWinControl);
    rocmb.callback:=TLCLComboboxCallback.Create(rocmb, AWinControl);
    rocmb.list:=TCocoaComboBoxList.Create(nil, rocmb);
    rocmb.setTarget(rocmb);
    rocmb.setAction(objcselector('comboboxAction:'));
    rocmb.selectItemAtIndex(rocmb.lastSelectedItemIndex);
    Result:=TLCLIntfHandle(rocmb);
  end
  else
  begin
    cmb := NSView(TCocoaComboBox.alloc).lclInitWithCreateParams(AParams);
    if not Assigned(cmb) then Exit;
    cmb.callback:=TLCLComboboxCallback.Create(cmb, AWinControl);
    cmb.list:=TCocoaComboBoxList.Create(cmb, nil);
    cmb.setUsesDataSource(true);
    cmb.setDataSource(cmb);
    cmb.setDelegate(cmb);
    Result:=TLCLIntfHandle(cmb);
  end;
  //todo: 26 pixels is the height of 'normal' combobox. The value is taken from the Interface Builder!
  //      use the correct way to set the size constraints
  AWinControl.Constraints.SetInterfaceConstraints(0,26,0,26);
end;

class function TCocoaWSCustomComboBox.GetItemIndex(const ACustomComboBox:
  TCustomComboBox):integer;
begin
  if (not Assigned(ACustomComboBox)) or (not ACustomComboBox.HandleAllocated) then
    Exit;

  if ACustomComboBox.ReadOnly then
    Result := TCocoaReadOnlyComboBox(ACustomComboBox.Handle).indexOfSelectedItem
  else
    Result := TCocoaComboBox(ACustomComboBox.Handle).indexOfSelectedItem;
end;

class procedure TCocoaWSCustomComboBox.SetItemIndex(const ACustomComboBox:
  TCustomComboBox;NewIndex:integer);
var
  rocmb: TCocoaReadOnlyComboBox;
begin
  if (not Assigned(ACustomComboBox)) or (not ACustomComboBox.HandleAllocated) then
    Exit;

  if ACustomComboBox.ReadOnly then
  begin
    rocmb := TCocoaReadOnlyComboBox(ACustomComboBox.Handle);
    rocmb.lastSelectedItemIndex := NewIndex;
    rocmb.selectItemAtIndex(NewIndex);
  end
  else
    TCocoaComboBox(ACustomComboBox.Handle).selectItemAtIndex(NewIndex);
end;

class procedure TCocoaWSCustomComboBox.SetReadOnly(const ACustomComboBox:
  TCustomComboBox; NewReadOnly: boolean);
begin
  if Assigned(ACustomComboBox) then
    RecreateWnd(ACustomComboBox);
end;

class procedure TCocoaWSCustomComboBox.SetDropDownCount(const ACustomComboBox:
  TCustomComboBox;NewCount:Integer);
begin
  if (not Assigned(ACustomComboBox)) or (not ACustomComboBox.HandleAllocated) then
    Exit;

  if not ACustomComboBox.ReadOnly then
    TCocoaComboBox(ACustomComboBox.Handle).setNumberOfVisibleItems(NewCount);
end;

class function TCocoaWSCustomComboBox.GetItems(const ACustomComboBox: TCustomComboBox): TStrings;
begin
  if (not Assigned(ACustomComboBox)) or (not ACustomComboBox.HandleAllocated) then
    Exit;

  if ACustomComboBox.ReadOnly then
    Result:=TCocoaReadOnlyComboBox(ACustomComboBox.Handle).list
  else
    Result:=TCocoaComboBox(ACustomComboBox.Handle).list;
end;

class function TCocoaWSCustomComboBox.GetItemHeight(const ACustomComboBox:
  TCustomComboBox):Integer;
begin
  if (not Assigned(ACustomComboBox)) or (not ACustomComboBox.HandleAllocated) then
    Exit;

  if ACustomComboBox.ReadOnly then
    Result := 26 // ToDo
  else
    Result:=Round(TCocoaComboBox(ACustomComboBox.Handle).itemHeight);
end;

class procedure TCocoaWSCustomComboBox.SetItemHeight(const ACustomComboBox:
  TCustomComboBox;const AItemHeight:Integer);
begin
  if (not Assigned(ACustomComboBox)) or (not ACustomComboBox.HandleAllocated) then
    Exit;

  if ACustomComboBox.ReadOnly then
    Exit // ToDo
  else
    TCocoaComboBox(ACustomComboBox.Handle).setItemHeight(AItemHeight);
end;

class procedure TCocoaWSCustomComboBox.GetPreferredSize(
  const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer;
  WithThemeSpace: Boolean);
begin
  // do not override PreferredWidth and Height
  // see todo at TCocoaWSWinControl.GetPreferredSize
  // once it's resolved, TCocoaWSCustomComboBox.GetPreferredSize could be removed
end;

{ TCocoaWSToggleBox }

class function TCocoaWSToggleBox.CreateHandle(const AWinControl:TWinControl;
  const AParams:TCreateParams):TLCLIntfHandle;
var
  btn: NSButton;
  cl: NSButtonCell;
begin
  btn := AllocButton(AWinControl, TLCLButtonCallBack, AParams, NSTexturedRoundedBezelStyle, NSToggleButton);
  cl := NSButtonCell(NSButton(btn).cell);
  cl.setShowsStateBy(cl.showsStateBy or NSContentsCellMask);
  Result := TLCLIntfHandle(btn);
end;

{ TCocoaWSScrollBar }

class function TCocoaWSScrollBar.CreateHandle(const AWinControl:TWinControl;
  const AParams:TCreateParams):TLCLIntfHandle;
var
  scr : TCocoaScrollBar;
begin
  scr:=NSView(TCocoaScrollBar.alloc).lclInitWithCreateParams(AParams);
  scr.callback:=TLCLCommonCallback.Create(scr, AWinControl);

  // OnChange (scrolling) event handling
  scr.LCLScrollBar := TCustomScrollBar(AWinControl);
  scr.setTarget(scr);
  scr.setAction(objcselector('actionScrolling:'));

  Result:=TLCLIntfHandle(scr);
end;

// vertical/horizontal in Cocoa is set automatically according to
// the geometry of the scrollbar, it cannot be forced to an unusual value
class procedure TCocoaWSScrollBar.SetKind(const AScrollBar: TCustomScrollBar; const AIsHorizontal: Boolean);
begin
  // do nothing
end;

class procedure TCocoaWSScrollBar.SetParams(const AScrollBar:TCustomScrollBar);
var
  lScroller: TCocoaScrollBar;
begin
  if not Assigned(AScrollBar) then Exit;
  lScroller := TCocoaScrollBar(AScrollBar.Handle);
  if (lScroller = nil) then Exit;
  if AScrollBar.Max > 0 then
  begin
    lScroller.setFloatValue_knobProportion(
      AScrollBar.Position / AScrollBar.Max,
      AScrollBar.PageSize / AScrollBar.Max);
    //if TCocoaScrollBar(Handle).setKnobProportion( PageSize/Max );
    //if TCocoaScrollBar(Handle).setDoubleValue( Position/Max );
  end;
end;

{ TCocoaWSCustomGroupBox }

class function TCocoaWSCustomGroupBox.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
var
  box: TCocoaGroupBox;
  cap: NSString;
  lGroupBoxContents: TCocoaCustomControl;
  ns: NSRect;
  //str: string;
begin
  box := NSView(TCocoaGroupBox.alloc).lclInitWithCreateParams(AParams);
  if Assigned(box) then
  begin
    box.callback := TLCLCommonCallback.Create(box, AWinControl);
    cap := NSStringUTF8(AParams.Caption);
    box.setTitle(cap);
    cap.release;

    // set a content view in order to be able to customize drawing for labels/color
    ns := GetNSRect(AParams.X, AParams.Y, AParams.Width, AParams.Height);
    lGroupBoxContents := TCocoaCustomControl(TCocoaCustomControl.alloc.initWithFrame(ns));
    lGroupBoxContents.callback := TLCLCustomControlCallback.Create(lGroupBoxContents, AWinControl);
    //str := Format('%X=%X', [PtrUInt(box.callback), PtrUInt(lGroupBoxContents.callback)]);
    lGroupBoxContents.autorelease;
    box.setContentView(lGroupBoxContents);
  end;
  Result := TLCLIntfHandle(box);
end;

{ TCocoaWSCustomListBox }

function GetListBox(AWinControl: TWinControl): TCocoaListBox;
begin
  if not Assigned(AWinControl) or (AWinControl.Handle=0) then
    Result := nil
  else
    Result := TCocoaListBox(TCocoaScrollView(AWinControl.Handle).documentView);
end;

class function TCocoaWSCustomListBox.CreateHandle(const AWinControl:TWinControl;
  const AParams:TCreateParams):TLCLIntfHandle;
var
  list    : TCocoaListBox;
  scroll  : TCocoaScrollView;
begin
  list := NSView(TCocoaListBox.alloc).lclInitWithCreateParams(AParams);
  if not Assigned(list) then
  begin
    Result := 0;
    Exit;
  end;
  list.callback := TLCLListBoxCallback.Create(list, AWinControl);
  list.list := TCocoaStringList.Create(list);
  list.addTableColumn(NSTableColumn.alloc.init);
  list.setHeaderView(nil);
  list.setDataSource(list);
  list.setDelegate(list);


  scroll := EmbedInScrollView(list);
  if not Assigned(scroll) then
  begin
    list.dealloc;
    Result := 0;
    Exit;
  end;
  scroll.callback := list.callback;
  scroll.setHasVerticalScroller(true);
  scroll.setAutohidesScrollers(true);
  Result := TLCLIntfHandle(scroll);
end;

class function TCocoaWSCustomListBox.GetStrings(const ACustomListBox: TCustomListBox):TStrings;
var
  view : TCocoaListBox;
begin
  view:=GetListBox(ACustomListBox);
  if not Assigned(view) then
    Result:=nil
  else
    Result:=view.list;
end;

class function TCocoaWSCustomListBox.GetItemRect(const ACustomListBox: TCustomListBox; Index: integer; var ARect: TRect): boolean;
var view : TCocoaListBox;
    r:NSRect;
begin
  Result := False;

  view:=GetListBox(ACustomListBox);
  if not Assigned(view) then
    begin
    Result:=false;
    exit;
    end;

  r:=view.frameOfCellAtColumn_row(0,index);
  Arect:=NSRectToRect(r);
  Result := True;

end;

class function TCocoaWSCustomListBox.GetItemIndex(const ACustomListBox: TCustomListBox): integer;
var
  view : TCocoaListBox;
  indexset: NSIndexSet;
begin

  view:=GetListBox(ACustomListBox);
  if not Assigned(view) then
    begin
    Result:=-1;
    exit;
    end;

  indexset:=view.selectedRowIndexes();
  result:=indexset.firstIndex;

end;

end.

