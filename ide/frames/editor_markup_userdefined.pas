unit editor_markup_userdefined;

{$mode objfpc}{$H+}

interface

uses
  Classes, StdCtrls, ComCtrls, Graphics, sysutils, math, EditorOptions,
  LazarusIDEStrConsts, SynColorAttribEditor, KeyMapping, KeyMapShortCutDlg,
  IDEOptionsIntf, IDECommands, IDEDialogs, Spin, ExtCtrls, SynEditMarkupBracket,
  editor_color_options, editor_general_options, editor_keymapping_options,
  SynEdit, SynCompletion, SynHighlighterPas, SynEditKeyCmds,
  SynEditMarkupHighAll, DividerBevel, LazLoggerBase, LCLType, Menus, Grids,
  Controls, Dialogs, Buttons;

type

  { TColorStringGrid }

  TColorStringGrid = class(TStringGrid)
  private
    FRowFontColor: Array of TColor;
    function GetRowFontColor(AIndex: Integer): TColor;
    procedure SetRowFontColor(AIndex: Integer; AValue: TColor);
  protected
    procedure PrepareCanvas(aCol, aRow: Integer; aState: TGridDrawState); override;
    procedure ColRowDeleted(IsColumn: Boolean; index: Integer); override;
    procedure ColRowInserted(IsColumn: boolean; index: integer); override;
    // no exchanged or move
    procedure SizeChanged(OldColCount, OldRowCount: Integer); override;
  public
    property RowFontColor[AIndex: Integer]: TColor read GetRowFontColor write SetRowFontColor;
  end;

  { TEditorMarkupUserDefinedFrame }

  TEditorMarkupUserDefinedFrame = class(TAbstractIDEOptionsEditor)
    cbCaseSense: TCheckBox;
    cbMatchEndBound: TCheckBox;
    cbMatchStartBound: TCheckBox;
    cbKeyCase: TCheckBox;
    cbKeyBoundStart: TCheckBox;
    cbKeyBoundEnd: TCheckBox;
    cbSmartSelectBound: TCheckBox;
    cbGlobalList: TCheckBox;
    divKeyAdd: TDividerBevel;
    divKeyRemove: TDividerBevel;
    divKeyToggle: TDividerBevel;
    edListName: TEdit;
    HCenter: TLabel;
    lbWordMin: TLabel;
    lbSelectMin: TLabel;
    HQuarter: TLabel;
    lbKeyBoundMinLen: TLabel;
    lbNewKeyOptions: TLabel;
    HCenterKey: TLabel;
    lbKeyAdd1: TLabel;
    lbKeyAdd2: TLabel;
    lbKeyRemove1: TLabel;
    lbKeyRemove2: TLabel;
    lbKeyToggle1: TLabel;
    lbKeyToggle2: TLabel;
    lbListName: TLabel;
    ListMenu: TPopupMenu;
    MainPanel: TPanel;
    Notebook1: TNotebook;
    PageMain: TPage;
    PageKeys: TPage;
    Panel1: TPanel;
    btnKeyAdd: TSpeedButton;
    btnKeyRemove: TSpeedButton;
    btnKeyToggle: TSpeedButton;
    edWordMin: TSpinEdit;
    edSelectMin: TSpinEdit;
    SynColorAttrEditor1: TSynColorAttrEditor;
    ToolBar1: TToolBar;
    tbSelectList: TToolButton;
    tbNewList: TToolButton;
    tbDeleteList: TToolButton;
    ToolButton2: TToolButton;
    tbMainPage: TToolButton;
    tbKeyPage: TToolButton;
    WordList: TColorStringGrid;
    procedure edListNameEditingDone(Sender: TObject);
    procedure edListNameKeyPress(Sender: TObject; var Key: char);
    procedure KeyEditClicked(Sender: TObject);
    procedure tbDeleteListClick(Sender: TObject);
    procedure tbNewListClick(Sender: TObject);
    procedure tbSelectListClick(Sender: TObject);
    procedure GeneralCheckBoxChange(Sender: TObject);
    procedure tbSelectPageClicked(Sender: TObject);
    procedure WordListColRowDeleted(Sender: TObject; IsColumn: Boolean; sIndex,
      tIndex: Integer);
    procedure WordListEditingDone(Sender: TObject);
    procedure WordListExit(Sender: TObject);
    procedure WordListKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure WordListSelection(Sender: TObject; aCol, aRow: Integer);
  private
    { private declarations }
    FGlobalColors: TEditorUserDefinedWordsList;
    FUserWordsList: TEditorUserDefinedWordsList;
    FUserWords: TEditorUserDefinedWords;
    FKeyOptFrame: TEditorKeymappingOptionsFrame;
    FSelectedListIdx: Integer;  // In List of Lists
    FSelectedRow: Integer;
    FUpdatingDisplay: Integer;
    procedure CheckDuplicate(AnIndex: Integer);
    procedure DoListSelected(Sender: TObject);
    procedure MaybeCleanEmptyRow(aRow: Integer);
    procedure UpdateKeys;
    procedure UpdateTermOptions;
    procedure UpdateListDropDownFull;
    procedure UpdateListDropDownCaption;
    procedure UpdateListDisplay(KeepDuplicates: Boolean = False);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetTitle: String; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

{ TColorStringGrid }

function TColorStringGrid.GetRowFontColor(AIndex: Integer): TColor;
begin
  assert(AIndex < Length(FRowFontColor), 'GetRowFontColor');
  Result := FRowFontColor[AIndex];
end;

procedure TColorStringGrid.SetRowFontColor(AIndex: Integer; AValue: TColor);
begin
  assert(AIndex < Length(FRowFontColor), 'SetRowFontColor');
  if FRowFontColor[AIndex] = AValue then
    exit;
  FRowFontColor[AIndex] := AValue;
  Invalidate;
end;

procedure TColorStringGrid.PrepareCanvas(aCol, aRow: Integer; aState: TGridDrawState);
begin
  assert(aRow < Length(FRowFontColor));
  inherited PrepareCanvas(aCol, aRow, aState);
  Canvas.Font.Color := FRowFontColor[aRow];
end;

procedure TColorStringGrid.ColRowDeleted(IsColumn: Boolean; index: Integer);
begin
  inherited ColRowDeleted(IsColumn, index);
  if IsColumn then exit;
  assert(index < Length(FRowFontColor), 'ColRowDeleted');
  if index < Length(FRowFontColor) - 1 then
    move(FRowFontColor[index+1], FRowFontColor[index],
      (Length(FRowFontColor)-index) * SizeOf(TColor));
  SetLength(FRowFontColor, Length(FRowFontColor) - 1);
end;

procedure TColorStringGrid.ColRowInserted(IsColumn: boolean; index: integer);
begin
  inherited ColRowInserted(IsColumn, index);
  if IsColumn then exit;
  SetLength(FRowFontColor, Length(FRowFontColor) + 1);
  assert(index < Length(FRowFontColor), 'ColRowInserted');
  if index < Length(FRowFontColor) - 1 then
    move(FRowFontColor[index], FRowFontColor[index+1],
      (Length(FRowFontColor)-index) * SizeOf(TColor));
  FRowFontColor[index] := Font.Color;
end;

procedure TColorStringGrid.SizeChanged(OldColCount, OldRowCount: Integer);
var
  i: Integer;
begin
  inherited SizeChanged(OldColCount, OldRowCount);
  i := Length(FRowFontColor);
  SetLength(FRowFontColor, RowCount);
  while i < RowCount do begin
    FRowFontColor[i] := Font.Color;
    inc(i);
  end;
end;

{$R *.lfm}

{ TEditorMarkupUserDefinedFrame }

procedure TEditorMarkupUserDefinedFrame.edListNameEditingDone(Sender: TObject);
begin
  if (FUpdatingDisplay > 0) or (FUserWords = nil) then exit;
  if FUserWords.Name = edListName.Text then
    exit;
  FUserWords.Name := edListName.Text;
  UpdateListDropDownFull;
end;

procedure TEditorMarkupUserDefinedFrame.edListNameKeyPress(Sender: TObject; var Key: char);
begin
  if key in [#10,#13] then edListNameEditingDone(nil);
end;

procedure TEditorMarkupUserDefinedFrame.KeyEditClicked(Sender: TObject);
var
  i: Integer;
begin
  if FUserWords = nil then exit;

  i := -1;
  if Sender = btnKeyAdd then
    i := (FUserWordsList.KeyCommandList as TKeyCommandRelationList).IndexOf(FUserWords.AddTermCmd as TKeyCommandRelation);
  if Sender = btnKeyRemove then
    i := (FUserWordsList.KeyCommandList as TKeyCommandRelationList).IndexOf(FUserWords.RemoveTermCmd as TKeyCommandRelation);
  if Sender = btnKeyToggle then
    i := (FUserWordsList.KeyCommandList as TKeyCommandRelationList).IndexOf(FUserWords.ToggleTermCmd as TKeyCommandRelation);

  if i < 0 then exit;

  ShowKeyMappingEditForm(i, (FUserWordsList.KeyCommandList as TKeyCommandRelationList));
  FKeyOptFrame.UpdateTree;
  UpdateKeys;
end;

procedure TEditorMarkupUserDefinedFrame.tbDeleteListClick(Sender: TObject);
begin
  if FUserWords = nil then exit;
  if WordList.EditorMode then
    WordList.EditingDone;

  if IDEMessageDialog(dlgMarkupUserDefinedDelCaption,
                Format(dlgMarkupUserDefinedDelPrompt, [FUserWords.Name]),
                mtConfirmation, mbYesNo) = mrNo
  then
    exit;

  FUserWordsList.Remove(FUserWords, True);
  FUserWords := nil;
  if FSelectedListIdx > 0 then
    dec(FSelectedListIdx);

  UpdateListDropDownFull;
  UpdateListDisplay;
end;

procedure TEditorMarkupUserDefinedFrame.tbNewListClick(Sender: TObject);
begin
  if WordList.EditorMode then
    WordList.EditingDone;

  FUserWords := FUserWordsList.Add(dlgMarkupUserDefinedNewName);
  FSelectedListIdx := FUserWordsList.IndexOf(FUserWords);
  UpdateListDropDownFull;
  UpdateListDisplay;
end;

procedure TEditorMarkupUserDefinedFrame.tbSelectListClick(Sender: TObject);
begin
  tbSelectList.CheckMenuDropdown;
end;

procedure TEditorMarkupUserDefinedFrame.GeneralCheckBoxChange(Sender: TObject);
var
  i: PtrInt;
begin
  if (FUpdatingDisplay > 0) or (FUserWords = nil) then exit;

  if WordList.EditorMode then
    WordList.EditingDone;

  if Sender = cbKeyCase then begin
    FUserWords.KeyAddCase := cbKeyCase.Checked;
  end;

  if (Sender = cbKeyBoundStart) or (Sender = cbKeyBoundEnd) then begin
    if cbKeyBoundStart.Checked then begin
      if cbKeyBoundEnd.Checked
      then FUserWords.KeyAddTermBounds := soBothBounds
      else FUserWords.KeyAddTermBounds := soBoundsAtStart;
    end
    else begin
      if cbKeyBoundEnd.Checked
      then FUserWords.KeyAddTermBounds := soBoundsAtEnd
      else FUserWords.KeyAddTermBounds := soNoBounds;
    end;

    cbSmartSelectBound.Enabled := FUserWords.KeyAddTermBounds <> soNoBounds;
    edWordMin.Enabled   := FUserWords.KeyAddTermBounds <> soNoBounds;
    edSelectMin.Enabled := FUserWords.KeyAddTermBounds <> soNoBounds;
  end;

  if Sender = cbSmartSelectBound then begin
    FUserWords.KeyAddSelectSmart := cbSmartSelectBound.Checked;
  end;

  if Sender = edWordMin then begin
    FUserWords.KeyAddWordBoundMaxLen := edWordMin.Value;
  end;

  if Sender = edSelectMin then begin
    FUserWords.KeyAddSelectBoundMaxLen := edSelectMin.Value;
  end;

  if Sender = cbGlobalList then
    FUserWords.GlobalList := cbGlobalList.Checked;


  // Related to current word
  i := PtrInt(WordList.Objects[0, FSelectedRow])-1;
  if (i < 0) or (i >= FUserWords.Count) then
    exit;

  if Sender = cbCaseSense then begin
    FUserWords.Items[i].MatchCase := cbCaseSense.Checked;
    CheckDuplicate(FSelectedRow);
  end;

  if (Sender = cbMatchStartBound) or (Sender = cbMatchEndBound) then begin
    if cbMatchStartBound.Checked then begin
      if cbMatchEndBound.Checked
      then FUserWords.Items[i].MatchWordBounds := soBothBounds
      else FUserWords.Items[i].MatchWordBounds := soBoundsAtStart;
    end
    else begin
      if cbMatchEndBound.Checked
      then FUserWords.Items[i].MatchWordBounds := soBoundsAtEnd
      else FUserWords.Items[i].MatchWordBounds := soNoBounds;
    end;
  end;

end;

procedure TEditorMarkupUserDefinedFrame.tbSelectPageClicked(Sender: TObject);
begin
  if WordList.EditorMode then
    WordList.EditingDone;

  if tbMainPage.Down then
    Notebook1.PageIndex :=  0
  else
    Notebook1.PageIndex :=  1;
end;

procedure TEditorMarkupUserDefinedFrame.WordListColRowDeleted(Sender: TObject;
  IsColumn: Boolean; sIndex, tIndex: Integer);
begin
  if (FUpdatingDisplay > 0) or (FUserWords = nil) then exit;
  UpdateListDisplay(True);
end;

procedure TEditorMarkupUserDefinedFrame.WordListEditingDone(Sender: TObject);
var
  i: Integer;
begin
  if (FUpdatingDisplay > 0) or (FUserWords = nil) then exit;

  i := PtrInt(WordList.Objects[0, FSelectedRow])-1;
  if (i = -1) and (WordList.Cells[0, FSelectedRow] <> '') then begin
    i := FUserWords.Add.Index;
    WordList.Objects[0, FSelectedRow] := TObject(PtrInt(i+1));
  end;

  if (i < 0) or (i >= FUserWords.Count) then
    exit;

  if FUserWords.Items[i].SearchTerm = WordList.Cells[0, FSelectedRow] then
    exit;

  FUserWords.Items[i].SearchTerm := WordList.Cells[0, FSelectedRow];
  UpdateTermOptions;
  CheckDuplicate(FSelectedRow);
end;

procedure TEditorMarkupUserDefinedFrame.WordListExit(Sender: TObject);
begin
  MaybeCleanEmptyRow(FSelectedRow);
end;

procedure TEditorMarkupUserDefinedFrame.WordListKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  i: PtrInt;
begin
  if (FUpdatingDisplay > 0) or (FUserWords = nil) then exit;

  i := PtrInt(WordList.Objects[0, FSelectedRow])-1;
  if (i = -1) and (WordList.Cells[0, FSelectedRow] <> '') then begin
    i := FUserWords.Add.Index;
    WordList.Objects[0, FSelectedRow] := TObject(PtrInt(i+1));
    UpdateTermOptions;
  end
end;

procedure TEditorMarkupUserDefinedFrame.WordListSelection(Sender: TObject; aCol,
  aRow: Integer);
var
  i: Integer;
begin
  if (FUpdatingDisplay > 0) or (FUserWords = nil) then exit;

  if WordList.EditorMode then
    WordList.EditingDone;

  i := FSelectedRow;
  FSelectedRow := aRow;

  MaybeCleanEmptyRow(i);
  UpdateTermOptions;
end;

procedure TEditorMarkupUserDefinedFrame.CheckDuplicate(AnIndex: Integer);

  procedure UpdateDupErrors;
  var
    i: Integer;
  begin
    i := 0;
    while (i < FUserWords.Count) do begin
      if (FUserWords.FindSimilarMatchFor(FUserWords[i], 0, i) >= 0) then
        WordList.RowFontColor[i] := clRed
      else
        WordList.RowFontColor[i] := clDefault;
      inc(i);
    end;
  end;

var
  j: Integer;
begin
  if AnIndex < 0 then begin
    UpdateDupErrors;
    exit;
  end;

  j := FUserWords.FindSimilarMatchFor(FUserWords[AnIndex], 0, AnIndex);
  if (j >= 0) then begin
    if WordList.RowFontColor[FSelectedRow] <> clRed then begin
      UpdateDupErrors;
      IDEMessageDialog(dlgMarkupUserDefinedDuplicate,
                 Format(dlgMarkupUserDefinedDuplicateMsg, [FUserWords[AnIndex].SearchTerm]),
                 mtConfirmation, [mbOK]);
    end;
  end
  else
  if WordList.RowFontColor[FSelectedRow] <> clDefault then
    UpdateDupErrors;
end;

procedure TEditorMarkupUserDefinedFrame.DoListSelected(Sender: TObject);
begin
  if WordList.EditorMode then
    WordList.EditingDone;

  FSelectedListIdx := TMenuItem(Sender).Tag;
  UpdateListDisplay;
end;

procedure TEditorMarkupUserDefinedFrame.MaybeCleanEmptyRow(aRow: Integer);
var
  i: PtrInt;
begin
  if (FUpdatingDisplay > 0) or (FUserWords = nil) then exit;

  inc(FUpdatingDisplay);
  try
    i := PtrInt(WordList.Objects[0, aRow])-1;
    if (i = -1) and (aRow > 0) then begin
      WordList.DeleteRow(aRow);
      if FSelectedRow > aRow then
        dec(FSelectedRow);
      if FSelectedRow >= WordList.RowCount then
        dec(FSelectedRow);
      WordList.Row := FSelectedRow;
      UpdateTermOptions; // WordListSelection
    end;

    if (i < 0) or (i >= FUserWords.Count) then
      exit;

    if FUserWords.Items[i].SearchTerm = '' then begin
      FUserWords.Delete(i);
      if FSelectedRow > aRow then
        dec(FSelectedRow);
      i := FSelectedRow;
      UpdateListDisplay(True);
      if i >= WordList.RowCount then
        dec(i);
      WordList.Row := i;
      FSelectedRow := i;
      UpdateTermOptions; // WordListSelection
    end;

  finally
    dec(FUpdatingDisplay);
  end;
end;

procedure TEditorMarkupUserDefinedFrame.UpdateKeys;
const
  NoKey: TIDEShortCut = (Key1: VK_UNKNOWN; Shift1: []; Key2: VK_UNKNOWN; Shift2: [];);
begin
  if (FUserWords = nil) then begin
    lbKeyAdd1.Caption    := KeyAndShiftStateToEditorKeyString(NoKey);
    lbKeyAdd2.Caption    := KeyAndShiftStateToEditorKeyString(NoKey);
    lbKeyRemove1.Caption := KeyAndShiftStateToEditorKeyString(NoKey);
    lbKeyRemove2.Caption := KeyAndShiftStateToEditorKeyString(NoKey);
    lbKeyToggle1.Caption := KeyAndShiftStateToEditorKeyString(NoKey);
    lbKeyToggle2.Caption := KeyAndShiftStateToEditorKeyString(NoKey);
    exit;
  end;

  lbKeyAdd1.Caption    := KeyAndShiftStateToEditorKeyString(FUserWords.AddTermCmd.ShortcutA);
  lbKeyAdd2.Caption    := KeyAndShiftStateToEditorKeyString(FUserWords.AddTermCmd.ShortcutB);
  lbKeyRemove1.Caption := KeyAndShiftStateToEditorKeyString(FUserWords.RemoveTermCmd.ShortcutA);
  lbKeyRemove2.Caption := KeyAndShiftStateToEditorKeyString(FUserWords.RemoveTermCmd.ShortcutB);
  lbKeyToggle1.Caption := KeyAndShiftStateToEditorKeyString(FUserWords.ToggleTermCmd.ShortcutA);
  lbKeyToggle2.Caption := KeyAndShiftStateToEditorKeyString(FUserWords.ToggleTermCmd.ShortcutB);
end;

procedure TEditorMarkupUserDefinedFrame.UpdateTermOptions;
var
  i: PtrInt;
begin
  if (FUserWords = nil) then exit;

  inc(FUpdatingDisplay);
  try
    i := PtrInt(WordList.Objects[0, FSelectedRow])-1;
    cbCaseSense.Enabled       := (i >= 0) and (i < FUserWords.Count);
    cbMatchStartBound.Enabled := (i >= 0) and (i < FUserWords.Count);
    cbMatchEndBound.Enabled   := (i >= 0) and (i < FUserWords.Count);

    if (i < 0) or (i >= FUserWords.Count) then begin
      cbCaseSense.Checked       := False;
      cbMatchStartBound.Checked := False;
      cbMatchEndBound.Checked   := False;
      exit;
    end;

    cbCaseSense.Checked       := FUserWords.Items[i].MatchCase;
    cbMatchStartBound.Checked := FUserWords.Items[i].MatchWordBounds in [soBoundsAtStart, soBothBounds];
    cbMatchEndBound.Checked   := FUserWords.Items[i].MatchWordBounds in [soBoundsAtEnd, soBothBounds];
  finally
    dec(FUpdatingDisplay);
  end;
end;

procedure TEditorMarkupUserDefinedFrame.UpdateListDropDownFull;
var
  m: TMenuItem;
  i: Integer;
begin
  ListMenu.Items.Clear;
  if FUserWordsList.Count > 0 then begin
    for i := 0 to FUserWordsList.Count - 1 do begin
      m := TMenuItem.Create(ListMenu);
      m.Caption := FUserWordsList.Lists[i].Name;
      m.Tag := i;
      m.OnClick := @DoListSelected;
      ListMenu.Items.Add(m);
    end;
  end;
  UpdateListDropDownCaption;
end;

procedure TEditorMarkupUserDefinedFrame.UpdateListDropDownCaption;
begin
  if FUserWordsList.Count = 0 then begin
    tbSelectList.Enabled := False;
    tbSelectList.Caption := dlgMarkupUserDefinedNoLists;
  end
  else begin
    tbSelectList.Enabled := True;
    if (FSelectedListIdx >= 0) and (FSelectedListIdx < FUserWordsList.Count) then
      tbSelectList.Caption := FUserWordsList.Lists[FSelectedListIdx].Name
    else
      tbSelectList.Caption := dlgMarkupUserDefinedNoListsSel;
  end;
end;

procedure TEditorMarkupUserDefinedFrame.UpdateListDisplay(KeepDuplicates: Boolean);
var
  i: Integer;
begin
  WordList.EditorMode := False;
  inc(FUpdatingDisplay);

  if (FUserWords <> nil) and not (KeepDuplicates) then
    FUserWords.ClearSimilarMatches;

  UpdateListDropDownCaption;
  try
    if (FSelectedListIdx < 0) or (FSelectedListIdx >= FUserWordsList.Count) then begin
      FUserWords := nil;
      MainPanel.Enabled := False;
      WordList.RowCount := 0;
      UpdateKeys;
      exit;
    end;

    FUserWords := FUserWordsList.Lists[FSelectedListIdx];
    MainPanel.Enabled := True;
    edListName.Text := FUserWords.Name;
    SynColorAttrEditor1.CurHighlightElement := FUserWords.ColorAttr;
    WordList.RowCount := max(1, FUserWords.Count);
    WordList.Cells[0, 0] := '';
    WordList.Objects[0,0] := TObject(PtrInt(0));
    for i := 0 to FUserWords.Count - 1 do begin
      WordList.Cells[0, i] := FUserWords.Items[i].SearchTerm;
      WordList.Objects[0,i] := TObject(PtrInt(FUserWords.Items[i].Index + 1));
    end;
    FSelectedRow := 0;
    WordList.Col := 0;
    WordList.Row := 0;

    CheckDuplicate(-1);
    UpdateKeys;
    cbKeyCase.Checked          := FUserWords.KeyAddCase;
    cbKeyBoundStart.Checked    := FUserWords.KeyAddTermBounds in [soBoundsAtStart, soBothBounds];
    cbKeyBoundEnd.Checked      := FUserWords.KeyAddTermBounds in [soBoundsAtEnd, soBothBounds];
    cbSmartSelectBound.Checked := FUserWords.KeyAddSelectSmart;
    cbGlobalList.Checked       := FUserWords.GlobalList;
    edWordMin.Value   := FUserWords.KeyAddWordBoundMaxLen;
    edSelectMin.Value := FUserWords.KeyAddSelectBoundMaxLen;
    cbSmartSelectBound.Enabled := FUserWords.KeyAddTermBounds <> soNoBounds;
    edWordMin.Enabled          := FUserWords.KeyAddTermBounds <> soNoBounds;
    edSelectMin.Enabled        := FUserWords.KeyAddTermBounds <> soNoBounds;
  finally
    dec(FUpdatingDisplay)
  end;
  WordListSelection(nil, 0, 0);
end;

constructor TEditorMarkupUserDefinedFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FUserWordsList := TEditorUserDefinedWordsList.Create;
  FUpdatingDisplay := 0;
end;

destructor TEditorMarkupUserDefinedFrame.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FUserWordsList);
end;

function TEditorMarkupUserDefinedFrame.GetTitle: String;
begin
  Result := dlgMarkupUserDefined;
end;

procedure TEditorMarkupUserDefinedFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  SynColorAttrEditor1.Setup;
  SynColorAttrEditor1.ShowPrior := True;
  tbNewList.Caption          := dlgMarkupUserDefinedListNew;
  tbDeleteList.Caption       := dlgMarkupUserDefinedListDel;
  lbListName.Caption         := dlgMarkupUserDefinedListName;
  tbMainPage.Caption         := dlgMarkupUserDefinedPageMain;
  tbKeyPage.Caption          := dlgMarkupUserDefinedPageKeys;
  cbCaseSense.Caption        := dlgMarkupUserDefinedMatchCase;
  cbMatchStartBound.Caption  := dlgMarkupUserDefinedMatchStartBound;
  cbMatchEndBound.Caption    := dlgMarkupUserDefinedMatchEndBound;
  divKeyAdd.Caption          := dlgMarkupUserDefinedDivKeyAdd;
  divKeyRemove.Caption       := dlgMarkupUserDefinedDivKeyRemove;
  divKeyToggle.Caption       := dlgMarkupUserDefinedDivKeyToggle;

  lbNewKeyOptions.Caption    := dlgMarkupUserDefinedNewByKeyOpts;
  cbKeyCase.Caption          := dlgMarkupUserDefinedMatchCase;
  cbKeyBoundStart.Caption    := dlgMarkupUserDefinedMatchStartBound;
  cbKeyBoundEnd.Caption      := dlgMarkupUserDefinedMatchEndBound;
  lbKeyBoundMinLen.Caption   := dlgMarkupUserDefinedNewByKeyLen;
  lbWordMin.Caption          := dlgMarkupUserDefinedNewByKeyLenWord;
  lbSelectMin.Caption        := dlgMarkupUserDefinedNewByKeyLenSelect;
  cbSmartSelectBound.Caption := dlgMarkupUserDefinedNewByKeySmartSelect;
  cbGlobalList.Caption       := dlgMarkupUserDefinedGlobalList;

  FKeyOptFrame := TEditorKeymappingOptionsFrame(ADialog.FindEditor(TEditorKeymappingOptionsFrame));
  FUserWordsList.KeyCommandList := FKeyOptFrame.EditingKeyMap;
  edListName.Text := '';
end;

procedure TEditorMarkupUserDefinedFrame.ReadSettings(AOptions: TAbstractIDEOptions);
begin
  FGlobalColors := TEditorOptions(AOptions).UserDefinedColors;
  FSelectedListIdx := 0;

  FKeyOptFrame.ReadSettings(AOptions);

  FUserWordsList.Assign(FGlobalColors);
  FSelectedListIdx := 0;
  UpdateListDropDownFull;
  UpdateListDisplay;
  tbDeleteList.Enabled := FUserWordsList.Count > 0;
  FGlobalColors := nil;
  UpdateKeys;
end;

procedure TEditorMarkupUserDefinedFrame.WriteSettings(AOptions: TAbstractIDEOptions);
begin
  if FGlobalColors <> nil then
    exit;

  if FUserWords <> nil then
    FUserWords.ClearSimilarMatches;
  TEditorOptions(AOptions).UserDefinedColors.Assign(FUserWordsList);
end;

class function TEditorMarkupUserDefinedFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TEditorOptions;
end;

initialization
  RegisterIDEOptionsEditor(GroupEditor, TEditorMarkupUserDefinedFrame,
    EdtOptionsUserDefined, EdtOptionsDisplay);
end.

