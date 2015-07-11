{
 *****************************************************************************
 *                               WSControls.pp                               * 
 *                               -------------                               * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit Gtk3WSControls;

{$mode objfpc}{$H+}
{$I gtk3defines.inc}

interface
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// 1) Only class methods allowed
// 2) Class methods have to be published and virtual
// 3) To get as little as posible circles, the uses
//    clause should contain only those LCL units 
//    needed for registration. WSxxx units are OK
// 4) To improve speed, register only classes in the 
//    initialization section which actually 
//    implement something
// 5) To enable your XXX widgetset units, look at
//    the uses clause of the XXXintf.pp
////////////////////////////////////////////////////
uses
  Classes,
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
  Controls, Graphics, LCLType, Types, LCLProc,
////////////////////////////////////////////////////
  WSLCLClasses, WSControls, WSProc, LazGtk3, LazGdk3, LazGlib2, LazGObject2,
  gtk3widgets, LazPango1,
  { TODO: remove when CreateHandle/Component code moved }
  InterfaceBase;

type
  { TGtk3WSDragImageList }

  TGtk3WSDragImageList = class(TWSDragImageList)
  published
    class function BeginDrag(const ADragImageList: TDragImageList; Window: HWND; AIndex, X, Y: Integer): Boolean; override;
    class function DragMove(const ADragImageList: TDragImageList; X, Y: Integer): Boolean; override;
    class procedure EndDrag(const ADragImageList: TDragImageList); override;
    class function HideDragImage(const ADragImageList: TDragImageList;
      ALockedWindow: HWND; DoUnLock: Boolean): Boolean; override;
    class function ShowDragImage(const ADragImageList: TDragImageList;
      ALockedWindow: HWND; X, Y: Integer; DoLock: Boolean): Boolean; override;
  end;

  TGtk3WSDragImageListClass = class of TGtk3WSDragImageList;


  { TGtk3WSControl }

  TGtk3WSControl = class(TWSControl)
  end;

  TGtk3WSControlClass = class of TGtk3WSControl;


  { TGtk3WSWinControl }

  TGtk3WSWinControl = class(TWSWinControl)
  published
    class procedure AddControl(const AControl: TControl); override;
    class function  CanFocus(const AWincontrol: TWinControl): Boolean; override;
    
    class function  GetClientBounds(const AWincontrol: TWinControl; var ARect: TRect): Boolean; override;
    class function  GetClientRect(const AWincontrol: TWinControl; var ARect: TRect): Boolean; override;
    class procedure GetPreferredSize(const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean); override;
    class function  GetDefaultClientRect(const AWinControl: TWinControl; const aLeft, aTop, aWidth, aHeight: integer; var aClientRect: TRect): boolean; override;
    class function GetDesignInteractive(const AWinControl: TWinControl; AClientPos: TPoint): Boolean; override;
    class function  GetText(const AWinControl: TWinControl; var AText: String): Boolean; override;
    class function  GetTextLen(const AWinControl: TWinControl; var ALength: Integer): Boolean; override;

    class procedure SetBiDiMode(const AWinControl: TWinControl; UseRightToLeftAlign, UseRightToLeftReading, UseRightToLeftScrollBar : Boolean); override;
    class procedure SetBorderStyle(const AWinControl: TWinControl; const ABorderStyle: TBorderStyle); override;
    class procedure SetBounds(const AWinControl: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer); override;
    class procedure SetColor(const AWinControl: TWinControl); override;
    class procedure SetChildZPosition(const AWinControl, AChild: TWinControl; const AOldPos, ANewPos: Integer; const AChildren: TFPList); override;
    class procedure SetFont(const AWinControl: TWinControl; const AFont: TFont); override;
    class procedure SetPos(const AWinControl: TWinControl; const ALeft, ATop: Integer); override;
    class procedure SetSize(const AWinControl: TWinControl; const AWidth, AHeight: Integer); override;
    class procedure SetText(const AWinControl: TWinControl; const AText: String); override;
    class procedure SetCursor(const AWinControl: TWinControl; const ACursor: HCursor); override;
    class procedure SetShape(const AWinControl: TWinControl; const AShape: HBITMAP); override;

    { TODO: move AdaptBounds: it is only used in winapi interfaces }
    class procedure AdaptBounds(const AWinControl: TWinControl;
          var Left, Top, Width, Height: integer; var SuppressMove: boolean); override;
          
    class procedure ConstraintsChange(const AWinControl: TWinControl); override;
    class function  CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;
    class procedure DefaultWndHandler(const AWinControl: TWinControl; var AMessage); override;
    class procedure Invalidate(const AWinControl: TWinControl); override;
    class procedure PaintTo(const AWinControl: TWinControl; ADC: HDC; X, Y: Integer); override;
    class procedure ShowHide(const AWinControl: TWinControl); override; //TODO: rename to SetVisible(control, visible)
  end;
  TGtk3WSWinControlClass = class of TGtk3WSWinControl;


  { TGtk3WSCustomControl }

  TGtk3WSCustomControl = class(TGtk3WSWinControl)
  published
    class function CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLIntfHandle; override;
  end;


implementation
uses SysUtils, gtk3objects, gtk3procs;

{ TGtk3WSWinControl }

class procedure TGtk3WSWinControl.AdaptBounds(const AWinControl: TWinControl;
  var Left, Top, Width, Height: integer; var SuppressMove: boolean);
begin
  {$IFDEF GTK3DEBUGCORE}
  DebugLn('TGtk3WSWinControl.AdaptBounds');
  {$ENDIF}
end;

class procedure TGtk3WSWinControl.ConstraintsChange(const AWinControl: TWinControl);
begin
  {$IFDEF GTK3DEBUGCORE}
  DebugLn('TGtk3WSWinControl.ConstraintsChange');
  {$ENDIF}
end;

class function TGtk3WSWinControl.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
begin
  // For now default to the old creation routines
  {$IFDEF GTK3DEBUGCORE}
  DebugLn('TGtk3WSWinControl.CreateHandle');
  {$ENDIF}
  Result := 0;
end;

class procedure TGtk3WSWinControl.DestroyHandle(const AWinControl: TWinControl);
begin
  {$IFDEF GTK3DEBUGCORE}
  DebugLn('TGtk3WSWinControl.DestroyHandle ',dbgsName(AWinControl),' handle ',dbgs(AWinControl.HandleAllocated));
  {$ENDIF}
  if AWinControl.HandleAllocated then
  begin
    TGtk3Widget(AWinControl.Handle).Free;
  end;
end;

class procedure TGtk3WSWinControl.DefaultWndHandler(const AWinControl: TWinControl; var AMessage);
begin
  // WidgetSet.CallDefaultWndHandler(AWinControl, AMessage);
  {$IFDEF GTK3DEBUGCORE}
  DebugLn('TGtk3WSWinControl.DefaultWndHandler');
  {$ENDIF}
end;

class procedure TGtk3WSWinControl.AddControl(const AControl: TControl);
var
  AHandle: TGtk3Widget;
  AWidget: PGtkWidget;
  AParent: TWinControl;
  AChild: PGtkWidget;
begin
  if not WSCheckHandleAllocated(TWinControl(AControl), 'AddControl') then
    Exit;
  AParent := TWinControl(AControl).Parent;
  AHandle := TGtk3Widget(AParent.Handle);
  AWidget := AHandle.Widget;

  {$IF DEFINED(GTK3DEBUGCORE) OR DEFINED(GTK3DEBUGSIZE) OR DEFINED(GTK3DEBUGREPARENTING)}
  DebugLn('TGtk3WSWinControl.AddControl ',dbgsName(AControl),' LEFT=',dbgs(AControl.Left),' TOP=',dbgs(AControl.Top),
    ' PARENT=',dbgsName(AParent));
  {$ENDIF}

  // better use this, since it sets position imediatelly if its child of container
  // so, reduce flickering.
  TGtk3Widget(TWinControl(AControl).Handle).SetParent(AHandle, AControl.Left, AControl.Top);
end;

class function TGtk3WSWinControl.CanFocus(const AWincontrol: TWinControl): Boolean;
begin
  // lets consider that by deafult all WinControls can be focused
  Result := False;
  if AWinControl.HandleAllocated then
    Result := TGtk3Widget(AWinControl.Handle).CanFocus;
  {$IF DEFINED(GTK3DEBUGCORE) OR DEFINED(GTK3DEBUGFOCUS)}
  DebugLn('TGtk3WSWinControl.CanFocus ',dbgsName(AWinControl),' result ',dbgs(Result));
  {$ENDIF}
end;

class function TGtk3WSWinControl.GetClientBounds(const AWincontrol: TWinControl; var ARect: TRect): Boolean;
begin
  // for now default to the WinAPI version
  {$IF DEFINED(GTK3DEBUGCORE) OR DEFINED(GTK3DEBUGSIZE)}
  DebugLn('TGtk3WSWinControl.GetClientBounds ',dbgsName(AWinControl));
  {$ENDIF}
  Result := False;
  if AWinControl.HandleAllocated then
  begin
    ARect := TGtk3Widget(AWinControl.Handle).getClientBounds;
    Result := True;
  end else
    ARect := Rect(0, 0, 0, 0);

  //TODO: USE winapi version
    // Gtk3WidgetSet.GetClientBounds(AWincontrol.Handle, ARect);
end;

class function TGtk3WSWinControl.GetClientRect(const AWincontrol: TWinControl; var ARect: TRect): Boolean;
begin
  // for now default to the WinAPI version
  {$IF DEFINED(GTK3DEBUGCORE) OR DEFINED(GTK3DEBUGSIZE)}
  DebugLn('TGtk3WSWinControl.GetClientRect ',dbgsName(AWinControl));
  {$ENDIF}
  //TODO: USE winapi version
  Result := False;
  if AWinControl.HandleAllocated then
  begin
    ARect := TGtk3Widget(AWinControl.Handle).getClientRect;
    Result := True;
  end else
    ARect := Rect(0, 0, 0, 0);
  // Result := Gtk3WidgetSet.GetClientRect(AWincontrol.Handle, ARect);
end;

{------------------------------------------------------------------------------
  Function: TGtk3WSWinControl.GetText
  Params:  Sender: The control to retrieve the text from
  Returns: the requested text

  Retrieves the text from a control. 
 ------------------------------------------------------------------------------}
class function TGtk3WSWinControl.GetText(const AWinControl: TWinControl; var AText: String): Boolean;
begin
  Result := False;
  if not WSCheckHandleAllocated(AWinControl, 'GetText') then
    Exit;
  {$IFDEF GTK3DEBUGCORE}
  DebugLn('TGtk3WSWinControl.GetText ',dbgsName(AWinControl));
  {$ENDIF}
  AText := TGtk3Widget(AWinControl.Handle).Text;
  Result := True;
end;
  
class function TGtk3WSWinControl.GetTextLen(const AWinControl: TWinControl; var ALength: Integer): Boolean;
var
  S: String;
begin
  {$IFDEF GTK3DEBUGCORE}
  DebugLn('TGtk3WSWinControl.GetTextLen');
  {$ENDIF}
  Result := GetText(AWinControl, S);
  if Result
  then ALength := Length(S);
end;

class procedure TGtk3WSWinControl.SetBiDiMode(const AWinControl: TWinControl; UseRightToLeftAlign, UseRightToLeftReading, UseRightToLeftScrollBar : Boolean);
begin
  {$IFDEF GTK3DEBUGCORE}
  DebugLn('TGtk3WSWinControl.SetBiDiMode');
  {$ENDIF}
end;

class procedure TGtk3WSWinControl.GetPreferredSize(const AWinControl: TWinControl;
  var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean);
begin
  {$IFDEF GTK3DEBUGCORE}
  DebugLn('TGtk3WSWinControl.GetPreferredSize');
  {$ENDIF}
  PreferredWidth := 0;
  PreferredHeight := 0;
end;

class function TGtk3WSWinControl.GetDefaultClientRect(
  const AWinControl: TWinControl; const aLeft, aTop, aWidth, aHeight: integer;
  var aClientRect: TRect): boolean;
begin
  {$IFDEF GTK3DEBUGCORE}
  DebugLn('TGtk3WSWinControl.GetDefaultClientRect ',dbgsName(AWinControl),' handle=',dbgs(AWinControl.HandleAllocated));
  {$ENDIF}
  Result:=false;
end;

class function TGtk3WSWinControl.GetDesignInteractive(
  const AWinControl: TWinControl; AClientPos: TPoint): Boolean;
begin
  {$IFDEF GTK3DEBUGCORE}
  DebugLn('TGtk3WSWinControl.GetDesignInteractive');
  {$ENDIF}
  Result := False;
end;

class procedure TGtk3WSWinControl.Invalidate(const AWinControl: TWinControl);
begin
  if not WSCheckHandleAllocated(AWinControl, 'Invalidate') then
    Exit;
  {$IFDEF GTK3DEBUGCORE}
  DebugLn('TGtk3WSWinControl.Invalidate');
  {$ENDIF}
  TGtk3Widget(AWinControl.Handle).Update(nil);
end;

class procedure TGtk3WSWinControl.PaintTo(const AWinControl: TWinControl; ADC: HDC;
  X, Y: Integer);
begin
  if not WSCheckHandleAllocated(AWincontrol, 'PaintTo') or (ADC = 0) then
    Exit;
  {.$IFDEF GTK3DEBUGCORE}
  DebugLn('WARNING: TGtk3WSWinControl.PaintTo not implemented');
  {.$ENDIF}
end;

class procedure TGtk3WSWinControl.SetBounds(const AWinControl: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer);
var
  AWidget: PGtkWidget;
  ARect: TGdkRectangle;
  Alloc: TGtkAllocation;
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetBounds') then
    Exit;
  {$IF DEFINED(GTK3DEBUGCORE) OR DEFINED(GTK3DEBUGSIZE)}
  DebugLn('TGtk3WSWinControl.SetBounds ',dbgsName(AWinControl),Format(' ALeft %d ATop %d AWidth %d AHeight %d',[ALeft, ATop, AWidth, AHeight]));
  {$ENDIF}
  AWidget := TGtk3Widget(AWinControl.Handle).Widget;
  ARect.x := ALeft;
  ARect.y := ATop;
  ARect.width := AWidth;
  ARect.Height := AHeight;
  with Alloc do
  begin
    x := ALeft;
    y := ATop;
    width := AWidth;
    height := AHeight;
  end;
  TGtk3Widget(AWinControl.Handle).BeginUpdate;
  try
    AWidget^.size_allocate(@ARect);
    AWidget^.set_size_request(AWidth, AHeight);
    if AWinControl.Parent <> nil then
      TGtk3Widget(AWinControl.Handle).move(ALeft, ATop);
    // we must trigger get_preferred_width after changing size
    if wtProgressBar in TGtk3Widget(AWinControl.Handle).WidgetType then
      TGtk3Widget(AWinControl.Handle).getContainerWidget^.set_size_request(AWidth, AHeight);
  finally
    TGtk3Widget(AWinControl.Handle).EndUpdate;
  end;

  {$IF DEFINED(GTK3DEBUGCORE) OR DEFINED(GTK3DEBUGSIZE)}
  DebugLn('TGtk3WSWinControl.SetBounds ',dbgsName(AWinControl),' isRealized=',dbgs(AWidget^.get_realized),
    ' IsMapped=',dbgs(AWidget^.get_mapped));
  {$ENDIF}

end;
    
class procedure TGtk3WSWinControl.SetBorderStyle(const AWinControl: TWinControl; const ABorderStyle: TBorderStyle);
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetBorderStyle') then
    Exit;
  {$IFDEF GTK3DEBUGCORE}
  DebugLn('TGtk3WSWinControl.SetBorderStyle');
  {$ENDIF}
end;

class procedure TGtk3WSWinControl.SetChildZPosition(
  const AWinControl, AChild: TWinControl; const AOldPos, ANewPos: Integer;
  const AChildren: TFPList);
var
  Reorder: TFPList;
  n: Integer;
  Child: TWinControl;
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetChildZPosition') then
    Exit;
  if not WSCheckHandleAllocated(AChild, 'SetChildZPosition (child)') then
    Exit;
  {$IFDEF GTK3DEBUGCORE}
  DebugLn('TGtk3WSWinControl.SetChildZPosition');
  {$ENDIF}
  if (ANewPos <= 0) or (ANewPos >= AChildren.Count - 1) then
  begin
    // simple
    if ANewPos <= 0 then // bottom
      TGtk3Widget(AChild.Handle).lowerWidget
    else
      TGtk3Widget(AChild.Handle).raiseWidget;
  end else
  begin
    if (ANewPos >= 0) and (ANewPos < AChildren.Count -1) then
    begin
      Reorder := TFPList.Create;
      for n := AChildren.Count - 1 downto 0 do
        Reorder.Add(AChildren[n]);
      Child := TWinControl(Reorder[ANewPos + 1]);
      if Child.HandleAllocated then
        TGtk3Widget(AChild.Handle).stackUnder(TGtk3Widget(Child.Handle).Widget)
      else
        TGtk3Widget(AChild.Handle).lowerWidget;
      Reorder.Free;
    end;
  end;
end;

class procedure TGtk3WSWinControl.SetColor(const AWinControl: TWinControl);
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetColor') then
    Exit;
  {$IFDEF GTK3DEBUGCORE}
  DebugLn('TGtk3WSWinControl.SetColor ',dbgsName(AWinControl));
  {$ENDIF}
  TGtk3Widget(AWinControl.Handle).Color := AWinControl.Color;
end;

class procedure TGtk3WSWinControl.SetCursor(const AWinControl: TWinControl; const ACursor: HCursor);
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetCursor') then
    Exit;
  {$IFDEF GTK3DEBUGNOTIMPLEMENTED}
  // quiet for now
  // DebugLn('TGtk3WSWinControl.SetCursor not implemented');
  {$ENDIF}
  TGtk3Widget(AWinControl.Handle).SetCursor(ACursor);
end;

class procedure TGtk3WSWinControl.SetShape(const AWinControl: TWinControl;
  const AShape: HBITMAP);
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetShape') then
    Exit;
  {$IFDEF GTK3DEBUGNOTIMPLEMENTED}
  DebugLn('TGtk3WSWinControl.SetShape not implemented');
  {$ENDIF}
end;

class procedure TGtk3WSWinControl.SetFont(const AWinControl: TWinControl; const AFont: TFont);
var
  AWidget: TGtk3Widget;
  AGtkFont: PPangoFontDescription;
  APangoStyle: TPangoStyle;
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetFont') then
    Exit;

  {$IFDEF GTK3DEBUGCORE}
  DebugLn('TGtk3WSWinControl.SetFont ',dbgsName(AWinControl),' font.Size=',dbgs(AFont.Size),' font.Height=',dbgs(AFont.Height),' ASize=',dbgs(ASize),
  ' pxPerInch ',dbgs(AFont.PixelsPerInch));
  {$ENDIF}
  AWidget := TGtk3Widget(AWinControl.Handle);
  if LowerCase(AFont.Name) = 'default' then
  begin
    AGtkFont := TGtk3Widget(AWinControl.Handle).Font;
    if AFont.Size <> 0 then
      pango_font_description_set_absolute_size(AGtkFont, Abs(AFont.Size) * PANGO_SCALE);
  end else
  begin
    AGtkFont := pango_font_description_from_string(PgChar(AFont.Name));
    pango_font_description_set_family(AGtkFont, PgChar(AFont.Name));
    if AFont.Size <> 0 then
      pango_font_description_set_size(AGtkFont, Abs(AFont.Size) * PANGO_SCALE);
  end;

  if fsItalic in AFont.Style then
    APangoStyle := PANGO_STYLE_ITALIC
  else
    APangoStyle := PANGO_STYLE_NORMAL;
  pango_font_description_set_style(AGtkFont, APangoStyle);
  if fsBold in AFont.Style then
    pango_font_description_set_weight(AGtkFont, PANGO_WEIGHT_BOLD);
  AWidget.Font := AGtkFont;
  AWidget.FontColor := AFont.Color;
end;

class procedure TGtk3WSWinControl.SetPos(const AWinControl: TWinControl; const ALeft, ATop: Integer);
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetPos') then
    Exit;
  {$IF DEFINED(GTK3DEBUGCORE) OR DEFINED(GTK3DEBUGSIZE)}
  DebugLn('WARNING: TGtk3WSWinControl.SetPos is not implemented. *****');
  {$ENDIF}
end;

class procedure TGtk3WSWinControl.SetSize(const AWinControl: TWinControl; const AWidth, AHeight: Integer);
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetSize') then
    Exit;
  {$IF DEFINED(GTK3DEBUGCORE) OR DEFINED(GTK3DEBUGSIZE)}
  DebugLn('WARNING: TGtk3WSWinControl.SetSize is not implemented. *****');
  {$ENDIF}
end;

{------------------------------------------------------------------------------
  Method: TGtk3WSWinControl.SetText
  Params:  AWinControl - the calling object
           AText       - String to be set as label/text for a control
  Returns: Nothing

  Sets the label text on a widget
 ------------------------------------------------------------------------------}
class procedure TGtk3WSWinControl.SetText(const AWinControl: TWinControl; const AText: String);
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetText') then
    Exit;
  {$IFDEF GTK3DEBUGCORE}
  DebugLn('TGtk3WSWinControl.SetText ',dbgsName(AWinControl));
  {$ENDIF}
  TGtk3Widget(AWinControl.Handle).Text := AText;
end;

class procedure TGtk3WSWinControl.ShowHide(const AWinControl: TWinControl);
begin
  if not WSCheckHandleAllocated(AWinControl, 'ShowHide') then
    Exit;
  {$IFDEF GTK3DEBUGCORE}
  DebugLn('TGtk3WSWinControl.ShowHide ',dbgsName(AWinControl));
  {$ENDIF}
  TGtk3Widget(AWinControl.Handle).Visible := AWinControl.HandleObjectShouldBeVisible;
  if TGtk3Widget(AWinControl.Handle).Visible then
  begin
    TGtk3Widget(AWinControl.Handle).ShowAll;
    // imediatelly realize (create widget handles), so we'll get updated bounds
    // and everything just on time.
    if not (wtScrollingWin in TGtk3Widget(AWinControl.Handle).WidgetType) then
      PGtkWidget(TGtk3Widget(AWinControl.Handle).GetContainerWidget)^.realize;
  end;
end;

{ TGtk3WSCustomControl }

class function TGtk3WSCustomControl.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle;
var
  Gtk3CustomControl: TGtk3CustomControl;
begin
  Gtk3CustomControl := TGtk3CustomControl.Create(AWinControl, AParams);
  Result := TLCLIntfHandle(Gtk3CustomControl);
end;


{ TGtk3WSDragImageList }

class function TGtk3WSDragImageList.BeginDrag(const ADragImageList: TDragImageList;
  Window: HWND; AIndex, X, Y: Integer): Boolean;
begin
  Result := False;
end;

class function TGtk3WSDragImageList.DragMove(const ADragImageList: TDragImageList;
  X, Y: Integer): Boolean;
begin
  Result := False;
end;

class procedure TGtk3WSDragImageList.EndDrag(const ADragImageList: TDragImageList);
begin
end;

class function TGtk3WSDragImageList.HideDragImage(const ADragImageList: TDragImageList;
  ALockedWindow: HWND; DoUnLock: Boolean): Boolean;
begin
  Result := False;
end;

class function TGtk3WSDragImageList.ShowDragImage(const ADragImageList: TDragImageList;
  ALockedWindow: HWND; X, Y: Integer; DoLock: Boolean): Boolean;
begin
  Result := False;
end;

end.
