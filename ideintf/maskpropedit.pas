{ Copyright (C) 2005

 *****************************************************************************
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

  Author: Lagunov Aleksey

  Abstract:
    Property Editors for TMaskEdit.EditMask of FCL and LCL.
}

unit MaskPropEdit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MaskUtils, LResources, Forms, Controls, Graphics, Dialogs,
  StrUtils, StdCtrls, Buttons, ExtCtrls, FileUtil, MaskEdit, LazIDEIntf,
  PropEdits, ComponentEditors, ObjInspStrConsts;

type

  { TMaskEditorForm }

  TMaskEditorForm = class(TForm)
    CancelButton: TBitBtn;
    HelpButton: TBitBtn;
    LoadSampleMasksButton: TButton;
    OkButton: TBitBtn;
    SaveLiteralCheckBox: TCheckBox;
    InputMaskEdit: TEdit;
    CharactersForBlanksEdit: TEdit;
    InputMaskLabel: TLabel;
    SampleMasksLabel: TLabel;
    CharactersForBlanksLabel: TLabel;
    TestInputLabel: TLabel;
    SampleMasksListBox: TListBox;
    TestMaskEdit: TMaskEdit;
    OpenDialog1: TOpenDialog;
    TestInputPanel: TPanel;
    procedure LoadSampleMasksButtonClick(Sender: TObject);
    procedure SampleMasksListBoxDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure SaveLiteralCheckBoxClick(Sender: TObject);
    procedure InputMaskEditChange(Sender: TObject);
    procedure CharactersForBlankEditChange(Sender: TObject);
    procedure SampleMasksListBoxClick(Sender: TObject);
    procedure MaskEditorFormCreate(Sender: TObject);
  private
    function GetEditMask: string;
    procedure LoadDEMFile(AFileName: string);
    procedure SetEditMask(AValue: string);
    procedure UpdateTestEditor;
  public
    property EditMask: string read GetEditMask write SetEditMask;
  end; 

  { TEditMaskProperty }

  TEditMaskProperty = class(TStringPropertyEditor)
  public
    function  GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

  { TMaskEditEditor }

  TMaskEditEditor = class(TDefaultComponentEditor)
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
    function MaskEdit: TCustomMaskEdit; virtual;
  end;

implementation

procedure ParseMaskLine(Line: String; out Caption, Example, Mask: String);
begin
  // in delphi .dem files every mask line contains:
  // mask name|mask example|mask

  // 1. Extract caption from Line
  Caption := Copy(Line, 1, Pos('|', Line) - 1);
  Delete(Line, 1, Length(Caption) + 1);

  // 2. Extract example from Line
  Example := Copy(Line, 1, Pos('|', Line) - 1);
  Delete(Line, 1, Length(Example) + 1);

  // 3. Copy what we have to Mask
  Mask := Line;
end;

function MaskDoFormatText(const EditMask: string; const Value: string; Blank: Char): String;
var
  P: Integer;
  S: String;
begin
  // cheat maskutils while it has no its own MaskDoFormatText
  S := EditMask;
  P := LastDelimiter(';', S);
  if P <> 0 then
  begin
    S[P + 1] := Blank;
    dec(P);
    while (P > 0) and (S[P] <> ';') do
      dec(P);
    if P <> 0 then
     S[P + 1] := '0';
  end;
  try
    Result := FormatMaskText(S, Value);
  except
    Result := Value;
  end;
end;

{ TMaskEditorForm }

procedure TMaskEditorForm.LoadSampleMasksButtonClick(Sender: TObject);
begin
  OpenDialog1.InitialDir:=ExtractFileDir(ParamStrUTF8(0));
  if OpenDialog1.Execute then
    LoadDEMFile(OpenDialog1.FileName);
end;

procedure TMaskEditorForm.SampleMasksListBoxDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
var
  OldBrushStyle: TBrushStyle;
  OldTextStyle: TTextStyle;
  NewTextStyle: TTextStyle;
  ListBox: TListBox absolute Control;
  AMaskCaption, AMaskExample, AEditMask: String;
  R1, R2: TRect;
begin
  ListBox.Canvas.FillRect(ARect);
  if (Index >= 0) and (Index < ListBox.Items.Count) then
  begin
    OldBrushStyle := ListBox.Canvas.Brush.Style;
    ListBox.Canvas.Brush.Style := bsClear;

    OldTextStyle := ListBox.Canvas.TextStyle;
    NewTextStyle := OldTextStyle;
    NewTextStyle.Layout := tlCenter;
    ListBox.Canvas.TextStyle := NewTextStyle;

    ParseMaskLine(ListBox.Items[Index], AMaskCaption, AMaskExample, AEditMask);
    AMaskExample := MaskDoFormatText(AEditMask, AMaskExample, ' ');

    R1 := ARect;
    R2 := ARect;
    R1.Right := (R1.Left + R1.Right) div 2;
    R2.Left := R1.Right + 1;
    ListBox.Canvas.TextRect(R1, R1.Left + 2, R1.Top, AMaskCaption);
    ListBox.Canvas.TextRect(R2, R2.Left + 2, R2.Top, AMaskExample);
    ListBox.Canvas.MoveTo(R2.Left - 1, R2.Top);
    ListBox.Canvas.LineTo(R2.Left - 1, R2.Bottom);
    ListBox.Canvas.Brush.Style := OldBrushStyle;
    ListBox.Canvas.TextStyle := OldTextStyle;
  end;
end;

procedure TMaskEditorForm.SaveLiteralCheckBoxClick(Sender: TObject);
var
  I: integer;
  S1: string;
begin
  S1 := InputMaskEdit.Text;
  I := Pos(';', S1);
  if (I > 0) and (I < Length(S1)) then
  begin
    S1[i+1] := IntToStr(Ord(SaveLiteralCheckBox.Checked))[1];
    InputMaskEdit.Text := S1;
  end;
end;

procedure TMaskEditorForm.InputMaskEditChange(Sender: TObject);
begin
  UpdateTestEditor;
end;

procedure TMaskEditorForm.CharactersForBlankEditChange(Sender: TObject);
var
  I:integer;
  S1:string;
begin
  S1:=InputMaskEdit.Text;
  I:=NPos(';', S1, 2);
  if (I>0) and (I<Length(S1)) and (CharactersForBlanksEdit.Text<>'') then
  begin
    S1[i+1]:=CharactersForBlanksEdit.Text[1];
    InputMaskEdit.Text:=S1;
  end;
end;

procedure TMaskEditorForm.SampleMasksListBoxClick(Sender: TObject);
var
  AMaskCaption, AMaskExample, AEditMask: String;
begin
  if (SampleMasksListBox.Items.Count > 0) then
  begin
    TestMaskEdit.Text := '';
    ParseMaskLine(SampleMasksListBox.Items[SampleMasksListBox.ItemIndex],
      AMaskCaption, AMaskExample, AEditMask);
    EditMask := AEditMask;
  end;
end;

procedure TMaskEditorForm.MaskEditorFormCreate(Sender: TObject);
var
  aDemFile: string;
begin
  LoadSampleMasksButton.Caption := oisMasks;
  SaveLiteralCheckBox.Caption := oisSaveLiteralCharacters;
  InputMaskLabel.Caption := oisInputMask;
  SampleMasksLabel.Caption := oisSampleMasks;
  CharactersForBlanksLabel.Caption := oisCharactersForBlanks;
  TestInputLabel.Caption := oisTestInput;

  if LazarusIDE<>nil then
    aDemFile:=LazarusIDE.GetPrimaryConfigPath
  else
    aDemFile:=ExtractFileDir(ParamStrUTF8(0));
  aDemFile:=CleanAndExpandDirectory(aDemFile)+'maskeditmasks.txt';
  if FileExistsUTF8(aDemFile) then
    LoadDEMFile(aDemFile);
end;

function TMaskEditorForm.GetEditMask: string;
begin
  Result:=InputMaskEdit.Text;
end;

procedure TMaskEditorForm.LoadDEMFile(AFileName: string);
begin
  SampleMasksListBox.Items.Clear;
  SampleMasksListBox.Items.LoadFromFile(UTF8ToSys(AFileName));
end;

procedure TMaskEditorForm.SetEditMask(AValue: string);
begin
  InputMaskEdit.Text := AValue;
  Delete(AValue, 1, Pos(';', AValue));
  if AValue <> '' then
    SaveLiteralCheckBox.Checked := AValue[1] = '1';
  Delete(AValue, 1, Pos(';', AValue));
  CharactersForBlanksEdit.Text := AValue;
  UpdateTestEditor;
end;

procedure TMaskEditorForm.UpdateTestEditor;
begin
  TestMaskEdit.EditMask:=InputMaskEdit.Text;
end;

{ TEditMaskProperty }

function TEditMaskProperty.GetAttributes: TPropertyAttributes;
begin
  Result:= [paDialog];
end;

procedure TEditMaskProperty.Edit;
var
  MaskEditorForm: TMaskEditorForm;
begin
  MaskEditorForm:=TMaskEditorForm.Create(Application);
  try
    MaskEditorForm.EditMask:=GetValue;
    if MaskEditorForm.ShowModal = mrOk then
      SetValue(MaskEditorForm.EditMask);
  finally
    MaskEditorForm.Free;
  end;
end;

{ TMaskEditEditor }

procedure TMaskEditEditor.ExecuteVerb(Index: Integer);
var
  MaskEditorForm: TMaskEditorForm;
begin
  if Index = 0 then
  begin
    MaskEditorForm := TMaskEditorForm.Create(Application);
    try
      MaskEditorForm.EditMask := MaskEdit.EditMask;
      if MaskEditorForm.ShowModal = mrOk then
        MaskEdit.EditMask := MaskEditorForm.EditMask;
    finally
      MaskEditorForm.Free;
    end;
  end;
end;

function TMaskEditEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := sccsMaskEditor;
    else
      Result := '';
  end;
end;

function TMaskEditEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

function TMaskEditEditor.MaskEdit: TCustomMaskEdit;
begin
  Result := TCustomMaskEdit(GetComponent)
end;

initialization
  {$I maskpropedit.lrs}
  RegisterPropertyEditor(TypeInfo(string), TCustomMaskEdit, 'EditMask',
                         TEditMaskProperty);
  RegisterComponentEditor(TCustomMaskEdit, TMaskEditEditor);

end.

