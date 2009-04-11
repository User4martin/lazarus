{ $Id$
 /***************************************************************************
                               checklst.pas
                               ------------

                   Initial Revision  : Thu Jun 19 CST 2003

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

unit CheckLst;

{$mode objfpc} {$H+}

interface

uses
  Classes, SysUtils, LCLProc, LCLType, GraphType, Graphics, LMessages,
  LResources, Controls, StdCtrls;
  

type
  TCheckListClicked = procedure(Sender: TObject; Index: integer) of object;

  { TCustomCheckListBox }

  TCustomCheckListBox = class(TCustomListBox)
  private
    FAllowGrayed: Boolean;
    FItemDataOffset: Integer;
    FOnClickCheck : TNotifyEvent;
    FOnItemClick: TCheckListClicked;
    function GetChecked(const AIndex: Integer): Boolean;
    function GetCount: integer;
    function GetItemEnabled(AIndex: Integer): Boolean;
    function GetState(AIndex: Integer): TCheckBoxState;
    procedure SetChecked(const AIndex: Integer; const AValue: Boolean);
    procedure SendItemState(const AIndex: Integer; const AState: TCheckBoxState);
    procedure SendItemEnabled(const AIndex: Integer; const AEnabled: Boolean);
    procedure DoChange(var Msg: TLMessage); message LM_CHANGED;
    procedure SetItemEnabled(AIndex: Integer; const AValue: Boolean);
    procedure SetState(AIndex: Integer; const AValue: TCheckBoxState);
  protected
    class procedure WSRegisterClass; override;
    procedure AssignItemDataToCache(const AIndex: Integer; const AData: Pointer); override;
    procedure AssignCacheToItemData(const AIndex: Integer; const AData: Pointer); override;
    function  GetCachedDataSize: Integer; override;
    procedure DefineProperties(Filer: TFiler); override;
    procedure ReadData(Stream: TStream);
    procedure WriteData(Stream: TStream);
    procedure ClickCheck; dynamic;
    procedure ItemClick(const AIndex: Integer); dynamic;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure FontChanged(Sender: TObject); override;
    procedure ParentFontChanged; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure MeasureItem(Index: Integer; var TheHeight: Integer); override;
    procedure Toggle(AIndex: Integer);
    
    property AllowGrayed: Boolean read FAllowGrayed write FAllowGrayed default False;
    property Checked[AIndex: Integer]: Boolean read GetChecked write SetChecked;
    property ItemEnabled[AIndex: Integer]: Boolean read GetItemEnabled write SetItemEnabled;
    property State[AIndex: Integer]: TCheckBoxState read GetState write SetState;
    property Count: integer read GetCount;
    property OnClickCheck: TNotifyEvent read FOnClickCheck write FOnClickCheck;
    property OnItemClick: TCheckListClicked read FOnItemClick write FOnItemClick;
  end;
  
  
  { TCheckListBox }
  
  TCheckListBox = class(TCustomCheckListBox)
  published
    property Align;
    property AllowGrayed;
    property Anchors;
    property BidiMode;
    property BorderSpacing;
    property BorderStyle;
    property Color;
    property Columns;
    property Constraints;
    property DragCursor;
    property DragMode;
    property ExtendedSelect;
    property Enabled;
    property Font;
    property IntegralHeight;
    property Items;
    property ItemHeight;
    property MultiSelect;
    property OnChangeBounds;
    property OnClick;
    property OnClickCheck;
    property OnContextPopup;
    property OnDblClick;
    property OnDrawItem;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnItemClick;
    property OnKeyPress;
    property OnKeyDown;
    property OnKeyUp;
    property OnMouseMove;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnResize;
    property OnShowHint;
    property OnStartDrag;
    property OnUTF8KeyPress;
    property ParentBidiMode;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Sorted;
    property Style;
    property TabOrder;
    property TabStop;
    property TopIndex;
    property Visible;
  end;


procedure Register;

implementation

uses
  WSCheckLst, WSFactory;

procedure Register;
begin
  RegisterComponents('Additional',[TCheckListBox]);
end;

type
  PCachedItemData = ^TCachedItemData;
  TCachedItemData = record
    State: TCheckBoxState;
    Enabled: Boolean;
  end;

{ TCustomCheckListBox }

procedure TCustomCheckListBox.AssignCacheToItemData(const AIndex: Integer;
  const AData: Pointer);
begin
  inherited AssignCacheToItemData(AIndex, AData);
  SendItemState(AIndex, PCachedItemData(AData + FItemDataOffset)^.State);
end;

procedure TCustomCheckListBox.AssignItemDataToCache(const AIndex: Integer;
  const AData: Pointer);
begin
  inherited AssignItemDataToCache(AIndex, AData);
  PCachedItemData(AData + FItemDataOffset)^.State := State[AIndex];
  PCachedItemData(AData + FItemDataOffset)^.Enabled := ItemEnabled[AIndex];
end;

constructor TCustomCheckListBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCompStyle := csCheckListBox;
  FItemDataOffset := inherited GetCachedDataSize;
end;

procedure TCustomCheckListBox.MeasureItem(Index: Integer; var TheHeight: Integer);
begin
  if (Style = lbStandard) then
    TheHeight := CalculateStandardItemHeight
  else
    inherited MeasureItem(Index, TheHeight);
end;

procedure TCustomCheckListBox.Toggle(AIndex: Integer);
const
  NextStateMap: array[TCheckBoxState] of array[Boolean] of TCheckBoxState =
  (
{cbUnchecked} (cbChecked, cbChecked),
{cbChecked  } (cbUnChecked, cbGrayed),
{cbGrayed   } (cbUnChecked, cbUnChecked)
  );
begin
  State[AIndex] := NextStateMap[State[AIndex]][AllowGrayed];
end;

procedure TCustomCheckListBox.DoChange(var Msg: TLMessage);
begin
  //DebugLn(['TCustomCheckListBox.DoChange ',DbgSName(Self),' ',Msg.WParam]);
  ClickCheck;
  ItemClick(Msg.WParam);
end;

function TCustomCheckListBox.GetCachedDataSize: Integer;
begin
  FItemDataOffset := inherited GetCachedDataSize;
  Result := FItemDataOffset + SizeOf(TCachedItemData);
end;

function TCustomCheckListBox.GetChecked(const AIndex: Integer): Boolean;
begin
  Result := State[AIndex] <> cbUnchecked;
end;

function TCustomCheckListBox.GetCount: integer;
begin
  Result := Items.Count;
end;

function TCustomCheckListBox.GetItemEnabled(AIndex: Integer): Boolean;
begin
  CheckIndex(AIndex);

  if HandleAllocated then
    Result := TWSCustomCheckListBoxClass(WidgetSetClass).GetItemEnabled(Self, AIndex)
  else
    Result := PCachedItemData(GetCachedData(AIndex) + FItemDataOffset)^.Enabled;
end;

function TCustomCheckListBox.GetState(AIndex: Integer): TCheckBoxState;
begin
  CheckIndex(AIndex);

  if HandleAllocated then
    Result := TWSCustomCheckListBoxClass(WidgetSetClass).GetState(Self, AIndex)
  else
    Result := PCachedItemData(GetCachedData(AIndex) + FItemDataOffset)^.State;
end;

procedure TCustomCheckListBox.KeyDown(var Key: Word; Shift: TShiftState);
var
  Index: Integer;
begin
  if (Key = VK_SPACE) and (Shift=[]) then
  begin
    Index := ItemIndex;
    Checked[Index] := not Checked[Index];
    ItemClick(Index);
    Key := VK_UNKNOWN;
  end else
    inherited KeyDown(Key,Shift);
end;

procedure TCustomCheckListBox.SetItemEnabled(AIndex: Integer;
  const AValue: Boolean);
begin
  CheckIndex(AIndex);

  if HandleAllocated then
    SendItemEnabled(AIndex, AValue)
  else
    PCachedItemData(GetCachedData(AIndex) + FItemDataOffset)^.Enabled := AValue;
end;

procedure TCustomCheckListBox.SetState(AIndex: Integer;
  const AValue: TCheckBoxState);
begin
  CheckIndex(AIndex);

  if HandleAllocated
  then SendItemState(AIndex, AValue)
  else PCachedItemData(GetCachedData(AIndex) + FItemDataOffset)^.State := AValue;
end;

class procedure TCustomCheckListBox.WSRegisterClass;
begin
  inherited WSRegisterClass;
  RegisterCustomCheckListBox;
end;

procedure TCustomCheckListBox.SendItemState(const AIndex: Integer;
  const AState: TCheckBoxState);
begin
  if HandleAllocated then
    TWSCustomCheckListBoxClass(WidgetSetClass).SetState(Self, AIndex, AState);
end;

procedure TCustomCheckListBox.SendItemEnabled(const AIndex: Integer;
  const AEnabled: Boolean);
begin
  if HandleAllocated then
    TWSCustomCheckListBoxClass(WidgetSetClass).SetItemEnabled(Self, AIndex, AEnabled);
end;

procedure TCustomCheckListBox.SetChecked(const AIndex: Integer;
  const AValue: Boolean);
begin
  if AValue then
    SetState(AIndex, cbChecked)
  else
    SetState(AIndex, cbUnChecked);
end;

procedure TCustomCheckListBox.ClickCheck;
begin
  if Assigned(FOnClickCheck) then FOnClickCheck(Self);
end;

procedure TCustomCheckListBox.ItemClick(const AIndex: Integer);
begin
  if Assigned(OnItemClick) then OnItemClick(Self, AIndex);
end;

procedure TCustomCheckListBox.FontChanged(Sender: TObject);
begin
  inherited FontChanged(Sender);
  if ([csLoading, csDestroying] * ComponentState = []) and (Style = lbStandard) then
    ItemHeight := CalculateStandardItemHeight;
end;

procedure TCustomCheckListBox.ParentFontChanged;
begin
  inherited ParentFontChanged;
  if ([csLoading, csDestroying] * ComponentState = []) and (Style = lbStandard) then
    ItemHeight := CalculateStandardItemHeight;
end;

procedure TCustomCheckListBox.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineBinaryProperty('Data', @ReadData, @WriteData, Items.Count > 0);
end;

procedure TCustomCheckListBox.ReadData(Stream: TStream);
var
  ChecksCount: integer;
  Checks: string;
  i: Integer;
begin
  ChecksCount := ReadLRSInteger(Stream);
  if ChecksCount > 0 then
  begin
    SetLength(Checks, ChecksCount);
    Stream.ReadBuffer(Checks[1], ChecksCount);
    for i := 0 to ChecksCount-1 do
      State[i] := TCheckBoxState(ord(Checks[i + 1]));
  end;
end;

procedure TCustomCheckListBox.WriteData(Stream: TStream);
var
  ChecksCount: integer;
  Checks: string;
  i: Integer;
begin
  ChecksCount := Items.Count;
  WriteLRSInteger(Stream, ChecksCount);
  if ChecksCount > 0 then
  begin
    SetLength(Checks, ChecksCount);
    for i := 0 to ChecksCount - 1 do
      Checks[i+1] := chr(Ord(State[i]));
    Stream.WriteBuffer(Checks[1], ChecksCount);
  end;
end;

end.
