{ $Id$ }
{
 /***************************************************************************
                       gtk2int.pas  -  GTK2 Interface Object
                       -------------------------------------


 ***************************************************************************/

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

unit Gtk2Int;

{$mode objfpc}{$H+}

interface

{$ifdef Trace}
{$ASSERTIONS ON}
{$endif}

{$I gtk2defines.inc}

uses
  ctypes,
  {$ifdef Unix}
  BaseUnix, Unix,
  {$endif}
  Types, Classes, SysUtils, Math, maps,
  {$IfNDef GTK2_2}
    {$IfDef HasX}
     XLib, X, //XUtil,
    {$EndIf}
  {$EndIf}


  // LCL
  FileUtil, Translations, ExtDlgs, Dialogs, Controls, Forms, LCLStrConsts,
  LMessages, LCLProc, LCLIntf, LCLType, DynHashArray, GraphType, GraphMath,
  Graphics, Menus, Themes, WSLCLClasses,

  Buttons, StdCtrls, PairSplitter,
  ComCtrls, Calendar, Arrow, Spin,
  ExtCtrls, FileCtrl, LResources,

  gdk2pixbuf, gtk2, gdk2, glib2, Pango,
  InterfaceBase,
  Gtk2WinApiWindow,
  Gtk2Globals, Gtk2Proc,
  Gtk2Def, GtkFontCache, Gtk2Extra,
  GtkMsgQueue;

type

  { TGtk2WidgetSet }

  TGtk2WidgetSet = class(TWidgetSet)
  private
    FMultiThreadingEnabled: boolean;
    FocusTimer: cardinal;
    FLastFocusIn: PGtkWidget;
    FLastFocusOut: PGtkWidget;
    StayOnTopList: TMap;
    FAppActive: Boolean;
    function GetAppActive: Boolean;
    procedure SetAppActive(const AValue: Boolean);

  protected
    procedure AppendText(Sender: TObject; Str: PChar);
    function GetText(Sender: TComponent; var Text: String): Boolean;
    function CreateThemeServices: TThemeServices; override;
    function GetDeviceContextClass: TGtkDeviceContextClass;
  protected
    FKeyStateList_: TFPList; // Keeps track of which keys are pressed
    FDeviceContexts: TDynHashArray;// hasharray of HDC
    FGDIObjects: TDynHashArray;    // hasharray of PGdiObject
    FMessageQueue: TGtkMessageQueue; // queue of PMsg (must be thread safe!)
    WaitingForMessages: boolean;
    MovedPaintMessageCount: integer;// how many paint messages moved to he end of the queue

    FRCFilename: string;
    FRCFileParsed: boolean;
    FRCFileAge: integer;
    FGTKToolTips: PGtkToolTips;

    FLogHandlerID: guint; // ID returend by set_handler

    FStockNullBrush: HBRUSH;
    FStockBlackBrush: HBRUSH;
    FStockLtGrayBrush: HBRUSH;
    FStockGrayBrush: HBRUSH;
    FStockDkGrayBrush: HBRUSH;
    FStockWhiteBrush: HBRUSH;

    FStockNullPen: HPEN;
    FStockBlackPen: HPEN;
    FStockWhitePen: HPEN;

    FSysColorBrushes: array[0..MAX_SYS_COLORS] of HBrush;

    FWaitHandles: PWaitHandleEventHandler;
    {$ifdef unix}
    FChildSignalHandlers: PChildSignalEventHandler;
    {$else}
    {$IFDEF VerboseGtkToDos}{$warning no declaration of FChildSignalHandlers for this OS}{$ENDIF}
    {$endif}

    {$Ifdef GTK2}
    FDefaultFontDesc: PPangoFontDescription;
    {$Endif}
    FDefaultFont: TGtkIntfFont;
    FStockSystemFont: HFONT;
    FExtUTF8OutCache: Pointer;
    FExtUTF8OutCacheSize: integer;
    FGlobalCursor: HCursor;

    FDCManager: TDeviceContextMemManager;
    FDockImage: PGtkWidget;
    FDragImageList: PGtkWidget;
    FDragImageListIcon: PGtkWidget;
    FDragHotStop: TPoint;
  public
    procedure InitStockItems; virtual;
    procedure FreeStockItems; virtual;
    procedure InitSystemColors;
    procedure InitSystemBrushes; virtual;
    procedure FreeSystemBrushes; virtual;
    procedure PassCmdLineOptions; override;

{$ifdef Unix}
    procedure InitSynchronizeSupport;
    procedure ProcessChildSignal;
    procedure PrepareSynchronize(AObject: TObject);
{$endif}

    procedure HandlePipeEvent(AData: PtrInt; AFlags: dword);

    // styles
    procedure FreeAllStyles; virtual;
    function GetCompStyle(Sender : TObject) : Longint; virtual;

    // create and destroy
    function CreateAPIWidget(AWinControl: TWinControl): PGtkWidget;
    function OldCreateStatusBarPanel(StatusBar: TObject; Index: integer): PGtkWidget;
    function CreateSimpleClientAreaWidget(Sender: TObject;
      NotOnParentsClientArea: boolean): PGtkWidget;
    procedure DestroyEmptySubmenu(Sender: TObject);virtual;
    procedure DestroyConnectedWidget(Widget: PGtkWidget;
                                     CheckIfDestroying: boolean);virtual;
    function  RecreateWnd(Sender: TObject): Integer; virtual;
    procedure AssignSelf(Child, Data: Pointer);virtual;

    // clipboard
    procedure SetClipboardWidget(TargetWidget: PGtkWidget);virtual;

    // device contexts
    function IsValidDC(const DC: HDC): Boolean;virtual;
    function NewDC: TGtkDeviceContext;virtual;
    function FindDCWithGDIObject(GDIObject: PGdiObject): TGtkDeviceContext;virtual;
    procedure DisposeDC(aDC: TGtkDeviceContext);virtual;
    function CreateDCForWidget(AWidget: PGtkWidget; AWindow: PGdkWindow;
                               AWithChildWindows: Boolean; ADoubleBuffer: PgdkDrawable = nil): HDC;
    function GetDoubleBufferedDC(Handle: HWND): HDC;

    // GDIObjects
    function IsValidGDIObject(const AGDIObj: HGDIOBJ): Boolean; virtual;
    function IsValidGDIObjectType(const GDIObject: HGDIOBJ;
                                  const GDIType: TGDIType): Boolean;virtual;
    function NewGDIObject(const GDIType: TGDIType): PGdiObject;virtual;
    procedure DisposeGDIObject(GdiObject: PGdiObject);virtual;
    function ReleaseGDIObject(GdiObject: PGdiObject): boolean;virtual;
    procedure ReferenceGDIObject(GdiObject: PGdiObject);virtual;
    function CreateDefaultBrush: PGdiObject;virtual;
    function CreateDefaultFont: PGdiObject;virtual;
    function CreateDefaultPen: PGdiObject;virtual;
    function CreateDefaultGDIBitmap: PGdiObject;virtual;
    procedure UpdateDCTextMetric(DC: TGtkDeviceContext); virtual;
    {$Ifdef GTK2}
    function GetDefaultFontDesc(IncreaseReferenceCount: boolean): PPangoFontDescription;
    {$Endif}
    function GetDefaultGtkFont(IncreaseReferenceCount: boolean): TGtkIntfFont;
    function GetGtkFont(DC: TGtkDeviceContext): TGtkIntfFont;
    function CreateRegionCopy(SrcRGN: hRGN): hRGN; override;
    function DCClipRegionValid(DC: HDC): boolean; override;
    function CreateEmptyRegion: hRGN; override;

    // images
    procedure LoadPixbufFromLazResource(const ResourceName: string;
      var Pixbuf: PGdkPixbuf);
    function InternalGetDIBits(DC: HDC; Bitmap: HBitmap; StartScan, NumScans: UINT;
      BitSize : Longint; Bits: Pointer; var BitInfo: BitmapInfo; Usage: UINT; DIB : Boolean): Integer;virtual;
    function RawImage_DescriptionFromDrawable(out ADesc: TRawImageDescription; ADrawable: PGdkDrawable; ACustomAlpha: Boolean): boolean;
    function RawImage_DescriptionFromPixbuf(out ADesc: TRawImageDescription; APixbuf: PGdkPixbuf): boolean;
    function RawImage_FromDrawable(out ARawImage: TRawImage; ADrawable, AAlpha: PGdkDrawable; ARect: PRect = nil): boolean;
    function RawImage_FromPixbuf(out ARawImage: TRawImage; APixbuf: PGdkPixbuf; ARect: PRect = nil): boolean;
    function RawImage_SetAlpha(var ARawImage: TRawImage; AAlpha: PGdkPixmap; ARect: PRect = nil): boolean;
    function RawImage_AddMask(var ARawImage: TRawImage; AMask: PGdkBitmap; ARect: PRect = nil): boolean;
    function StretchCopyArea(DestDC: HDC; X, Y, Width, Height: Integer;
      SrcDC: HDC; XSrc, YSrc, SrcWidth, SrcHeight: Integer;
      Mask: HBITMAP; XMask, YMask: Integer;
      Rop: Cardinal): Boolean;

    // RC file
    procedure SetRCFilename(const AValue: string);virtual;
    procedure CheckRCFilename;virtual;
    procedure ParseRCFile;virtual;

    // forms and dialogs
    procedure BringFormToFront(Sender: TObject);
    procedure UntransientWindow(GtkWindow: PGtkWindow);
    // misc
    function GetCaption(Sender : TObject) : String; virtual;
    procedure WordWrap(DC: HDC; AText: PChar; MaxWidthInPixel: integer;
      var Lines: PPChar; var LineCount: integer);

    procedure ResizeChild(Sender : TObject; Left,Top,Width,Height : Integer);virtual;
    procedure RemoveCallbacks(Widget: PGtkWidget); virtual;

    // for gtk specific components:
    procedure SetWidgetColor(const AWidget: PGtkWidget;
                             const FGColor, BGColor: TColor;
                             const Mask: tGtkStateEnum);
    procedure SetCallbackDirect(const AMsg: LongInt; const AGTKObject: PGTKObject;
                          const ALCLObject: TObject);
    procedure SetCallback(const AMsg: LongInt; const AGTKObject: PGTKObject;
                          const ALCLObject: TObject);
    function  LCLtoGtkMessagePending: boolean;virtual;
    procedure SendCachedGtkMessages;virtual;
    // show, hide and invalidate
    procedure SetVisible(Sender: TObject; const AVisible: Boolean); virtual;

    // Drag ImageLsit
    function DragImageList_BeginDrag(APixmap: PGdkPixmap; AMask: PGdkBitmap; AHotSpot: TPoint): Boolean;
    procedure DragImageList_EndDrag;
    function DragImageList_DragMove(X, Y: Integer): Boolean;
    function DragImageList_SetVisible(NewVisible: Boolean): Boolean;

    procedure UpdateTransientWindows; virtual;
    procedure SendCachedLCLMessages; override;

    function CreateTimer(Interval: integer; TimerProc: TWSTimerProc) : THandle; override;
    function DestroyTimer(TimerHandle: THandle) : boolean; override;
    procedure DestroyLCLComponent(Sender: TObject);virtual;
    // notebook
    procedure AddDummyNoteBookPage(NoteBookWidget: PGtkNoteBook);virtual;


    function CreateStandardCursor(ACursor: SmallInt): hCursor; override;
    procedure SetDesigning(AComponent: TComponent); override;
    function  DCGetPixel(CanvasHandle: HDC; X, Y: integer): TGraphicsColor; override;
    procedure DCSetPixel(CanvasHandle: HDC; X, Y: integer; AColor: TGraphicsColor); override;
    procedure DCRedraw(CanvasHandle: HDC); override;
    procedure FinishCreateHandle(const AWinControl: TWinControl;
      Widget: PGtkWidget; const AParams: TCreateParams);

  private
    procedure Gtk1Create;
    procedure Gtk1Destroy;

  public
    constructor Create; override;
    destructor Destroy; override;

    function LCLPlatform: TLCLPlatform; override;

    procedure AppInit(var ScreenInfo: TScreenInfo); override;
    procedure AppBringToFront; override;
    procedure AppMinimize; override;
    procedure AppRestore; override;
    function AppHandle: THandle; override;
    function AppRemoveStayOnTopFlags(const ASystemTopAlso: Boolean = False): Boolean; override;
    function AppRestoreStayOnTopFlags(const ASystemTopAlso: Boolean = False): Boolean; override;
    procedure AppProcessMessages; override;
    procedure AppWaitMessage; override;
    procedure AppTerminate; override;
    procedure AppSetTitle(const ATitle: string); override;

    // copied from GtkInt
    procedure _SetCallbackEx(const AMsg: LongInt; const AGTKObject: PGTKObject; const ALCLObject: TObject; Direct: Boolean);
    procedure SetCallbackEx(const AMsg: LongInt; const AGTKObject: PGTKObject; const ALCLObject: TObject; Direct: Boolean);
    procedure SetCommonCallbacks(const AGTKObject: PGTKObject; const ALCLObject: TObject);
    procedure SetLabelCaption(const ALabel: PGtkLabel; const ACaption: String);
    procedure SetSelectionMode(Sender: TObject; Widget: PGtkWidget;
      MultiSelect, ExtendedSelect: Boolean);
    function ForceLineBreaks(DC : hDC; Src: PChar; MaxWidthInPixels : Longint;
                             ConvertAmpersandsToUnderScores: Boolean) : PChar;
    procedure SetWidgetFont(const AWidget: PGtkWidget; const AFont: TFont);
    {$I gtk2winapih.inc}
    {$I gtk2lclintfh.inc}
  public
    procedure StartFocusTimer;
    property AppActive: Boolean read GetAppActive write SetAppActive;
    property LastFocusIn: PGtkWidget read FLastFocusIn write FLastFocusIn;
    property LastFocusOut: PGtkWidget read FLastFocusOut write FLastFocusOut;
    property MultiThreadingEnabled: boolean read FMultiThreadingEnabled;
  end;

  {$I gtk2listslh.inc}

  { TGtkListStoreStringList }

  TGtkListStoreStringList = class(TStrings)
  private
    FChangeStamp: Integer;
    FColumnIndex: Integer;
    FGtkListStore: PGtkListStore;
    FOwner: TWinControl;
    FSorted: Boolean;
    FStates: TGtkListStringsStates;
    FCachedCount: Integer;
    FCachedCapacity: Integer;
    FCachedSize: Integer;
    FCachedItems: PGtkTreeIter;
    FUpdateCount: Integer;
  protected
    function GetCount: Integer; override;
    function Get(Index: Integer): String; override;
    function GetObject(Index: Integer): TObject; override;
    procedure Put(Index: Integer; const S: String); override;
    procedure PutObject(Index: Integer; AnObject: TObject); override;
    procedure SetSorted(Val: Boolean); virtual;
    procedure UpdateItemCache;
    procedure GrowCache;
    procedure ShrinkCache;
    procedure IncreaseChangeStamp;
  public
    constructor Create(AListStore: PGtkListStore;
                       ColumnIndex: Integer; AOwner: TWinControl);
    destructor Destroy; override;
    function Add(const S: String): Integer; override;
    procedure Assign(Source: TPersistent); override;
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    function Find(const S: String; var Index: Integer): Boolean;
    function IndexOf(const S: String): Integer; override;
    procedure Insert(Index: Integer; const S: String); override;
    procedure Sort; virtual;
    function IsEqual(List: TStrings): Boolean;
    procedure BeginUpdate;
    procedure EndUpdate;
  public
    property Sorted: Boolean read FSorted write SetSorted;
    property Owner: TWinControl read FOwner;
    property ChangeStamp: Integer read FChangeStamp;
  end;

var
  GTK2WidgetSet: TGTK2WidgetSet;


implementation

uses
{$ifdef Windows}
  Gtk2Windows,
{$endif}
  Gtk2WSFactory,
  Gtk2WSStdCtrls,
  Gtk2WSControls,
  Gtk2WSPrivate,
  Gtk2Themes,
////////////////////////////////////////////////////
  GtkDebug;

{$include gtk2widgetset.inc}
{$include gtk2winapi.inc}
{$include gtk2lclintf.inc}

const
  GtkListStoreItemGtkListTag = 'GtkList';
  GtkListStoreItemLCLListTag = 'LCLList';

{*************************************************************}
{                      TGtkListStoreStringList methods             }
{*************************************************************}

{------------------------------------------------------------------------------
  Method: TGtkListStoreStringList.Create
  Params:
  Returns:

 ------------------------------------------------------------------------------}
constructor TGtkListStoreStringList.Create(AListStore: PGtkListStore;
  ColumnIndex: Integer; AOwner: TWinControl);
begin
  inherited Create;
  if AListStore = nil 
  then RaiseGDBException('TGtkListStoreStringList.Create Unspecified list store');

  FGtkListStore := AListStore;

  if (ColumnIndex < 0) 
  or (ColumnIndex >= gtk_tree_model_get_n_columns(GTK_TREE_MODEL(fGtkListStore))) 
  then RaiseGDBException('TGtkListStoreStringList.Create Invalid Column Index');
  FColumnIndex := ColumnIndex;

  if AOwner = nil 
  then RaiseGDBException('TGtkListStoreStringList.Create Unspecified owner');
  FOwner := AOwner;
  FStates := [glsItemCacheNeedsUpdate, glsCountNeedsUpdate];
end;

destructor TGtkListStoreStringList.Destroy;
begin
  FGtkListStore := nil;
  // don't destroy the widgets
  ReAllocMem(FCachedItems, 0);
  inherited Destroy;
end;

function TGtkListStoreStringList.Add(const S: String): Integer;
begin
  if FSorted then
    Find(S, Result)
  else
    Result := Count;

  //DebugLn(['TGtkListStoreStringList.Add ',S,' Count=',Result]);
  Insert(Result, S);
end;

{------------------------------------------------------------------------------
  Method: TGtkListStringList.SetSorted
  Params:
  Returns:

 ------------------------------------------------------------------------------}
procedure TGtkListStoreStringList.SetSorted(Val: Boolean);
var
  i: Integer;
begin
  if Val = FSorted then Exit;

  FSorted := Val;
  if not FSorted then Exit;

  for i := 0 to Count - 2 do
  begin
    if AnsiCompareText(Strings[i], Strings[i + 1]) < 0 then
    begin
      Sort;
      Break;
    end;
  end;
end;

{------------------------------------------------------------------------------
  procedure TGtkListStoreStringList.RemoveAllCallbacks;

 ------------------------------------------------------------------------------}

procedure TGtkListStoreStringList.UpdateItemCache;
var
  i: Integer;
begin
  if not (glsItemCacheNeedsUpdate in FStates) then exit;

  //DebugLn(['TGtkListStoreStringList.UpdateItemCache ']); DumpStack;
  FCachedSize := Count;
  FCachedCapacity := Count;
  ReAllocMem(FCachedItems, SizeOf(TGtkTreeIter) * FCachedCapacity);
  if FGtkListStore <> nil then
    for I := 0 to FCachedSize - 1 do
      gtk_tree_model_iter_nth_child(GTK_TREE_MODEL(FGtkListStore),
        @FCachedItems[i], nil, I);
  Exclude(FStates, glsItemCacheNeedsUpdate);
end;

procedure TGtkListStoreStringList.GrowCache;
begin
  FCachedCapacity := ((FCachedCapacity * 5) div 4) + 10;
  ReAllocMem(FCachedItems, SizeOf(TGtkTreeIter) * FCachedCapacity);
end;

procedure TGtkListStoreStringList.ShrinkCache;
begin
  FCachedCapacity := FCachedSize + 1;
  ReAllocMem(FCachedItems, SizeOf(TGtkTreeIter) * FCachedCapacity);
end;

procedure TGtkListStoreStringList.IncreaseChangeStamp;
begin
  if FChangeStamp < High(FChangeStamp) then
    Inc(FChangeStamp)
  else
    FChangeStamp := Low(FChangeStamp);
end;

procedure TGtkListStoreStringList.PutObject(Index: Integer; AnObject: TObject);
var
  ListItem: TGtkTreeIter;
begin
  if (Index < 0) or (Index >= Count) 
  then begin
    RaiseGDBException('TGtkListStoreStringList.PutObject Out of bounds.');
    Exit;
  end;

  if FGtkListStore = nil then Exit;

  UpdateItemCache;
  ListItem := FCachedItems[Index];
  gtk_list_store_set(FGtkListStore, @ListItem, [FColumnIndex + 1, Pointer(AnObject), -1]);
  IncreaseChangeStamp;
end;

{------------------------------------------------------------------------------
  Method: TGtkListStoreStringList.Sort
  Params:
  Returns:

 ------------------------------------------------------------------------------}
procedure TGtkListStoreStringList.Sort;
var
  sl: TStringList;
  OldSorted: Boolean;
begin
  BeginUpdate;
  // sort internally (sorting in the widget would be slow and unpretty ;)
  sl := TStringList.Create;
  sl.Assign(Self);
  sl.Sort;
  OldSorted := Sorted;
  FSorted := False;
  Assign(sl);
  FSorted := OldSorted;
  sl.Free;
  EndUpdate;
end;

function TGtkListStoreStringList.IsEqual(List: TStrings): Boolean;
var
  i, Cnt: Integer;
begin
  if List = Self then Exit(True);
  if List = nil then Exit(False);

  Cnt := Count;
  if (Cnt <> List.Count) then Exit(False);

  for i := 0 to Cnt - 1 do
  begin
    if Strings[i] <> List[i] then Exit(False);
    if Objects[i] <> List.Objects[i] then Exit(False);
  end;
  
  Result := True;
end;

procedure TGtkListStoreStringList.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TGtkListStoreStringList.EndUpdate;
begin
  Dec(FUpdateCount);
end;

{------------------------------------------------------------------------------
  Method: TGtkListStoreStringList.Assign
  Params:
  Returns:

 ------------------------------------------------------------------------------}
procedure TGtkListStoreStringList.Assign(Source: TPersistent);
var
  i, Cnt: Integer;
  CmpList: TStrings;
  OldSorted: Boolean;
begin
  if (Source = Self) or (Source = nil) then Exit;

  if ((Source is TGtkListStoreStringList) 
  and (TGtkListStoreStringList(Source).FGtkListStore = FGtkListStore)) then
    RaiseGDBException('TGtkListStoreStringList.Assign: There are 2 lists with the same FGtkListStore');

  BeginUpdate;
  OldSorted := Sorted;
  CmpList := nil;
  try
    if Source is TStrings then
    begin
      // clearing and resetting can change other properties of the widget,
      // => don't change if the content is already the same
      if Sorted then
      begin
        CmpList := TStringList.Create;
        CmpList.Assign(TStrings(Source));
        TStringList(CmpList).Sort;
      end
      else
        CmpList := TStrings(Source);
     
      if IsEqual(CmpList) then Exit;

      Clear;
      FSorted := False;
      Cnt := TStrings(Source).Count;
      for i := 0 to Cnt - 1 do
      begin
        AddObject(CmpList[i], CmpList.Objects[i]);
        //DebugLn(['TGtkListStoreStringList.Assign ',i,' ',CmpList[i],' ',Count]);
      end;
      // ToDo: restore other settings

      // Do not call inherited Assign as it does things we do not want to happen
    end
    else
      inherited Assign(Source);
  finally
    fSorted := OldSorted;
    if CmpList <> Source 
    then CmpList.Free;

    EndUpdate;
  end;
end;

{------------------------------------------------------------------------------
  Method: TGtkListStoreStringList.Get
  Params:
  Returns:

 ------------------------------------------------------------------------------}
function TGtkListStoreStringList.Get(Index: Integer): String;
var
  Item: PChar;
  ListItem: TGtkTreeIter;
begin
  if (Index < 0) or (Index >= Count) 
  then begin
    RaiseGDBException('TGtkListStoreStringList.Get Out of bounds.');
    Exit;
  end;

  UpdateItemCache;
  ListItem := FCachedItems[Index];

  Item := nil;
  gtk_tree_model_get(GTK_TREE_MODEL(FGtkListStore), @ListItem, [FColumnIndex, @Item, -1]);
  if Item = nil then Exit('');

  Result := Item;
  g_free(Item);
end;

function TGtkListStoreStringList.GetObject(Index: Integer): TObject;
var
  ListItem: TGtkTreeIter;
begin
  if (Index < 0) or (Index >= Count)
  then begin
    RaiseGDBException('TGtkListStoreStringList.GetObject Out of bounds.');
    Exit(nil);
  end;
  if FGtkListStore = nil then Exit(nil);

  UpdateItemCache;
  ListItem := FCachedItems[Index];
  gtk_tree_model_get(FGtkListStore, @ListItem, [FColumnIndex + 1, @Result, -1]);
end;

procedure TGtkListStoreStringList.Put(Index: Integer; const S: String);
var
  ListItem: TGtkTreeIter;
begin
  if (Index < 0) or (Index >= Count) 
  then begin
    RaiseGDBException('TGtkListStoreStringList.Put Out of bounds.');
    Exit;
  end;
  if FGtkListStore = nil then Exit;

  UpdateItemCache;
  ListItem := FCachedItems[Index];
  gtk_list_store_set(FGtkListStore, @ListItem, [FColumnIndex, PChar(S), -1]);
  IncreaseChangeStamp;
end;

{------------------------------------------------------------------------------
  Method: TGtkListStoreStringList.GetCount
  Params:
  Returns:

 ------------------------------------------------------------------------------}
function TGtkListStoreStringList.GetCount: Integer;
begin
  if (glsCountNeedsUpdate in FStates) then
  begin
    if FGtkListStore <> nil then
      FCachedCount := gtk_tree_model_iter_n_children(GTK_TREE_MODEL(FGtkListStore), nil)
    else
      FCachedCount := 0;
    Exclude(FStates, glsCountNeedsUpdate);
  end;
  Result := FCachedCount;
end;

{------------------------------------------------------------------------------
  Method: TGtkListStoreStringList.Clear
  Params:
  Returns:

 ------------------------------------------------------------------------------}
procedure TGtkListStoreStringList.Clear;
var
  WidgetInfo: PWidgetInfo;
begin
  //DebugLn(['TGtkListStoreStringList.Clear ']);
  //while Count>0 do Delete(Count-1);

  //Lock the widget to avoid trigger events
  //Note: Assign/Clear is called inside CreateHandle before Handle is set
  if FOwner.HandleAllocated then
  begin
    WidgetInfo := GetWidgetInfo(Pointer(FOwner.Handle), False);
    Inc(WidgetInfo^.ChangeLock);

    gtk_list_store_clear(FGtkListStore);

    Dec(WidgetInfo^.ChangeLock);
    //Update the internal Index cache
    PInteger(WidgetInfo^.UserData)^ := -1;
  end;

  IncreaseChangeStamp;

  ReAllocMem(FCachedItems, 0);
  FCachedCapacity := 0;
  FCachedSize := 0;
  Exclude(FStates, glsItemCacheNeedsUpdate);
  FCachedCount := 0;
  Exclude(FStates, glsCountNeedsUpdate);
end;

{------------------------------------------------------------------------------
  Method: TGtkListStoreStringList.Delete
  Params:
  Returns:

 ------------------------------------------------------------------------------}
procedure TGtkListStoreStringList.Delete(Index: Integer);
var
  ListItem: TGtkTreeIter;
  WidgetInfo: PWidgetInfo;
begin
  if not (glsItemCacheNeedsUpdate in FStates) then
    ListItem := FCachedItems[Index]
  else
    gtk_tree_model_iter_nth_child(FGtkListStore, @ListItem, nil, Index);

  //gtk_list_store_g
  WidgetInfo := GetWidgetInfo(Pointer(FOwner.Handle));
  //Lock the widget to avoid trigger events
  Inc(WidgetInfo^.ChangeLock);
  gtk_list_store_remove(FGtkListStore, @ListItem);
  Dec(WidgetInfo^.ChangeLock);
  IncreaseChangeStamp;

  if not (glsCountNeedsUpdate in FStates) then
    Dec(FCachedCount);
  if (not (glsItemCacheNeedsUpdate in FStates)) and (Index = Count) then
  begin
    // cache is valid and the last item was deleted -> just remove last item
    Dec(FCachedSize);
    if (FCachedSize < FCachedCapacity div 2) then
      ShrinkCache;
  end
  else
    Include(FStates, glsItemCacheNeedsUpdate);

  if FOwner is TCustomComboBox then
  begin
    TGtk2WSCustomComboBox.SetText(FOwner, '');
    //Update the internal Index cache
    PInteger(WidgetInfo^.UserData)^ := -1;
  end;
end;

function TGtkListStoreStringList.Find(const S: String; var Index: Integer): Boolean;
var
  L, R, I: Integer;
  CompareRes: Integer;
begin
  Result := False;
  // Use binary search.
  L := 0;
  R := Count - 1;
  while (L <= R) do
  begin
    I := L + (R - L) div 2;
    CompareRes := AnsiCompareText(S, Strings[I]);
    if (CompareRes > 0) then
      L := I + 1
    else
    begin
      R := I - 1;
      if (CompareRes = 0) then
      begin
        Result := True;
        L := I; // forces end of while loop
      end;
    end;
  end;
  Index := L;
end;

function TGtkListStoreStringList.IndexOf(const S: String): Integer;
begin
  BeginUpdate;
  if FSorted then
  begin
    //Binary Search
    if not Find(S, Result) then
      Result := -1;
  end else
    Result := inherited IndexOf(S);
  EndUpdate;
end;

{------------------------------------------------------------------------------
  Method: TGtkListStoreStringList.Insert
  Params:
  Returns:

 ------------------------------------------------------------------------------}
procedure TGtkListStoreStringList.Insert(Index: Integer; const S: String);
var
  li: TGtkTreeIter;
  LCLIndex: PInteger;
begin
  if (Index < 0) or (Index > Count)
  then begin
    RaiseGDBException('TGtkListStoreStringList.Insert: Index ' + IntToStr(Index) + ' out of bounds. Count=' + IntToStr(Count));
    Exit;
  end;

  if Owner = nil
  then begin
    RaiseGDBException('TGtkListStoreStringList.Insert Unspecified owner');
    Exit;
  end;

  BeginUpdate;
  try
    // this call is few times faster than gtk_list_store_insert, gtk_list_store_set
    gtk_list_store_insert_with_values(FGtkListStore, @li, Index, FColumnIndex, PChar(S), -1);
    IncreaseChangeStamp;

    //if the item is inserted before the selected item the
    //internal index cache becomes out of sync
    if (FOwner is TCustomComboBox) and FOwner.HandleAllocated then
    begin
      LCLIndex := PInteger(GetWidgetInfo(Pointer(FOwner.Handle))^.UserData);
      if Index <= LCLIndex^ then
        Inc(LCLIndex^);
    end;

    // ToDo: connect callbacks

    if not (glsCountNeedsUpdate in FStates) then
      Inc(FCachedCount);

    if (not (glsItemCacheNeedsUpdate in FStates)) and (Index = Count - 1) then
    begin
      // cache is valid and item was added as last
      // Add item to cache (instead of updating the whole cache)
      // This accelerates Assign.
      if FCachedSize = FCachedCapacity then GrowCache;
      FCachedItems[FCachedSize] := li;
      Inc(FCachedSize);
    end
    else
      Include(FStates, glsItemCacheNeedsUpdate);
  finally
    EndUpdate;
  end;
end;

{$I gtk2listsl.inc}

end.

