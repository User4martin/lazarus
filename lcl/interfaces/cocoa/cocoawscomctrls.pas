unit CocoaWSComCtrls;

interface

{$mode delphi}
{$modeswitch objectivec1}

{.$DEFINE COCOA_DEBUG_TABCONTROL}
{.$DEFINE COCOA_DEBUG_LISTVIEW}

uses
  // RTL, FCL, LCL
  MacOSAll, CocoaAll,
  Classes, LCLType, SysUtils, Contnrs, LCLMessageGlue, LMessages,
  Controls, ComCtrls, Types, StdCtrls, LCLProc, Graphics, ImgList,
  Math,
  // WS
  WSComCtrls,
  // Cocoa WS
  CocoaPrivate, CocoaUtils, CocoaProc, CocoaWSCommon;

type

  { TCocoaWSStatusBar }

  TCocoaWSStatusBar = class(TWSStatusBar)
  published
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure PanelUpdate(const AStatusBar: TStatusBar; PanelIndex: integer); override;
    class procedure SetPanelText(const AStatusBar: TStatusBar; PanelIndex: integer); override;
    class procedure Update(const AStatusBar: TStatusBar); override;
    //
    class procedure GetPreferredSize(const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean); override;
  end;

  { TCocoaWSTabSheet }

  TCocoaWSTabSheet = class(TWSTabSheet)
  published
  end;


  { TCocoaWSCustomPage }

  TCocoaWSCustomPage = class(TWSCustomPage)
  public
    class function  GetCocoaTabPageFromHandle(AHandle: HWND): TCocoaTabPage;
  published
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure UpdateProperties(const ACustomPage: TCustomPage); override;
    class procedure SetProperties(const ACustomPage: TCustomPage; ACocoaControl: NSTabViewItem);
    //
    class procedure SetBounds(const AWinControl: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer); override;
  end;

  { TCocoaWSCustomTabControl }

  TCocoaWSCustomTabControl = class(TWSCustomTabControl)
  private
    class function LCLTabPosToNSTabStyle(AShowTabs: Boolean; ABorderWidth: Integer; ATabPos: TTabPosition): NSTabViewType;
  public
    class function  GetCocoaTabControlHandle(ATabControl: TCustomTabControl): TCocoaTabControl;
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;

    class procedure AddPage(const ATabControl: TCustomTabControl; const AChild: TCustomPage; const AIndex: integer); override;
    class procedure MovePage(const ATabControl: TCustomTabControl; const AChild: TCustomPage; const NewIndex: integer); override;
    class procedure RemovePage(const ATabControl: TCustomTabControl; const AIndex: integer); override;

    //class function GetNotebookMinTabHeight(const AWinControl: TWinControl): integer; override;
    //class function GetNotebookMinTabWidth(const AWinControl: TWinControl): integer; override;
    //class function GetPageRealIndex(const ATabControl: TCustomTabControl; AIndex: Integer): Integer; override;
    class function GetTabIndexAtPos(const ATabControl: TCustomTabControl; const AClientPos: TPoint): integer; override;
    class procedure SetPageIndex(const ATabControl: TCustomTabControl; const AIndex: integer); override;
    class procedure SetTabPosition(const ATabControl: TCustomTabControl; const ATabPosition: TTabPosition); override;
    class procedure ShowTabs(const ATabControl: TCustomTabControl; AShowTabs: boolean); override;
  end;

  { TCocoaWSPageControl }

  TCocoaWSPageControl = class(TWSPageControl)
  published
  end;

  { TCocoaWSCustomListView }

  TCocoaWSCustomListView = class(TWSCustomListView)
  private
    class function CheckParams(out AScroll: TCocoaListView; out ATableControl: TCocoaTableListView; const ALV: TCustomListView): Boolean;
    class function CheckColumnParams(out ATableControl: TCocoaTableListView;
      out ANSColumn: NSTableColumn; const ALV: TCustomListView; const AIndex: Integer; ASecondIndex: Integer = -1): Boolean;
  published
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
    // Column
    class procedure ColumnDelete(const ALV: TCustomListView; const AIndex: Integer); override;
    class function  ColumnGetWidth(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AColumn: TListColumn): Integer; override;
    class procedure ColumnInsert(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn); override;
    class procedure ColumnMove(const ALV: TCustomListView; const AOldIndex, ANewIndex: Integer; const AColumn: TListColumn); override;
    class procedure ColumnSetAlignment(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AColumn: TListColumn; const AAlignment: TAlignment); override;
    class procedure ColumnSetAutoSize(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AColumn: TListColumn; const AAutoSize: Boolean); override;
    class procedure ColumnSetCaption(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AColumn: TListColumn; const ACaption: String); override;
    class procedure ColumnSetImage(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AColumn: TListColumn; const AImageIndex: Integer); override;
    class procedure ColumnSetMaxWidth(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AColumn: TListColumn; const AMaxWidth: Integer); override;
    class procedure ColumnSetMinWidth(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AColumn: TListColumn; const AMinWidth: integer); override;
    class procedure ColumnSetWidth(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AColumn: TListColumn; const AWidth: Integer); override;
    class procedure ColumnSetVisible(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AColumn: TListColumn; const AVisible: Boolean); override;

    // Item
    class procedure ItemDelete(const ALV: TCustomListView; const AIndex: Integer); override;
    class function  ItemDisplayRect(const ALV: TCustomListView; const AIndex, ASubItem: Integer; ACode: TDisplayCode): TRect; override;
    class function  ItemGetChecked(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AItem: TListItem): Boolean; override;
    class function  ItemGetPosition(const ALV: TCustomListView; const AIndex: Integer): TPoint; override;
    class function  ItemGetState(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AItem: TListItem; const AState: TListItemState; out AIsSet: Boolean): Boolean; override; // returns True if supported
    class procedure ItemInsert(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AItem: TListItem); override;
    (*class procedure ItemSetChecked(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AItem: TListItem; const AChecked: Boolean); override;
    //class procedure ItemSetImage(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AItem: TListItem; const {%H-}ASubIndex, {%H-}AImageIndex: Integer); override;
    //carbon//class function ItemSetPosition(const ALV: TCustomListView; const AIndex: Integer; const ANewPosition: TPoint): Boolean; override;
    class procedure ItemSetState(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AItem: TListItem; const AState: TListItemState; const AIsSet: Boolean); override;*)
    class procedure ItemSetText(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AItem: TListItem; const {%H-}ASubIndex: Integer; const {%H-}AText: String); override;
    class procedure ItemShow(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AItem: TListItem; const PartialOK: Boolean); override;

    // LV
    //available in 10.7 only//class procedure BeginUpdate(const ALV: TCustomListView); override;
    //available in 10.7 only//class procedure EndUpdate(const ALV: TCustomListView); override;

    //class function GetBoundingRect(const ALV: TCustomListView): TRect; override;
    //carbon//class function GetDropTarget(const ALV: TCustomListView): Integer; override;
    class function GetFocused(const ALV: TCustomListView): Integer; override;
    //carbon//class function GetHoverTime(const ALV: TCustomListView): Integer; override;
    class function GetItemAt(const ALV: TCustomListView; x,y: integer): Integer; override;
    class function GetSelCount(const ALV: TCustomListView): Integer; override;
    class function GetSelection(const ALV: TCustomListView): Integer; override;
    class function GetTopItem(const ALV: TCustomListView): Integer; override;
    //class function GetViewOrigin(const ALV: TCustomListView): TPoint; override;
    class function GetVisibleRowCount(const ALV: TCustomListView): Integer; override;

    //carbon//class procedure SetAllocBy(const ALV: TCustomListView; const AValue: Integer); override;
    class procedure SetDefaultItemHeight(const ALV: TCustomListView; const AValue: Integer); override;
    //carbon//class procedure SetHotTrackStyles(const ALV: TCustomListView; const AValue: TListHotTrackStyles); override;
    //carbon//class procedure SetHoverTime(const ALV: TCustomListView; const AValue: Integer); override;
    (*class procedure SetImageList(const ALV: TCustomListView; const {%H-}AList: TListViewImageList; const {%H-}AValue: TCustomImageList); override;
    class procedure SetItemsCount(const ALV: TCustomListView; const Avalue: Integer); override;
    class procedure SetOwnerData(const ALV: TCustomListView; const {%H-}AValue: Boolean); override;*)
    class procedure SetProperty(const ALV: TCustomListView; const AProp: TListViewProperty; const AIsSet: Boolean); override;
    class procedure SetProperties(const ALV: TCustomListView; const AProps: TListViewProperties); override;
    class procedure SetScrollBars(const ALV: TCustomListView; const AValue: TScrollStyle); override;
    (*class procedure SetSort(const ALV: TCustomListView; const {%H-}AType: TSortType; const {%H-}AColumn: Integer;
      const {%H-}ASortDirection: TSortDirection); override;
    class procedure SetViewOrigin(const ALV: TCustomListView; const AValue: TPoint); override;
    class procedure SetViewStyle(const ALV: TCustomListView; const AValue: TViewStyle); override;*)
  end;

  { TCocoaWSProgressBar }

  TCocoaWSProgressBar = class(TWSProgressBar)
  published
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure ApplyChanges(const AProgressBar: TCustomProgressBar); override;
    class procedure SetPosition(const AProgressBar: TCustomProgressBar; const NewPosition: integer); override;
    class procedure SetStyle(const AProgressBar: TCustomProgressBar; const NewStyle: TProgressBarStyle); override;
  end;

  { TCocoaWSCustomUpDown }

  TCocoaWSCustomUpDown = class(TWSCustomUpDown)
  published
  end;

  { TCarbonWSUpDown }

  TCarbonWSUpDown = class(TWSUpDown)
  published
  end;

  { TCocoaWSToolButton }

  TCocoaWSToolButton = class(TWSToolButton)
  published
  end;

  { TCarbonWSToolBar }

  TCarbonWSToolBar = class(TWSToolBar)
  published
    //class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
  end;

  { TCocoaWSTrackBar }

  TCocoaWSTrackBar = class(TWSTrackBar)
  published
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure ApplyChanges(const ATrackBar: TCustomTrackBar); override;
    class function  GetPosition(const ATrackBar: TCustomTrackBar): integer; override;
    class procedure SetPosition(const ATrackBar: TCustomTrackBar; const {%H-}NewPosition: integer); override;
    class procedure SetOrientation(const ATrackBar: TCustomTrackBar; const AOrientation: TTrackBarOrientation); override;
    //class procedure SetTick(const ATrackBar: TCustomTrackBar; const ATick: integer); virtual;
  end;

  { TCocoaWSCustomTreeView }

  TCocoaWSCustomTreeView = class(TWSCustomTreeView)
  published
  end;

  { TCocoaWSTreeView }

  TCocoaWSTreeView = class(TWSTreeView)
  published
  end;

  { TLCLListViewCallback }

  TLCLListViewCallback = class(TLCLCommonCallback, IListViewCallback)
  public
    procedure delayedSelectionDidChange_OnTimer(ASender: TObject);
  end;
  TLCLListViewCallBackClass = class of TLCLListViewCallback;

implementation

{ TCocoaWSStatusBar }

class function TCocoaWSStatusBar.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
var
  lResult: TCocoaStatusBar;
  cell    : NSButtonCell;
begin
  Result := 0;
  lResult := TCocoaStatusBar.alloc.lclInitWithCreateParams(AParams);
  if not Assigned(lResult) then Exit;
  Result := TLCLIntfHandle(lResult);

  lResult.callback := TLCLCommonCallback.Create(lResult, AWinControl);
  lResult.StatusBar := TStatusBar(AWinControl);

  cell:=NSButtonCell(NSButtonCell.alloc).initTextCell(nil);
  // NSSmallSquareBezelStyle aka "Gradient button", is the best looking
  // candidate for the status bar panel. Could be changed to any NSCell class
  // since CocoaStatusBar doesn't suspect any specific cell type.
  cell.setBezelStyle(NSSmallSquareBezelStyle);
  cell.setFont( NSFont.systemFontOfSize( NSFont.smallSystemFontSize ));

  lResult.panelCell := cell;
end;

class procedure TCocoaWSStatusBar.PanelUpdate(const AStatusBar: TStatusBar;
  PanelIndex: integer);
begin

end;

class procedure TCocoaWSStatusBar.SetPanelText(const AStatusBar: TStatusBar;
  PanelIndex: integer);
begin

end;

class procedure TCocoaWSStatusBar.Update(const AStatusBar: TStatusBar);
begin

end;

class procedure TCocoaWSStatusBar.GetPreferredSize(const AWinControl: TWinControl;
  var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean);
begin
  PreferredWidth := 0;
  PreferredHeight := STATUSBAR_DEFAULT_HEIGHT;
end;

{ TCocoaWSCustomPage }

class function  TCocoaWSCustomPage.GetCocoaTabPageFromHandle(AHandle: HWND): TCocoaTabPage;
var
  lHandle: TCocoaTabPageView;
begin
  lHandle := TCocoaTabPageView(AHandle);
  Result := lHandle.tabPage;
end;

class function TCocoaWSCustomPage.CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle;
var
  lControl: TCocoaTabPage;
  tv: TCocoaTabPageView;
  tabview: TCocoaTabControl;
begin
  {$IFDEF COCOA_DEBUG_TABCONTROL}
  WriteLn('[TCocoaWSCustomPage.CreateHandle]');
  {$ENDIF}
  lControl := TCocoaTabPage.alloc().init();
  Result := TLCLIntfHandle(lControl);
  if Result <> 0 then
  begin
    lControl.callback := TLCLCommonCallback.Create(lControl, AWinControl);
    lControl.LCLPage := TCustomPage(AWinControl);
    SetProperties(TCustomPage(AWinControl), lControl);

    // Set a special view for the page
    // based on http://stackoverflow.com/questions/14892218/adding-a-nstextview-subview-to-nstabviewitem
    tabview := TCocoaTabControl(AWinControl.Parent.Handle);
    tv := TCocoaTabPageView.alloc.initWithFrame(NSZeroRect);
    tv.setAutoresizingMask(NSViewWidthSizable or NSViewHeightSizable);
    {tv.setHasVerticalScroller(True);
    tv.setHasHorizontalScroller(True);
    tv.setAutohidesScrollers(True);
    tv.setBorderType(NSNoBorder);}
    tv.tabView := tabview;
    tv.tabPage := lControl;
    tv.callback := TLCLCommonCallback.Create(tv, AWinControl);

    // view.addSubview works better than setView, no idea why
    lControl.view.setAutoresizesSubviews(True);
    lControl.view.addSubview(tv);

    Result := TLCLIntfHandle(tv);
  end;
end;

class procedure TCocoaWSCustomPage.UpdateProperties(const ACustomPage: TCustomPage);
var
  lTabPage: TCocoaTabPage;
begin
  {$IFDEF COCOA_DEBUG_TABCONTROL}
  WriteLn('[TCocoaWSCustomTabControl.UpdateProperties] ACustomPage='+IntToStr(PtrInt(ACustomPage)));
  {$ENDIF}
  if not Assigned(ACustomPage) or not ACustomPage.HandleAllocated then Exit;
  lTabPage := TCocoaTabPage(ACustomPage.Handle);
  SetProperties(ACustomPage, lTabPage);
end;

class procedure TCocoaWSCustomPage.SetProperties(
  const ACustomPage: TCustomPage; ACocoaControl: NSTabViewItem);
var
  lHintStr: string;
begin
  // title
  ACocoaControl.setLabel(NSStringUTF8(ACustomPage.Caption));

  // hint
  if ACustomPage.ShowHint then lHintStr := ACustomPage.Hint
  else lHintStr := '';
  ACocoaControl.setToolTip(NSStringUTF8(lHintStr));
end;

class procedure TCocoaWSCustomPage.SetBounds(const AWinControl: TWinControl;
  const ALeft, ATop, AWidth, AHeight: Integer);
begin
  // Pages should be fixed into their PageControl owner,
  // allowing the TCocoaWSWinControl.SetBounds function to operate here
  // was causing bug 28489
end;

{ TCocoaWSCustomTabControl }

class function TCocoaWSCustomTabControl.LCLTabPosToNSTabStyle(AShowTabs: Boolean; ABorderWidth: Integer; ATabPos: TTabPosition): NSTabViewType;
begin
  Result := NSTopTabsBezelBorder;
  if AShowTabs then
  begin
    case ATabPos of
    tpTop:    Result := NSTopTabsBezelBorder;
    tpBottom: Result := NSBottomTabsBezelBorder;
    tpLeft:   Result := NSLeftTabsBezelBorder;
    tpRight:  Result := NSRightTabsBezelBorder;
    end;
  end
  else
  begin
    if ABorderWidth = 0 then
      Result := NSNoTabsNoBorder
    else if ABorderWidth = 1 then
      Result := NSNoTabsLineBorder
    else
      Result := NSNoTabsBezelBorder;
  end;
end;

class function TCocoaWSCustomTabControl.GetCocoaTabControlHandle(ATabControl: TCustomTabControl): TCocoaTabControl;
begin
  Result := nil;
  if ATabControl = nil then Exit;
  if not ATabControl.HandleAllocated then Exit;
  Result := TCocoaTabControl(ATabControl.Handle);
end;

class function TCocoaWSCustomTabControl.CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle;
var
  lControl: TCocoaTabControl;
  lTabControl: TCustomTabControl = nil;
  lTabStyle: NSTabViewType = NSTopTabsBezelBorder;
begin
  lTabControl := TCustomTabControl(AWinControl);
  lControl := TCocoaTabControl.alloc.lclInitWithCreateParams(AParams);
  lTabStyle := LCLTabPosToNSTabStyle(lTabControl.ShowTabs, lTabControl.BorderWidth, lTabControl.TabPosition);
  lControl.setTabViewType(lTabStyle);
  Result := TLCLIntfHandle(lControl);
  if Result <> 0 then
  begin
    lControl.callback := TLCLCommonCallback.Create(lControl, AWinControl);
    lControl.LCLPageControl := TCustomTabControl(AWinControl);
    lControl.setDelegate(lControl);
  end;
end;

class procedure TCocoaWSCustomTabControl.AddPage(const ATabControl: TCustomTabControl; const AChild: TCustomPage; const AIndex: integer);
var
  lTabControl: TCocoaTabControl;
  lTabPage: TCocoaTabPage;
begin
  {$IFDEF COCOA_DEBUG_TABCONTROL}
  WriteLn('[TCocoaWSCustomTabControl.AddPage] AChild='+IntToStr(PtrInt(AChild)));
  {$ENDIF}
  if not Assigned(ATabControl) or not ATabControl.HandleAllocated then Exit;
  lTabControl := TCocoaTabControl(ATabControl.Handle);
  AChild.HandleNeeded();
  if not Assigned(AChild) or not AChild.HandleAllocated then Exit;
  lTabPage := TCocoaWSCustomPage.GetCocoaTabPageFromHandle(AChild.Handle);
  lTabPage.LCLParent := ATabControl;

  lTabControl.insertTabViewItem_atIndex(lTabPage, AIndex);
  {$IFDEF COCOA_DEBUG_TABCONTROL}
  WriteLn('[TCocoaWSCustomTabControl.AddPage] END');
  {$ENDIF}
end;

class procedure TCocoaWSCustomTabControl.MovePage(const ATabControl: TCustomTabControl; const AChild: TCustomPage; const NewIndex: integer);
var
  lTabControl: TCocoaTabControl;
  lTabPage: TCocoaTabPage;
begin
  if not Assigned(ATabControl) or not ATabControl.HandleAllocated then Exit;
  lTabControl := TCocoaTabControl(ATabControl.Handle);
  AChild.HandleNeeded();
  if not Assigned(AChild) or not AChild.HandleAllocated then Exit;
  lTabPage := TCocoaWSCustomPage.GetCocoaTabPageFromHandle(AChild.Handle);

  lTabControl.removeTabViewItem(lTabPage);
  lTabControl.insertTabViewItem_atIndex(lTabPage, NewIndex);
end;

class procedure TCocoaWSCustomTabControl.RemovePage(const ATabControl: TCustomTabControl; const AIndex: integer);
var
  lTabControl: TCocoaTabControl;
  lTabPage: NSTabViewItem;
begin
  if not Assigned(ATabControl) or not ATabControl.HandleAllocated then Exit;
  lTabControl := TCocoaTabControl(ATabControl.Handle);

  lTabPage := lTabControl.tabViewItemAtIndex(AIndex);
  lTabControl.removeTabViewItem(lTabPage);
end;

class function TCocoaWSCustomTabControl.GetTabIndexAtPos(const ATabControl: TCustomTabControl; const AClientPos: TPoint): integer;
var
  lTabControl: TCocoaTabControl;
  lTabPage: NSTabViewItem;
  lClientPos: NSPoint;
begin
  Result := 0;
  if not Assigned(ATabControl) or not ATabControl.HandleAllocated then Exit;
  lTabControl := TCocoaTabControl(ATabControl.Handle);

  lClientPos := LCLToNSPoint(AClientPos, lTabControl.frame.size.height);
  lTabPage := lTabControl.tabViewItemAtPoint(lClientPos);
  Result := lTabControl.indexOfTabViewItem(lTabPage);
end;

class procedure TCocoaWSCustomTabControl.SetPageIndex(const ATabControl: TCustomTabControl; const AIndex: integer);
var
  lTabControl: TCocoaTabControl;
  lTabCount: NSInteger;
begin
  {$IFDEF COCOA_DEBUG_TABCONTROL}
  WriteLn('[TCocoaWSCustomTabControl.SetPageIndex]');
  {$ENDIF}
  if not Assigned(ATabControl) or not ATabControl.HandleAllocated then Exit;
  lTabControl := TCocoaTabControl(ATabControl.Handle);
  {$IFDEF COCOA_DEBUG_TABCONTROL}
  WriteLn(Format('[TCocoaWSCustomTabControl.SetPageIndex] lTabControl=%d', [PtrUInt(lTabControl)]));
  {$ENDIF}
  lTabCount := lTabControl.numberOfTabViewItems();
  {$IFDEF COCOA_DEBUG_TABCONTROL}
  WriteLn(Format('[TCocoaWSCustomTabControl.SetPageIndex] lTabCount=%d', [lTabCount]));
  {$ENDIF}
  if (AIndex < 0) or (AIndex >= lTabCount) then Exit;

  lTabControl.selectTabViewItemAtIndex(AIndex);
end;

class procedure TCocoaWSCustomTabControl.SetTabPosition(const ATabControl: TCustomTabControl; const ATabPosition: TTabPosition);
var
  lTabControl: TCocoaTabControl = nil;
  lOldTabStyle, lTabStyle: NSTabViewType;
begin
  if not Assigned(ATabControl) or not ATabControl.HandleAllocated then Exit;
  lTabControl := TCocoaTabControl(ATabControl.Handle);

  lOldTabStyle := lTabControl.tabViewType();
  lTabStyle := LCLTabPosToNSTabStyle(ATabControl.ShowTabs, ATabControl.BorderWidth, ATabPosition);
  lTabControl.setTabViewType(lTabStyle);
end;

class procedure TCocoaWSCustomTabControl.ShowTabs(const ATabControl: TCustomTabControl; AShowTabs: boolean);
var
  lTabControl: TCocoaTabControl = nil;
  lOldTabStyle, lTabStyle: NSTabViewType;
begin
  if not Assigned(ATabControl) or not ATabControl.HandleAllocated then Exit;
  lTabControl := TCocoaTabControl(ATabControl.Handle);

  lOldTabStyle := lTabControl.tabViewType();
  lTabStyle := LCLTabPosToNSTabStyle(AShowTabs, ATabControl.BorderWidth, ATabControl.TabPosition);
  lTabControl.setTabViewType(lTabStyle);
end;

{ TCocoaWSCustomListView }

class function TCocoaWSCustomListView.CheckParams(
  out AScroll: TCocoaListView;
  out ATableControl: TCocoaTableListView; const ALV: TCustomListView): Boolean;
begin
  Result := False;
  AScroll := nil;
  ATableControl := nil;
  ALV.HandleNeeded();
  if not Assigned(ALV) or not ALV.HandleAllocated then Exit;
  AScroll := TCocoaListView(ALV.Handle);

  // ToDo: Implement for other styles
  if AScroll.TableListView <> nil then
  begin
    ATableControl := AScroll.TableListView;
    Result := True;
  end;
end;

class function TCocoaWSCustomListView.CheckColumnParams(
  out ATableControl: TCocoaTableListView; out ANSColumn: NSTableColumn;
  const ALV: TCustomListView; const AIndex: Integer; ASecondIndex: Integer
  ): Boolean;
var
  lObject: NSObject;
begin
  Result := False;
  ALV.HandleNeeded();
  if not Assigned(ALV) or not ALV.HandleAllocated then Exit;
  lObject := NSObject(ALV.Handle);
  if not lObject.isKindOfClass(TCocoaTableListView) then Exit; // in styles other than Report, column have no meaning

  ATableControl := TCocoaListView(lObject).TableListView;
  if (AIndex < 0) or (AIndex >= ATableControl.tableColumns.count()) then Exit;
  ANSColumn := NSTableColumn(ATableControl.tableColumns.objectAtIndex(AIndex));

  if ASecondIndex >= 0 then
  begin
    if (ASecondIndex < 0) or (ASecondIndex >= ATableControl.tableColumns.count()) then Exit;
  end;
  Result := True;
end;

class function TCocoaWSCustomListView.CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle;
var
  lCocoaLV: TCocoaListView;
  lTableLV: TCocoaTableListView;
  ns: NSRect;
begin
  {$IFDEF COCOA_DEBUG_LISTVIEW}
  WriteLn('[TCocoaWSCustomListView.CreateHandle] AWinControl='+IntToStr(PtrInt(AWinControl)));
  {$ENDIF}
  lCocoaLV := TCocoaListView.alloc.lclInitWithCreateParams(AParams);
  Result := TLCLIntfHandle(lCocoaLV);
  if Result <> 0 then
  begin
    ns := GetNSRect(0, 0, AParams.Width, AParams.Height);
    lTableLV := TCocoaTableListView.alloc.initWithFrame(ns);
    if lTableLV = nil then
    begin
      lCocoaLV.dealloc;
      Result := 0;
      exit;
    end;

    // Unintuitive things about NSTableView which caused a lot of headaches:
    // 1-> The column header appears only if the NSTableView is inside a NSScrollView
    // 2-> To get proper scrolling use NSScrollView.setDocumentView instead of addSubview
    // Source: http://stackoverflow.com/questions/13872642/nstableview-scrolling-does-not-work
    lCocoaLV.TableListView := lTableLV;
    lCocoaLV.ListView := TCustomListView(AWinControl);
    lCocoaLV.setDocumentView(lTableLV);
    lCocoaLV.setHasVerticalScroller(True);

    lTableLV.callback := TLCLListViewCallback.Create(lTableLV, AWinControl);
    lTableLV.Items := TStringList.Create;
    lTableLV.ListView := TCustomListView(AWinControl);
    lTableLV.setDataSource(lTableLV);
    lTableLV.setDelegate(lTableLV);
    lTableLV.setAllowsColumnReordering(False);
    {$IFDEF COCOA_DEBUG_LISTVIEW}
    WriteLn(Format('[TCocoaWSCustomListView.CreateHandle] headerView=%d', [PtrInt(lTableLV.headerView)]));
    {$ENDIF}
  end;
end;

class procedure TCocoaWSCustomListView.ColumnDelete(const ALV: TCustomListView;
  const AIndex: Integer);
var
  lTableLV: TCocoaTableListView;
  lNSColumn: NSTableColumn;
begin
  {$IFDEF COCOA_DEBUG_LISTVIEW}
  WriteLn(Format('[TCocoaWSCustomListView.ColumnDelete] AIndex=%d', [AIndex]));
  {$ENDIF}
  if not CheckColumnParams(lTableLV, lNSColumn, ALV, AIndex) then Exit;

  if lNSColumn = nil then Exit;
  lTableLV.removeTableColumn(lNSColumn);
  lNSColumn.release;
end;

class function TCocoaWSCustomListView.ColumnGetWidth(
  const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn
  ): Integer;
var
  lTableLV: TCocoaTableListView;
  lColumn: NSTableColumn;
begin
  {$IFDEF COCOA_DEBUG_LISTVIEW}
  WriteLn(Format('[TCocoaWSCustomListView.ColumnGetWidth] AIndex=%d', [AIndex]));
  {$ENDIF}
  if not Assigned(ALV) or not ALV.HandleAllocated then Exit;
  lTableLV := TCocoaListView(ALV.Handle).TableListView;
  if (AIndex < 0) or (AIndex >= lTableLV.tableColumns.count()) then Exit;

  lColumn := lTableLV.tableColumns.objectAtIndex(AIndex);
  Result := Round(lColumn.width());
end;

class procedure TCocoaWSCustomListView.ColumnInsert(const ALV: TCustomListView;
  const AIndex: Integer; const AColumn: TListColumn);
var
  lTableLV: TCocoaTableListView;
  lNSColumn: NSTableColumn;
  lTitle: NSString;
begin
  {$IFDEF COCOA_DEBUG_LISTVIEW}
  WriteLn(Format('[TCocoaWSCustomListView.ColumnInsert] ALV=%x AIndex=%d', [PtrInt(ALV), AIndex]));
  {$ENDIF}
  ALV.HandleNeeded();
  if not Assigned(ALV) or not ALV.HandleAllocated then Exit;
  lTableLV := TCocoaListView(ALV.Handle).TableListView;
  {$IFDEF COCOA_DEBUG_LISTVIEW}
  WriteLn(Format('[TCocoaWSCustomListView.ColumnInsert]=> tableColumns.count=%d', [lTableLV.tableColumns.count()]));
  {$ENDIF}
  if (AIndex < 0) or (AIndex >= lTableLV.tableColumns.count()+1) then Exit;
  lTitle := NSStringUTF8(AColumn.Caption);
  lNSColumn := NSTableColumn.alloc.initWithIdentifier(lTitle);
  lNSColumn.headerCell.setStringValue(lTitle);
  lTableLV.addTableColumn(lNSColumn);
  lTitle.release;
end;

class procedure TCocoaWSCustomListView.ColumnMove(const ALV: TCustomListView;
  const AOldIndex, ANewIndex: Integer; const AColumn: TListColumn);
var
  lTableLV: TCocoaTableListView;
  lNSColumn: NSTableColumn;
begin
  if not CheckColumnParams(lTableLV, lNSColumn, ALV, AOldINdex, ANewIndex) then Exit;

  lTableLV.moveColumn_toColumn(AOldIndex, ANewIndex);
end;

class procedure TCocoaWSCustomListView.ColumnSetAlignment(
  const ALV: TCustomListView; const AIndex: Integer;
  const AColumn: TListColumn; const AAlignment: TAlignment);
begin
  inherited ColumnSetAlignment(ALV, AIndex, AColumn, AAlignment);
end;

class procedure TCocoaWSCustomListView.ColumnSetAutoSize(
  const ALV: TCustomListView; const AIndex: Integer;
  const AColumn: TListColumn; const AAutoSize: Boolean);
var
  lTableLV: TCocoaTableListView;
  lNSColumn: NSTableColumn;
  lResizeMask: NSUInteger;
begin
  if not CheckColumnParams(lTableLV, lNSColumn, ALV, AIndex) then Exit;

  if AAutoSize then lResizeMask := NSTableColumnAutoresizingMask
  else lResizeMask := NSTableColumnUserResizingMask;
  lNSColumn.setResizingMask(lResizeMask);
end;

class procedure TCocoaWSCustomListView.ColumnSetCaption(
  const ALV: TCustomListView; const AIndex: Integer;
  const AColumn: TListColumn; const ACaption: String);
var
  lTableLV: TCocoaTableListView;
  lNSColumn: NSTableColumn;
  lNSCaption: NSString;
begin
  if not CheckColumnParams(lTableLV, lNSColumn, ALV, AIndex) then Exit;

  lNSCaption := NSStringUtf8(ACaption);
  lNSColumn.headerCell.setStringValue(lNSCaption);
  lNSCaption.release;
end;

class procedure TCocoaWSCustomListView.ColumnSetImage(
  const ALV: TCustomListView; const AIndex: Integer;
  const AColumn: TListColumn; const AImageIndex: Integer);
begin
  inherited ColumnSetImage(ALV, AIndex, AColumn, AImageIndex);
end;

class procedure TCocoaWSCustomListView.ColumnSetMaxWidth(
  const ALV: TCustomListView; const AIndex: Integer;
  const AColumn: TListColumn; const AMaxWidth: Integer);
var
  lTableLV: TCocoaTableListView;
  lNSColumn: NSTableColumn;
begin
  {$IFDEF COCOA_DEBUG_LISTVIEW}
  WriteLn(Format('[TCocoaWSCustomListView.ColumnSetMaxWidth] AMaxWidth=%d', [AMaxWidth]));
  {$ENDIF}
  if not CheckColumnParams(lTableLV, lNSColumn, ALV, AIndex) then Exit;

  if AMaxWidth <= 0 then lNSColumn.setMaxWidth($FFFFFFFF)
  else lNSColumn.setMaxWidth(AMaxWidth);
end;

class procedure TCocoaWSCustomListView.ColumnSetMinWidth(
  const ALV: TCustomListView; const AIndex: Integer;
  const AColumn: TListColumn; const AMinWidth: integer);
var
  lTableLV: TCocoaTableListView;
  lNSColumn: NSTableColumn;
begin
  {$IFDEF COCOA_DEBUG_LISTVIEW}
  WriteLn(Format('[TCocoaWSCustomListView.ColumnSetMinWidth] AMinWidth=%d', [AMinWidth]));
  {$ENDIF}
  if not CheckColumnParams(lTableLV, lNSColumn, ALV, AIndex) then Exit;

  lNSColumn.setMinWidth(AMinWidth);
end;

class procedure TCocoaWSCustomListView.ColumnSetWidth(
  const ALV: TCustomListView; const AIndex: Integer;
  const AColumn: TListColumn; const AWidth: Integer);
var
  lTableLV: TCocoaTableListView;
  lNSColumn: NSTableColumn;
begin
  {$IFDEF COCOA_DEBUG_LISTVIEW}
  WriteLn(Format('[TCocoaWSCustomListView.ColumnSetWidth] AWidth=%d', [AWidth]));
  {$ENDIF}
  if not CheckColumnParams(lTableLV, lNSColumn, ALV, AIndex) then Exit;

  lNSColumn.setWidth(AWidth);
end;

class procedure TCocoaWSCustomListView.ColumnSetVisible(
  const ALV: TCustomListView; const AIndex: Integer;
  const AColumn: TListColumn; const AVisible: Boolean);
var
  lTableLV: TCocoaTableListView;
  lNSColumn: NSTableColumn;
begin
  if not CheckColumnParams(lTableLV, lNSColumn, ALV, AIndex) then Exit;

  lNSColumn.setHidden(not AVisible);
end;

class procedure TCocoaWSCustomListView.ItemDelete(const ALV: TCustomListView;
  const AIndex: Integer);
var
  lCocoaLV: TCocoaListView;
  lTableLV: TCocoaTableListView;
  lStr: NSString;
begin
  {$IFDEF COCOA_DEBUG_TABCONTROL}
  WriteLn(Format('[TCocoaWSCustomListView.ItemDelete] AIndex=%d', [AIndex]));
  {$ENDIF}
  if not CheckParams(lCocoaLV, lTableLV, ALV) then Exit;
  lTableLV.deleteItemForRow(AIndex);
  lTableLV.reloadData();
  lTableLV.scheduleSelectionDidChange();
end;

class function TCocoaWSCustomListView.ItemDisplayRect(
  const ALV: TCustomListView; const AIndex, ASubItem: Integer;
  ACode: TDisplayCode): TRect;
var
  lCocoaLV: TCocoaListView;
  lTableLV: TCocoaTableListView;
  lRowRect, lColRect, lNSRect: NSRect;
begin
  if not CheckParams(lCocoaLV, lTableLV, ALV) then Exit;
  lRowRect := lTableLV.rectOfRow(AIndex);
  lColRect := lTableLV.rectOfColumn(ASubItem);
  lNSRect := NSIntersectionRect(lRowRect, lColRect);
  NSToLCLRect(lNSRect, lCocoaLV.frame.size.height, Result);
end;

class function TCocoaWSCustomListView.ItemGetChecked(
  const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem
  ): Boolean;
begin
  Result:=inherited ItemGetChecked(ALV, AIndex, AItem);
end;

class function TCocoaWSCustomListView.ItemGetPosition(
  const ALV: TCustomListView; const AIndex: Integer): TPoint;
var
  lCocoaLV: TCocoaListView;
  lTableLV: TCocoaTableListView;
  lNSRect: NSRect;
begin
  if not CheckParams(lCocoaLV, lTableLV, ALV) then Exit;
  lNSRect := lTableLV.rectOfRow(AIndex);
  Result.X := Round(lNSRect.origin.X);
  Result.Y := Round(lCocoaLV.frame.size.height - lNSRect.origin.Y);
end;

class function TCocoaWSCustomListView.ItemGetState(const ALV: TCustomListView;
  const AIndex: Integer; const AItem: TListItem; const AState: TListItemState;
  out AIsSet: Boolean): Boolean;
begin
  Result:=inherited ItemGetState(ALV, AIndex, AItem, AState, AIsSet);
end;

class procedure TCocoaWSCustomListView.ItemInsert(const ALV: TCustomListView;
  const AIndex: Integer; const AItem: TListItem);
var
  lCocoaLV: TCocoaListView;
  lTableLV: TCocoaTableListView;
  i, lColumnCount: Integer;
  lColumn: NSTableColumn;
  lStr: string;
  lNSStr: NSString;
begin
  {$IFDEF COCOA_DEBUG_TABCONTROL}
  WriteLn(Format('[TCocoaWSCustomListView.ItemInsert] AIndex=%d', [AIndex]));
  {$ENDIF}
  if not CheckParams(lCocoaLV, lTableLV, ALV) then Exit;
  lColumnCount := lTableLV.tableColumns.count();
  {$IFDEF COCOA_DEBUG_TABCONTROL}
  WriteLn(Format('[TCocoaWSCustomListView.ItemInsert]=> lColumnCount=%d', [lColumnCount]));
  {$ENDIF}
  for i := 0 to lColumnCount-1 do
  begin
    lColumn := lTableLV.tableColumns.objectAtIndex(i);
    if i = 0 then
      lStr := AItem.Caption
    else if (i-1 < AItem.SubItems.Count) then
      lStr := AItem.SubItems.Strings[i-1]
    else
      lStr := '';
    lNSStr := NSStringUTF8(lStr);
    lTableLV.setStringValue_forCol_row(lNSStr, i, AIndex);
    lNSStr.release;
  end;
  lTableLV.reloadData();
  lTableLV.sizeToFit();
end;

class procedure TCocoaWSCustomListView.ItemSetText(const ALV: TCustomListView;
  const AIndex: Integer; const AItem: TListItem; const ASubIndex: Integer;
  const AText: String);
var
  lCocoaLV: TCocoaListView;
  lTableLV: TCocoaTableListView;
  lStr: NSString;
begin
  if not CheckParams(lCocoaLV, lTableLV, ALV) then Exit;
  lStr := NSStringUTF8(AText);
  lTableLV.setStringValue_forCol_row(lStr, ASubIndex, AItem.Index);
  lStr.release;
end;

class procedure TCocoaWSCustomListView.ItemShow(const ALV: TCustomListView;
  const AIndex: Integer; const AItem: TListItem; const PartialOK: Boolean);
begin
  inherited ItemShow(ALV, AIndex, AItem, PartialOK);
end;

class function TCocoaWSCustomListView.GetFocused(const ALV: TCustomListView): Integer;
var
  lCocoaLV: TCocoaListView;
  lTableLV: TCocoaTableListView;
begin
  if not CheckParams(lCocoaLV, lTableLV, ALV) then Exit;
  Result := lTableLV.selectedRow;
  {$IFDEF COCOA_DEBUG_TABCONTROL}
  WriteLn(Format('[TCocoaWSCustomListView.GetFocused] Result=%d', [Result]));
  {$ENDIF}
end;

class function TCocoaWSCustomListView.GetItemAt(const ALV: TCustomListView; x,
  y: integer): Integer;
var
  lCocoaLV: TCocoaListView;
  lTableLV: TCocoaTableListView;
  lNSPt: NSPoint;
begin
  if not CheckParams(lCocoaLV, lTableLV, ALV) then Exit;
  lNSPt := LCLToNSPoint(Point(X, Y), lTableLV.superview.frame.size.height);
  Result := lTableLV.rowAtPoint(lNSPt);
end;

class function TCocoaWSCustomListView.GetSelCount(const ALV: TCustomListView): Integer;
var
  lCocoaLV: TCocoaListView;
  lTableLV: TCocoaTableListView;
begin
  if not CheckParams(lCocoaLV, lTableLV, ALV) then Exit;
  Result := lTableLV.selectedRowIndexes().count();
end;

class function TCocoaWSCustomListView.GetSelection(const ALV: TCustomListView): Integer;
var
  lCocoaLV: TCocoaListView;
  lTableLV: TCocoaTableListView;
begin
  if not CheckParams(lCocoaLV, lTableLV, ALV) then Exit;
  Result := lTableLV.selectedRow;
  {$IFDEF COCOA_DEBUG_TABCONTROL}
  WriteLn(Format('[TCocoaWSCustomListView.GetSelection] Result=%d', [Result]));
  {$ENDIF}
end;

class function TCocoaWSCustomListView.GetTopItem(const ALV: TCustomListView): Integer;
var
  lCocoaLV: TCocoaListView;
  lTableLV: TCocoaTableListView;
  lVisibleRows: NSRange;
begin
  if not CheckParams(lCocoaLV, lTableLV, ALV) then Exit;
  lVisibleRows := lTableLV.rowsInRect(lTableLV.visibleRect());
  Result := lVisibleRows.location;
end;

class function TCocoaWSCustomListView.GetVisibleRowCount(
  const ALV: TCustomListView): Integer;
var
  lCocoaLV: TCocoaListView;
  lTableLV: TCocoaTableListView;
  lVisibleRows: NSRange;
begin
  if not CheckParams(lCocoaLV, lTableLV, ALV) then Exit;
  lVisibleRows := lTableLV.rowsInRect(lTableLV.visibleRect());
  Result := lVisibleRows.length;
end;

class procedure TCocoaWSCustomListView.SetDefaultItemHeight(
  const ALV: TCustomListView; const AValue: Integer);
var
  lCocoaLV: TCocoaListView;
  lTableLV: TCocoaTableListView;
begin
  if not CheckParams(lCocoaLV, lTableLV, ALV) then Exit;
  if AValue > 0 then
    lTableLV.setRowHeight(AValue);
  // setRowSizeStyle could be used here but is available only in 10.7+
end;

class procedure TCocoaWSCustomListView.SetProperty(const ALV: TCustomListView;
  const AProp: TListViewProperty; const AIsSet: Boolean);
var
  lCocoaLV: TCocoaListView;
  lTableLV: TCocoaTableListView;
begin
  if not CheckParams(lCocoaLV, lTableLV, ALV) then Exit;
  case AProp of
  {lvpAutoArrange,
  lvpCheckboxes,}
  lvpColumnClick: lTableLV.setAllowsColumnSelection(AIsSet);
{  lvpFlatScrollBars,
  lvpFullDrag,
  lvpGridLines,
  lvpHideSelection,
  lvpHotTrack,}
  lvpMultiSelect: lTableLV.setAllowsMultipleSelection(AIsSet);
  {lvpOwnerDraw,
  //lvpReadOnly, implemented elsewhere, no need for this here
  lvpRowSelect,
  lvpShowColumnHeaders,
  lvpShowWorkAreas,
  lvpWrapText,
  lvpToolTips}
  end;
end;

class procedure TCocoaWSCustomListView.SetProperties(
  const ALV: TCustomListView; const AProps: TListViewProperties);
begin
  inherited SetProperties(ALV, AProps);
end;

class procedure TCocoaWSCustomListView.SetScrollBars(
  const ALV: TCustomListView; const AValue: TScrollStyle);
var
  lTableLV: TCocoaTableListView;
  lCocoaLV: TCocoaListView;
begin
  if not CheckParams(lCocoaLV, lTableLV, ALV) then Exit;
  case AValue of
  ssNone:
  begin
    lCocoaLV.setHasHorizontalRuler(False);
    lCocoaLV.setHasVerticalRuler(False);
  end;
  ssHorizontal, ssAutoHorizontal:
  begin
    lCocoaLV.setHasHorizontalRuler(True);
    lCocoaLV.setHasVerticalRuler(False);
  end;
  ssVertical, ssAutoVertical:
  begin
    lCocoaLV.setHasHorizontalRuler(False);
    lCocoaLV.setHasVerticalRuler(True);
  end;
  ssBoth, ssAutoBoth:
  begin
    lCocoaLV.setHasHorizontalRuler(True);
    lCocoaLV.setHasVerticalRuler(True);
  end;
  end;
  lCocoaLV.setAutohidesScrollers(AValue in [ssAutoHorizontal, ssAutoVertical, ssAutoBoth]);
end;

{ TCocoaWSProgressBar }

class function TCocoaWSProgressBar.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
var
  lResult: TCocoaProgressIndicator;
begin
  lResult := TCocoaProgressIndicator.alloc.lclInitWithCreateParams(AParams);
  if Assigned(lResult) then
  begin
    lResult.callback := TLCLCommonCallback.Create(lResult, AWinControl);
    lResult.startAnimation(nil);
    //small constrol size looks like carbon
    //lResult.setControlSize(NSSmallControlSize);
  end;
  Result := TLCLIntfHandle(lResult);
end;

class procedure TCocoaWSProgressBar.ApplyChanges(
  const AProgressBar: TCustomProgressBar);
var
  ind : NSProgressIndicator;
begin
  if not Assigned(AProgressBar) or not AProgressBar.HandleAllocated then Exit;
  ind:=NSProgressIndicator(AProgressBAr.Handle);
  ind.setMaxValue(AProgressBar.Max);
  ind.setMinValue(AProgressBar.Min);
  ind.setDoubleValue(AProgressBar.Position);
  ind.setIndeterminate(AProgressBar.Style = pbstMarquee);
end;

class procedure TCocoaWSProgressBar.SetPosition(
  const AProgressBar: TCustomProgressBar; const NewPosition: integer);
begin
  if AProgressBar.HandleAllocated then
    NSProgressIndicator(AProgressBar.Handle).setDoubleValue(NewPosition);
end;

class procedure TCocoaWSProgressBar.SetStyle(
  const AProgressBar: TCustomProgressBar; const NewStyle: TProgressBarStyle);
begin
  if AProgressBar.HandleAllocated then
    NSProgressIndicator(AProgressBar.Handle).setIndeterminate(NewStyle = pbstMarquee);
end;

{ TCocoaTabPage }

(*function TCocoaTabPage.lclGetCallback: ICommonCallback;
begin
  Result:=callback;
end;

procedure TCocoaTabPage.lclClearCallback;
begin
  callback:=nil;
end;

{ TCocoaTabControl }

function TCocoaTabControl.lclGetCallback: ICommonCallback;
begin
  Result:=callback;
end;

procedure TCocoaTabControl.lclClearCallback;
begin
  callback:=nil;
end; *)

{ TLCLListViewCallback }

procedure TLCLListViewCallback.delayedSelectionDidChange_OnTimer(
  ASender: TObject);
begin
  TCocoaTableListView(Owner).Timer.Enabled := False;
  TCocoaTableListView(Owner).tableViewSelectionDidChange(nil);
end;

{ TCocoaWSTrackBar }

{------------------------------------------------------------------------------
  Method:  TCocoaWSTrackBar.CreateHandle
  Params:  AWinControl - LCL control
           AParams     - Creation parameters
  Returns: Handle to the control in Carbon interface

  Creates new track bar with the specified parameters
 ------------------------------------------------------------------------------}
class function TCocoaWSTrackBar.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
var
  lResult: TCocoaSlider;
begin
  lResult := TCocoaSlider.alloc.lclInitWithCreateParams(AParams);
  if Assigned(lResult) then
  begin
    lResult.callback := TLCLCommonCallback.Create(lResult, AWinControl);
    lResult.setTarget(lResult);
    lResult.setAction(objcselector('sliderAction:'));
  end;
  Result := TLCLIntfHandle(lResult);
end;

{------------------------------------------------------------------------------
  Method:  TCocoaWSTrackBar.ApplyChanges
  Params:  ATrackBar - LCL custom track bar

  Sets the parameters (Min, Max, Position, Ticks) of slider
 ------------------------------------------------------------------------------}
class procedure TCocoaWSTrackBar.ApplyChanges(const ATrackBar: TCustomTrackBar);
var
  lSlider: TCocoaSlider;
  lTickCount, lTrackBarLength: Integer;
begin
  if not Assigned(ATrackBar) or not ATrackBar.HandleAllocated then Exit;
  lSlider := TCocoaSlider(ATrackBar.Handle);
  lSlider.setMaxValue(ATrackBar.Max);
  lSlider.setMinValue(ATrackBar.Min);
  lSlider.setIntValue(ATrackBar.Position);

  if ATrackBar.Orientation = trHorizontal then
    lTrackBarLength := ATrackBar.Width
  else
    lTrackBarLength := ATrackBar.Height;

  // Ticks
  if ATrackBar.TickStyle = tsNone then
  begin
    lTickCount := 0;
  end
  else
  begin
    lTickCount := lTrackBarLength div 5;
    lTickCount := Min(lTickCount, ATrackBar.Max-ATrackBar.Min);
  end;
  lSlider.setNumberOfTickMarks(lTickCount);

  //procedure setAltIncrementValue(incValue: double); message 'setAltIncrementValue:';
  //procedure setTitle(aString: NSString); message 'setTitle:';
  //procedure setKnobThickness(aFloat: CGFloat); message 'setKnobThickness:';
end;

{------------------------------------------------------------------------------
  Method:  TCocoaWSTrackBar.GetPosition
  Params:  ATrackBar - LCL custom track bar
  Returns: Position of slider
 ------------------------------------------------------------------------------}
class function TCocoaWSTrackBar.GetPosition(const ATrackBar: TCustomTrackBar
  ): integer;
var
  lSlider: TCocoaSlider;
begin
  if not Assigned(ATrackBar) or not ATrackBar.HandleAllocated then Exit;
  lSlider := TCocoaSlider(ATrackBar.Handle);
  Result := lSlider.intValue();
end;

{------------------------------------------------------------------------------
  Method:  TCocoaWSTrackBar.SetPosition
  Params:  ATrackBar - LCL custom track bar
           NewPosition  - New position

  Sets the position of slider
 ------------------------------------------------------------------------------}
class procedure TCocoaWSTrackBar.SetPosition(const ATrackBar: TCustomTrackBar;
  const NewPosition: integer);
var
  lSlider: TCocoaSlider;
begin
  if not Assigned(ATrackBar) or not ATrackBar.HandleAllocated then Exit;
  lSlider := TCocoaSlider(ATrackBar.Handle);
  lSlider.setIntValue(ATrackBar.Position);
end;

// Cocoa auto-detects the orientation based on width/height and there seams
// to be no way to force it
class procedure TCocoaWSTrackBar.SetOrientation(
  const ATrackBar: TCustomTrackBar; const AOrientation: TTrackBarOrientation);
begin
  if (AOrientation = trHorizontal) and (ATrackBar.Height > ATrackBar.Width) then
    ATrackBar.Width := ATrackBar.Height + 1
  else if (AOrientation = trVertical) and (ATrackBar.Width > ATrackBar.Height) then
    ATrackBar.Height := ATrackBar.Width + 1;
end;

end.
