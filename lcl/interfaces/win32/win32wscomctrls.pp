{ $Id$}
{
 *****************************************************************************
 *                            Win32WSComCtrls.pp                             * 
 *                            ------------------                             * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
unit Win32WSComCtrls;

{$mode objfpc}{$H+}
{$I win32defines.inc}

interface

uses        
  // FCL
  CommCtrl, Windows, Classes, SysUtils, Win32Extra,
  // LCL
  ComCtrls, LCLType, Controls, Graphics, Themes,
  ImgList, StdCtrls,
  LMessages, LCLProc, InterfaceBase,
  // widgetset
  WSComCtrls, WSLCLClasses, WSControls, WSProc,
  // win32 widgetset
  Win32Int, Win32Proc, Win32WSControls;

type

  { TWin32WSStatusBar }

  TWin32WSStatusBar = class(TWSStatusBar)
  private
  protected
  public
    class function CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): HWND; override;
    class procedure Update(const AStatusBar: TStatusBar); override;
    class procedure PanelUpdate(const AStatusBar: TStatusBar; PanelIndex: integer); override;
    class procedure SetPanelText(const AStatusBar: TStatusBar; PanelIndex: integer); override;
    class procedure SetSizeGrip(const AStatusBar: TStatusBar; SizeGrip: Boolean); override;
    class procedure SetText(const AWinControl: TWinControl; const AText: string); override;
    class procedure GetPreferredSize(const AWinControl: TWinControl;
                        var PreferredWidth, PreferredHeight: integer;
                        WithThemeSpace: Boolean); override;
  end;

  { TWin32WSTabSheet }

  TWin32WSTabSheet = class(TWSTabSheet)
  private
  protected
  public
  end;

  { TWin32WSPageControl }

  TWin32WSPageControl = class(TWSPageControl)
  private
  protected
  public
  end;

  { TWin32WSCustomListView }

  TWin32WSCustomListView = class(TWSCustomListView)
  private
    class function  GetHeader(const AHandle: THandle): THandle;
    class procedure PositionHeader(const AHandle: THandle);
    class procedure UpdateStyle(const AHandle: THandle; const AMask, AStyle: Integer);
    class procedure UpdateExStyle(const AHandle: THandle; const AMask, AStyle: Integer);
  protected
  public
    // columns
    class procedure ColumnDelete(const ALV: TCustomListView; const AIndex: Integer); override;
    class function  ColumnGetWidth(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn): Integer; override;
    class procedure ColumnInsert(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn); override;
    class procedure ColumnMove(const ALV: TCustomListView; const AOldIndex, ANewIndex: Integer; const AColumn: TListColumn); override;
    class procedure ColumnSetAlignment(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AAlignment: TAlignment); override;
    class procedure ColumnSetAutoSize(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AAutoSize: Boolean); override;
    class procedure ColumnSetCaption(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const ACaption: String); override;
    class procedure ColumnSetImage(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AImageIndex: Integer); override;
    class procedure ColumnSetMaxWidth(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AMaxWidth: Integer); override;
    class procedure ColumnSetMinWidth(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AMinWidth: integer); override;
    class procedure ColumnSetWidth(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AWidth: Integer); override;
    class procedure ColumnSetVisible(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AVisible: Boolean); override;

    // items
    class procedure ItemDelete(const ALV: TCustomListView; const AIndex: Integer); override;
    class function  ItemDisplayRect(const ALV: TCustomListView; const AIndex, ASubItem: Integer; ACode: TDisplayCode): TRect; override;
    class function  ItemGetChecked(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem): Boolean; override;
    class function  ItemGetPosition(const ALV: TCustomListView; const AIndex: Integer): TPoint; override;
    class function  ItemGetState(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const AState: TListItemState; out AIsSet: Boolean): Boolean; override; // returns True if supported
    class procedure ItemInsert(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem); override;
    class procedure ItemSetChecked(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const AChecked: Boolean); override;
    class procedure ItemSetImage(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const ASubIndex, AImageIndex: Integer); override;
    class function  ItemSetPosition(const ALV: TCustomListView; const AIndex: Integer; const ANewPosition: TPoint): Boolean; override;
    class procedure ItemSetState(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const AState: TListItemState; const AIsSet: Boolean); override;
    class procedure ItemSetText(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const ASubIndex: Integer; const AText: String); override;
    class procedure ItemShow(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const PartialOK: Boolean); override;
  
    // lv
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): HWND; override;

    class procedure BeginUpdate(const ALV: TCustomListView); override;
    class procedure EndUpdate(const ALV: TCustomListView); override;

    class function GetBoundingRect(const ALV: TCustomListView): TRect; override;
    class function GetDropTarget(const ALV: TCustomListView): Integer; override;
    class function GetFocused(const ALV: TCustomListView): Integer; override;
    class function GetHoverTime(const ALV: TCustomListView): Integer; override;
    class function GetItemAt(const ALV: TCustomListView; x,y: Integer): Integer; override;
    class function GetSelCount(const ALV: TCustomListView): Integer; override;
    class function GetSelection(const ALV: TCustomListView): Integer; override;
    class function GetTopItem(const ALV: TCustomListView): Integer; override;
    class function GetViewOrigin(const ALV: TCustomListView): TPoint; override;
    class function GetVisibleRowCount(const ALV: TCustomListView): Integer; override;

    class procedure SetAllocBy(const ALV: TCustomListView; const AValue: Integer); override;
    class procedure SetDefaultItemHeight(const ALV: TCustomListView; const AValue: Integer); override;
    class procedure SetFont(const AWinControl: TWinControl; const AFont: TFont); override;
    class procedure SetHotTrackStyles(const ALV: TCustomListView; const AValue: TListHotTrackStyles); override;
    class procedure SetHoverTime(const ALV: TCustomListView; const AValue: Integer); override;
//    class procedure SetIconOptions(const ALV: TCustomListView; const AValue: TIconOptions); override;
    class procedure SetImageList(const ALV: TCustomListView; const AList: TListViewImageList; const AValue: TCustomImageList); override;
    class procedure SetProperty(const ALV: TCustomListView; const AProp: TListViewProperty; const AIsSet: Boolean); override;
    class procedure SetProperties(const ALV: TCustomListView; const AProps: TListViewProperties); override;
    class procedure SetScrollBars(const ALV: TCustomListView; const AValue: TScrollStyle); override;
    class procedure SetSort(const ALV: TCustomListView; const AType: TSortType; const AColumn: Integer); override;
    class procedure SetViewOrigin(const ALV: TCustomListView; const AValue: TPoint); override;
    class procedure SetViewStyle(const ALV: TCustomListView; const Avalue: TViewStyle); override;
  end;

  { TWin32WSListView }

  TWin32WSListView = class(TWSListView)
  private
  protected
  public
  end;

  { TWin32WSProgressBar }

  TWin32WSProgressBar = class(TWSProgressBar)
  private
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): HWND; override;
    class procedure ApplyChanges(const AProgressBar: TCustomProgressBar); override;
    class procedure SetPosition(const AProgressBar: TCustomProgressBar; const NewPosition: integer); override;
  end;

  { TWin32WSCustomUpDown }

  TWin32WSCustomUpDown = class(TWSCustomUpDown)
  private
  protected
  public
  end;

  { TWin32WSUpDown }

  TWin32WSUpDown = class(TWSUpDown)
  private
  protected
  public
  end;

  { TWin32WSToolButton }

  TWin32WSToolButton = class(TWSToolButton)
  private
  protected
  public
  end;

  { TWin32WSToolBar }

  TWin32WSToolBar = class(TWSToolBar)
  private
  protected
  public
{$ifdef OldToolbar}  
    class function  CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): HWND; override;
    class function  GetButtonCount(const AToolBar: TToolBar): integer; override;
    class procedure InsertToolButton(const AToolBar: TToolbar; const AControl: TControl); override;
    class procedure DeleteToolButton(const AToolBar: TToolbar; const AControl: TControl); override;
{$endif}    
  end;

  { TWin32WSTrackBar }

  TWin32WSTrackBar = class(TWSTrackBar)
  private
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): HWND; override;
    class procedure ApplyChanges(const ATrackBar: TCustomTrackBar); override;
    class function  GetPosition(const ATrackBar: TCustomTrackBar): integer; override;
    class procedure SetPosition(const ATrackBar: TCustomTrackBar; const NewPosition: integer); override;
  end;

  { TWin32WSCustomTreeView }

  TWin32WSCustomTreeView = class(TWSCustomTreeView)
  private
  protected
  public
  end;

  { TWin32WSTreeView }

  TWin32WSTreeView = class(TWSTreeView)
  private
  protected
  public
  end;


implementation

{$I win32wscustomlistview.inc }


{ --- Helper routines for TWin32WSStatusBar --- }

var
  PreferredStatusBarHeight: integer = 0;

procedure InitializePreferredStatusBarHeight;
var
  Flags: LongWord;
  Parent: HWND;
  PreferredSizeStatusBar: HWND;
  R: TRect;
begin
  Flags := WS_CHILD or WS_CLIPSIBLINGS or WS_CLIPCHILDREN;
  Parent := TWin32WidgetSet(WidgetSet).AppHandle;
  {$ifdef WindowsUnicodeSupport}
  if UnicodeEnabledOS then
    PreferredSizeStatusBar := CreateWindowExW(0, STATUSCLASSNAMEW,
      nil, Flags,
      0, 0, 0, 0, Parent, 0, HInstance, Nil)
  else
    PreferredSizeStatusBar := CreateWindowEx(0, STATUSCLASSNAME, nil,
      Flags, 0, 0, 0, 0, Parent,0 , HInstance, Nil);
  {$else}
    PreferredSizeStatusBar := CreateWindowEx(0, STATUSCLASSNAME, nil,
      Flags, 0, 0, 0, 0, Parent, 0, HInstance, Nil);
  {$endif}
  GetWindowRect(PreferredSizeStatusBar, R);
  PreferredStatusBarHeight := R.Bottom - R.Top;
  DestroyWindow(PreferredSizeStatusBar);
end;

{------------------------------------------------------------------------------
  Method: UpdateStatusBarPanel
  Params: StatusPanel - StatusPanel which needs to be update
  Returns: Nothing

  Called by StatusBarPanelUpdate and StatusBarSetText
  Everything is updated except the panel width
 ------------------------------------------------------------------------------}
procedure UpdateStatusBarPanel(const StatusPanel: TStatusPanel);
const
  StatusBevelMap: array[TStatusPanelBevel] of Integer =
  (
{ pbNone    } Windows.SBT_NOBORDERS,
{ pbLowered } 0,
{ pbRaised  } Windows.SBT_POPOUT
  );
var
  BevelType: integer;
  Text: string;
begin
  Text := StatusPanel.Text;
  case StatusPanel.Alignment of
    taCenter: Text := #9 + Text;
    taRightJustify: Text := #9#9 + Text;
  end;
  BevelType := StatusBevelMap[StatusPanel.Bevel];

  {$ifdef WindowsUnicodeSupport}
    if UnicodeEnabledOS then
      Windows.SendMessage(StatusPanel.StatusBar.Handle, SB_SETTEXTW, StatusPanel.Index or BevelType, LPARAM(PWideChar(Utf8Decode(Text))))
    else
      Windows.SendMessage(StatusPanel.StatusBar.Handle, SB_SETTEXT, StatusPanel.Index or BevelType, LPARAM(PChar(Utf8ToAnsi(Text))));
  {$else}
    Windows.SendMessage(StatusPanel.StatusBar.Handle, SB_SETTEXT, StatusPanel.Index or BevelType, LPARAM(PChar(Text)));
  {$endif}
end;

procedure UpdateStatusBarPanelWidths(const StatusBar: TStatusBar);
var
  Rights: PInteger;
  PanelIndex: integer;
  CurrentRight: integer;
begin
  if StatusBar.Panels.Count=0 then begin
    // SETPARTS 0,0 does not work :S
    Windows.SendMessage(StatusBar.Handle, SB_SIMPLE, 1, 0);
    Windows.SendMessage(StatusBar.Handle, SB_SETTEXT, 255, WPARAM(PChar('')));
    exit;
  end;
  Getmem(Rights, StatusBar.Panels.Count * SizeOf(integer));
  try
    CurrentRight := 0;
    for PanelIndex := 0 to StatusBar.Panels.Count-2 do begin
      CurrentRight := CurrentRight + StatusBar.Panels[PanelIndex].Width;
      Rights[PanelIndex] := CurrentRight;
    end;
    Rights[StatusBar.Panels.Count-1] := -1; //Last extends to end;
    Windows.SendMessage(StatusBar.Handle, SB_SETPARTS, StatusBar.Panels.Count, LPARAM(Rights));
  finally
    Freemem(Rights);
  end;
end;

function StatusBarWndProc(Window: HWnd; Msg: UInt; WParam: Windows.WParam;
    LParam: Windows.LParam): LResult; stdcall;
var
  Info: PWindowInfo;
  Control: TWinControl;
  Details: TThemedElementDetails;
begin
  Info := GetWindowInfo(Window);
  if (Info = nil) or (Info^.WinControl = nil) then
  begin
    Result := CallDefaultWindowProc(Window, Msg, WParam, LParam);
    Exit;
  end
  else
    Control := Info^.WinControl;

  // Paul: next is a slightly modified code of TThemeManager.StatusBarWindowProc
  // of Mike Lischke Theme manager library (Mike granted us permition to use his code)
  
  case Msg of
    WM_NCCALCSIZE:
      begin
        // We need to override the window class' CS_HREDRAW and CS_VREDRAW styles but the following
        // does the job very well too.
        // Note: this may produce trouble with embedded controls (e.g. progress bars).
        if WParam <> 0 then
          Result := CallDefaultWindowProc(Window, Msg, WParam, LParam) or WVR_REDRAW;
      end;
    WM_ERASEBKGND:
      begin
        Details := ThemeServices.GetElementDetails(tsStatusRoot);
        ThemeServices.DrawElement(HDC(WParam), Details, Control.ClientRect);
        Result := 1;
      end;
    else
      Result := WindowProc(Window, Msg, WParam, LParam);
  end;
end;

{ TWin32WSStatusBar }

class function TWin32WSStatusBar.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
var
  Params: TCreateWindowExParams;
begin
  // general initialization of Params
  PrepareCreateWindow(AWinControl, Params);
  // customization of Params
  with Params do
  begin
    Flags := Flags or CCS_NOPARENTALIGN;
    if TStatusBar(AWinControl).SizeGrip and TStatusBar(AWinControl).SizeGripEnabled then
      Flags := Flags or SBARS_SIZEGRIP;
    pClassName := STATUSCLASSNAME;
    WindowTitle := StrCaption;
    if ThemeServices.ThemesEnabled then
      SubClassWndProc := @StatusBarWndProc;
  end;
  // create window
  FinishCreateWindow(AWinControl, Params, false);
  Params.WindowInfo^.needParentPaint := false;
  // need to set handle for Update method
  AWinControl.Handle := Params.Window;
  Update(TStatusBar(AWinControl));
  Result := Params.Window;
end;

class procedure TWin32WSStatusBar.PanelUpdate(const AStatusBar: TStatusBar; PanelIndex: integer);
begin
  UpdateStatusBarPanelWidths(AStatusBar);
  UpdateStatusBarPanel(AStatusBar.Panels[PanelIndex]);
end;

class procedure TWin32WSStatusBar.GetPreferredSize(const AWinControl: TWinControl;
  var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean);
begin
  if (PreferredStatusBarHeight=0) then
    InitializePreferredStatusBarHeight;

  PreferredHeight := PreferredStatusBarHeight;
end;

class procedure TWin32WSStatusBar.SetPanelText(const AStatusBar: TStatusBar; PanelIndex: integer);
begin
  if AStatusBar.SimplePanel then
  {$ifdef WindowsUnicodeSupport}
    if UnicodeEnabledOS then
      Windows.SendMessage(AStatusBar.Handle, SB_SETTEXTW, 255, LPARAM(PWideChar(Utf8Decode(AStatusBar.SimpleText))))
    else
      Windows.SendMessage(AStatusBar.Handle, SB_SETTEXT, 255, LPARAM(PChar(Utf8ToAnsi(AStatusBar.SimpleText))))
  {$else}
    Windows.SendMessage(AStatusBar.Handle, SB_SETTEXT, 255, LPARAM(PChar(AStatusBar.SimpleText)))
  {$endif}
  else
    UpdateStatusBarPanel(AStatusBar.Panels[PanelIndex]);
end;

class procedure TWin32WSStatusBar.SetSizeGrip(const AStatusBar: TStatusBar;
  SizeGrip: Boolean);
var
  AStyle: Long;
begin
  if not WSCheckHandleAllocated(AStatusBar, 'SetSizeGrip') then
    Exit;
  AStyle := GetWindowLong(AStatusBar.Handle, GWL_STYLE);
  if ((AStyle and SBARS_SIZEGRIP) <> 0) <> (SizeGrip and AStatusBar.SizeGripEnabled) then
    RecreateWnd(AStatusBar);
end;

class procedure TWin32WSStatusBar.SetText(const AWinControl: TWinControl;
  const AText: string);
begin
  // inhibit. StatusBars do not have a caption, simpletext is set by SetPanelText
end;

class procedure TWin32WSStatusBar.Update(const AStatusBar: TStatusBar);
var
  PanelIndex: integer;
begin
  Windows.SendMessage(AStatusBar.Handle, SB_SIMPLE, WPARAM(AStatusBar.SimplePanel), 0);
  if AStatusBar.SimplePanel then
    SetPanelText(AStatusBar, 0)
  else
  begin
    UpdateStatusBarPanelWidths(AStatusBar);
    for PanelIndex := 0 to AStatusBar.Panels.Count - 1 do
      UpdateStatusBarPanel(AStatusBar.Panels[PanelIndex]);
  end;
end;

{ TWin32WSProgressBar }

class function TWin32WSProgressBar.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
var
  Params: TCreateWindowExParams;
begin
  // general initialization of Params
  PrepareCreateWindow(AWinControl, Params);
  // customization of Params
  with Params do
  begin
    with TCustomProgressBar(AWinControl) do
    begin
      if Smooth then
        Flags := Flags or PBS_SMOOTH;
      if (Orientation = pbVertical) or (Orientation = pbTopDown) then
        Flags := Flags or PBS_VERTICAL;
    end;
    pClassName := PROGRESS_CLASS;
  end;
  // create window
  FinishCreateWindow(AWinControl, Params, false);
  Result := Params.Window;
end;

class procedure TWin32WSProgressBar.ApplyChanges(
  const AProgressBar: TCustomProgressBar);
begin
  with AProgressBar do
  begin
    { smooth and vertical need window recreation }
    if ((GetWindowLong(Handle, GWL_STYLE) and PBS_SMOOTH  ) <>
         PtrInt(Smooth) * PBS_SMOOTH) or
       ((GetWindowLong(Handle, GWL_STYLE) and PBS_VERTICAL) <>
         PtrInt((Orientation = pbVertical) or (Orientation = pbTopDown)) * PBS_VERTICAL) then
      RecreateWnd(AProgressBar);

    SendMessage(Handle, PBM_SETRANGE32, Min, Max);
    SendMessage(Handle, PBM_SETPOS, Position, 0);

{ TODO: Implementable?
    If BarShowText Then
    Begin
      SetWindowText(Handle, StrToPChar((Sender As TControl).Caption));
    End
    Else
      SetWindowText(Handle, Nil);
}
  end;
end;

class procedure TWin32WSProgressBar.SetPosition(
  const AProgressBar: TCustomProgressBar; const NewPosition: integer);
begin
  Windows.SendMessage(AProgressBar.Handle, PBM_SETPOS, Windows.WPARAM(NewPosition), 0);
end;

{ TWin32WSToolbar}

{$ifdef OldToolbar}

class function TWin32WSToolBar.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
var
  Params: TCreateWindowExParams;
begin
  // general initialization of Params
  PrepareCreateWindow(AWinControl, Params);
  // customization of Params
  with Params do
  begin
    pClassName := TOOLBARCLASSNAME;
    Flags := Flags or CCS_ADJUSTABLE;
  end;
  // create window
  FinishCreateWindow(AWinControl, Params, false);
  Result := Params.Window;
end;

function  TWin32WSToolbar.GetButtonCount(const AToolBar: TToolBar): integer;
begin
  Result := SendMessage(AToolbar.Handle, TB_BUTTONCOUNT, 0, 0)
end;

class procedure TWin32WSToolbar.InsertToolButton(const AToolBar: TToolbar; const AControl: TControl);
var
  PStr, PStr2: PChar;
  Num: Integer;
  TBB: TBBUTTON;
begin
  // TODO: check correctness / clean up
  Assert(False, 'Trace:!!!!!!!!!!!!!!!!!!!!!!!!!');
  Assert(False, 'Trace:Toolbutton being inserted');
  Assert(False, 'Trace:!!!!!!!!!!!!!!!!!!!!!!!!!');
  If (AControl is TWinControl) Then
  Begin
    PStr := StrAlloc(Length(TToolButton(AControl).Caption) + 1);
    StrPCopy(PStr, TToolButton(AControl).Caption);
    PStr2 := StrAlloc(Length(TControl(AControl).Hint) + 1);
    StrPCopy(PStr2, TControl(AControl).Hint);
  End
  Else
  Begin
    Raise Exception.Create('Can not assign this control to the toolbar');
    Exit;
  End;

  Num := TToolbar(TWinControl(AControl).Parent).Buttonlist.IndexOf(TControl(AControl));
  If Num < 0 Then
    Num := TToolbar(TWinControl(AControl).Parent).Buttonlist.Count + 1;
  Assert(False, Format('Trace:Num = %d in LM_INSERTTOOLBUTTON', [Num]));

  With tbb Do
  Begin
    iBitmap := Num;
    idCommand := Num;
    fsState := TBSTATE_ENABLED;
    fsStyle := TBSTYLE_BUTTON;
    iString := Integer(PStr);
  End;

  SendMessage(TWinControl(AControl).Parent.Handle, TB_BUTTONSTRUCTSIZE, SizeOf(TBBUTTON), 0);
  SendMessage(TWinControl(AControl).Parent.Handle, TB_ADDBUTTONS, 1, LParam(LPTBButton(@tbb)));
  StrDispose(pStr);
  StrDispose(pStr2);
  Assert(False, 'Trace:!!!!!!!!!!!!!!!!!!!!!!!!!');
end;

class procedure TWin32WSToolbar.DeleteToolButton(const AToolBar: TToolbar; const AControl: TControl);
begin
  // TODO: code buggy, Index of button to delete ?!
  SendMessage(AToolBar.Handle, TB_DELETEBUTTON, 0, 0);
end;

{$endif}

function TrackBarWndProc(Window: HWnd; Msg: UInt; WParam: Windows.WParam;
    LParam: Windows.LParam): LResult; stdcall;
var
  WindowInfo: PWindowInfo;
  Control: TWinControl;
  FocusBorderWidth,
  FocusBorderHeight, Offset: Integer;
  R: TRect;
  Rgn: HRGN;
  Details: TThemedElementDetails;
  NMHdr: PNMHDR;
begin
  // Paul: next is a slightly modified code of TThemeManager.TrackBarWindowProc
  // of Mike Lischke Theme manager library (Mike granted us permition to use his code)
  case Msg of
    CN_NOTIFY:
      if ThemeServices.ThemesEnabled then
      begin
        NMHdr := PNMHDR(LParam);
        if NMHdr^.code = NM_CUSTOMDRAW then
        begin
          WindowInfo := GetWindowInfo(PNMHdr(LParam)^.hwndFrom);
          Control := WindowInfo^.WinControl;
          case PNMCustomDraw(LParam)^.dwDrawStage of
            CDDS_PREPAINT:
            begin
              Result := CDRF_NOTIFYITEMDRAW;
            end;
            CDDS_ITEMPREPAINT:
            begin
              case PNMCustomDraw(LParam)^.dwItemSpec of
                TBCD_TICS: // Before re-painting ticks redo whole background.
                  begin
                    R := Control.ClientRect;
                    // Leave room for the focus rectangle if there is one.
                    if Control.Focused and
                       ((Control.Perform(WM_QUERYUISTATE, 0, 0) and UISF_HIDEFOCUS) = 0) then
                    begin
                      SystemParametersInfo(SPI_GETFOCUSBORDERWIDTH, 0, @FocusBorderWidth, 0);
                      SystemParametersInfo(SPI_GETFOCUSBORDERHEIGHT, 0, @FocusBorderHeight, 0);
                      InflateRect(R, -FocusBorderWidth, -FocusBorderHeight);
                    end;
                    ThemeServices.DrawParentBackground(Window, PNMCustomDraw(LParam)^.hDC, nil, False, @R);
                  end;
                TBCD_CHANNEL:
                  begin
                    // Retrieve the bounding box for the thumb.
                    SendMessage(Window, TBM_GETTHUMBRECT, 0, Integer(@R));
                    // Extend this rectangle to the top/bottom or left/right border, respectively.
                    Offset := 0;
                    if TCustomTrackBar(Control).Orientation = trHorizontal then
                    begin
                      // Leave room for the focus rectangle if there is one.
                      if Control.Focused then
                      begin
                        SystemParametersInfo(SPI_GETFOCUSBORDERWIDTH, 0, @FocusBorderWidth, 0);
                        Inc(Offset, FocusBorderWidth);
                      end;
                      with Control.ClientRect do
                      begin
                        R.Left := Left + Offset;
                        R.Right := Right - Offset;
                      end;
                    end
                    else
                    begin
                      // Leave room for the focus rectangle if there is one.
                      if Control.Focused then
                      begin
                        SystemParametersInfo(SPI_GETFOCUSBORDERHEIGHT, 0, @FocusBorderHeight, 0);
                        Inc(Offset, FocusBorderWidth);
                      end;
                      with Control.ClientRect do
                      begin
                        R.Top := Top + Offset;
                        R.Bottom := Bottom - Offset;
                      end;
                    end;
                    with R do
                      Rgn := CreateRectRgn(Left, Top, Right, Bottom);
                    SelectClipRgn(PNMCustomDraw(LParam)^.hDC, Rgn);
                    Details := ThemeServices.GetElementDetails(ttbThumbTics);
                    ThemeServices.DrawParentBackground(Window, PNMCustomDraw(LParam)^.hDC, @Details, False);
                    DeleteObject(Rgn);
                    SelectClipRgn(PNMCustomDraw(LParam)^.hDC, 0);
                  end;
              end;
              Result := CDRF_DODEFAULT;
            end;
          end;
        end;
      end
      else
        Result := CallDefaultWindowProc(Window, Msg, WParam, LParam);
    else
      Result := WindowProc(Window, Msg, WParam, LParam);
  end;
end;

{ TWin32WSTrackBar }

class function TWin32WSTrackBar.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
var
  Params: TCreateWindowExParams;
begin
  // general initialization of Params
  PrepareCreateWindow(AWinControl, Params);
  // customization of Params
  with Params do
  begin
    pClassName := TRACKBAR_CLASS;
    WindowTitle := StrCaption;
    SubClassWndProc := @TrackBarWndProc;
  end;
  // create window
  FinishCreateWindow(AWinControl, Params, false);
  Params.WindowInfo^.ThemedCustomDraw := true;
  Result := Params.Window;
end;

class procedure TWin32WSTrackBar.ApplyChanges(const ATrackBar: TCustomTrackBar);
var
  wHandle: HWND;
  NewStyle: integer;
const
  StyleMask = TBS_AUTOTICKS or TBS_NOTICKS or TBS_VERT or TBS_TOP or TBS_BOTH;
  TickStyleStyle : array[TTickStyle] of integer =
    (TBS_NOTICKS, TBS_AUTOTICKS, 0);
  OrientationStyle : array[TTrackBarOrientation] of integer =
    (TBS_HORZ, TBS_VERT);
  TickMarksStyle : array[TTickMark] of integer =
    (TBS_BOTTOM, TBS_TOP, TBS_BOTH);
begin
  with ATrackBar do
  begin
    { cache handle }
    wHandle := Handle;
    NewStyle := TickStyleStyle[TickStyle] or OrientationStyle[Orientation] or
                TickMarksStyle[TickMarks];
    UpdateWindowStyle(wHandle, NewStyle, StyleMask);
    Windows.SendMessage(wHandle, TBM_SETRANGEMAX, Windows.WPARAM(true), Max);
    Windows.SendMessage(wHandle, TBM_SETRANGEMIN, Windows.WPARAM(true), Min);
    Windows.SendMessage(wHandle, TBM_SETPOS, Windows.WPARAM(true), Position);
    Windows.SendMessage(wHandle, TBM_SETLINESIZE, 0, LineSize);
    Windows.SendMessage(wHandle, TBM_SETPAGESIZE, 0, PageSize);
    Windows.SendMessage(wHandle, TBM_SETTICFREQ, Frequency, 0);
  end;
end;

class function TWin32WSTrackBar.GetPosition(const ATrackBar: TCustomTrackBar): integer;
begin
  Result := SendMessage(ATrackBar.Handle, TBM_GETPOS, 0, 0)
end;

class procedure TWin32WSTrackBar.SetPosition(const ATrackBar: TCustomTrackBar; const NewPosition: integer);
begin
  Windows.SendMessage(ATrackBar.Handle, TBM_SETPOS, Windows.WPARAM(true), Windows.LPARAM(NewPosition));
end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
  RegisterWSComponent(TStatusBar, TWin32WSStatusBar);
//  RegisterWSComponent(TCustomTabSheet, TWin32WSTabSheet);
//  RegisterWSComponent(TCustomPageControl, TWin32WSPageControl);
  RegisterWSComponent(TCustomListView, TWin32WSCustomListView);
//  RegisterWSComponent(TCustomListView, TWin32WSListView);
  RegisterWSComponent(TCustomProgressBar, TWin32WSProgressBar);
//  RegisterWSComponent(TCustomUpDown, TWin32WSCustomUpDown);
//  RegisterWSComponent(TCustomUpDown, TWin32WSUpDown);
//  RegisterWSComponent(TCustomToolButton, TWin32WSToolButton);
{$ifdef OldToolbar}
  RegisterWSComponent(TToolBar, TWin32WSToolBar);
{$endif}
  RegisterWSComponent(TCustomTrackBar, TWin32WSTrackBar);
//  RegisterWSComponent(TCustomTreeView, TWin32WSCustomTreeView);
//  RegisterWSComponent(TCustomTreeView, TWin32WSTreeView);
////////////////////////////////////////////////////

end.
