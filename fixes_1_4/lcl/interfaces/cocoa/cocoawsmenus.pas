{ $Id: Cocoawsmenus.pp 15309 2008-06-04 22:12:59Z vincents $}
{
 *****************************************************************************
 *                               CocoaWSMenus.pp                             *
 *                               ------------                                * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit CocoaWSMenus;

{$mode objfpc}{$H+}
{$modeswitch objectivec1}

interface

uses
  // Libs
  CocoaAll,
  MacOSAll,
  // RTL
  sysutils,
  // LCL
  Controls, Forms, Menus, Graphics, LCLType, LMessages, LCLProc, Classes,
  // Widgetset
  WSMenus, WSLCLClasses,
  // LCL Cocoa
  CocoaPrivate, CocoaWSCommon, CocoaUtils;

type

  { TCocoaWSMenuItem }

  TCocoaWSMenuItem = class(TWSMenuItem)
  published
    class procedure AttachMenu(const AMenuItem: TMenuItem); override;
    class function  CreateHandle(const AMenuItem: TMenuItem): HMENU; override;
    class procedure DestroyHandle(const AMenuItem: TMenuItem); override;
    class procedure SetCaption(const AMenuItem: TMenuItem; const ACaption: string); override;
    class procedure SetShortCut(const AMenuItem: TMenuItem; const ShortCutK1, ShortCutK2: TShortCut); override;
    class procedure SetVisible(const AMenuItem: TMenuItem; const Visible: boolean); override;
    class function SetCheck(const AMenuItem: TMenuItem; const Checked: boolean): boolean; override;
    class function SetEnable(const AMenuItem: TMenuItem; const Enabled: boolean): boolean; override;
    class function SetRadioItem(const AMenuItem: TMenuItem; const RadioItem: boolean): boolean; override;
    //class function SetRightJustify(const AMenuItem: TMenuItem; const Justified: boolean): boolean; override;
  end;

  { TCocoaWSMenu }

  TCocoaWSMenu = class(TWSMenu)
  published
    class function CreateHandle(const AMenu: TMenu): HMENU; override;
  end;

  { TCocoaWSMainMenu }

  TCocoaWSMainMenu = class(TWSMainMenu)
  private
  protected
  public
  end;

  { TCocoaWSPopupMenu }

  TCocoaWSPopupMenu = class(TWSPopupMenu)
  published
    class procedure Popup(const APopupMenu: TPopupMenu; const X, Y: Integer); override;
  end;


implementation

// used from the MenuMadness example
function NSMenuCheckmark: NSImage;
begin
  Result:=NSImage.imageNamed(NSString.alloc.initWithCString('NSMenuCheckmark'));
end;

function NSMenuRadio: NSImage;
begin
  Result:=NSImage.imageNamed(NSString.alloc.initWithCString('NSMenuRadio'))
end;

function isSeparator(const ACaption: AnsiString): Boolean;
begin
  Result:=ACaption='-';
end;

function MenuCaption(const ACaption: AnsiString): AnsiString;
var
  i : Integer;
begin
  i:=Pos('&', ACaption);
  if i>0 then
    Result:=Copy(ACaption, 1, i-1)+Copy(ACaption,i+1, length(ACaption))
  else
    Result:=ACaption;
end;

{ TCocoaWSMenu }

{------------------------------------------------------------------------------
  Method:  TCocoaWSMenu.CreateHandle
  Params:  AMenu - LCL menu
  Returns: Handle to the menu in Cocoa interface

  Creates new menu in Cocoa interface
 ------------------------------------------------------------------------------}
class function TCocoaWSMenu.CreateHandle(const AMenu: TMenu): HMENU;
begin
  Result:=HMENU(TCocoaMenu.alloc.init) ;
end;

{ TCocoaWSMenuItem }

{------------------------------------------------------------------------------
  Method:  TCocoaWSMenuItem.AttachMenu
  Params:  AMenuItem - LCL menu item

  Attaches menu item to its parent menu in Cocoa interface
 ------------------------------------------------------------------------------}
class procedure TCocoaWSMenuItem.AttachMenu(const AMenuItem: TMenuItem);
var
  ParObj  : NSObject;
  Parent  : TCocoaMenu;
  item    : NSMenuItem;
  ns      : NSString;
  s       : string;
begin
  if not Assigned(AMenuItem) or (AMenuItem.Handle=0) or not Assigned(AMenuItem.Parent) or (AMenuItem.Parent.Handle=0) then Exit;
  ParObj:=NSObject(AMenuItem.Parent.Handle);

  if ParObj.isKindOfClass_(NSMenuItem) then
  begin
    if not NSMenuItem(ParObj).hasSubmenu then
    begin
      s := AMenuItem.Parent.Caption;
      DeleteAmpersands(s);
      ns := NSStringUtf8(pchar(s));
      Parent := TCocoaMenu.alloc.initWithTitle(ns);
      NSMenuItem(ParObj).setSubmenu(Parent);
      ns.release;
    end
    else
      Parent:=TCocoaMenu(NSMenuItem(ParObj).submenu);
  end else if ParObj.isKindOfClass_(NSMenu) then
    Parent:=TCocoaMenu(ParObj)
  else
    Exit;

  item:=NSMenuItem(AMenuItem.Handle);
  Parent.insertItem_atIndex(item, Parent.itemArray.count);
end;

{------------------------------------------------------------------------------
  Method:  TCocoaWSMenuItem.CreateHandle
  Params:  AMenuItem - LCL menu item
  Returns: Handle to the menu item in Cocoa interface

  Creates new menu item in Cocoa interface
 ------------------------------------------------------------------------------}
class function TCocoaWSMenuItem.CreateHandle(const AMenuItem: TMenuItem): HMENU;
var
  item    : NSMenuItem;
  ANSMenu : NSMenu;
  s       : string;
  ns      : NSString;
  nsKey   : NSString;
  key     : string;
  ShiftSt : NSUInteger;
begin
  if not Assigned(AMenuItem) then Exit;

  if AMenuItem.Caption = '-' then
    item := NSMenuItem.separatorItem
  else
  begin
    s := AMenuItem.Caption;
    DeleteAmpersands(s);
    ShortcutToKeyEquivalent(AMenuItem.ShortCut, key, ShiftSt);

    nsKey := NSString(CFStringCreateWithCString(nil, pointer(pchar(key)), kCFStringEncodingASCII));
    ns := NSStringUtf8(s);
    item := TCocoaMenuItem.alloc.initWithTitle_action_keyEquivalent(ns,
      objcselector('lclItemSelected:'), nsKey);
    item.setKeyEquivalentModifierMask(ShiftSt);

    if AMenuItem.IsInMenuBar then
      begin
      ANSMenu := TCocoaMenu.alloc.initWithTitle(ns);
      item.setSubmenu(ANSMenu);
      end;

    ns.release;
    nsKey.release;
    item.setTarget(item);
    TCocoaMenuItem(item).menuItemCallback:=TLCLMenuItemCallback.Create(item, AMenuItem);
    item.setEnabled(AMenuItem.Enabled);
  end;

  Result:=HMENU(item);
end;

{------------------------------------------------------------------------------
  Method:  TCocoaWSMenuItem.DestroyHandle
  Params:  AMenuItem - LCL menu item

  Destroys menu item in Cocoa interface
 ------------------------------------------------------------------------------}
class procedure TCocoaWSMenuItem.DestroyHandle(const AMenuItem: TMenuItem);
var
  callback: IMenuItemCallback;
  callbackObject: TObject;
  item    : NSObject;
  parItem : NSObject;
begin
  if AMenuItem.Caption <> '-' then
    begin
    item:=NSObject(AMenuItem.Handle);
    if item.isKindOfClass_(TCocoaMenuItem) then
      begin
      callback := TCocoaMenuItem(item).lclGetCallback;
      if Assigned(callback) then
        begin
        callbackObject := callback.GetCallbackObject;
        callback := nil;
        TCocoaMenuItem(item).lclClearCallback;
        callbackObject.Free;
        end;
      parItem := TCocoaMenuItem(Item).parentItem;
      if assigned(parItem) and parItem.isKindOfClass_(NSMenuItem) then
        NSMenuItem(paritem).submenu.removeItem(NSMenuItem(item));
      Item.Release;
      AMenuItem.Handle := 0;
      end
    end;
end;

{------------------------------------------------------------------------------
  Method:  TCocoaWSMenuItem.SetCaption
  Params:  AMenuItem - LCL menu item
           ACaption  - Menu item caption

  Sets the caption of menu item in Cocoa interface
 ------------------------------------------------------------------------------}
class procedure TCocoaWSMenuItem.SetCaption(const AMenuItem: TMenuItem; const ACaption: string);
var
  ns : NSString;
  s: string;
begin
  if not Assigned(AMenuItem) or (AMenuItem.Handle=0) then Exit;
  s := ACaption;
  DeleteAmpersands(s);
  ns:=NSStringUtf8(s);
  NSMenuItem(AMenuItem.Handle).setTitle(ns);
  if NSMenuItem(AMenuItem.Handle).hasSubmenu then
    NSMenuItem(AMenuItem.Handle).submenu.setTitle(ns);
  ns.release;
end;

{------------------------------------------------------------------------------
  Method:  TCocoaWSMenuItem.SetShortCut
  Params:  AMenuItem   - LCL menu item
           ShortCutK1 and ShortCutK2 - New shortcut key1 and key2

  Sets the shortcut of menu item in Cocoa interface
 ------------------------------------------------------------------------------}
class procedure TCocoaWSMenuItem.SetShortCut(const AMenuItem: TMenuItem;
  const ShortCutK1, ShortCutK2: TShortCut);
var
  key: string;
  ShiftState: NSUInteger;
  ns: NSString;
begin
  ShortcutToKeyEquivalent(ShortCutK1, key, ShiftState);
  ns := NSString(CFStringCreateWithCString(nil, pointer(pchar(key)), kCFStringEncodingASCII));
  TCocoaMenuItem(AMenuItem.Handle).setKeyEquivalentModifierMask(ShiftState);
  TCocoaMenuItem(AMenuItem.Handle).setKeyEquivalent(ns);
  ns.release;
end;

{------------------------------------------------------------------------------
  Method:  TCocoaWSMenuItem.SetVisible
  Params:  AMenuItem - LCL menu item
           Visible   - Menu item visibility

  Sets the visibility of menu item in Cocoa interface
 ------------------------------------------------------------------------------}
class procedure TCocoaWSMenuItem.SetVisible(const AMenuItem: TMenuItem;
  const Visible: boolean);
begin
  if not Assigned(AMenuItem) or (AMenuItem.Handle=0) then Exit;
  NSMenuItem(AMenuItem.Handle).setHidden( not Visible );
end;

{------------------------------------------------------------------------------
  Method:  TCocoaWSMenuItem.SetCheck
  Params:  AMenuItem - LCL menu item
           Checked   - Menu item checked
  Returns: If the function succeeds

  Sets the check of menu item in Cocoa interface
 ------------------------------------------------------------------------------}
class function TCocoaWSMenuItem.SetCheck(const AMenuItem: TMenuItem;
  const Checked: boolean): boolean;
const
  menustate : array [Boolean] of NSInteger = (NSOffState, NSOnState);
begin
  Result:=Assigned(AMenuItem) and (AMenuItem.Handle<>0);
  if not Result then Exit;
  NSMenuItem(AMenuItem.Handle).setOnStateImage( NSMenuCheckmark );
  NSMenuItem(AMenuItem.Handle).setState( menustate[Checked] );
end;

{------------------------------------------------------------------------------
  Method:  TCocoaWSMenuItem.SetEnable
  Params:  AMenuItem - LCL menu item
           Enabled   - Menu item enabled
  Returns: If the function succeeds

  Sets the enabled of menu item in Cocoa interface
 ------------------------------------------------------------------------------}
class function TCocoaWSMenuItem.SetEnable(const AMenuItem: TMenuItem;
  const Enabled: boolean): boolean;
begin
  Result:=Assigned(AMenuItem) and (AMenuItem.Handle<>0);
  if not Result then Exit;
  NSMenuItem(AMenuItem.Handle).setEnabled( Enabled );
end;

{------------------------------------------------------------------------------
  Method:  TCocoaWSMenuItem.SetRadioItem
  Params:  AMenuItem - LCL menu item
           RadioItem - Menu item has radio
  Returns: If the function succeeds

  Sets the radio behaviour of menu item in Cocoa interface
 ------------------------------------------------------------------------------}
class function TCocoaWSMenuItem.SetRadioItem(const AMenuItem: TMenuItem;
  const RadioItem: boolean): boolean;
const
  menustate : array [Boolean] of NSInteger = (NSOffState, NSOnState);
begin
  Result:=Assigned(AMenuItem) and (AMenuItem.Handle<>0);
  if not Result then Exit;
  //todo: disable relative radio items
  NSMenuItem(AMenuItem.Handle).setOnStateImage( NSMenuRadio );
  NSMenuItem(AMenuItem.Handle).setState( menustate[RadioItem] );
end;

{ TCocoaWSPopupMenu }

{------------------------------------------------------------------------------
  Method:  TCocoaWSPopupMenu.Popup
  Params:  APopupMenu - LCL popup menu
           X, Y       - Screen coordinates to popup

  Popups menu in Cocoa interface
 ------------------------------------------------------------------------------}
class procedure TCocoaWSPopupMenu.Popup(const APopupMenu: TPopupMenu; const X, Y: integer);
var
  w : NSWindow;
begin
  // todo: there's no way to control X,Y coordinates of the Popup menu in the OSX
  // prior to 10.6. Check the if there's the method and use it, if available
  if Assigned(APopupMenu) and (APopupMenu.Handle<>0) then 
  begin
    w:=NSApp.keyWindow;
    if Assigned(w) then
      NSMenu.popUpContextMenu_withEvent_forView( TCocoaMenu(APopupMenu.Handle),
        NSApp.currentEvent, NSView(w.contentView));
    APopupMenu.Close; // notify LCL popup menu
  end;
end;

end.
