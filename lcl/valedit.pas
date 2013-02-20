unit ValEdit;

{$mode objfpc}{$H+}

interface

uses
  Classes, Controls, StdCtrls, SysUtils, Grids, LResources, Dialogs, LazUtf8, variants, LCLProc,
  ContNrs;

type

  TValueListEditor = class;    // Forward declaration
  TValueListStrings = class;

  TEditStyle = (esSimple, esEllipsis, esPickList);

  { TItemProp }

  TItemProp = class(TPersistent)
  private
    FGrid: TValueListEditor;
    FEditMask: string;
    FEditStyle: TEditStyle;
    FPickList: TStrings;
    FMaxLength: Integer;
    FReadOnly: Boolean;
    FKeyDesc: string;
    function GetPickList: TStrings;
    procedure PickListChange(Sender: TObject);
    procedure SetEditMask(const AValue: string);
    procedure SetMaxLength(const AValue: Integer);
    procedure SetReadOnly(const AValue: Boolean);
    procedure SetEditStyle(const AValue: TEditStyle);
    procedure SetPickList(const AValue: TStrings);
    procedure SetKeyDesc(const AValue: string);
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create(AOwner: TValueListEditor);
    destructor Destroy; override;
//    function HasPickList: Boolean;
  published
    property EditMask: string read FEditMask write SetEditMask;
    property EditStyle: TEditStyle read FEditStyle write SetEditStyle;
    property KeyDesc: string read FKeyDesc write SetKeyDesc;
    property PickList: TStrings read GetPickList write SetPickList;
    property MaxLength: Integer read FMaxLength write SetMaxLength;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly;
  end;

  { TItemPropList }

  TItemPropList = class
  private
    FList: TFPObjectList;
    FStrings: TValueListStrings;
    function GetCount: Integer;
    function GetItem(Index: Integer): TItemProp;
    procedure SetItem(Index: Integer; AValue: TItemProp);
  protected
  public
    procedure Add(AValue: TItemProp);
    procedure Assign(Source: TItemPropList);
    procedure Clear;
    procedure Delete(Index: Integer);
    procedure Exchange(Index1, Index2: Integer);
    procedure Insert(Index: Integer; AValue: TItemProp);
  public
    constructor Create(AOwner: TValueListStrings);
    destructor Destroy; override;
  public
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TItemProp read GetItem write SetItem; default;
  end;

  { TValueListStrings }

  TValueListStrings = class(TStringList)
  private
    FGrid: TValueListEditor;
    FItemProps: TItemPropList;
    function GetItemProp(const AKeyOrIndex: Variant): TItemProp;
    procedure QuickSortStringsAndItemProps(L, R: Integer; CompareFn: TStringListSortCompare);
  protected
    procedure InsertItem(Index: Integer; const S: string; AObject: TObject); override;
    procedure InsertItem(Index: Integer; const S: string); override;
    procedure Put(Index: Integer; const S: String); override;
  public
    constructor Create(AOwner: TValueListEditor);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure Clear; override;
    procedure CustomSort(Compare: TStringListSortCompare); override;
    procedure Delete(Index: Integer); override;
    procedure Exchange(Index1, Index2: Integer); override;
  end;


  TDisplayOption = (doColumnTitles, doAutoColResize, doKeyColFixed);
  TDisplayOptions = set of TDisplayOption;

  TKeyOption = (keyEdit, keyAdd, keyDelete, keyUnique);
  TKeyOptions = set of TKeyOption;

  TGetPickListEvent = procedure(Sender: TObject; const KeyName: string;
    Values: TStrings) of object;

  TOnValidateEvent = procedure(Sender: TObject; ACol, ARow: Longint;
    const KeyName, KeyValue: string) of object;

  { TValueListEditor }

  TValueListEditor = class(TCustomStringGrid)
  private
    FTitleCaptions: TStrings;
    FStrings: TValueListStrings;
    FKeyOptions: TKeyOptions;
    FDisplayOptions: TDisplayOptions;
    FDropDownRows: Integer;
    FOnGetPickList: TGetPickListEvent;
    FOnStringsChange: TNotifyEvent;
    FOnStringsChanging: TNotifyEvent;
    FOnValidate: TOnValidateEvent;
    function GetFixedRows: Integer;
    function GetItemProp(const AKeyOrIndex: Variant): TItemProp;
    procedure SetFixedRows(AValue: Integer);
    procedure SetItemProp(const AKeyOrIndex: Variant; AValue: TItemProp);
    procedure StringsChange(Sender: TObject);
    procedure StringsChanging(Sender: TObject);
    function GetOptions: TGridOptions;
    function GetKey(Index: Integer): string;
    function GetValue(const Key: string): string;
    procedure SetDisplayOptions(const AValue: TDisplayOptions);
    procedure SetDropDownRows(const AValue: Integer);
    procedure SetKeyOptions({const} AValue: TKeyOptions);
    procedure SetKey(Index: Integer; const Value: string);
    procedure SetValue(const Key: string; AValue: string);
    procedure SetOptions(const AValue: TGridOptions);
    procedure SetStrings(const AValue: TValueListStrings);
    procedure SetTitleCaptions(const AValue: TStrings);
  protected
    class procedure WSRegisterClass; override;
    procedure DoOnResize; override;
    procedure SetFixedCols(const AValue: Integer); override;
    procedure ShowColumnTitles;
    procedure AdjustColumnWidths; virtual;
    procedure AdjustRowCount; virtual;
    procedure ColWidthsChanged; override;
    procedure DefineCellsProperty(Filer: TFiler); override;
    function GetEditText(ACol, ARow: Integer): string; override;
    function GetCells(ACol, ARow: Integer): string; override;
    procedure SelectEditor; override;
    procedure SetCells(ACol, ARow: Integer; const AValue: string); override;
    procedure SetEditText(ACol, ARow: Longint; const Value: string); override;
    procedure TitlesChanged(Sender: TObject);
    function ValidateEntry(const ACol,ARow:Integer; const OldValue:string; var NewValue:string): boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function InsertRow(const KeyName, Value: string; Append: Boolean): Integer;
    property FixedRows: Integer read GetFixedRows write SetFixedRows default 1;
    property Modified;
    property Keys[Index: Integer]: string read GetKey write SetKey;
    property Values[const Key: string]: string read GetValue write SetValue;
    property ItemProps[const AKeyOrIndex: Variant]: TItemProp read GetItemProp write SetItemProp;
  published
    // Same as in TStringGrid
    property Align;
    property AlternateColor;
    property Anchors;
    property AutoAdvance;
    property AutoEdit;
    property AutoFillColumns;
    property BiDiMode;
    property BorderSpacing;
    property BorderStyle;
    property Color;
    property Constraints;
    property DefaultColWidth;
    property DefaultDrawing;
    property DefaultRowHeight;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property ExtendedSelect;
    property FixedColor;
    property FixedCols;
    property Flat;
    property Font;
    property GridLineWidth;
    property HeaderHotZones;
    property HeaderPushZones;
    property MouseWheelOption;
    property ParentBiDiMode;
    property ParentColor default false;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property RowCount;
    property ScrollBars;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property TitleFont;
    property TitleImageList;
    property TitleStyle;
    property UseXORFeatures;
    property Visible;
    property VisibleColCount;
    property VisibleRowCount;

    property OnBeforeSelection;
    property OnChangeBounds;
    property OnCheckboxToggled;
    property OnClick;
    property OnColRowDeleted;
    property OnColRowExchanged;
    property OnColRowInserted;
    property OnColRowMoved;
    property OnCompareCells;
    property OnContextPopup;
    property OnDragDrop;
    property OnDragOver;
    property OnDblClick;
    property OnDrawCell;
    property OnEditingDone;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetEditMask;
    property OnGetEditText;
    property OnHeaderClick;
    property OnHeaderSized;
    property OnHeaderSizing;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnPickListSelect;
    property OnPrepareCanvas;
    property OnResize;
    property OnSelectEditor;
    property OnSelection;
    property OnSelectCell;
    property OnSetEditText;
    property OnShowHint;
    property OnStartDock;
    property OnStartDrag;
    property OnTopLeftChanged;
    property OnUserCheckboxBitmap;
    property OnUTF8KeyPress;
    property OnValidateEntry;

    // Compatible with Delphi TValueListEditor:
    property DisplayOptions: TDisplayOptions read FDisplayOptions
      write SetDisplayOptions default [doColumnTitles, doAutoColResize, doKeyColFixed];
    property DoubleBuffered;
    property DropDownRows: Integer read FDropDownRows write SetDropDownRows default 8;
    property KeyOptions: TKeyOptions read FKeyOptions write SetKeyOptions default [];
    property Options: TGridOptions read GetOptions write SetOptions default
     [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing,
      goEditing, goAlwaysShowEditor, goThumbTracking];
    property Strings: TValueListStrings read FStrings write SetStrings;
    property TitleCaptions: TStrings read FTitleCaptions write SetTitleCaptions;

    property OnGetPickList: TGetPickListEvent read FOnGetPickList write FOnGetPickList;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnStringsChange: TNotifyEvent read FOnStringsChange write FOnStringsChange;
    property OnStringsChanging: TNotifyEvent read FOnStringsChanging write FOnStringsChanging;
    property OnValidate: TOnValidateEvent read FOnValidate write FOnValidate;

  end;

const
  //ToDo: Make this a resourcestring in lclstrconsts unit, once we are satisfied with the implementation of validating
  rsVLEDuplicateKey = 'Duplicate Key:'+LineEnding+'A key with name "%s" already exists at column %d';
  //ToDo: Make this a resourcestring in lclstrconsts unit, once we are satisfied with ShowColumnTitles
  rsVLEKey = 'Key';
  rsVLEName = 'Name';

procedure Register;

implementation

{ TItemProp }


constructor TItemProp.Create(AOwner: TValueListEditor);
begin
  inherited Create;
  FGrid := AOwner;
end;

destructor TItemProp.Destroy;
begin
  FPickList.Free;
  inherited Destroy;
end;

function TItemProp.GetPickList: TStrings;
begin
  if FPickList = Nil then
  begin
    FPickList := TStringList.Create;
    TStringList(FPickList).OnChange := @PickListChange;
  end;
  Result := FPickList;
end;

procedure TItemProp.PickListChange(Sender: TObject);
begin
  if PickList.Count > 0 then begin
    if EditStyle = esSimple then
      EditStyle := esPickList;
  end
  else begin
    if EditStyle = esPickList then
      EditStyle := esSimple;
  end;
end;

procedure TItemProp.SetEditMask(const AValue: string);
begin
  FEditMask := AValue;
  with FGrid do
    if EditorMode and (FStrings.UpdateCount = 0) then
      InvalidateCell(Col, Row);
end;

procedure TItemProp.SetMaxLength(const AValue: Integer);
begin
  FMaxLength := AValue;
  with FGrid do
    if EditorMode and (FStrings.UpdateCount = 0) then
      InvalidateCell(Col, Row);
end;

procedure TItemProp.SetReadOnly(const AValue: Boolean);
begin
  FReadOnly := AValue;
  with FGrid do
    if EditorMode and (FStrings.UpdateCount = 0) then
      InvalidateCell(Col, Row);
end;

procedure TItemProp.SetEditStyle(const AValue: TEditStyle);
begin
  FEditStyle := AValue;
  with FGrid do
    if EditorMode and (FStrings.UpdateCount = 0) then
      InvalidateCell(Col, Row);
end;

procedure TItemProp.SetPickList(const AValue: TStrings);
begin
  GetPickList.Assign(AValue);
  with FGrid do
    if EditorMode and (FStrings.UpdateCount = 0) then
      InvalidateCell(Col, Row);
end;

procedure TItemProp.SetKeyDesc(const AValue: string);
begin
  FKeyDesc := AValue;
end;

procedure TItemProp.AssignTo(Dest: TPersistent);
begin
  if not (Dest is TItemProp) then
    inherited AssignTo(Dest)
  else
  begin
    TItemProp(Dest).EditMask := Self.EditMask;
    TItemProp(Dest).EditStyle := Self.EditStyle;
    TItemProp(Dest).EditStyle := Self.EditStyle;
    TItemProp(Dest).KeyDesc := Self.KeyDesc;
    TItemProp(Dest).PickList.Assign(Self.PickList);
    TItemProp(Dest).MaxLength := Self.MaxLength;
    TItemProp(Dest).ReadOnly := Self.ReadOnly;
  end;
end;


{ TItemPropList }

function TItemPropList.GetItem(Index: Integer): TItemProp;
begin
  Result := TItemProp(FList.Items[Index]);
end;

function TItemPropList.GetCount: Integer;
begin
  Result := FList.Count;
end;

procedure TItemPropList.SetItem(Index: Integer; AValue: TItemProp);
begin
  FList.Items[Index] := AValue;
end;

procedure TItemPropList.Insert(Index: Integer; AValue: TItemProp);
begin
  FList.Insert(Index, AValue);
end;

procedure TItemPropList.Add(AValue: TItemProp);
begin
  FList.Add(AValue);
end;

procedure TItemPropList.Assign(Source: TItemPropList);
var
  Index: Integer;
  Prop: TItemProp;
begin
  Clear;
  if not Assigned(Source) then Exit;
  for Index := 0 to Source.Count - 1 do
  begin
    Prop := TItemProp.Create(FStrings.FGrid);
    Prop.Assign(Source.Items[Index]);
    Add(Prop);
  end;
end;

procedure TItemPropList.Delete(Index: Integer);
begin
  FList.Delete(Index);
end;

procedure TItemPropList.Exchange(Index1, Index2: Integer);
begin
  FList.Exchange(Index1, index2);
end;

procedure TItemPropList.Clear;
begin
  FList.Clear;
end;

constructor TItemPropList.Create(AOwner: TValueListStrings);
begin
  FStrings := AOwner;
  FList := TFPObjectList.Create(True);
end;

destructor TItemPropList.Destroy;
begin
  FList.Free;
  inherited Destroy;
end;



{ TValueListStrings }


procedure TValueListStrings.InsertItem(Index: Integer; const S: string; AObject: TObject);
var
  i: Integer;
  IsShowingEditor: Boolean;
begin
  // ToDo: Check validity of key
  //debugln('TValueListStrings.InsertItem: Index=',dbgs(index),' S=',S,' AObject=',dbgs(aobject));
  IsShowingEditor := goAlwaysShowEditor in FGrid.Options;
  if IsShowingEditor then FGrid.Options := FGrid.Options - [goAlwaysShowEditor];
  inherited InsertItem(Index, S, AObject);
  FItemProps.Insert(Index, TItemProp.Create(FGrid));
  //only restore this _after_ FItemProps is updated!
  if IsShowingEditor then FGrid.Options := FGrid.Options + [goAlwaysShowEditor];
end;

procedure TValueListStrings.InsertItem(Index: Integer; const S: string);
begin
  InsertItem(Index, S, nil);
end;

procedure TValueListStrings.Put(Index: Integer; const S: String);
var
  IndexToRow: Integer;
  MustHideShowingEditor: Boolean;
begin
  // ToDo: Check validity of key
  IndexToRow := Index + FGrid.FixedRows;
  MustHideShowingEditor := (goAlwaysShowEditor in FGrid.Options) and
                           FGrid.Editor.Visible and
                           (IndexToRow = FGrid.Row) and
                           //if editor is Focussed, we are editing a cell, so we cannot hide!
                           (not FGrid.Editor.Focused);
  //debugln('TValueListStrings.Put: MustHideShowingEditor=',DbgS(MustHideShowingEditor));
  if MustHideShowingEditor then FGrid.Options := FGrid.Options - [goAlwaysShowEditor];
  inherited Put(Index, S);
  if MustHideShowingEditor then FGrid.Options := FGrid.Options + [goAlwaysShowEditor];
end;

constructor TValueListStrings.Create(AOwner: TValueListEditor);
begin
  inherited Create;
  FGrid := AOwner;
  FItemProps := TItemPropList.Create(Self);
end;

destructor TValueListStrings.Destroy;
begin
  FItemProps.Free;
  inherited Destroy;
end;

procedure TValueListStrings.Assign(Source: TPersistent);
begin
  inherited Assign(Source);
  if (Source is TValueListStrings) then
    FItemProps.Assign(TValueListStrings(Source).FItemProps);
end;

procedure TValueListStrings.Clear;
var
  IsShowingEditor: Boolean;
begin
  IsShowingEditor := goAlwaysShowEditor in FGrid.Options;
  if IsShowingEditor then FGrid.Options := FGrid.Options - [goAlwaysShowEditor];
  inherited Clear;
  FItemProps.Clear;
  if IsShowingEditor then FGrid.Options := FGrid.Options + [goAlwaysShowEditor];
end;


{
 Duplicates the functionality of TStringList.QuickSort, but also
 sorts the ItemProps.
}
procedure TValueListStrings.QuickSortStringsAndItemProps(L, R: Integer;
  CompareFn: TStringListSortCompare);
var
  Pivot, vL, vR: Integer;
begin
  if R - L <= 1 then
  begin // a little bit of time saver
    if L < R then
      if CompareFn(Self, L, R) > 0 then
        //Exchange also exchanges FItemProps
        Exchange(L, R);
    Exit;
  end;

  vL := L;
  vR := R;

  Pivot := L + Random(R - L); // they say random is best

  while vL < vR do
  begin
    while (vL < Pivot) and (CompareFn(Self, vL, Pivot) <= 0) do
      Inc(vL);

    while (vR > Pivot) and (CompareFn(Self, vR, Pivot) > 0) do
      Dec(vR);
    //Exchange also exchanges FItemProps
    Exchange(vL, vR);

    if Pivot = vL then // swap pivot if we just hit it from one side
      Pivot := vR
    else if Pivot = vR then
      Pivot := vL;
  end;

  if Pivot - 1 >= L then
    QuickSortStringsAndItemProps(L, Pivot - 1, CompareFn);
  if Pivot + 1 <= R then
    QuickSortStringsAndItemProps(Pivot + 1, R, CompareFn);
end;

procedure TValueListStrings.CustomSort(Compare: TStringListSortCompare);
{
 Re-implement it, because we need it to call our own QuickSortStringsAndItemProps
 and so we cannot use inherited CustomSort
 Use BeginUpdate/EndUpdate to avoid numerous Changing/Changed calls
}
begin
  If not Sorted and (Count>1) then
  begin
    try
      BeginUpdate;
      QuickSortStringsAndItemProps(0,Count-1, Compare);
    finally
      EndUpdate;
    end;
  end;
end;

procedure TValueListStrings.Delete(Index: Integer);
var
  i: Integer;
  IsShowingEditor: Boolean;
begin
  IsShowingEditor := goAlwaysShowEditor in FGrid.Options;
  if IsShowingEditor then FGrid.Options := FGrid.Options - [goAlwaysShowEditor];
  inherited Delete(Index);
  // Delete also ItemProps
  FItemProps.Delete(Index);
  //only restore this _after_ FItemProps is updated!
  if IsShowingEditor then FGrid.Options := FGrid.Options + [goAlwaysShowEditor];
end;

procedure TValueListStrings.Exchange(Index1, Index2: Integer);
var
  IndexToRow1, IndexToRow2: Integer;
  MustHideShowingEditor: Boolean;
begin
  IndexToRow1 := Index1 + FGrid.FixedRows;
  IndexToRow2 := Index2 + FGrid.FixedRows;
  MustHideShowingEditor := (goAlwaysShowEditor in FGrid.Options) and
                           FGrid.Editor.Visible and
                           ((IndexToRow1 = FGrid.Row) or (IndexToRow2 = FGrid.Row));
  if MustHideShowingEditor then FGrid.Options := FGrid.Options - [goAlwaysShowEditor];
  inherited Exchange(Index1, Index2);
  FItemProps.Exchange(Index1, Index2);
  if MustHideShowingEditor then FGrid.Options := FGrid.Options + [goAlwaysShowEditor];
end;

function TValueListStrings.GetItemProp(const AKeyOrIndex: Variant): TItemProp;
var
  i: Integer;
  s: string;

begin
  Result := Nil;
  if (Count > 0) and (UpdateCount = 0) then
  begin
    if VarIsOrdinal(AKeyOrIndex) then
      i := AKeyOrIndex
    else begin
      s := AKeyOrIndex;
      i := IndexOfName(s);
      if i = -1 then
        raise Exception.Create('TValueListStrings.GetItemProp: Key not found: '+s);
    end;
    Result := FItemProps.Items[i];
    if not Assigned(Result) then
      Raise Exception.Create(Format('TValueListStrings.GetItemProp: Index=%d Result=Nil',[i]));
  end;
end;



{ TValueListEditor }

constructor TValueListEditor.Create(AOwner: TComponent);
begin
  //need FStrings before inherited Create, because they are needed in overridden SelectEditor
  FStrings := TValueListStrings.Create(Self);
  FTitleCaptions := TStringList.Create;
  inherited Create(AOwner);
  FStrings.OnChange := @StringsChange;
  FStrings.OnChanging := @StringsChanging;
  TStringList(FTitleCaptions).OnChange := @TitlesChanged;

  //Don't use Columns.Add, it interferes with setting FixedCols := 1 (it will then insert an extra column)
  {
  with Columns.Add do
    Title.Caption := 'Key';
  with Columns.Add do begin
    Title.Caption := 'Value';
    DropDownRows := 8;
  end;
  }

  ColCount:=2;
  inherited RowCount := 2;
  FixedCols := 0;
//  DefaultColWidth := 150;
//  DefaultRowHeight := 18;
//  Width := 306;
//  Height := 300;
  Options := [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine,
              goColSizing, goEditing, goAlwaysShowEditor, goThumbTracking];
  FDisplayOptions := [doColumnTitles, doAutoColResize, doKeyColFixed];
  Col := 1;
  FDropDownRows := 8;
  ShowColumnTitles;
end;

destructor TValueListEditor.Destroy;
begin
  FTitleCaptions.Free;
  FStrings.Free;
  inherited Destroy;
end;

function TValueListEditor.InsertRow(const KeyName, Value: string; Append: Boolean): Integer;
var
  NewInd: Integer;
begin
  Result := Row;
  if (Row > Strings.Count) or ((Row - FixedRows) >= Strings.Count)
  or (Cells[0, Row] <> '') or (Cells[1, Row] <> '') then
  begin                                    // Add a new Key=Value pair
    Strings.BeginUpdate;
    try
      if Append then
        NewInd := Strings.Count
      else
        NewInd := Result - FixedRows;
      Strings.InsertItem(NewInd, KeyName+'='+Value, Nil);
    finally
      Strings.EndUpdate;
    end;
  end
  else begin   // Use an existing row, just update the Key and Value.
    Cells[0, Result] := KeyName;
    Cells[1, Result] := Value;
  end;
end;

procedure TValueListEditor.StringsChange(Sender: TObject);
begin
  //Since we never call inherited SetCell, this seems the logical place to do it
  Modified := True;
  AdjustRowCount;
  Invalidate;
  if Assigned(OnStringsChange) then
    OnStringsChange(Self);
end;

procedure TValueListEditor.StringsChanging(Sender: TObject);
begin
  if Assigned(OnStringsChanging) then
    OnStringsChanging(Self);
end;



function TValueListEditor.GetFixedRows: Integer;
begin
  Result := inherited FixedRows;
end;

procedure TValueListEditor.SetFixedCols(const AValue: Integer);
begin
  if (AValue in [0,1]) then
    inherited SetFixedCols(AValue);
end;

procedure TValueListEditor.SetFixedRows(AValue: Integer);
begin
  if AValue in [0,1] then begin  // No other values are allowed
    if AValue = 0 then           // Typically DisplayOptions are changed directly
      DisplayOptions := DisplayOptions - [doColumnTitles]
    else
      DisplayOptions := DisplayOptions + [doColumnTitles]
  end;
end;

function TValueListEditor.GetItemProp(const AKeyOrIndex: Variant): TItemProp;
begin
  Result := FStrings.GetItemProp(AKeyOrIndex);
end;

procedure TValueListEditor.SetItemProp(const AKeyOrIndex: Variant; AValue: TItemProp);
begin
  FStrings.GetItemProp(AKeyOrIndex).Assign(AValue);
end;

function TValueListEditor.GetOptions: TGridOptions;
begin
  Result := inherited Options;
end;

procedure TValueListEditor.SetDisplayOptions(const AValue: TDisplayOptions);
// Set number of fixed rows to 1 if titles are shown (based on DisplayOptions).
// Set the local options value, then Adjust Column Widths and Refresh the display.
begin
  if (doColumnTitles in DisplayOptions) <> (doColumnTitles in AValue) then
    if doColumnTitles in AValue then begin
      if RowCount < 2 then
        inherited RowCount := 2;
      inherited FixedRows := 1;
    end else
      inherited FixedRows := 0;
  FDisplayOptions := AValue;
  ShowColumnTitles;
  AdjustColumnWidths;
  AdjustRowCount;
  Invalidate;
end;

procedure TValueListEditor.SetDropDownRows(const AValue: Integer);
begin
  FDropDownRows := AValue;
  // ToDo: If edit list for inplace editing is implemented, set its handler, too.
end;

procedure TValueListEditor.SetKeyOptions({const} AValue: TKeyOptions);
begin
  // ToDo: Disable Add or enable Edit based on current value.
  // Enable Edit when Adding, disable Add when Editing.
  // Change Col if needed when editing keys is disabled.
  FKeyOptions := AValue;
end;


procedure TValueListEditor.SetOptions(const AValue: TGridOptions);
begin
  if not (goColMoving in AValue) then
    inherited Options := AValue
  else
    inherited Options := AValue - [goColMoving];
end;

procedure TValueListEditor.SetStrings(const AValue: TValueListStrings);
begin
  FStrings.Assign(AValue);
end;

procedure TValueListEditor.SetTitleCaptions(const AValue: TStrings);
begin
  FTitleCaptions.Assign(AValue);
end;

function TValueListEditor.GetKey(Index: Integer): string;
begin
  Result:=Cells[0,Index];
end;

procedure TValueListEditor.SetKey(Index: Integer; const Value: string);
begin
  Cells[0,Index]:=Value;
end;

function TValueListEditor.GetValue(const Key: string): string;
var
  I: Integer;
begin
  Result := '';
  I := Strings.IndexOfName(Key);
  if I > -1 then begin
    Inc(I, FixedRows);
    Result:=Cells[1,I];
  end;
end;

procedure TValueListEditor.SetValue(const Key: string; AValue: string);
var
  I: Integer;
begin
  I := Strings.IndexOfName(Key);
  if I > -1 then begin
    Inc(I, FixedRows);
    Cells[1,I]:=AValue;
  end
  else
    Strings.Add(Key+'='+AValue);
end;

procedure TValueListEditor.ShowColumnTitles;
var
  KeyCap, ValCap: String;
begin
  if (doColumnTitles in DisplayOptions) then
  begin
    KeyCap := rsVLEKey;
    ValCap := rsVLEName;
    if (TitleCaptions.Count > 0) then KeyCap := TitleCaptions[0];
    if (TitleCaptions.Count > 1) then ValCap := TitleCaptions[1];
    //Columns[0].Title.Caption := KeyCap;
    //Columns[1].Title.Caption := ValCap;
    //or:
    Cells[0,0] := KeyCap;
    Cells[1,0] := ValCap;
  end;
end;

procedure TValueListEditor.AdjustColumnWidths;
// If key column is fixed in width then adjust only the second column,
//  otherwise adjust both columns propertionally.
var
  CW: Integer;
begin
  CW := ClientWidth;
  if  (doKeyColFixed in DisplayOptions) then
  begin
    //AutoSizeColumn(0);
    ColWidths[1] := CW - ColWidths[0];
  end
  else
  begin
    ColWidths[0] := CW div 2;
    ColWidths[1] := CW div 2;
  end;
end;

procedure TValueListEditor.AdjustRowCount;
// Change the number of rows based on the number of items in Strings collection.
// Sets Row and RowCount of parent TCustomDrawGrid class.
var
  NewC: Integer;
begin
  NewC:=FixedRows+1;
  if Strings.Count>0 then
    NewC:=Strings.Count+FixedRows;
  if NewC<>RowCount then
  begin
    if NewC<Row then
      Row:=NewC-1;
    if Row = 0 then
      if doColumnTitles in DisplayOptions then
        Row:=1;
    inherited RowCount:=NewC;
  end;
end;

procedure TValueListEditor.ColWidthsChanged;
begin
  AdjustColumnWidths;
  inherited;
end;

procedure TValueListEditor.DefineCellsProperty(Filer: TFiler);
begin
end;

function TValueListEditor.GetCells(ACol, ARow: Integer): string;
var
  I: Integer;
begin
  Result:='';
  if (ARow=0) and (doColumnTitles in DisplayOptions) then
  begin
    Result := Inherited GetCells(ACol, ARow);
  end
  else
  begin
    I:=ARow-FixedRows;
    if Strings.Count<=I then exit;
    if ACol=0 then
      Result:=Strings.Names[I]
    else if ACol=1 then
      Result:=Strings.ValueFromIndex[I];
  end;
end;

procedure TValueListEditor.SelectEditor;
var
  ItemProp: TItemProp;
begin
  inherited SelectEditor;
  if Col <> 1 then Exit;     // Only for the Value column
  ItemProp := nil;
  //debugln('**** A Col=',dbgs(col),' Row=',dbgs(row),' (',dbgs(itemprop),')');
  ItemProp := Strings.GetItemProp(Row-FixedRows);
  if Assigned(ItemProp) then
    case ItemProp.EditStyle of
      esSimple: Editor := EditorByStyle(cbsAuto);
      esEllipsis: Editor := EditorByStyle(cbsEllipsis);
      esPickList: begin
        Editor := EditorByStyle(cbsPickList);
        (Editor as TCustomComboBox).Items.Assign(ItemProp.PickList);
        //Style := csDropDown, default = csDropDownList;
      end;
    end;
end;

procedure TValueListEditor.SetCells(ACol, ARow: Integer; const AValue: string);
var
  I: Integer;
  Key, KeyValue, Line: string;
begin
  if (ARow = 0) and (doColumnTitles in DisplayOptions) then
  begin
    Inherited SetCells(ACol, ARow, AValue);
  end
  else
  begin
    I:=ARow-FixedRows;
    if ACol=0 then
    begin
      Key := AValue;
      KeyValue := Cells[1,ARow]
    end
    else
    begin
      KeyValue := AValue;
      Key := Cells[0,ARow];
    end;
    //If cells are empty don't store '=' in Strings
    if (Key = '') and (KeyValue = '') then
      Line := ''
    else
      Line := Key + '=' + KeyValue;
    // Empty grid: don't add a the line '' to Strings!
    if (Strings.Count = 0) and (Line = '') then Exit;
    if I>=Strings.Count then
      Strings.Insert(I,Line)
    else
      if (Line <> Strings[I]) then Strings[I]:=Line;
  end;
end;

function TValueListEditor.GetEditText(ACol, ARow: Integer): string;
begin
  Result:= Cells[ACol, ARow];
  if Assigned(OnGetEditText) then
    OnGetEditText(Self, ACol, ARow, Result);
end;

procedure TValueListEditor.SetEditText(ACol, ARow: Longint; const Value: string);
begin
  inherited SetEditText(ACol, ARow, Value);
  Cells[ACol, ARow] := Value;
end;

procedure TValueListEditor.TitlesChanged(Sender: TObject);
begin
  // Refresh the display.
  ShowColumnTitles;
  AdjustRowCount;
  Invalidate;
end;

function TValueListEditor.ValidateEntry(const ACol, ARow: Integer;
  const OldValue: string; var NewValue: string): boolean;
var
  Index, i: Integer;
begin
  Result := inherited ValidateEntry(ACol, ARow, OldValue, NewValue);
  if ((ACol - FixedCols) = 0) then
  begin//Check for duplicate key names (only in "Key" column)
    Index := ARow - FixedRows;
    for i := 0 to FStrings.Count - 1 do
    begin
      if (Index <> i) and (FStrings.Names[i] <> '') then
      begin
        if (Utf8CompareText(FStrings.Names[i], NewValue) = 0) then
        begin
          Result := False;
          ShowMessage(Format(rsVLEDuplicateKey,[NewValue, i + FixedRows]));
          if Editor is TStringCellEditor then TStringCelleditor(Editor).SelectAll;
        end;
      end;
    end;
  end;
end;

class procedure TValueListEditor.WSRegisterClass;
begin
//  RegisterPropertyToSkip(Self, 'SomeProperty', 'VCL compatibility property', '');
  inherited WSRegisterClass;
end;

procedure TValueListEditor.DoOnResize;
begin
  inherited DoOnResize;
  if (doAutoColResize in DisplayOptions) then AdjustColumnWidths;
end;


procedure Register;
begin
  RegisterComponents('Additional',[TValueListEditor]);
end;


end.

