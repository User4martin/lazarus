{ $Id$}
{
 *****************************************************************************
 *                               QtWSMenus.pp                                * 
 *                               ------------                                * 
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
unit QtWSMenus;

{$mode objfpc}{$H+}

interface

{$I qtdefines.inc}

uses
  // Bindings
  qt4,
  qtwidgets, qtobjects, qtproc, QtWsControls,
  // LCL
  SysUtils, Classes, LCLType, LCLProc, Graphics, Controls, Forms, Menus,
  // Widgetset
  WSMenus, WSLCLClasses;

type

  { TQtWSMenuItem }

  TQtWSMenuItem = class(TWSMenuItem)
  private
  protected
    class function CreateMenuFromMenuItem(const AMenuItem: TMenuItem): TQtMenu;
  public
    class procedure AttachMenu(const AMenuItem: TMenuItem); override;
    class function CreateHandle(const AMenuItem: TMenuItem): HMENU; override;
    class procedure DestroyHandle(const AMenuItem: TMenuItem); override;
    class procedure SetCaption(const AMenuItem: TMenuItem; const ACaption: string); override;
    class procedure SetShortCut(const AMenuItem: TMenuItem; const OldShortCut, NewShortCut: TShortCut); override;
    class procedure SetVisible(const AMenuItem: TMenuItem; const Visible: boolean); override;
    class function SetCheck(const AMenuItem: TMenuItem; const Checked: boolean): boolean; override;
    class function SetEnable(const AMenuItem: TMenuItem; const Enabled: boolean): boolean; override;
    class function SetRadioItem(const AMenuItem: TMenuItem; const RadioItem: boolean): boolean; override;
    class function SetRightJustify(const AMenuItem: TMenuItem; const Justified: boolean): boolean; override;
    class procedure UpdateMenuIcon(const AMenuItem: TMenuItem; const HasIcon: Boolean; const AIcon: TBitmap); override;
  end;

  { TQtWSMenu }

  TQtWSMenu = class(TWSMenu)
  private
  protected
  public
    class function  CreateHandle(const AMenu: TMenu): HMENU; override;
    class procedure SetBiDiMode(const AMenu: TMenu; UseRightToLeftAlign, UseRightToLeftReading : Boolean); override;
  end;

  { TQtWSMainMenu }

  TQtWSMainMenu = class(TWSMainMenu)
  private
  protected
  public
  end;

  { TQtWSPopupMenu }

  TQtWSPopupMenu = class(TWSPopupMenu)
  private
  protected
  public
    class procedure Popup(const APopupMenu: TPopupMenu; const X, Y: integer); override;
  end;


implementation

{ TQtWSMenuItem }

{------------------------------------------------------------------------------
  Function: TQtWSMenuItem.AttachMenu
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSMenuItem.AttachMenu(const AMenuItem: TMenuItem);
var
  Widget: TQtWidget;
begin
  if not WSCheckMenuItem(AMenuItem, 'AttachMenu') or (AMenuItem.Parent = nil) then
    Exit;

  Widget := TQtWidget(AMenuItem.Parent.Handle);
  if Widget is TQtMenuBar then
    TQtMenuBar(Widget).insertMenu(AMenuItem.Parent.VisibleIndexOf(AMenuItem),
      QMenuH(TQtMenu(AMenuItem.Handle).Widget))
  else
  if Widget is TQtMenu then
    TQtMenu(Widget).insertMenu(AMenuItem.Parent.VisibleIndexOf(AMenuItem),
      QMenuH(TQtMenu(AMenuItem.Handle).Widget));
end;

class function TQtWSMenuItem.CreateMenuFromMenuItem(const AMenuItem: TMenuItem): TQtMenu;
begin
  Result := TQtMenu.Create(AMenuItem);
  Result.setSeparator(AMenuItem.IsLine);
  Result.setHasSubmenu(AMenuItem.Count > 0);
  if not AMenuItem.IsLine then
  begin
    Result.setText(GetUtf8String(AMenuItem.Caption));
    Result.setEnabled(AMenuItem.Enabled);
    Result.setChecked(AMenuItem.Checked);
    Result.setShortcut(AMenuItem.ShortCut);
    if AMenuItem.HasIcon then
      Result.setImage(TQtImage(AMenuItem.Bitmap.Handle));
  end;
end;
{------------------------------------------------------------------------------
  Function: TQtWSMenuItem.CreateHandle
  Params:  None
  Returns: Nothing

  Creates a Menu Item
 ------------------------------------------------------------------------------}
class function TQtWSMenuItem.CreateHandle(const AMenuItem: TMenuItem): HMENU;
var
  Menu: TQtMenu;
begin
  {$ifdef VerboseQt}
    WriteLn('trace:> [TQtWSMenuItem.CreateHandle] Caption: ', AMenuItem.Caption,
     ' Subitems: ' + IntToStr(AMenuItem.Count));

    Write('trace:< [TQtWSMenuItem.CreateHandle]');
  {$endif}
  
  Menu := nil;

  {------------------------------------------------------------------------------
    This case should not happen. A menu item must have a parent, but it seams LCL
   will sometimes create a menu item prior to creating it's parent.
    So, if we arrive here, we must create this item as if it was a TMenu
   ------------------------------------------------------------------------------}
  if (not AMenuItem.HasParent) then
  begin
    {$ifdef VerboseQt}
      Write(' Parent: Menu without parent');
    {$endif}

    Result := TQtWSMenu.CreateHandle(AMenuItem.GetParentMenu);
  end
  {------------------------------------------------------------------------------
    If the parent has no parent, then this item is directly owned by a TMenu
    In this case we have to detect if the parent is a TMainMenu or a TPopUpMenu
   because TMainMenu uses the special Handle QMenuBar while TPopUpMenu can be
   treat like if this menu item was a subitem of another item
   ------------------------------------------------------------------------------}
  else
  if ((not AMenuItem.Parent.HasParent) and (AMenuItem.GetParentMenu is TMainMenu)) then
  begin
    Menu := CreateMenuFromMenuItem(AMenuItem);
    Result := HMENU(Menu);
  end
  {------------------------------------------------------------------------------
    If the parent has a parent, then that item's Handle is necessarely a TQtMenu
   ------------------------------------------------------------------------------}
  else
  begin
    Menu := CreateMenuFromMenuItem(AMenuItem);
    Result := HMENU(Menu);
  end;
  
  if Menu <> nil then
    Menu.AttachEvents;

  {$ifdef VerboseQt}
    WriteLn(' Result: ', dbghex(Result));
  {$endif}
end;

{------------------------------------------------------------------------------
  Function: TQtWSMenuItem.DestroyHandle
  Params:  None
  Returns: Nothing

  Dealocates a Menu Item
 ------------------------------------------------------------------------------}
class procedure TQtWSMenuItem.DestroyHandle(const AMenuItem: TMenuItem);
var
  Obj: TObject;
begin
  {$ifdef VerboseQt}
    WriteLn('[TQtWSMenuItem.DestroyHandle] Caption: ' + AMenuItem.Caption);
  {$endif}
  
  Obj := TObject(AMenuItem.Handle);
  if Obj is TQtMenu then
    TQtMenu(Obj).Release;
end;

{------------------------------------------------------------------------------
  Function: TQtWSMenuItem.SetCaption
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSMenuItem.SetCaption(const AMenuItem: TMenuItem; const ACaption: string);
var
  Widget: TQtWidget;
begin
  {$ifdef VerboseQt}
    WriteLn('[TQtWSMenuItem.SetCaption] Caption: ' + AMenuItem.Caption + ' NewCaption: ', ACaption);
  {$endif}

  if not WSCheckMenuItem(AMenuItem, 'SetEnable') then
    Exit;

  Widget := TQtWidget(AMenuItem.Handle);
  if Widget is TQtMenu then
    TQtMenu(Widget).setText(GetUtf8String(ACaption));
end;

{------------------------------------------------------------------------------
  Function: TQtWSMenuItem.SetShortCut
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSMenuItem.SetShortCut(const AMenuItem: TMenuItem; const OldShortCut, NewShortCut: TShortCut);
var
  Widget: TQtWidget;
begin
  {$ifdef VerboseQt}
    WriteLn('[TQtWSMenuItem.SetCaption] SetShortCut: ' + AMenuItem.Caption);
  {$endif}

  if not WSCheckMenuItem(AMenuItem, 'SetEnable') then
    Exit;

  Widget := TQtWidget(AMenuItem.Handle);
  if Widget is TQtMenu then
    TQtMenu(Widget).setShortcut(NewShortCut);
end;

{------------------------------------------------------------------------------
  Function: TQtWSMenuItem.SetVisible
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSMenuItem.SetVisible(const AMenuItem: TMenuItem; const Visible: boolean);
begin
  {$ifdef VerboseQt}
    WriteLn('[TQtWSMenuItem.SetVisible] SetShortCut: ' + AMenuItem.Caption + ' Visible: ', Visible);
  {$endif}
  if not WSCheckMenuItem(AMenuItem, 'SetEnable') then
    Exit;
    
  TQtMenu(AMenuItem.Handle).setVisible(Visible);
end;

{------------------------------------------------------------------------------
  Function: TQtWSMenuItem.SetCheck
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function TQtWSMenuItem.SetCheck(const AMenuItem: TMenuItem; const Checked: boolean): boolean;
begin
  Result := False;

  if not WSCheckMenuItem(AMenuItem, 'SetEnable') then
    Exit;

  TQtMenu(AMenuItem.Handle).setChecked(Checked);

  Result := True;
end;

{------------------------------------------------------------------------------
  Function: TQtWSMenuItem.SetEnable
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function TQtWSMenuItem.SetEnable(const AMenuItem: TMenuItem; const Enabled: boolean): boolean;
begin
  Result := False;

  if not WSCheckMenuItem(AMenuItem, 'SetEnable') then
    Exit;

  TQtMenu(AMenuItem.Handle).setEnabled(Enabled);

  Result := True;
end;

{------------------------------------------------------------------------------
  Function: TQtWSMenuItem.SetRadioItem
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function TQtWSMenuItem.SetRadioItem(const AMenuItem: TMenuItem; const RadioItem: boolean): boolean;
begin
  Result := False;

  if not WSCheckMenuItem(AMenuItem, 'SetEnable') then
    Exit;

  TQtMenu(AMenuItem.Handle).setCheckable(RadioItem);
  SetCheck(AMenuItem, AMenuItem.Checked);
  
  Result := True;
end;

{------------------------------------------------------------------------------
  Function: TQtWSMenuItem.SetRightJustify
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function TQtWSMenuItem.SetRightJustify(const AMenuItem: TMenuItem; const Justified: boolean): boolean;
begin
  if not WSCheckMenuItem(AMenuItem, 'SetEnable') then
    Exit;

  // what should be done here? maybe this?
  TQtMenu(AMenuItem.Handle).setAttribute(QtWA_RightToLeft, Justified);
  Result := True;
end;

class procedure TQtWSMenuItem.UpdateMenuIcon(const AMenuItem: TMenuItem;
  const HasIcon: Boolean; const AIcon: TBitmap);
begin
  if AMenuItem.HasParent then
  begin
    if HasIcon then
      TQtMenu(AMenuItem.Handle).setImage(TQtImage(AIcon.Handle))
    else
      TQtMenu(AMenuItem.Handle).setImage(nil);
  end;
end;

{ TQtWSMenu }

{------------------------------------------------------------------------------
  Function: TQtWSMenu.CreateHandle
  Params:  None
  Returns: Nothing

  Creates a Menu
 ------------------------------------------------------------------------------}
class function TQtWSMenu.CreateHandle(const AMenu: TMenu): HMENU;
var
  MenuBar: TQtMenuBar;
  Menu: TQtMenu;
begin
  { If the menu is a main menu, there is no need to create a handle for it.
    It's already created on the window }
  if (AMenu is TMainMenu) and (AMenu.Owner is TCustomForm) then
  begin
    MenuBar := TQtMainWindow(TCustomForm(AMenu.Owner).Handle).MenuBar;

    Result := HMENU(MenuBar);
  end
  else if (AMenu is TPopUpMenu) then
  begin
    Menu := TQtMenu.Create(AMenu.Items);
    //Menu.setParent(Parent);
    Menu.AttachEvents;
  
    Result := HMENU(Menu);
  end;

  {$ifdef VerboseQt}
    Write('[TQtWSMenu.CreateHandle] ');

    if (AMenu is TMainMenu) then Write('IsMainMenu ');

    WriteLn(' Handle: ', dbghex(Result), ' Name: ', AMenu.Name);
  {$endif}
end;

class procedure TQtWSMenu.SetBiDiMode(const AMenu : TMenu; UseRightToLeftAlign,
  UseRightToLeftReading : Boolean);
begin
  TQtWidget(AMenu.Handle).setLayoutDirection(TLayoutDirectionMap[UseRightToLeftAlign]);
end;


{ TQtWSPopupMenu }

{------------------------------------------------------------------------------
  Function: TQtWSPopupMenu.Popup
  Params:  None
  Returns: Nothing

  Creates a PopUp menu
 ------------------------------------------------------------------------------}
class procedure TQtWSPopupMenu.Popup(const APopupMenu: TPopupMenu; const X, Y: integer);
var
  Point: TQtPoint;
begin
  {$ifdef VerboseQt}
    WriteLn('[TQtWSPopupMenu.Popup] APopupMenu.Handle ' + dbghex(APopupMenu.Handle)
     + ' FirstItemName: ' + APopupMenu.Items.Name
     + ' FirstItemWND: ' + IntToStr(APopupMenu.Items.Handle)
     + ' FirstItemCount: ' + IntToStr(APopupMenu.Items.Count));
  {$endif}

  Point.X := X;
  Point.Y := Y;

  TQtMenu(APopupMenu.Handle).PopUp(@Point);
end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
  RegisterWSComponent(TMenuItem, TQtWSMenuItem);
  RegisterWSComponent(TMenu, TQtWSMenu);
//  RegisterWSComponent(TMainMenu, TQtWSMainMenu);
  RegisterWSComponent(TPopupMenu, TQtWSPopupMenu);
////////////////////////////////////////////////////
end.
