{ $Id: wscontrols.pp 7963 2005-10-12 22:22:02Z marc $}
{
 *****************************************************************************
 *                               WSControls.pp                               * 
 *                               -------------                               * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
unit WinCEWSControls;

{$mode objfpc}{$H+}

interface

uses
  // Libs
  Windows, commctrl,
  // RTL, LCL
  Classes,
  LCLType, Controls, Forms, Graphics,
  // Widgetset
  winceproc, WinCEInt, Sysutils, WSProc,
  WSLCLClasses, WSImgList, WSControls,
  InterfaceBase;

type
  { TWinCEWSDragImageList }

  TWinCEWSDragImageList = class(TWSDragImageList)
  published
    class function BeginDrag(const ADragImageList: TDragImageList; Window: HWND;
      AIndex, X, Y: Integer): Boolean; override;
    class function DragMove(const ADragImageList: TDragImageList; X, Y: Integer): Boolean; override;
    class procedure EndDrag(const ADragImageList: TDragImageList); override;
    class function HideDragImage(const ADragImageList: TDragImageList;
      ALockedWindow: HWND; DoUnLock: Boolean): Boolean; override;
    class function ShowDragImage(const ADragImageList: TDragImageList;
      ALockedWindow: HWND; X, Y: Integer; DoLock: Boolean): Boolean; override;
  end;

  { TWinCEWSControl }

  TWinCEWSControl = class(TWSControl)
  private
  protected
  public
  end;

  { TWinCEWSWinControlPrivate }

  TWinCEWSWinControlPrivate = class(TWSPrivate)
  private
  protected
  public
  end;
  TWinCEWSWinControlPrivateClass = class of TWinCEWSWinControlPrivate;


  { TWinCEWSWinControl }

  TWinCEWSWinControl = class(TWSWinControl)
  published
    class procedure AddControl(const AControl: TControl); override;

    class function  GetText(const AWinControl: TWinControl; var AText: String): Boolean; override;
    class procedure SetBounds(const AWinControl: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer); override;
    class procedure SetBorderStyle(const AWinControl: TWinControl; const ABorderStyle: TBorderStyle); override;
    class procedure SetChildZPosition(const AWinControl, AChild: TWinControl;
                                      const AOldPos, ANewPos: Integer;
                                      const AChildren: TFPList); override;
    class procedure SetColor(const AWinControl: TWinControl); override;
    class procedure SetFont(const AWinControl: TWinControl; const AFont: TFont); override;
    class procedure SetText(const AWinControl: TWinControl; const AText: string); override;

    class procedure ConstraintsChange(const AWinControl: TWinControl); override;
    class function  CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): HWND; override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;
    class procedure Invalidate(const AWinControl: TWinControl); override;
    class procedure ShowHide(const AWinControl: TWinControl); override;
  end;

  { TWinCEWSGraphicControl }

  TWinCEWSGraphicControl = class(TWSGraphicControl)
  private
  protected
  public
  end;

  { TWinCEWSCustomControl }

  TWinCEWSCustomControl = class(TWSCustomControl)
  private
  protected
  public
  end;

  { TWinCEWSImageList }

  TWinCEWSImageList = class(TWSImageList)
  private
  protected
  public
  end;

type
  TCreateWindowExParams = record
    Buddy, Parent, Window: HWND;
    Left, Top, Height, Width: integer;
    WindowInfo, BuddyWindowInfo: PWindowInfo;
    MenuHandle: HMENU;
    Flags, FlagsEx: dword;
    SubClassWndProc: pointer;
    WindowTitle, StrCaption: String;
    pClassName: PWideChar;
  end;

 // TODO: better names?

procedure PrepareCreateWindow(const AWinControl: TWinControl; var Params: TCreateWindowExParams);
procedure FinishCreateWindow(const AWinControl: TWinControl; var Params: TCreateWindowExParams;
  const AlternateCreateWindow: boolean);
procedure WindowCreateInitBuddy(const AWinControl: TWinControl;
  var Params: TCreateWindowExParams);


implementation

{ Global helper routines }

procedure PrepareCreateWindow(const AWinControl: TWinControl; var Params: TCreateWindowExParams);
begin
  Fillchar(Params,Sizeof(Params),0);
  with Params do
  begin
    Flags := WS_CHILD or WS_CLIPSIBLINGS or WS_CLIPCHILDREN;
    FlagsEx := 0;
    Assert(False, 'Trace:Setting flags');
    Window := HWND(Nil);
    Buddy := HWND(Nil);
    Assert(False, 'Trace:Setting window');

    if AWinControl.Parent <> nil then
      Parent := AWinControl.Parent.Handle
    else
      Parent := TWinCEWidgetSet(WidgetSet).AppHandle;

    SubClassWndProc := @WindowProc;
    StrCaption := AWinControl.Caption;
    WindowTitle := '';
    Height := AWinControl.Height;
    Left := AWinControl.Left;
    //Parent := AWinControl.Parent;
    Top := AWinControl.Top;
    Width := AWinControl.Width;
    if AWinControl.Visible then
      Flags := Flags or WS_VISIBLE;
    if csAcceptsControls in AWinControl.ControlStyle then
      FlagsEx := FlagsEx or WS_EX_CONTROLPARENT;
    if AWinControl.TabStop then
      Flags := Flags or WS_TABSTOP;
    Assert(False, 'Trace:Setting dimentions');
    LCLBoundsToWin32Bounds(AWinControl, Left, Top, Width, Height);
    if AWinControl is TCustomControl then
      if TCustomControl(AWinControl).BorderStyle = bsSingle then
        FlagsEx := FlagsEx or WS_EX_CLIENTEDGE;
    {$IFDEF VerboseSizeMsg}
    writeln('PrepareCreateWindow ',AWinControl.Name,':',AWinControl.ClassName,' ',Left,',',Top,',',Width,',',Height);
    {$ENDIF}

    //Assert(False, Format('Trace:PrepareCreateWindow - Creating component %S with the caption of %S', [AWinControl.ClassName, AWinControl.Caption]));
    //Assert(False, Format('Trace:PrepareCreateWindow - Left: %D, Top: %D, Width: %D, Height: %D, Parent handle: 0x%X, instance handle: 0x%X', [Left, Top, Width, Height, Parent, HInstance]));
  end;
end;

procedure FinishCreateWindow(const AWinControl: TWinControl; var Params: TCreateWindowExParams;
  const AlternateCreateWindow: boolean);
var
  lhFont: HFONT;
begin
  if not AlternateCreateWindow then
  begin
    with Params do
    begin
      if (Flags and WS_CHILD) <> 0 then
      begin
        // menu handle is also for specifying a control id if this is a child
        MenuHandle := HMENU(AWinControl);
      end else begin
        MenuHandle := HMENU(nil);
      end;

      Window := CreateWindowExW(
       FlagsEx,            // Extra Flags
       pClassName,         // Name of the registered class
       PWideChar(UTF8Decode(WindowTitle)),// Title of the window
       Flags,              // Style of the window
       Left,               // x-position (at beginning)
       Top,                // y-position (at beginning)
       Width,              // window width
       Height,             // window height
       Parent,             // handle to parent or owner window
       MenuHandle,         // handle to menu
       System.HInstance,   // handle to application instance
       nil);               // pointer to window-creation data

      if Window = 0 then
      begin
        raise exception.create('failed to create win32 control, error: '+IntToStr(GetLastError())
         + ' WindowTitle: ' + WindowTitle);
      end;
    end;
    { after creating a child window the following happens:
      1) the previously bottom window is thrown to the top
      2) the created window is added at the bottom
      undo this by throwing them both to the bottom again }
    { not needed anymore, tab order is handled entirely by LCL now
    Windows.SetWindowPos(Windows.GetTopWindow(Parent), HWND_BOTTOM, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
    Windows.SetWindowPos(Window, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
    }
  end;
  with Params do
  begin
    if Window <> HWND(Nil) then
    begin
      // some controls (combobox) immediately send a message upon setting font
      WindowInfo := AllocWindowInfo(Window);
      WindowInfo^.myButton := Window;
      if GetWindowInfo(Parent)^.needParentPaint then
        WindowInfo^.needParentPaint := true;
      WindowInfo^.WinControl := AWinControl;
      AWinControl.Handle := Window;
      if SubClassWndProc <> nil then
        WindowInfo^.DefWndProc := Windows.WNDPROC(Windows.SetWindowLong(
          Window, GWL_WNDPROC, LongInt(SubClassWndProc)));
      if AWinControl.Font.IsDefault then
        lhFont := GetStockObject(DEFAULT_GUI_FONT)
      else
        lhFont := AWinControl.Font.Reference.Handle;
      Windows.SendMessage(Window, WM_SETFONT, lhFont, 0)
    end;
  end;
end;

procedure WindowCreateInitBuddy(const AWinControl: TWinControl;
  var Params: TCreateWindowExParams);
var
  lhFont: HFONT;
begin
  with Params do
    if Buddy <> HWND(Nil) then
    begin
      BuddyWindowInfo := AllocWindowInfo(Buddy);
      BuddyWindowInfo^.AWinControl := AWinControl;
      BuddyWindowInfo^.DefWndProc := Windows.WNDPROC(Windows.SetWindowLong(
        Buddy, GWL_WNDPROC, LongInt(SubClassWndProc)));
      if AWinControl.Font.IsDefault then
        lhFont := GetStockObject(DEFAULT_GUI_FONT)
      else
        lhFont := AWinControl.Font.Reference.Handle;
      Windows.SendMessage(Buddy, WM_SETFONT, lhFont, 0);
    end
    else
      BuddyWindowInfo := nil;
end;


{ TWinCEWSWinControl }

class function TWinCEWSWinControl.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
var
  Params: TCreateWindowExParams;
begin
  {$ifdef VerboseWinCE}
  writeln(' TWinCEWSWinControl.CreateHandle ');
  {$endif}
  // general initialization of Params
  PrepareCreateWindow(AWinControl, Params);
  // customization of Params
  with Params do
  begin
    pClassName := @ClsName;
    WindowTitle := StrCaption;
    SubClassWndProc := nil;
  end;
  // create window
  FinishCreateWindow(AWinControl, Params, false);
  Result := Params.Window;
end;

class procedure TWinCEWSWinControl.AddControl(const AControl: TControl);
var
  ParentPanelHandle, ParentHandle, ChildHandle: HWND;
begin
  {$ifdef OldToolbar}
  if (AControl.Parent is TToolbar) then
    exit;
  {$endif}

  with TWinControl(AControl) do
  begin
    Assert(False, Format('Trace:[TWinCEWSWinControl.AddControl] %S --> Calling Add Child: %S', [Parent.ClassName, ClassName]));
    ParentHandle := Parent.Handle;
    ChildHandle := Handle;
  end;

  Assert(False, 'Trace:AddControl - Parent Window Handle is $' + IntToHex(LongInt(ParentHandle), 8));
  Assert(False, 'Trace:AddControl - Child Window Handle is $' + IntToHex(LongInt(ChildHandle), 8));
  // handle groupbox exception
  ParentPanelHandle := GetWindowInfo(ChildHandle)^.ParentPanel;
  if ParentPanelHandle <> 0 then
    ChildHandle := ParentPanelHandle;
  SetParent(ChildHandle, ParentHandle);
end;

class function  TWinCEWSWinControl.GetText(const AWinControl: TWinControl; var AText: String): Boolean;
begin
  AText := '';
  Result := false;
end;

class procedure TWinCEWSWinControl.SetBorderStyle(const AWinControl: TWinControl; const ABorderStyle: TBorderStyle);
begin
  RecreateWnd(AWinControl);
end;

class procedure TWinCEWSWinControl.SetChildZPosition(
  const AWinControl, AChild: TWinControl; const AOldPos, ANewPos: Integer;
  const AChildren: TFPList);
var
  AfterWnd: hWnd;
  n, StopPos: Integer;
  Child: TWinControl;
begin
  if not WSCheckHandleAllocated(AWincontrol, 'SetChildZPosition')
  then Exit;
  if not WSCheckHandleAllocated(AChild, 'SetChildZPosition (child)')
  then Exit;

  if ANewPos = 0 // bottom
  then AfterWnd := HWND_BOTTOM
  else if ANewPos >= AChildren.Count - 1
  then AfterWnd := HWND_TOP
  else begin
    // Search for the first child above us with a handle
    // the child list is reversed form the windows order.
    // So the first window is the top window and is the last child
    // if we don't find a allocated handle then we are effectively not moved
    AfterWnd := 0;
    if AOldPos > ANewPos
    then StopPos := AOldPos              // The child is moved to the bottom, oldpos is on top of it
    else StopPos := AChildren.Count - 1; // the child is moved to the top

    for n := ANewPos + 1 to StopPos do
    begin
      Child := TWinControl(AChildren[n]);
      if Child.HandleAllocated
      then begin
        AfterWnd := Child.Handle;
        Break;
      end;
    end;

    if AfterWnd = 0 then Exit; // nothing to do
  end;
  Windows.SetWindowPos(AChild.Handle, AfterWnd, 0, 0, 0, 0,
    SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOOWNERZORDER or
    SWP_NOSIZE or SWP_NOSENDCHANGING);
end;

{------------------------------------------------------------------------------
  Method:  SetBounds
  Params:  AWinControl                  - the object which invoked this function
           ALeft, ATop, AWidth, AHeight - new dimensions for the control
  Pre:     AWinControl.HandleAllocated
  Returns: Nothing

  Resize a window
 ------------------------------------------------------------------------------}
class procedure TWinCEWSWinControl.SetBounds(const AWinControl: TWinControl;
  const ALeft, ATop, AWidth, AHeight: Integer);
var
  IntfLeft, IntfTop, IntfWidth, IntfHeight: integer;
  suppressMove: boolean;
begin
  IntfLeft := ALeft; IntfTop := ATop;
  IntfWidth := AWidth; IntfHeight := AHeight;
  LCLBoundsToWin32Bounds(AWinControl, IntfLeft, IntfTop, IntfWidth, IntfHeight);
  {$IFDEF VerboseSizeMsg}
  writeln('TWinCEWSWinControl.ResizeWindow A ',AWinControl.Name,':',AWinControl.ClassName,
    ' LCL=',ALeft,',',ATop,',',AWidth,',',AHeight,
    ' Win32=',IntfLeft,',',IntfTop,',',IntfWidth,',',IntfHeight,
    '');
  {$ENDIF}
  suppressMove := false;
  AdaptBounds(AWinControl, IntfLeft, IntfTop, IntfWidth, IntfHeight, suppressMove);

  // Why would we want to supress the move?
  // Form moving is indispensable to have message dialogs

  MoveWindow(AWinControl.Handle, IntfLeft, IntfTop, IntfWidth, IntfHeight, true);

  LCLControlSizeNeedsUpdate(AWinControl, false);
end;

class procedure TWinCEWSWinControl.SetColor(const AWinControl: TWinControl);
begin
  // TODO: to be implemented, had no implementation in LM_SETCOLOR message
end;

class procedure TWinCEWSWinControl.SetFont(const AWinControl: TWinControl; const AFont: TFont);
begin
  Windows.SendMessage(AWinControl.Handle, WM_SETFONT, Windows.WParam(AFont.Reference.Handle), 1);
end;

class procedure TWinCEWSWinControl.SetText(const AWinControl: TWinControl; const AText: string);
begin
  if not WSCheckHandleAllocated(AWincontrol, 'SetText') then Exit;

  Windows.SetWindowTextW(AWinControl.Handle, PWideChar(UTF8Decode(AText)));
end;

class procedure TWinCEWSWinControl.ConstraintsChange(const AWinControl: TWinControl);
begin
  // TODO: implement me!
end;

class procedure TWinCEWSWinControl.DestroyHandle(const AWinControl: TWinControl);
var
  Handle: HWND;
  AccelTable: HACCEL;
begin
  Handle := AWinControl.Handle;
//  AccelTable := GetWindowInfo(Handle)^.Accel;
//  if AccelTable <> 0 then
//    DestroyAcceleratorTable(AccelTable);
  DestroyWindow(Handle);
end;

class procedure TWinCEWSWinControl.Invalidate(const AWinControl: TWinControl);
begin
  // lpRect = nil updates entire client area of window
  InvalidateRect(AWinControl.Handle, nil, true);
end;

class procedure TWinCEWSWinControl.ShowHide(const AWinControl: TWinControl);
begin
  // other methods also use ShowHide, can't move code
  TWinCEWidgetSet(WidgetSet).ShowHide(AWinControl);
end;

{ TWinCEWSDragImageList }

class function TWinCEWSDragImageList.BeginDrag(
  const ADragImageList: TDragImageList; Window: HWND; AIndex, X, Y: Integer): Boolean;
begin
  // No check to Handle should be done, because if there is no handle (no needed)
  // we must create it here. This is normal for imagelist (we can never need handle)
  Result := ImageList_BeginDrag(ADragImageList.Reference.Handle, AIndex, X, Y);
end;

class function TWinCEWSDragImageList.DragMove(const ADragImageList: TDragImageList;
  X, Y: Integer): Boolean;
begin
  Result := ImageList_DragMove(X, Y);
end;

class procedure TWinCEWSDragImageList.EndDrag(const ADragImageList: TDragImageList);
begin
  ImageList_EndDrag;
end;

class function TWinCEWSDragImageList.HideDragImage(const ADragImageList: TDragImageList;
  ALockedWindow: HWND; DoUnLock: Boolean): Boolean;
begin
  if DoUnLock then
    Result := ImageList_DragLeave(ALockedWindow)
  else
    Result := ImageList_DragShowNolock(False);
end;

class function TWinCEWSDragImageList.ShowDragImage(const ADragImageList: TDragImageList;
  ALockedWindow: HWND; X, Y: Integer; DoLock: Boolean): Boolean;
begin
  if DoLock then
    Result := ImageList_DragEnter(ALockedWindow, X, Y)
  else
    Result := ImageList_DragShowNolock(True);
end;

initialization

////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
  RegisterWSComponent(TDragImageList, TWinCEWSDragImageList);
//  RegisterWSComponent(TControl, TWinCEWSControl);
  RegisterWSComponent(TWinControl, TWinCEWSWinControl);
//  RegisterWSComponent(TGraphicControl, TWSGraphicControl);
//  RegisterWSComponent(TCustomControl, TWSCustomControl);
//  RegisterWSComponent(TImageList, TWSImageList);
////////////////////////////////////////////////////
end.
