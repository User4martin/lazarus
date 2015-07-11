{ $Id: wsforms.pp 7361 2005-07-16 00:08:26Z marc $}
{
 *****************************************************************************
 *                                WSForms.pp                                 * 
 *                                ----------                                 * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit WinCEWSForms;

{$mode objfpc}{$H+}

interface

uses
  // RTL, FCL, LCL
  Windows, LCLProc, Classes,
  SysUtils, Controls, LCLType, Forms, InterfaceBase,
  // Widgetset
  winceproc, wincewscontrols, winceextra,
  WSForms, WSProc, WSLCLClasses;

type

  { TWinCEWSScrollingWinControl }

  TWinCEWSScrollingWinControl = class(TWSScrollingWinControl)
  published
    class procedure ScrollBy(const AWinControl: TScrollingWinControl;
      const DeltaX, DeltaY: integer); override;
  end;

  { TWinCEWSScrollBox }

  TWinCEWSScrollBox = class(TWSScrollBox)
  published
    class function CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): HWND; override;
  end;

  { TWinCEWSCustomFrame }

  TWinCEWSCustomFrame = class(TWSCustomFrame)
  private
  protected
  public
  end;

  { TWinCEWSFrame }

  TWinCEWSFrame = class(TWSFrame)
  private
  protected
  public
  end;

  { TWinCEWSCustomForm }

  TWinCEWSCustomForm = class(TWSCustomForm)
  private
    class function CalcBorderIconsFlags(const AForm: TCustomForm): dword;
    class procedure CalcFormWindowFlags(const AForm: TCustomForm;
      var Flags, FlagsEx: dword);
    class procedure CalculateDialogPosition(var Params: TCreateWindowExParams;
     Bounds: TRect; lForm: TCustomForm);
  published
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): HWND; override;

    class procedure SetBounds(const AWinControl: TWinControl;
      const ALeft, ATop, AWidth, AHeight: Integer); override;
    class procedure SetBorderIcons(const AForm: TCustomForm;
                                   const ABorderIcons: TBorderIcons); override;
    class procedure SetFormBorderStyle(const AForm: TCustomForm;
                             const AFormBorderStyle: TFormBorderStyle); override;
    class procedure SetIcon(const AForm: TCustomForm; const Small, Big: HICON); override;
    class procedure SetShowInTaskbar(const AForm: TCustomForm; const AValue: TShowInTaskbar); override;
    class procedure ShowModal(const ACustomForm: TCustomForm); override;
    class procedure ShowHide(const AWinControl: TWinControl); override;
  end;

  { TWinCEWSForm }

  TWinCEWSForm = class(TWSForm)
  private
  protected
  public
  end;

  { TWinCEWSHintWindow }

  TWinCEWSHintWindow = class(TWSHintWindow)
  private
  protected
  public
  end;

  { TWinCEWSScreen }

  TWinCEWSScreen = class(TWSScreen)
  private
  protected
  public
  end;

  { TWinCEWSApplicationProperties }

  TWinCEWSApplicationProperties = class(TWSApplicationProperties)
  private
  protected
  public
  end;


implementation

uses Winceint, wincewsmenus;

{ TWinCEWSScrollBox }

class function TWinCEWSScrollBox.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
var
  Params: TCreateWindowExParams;
begin
  // general initialization of Params
  PrepareCreateWindow(AWinControl, AParams, Params);
  // customization of Params
  with Params do
  begin
    //TODO: Make control respond to user scroll request
    if TScrollBox(AWinControl).BorderStyle = bsSingle then
      FlagsEx := FlagsEx or WS_EX_CLIENTEDGE;
    pClassName := @ClsName;
    Flags := Flags or WS_HSCROLL or WS_VSCROLL;
    SubClassWndProc := nil;
  end;
  // create window
  FinishCreateWindow(AWinControl, Params, false);
  Result := Params.Window;
end;

{ TWinCEWSScrollingWinControl }

class procedure TWinCEWSScrollingWinControl.ScrollBy(const AWinControl: TScrollingWinControl;
  const DeltaX, DeltaY: integer);
var
  rgn: HRGN;
  rect: trect;
begin
  rgn := 0; //roozbeh : seems to be ok?
  // GetClipRgn(AWinControl.Handle,rgn);
  // roozbeh:which flags really are required?!
  if Windows.IsWindowVisible(AWinControl.Handle) then
    {$ifdef win32}
    ScrollWindowPtr(AWinControl.Handle, DeltaX, DeltaY, nil, nil);
    {$else}
    ScrollWindowPtr(AWinControl.Handle, DeltaX, DeltaY, nil, nil,
      rgn, nil, SW_INVALIDATE or SW_ERASE or SW_SCROLLCHILDREN);
    {$endif}
end;

{ TWinCEWSCustomForm }

class function TWinCEWSCustomForm.CalcBorderIconsFlags(const AForm: TCustomForm): dword;
var
  BorderIcons: TBorderIcons;
begin
  Result := 0;
  BorderIcons := AForm.BorderIcons;
  if biSystemMenu in BorderIcons then
    Result := Result or WS_SYSMENU;
  if AForm.BorderStyle in [bsNone, bsSingle, bsSizeable] then
  begin
    if biMinimize in BorderIcons then
      Result := Result or WS_MINIMIZE;
    if biMaximize in BorderIcons then
      Result := Result or WS_MAXIMIZE;
  end;
end;

class procedure TWinCEWSCustomForm.CalcFormWindowFlags(const AForm: TCustomForm;
  var Flags, FlagsEx: dword);
var
  BorderStyle: TFormBorderStyle;
begin
  BorderStyle := AForm.BorderStyle;
  Flags := BorderStyleToWinAPIFlags(BorderStyle);
  if AForm.Parent <> nil then
    Flags := (Flags or WS_CHILD) and not WS_POPUP;
  FlagsEx := BorderStyleToWinAPIFlagsEx(AForm, BorderStyle);
  if (AForm.FormStyle in fsAllStayOnTop) then
    FlagsEx := FlagsEx or WS_EX_TOPMOST;
  Flags := Flags or CalcBorderIconsFlags(AForm);
end;

class procedure TWinCEWSCustomForm.CalculateDialogPosition(
  var Params: TCreateWindowExParams; Bounds: TRect; lForm: TCustomForm);
begin
  if lForm.Position in [poDefault, poDefaultPosOnly] then
  begin
    Params.Left := CW_USEDEFAULT;
    Params.Top := CW_USEDEFAULT;
  end
  else
  begin
    Params.Left := Bounds.Left;
    Params.Top := Bounds.Top;
  end;
  if lForm.Position in [poDefault, poDefaultSizeOnly] then
  begin
    Params.Width := CW_USEDEFAULT;
    Params.Height := CW_USEDEFAULT;
  end
  else
  begin
    Params.Width := Bounds.Right - Bounds.Left;
    Params.Height := Bounds.Bottom - Bounds.Top;
  end;
end;

{------------------------------------------------------------------------------
  Method: TWinCEWSCustomForm.CreateHandle
  Params:  None
  Returns: Nothing

  Creates a Windows CE Form, initializes it according to it�s properties and shows it
 ------------------------------------------------------------------------------}
class function TWinCEWSCustomForm.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
var
  Params: TCreateWindowExParams;
  LForm : TCustomForm;
  BorderStyle: TFormBorderStyle;
  WR: Windows.RECT;
  lWinBounds, lOldLCLBounds, lNewLCLBounds: TRect;
begin
  {$ifdef VerboseWinCE}
  DebugLn('TWinCEWSCustomForm.CreateHandle');
  {$endif}
  // general initialization of Params
  PrepareCreateWindow(AWinControl, AParams, Params);

  // customization of Params
  with Params do
  begin
    // Different from win32
    SubClassWndProc := nil; // Otherwise crash in wince, works in win32
    BorderStyle := TCustomForm(AWinControl).BorderStyle;

    // Same as in win32
    lForm := TCustomForm(AWinControl);
    CalcFormWindowFlags(lForm, Flags, FlagsEx);
    pClassName := @ClsName;
    WindowTitle := StrCaption;

    // Get the difference between the client and window sizes
    lWinBounds := lForm.BoundsRect;
    Windows.AdjustWindowRectEx(@lWinBounds, Flags, false, FlagsEx);

    if Application.ApplicationType in [atPDA, atKeyPadDevice, atDefault] then
    begin
      // Gets the work area
      Windows.SystemParametersInfo(SPI_GETWORKAREA, 0, @WR, 0);

      { The position and size of common windows is ignored on PDA mode,
        and a position and size that covers the whole workarea excluding
        the menu is used. The Workarea size automatically excludes the
        Taskbar.

        Simply using CM_USEDEFAULT produces a too large Height, which
        covers the menus. So the workarea size is detected (which ignores
        the Taskbar).

        In some devices subtracting the menu size seams to work better, but
        others, if no menu is present, it's a big problem.
      }
      if (BorderStyle <> bsDialog) and (BorderStyle <> bsNone) then
      begin
        Left := WR.Left;
        Top := WR.Top;
        Height := WR.Bottom - WR.Top;
        Width := WR.Right - WR.Left;

        // Update the position of the window for the LCL
        AWinControl.BoundsRect := Bounds(
          Params.Left, Params.Top, Params.Width, Params.Height);
      end
      else if (BorderStyle = bsDialog) then
      {
        For dialogs, the window is put in the middle of the screen.

        On normal dialogs we need to take into consideration the size of
        the window decoration.

        For the Top and Left coordinates, using CM_USEDEFAULT produces
        a wrong and bad result. Using the Workarea rectagle works fine
        for most devices, but not all, so we put the dialog in the center.
      }
      begin
        Top := WR.Top + (WR.Bottom - WR.Top) div 2
          - (lWinBounds.Bottom - lWinBounds.Top) div 2;
        Left := WR.Left + (WR.Right - WR.Left) div 2
          - (lWinBounds.Right - lWinBounds.Left) div 2;
        Height := lWinBounds.Bottom - lWinBounds.Top;
        Width := lWinBounds.Right - lWinBounds.Left;

        // Update the position of the window for the LCL
        lOldLCLBounds := lForm.BoundsRect;
        lNewLCLBounds.Left := Params.Left - (lWinBounds.Left - lOldLCLBounds.Left);
        lNewLCLBounds.Top := Params.Top - (lWinBounds.Top - lOldLCLBounds.Top);
        lNewLCLBounds.Right := Params.Left + Params.Width
          - (lWinBounds.Right - lOldLCLBounds.Right);
        lNewLCLBounds.Bottom := Params.Top + Params.Height
          - (lWinBounds.Bottom - lOldLCLBounds.Bottom);
        AWinControl.BoundsRect := lNewLCLBounds;
      end
      else { BorderStyle = bsNone }
      { On borderless Windows we allow the user full control of the
        window position
      }
      begin
        CalculateDialogPosition(Params, lWinBounds, lForm);
      end;
    end
    else
    begin
      { On Desktop mode we need to take into consideration the size of
        the window decoration }
      CalculateDialogPosition(Params, lWinBounds, lForm);
    end;
  end;

  // create window
  FinishCreateWindow(AWinControl, Params, false);
  Result := Params.Window;

  {$if defined(VerboseWinCE) or defined(VerboseSizeMsg)}
  DebugLn('Window Handle = ' + IntToStr(Result));
  {$endif}
end;

class procedure TWinCEWSCustomForm.SetBorderIcons(const AForm: TCustomForm;
 const ABorderIcons: TBorderIcons);
begin
  UpdateWindowStyle(AForm.Handle, CalcBorderIconsFlags(AForm),
    WS_SYSMENU or WS_MINIMIZEBOX or WS_MAXIMIZEBOX);
end;

class procedure TWinCEWSCustomForm.SetFormBorderStyle(const AForm: TCustomForm;
          const AFormBorderStyle: TFormBorderStyle);
begin
  RecreateWnd(AForm);
end;
                            
class procedure TWinCEWSCustomForm.SetBounds(const AWinControl: TWinControl;
    const ALeft, ATop, AWidth, AHeight: Integer);
var
  SizeRect: Windows.RECT;
  BorderStyle: TFormBorderStyle;
  WR: Windows.RECT;
begin
  { User selected LCL window size }
  SizeRect.Top := ATop;
  SizeRect.Left := ALeft;
  SizeRect.Bottom := ATop + AHeight;
  SizeRect.Right := ALeft + AWidth;

  BorderStyle := TCustomForm(AWinControl).BorderStyle;

  { Verifies if the size should be overriden, acording to the ApplicationType }
  if (Application.ApplicationType in [atPDA, atKeyPadDevice, atDefault]) then
  begin
    { We should never move forms which are in full-screen mode }
    if (BorderStyle <> bsDialog) and (BorderStyle <> bsNone) then Exit;

    { For dialogs, the window is put in the middle of the screen. }
    if (BorderStyle = bsDialog) then
    begin
      Windows.SystemParametersInfo(SPI_GETWORKAREA, 0, @WR, 0);
      SizeRect.Top := WR.Top + (WR.Bottom - WR.Top) div 2
          - AHeight div 2;
      SizeRect.Left := WR.Left + (WR.Right - WR.Left) div 2
          - AWidth div 2;
      SizeRect.Bottom := SizeRect.Top + AHeight;
      SizeRect.Right := SizeRect.Left + AWidth;
    end;
    { On borderless Windows we allow the user full control of the window position }
  end;

  { the LCL defines the size of a form without border, winceapi with.
    -> adjust size according to BorderStyle
    Must be done after setting sizeRect }
  Windows.AdjustWindowRectEx(@SizeRect, BorderStyleToWinAPIFlags(
      BorderStyle), false, BorderStyleToWinAPIFlagsEx(TCustomForm(AWinControl), BorderStyle));

  // rect adjusted, pass to inherited to do real work
  TWinCEWSWinControl.SetBounds(AWinControl, SizeRect.Left, SizeRect.Top,
    SizeRect.Right - SizeRect.Left, SizeRect.Bottom - SizeRect.Top);

  {$IFDEF VerboseSizeMsg}
  DebugLn(
    Format('[TWinCEWSCustomForm.SetBounds]: Name:%s Request x:%d y:%d w:%d h:%d'
    + ' SizeRect x:%d y:%d w:%d h:%d',
    [AWinControl.Name, ALeft, ATop, AWidth, AHeight,
    SizeRect.Left, SizeRect.Top,
    SizeRect.Right - SizeRect.Left, SizeRect.Bottom - SizeRect.Top]));
  {$ENDIF}
end;

class procedure TWinCEWSCustomForm.SetIcon(const AForm: TCustomForm; const Small, Big: HICON);
begin
  if not WSCheckHandleAllocated(AForm, 'SetIcon') then
    Exit;
  SendMessage(AForm.Handle, WM_SETICON, ICON_SMALL, LPARAM(Small));
  SendMessage(AForm.Handle, WM_SETICON, ICON_BIG, LPARAM(Big));
end;

class procedure TWinCEWSCustomForm.SetShowInTaskbar(const AForm: TCustomForm;
  const AValue: TShowInTaskbar);
begin
  if not WSCheckHandleAllocated(AForm, 'SetShowInTaskbar') then
    Exit;
  if (Application <> nil) and (AForm = Application.MainForm) then
    Exit;

  RecreateWnd(AForm);
end;

class procedure TWinCEWSCustomForm.ShowModal(const ACustomForm: TCustomForm);
begin
  ShowWindow(ACustomForm.Handle, SW_SHOW);
  BringWindowToTop(ACustomForm.Handle);
end;

class procedure TWinCEWSCustomForm.ShowHide(const AWinControl: TWinControl);
var
  lForm: TCustomForm absolute AWinControl;
begin
  TWinCEWSWinControl.ShowHide(AWinControl);

  {$ifndef Win32}
  // In atKeyPadDevice mode, we need to install the menu upon showing
  if (Application.ApplicationType = atKeyPadDevice) and
    lForm.HandleObjectShouldBeVisible then
  begin
    if (lForm.Menu = nil) then
      CeSetMenu(AWinControl.Handle, 0, nil)
    else
      CeSetMenu(AWinControl.Handle, lForm.Menu.Handle, lForm.Menu);
  end;
  {$endif}
end;

end.
