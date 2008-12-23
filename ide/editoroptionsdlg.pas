{  $Id: editoroptionsdlg.pas 17085 2008-10-21 09:30:01Z paul $  }
{
 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************
 
  Author: Mattias Gaertner
}
unit EditorOptionsDlg;

{$mode objfpc}{$H+}

interface

uses
  // RTL, FCL
  Classes, SysUtils,
  // LCL
  Buttons, ComCtrls, Controls, Dialogs, ExtCtrls, Forms, Graphics, FileUtil,
  GraphType, LCLIntf, LCLProc, LCLType, LResources, StdCtrls, Spin,
  // synedit
  SynEdit, SynEditAutoComplete, SynEditHighlighter, SynEditKeyCmds,
  SynEditStrConst,
  SynHighlighterCPP, SynHighlighterHTML, SynHighlighterJava, SynHighlighterLFM,
  SynHighlighterPas, SynHighlighterPerl, SynHighlighterPHP, SynHighlighterSQL,
  SynHighlighterPython, SynHighlighterUNIXShellScript, SynHighlighterXML,
  SynHighlighterJScript, SynEditMiscClasses,
  // codetools
  LinkScanner, CodeToolManager, Laz_XMLCfg,
  // IDEIntf
  IDECommands, IDEWindowIntf, SrcEditorIntf, IDEImagesIntf, IDEOptionsIntf,
  // IDE
  LazarusIDEStrConsts, IDEOptionDefs, IDEProcs, InputHistory, KeyMapping,
  KeymapSchemeDlg, KeyMapShortCutDlg, LazConf, ButtonPanel, EditorOptions;

type
  TPreviewEditor = TSynEdit;

  { TEditorOptionsForm }

  TEditorOptionsForm = class(TForm)
    ButtonPanel: TButtonPanel;
    DisableAntialiasingCheckBox: TCheckBox;
    MainNoteBook: TNoteBook;

    // general options
    EditorOptionsGroupBox: TCheckGroup;
    GeneralPage: TPage;
    DisplayPage: TPage;
    KeymappingPage: TPage;
    ColorPage: TPage;
    CodetoolsPage: TPage;
    BlockIndentComboBox: TComboBox;
    BlockIndentLabel: TLabel;
    CodeFolding: TPage;
    TextBoldRadioOn : TRadioButton;
    TextBoldRadioOff : TRadioButton;
    TextBoldRadioInvert : TRadioButton;
    TextItalicRadioOn : TRadioButton;
    TextItalicRadioOff : TRadioButton;
    TextItalicRadioInvert : TRadioButton;
    TextUnderlineRadioOn : TRadioButton;
    TextUnderlineRadioOff : TRadioButton;
    TextUnderlineRadioInvert : TRadioButton;
    TextBoldRadioPanel : TPanel;
    TextItalicRadioPanel : TPanel;
    TextUnderlineRadioPanel : TPanel;
    TextUnderlinePanel : TPanel;
    TextItalicPanel : TPanel;
    TextBoldPanel : TPanel;
    UndoLimitComboBox: TComboBox;
    UndoLimitLabel: TLabel;
    TabWidthsComboBox: TComboBox;
    TabWidthsLabel: TLabel;

    // Display options
    MarginAndGutterGroupBox: TGroupBox;
    VisibleRightMarginCheckBox: TCheckBox;
    VisibleGutterCheckBox: TCheckBox;
    ShowLineNumbersCheckBox: TCheckBox;
    ShowOnlyLineNumbersMultiplesOfLabel: TLabel;
    ShowOnlyLineNumbersMultiplesOfSpinEdit: TSpinEdit;
    GutterColorButton: TColorButton;
    GutterColorLabel:  TLabel;
    RightMarginComboBox: TComboBox;
    RightMarginLabel:  TLabel;
    RightMarginColorButton: TColorButton;
    RightMarginColorLabel: TLabel;
    EditorFontGroupBox: TGroupBox;
    EditorFontComboBox: TComboBox;
    EditorFontButton: TButton;
    EditorFontHeightLabel: TLabel;
    EditorFontHeightComboBox: TComboBox;
    ExtraLineSpacingLabel: TLabel;
    ExtraLineSpacingComboBox: TComboBox;
    ExtraCharSpacingLabel: TLabel;
    ExtraCharSpacingComboBox: TComboBox;
    DisplayPreview: TPreviewEditor;

    // Key Mappings
    KeyMappingChooseSchemeButton: TButton;
    KeyMappingHelpLabel: TLabel;
    KeyMappingTreeView: TTreeView;
    KeyMappingConsistencyCheckButton: TButton;
    KeyMappingFindKeyButton: TButton;
    KeyMappingFilterEdit: TEdit;

    // Color options
    LanguageComboBox: TComboBox;
    LanguageLabel: TLabel;
    FileExtensionsComboBox: TComboBox;
    FileExtensionsLabel: TLabel;
    ColorSchemeComboBox: TComboBox;
    ColorSchemeLabel: TLabel;
    ColorElementLabel: TLabel;
    ColorElementListBox: TListBox;
    TextAttributesGroupBox: TGroupBox;
    TextBoldCheckBox: TCheckBox;
    TextItalicCheckBox: TCheckBox;
    TextUnderlineCheckBox: TCheckBox;
    ForeGroundGroupBox: TGroupBox;
    ForeGroundColorButton: TColorButton;
    ForeGroundUseDefaultCheckBox: TCheckBox;
    BackGroundGroupBox: TGroupBox;
    BackGroundColorButton: TColorButton;
    BackGroundUseDefaultCheckBox: TCheckBox;
    SetAttributeToDefaultButton: TButton;
    SetAllAttributesToDefaultButton: TButton;
    ColorPreview: TPreviewEditor;
    ForeGroundLabel: TLabel;
    BackGroundLabel: TLabel;

    // Code Tools options
    AutomaticFeaturesGroupBox: TGroupBox;
    AutoIdentifierCompletionCheckBox: TCheckBox;
    AutoCodeParametersCheckBox: TCheckBox;
    AutoToolTipExprEvalCheckBox: TCheckBox;
    AutoToolTipSymbToolsCheckBox: TCheckBox;
    AutoDelayLabel: TLabel;
    AutoDelayTrackBar: TTrackBar;
    AutoDelayMinLabel: TLabel;
    AutoDelayMaxLabel: TLabel;
    
    // Code Folding
    Bevel1: TBevel;
    chkCodeFoldingEnabled: TCheckBox;
    lblDividerDrawLevel: TLabel;
    edDividerDrawLevel: TSpinEdit;

    // general
    procedure ColorElementListBoxClick(Sender: TObject);
    procedure DisplayPreviewStatusChange(Sender : TObject; Changes : TSynStatusChanges);
    procedure GeneralCheckBoxOnChange(Sender: TObject);
    procedure ComboBoxOnChange(Sender: TObject);
    procedure ComboBoxOnExit(Sender: TObject);
    procedure ComboBoxOnKeyDown(Sender: TObject;
                                var Key: Word; Shift: TShiftState);
    procedure ColorButtonColorChanged(Sender: TObject);

    // display
    procedure FontDialogApplyClicked(Sender: TObject);
    procedure EditorFontComboBoxEditingDone(Sender: TObject);
    procedure EditorFontButtonClick(Sender: TObject);
    procedure HelpButtonClick(Sender: TObject);
    procedure KeyMappingFilterEditExit(Sender: TObject);
    procedure RightMarginColorButtonColorChanged(Sender: TObject);

    // key mapping
    procedure KeyMappingFilterEditEnter(Sender: TObject);
    procedure KeyMappingFilterEditChange(Sender: TObject);
    procedure KeyMappingChooseSchemeButtonClick(Sender: TObject);
    procedure KeyMappingTreeViewMouseUp(Sender: TObject;
                      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure KeyMappingConsistencyCheckButtonClick(Sender: TObject);
    procedure KeyMappingFindKeyButtonClick(Sender: TObject);

    // color
    procedure ColorElementListBoxSelectionChange(Sender: TObject; User: Boolean);
    procedure ColorPreviewMouseUp(Sender: TObject; Button: TMouseButton;
                                  Shift: TShiftState; X, Y: Integer);
    procedure OnSpecialLineColors(Sender: TObject; Line: Integer;
                                  var Special: boolean; aMarkUp : TSynSelectedColor);
    procedure SetAttributeToDefaultButtonClick(Sender: TObject);
    procedure SetAllAttributesToDefaultButtonClick(Sender: TObject);

    // code tools

    // Code Folding
    procedure chkCodeFoldingEnabledChange(Sender: TObject);

    // buttons at bottom
    procedure OkButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure ShowLineNumbersCheckBoxClick(Sender: TObject);
    procedure TextStyleRadioOnChange(Sender : TObject);
  private
    FormCreating: Boolean;
    PreviewSyn: TSrcIDEHighlighter;
    // 3 is used to hold the true (non-preview) options, it is not displayed
    PreviewEdits: array[1..3] of TPreviewEditor;
    CurLanguageID: Integer;
    // current index in EditorOpts.EditOptHighlighterList
    CurHighlightElement: TSynHighlightElement;
    CurHighlightElementIsExtra: Boolean;
    UpdatingColor: Boolean;
    fHighlighterList: TStringList; // list of "ColorScheme" Data=TSrcIDEHighlighter
    fColorSchemes: TStringList;    // list of LanguageName=ColorScheme
    fFileExtensions: TStringList;  // list of LanguageName=FileExtensions
    EditingKeyMap: TKeyCommandRelationList;

    procedure SetComboBoxText(AComboBox: TComboBox; const AText: String);
    procedure FontDialogNameToFont(FontDialogName: String; AFont: TFont);
    procedure InvalidatePreviews;
    procedure SetPreviewSynInAllPreviews;
    procedure SetupButtonBar;

    // general
    procedure SetupGeneralPage(Page: Integer);

    // display
    procedure SetupDisplayPage(Page: Integer);

    // keymapping
    KeyMapNameFilter: string;
    KeyMapKeyFilter: TIDEShortCut;
    procedure SetupKeyMappingsPage(Page: Integer);
    function KeyMappingRelationToString(Index: Integer): String;
    function KeyMappingRelationToString(KeyRelation:
                                        TKeyCommandRelation): String;
    procedure FillKeyMappingTreeView;

    // color
    procedure SetupColorPage(Page: Integer);
    procedure ShowCurAttribute;
    procedure FindCurHighlightElement;
    function GetHighlighter(SynClass: TCustomSynClass;
      const ColorScheme: String; CreateIfNotExists: Boolean): TSrcIDEHighlighter;
    procedure ClearHighlighters;
    procedure SaveAllHighlighters;
    procedure FillColorElementListBox;
    function GetCurColorScheme(const LanguageName: String): String;
    procedure SetCurColorScheme(const LanguageName, ColorScheme: String);
    procedure SaveAllColorSchemes;
    function GetCurFileExtensions(const LanguageName: String): String;
    procedure SetCurFileExtensions(const LanguageName, FileExtensions: String);
    procedure SaveAllFileExtensions;
    procedure SetColorElementsToDefaults(OnlySelected: Boolean);

    // code tools
    procedure SetupCodeToolsPage(Page: Integer);
    
    // Code Folding
    procedure SetupCodeFoldingPage(Page: integer);
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

uses
  IDEContextHelpEdit;

var
  imgKeyCategory, imgKeyItem: Integer;

{ TEditorOptionsForm }

constructor TEditorOptionsForm.Create(TheOwner: TComponent);
var
  a: Integer;
  s: String;
begin
  inherited Create(TheOwner);
  FormCreating := True;
  Caption      := lismenueditoroptions;
  KeyMapNameFilter:='';
  KeyMapKeyFilter:=CleanIDEShortCut;

  IDEDialogLayoutList.ApplyLayout(Self, Width,Height);

  SetupGeneralPage(0);
  SetupDisplayPage(1);
  SetupKeyMappingsPage(2);
  SetupColorPage(3);
  SetupCodeToolsPage(4);
  SetupCodeFoldingPage(5);
  SetupButtonBar;

  UpdatingColor := False;
  CurHighlightElement := Nil;
  CurHighlightElementIsExtra := False;

  // create a temporary copy of the keymap for editing
  EditingKeyMap := TKeyCommandRelationList.Create;
  EditingKeyMap.Assign(EditorOpts.KeyMap);

  // initialize previews
  for a := Low(PreviewEdits) to High(PreviewEdits) do
    PreviewEdits[a] := Nil;
  s := GetCurColorScheme(TPreviewPasSyn.GetLanguageName);
  PreviewSyn := GetHighlighter(TPreviewPasSyn, s, True);
  CurLanguageID := EditorOpts.HighlighterList.FindByClass(
    TCustomSynClass(PreviewSyn.ClassType));

  PreviewEdits[1] := DisplayPreview;
  PreviewEdits[2] := ColorPreview;
  PreviewEdits[3] := TSynEdit.Create(self);
  for a := Low(PreviewEdits) to High(PreviewEdits) do
    if PreviewEdits[a] <> Nil then
      with PreviewEdits[a] do
      begin
        if EditorOpts.UseSyntaxHighlight then
          Highlighter := PreviewSyn;
        if a <> 3 then
          EditorOpts.GetSynEditPreviewSettings(PreviewEdits[a])
        else
          EditorOpts.GetSynEditSettings(PreviewEdits[a]);
        EditingKeyMap.AssignTo(PreviewEdits[a].KeyStrokes,
          TSourceEditorWindowInterface);
        if a <> 3 then
        begin
          Lines.Text := EditorOpts.HighlighterList[CurLanguageID].SampleSource;
          PreviewEdits[a].CaretXY := EditorOpts.HighlighterList[CurLanguageID].CaretXY;
          PreviewEdits[a].TopLine := 1;
          PreviewEdits[a].LeftChar := 1;
        end;
      end;

  // general options

  // display options

  // key mappings
  FillKeyMappingTreeView;

  // color options
  LanguageComboBox.Text := PreviewSyn.LanguageName;
  SetComboBoxText(LanguageComboBox, LanguageComboBox.Text);
  ColorSchemeComboBox.Text := GetCurColorScheme(PreviewSyn.LanguageName);
  SetComboBoxText(ColorSchemeComboBox, ColorSchemeComboBox.Text);
  FillColorElementListBox;
  FindCurHighlightElement;
  ShowCurAttribute;
  InvalidatePreviews;

  // code Tools options

  MainNoteBook.PageIndex := 0;
  FormCreating := False;
end;

destructor TEditorOptionsForm.Destroy;
begin
  ClearHighlighters;
  fColorSchemes.Free;
  fFileExtensions.Free;
  EditingKeyMap.Free;
  inherited Destroy;
end;


// general

procedure TEditorOptionsForm.GeneralCheckBoxOnChange(Sender: TObject);
var
  a: Integer;
  NewColor: TColor;
  i: LongInt;

  procedure SetOption(const CheckBoxName: String; AnOption: TSynEditorOption);
  var
    a: Integer;
    i: LongInt;
  begin
    i:=EditorOptionsGroupBox.Items.IndexOf(CheckBoxName);
    if i<0 then begin
      DebugLn(['TEditorOptionsForm.GeneralCheckBoxOnChange.SetOption i<0']);
      exit;
    end;
    for a := Low(PreviewEdits) to High(PreviewEdits) do begin
      if (a <> 3) and (AnOption in SynEditPreviewExcludeOptions) then
        continue;
      if PreviewEdits[a] <> Nil then
        if EditorOptionsGroupBox.Checked[i] then
          PreviewEdits[a].Options := PreviewEdits[a].Options + [AnOption]
        else
          PreviewEdits[a].Options := PreviewEdits[a].Options - [AnOption];
    end;
  end;

  procedure SetOption2(const CheckBoxName: String; AnOption: TSynEditorOption2);
  var
    a: Integer;
    i: LongInt;
  begin
    i:=EditorOptionsGroupBox.Items.IndexOf(CheckBoxName);
    if i<0 then exit;
    for a := Low(PreviewEdits) to High(PreviewEdits) do begin
      if (a <> 3) and (AnOption in SynEditPreviewExcludeOptions2) then
        continue;
      if PreviewEdits[a] <> Nil then
        if EditorOptionsGroupBox.Checked[i] then
          PreviewEdits[a].Options2 := PreviewEdits[a].Options2 + [AnOption]
        else
          PreviewEdits[a].Options2 := PreviewEdits[a].Options2 - [AnOption];
    end;
  end;

  // GeneralCheckBoxOnChange
begin
  if FormCreating then
    exit;
  // general
  SetOption(dlgAltSetClMode, eoAltSetsColumnMode);
  SetOption(dlgAutoIdent, eoAutoIndent);
  SetOption(dlgBracHighlight,eoBracketHighlight);
  SetOption(dlgDoubleClickLine, eoDoubleClickSelectsLine);
  SetOption(dlgDragDropEd, eoDragDropEditing);
  SetOption(dlgDropFiles, eoDropFiles);
  SetOption(dlgGroupUndo, eoGroupUndo);
  SetOption(dlgHomeKeyJumpsToNearestStart, eoEnhanceHomeKey);
  SetOption(dlgHalfPageScroll, eoHalfPageScroll);
  SetOption(dlgKeepCursorX, eoKeepCaretX);
  SetOption(dlgPersistentCursor, eoPersistentCaret);
  SetOption(dlgRightMouseMovesCursor, eoRightMouseMovesCursor);
  // not for Preview: SetOption('NoSelectionCheckBox',eoNoSelection);
  SetOption(dlgScrollByOneLess, eoScrollByOneLess);
  SetOption(dlgScrollPastEndFile, eoScrollPastEoF);
  SetOption(dlgScrollPastEndLine, eoScrollPastEoL);
  SetOption(lisShowSpecialCharacters, eoShowSpecialChars);
  //SetOption(dlgShowScrollHint, eoShowScrollHint);
  SetOption(dlgSmartTabs, eoSmartTabs);
  SetOption(dlgTabsToSpaces, eoTabsToSpaces);
  SetOption(dlgTabIndent, eoTabIndent);
  SetOption(dlgTrimTrailingSpaces, eoTrimTrailingSpaces);
  
  SetOption2(dlgCursorSkipsSelection, eoCaretSkipsSelection);
  SetOption2(dlgAlwaysVisibleCursor, eoAlwaysVisibleCaret);

  for a := Low(PreviewEdits) to High(PreviewEdits) do
    if PreviewEdits[a] <> Nil then
    begin
      // general
      i:=EditorOptionsGroupBox.Items.IndexOf(dlgUseSyntaxHighlight);
      if EditorOptionsGroupBox.Checked[i] then
        PreviewEdits[a].Highlighter := PreviewSyn
      else
        PreviewEdits[a].Highlighter := Nil;
      // display
      PreviewEdits[a].Gutter.Visible := VisibleGutterCheckBox.Checked;
      PreviewEdits[a].Gutter.ShowLineNumbers  := ShowLineNumbersCheckBox.Checked;
      PreviewEdits[a].Gutter.ShowOnlyLineNumbersMultiplesOf := ShowOnlyLineNumbersMultiplesOfSpinEdit.Value;
      PreviewEdits[a].RightEdgeColor:=RightMarginColorButton.ButtonColor;
      if VisibleRightMarginCheckBox.Checked then
        PreviewEdits[a].RightEdge:=StrToIntDef(RightMarginComboBox.Text,80)
      else
        PreviewEdits[a].RightEdge:=0;
      if DisableAntialiasingCheckBox.Checked then
        PreviewEdits[a].Font.Quality:=fqNonAntialiased
      else
        PreviewEdits[a].Font.Quality:=fqDefault;
    end;
  if CurHighlightElement <> Nil then
  begin
    if Sender = ForeGroundUseDefaultCheckBox then
      if UpdatingColor = False then
      begin
        UpdatingColor := True;
        if not ForeGroundUseDefaultCheckBox.Checked then
          NewColor := ForeGroundColorButton.ButtonColor
        else
          NewColor := clNone;
        ForeGroundColorButton.Visible := not
          ForeGroundUseDefaultCheckBox.Checked;
        if NewColor <> CurHighlightElement.Foreground then
        begin
          CurHighlightElement.Foreground := NewColor;
          InvalidatePreviews;
        end;
        UpdatingColor := False;
      end;
    if Sender = BackGroundUseDefaultCheckBox then
      if UpdatingColor = False then
      begin
        if not BackGroundUseDefaultCheckBox.Checked then
          NewColor := BackGroundColorButton.ButtonColor
        else
          NewColor := clNone;
        BackGroundColorButton.Visible := not
          BackGroundUseDefaultCheckBox.Checked;
        if NewColor <> CurHighlightElement.Background then
        begin
          CurHighlightElement.Background := NewColor;
          InvalidatePreviews;
        end;
      end;
    if Sender = TextBoldCheckBox then
      if CurHighlightElementIsExtra
      then TextStyleRadioOnChange(Sender)
      else if TextBoldCheckBox.Checked xor (fsBold in CurHighlightElement.Style) then
      begin
        if TextBoldCheckBox.Checked then
          CurHighlightElement.Style := CurHighlightElement.Style + [fsBold]
        else
          CurHighlightElement.Style := CurHighlightElement.Style - [fsBold];
        InvalidatePreviews;
      end;
    if Sender = TextItalicCheckBox then
      if CurHighlightElementIsExtra
      then TextStyleRadioOnChange(Sender)
      else if TextItalicCheckBox.Checked then
      begin
        if not (fsItalic in CurHighlightElement.Style) then
        begin
          CurHighlightElement.Style := CurHighlightElement.Style + [fsItalic];
          InvalidatePreviews;
        end;
      end
      else
      if (fsItalic in CurHighlightElement.Style) then
      begin
        CurHighlightElement.Style := CurHighlightElement.Style - [fsItalic];
        InvalidatePreviews;
      end;
    if Sender = TextUnderlineCheckBox then
      if CurHighlightElementIsExtra
      then TextStyleRadioOnChange(Sender)
      else if TextUnderlineCheckBox.Checked then
      begin
        if not (fsUnderline in CurHighlightElement.Style) then
        begin
          CurHighlightElement.Style := CurHighlightElement.Style + [fsUnderline];
          InvalidatePreviews;
        end;
      end
      else
      if (fsUnderline in CurHighlightElement.Style) then
      begin
        CurHighlightElement.Style := CurHighlightElement.Style - [fsUnderline];
        InvalidatePreviews;
      end;
  end;
end;
procedure TEditorOptionsForm.ColorElementListBoxClick(Sender: TObject);
begin
  FindCurHighlightElement;
end;

type
  // This is only needed until SynEdit does the ScrollWindowEx in Paint, instead of SetTopline
  TSynEditAccess = class(TSynEdit);
procedure TEditorOptionsForm.DisplayPreviewStatusChange(Sender : TObject; Changes : TSynStatusChanges);
var
  Syn: TSynEditAccess;
  p: TPoint;
  tl, lc: Integer;
begin
  p := EditorOpts.HighlighterList[CurLanguageID].CaretXY;
  Syn := TSynEditAccess(Pointer(Sender as TSynEdit));
  if p.y > Syn.Lines.Count then exit;
  if (Syn.CaretX = p.x) and (Syn.Carety = p.y) then exit;
  try
    Syn.IncPaintLock;
    tl := Syn.TopLine;
    lc := Syn.LeftChar;
    Syn.CaretXY:= p;
    Syn.TopLine := tl;
    Syn.LeftChar := lc;
  finally
    Syn.DecPaintLock;
  end;
end;

procedure TEditorOptionsForm.chkCodeFoldingEnabledChange(Sender: TObject);
begin
  lblDividerDrawLevel.Enabled := chkCodeFoldingEnabled.Checked;
  edDividerDrawLevel.Enabled  := chkCodeFoldingEnabled.Checked;
end;

procedure TEditorOptionsForm.EditorFontComboBoxEditingDone(Sender: TObject);
var
  i: Integer;
begin
  for i := Low(PreviewEdits) to High(PreviewEdits) do
    if PreviewEdits[i] <> Nil then
      PreviewEdits[i].Font.Name:=EditorFontComboBox.Text;
end;

procedure TEditorOptionsForm.ColorButtonColorChanged(Sender: TObject);
var
  a: Integer;
begin
  if FormCreating then
    exit;
  if Sender = ForeGroundColorButton then
  begin
    if (CurHighlightElement = Nil) or UpdatingColor then
      exit;
    if not ForeGroundUseDefaultCheckBox.Checked then
    begin
      CurHighlightElement.Foreground := ForeGroundColorButton.ButtonColor;
      InvalidatePreviews;
    end;
  end;
  if Sender = BackGroundColorButton then
  begin
    if (CurHighlightElement = Nil) or UpdatingColor then
      exit;
    if not BackGroundUseDefaultCheckBox.Checked then
    begin
      CurHighlightElement.Background := BackGroundColorButton.ButtonColor;
      InvalidatePreviews;
    end;
  end;
  if Sender = GutterColorButton then
    for a := Low(PreviewEdits) to High(PreviewEdits) do
      if PreviewEdits[a] <> Nil then
      begin
        PreviewEdits[a].Gutter.Color := GutterColorButton.ButtonColor;
        PreviewEdits[a].Invalidate;
      end;
end;

procedure TEditorOptionsForm.FontDialogNameToFont(FontDialogName: String;
  AFont: TFont);
var
  TmpFont: TFont;
  p, p2, index: Integer;
  s: shortstring;
begin
  TmpFont := TFont.Create;
  TmpFont.Assign(AFont);
  try
    p := 1;
    p2 := 0;
    index := 1;
    while (p <= length(FontDialogName)) do
    begin
      if (FontDialogName[p] = '-') then
      begin
        // this is an XLFD font name, the third item is the name
        s := copy(FontDialogName, p2 + 1, p - p2 - 1);
        p2 := p;
        case Index of
          3:
            TmpFont.Name := s;
          //8:TmpFont.Height:=StrToIntDef(s,TmpFont.Height);
        end;
        inc(Index);
      end;
      inc(p);
    end;
    AFont.Assign(TmpFont);
  finally
    TmpFont.Free;
  end;
end;

procedure TEditorOptionsForm.FontDialogApplyClicked(Sender: TObject);
var
  a: Integer;
begin
  for a := Low(PreviewEdits) to High(PreviewEdits) do
    if PreviewEdits[a] <> Nil then
      PreviewEdits[a].Font.Assign(TFontDialog(Sender).Font);
  SetComboBoxText(EditorFontComboBox,DisplayPreview.Font.Name);
  SetComboBoxText(EditorFontHeightComboBox,
                  IntToStr(DisplayPreview.Font.Height));
end;

procedure TEditorOptionsForm.EditorFontButtonClick(Sender: TObject);
var
  FontDialog: TFontDialog;
  NewHeight: LongInt;
begin
  FontDialog := TFontDialog.Create(Nil);
  try
    with FontDialog do
    begin
      Font.Name   := EditorFontComboBox.Text;
      NewHeight := StrToIntDef(EditorFontHeightComboBox.Text, PreviewEdits[1].Font.Height);
      RepairEditorFontHeight(NewHeight);
      Font.Height := NewHeight;
      Options := Options + [fdApplyButton];
      OnApplyClicked := @FontDialogApplyClicked;
      if Execute then
        FontDialogApplyClicked(FontDialog);
    end;
  finally
    FontDialog.Free;
  end;
end;

procedure TEditorOptionsForm.HelpButtonClick(Sender: TObject);
begin
  ShowContextHelpForIDE(Self);
end;

procedure TEditorOptionsForm.KeyMappingFilterEditExit(Sender: TObject);
begin
  if KeyMappingFilterEdit.Text='' then
    KeyMappingFilterEdit.Text:=lisFilter2;
end;

procedure TEditorOptionsForm.KeyMappingFilterEditEnter(Sender: TObject);
begin
  if KeyMappingFilterEdit.Text=lisFilter2 then
    KeyMappingFilterEdit.Text:='';
end;

procedure TEditorOptionsForm.KeyMappingFilterEditChange(Sender: TObject);
var
  Filter: String;
begin
  if [csLoading,csDestroying]*ComponentState<>[] then exit;
  Filter:=KeyMappingFilterEdit.Text;
  if (Filter=lisFilter2) or (Filter=KeyMappingFilterEdit.Name) then Filter:='';
  KeyMapNameFilter:=Filter;
  FillKeyMappingTreeView;
end;

procedure TEditorOptionsForm.KeyMappingFindKeyButtonClick(Sender: TObject);
var
  KeyFilter: TIDEShortCut;
begin
  if ShowKeyMappingGrabForm(KeyFilter)<>mrOK then exit;
  //debugln(['TEditorOptionsForm.KeyMappingFindKeyButtonClick ',KeyAndShiftStateToEditorKeyString(KeyFilter)]);
  KeyMapKeyFilter:=KeyFilter;
  FillKeyMappingTreeView;
end;

procedure TEditorOptionsForm.KeyMappingChooseSchemeButtonClick(
  Sender: TObject);
var
  NewScheme: String;
begin
  NewScheme:=EditorOpts.KeyMappingScheme;
  if ShowChooseKeySchemeDialog(NewScheme) <> mrOk then
    exit;
  EditorOpts.KeyMappingScheme:=NewScheme;
  EditingKeyMap.LoadScheme(NewScheme);
  FillKeyMappingTreeView;
end;

procedure TEditorOptionsForm.ComboBoxOnExit(Sender: TObject);
var
  NewVal, a: Integer;
  Box: TComboBox;
begin
  if FormCreating then
    exit;
  Box := TComboBox(Sender);
  if PreviewEdits[1] <> Nil then
    if Sender = BlockIndentComboBox then
    begin
      NewVal := StrToIntDef(BlockIndentComboBox.Text,
        PreviewEdits[1].BlockIndent);
      SetComboBoxText(BlockIndentComboBox, IntToStr(NewVal));
      for a := Low(PreviewEdits) to High(PreviewEdits) do
        if PreviewEdits[a] <> Nil then
          PreviewEdits[a].BlockIndent := NewVal;
    end
    else
    if Sender = TabWidthsComboBox then
    begin
      NewVal := StrToIntDef(TabWidthsComboBox.Text,
        PreviewEdits[1].TabWidth);
      SetComboBoxText(TabWidthsComboBox, IntToStr(NewVal));
      for a := Low(PreviewEdits) to High(PreviewEdits) do
        if PreviewEdits[a] <> Nil then
          PreviewEdits[a].TabWidth := NewVal;
    end
    // display
    else
    if Sender = EditorFontHeightComboBox then
    begin
      NewVal := StrToIntDef(EditorFontHeightComboBox.Text,
                            PreviewEdits[1].Font.Height);
      RepairEditorFontHeight(NewVal);
      SetComboBoxText(EditorFontHeightComboBox, IntToStr(NewVal));
      for a := Low(PreviewEdits) to High(PreviewEdits) do
        if PreviewEdits[a] <> Nil then
          PreviewEdits[a].Font.Height := NewVal;
    end
    else
    if Sender = ExtraCharSpacingComboBox then
    begin
      NewVal := StrToIntDef(ExtraCharSpacingComboBox.Text,
        PreviewEdits[1].ExtraCharSpacing);
      SetComboBoxText(ExtraCharSpacingComboBox, IntToStr(NewVal));
      for a := Low(PreviewEdits) to High(PreviewEdits) do
        if PreviewEdits[a] <> Nil then
          PreviewEdits[a].ExtraCharSpacing := NewVal;
    end
    else
    if Sender = ExtraLineSpacingComboBox then
    begin
      NewVal := StrToIntDef(ExtraLineSpacingComboBox.Text,
        PreviewEdits[1].ExtraLineSpacing);
      SetComboBoxText(ExtraLineSpacingComboBox, IntToStr(NewVal));
      for a := Low(PreviewEdits) to High(PreviewEdits) do
        if PreviewEdits[a] <> Nil then
          PreviewEdits[a].ExtraLineSpacing := NewVal;
    end
    else
    if Sender = RightMarginComboBox then
    begin
      NewVal := StrToIntDef(RightMarginComboBox.Text,PreviewEdits[1].RightEdge);
      SetComboBoxText(RightMarginComboBox, IntToStr(NewVal));
      for a := Low(PreviewEdits) to High(PreviewEdits) do
        if PreviewEdits[a] <> Nil then begin
          if VisibleRightMarginCheckBox.Checked then
            PreviewEdits[a].RightEdge := NewVal
          else
            PreviewEdits[a].RightEdge := 0;
        end;
    end
    // color
    else
    if Sender = ColorSchemeComboBox then
    begin
      if Box.Items.IndexOf(Box.Text) < 0 then
        SetComboBoxText(Box, GetCurColorScheme(PreviewSyn.LanguageName))
        // unknown color scheme -> switch back
      else
      if Box.Text <> GetCurColorScheme(PreviewSyn.LanguageName) then
      begin
        // change the colorscheme
        SetCurColorScheme(PreviewSyn.LanguageName, Box.Text);
        SetComboBoxText(Box, Box.Text);
        PreviewSyn := GetHighlighter(TCustomSynClass(PreviewSyn.ClassType),
          Box.Text, True);
        SetPreviewSynInAllPreviews;
        FillColorElementListBox;
        FindCurHighlightElement;
        InvalidatePreviews;
      end;
    end
    else
    if Sender = FileExtensionsComboBox then
    begin
      //DebugLn(['TEditorOptionsForm.ComboBoxOnExit Box.Text="',Box.Text,'" Old="',GetCurFileExtensions(PreviewSyn.LanguageName),'" PreviewSyn.LanguageName=',PreviewSyn.LanguageName]);
      if Box.Text <> GetCurFileExtensions(PreviewSyn.LanguageName) then
      begin
        SetCurFileExtensions(PreviewSyn.LanguageName, Box.Text);
        SetComboBoxText(Box, Box.Text);
      end;
      //DebugLn(['TEditorOptionsForm.ComboBoxOnExit Box.Text="',Box.Text,'" Now="',GetCurFileExtensions(PreviewSyn.LanguageName),'" PreviewSyn.LanguageName=',PreviewSyn.LanguageName]);
    end
    else
    if Sender = LanguageComboBox then
      if Box.Items.IndexOf(Box.Text) < 0 then
        SetComboBoxText(Box, PreviewSyn.LanguageName)// unknown language -> switch back
      else
      if Box.Text <> PreviewSyn.LanguageName then
      begin
        NewVal := EditorOpts.HighlighterList.FindByName(Box.Text);
        if NewVal >= 0 then
        begin
          SetComboBoxText(Box, Box.Text);
          CurLanguageID := NewVal;
          PreviewSyn    := GetHighlighter(
            EditorOpts.HighlighterList[CurLanguageID].SynClass,
            GetCurColorScheme(
            EditorOpts.HighlighterList[
            CurLanguageID].SynClass.GetLanguageName)
            , True);
          SetComboBoxText(ColorSchemeComboBox,
            GetCurColorScheme(PreviewSyn.LanguageName));
          SetComboBoxText(FileExtensionsComboBox,
            GetCurFileExtensions(PreviewSyn.LanguageName));
          for a := Low(PreviewEdits) to High(PreviewEdits) do
            if a <> 3 then begin
              PreviewEdits[a].Lines.Text :=
                EditorOpts.HighlighterList[CurLanguageID].SampleSource;
              PreviewEdits[a].CaretXY := EditorOpts.HighlighterList[CurLanguageID].CaretXY;
              PreviewEdits[a].TopLine := 1;
              PreviewEdits[a].LeftChar := 1;
            end;
          SetPreviewSynInAllPreviews;
          FillColorElementListBox;
          FindCurHighlightElement;
          InvalidatePreviews;
        end;
      end// change language
    // general
  ;
end;

procedure TEditorOptionsForm.ComboBoxOnKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (ssCtrl in Shift) and (Key = VK_S) then
    ComboBoxOnExit(Sender);
end;

procedure TEditorOptionsForm.ComboBoxOnChange(Sender: TObject);
var
  ComboBox: TComboBox;
begin
  ComboBox := TComboBox(Sender);
  if ComboBox.Items.IndexOf(ComboBox.Text) >= 0 then
    ComboBoxOnExit(Sender);
end;

procedure TEditorOptionsForm.FindCurHighlightElement;
var
  a, i: Integer;
  h: TAdditionalHilightAttribute;
  Old:  TSynHighlightElement;
begin
  Old := CurHighlightElement;
  CurHighlightElement := Nil;
  a   := ColorElementListBox.ItemIndex;
  if (a >= 0) then
  begin
    i := PreviewSyn.AttrCount - 1;
    while (i >= 0) do
    begin
      if ColorElementListBox.Items[a] = PreviewSyn.Attribute[i].Name then
      begin
        CurHighlightElement := PreviewSyn.Attribute[i];
        break;
      end;
      dec(i);
    end;
  end;

  if Old <> CurHighlightElement then begin
    CurHighlightElementIsExtra := False;
    for h := Low(TAdditionalHilightAttribute)
    to high(TAdditionalHilightAttribute) do
      if ColorElementListBox.Items[a] = AdditionalHighlightAttributes[h]
        then CurHighlightElementIsExtra := true;
    ShowCurAttribute;
  end;
end;

procedure TEditorOptionsForm.InvalidatePreviews;
var
  a: Integer;
begin
  for a := Low(PreviewEdits) to High(PreviewEdits) do
    if PreviewEdits[a] <> Nil then begin
      EditorOpts.SetMarkupColors(PreviewEdits[a].Highlighter, PreviewEdits[a]);
      PreviewEdits[a].Invalidate;
    end;
end;

procedure TEditorOptionsForm.SetPreviewSynInAllPreviews;
var
  a: Integer;
begin
  for a := Low(PreviewEdits) to High(PreviewEdits) do
    if PreviewEdits[a] <> Nil then
      if EditorOpts.UseSyntaxHighlight then
        PreviewEdits[a].Highlighter := PreviewSyn
      else
        PreviewEdits[a].Highlighter := Nil;
end;

procedure TEditorOptionsForm.ShowCurAttribute;
begin
  if (CurHighlightElement = nil) or UpdatingColor then
    exit;
  UpdatingColor := True;
  
  TextBoldRadioPanel.Visible := CurHighlightElementIsExtra;
  TextItalicRadioPanel.Visible := CurHighlightElementIsExtra;
  TextUnderlineRadioPanel.Visible := CurHighlightElementIsExtra;
  if CurHighlightElementIsExtra then begin
    TextBoldCheckBox.Checked := (fsBold in CurHighlightElement.Style)
      or (fsBold in CurHighlightElement.StyleMask);
    TextBoldRadioPanel.Enabled := TextBoldCheckBox.Checked;
    if not(fsBold in CurHighlightElement.StyleMask)
    then TextBoldRadioInvert.Checked := True
    else if fsBold in CurHighlightElement.Style
    then TextBoldRadioOn.Checked := True
    else TextBoldRadioOff.Checked := True;

    TextItalicCheckBox.Checked := (fsItalic in CurHighlightElement.Style)
      or (fsItalic in CurHighlightElement.StyleMask);
    TextItalicRadioPanel.Enabled := TextItalicCheckBox.Checked;
    if not(fsItalic in CurHighlightElement.StyleMask)
    then TextItalicRadioInvert.Checked := True
    else if fsItalic  in CurHighlightElement.Style
    then TextItalicRadioOn.Checked := True
    else TextItalicRadioOff.Checked := True;

    TextUnderlineCheckBox.Checked := (fsUnderline in CurHighlightElement.Style)
      or (fsUnderline in CurHighlightElement.StyleMask);
    TextUnderlineRadioPanel.Enabled := TextUnderlineCheckBox.Checked;
    if not(fsUnderline in CurHighlightElement.StyleMask)
    then TextUnderlineRadioInvert.Checked := True
    else if fsUnderline in CurHighlightElement.Style
    then TextUnderlineRadioOn.Checked := True
    else TextUnderlineRadioOff.Checked := True;
  end else begin
    TextBoldCheckBox.Checked := fsBold in CurHighlightElement.Style;
    TextItalicCheckBox.Checked := fsItalic in CurHighlightElement.Style;
    TextUnderlineCheckBox.Checked := fsUnderline in CurHighlightElement.Style;
  end;


  if CurHighlightElement.Foreground = clNone then
    ForeGroundUseDefaultCheckBox.Checked := True
  else
  begin
    ForeGroundUseDefaultCheckBox.Checked := False;
    ForeGroundColorButton.ButtonColor    := CurHighlightElement.Foreground;
  end;
  ForeGroundColorButton.Visible := not ForeGroundUseDefaultCheckBox.Checked;
  if CurHighlightElement.Background = clNone then
    BackGroundUseDefaultCheckBox.Checked := True
  else
  begin
    BackGroundUseDefaultCheckBox.Checked := False;
    BackGroundColorButton.ButtonColor    := CurHighlightElement.Background;
  end;
  BackGroundColorButton.Visible := not BackGroundUseDefaultCheckBox.Checked;
  UpdatingColor := False;
end;

procedure TEditorOptionsForm.KeyMappingTreeViewMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  i: Integer;
  ARelation: TKeyCommandRelation;
  ANode: TTreeNode;
begin
  ANode := KeyMappingTreeView.GetNodeAt(X, Y);
  if (ANode <> Nil) and (ANode.Data <> Nil) and
    (TObject(ANode.Data) is TKeyCommandRelation) then
  begin
    ARelation := TKeyCommandRelation(ANode.Data);
    i := EditingKeyMap.IndexOf(ARelation);
    if (i >= 0) and (ShowKeyMappingEditForm(i, EditingKeyMap) = mrOk) then
    begin
      FillKeyMappingTreeView;
      for i := Low(PreviewEdits) to High(PreviewEdits) do
        if PreviewEdits[i] <> Nil then
          EditingKeyMap.AssignTo(PreviewEdits[i].KeyStrokes,
            TSourceEditorWindowInterface);
    end;
  end;
end;

type
  TKeyMapErrorsForm = class(TForm)
    ListBox: TListBox;
    BackButton: TButton;
    procedure BackButtonClick(Sender: TObject);
  public
    constructor Create(AnOwner: TComponent); override;
  end;

constructor TKeyMapErrorsForm.Create(AnOwner: TComponent);
begin
  inherited Create(AnOwner);
  if LazarusResources.Find(ClassName) = Nil then
  begin
    SetBounds((Screen.Width - 410) div 2, (Screen.Height - 260) div 2, 400, 250);
    Caption := dlgKeyMappingErrors;

    ListBox := TListBox.Create(Self);
    with ListBox do
    begin
      Name := 'ListBox';
      Align:=alTop;
      Parent := Self;
    end;

    BackButton := TButton.Create(Self);
    with BackButton do
    begin
      Name := 'BackButton';
      AutoSize:=true;
      Anchors:=[akBottom];
      Parent := Self;
      AnchorParallel(akBottom,6,Self);
      Caption := dlgEdBack;
      OnClick := @BackButtonClick;
    end;
    ListBox.AnchorToNeighbour(akBottom,6,BackButton);
  end;
end;

procedure TKeyMapErrorsForm.BackButtonClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TEditorOptionsForm.KeyMappingConsistencyCheckButtonClick(
  Sender: TObject);
var
  Protocol: TStringList;
  ErrorCount, Index1, Index2: Integer;
  ACaption, AText: String;
  KeyMapErrorsForm: TKeyMapErrorsForm;
begin
  Protocol := TStringList.Create;
  try
    ErrorCount := FindKeymapConflicts(EditingKeyMap, Protocol, Index1, Index2);
    if ErrorCount > 0 then
    begin
      KeyMapErrorsForm := TKeyMapErrorsForm.Create(Nil);
      try
        KeyMapErrorsForm.ListBox.Items.Assign(Protocol);
        KeyMapErrorsForm.ShowModal;
      finally
        KeyMapErrorsForm.Free;
      end;
    end
    else
    begin
      ACaption := dlgReport;
      AText    := dlgEdNoErr;
      MessageDlg(ACaption, AText, mtInformation, [mbOk], 0);
    end;
  finally
    Protocol.Free;
  end;
end;

procedure TEditorOptionsForm.ColorElementListBoxSelectionChange(
  Sender: TObject;
  User: Boolean);
begin
  FindCurHighlightElement;
end;

procedure TEditorOptionsForm.FillColorElementListBox;
var
  i: Integer;
begin
  with ColorElementListBox.Items do
  begin
    BeginUpdate;
    Clear;

    for i := 0 to PreviewSyn.AttrCount - 1 do
      if PreviewSyn.Attribute[i].Name <> '' then
        Add(PreviewSyn.Attribute[i].Name);
    EndUpdate;
  end;

  CurHighlightElement := Nil;
  CurHighlightElementIsExtra := False;
  if ColorElementListBox.Items.Count > 0 then
    ColorElementListBox.Selected[0] := True;
  FindCurHighlightElement;
end;

procedure TEditorOptionsForm.ColorPreviewMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  NewIndex: Integer;
  Token:    String;
  Attri:    TSynHighlightElement;
  MouseXY, XY: TPoint;
  AddAttr:  TAdditionalHilightAttribute;
begin
  MouseXY := Point(X, Y);
  XY      := ColorPreview.PixelsToRowColumn(MouseXY);
  NewIndex := -1;
  if CurLanguageID >= 0 then
  begin
    AddAttr := EditorOpts.HighlighterList[
      CurLanguageID].SampleLineToAddAttr(XY.Y);
    if AddAttr <> ahaNone then
      NewIndex := ColorElementListBox.Items.IndexOf(
        AdditionalHighlightAttributes[AddAttr]);
  end;
  if NewIndex < 0 then
  begin
    Token:='';
    Attri:=nil;
    ColorPreview.GetHighlighterAttriAtRowCol(XY, Token, Attri);
    if Attri = Nil then
      Attri := PreviewSyn.WhitespaceAttribute;
    if Attri <> Nil then
      NewIndex := ColorElementListBox.Items.IndexOf(Attri.Name);
  end;
  if NewIndex >= 0 then
  begin
    ColorElementListBox.ItemIndex := NewIndex;
    FindCurHighlightElement;
  end;
end;

procedure TEditorOptionsForm.OnSpecialLineColors(Sender: TObject;
  Line: Integer; var Special: boolean; aMarkup: TSynSelectedColor);
var
  e: TSynHighlightElement;
  AddAttr: TAdditionalHilightAttribute;
  i: Integer;
begin
  if CurLanguageID >= 0 then
  begin
    AddAttr := EditorOpts.HighlighterList[CurLanguageID].SampleLineToAddAttr(Line);
    if AddAttr <> ahaNone then
    begin
      i := PreviewSyn.AttrCount - 1;
      while (i >= 0) do
      begin
        e := PreviewSyn.Attribute[i];
        if e.Name = '' then
          continue;
        if e.Name = AdditionalHighlightAttributes[AddAttr] then
        begin
          Special := True;
          EditorOpts.SetMarkupColor(PreviewSyn, AddAttr, aMarkup);
          exit;
        end;
        dec(i);
      end;
    end;
  end;
end;

procedure TEditorOptionsForm.RightMarginColorButtonColorChanged(Sender: TObject);
var
  a: Integer;
begin
  for a := Low(PreviewEdits) to High(PreviewEdits) do
    if PreviewEdits[a] <> Nil then
      PreviewEdits[a].RightEdgeColor:=RightMarginColorButton.ButtonColor;
end;

procedure TEditorOptionsForm.SetAttributeToDefaultButtonClick(Sender: TObject);
begin
  SetColorElementsToDefaults(True);
end;

procedure TEditorOptionsForm.SetAllAttributesToDefaultButtonClick(
  Sender: TObject);
begin
  SetColorElementsToDefaults(False);
end;

procedure TEditorOptionsForm.SetColorElementsToDefaults(OnlySelected: Boolean);
var
  DefaultSyn: TSrcIDEHighlighter;
  PascalSyn: TPreviewPasSyn;
  i, j: Integer;
  CurSynClass: TCustomSynClass;
begin
  PascalSyn := TPreviewPasSyn(GetHighlighter(TPreviewPasSyn,
    ColorSchemeComboBox.Text, True));
  CurSynClass := TCustomSynClass(PreviewSyn.ClassType);
  DefaultSyn := CurSynClass.Create(Nil);
  try
    EditorOpts.AddSpecialHilightAttribsToHighlighter(DefaultSyn);
    EditorOpts.ReadDefaultsForHighlighterSettings(DefaultSyn,
      ColorSchemeComboBox.Text, PascalSyn);
    for i := 0 to DefaultSyn.AttrCount - 1 do
    begin
      if DefaultSyn.Attribute[i].Name = '' then
        continue;
      if OnlySelected then
      begin
        if (DefaultSyn.Attribute[i].Name = CurHighlightElement.Name) then
          CopyHiLightAttributeValues(DefaultSyn.Attribute[i],
            CurHighlightElement);
      end
      else
        for j := 0 to PreviewSyn.AttrCount - 1 do
          if PreviewSyn.Attribute[j].Name = DefaultSyn.Attribute[i].Name then
            CopyHiLightAttributeValues(DefaultSyn.Attribute[i],
              PreviewSyn.Attribute[j]);
    end;
  finally
    DefaultSyn.Free;
  end;
  ShowCurAttribute;
end;

function TEditorOptionsForm.GetCurColorScheme(
  const LanguageName: String): String;
begin
  if fColorSchemes = Nil then
    Result := ''
  else
    Result := fColorSchemes.Values[LanguageName];
  if Result = '' then
    Result := EditorOpts.ReadColorScheme(LanguageName);
end;

procedure TEditorOptionsForm.SetCurColorScheme(
  const LanguageName, ColorScheme: String);
begin
  if fColorSchemes = Nil then
    fColorSchemes := TStringList.Create;
  fColorSchemes.Values[LanguageName] := ColorScheme;
end;

procedure TEditorOptionsForm.SaveAllColorSchemes;
var
  i: Integer;
begin
  if fColorSchemes = Nil then
    exit;
  for i := 0 to fColorSchemes.Count - 1 do
    EditorOpts.WriteColorScheme(fColorSchemes.Names[i],
      fColorSchemes.Values[fColorSchemes.Names[i]]);
end;

function TEditorOptionsForm.GetCurFileExtensions(
  const LanguageName: String): String;
var
  i: Integer;
begin
  if fFileExtensions = Nil then
    Result := ''
  else
    Result := fFileExtensions.Values[LanguageName];
  if Result = '' then
  begin
    i := EditorOpts.HighlighterList.FindByName(LanguageName);
    if i >= 0 then
      Result := EditorOpts.HighlighterList[i].FileExtensions;
  end;
end;

procedure TEditorOptionsForm.SetCurFileExtensions(
  const LanguageName, FileExtensions: String);
begin
  if fFileExtensions = Nil then
    fFileExtensions := TStringList.Create;
  fFileExtensions.Values[LanguageName] := FileExtensions;
  //DebugLn(['TEditorOptionsForm.SetCurFileExtensions ',LanguageName,'=',FileExtensions]);
end;

procedure TEditorOptionsForm.SaveAllFileExtensions;
var
  i, j: Integer;
begin
  if fFileExtensions = Nil then
    exit;
  for i := 0 to fFileExtensions.Count - 1 do
  begin
    j := EditorOpts.HighlighterList.FindByName(fFileExtensions.Names[i]);
    if j >= 0 then begin
      EditorOpts.HighlighterList[j].FileExtensions :=
        fFileExtensions.ValueFromIndex[i];
      //DebugLn(['TEditorOptionsForm.SaveAllFileExtensions ',fFileExtensions.Names[i],'=',fFileExtensions.ValueFromIndex[i],' -> ',EditorOpts.HighlighterList[j].FileExtensions]);
    end;
  end;
end;

function TEditorOptionsForm.GetHighlighter(SynClass: TCustomSynClass;
  const ColorScheme: String; CreateIfNotExists: Boolean): TSrcIDEHighlighter;
var
  i: Integer;
begin
  if fHighlighterList = Nil then
    fHighlighterList := TStringList.Create;
  for i := 0 to fHighlighterList.Count - 1 do
    if (fHighlighterList[i] = ColorScheme) and
      (TCustomSynClass(TSrcIDEHighlighter(fHighlighterList.Objects[i]).ClassType) =
      SynClass) then
    begin
      Result := TSrcIDEHighlighter(fHighlighterList.Objects[i]);
      exit;
    end;
  if CreateIfNotExists then
  begin
    Result := SynClass.Create(Nil);
    EditorOpts.AddSpecialHilightAttribsToHighlighter(Result);
    fHighlighterList.AddObject(ColorScheme, Result);
    EditorOpts.ReadHighlighterSettings(Result, ColorScheme);
  end;
end;

procedure TEditorOptionsForm.ClearHighlighters;
var
  i: Integer;
begin
  if fHighlighterList = Nil then
    exit;
  for i := 0 to fHighlighterList.Count - 1 do
    TSrcIDEHighlighter(fHighlighterList.Objects[i]).Free;
  fHighlighterList.Free;
end;

procedure TEditorOptionsForm.SaveAllHighlighters;
var
  i: Integer;
  Syn: TSrcIDEHighlighter;
begin
  if fHighlighterList = Nil then
    exit;
  for i := 0 to fHighlighterList.Count - 1 do
  begin
    Syn := TSrcIDEHighlighter(fHighlighterList.Objects[i]);
    EditorOpts.WriteHighlighterSettings(Syn, fHighlighterList[i]);
  end;
end;

// keymapping ------------------------------------------------------------------

function TEditorOptionsForm.KeyMappingRelationToString(Index: Integer): String;
begin
  Result := KeyMappingRelationToString(EditingKeyMap.Relations[Index]);
end;

function TEditorOptionsForm.KeyMappingRelationToString(
  KeyRelation: TKeyCommandRelation): String;
var
  s: String;
  CopiedLength: Integer;
begin
  with KeyRelation do
  begin
    Result := UTF8Copy(LocalizedName, 1, 40);
    CopiedLength := UTF8Length(Result);
    if CopiedLength < 40 then
    begin
      SetLength(s, (40 - CopiedLength));
      FillChar(s[1], length(s), ' ');
    end
    else
      s := '';
    Result := Result + s;
    if (ShortcutA.Key1 = VK_UNKNOWN) and (ShortcutB.Key1 = VK_UNKNOWN) then
      Result := Result + lisNone2
    else
    if (ShortcutA.Key1 = VK_UNKNOWN) then
      Result := Result + KeyAndShiftStateToEditorKeyString(ShortcutB)
    else
    if (ShortcutB.Key1 = VK_UNKNOWN) then
      Result := Result + KeyAndShiftStateToEditorKeyString(ShortcutA)
    else
      Result := Result + KeyAndShiftStateToEditorKeyString(ShortcutA)
                       + '  '+lisOr+'  ' +
                         KeyAndShiftStateToEditorKeyString(ShortcutB);
  end;
end;

procedure TEditorOptionsForm.FillKeyMappingTreeView;
var
  i, j: Integer;
  NewCategoryNode, NewKeyNode: TTreeNode;
  CurCategory: TIDECommandCategory;
  CurKeyRelation: TKeyCommandRelation;
  ChildNodeIndex: Integer;
  CategoryNodeIndex: Integer;
  HasFilter: Boolean;
  ItemCaption: String;
  NameFilterUp: String;
begin
  HasFilter:=(KeyMapNameFilter<>'');
  NameFilterUp:=uppercase(KeyMapNameFilter);
  with KeyMappingTreeView do
  begin
    BeginUpdate;
    CategoryNodeIndex:=0;
    for i := 0 to EditingKeyMap.CategoryCount - 1 do
    begin
      CurCategory := EditingKeyMap.Categories[i];
      if Items.TopLvlCount > CategoryNodeIndex then
      begin
        NewCategoryNode := Items.TopLvlItems[CategoryNodeIndex];
        NewCategoryNode.Text := CurCategory.Description;
        NewCategoryNode.Data := CurCategory;
      end
      else
        NewCategoryNode := Items.AddObject(Nil, CurCategory.Description, CurCategory);
      NewCategoryNode.ImageIndex := imgKeyCategory;
      NewCategoryNode.SelectedIndex := NewCategoryNode.ImageIndex;
      ChildNodeIndex:=0;
      for j := 0 to CurCategory.Count - 1 do
      begin
        CurKeyRelation := TKeyCommandRelation(CurCategory[j]);
        ItemCaption:=KeyMappingRelationToString(CurKeyRelation);
        if (NameFilterUp<>'')
        and (System.Pos(NameFilterUp,UpperCase(ItemCaption))=0) then
          continue;
        if (KeyMapKeyFilter.Key1<>VK_UNKNOWN)
        and (CompareIDEShortCutKey1s(@KeyMapKeyFilter,@CurKeyRelation.ShortcutA)<>0)
        and (CompareIDEShortCutKey1s(@KeyMapKeyFilter,@CurKeyRelation.ShortcutB)<>0)
        then
          continue;
        if NewCategoryNode.Count > ChildNodeIndex then
        begin
          NewKeyNode := NewCategoryNode.Items[ChildNodeIndex];
          NewKeyNode.Text := ItemCaption;
          NewKeyNode.Data := CurKeyRelation;
        end
        else
          NewKeyNode := Items.AddChildObject(NewCategoryNode,
            ItemCaption, CurKeyRelation);
        NewKeyNode.ImageIndex := imgKeyItem;
        NewKeyNode.SelectedIndex := NewKeyNode.ImageIndex;
        inc(ChildNodeIndex);
      end;
      // delete unneeded ones
      while NewCategoryNode.Count > ChildNodeIndex do
        NewCategoryNode[NewCategoryNode.Count - 1].Delete;
      if NewCategoryNode.Count>0 then begin
        if HasFilter then
          NewCategoryNode.Expanded:=true;
        inc(CategoryNodeIndex);
      end;
    end;
    while Items.TopLvlCount > CategoryNodeIndex do
      Items.TopLvlItems[Items.TopLvlCount - 1].Delete;
    EndUpdate;
  end;
end;

// useful functions

procedure TEditorOptionsForm.SetComboBoxText(AComboBox: TComboBox;
  const AText: String);
var
  a: Integer;
begin
  a := AComboBox.Items.IndexOf(AText);
  if a >= 0 then begin
    AComboBox.ItemIndex := a;
  end else
  begin
    AComboBox.Items.Add(AText);
    AComboBox.ItemIndex := AComboBox.Items.IndexOf(AText);
  end;
end;

procedure TEditorOptionsForm.SetupGeneralPage(Page: Integer);
begin
  MainNoteBook.Page[Page].Caption := lisMenuInsertGeneral;

  EditorOptionsGroupBox.Caption := lismenueditoroptions;

  with EditorOptionsGroupBox do
  begin
    // selections
    Items.Add(dlgAltSetClMode);
    Items.Add(dlgAutoIdent);
    // visual effects
    Items.Add(dlgBracHighlight);
    Items.Add(dlgShowGutterHints);
    //Items.Add(dlgShowScrollHint);
    Items.Add(lisShowSpecialCharacters);
    Items.Add(dlgUseSyntaxHighlight);
    // drag&drop
    Items.Add(dlgDragDropEd);
    Items.Add(dlgDropFiles);
    // caret + scrolling + key navigation
    Items.Add(dlgHalfPageScroll);
    Items.Add(dlgKeepCursorX);
    Items.Add(dlgPersistentCursor);
    Items.Add(dlgCursorSkipsSelection);
    Items.Add(dlgRightMouseMovesCursor);
    Items.Add(dlgScrollByOneLess);
    Items.Add(dlgScrollPastEndFile);
    Items.Add(dlgScrollPastEndLine);
    Items.Add(dlgHomeKeyJumpsToNearestStart);
    Items.Add(dlgAlwaysVisibleCursor);
    // tabs
    Items.Add(dlgSmartTabs);
    Items.Add(dlgTabsToSpaces);
    Items.Add(dlgTabIndent);
    // spaces
    Items.Add(dlgTrimTrailingSpaces);
    // undo
    Items.Add(dlgUndoAfterSave);
    Items.Add(dlgGroupUndo);
    // mouse
    Items.Add(dlgDoubleClickLine);
    Items.Add(dlgMouseLinks);
    Items.Add(dlgCloseButtonsNotebook);
    // copying
    Items.Add(dlgFindTextatCursor);
    Items.Add(dlgCopyWordAtCursorOnCopyNone);

    Checked[Items.IndexOf(dlgAltSetClMode)] := eoAltSetsColumnMode in
                                                      EditorOpts.SynEditOptions;
    Checked[Items.IndexOf(dlgAutoIdent)]    := eoAutoIndent in EditorOpts.SynEditOptions;
    Checked[Items.IndexOf(dlgBracHighlight)] :=
                                eoBracketHighlight in EditorOpts.SynEditOptions;
    Checked[Items.IndexOf(dlgDragDropEd)]   :=
                                 eoDragDropEditing in EditorOpts.SynEditOptions;
    Checked[Items.IndexOf(dlgDropFiles)]    := eoDropFiles in EditorOpts.SynEditOptions;
    //TODO CheckEnabledByName[dlgDropFiles] := False;
    Checked[Items.IndexOf(dlgGroupUndo)] := eoGroupUndo in EditorOpts.SynEditOptions;
    Checked[Items.IndexOf(dlgHalfPageScroll)] :=
                                  eoHalfPageScroll in EditorOpts.SynEditOptions;
    Checked[Items.IndexOf(dlgKeepCursorX)] := eoKeepCaretX in EditorOpts.SynEditOptions;
    Checked[Items.IndexOf(dlgPersistentCursor)] :=
                                 eoPersistentCaret in EditorOpts.SynEditOptions;
    Checked[Items.IndexOf(dlgRightMouseMovesCursor)] :=
                           eoRightMouseMovesCursor in EditorOpts.SynEditOptions;
    Checked[Items.IndexOf(dlgScrollByOneLess)] :=
                                 eoScrollByOneLess in EditorOpts.SynEditOptions;
    Checked[Items.IndexOf(dlgScrollPastEndFile)] :=
                                   eoScrollPastEoF in EditorOpts.SynEditOptions;
    Checked[Items.IndexOf(dlgMouseLinks)]   := EditorOpts.CtrlMouseLinks;
    Checked[Items.IndexOf(dlgShowGutterHints)] := EditorOpts.ShowGutterHints;
    Checked[Items.IndexOf(dlgScrollPastEndLine)] :=
                                   eoScrollPastEoL in EditorOpts.SynEditOptions;
    Checked[Items.IndexOf(dlgCloseButtonsNotebook)] := EditorOpts.ShowTabCloseButtons;
    //Checked[Items.IndexOf(dlgShowScrollHint)] :=
    //                              eoShowScrollHint in EditorOpts.SynEditOptions;
    Checked[Items.IndexOf(lisShowSpecialCharacters)] :=
                                eoShowSpecialChars in EditorOpts.SynEditOptions;
    Checked[Items.IndexOf(dlgSmartTabs)] := eoSmartTabs in EditorOpts.SynEditOptions;
    //DebugLn(['TEditorOptionsForm.SetupGeneralPage ',Checked[Items.IndexOf(dlgSmartTabs)],' ',Items.IndexOf(dlgSmartTabs),' ',eoSmartTabs in EditorOpts.SynEditOptions]);
    Checked[Items.IndexOf(dlgTabsToSpaces)] :=
                                    eoTabsToSpaces in EditorOpts.SynEditOptions;
    Checked[Items.IndexOf(dlgTabIndent)]    := eoTabIndent in EditorOpts.SynEditOptions;
    Checked[Items.IndexOf(dlgTrimTrailingSpaces)] :=
                              eoTrimTrailingSpaces in EditorOpts.SynEditOptions;
    Checked[Items.IndexOf(dlgUndoAfterSave)] := EditorOpts.UndoAfterSave;
    Checked[Items.IndexOf(dlgDoubleClickLine)] :=
                          eoDoubleClickSelectsLine in EditorOpts.SynEditOptions;
    Checked[Items.IndexOf(dlgFindTextatCursor)] := EditorOpts.FindTextAtCursor;
    Checked[Items.IndexOf(dlgUseSyntaxHighlight)] := EditorOpts.UseSyntaxHighlight;
    Checked[Items.IndexOf(dlgCopyWordAtCursorOnCopyNone)] :=
                                          EditorOpts.CopyWordAtCursorOnCopyNone;
    Checked[Items.IndexOf(dlgHomeKeyJumpsToNearestStart)] :=
                                  eoEnhanceHomeKey in EditorOpts.SynEditOptions;
    Checked[Items.IndexOf(dlgCursorSkipsSelection)] :=
                            eoCaretSkipsSelection in EditorOpts.SynEditOptions2;
    Checked[Items.IndexOf(dlgAlwaysVisibleCursor)] :=
                             eoAlwaysVisibleCaret in EditorOpts.SynEditOptions2;
  end;

  with BlockIndentComboBox do
    SetComboBoxText(BlockIndentComboBox, IntToStr(EditorOpts.BlockIndent));

  BlockIndentLabel.Caption := dlgBlockIndent;

  with UndoLimitComboBox do
    SetComboBoxText(UndoLimitComboBox, IntToStr(EditorOpts.UndoLimit));

  UndoLimitLabel.Caption := dlgUndoLimit;

  with TabWidthsComboBox do
    SetComboBoxText(TabWidthsComboBox, IntToStr(EditorOpts.TabWidth));

  TabWidthsLabel.Caption := dlgTabWidths;
end;

procedure TEditorOptionsForm.SetupDisplayPage(Page: Integer);
begin
  MainNoteBook.Page[Page].Caption := dlgEdDisplay;

  MarginAndGutterGroupBox.Caption := dlgMarginGutter;

  with VisibleRightMarginCheckBox do
  begin
    Caption := dlgVisibleRightMargin;
    Checked := EditorOpts.VisibleRightMargin;
  end;

  with VisibleGutterCheckBox do
  begin
    Caption := dlgVisibleGutter;
    Checked := EditorOpts.VisibleGutter;
  end;

  with ShowLineNumbersCheckBox do
  begin
    Caption := dlgShowLineNumbers;
    Checked := EditorOpts.ShowLineNumbers;
  end;

  ShowOnlyLineNumbersMultiplesOfLabel.Caption := lisEveryNThLineNumber;
  ShowOnlyLineNumbersMultiplesOfLabel.Enabled := ShowLineNumbersCheckBox.Checked;
  ShowOnlyLineNumbersMultiplesOfSpinEdit.Value := EditorOpts.ShowOnlyLineNumbersMultiplesOf;
  ShowOnlyLineNumbersMultiplesOfSpinEdit.Enabled := ShowLineNumbersCheckBox.Checked;

  RightMarginLabel.Caption := dlgRightMargin;

  VisibleRightMarginCheckBox.Checked:=EditorOpts.VisibleRightMargin;
  with RightMarginComboBox do
    SetComboBoxText(RightMarginComboBox, IntToStr(EditorOpts.RightMargin));

  RightMarginColorLabel.Caption := dlgRightMarginColor;

  RightMarginColorButton.ButtonColor := EditorOpts.RightMarginColor;

  GutterColorLabel.Caption := dlgGutterColor;

  GutterColorButton.ButtonColor := EditorOpts.GutterColor;

  EditorFontGroupBox.Caption := dlgDefaultEditorFont;

  with EditorFontComboBox do
    SetComboBoxText(EditorFontComboBox, EditorOpts.EditorFont);

  with EditorFontHeightComboBox do
    SetComboBoxText(EditorFontHeightComboBox,IntToStr(EditorOpts.EditorFontHeight));

  EditorFontHeightLabel.Caption := dlgEditorFontHeight;

  SetComboBoxText(ExtraCharSpacingComboBox,IntToStr(EditorOpts.ExtraCharSpacing));
  ExtraCharSpacingLabel.Caption := dlgExtraCharSpacing;
  SetComboBoxText(ExtraLineSpacingComboBox,IntToStr(EditorOpts.ExtraLineSpacing));
  ExtraLineSpacingLabel.Caption := dlgExtraLineSpacing;
  DisableAntialiasingCheckBox.Checked := EditorOpts.DisableAntialiasing;
  DisableAntialiasingCheckBox.Caption := dlgDisableAntialiasing;
end;

procedure TEditorOptionsForm.SetupKeyMappingsPage(Page: Integer);
begin
  MainNoteBook.Page[Page].Caption := dlgKeyMapping;

  KeyMappingChooseSchemeButton.Caption := lisEdOptsChooseScheme;

  KeyMappingConsistencyCheckButton.Caption := dlgCheckConsistency;

  KeyMappingHelpLabel.Caption := dlgEdHintCommand;
  KeyMappingFilterEdit.Text:=lisFilter2;
  KeyMappingFindKeyButton.Caption:=lisFindKeyCombination;
  KeyMappingTreeView.Images := IDEImages.Images_16;
  imgKeyCategory := IDEImages.LoadImage(16, 'item_keyboard');
  imgKeyItem := IDEImages.LoadImage(16, 'item_character');
end;

procedure TEditorOptionsForm.SetupColorPage(Page: Integer);
var
  a: Integer;
begin
  MainNoteBook.Page[Page].Caption := dlgEdColor;

  LanguageLabel.Caption := dlgLang;

  with LanguageComboBox do
    with Items do
    begin
      BeginUpdate;
      for a := 0 to EditorOpts.HighlighterList.Count - 1 do
        Add(EditorOpts.HighlighterList[a].SynClass.GetLanguageName);
      //for a:=0 to EditorOpts.HighlighterList.Count-1 do
      //  writeln('TEditorOptionsForm.SetupColorPage ',a,' ',EditorOpts.HighlighterList[a].SynClass.GetLanguageName
      //  ,' ',EditorOpts.HighlighterList[a].SynClass.ClassName);
      EndUpdate;
    end;

  ColorSchemeLabel.Caption := dlgClrScheme;

  with ColorSchemeComboBox do
  begin
    with Items do
    begin
      BeginUpdate;
      // ToDo: fill also with custom color schemes
      Add(DEFAULT_COLOR_SCHEME.Name);
      Add(DELPHI_COLOR_SCHEME.Name);
      Add(CLASSIC_COLOR_SCHEME.Name);
      Add(TWILIGHT_COLOR_SCHEME.Name);
      Add(OCEAN_COLOR_SCHEME.Name);
      EndUpdate;
    end;
    Text := DEFAULT_COLOR_SCHEME.Name;
  end;

  FileExtensionsLabel.Caption := dlgFileExts;

  with FileExtensionsComboBox do
    if CurLanguageID >= 0 then
      SetComboBoxText(FileExtensionsComboBox,
        EditorOpts.HighlighterList[CurLanguageID].FileExtensions);

  ColorElementLabel.Caption := dlgEdElement;

  SetAttributeToDefaultButton.Caption := dlgSetElementDefault;

  SetAllAttributesToDefaultButton.Caption := dlgSetAllElementDefault;

  ForeGroundLabel.Caption := dlgForecolor;

  ForeGroundUseDefaultCheckBox.Caption := dlgEdUseDefColor;

  BackGroundLabel.Caption := dlgBackColor;

  BackgroundColorButton.Color := clBlue;

  BackGroundUseDefaultCheckBox.Caption := dlgEdUseDefColor;

  TextAttributesGroupBox.Caption := dlgTextAttributes;

  TextBoldCheckBox.Caption := dlgEdBold;
  TextBoldRadioOn.Caption := dlgEdOn;
  TextBoldRadioOff.Caption := dlgEdOff;
  TextBoldRadioInvert.Caption := dlgEdInvert;

  TextItalicCheckBox.Caption := dlgEdItal;
  TextItalicRadioOn.Caption := dlgEdOn;
  TextItalicRadioOff.Caption := dlgEdOff;
  TextItalicRadioInvert.Caption := dlgEdInvert;

  TextUnderlineCheckBox.Caption := dlgEdUnder;
  TextUnderlineRadioOn.Caption := dlgEdOn;
  TextUnderlineRadioOff.Caption := dlgEdOff;
  TextUnderlineRadioInvert.Caption := dlgEdInvert;
end;

procedure TEditorOptionsForm.SetupCodeToolsPage(Page: Integer);
begin
  MainNoteBook.Page[Page].Caption := dlgCodeToolsTab;

  AutomaticFeaturesGroupBox.Caption := lisAutomaticFeatures;

  with AutoIdentifierCompletionCheckBox do
  begin
    Caption := dlgEdIdComlet;
    Checked := EditorOpts.AutoIdentifierCompletion;
  end;

  with AutoCodeParametersCheckBox do
  begin
    Caption := dlgEdCodeParams;
    Checked := EditorOpts.AutoCodeParameters;
  end;

  with AutoToolTipExprEvalCheckBox do
  begin
    Caption := dlgTooltipEval;
    Checked := EditorOpts.AutoToolTipExprEval;
  end;

  with AutoToolTipSymbToolsCheckBox do
  begin
    Caption := dlgTooltipTools;
    Checked := EditorOpts.AutoToolTipSymbTools;
  end;

  AutoDelayLabel.Caption := dlgEdDelay;
  AutoDelayTrackBar.Position := EditorOpts.AutoDelayInMSec;
  AutoDelayMinLabel.Caption := '0.5 ' + DlgTimeSecondUnit;
  AutoDelayMaxLabel.Caption := '4.0 ' + dlgTimeSecondUnit;
end;

procedure TEditorOptionsForm.SetupCodeFoldingPage(Page: integer);
begin
  MainNoteBook.Page[Page].Caption := dlgUseCodeFolding;
  chkCodeFoldingEnabled.Caption   := dlgUseCodeFolding;
  lblDividerDrawLevel.Caption     := dlgCFDividerDrawLevel + ':';
  
  chkCodeFoldingEnabled.Checked   := EditorOpts.UseCodeFolding;
  edDividerDrawLevel.Value        := EditorOpts.CFDividerDrawLevel;
end;

procedure TEditorOptionsForm.SetupButtonBar;
begin
  ButtonPanel.OKButton.OnClick := @OKButtonClick;
  ButtonPanel.CancelButton.OnClick := @CancelButtonClick;
  ButtonPanel.HelpButton.OnClick := @HelpButtonClick;
end;

procedure TEditorOptionsForm.OkButtonClick(Sender: TObject);
var
  i: Integer;
begin
  IDEDialogLayoutList.SaveLayout(Self);

  // save all values
  EditorOpts.KeyMap.Assign(EditingKeyMap);
  EditorOpts.SetSynEditSettings(PreviewEdits[3]);

  // general
  EditorOpts.ShowTabCloseButtons :=
    CheckGroupItemChecked(EditorOptionsGroupBox,dlgCloseButtonsNotebook);
  EditorOpts.UndoAfterSave :=
    CheckGroupItemChecked(EditorOptionsGroupBox,dlgUndoAfterSave);
  EditorOpts.CopyWordAtCursorOnCopyNone :=
    CheckGroupItemChecked(EditorOptionsGroupBox,dlgCopyWordAtCursorOnCopyNone);
  EditorOpts.ShowGutterHints :=
    CheckGroupItemChecked(EditorOptionsGroupBox,dlgShowGutterHints);
  EditorOpts.FindTextAtCursor :=
    CheckGroupItemChecked(EditorOptionsGroupBox,dlgFindTextatCursor);
  EditorOpts.UseSyntaxHighlight :=
    CheckGroupItemChecked(EditorOptionsGroupBox,dlgUseSyntaxHighlight);
  EditorOpts.CtrlMouseLinks :=
    CheckGroupItemChecked(EditorOptionsGroupBox,dlgMouseLinks);
  i := StrToIntDef(UndoLimitComboBox.Text, 32767);
  if i < 1 then
    i := 1;
  if i > 32767 then
    i := 32767;
  EditorOpts.UndoLimit := i;
  i := StrToIntDef(TabWidthsComboBox.Text, 2);
  if i < 1 then
    i := 1;
  if i > 20 then
    i := 20;
  EditorOpts.TabWidth := i;
  i := StrToIntDef(BlockIndentComboBox.Text, 2);
  if i < 1 then
    i := 1;
  if i > 20 then
    i := 20;
  EditorOpts.BlockIndent := i;


  // color
  SaveAllFileExtensions;
  SaveAllColorSchemes;
  SaveAllHighlighters;

  // code Tools
  EditorOpts.AutoIdentifierCompletion :=
    AutoIdentifierCompletionCheckBox.Checked;
  EditorOpts.AutoCodeParameters := AutoCodeParametersCheckBox.Checked;
  EditorOpts.AutoToolTipExprEval := AutoToolTipExprEvalCheckBox.Checked;
  EditorOpts.AutoToolTipSymbTools := AutoToolTipSymbToolsCheckBox.Checked;
  EditorOpts.AutoDelayInMSec    := AutoDelayTrackBar.Position;

  // Code Folding
  EditorOpts.UseCodeFolding       := chkCodeFoldingEnabled.Checked;
  EditorOpts.CFDividerDrawLevel   := edDividerDrawLevel.Value;
  
  EditorOpts.Save;
  ModalResult := mrOk;
end;

procedure TEditorOptionsForm.CancelButtonClick(Sender: TObject);
begin
  IDEDialogLayoutList.SaveLayout(Self);
  EditorOpts.Load;
  ModalResult := mrCancel;
end;

procedure TEditorOptionsForm.ShowLineNumbersCheckBoxClick(Sender: TObject);
begin
  ShowOnlyLineNumbersMultiplesOfSpinEdit.Enabled := ShowLineNumbersCheckBox.Checked;
  ShowOnlyLineNumbersMultiplesOfLabel.Enabled := ShowLineNumbersCheckBox.Checked;
end;

procedure TEditorOptionsForm.TextStyleRadioOnChange(Sender : TObject);
  procedure CalcNewStyle(CheckBox: TCheckBox; RadioOn, RadioOff,
                         RadioInvert: TRadioButton; fs : TFontStyle;
                         Panel: TPanel);
  begin
    if CheckBox.Checked then begin
      Panel.Enabled := True;
      if RadioInvert.Checked then begin
        CurHighlightElement.Style     := CurHighlightElement.Style + [fs];
        CurHighlightElement.StyleMask := CurHighlightElement.StyleMask - [fs];
      end else if RadioOn.Checked then begin
        CurHighlightElement.Style     := CurHighlightElement.Style + [fs];
        CurHighlightElement.StyleMask := CurHighlightElement.StyleMask + [fs];
      end else if RadioOff.Checked then begin
        CurHighlightElement.Style     := CurHighlightElement.Style - [fs];
        CurHighlightElement.StyleMask := CurHighlightElement.StyleMask + [fs];
      end
    end else begin
      Panel.Enabled := False;
      CurHighlightElement.Style     := CurHighlightElement.Style - [fs];
      CurHighlightElement.StyleMask := CurHighlightElement.StyleMask - [fs];
    end;
  end;
begin
  if FormCreating then exit;
  if UpdatingColor or not CurHighlightElementIsExtra then exit;

  if (Sender = TextBoldCheckBox) or (Sender = TextBoldRadioOn)
    or (Sender = TextBoldRadioOff) or (Sender = TextBoldRadioInvert)
  then CalcNewStyle(TextBoldCheckBox, TextBoldRadioOn, TextBoldRadioOff,
                    TextBoldRadioInvert, fsBold, TextBoldRadioPanel);

  if (Sender = TextItalicCheckBox) or (Sender = TextItalicRadioOn)
    or (Sender = TextItalicRadioOff) or (Sender = TextItalicRadioInvert)
  then CalcNewStyle(TextItalicCheckBox, TextItalicRadioOn, TextItalicRadioOff,
                    TextItalicRadioInvert, fsItalic, TextItalicRadioPanel);

  if (Sender = TextUnderlineCheckBox) or (Sender = TextUnderlineRadioOn)
    or (Sender = TextUnderlineRadioOff) or (Sender = TextUnderlineRadioInvert)
  then CalcNewStyle(TextUnderlineCheckBox, TextUnderlineRadioOn, TextUnderlineRadioOff,
                    TextUnderlineRadioInvert, fsUnderline, TextUnderlineRadioPanel);


  InvalidatePreviews;
end;

//=============================================================================

initialization
  {$I editoroptionsdlg.lrs}
end.
