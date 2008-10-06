{ $Id$}
{
 *****************************************************************************
 *                               WSStdCtrls.pp                               * 
 *                               -------------                               * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
unit WSStdCtrls;

{$mode objfpc}{$H+}

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
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
  StdCtrls, Graphics,
////////////////////////////////////////////////////
  WSLCLClasses, WSControls, Classes;

type
  { TWSScrollBar }

  TWSScrollBar = class(TWSWinControl)
    class procedure SetParams(const AScrollBar: TCustomScrollBar); virtual;
  end;
  TWSScrollBarClass = class of TWSScrollBar;

  { TWSCustomGroupBox }

  TWSCustomGroupBox = class(TWSCustomControl)
  end;

  { TWSGroupBox }

  TWSGroupBox = class(TWSCustomGroupBox)
  end;

  { TWSCustomComboBox }

  TWSCustomComboBox = class(TWSWinControl)
    class function  GetSelStart(const ACustomComboBox: TCustomComboBox): integer; virtual;
    class function  GetSelLength(const ACustomComboBox: TCustomComboBox): integer; virtual;
    class function  GetItemIndex(const ACustomComboBox: TCustomComboBox): integer; virtual;
    class function  GetMaxLength(const ACustomComboBox: TCustomComboBox): integer; virtual;
    
    class procedure SetArrowKeysTraverseList(const ACustomComboBox: TCustomComboBox; 
      NewTraverseList: boolean); virtual;
    class procedure SetDropDownCount(const ACustomComboBox: TCustomComboBox; NewCount: Integer); virtual;
    class procedure SetSelStart(const ACustomComboBox: TCustomComboBox; NewStart: integer); virtual;
    class procedure SetSelLength(const ACustomComboBox: TCustomComboBox; NewLength: integer); virtual;
    class procedure SetItemIndex(const ACustomComboBox: TCustomComboBox; NewIndex: integer); virtual;
    class procedure SetMaxLength(const ACustomComboBox: TCustomComboBox; NewLength: integer); virtual;
    class procedure SetStyle(const ACustomComboBox: TCustomComboBox; NewStyle: TComboBoxStyle); virtual;
    class procedure SetReadOnly(const ACustomComboBox: TCustomComboBox; NewReadOnly: boolean); virtual;

    class function  GetItems(const ACustomComboBox: TCustomComboBox): TStrings; virtual;
    class procedure Sort(const ACustomComboBox: TCustomComboBox; AList: TStrings; IsSorted: boolean); virtual;
    
    class function GetItemHeight(const ACustomComboBox: TCustomComboBox): Integer; virtual;
    class procedure SetItemHeight(const ACustomComboBox: TCustomComboBox; const AItemHeight: Integer); virtual;
  end;
  TWSCustomComboBoxClass = class of TWSCustomComboBox;

  { TWSComboBox }

  TWSComboBox = class(TWSCustomComboBox)
  end;

  { TWSCustomListBox }

  TWSCustomListBox = class(TWSWinControl)
    class function GetIndexAtXY(const ACustomListBox: TCustomListBox; X, Y: integer): integer; virtual;
    class function GetItemIndex(const ACustomListBox: TCustomListBox): integer; virtual;
    class function GetItemRect(const ACustomListBox: TCustomListBox; Index: integer; var ARect: TRect): boolean; virtual;
    class function GetSelCount(const ACustomListBox: TCustomListBox): integer; virtual;
    class function GetSelected(const ACustomListBox: TCustomListBox; const AIndex: integer): boolean; virtual;
    class function GetStrings(const ACustomListBox: TCustomListBox): TStrings; virtual;
    class function GetTopIndex(const ACustomListBox: TCustomListBox): integer; virtual;

    class procedure SelectItem(const ACustomListBox: TCustomListBox; AIndex: integer; ASelected: boolean); virtual;

    class procedure SetBorder(const ACustomListBox: TCustomListBox); virtual;
    class procedure SetColumnCount(const ACustomListBox: TCustomListBox; ACount: Integer); virtual;
    class procedure SetItemIndex(const ACustomListBox: TCustomListBox; const AIndex: integer); virtual;
    class procedure SetSelectionMode(const ACustomListBox: TCustomListBox; const AExtendedSelect, 
      AMultiSelect: boolean); virtual;
    class procedure SetStyle(const ACustomListBox: TCustomListBox); virtual;
    class procedure SetSorted(const ACustomListBox: TCustomListBox; AList: TStrings; ASorted: boolean); virtual;
    class procedure SetTopIndex(const ACustomListBox: TCustomListBox; const NewTopIndex: integer); virtual;
  end;
  TWSCustomListBoxClass = class of TWSCustomListBox;
  
  { TWSListBox }

  TWSListBox = class(TWSCustomListBox)
  end;

  { TWSCustomEdit }

  TWSCustomEdit = class(TWSWinControl)
    class function GetCanUndo(const ACustomEdit: TCustomEdit): Boolean; virtual;
    class function GetCaretPos(const ACustomEdit: TCustomEdit): TPoint; virtual;
    class function GetSelStart(const ACustomEdit: TCustomEdit): integer; virtual;
    class function GetSelLength(const ACustomEdit: TCustomEdit): integer; virtual;

    class procedure SetCaretPos(const ACustomEdit: TCustomEdit; const NewPos: TPoint); virtual;
    class procedure SetCharCase(const ACustomEdit: TCustomEdit; NewCase: TEditCharCase); virtual;
    class procedure SetEchoMode(const ACustomEdit: TCustomEdit; NewMode: TEchoMode); virtual;
    class procedure SetMaxLength(const ACustomEdit: TCustomEdit; NewLength: integer); virtual;
    class procedure SetPasswordChar(const ACustomEdit: TCustomEdit; NewChar: char); virtual;
    class procedure SetReadOnly(const ACustomEdit: TCustomEdit; NewReadOnly: boolean); virtual;
    class procedure SetSelStart(const ACustomEdit: TCustomEdit; NewStart: integer); virtual;
    class procedure SetSelLength(const ACustomEdit: TCustomEdit; NewLength: integer); virtual;

    class procedure Undo(const ACustomEdit: TCustomEdit); virtual;
  end;
  TWSCustomEditClass = class of TWSCustomEdit;

  { TWSCustomMemo }

  TWSCustomMemo = class(TWSCustomEdit)
    class procedure AppendText(const ACustomMemo: TCustomMemo; const AText: string); virtual;
    class function  GetStrings(const ACustomMemo: TCustomMemo): TStrings; virtual;
    class procedure SetAlignment(const ACustomMemo: TCustomMemo; const AAlignment: TAlignment); virtual;
    class procedure SetScrollbars(const ACustomMemo: TCustomMemo; const NewScrollbars: TScrollStyle); virtual;
    class procedure SetWantTabs(const ACustomMemo: TCustomMemo; const NewWantTabs: boolean); virtual;
    class procedure SetWantReturns(const ACustomMemo: TCustomMemo; const NewWantReturns: boolean); virtual;
    class procedure SetWordWrap(const ACustomMemo: TCustomMemo; const NewWordWrap: boolean); virtual;
  end;
  TWSCustomMemoClass = class of TWSCustomMemo;

  { TWSEdit }

  TWSEdit = class(TWSCustomEdit)
  end;

  { TWSMemo }

  TWSMemo = class(TWSCustomMemo)
  end;

  { TWSCustomStaticText }

  TWSCustomStaticTextClass = class of TWSCustomStaticText;
  TWSCustomStaticText = class(TWSWinControl)
    class procedure SetAlignment(const ACustomStaticText: TCustomStaticText; const NewAlignment: TAlignment); virtual;
    class procedure SetStaticBorderStyle(const ACustomStaticText: TCustomStaticText; const NewBorderStyle: TStaticBorderStyle); virtual;
  end;

  { TWSStaticText }

  TWSStaticText = class(TWSCustomStaticText)
  end;

  { TWSButtonControl }

  TWSButtonControl = class(TWSWinControl)
  end;

  { TWSButton }

  TWSButton = class(TWSButtonControl)
    class procedure SetDefault(const AButton: TCustomButton; ADefault: Boolean); virtual;
    class procedure SetShortCut(const AButton: TCustomButton; const OldShortCut, NewShortCut: TShortCut); virtual;
  end;
  TWSButtonClass = class of TWSButton;

  { TWSCustomCheckBox }

  TWSCustomCheckBox = class(TWSButtonControl)
    class function  RetrieveState(const ACustomCheckBox: TCustomCheckBox): TCheckBoxState; virtual;
    class procedure SetShortCut(const ACustomCheckBox: TCustomCheckBox; 
      const OldShortCut, NewShortCut: TShortCut); virtual;
    class procedure SetState(const ACustomCheckBox: TCustomCheckBox; const NewState: TCheckBoxState); virtual;
  end;
  TWSCustomCheckBoxClass = class of TWSCustomCheckBox;

  { TWSCheckBox }

  TWSCheckBox = class(TWSCustomCheckBox)
  end;

  { TWSToggleBox }

  TWSToggleBox = class(TWSCustomCheckBox)
  end;

  { TWSRadioButton }

  TWSRadioButton = class(TWSCustomCheckBox)
  end;


implementation

{ TWSScrollBar }

class procedure TWSScrollBar.SetParams(const AScrollBar: TCustomScrollBar);
begin
end;

{ TWSCustomListBox }

class function TWSCustomListBox.GetIndexAtXY(
  const ACustomListBox: TCustomListBox; X, Y: integer): integer;
begin
  Result := -1;
end;

class function  TWSCustomListBox.GetItemIndex(const ACustomListBox: TCustomListBox): integer;
begin
  Result := 0;
end;

class function TWSCustomListBox.GetItemRect(
  const ACustomListBox: TCustomListBox; Index: integer; var ARect: TRect
  ): boolean;
begin
  FillChar(ARect,SizeOf(ARect),0);
  Result:=false;
end;

class function  TWSCustomListBox.GetSelCount(const ACustomListBox: TCustomListBox): integer;
begin
  Result := 0;
end;

class function  TWSCustomListBox.GetSelected(const ACustomListBox: TCustomListBox; const AIndex: integer): boolean;
begin
  Result := false;
end;

class function  TWSCustomListBox.GetStrings(const ACustomListBox: TCustomListBox): TStrings;
begin
  Result := nil;
end;

class function  TWSCustomListBox.GetTopIndex(const ACustomListBox: TCustomListBox): integer;
begin
  Result := 0;
end;

class procedure TWSCustomListBox.SelectItem(const ACustomListBox: TCustomListBox; AIndex: integer; ASelected: boolean);
begin
end;

class procedure TWSCustomListBox.SetBorder(const ACustomListBox: TCustomListBox);
begin
end;

class procedure TWSCustomListBox.SetColumnCount(const ACustomListBox: TCustomListBox;
  ACount: Integer);
begin
end;

class procedure TWSCustomListBox.SetItemIndex(const ACustomListBox: TCustomListBox; const AIndex: integer);
begin
end;

class procedure TWSCustomListBox.SetSelectionMode(const ACustomListBox: TCustomListBox;
  const AExtendedSelect, AMultiSelect: boolean);
begin
end;

class procedure TWSCustomListBox.SetStyle(const ACustomListBox: TCustomListBox);
begin
end;

class procedure TWSCustomListBox.SetSorted(const ACustomListBox: TCustomListBox;
  AList: TStrings; ASorted: boolean);
begin
end;

class procedure TWSCustomListBox.SetTopIndex(const ACustomListBox: TCustomListBox;
  const NewTopIndex: integer);
begin
end;

{ TWSCustomComboBox }

class function  TWSCustomComboBox.GetSelStart(const ACustomComboBox: TCustomComboBox
  ): integer;
begin
  Result := -1;
end;

class function  TWSCustomComboBox.GetSelLength(const ACustomComboBox: TCustomComboBox
  ): integer;
begin
  Result := 0;
end;

class function  TWSCustomComboBox.GetItemIndex(const ACustomComboBox: TCustomComboBox
  ): integer;
begin
  Result := -1;
end;

class function  TWSCustomComboBox.GetMaxLength(const ACustomComboBox: TCustomComboBox
  ): integer;
begin
  Result := 0;
end;

class procedure TWSCustomComboBox.SetArrowKeysTraverseList(
  const ACustomComboBox: TCustomComboBox; NewTraverseList: boolean);
begin
end;

class procedure TWSCustomComboBox.SetDropDownCount(
  const ACustomComboBox: TCustomComboBox; NewCount: Integer);
begin
end;

class procedure TWSCustomComboBox.SetMaxLength(const ACustomComboBox: TCustomComboBox;
  NewLength: integer);
begin
end;

class procedure TWSCustomComboBox.SetSelStart(const ACustomComboBox: TCustomComboBox;
  NewStart: integer);
begin
end;

class procedure TWSCustomComboBox.SetSelLength(const ACustomComboBox: TCustomComboBox;
  NewLength: integer);
begin
end;

class procedure TWSCustomComboBox.SetItemIndex(const ACustomComboBox: TCustomComboBox;
  NewIndex: integer);
begin
end;

class procedure TWSCustomComboBox.SetStyle(const ACustomComboBox: TCustomComboBox;
  NewStyle: TComboBoxStyle);
begin
end;

class procedure TWSCustomComboBox.SetReadOnly(const ACustomComboBox: TCustomComboBox;
  NewReadOnly: boolean);
begin
end;

class function  TWSCustomComboBox.GetItems(const ACustomComboBox: TCustomComboBox
  ): TStrings;
begin
  Result := nil;
end;

class procedure TWSCustomComboBox.Sort(const ACustomComboBox: TCustomComboBox;
  AList: TStrings; IsSorted: boolean);
begin
end;

class function TWSCustomComboBox.GetItemHeight(const ACustomComboBox: TCustomComboBox): Integer;
begin
  Result := 0;
end;

class procedure TWSCustomComboBox.SetItemHeight(const ACustomComboBox: TCustomComboBox; const AItemHeight: Integer);
begin
end;

{ TWSCustomEdit }

class function TWSCustomEdit.GetCanUndo(const ACustomEdit: TCustomEdit
  ): Boolean;
begin
  Result := False;
end;

class function TWSCustomEdit.GetCaretPos(const ACustomEdit: TCustomEdit): TPoint;
begin
  Result := Point(0, 0);
end;

class function  TWSCustomEdit.GetSelStart(const ACustomEdit: TCustomEdit): integer;
begin
  result := -1;
end;

class function  TWSCustomEdit.GetSelLength(const ACustomEdit: TCustomEdit): integer;
begin
  result := 0;
end;

class procedure TWSCustomEdit.SetCaretPos(const ACustomEdit: TCustomEdit; const NewPos: TPoint);
begin

end;

class procedure TWSCustomEdit.SetCharCase(const ACustomEdit: TCustomEdit; NewCase: TEditCharCase);
begin
end;

class procedure TWSCustomEdit.SetEchoMode(const ACustomEdit: TCustomEdit; NewMode: TEchoMode);
begin
end;

class procedure TWSCustomEdit.SetMaxLength(const ACustomEdit: TCustomEdit; NewLength: integer);
begin
end;

class procedure TWSCustomEdit.SetPasswordChar(const ACustomEdit: TCustomEdit; NewChar: char);
begin
end;

class procedure TWSCustomEdit.SetReadOnly(const ACustomEdit: TCustomEdit; NewReadOnly: boolean);
begin
end;

class procedure TWSCustomEdit.SetSelStart(const ACustomEdit: TCustomEdit; NewStart: integer);
begin
end;

class procedure TWSCustomEdit.SetSelLength(const ACustomEdit: TCustomEdit; NewLength: integer);
begin
end;

class procedure TWSCustomEdit.Undo(const ACustomEdit: TCustomEdit);
begin
  // nothing
end;

{ TWSCustomMemo }

class procedure TWSCustomMemo.AppendText(const ACustomMemo: TCustomMemo; const AText: string);
begin
end;

class function TWSCustomMemo.GetStrings(const ACustomMemo: TCustomMemo): TStrings;
begin
  Result := ACustomMemo.Lines; //use default if the WS has not defined any
end;

class procedure TWSCustomMemo.SetAlignment(const ACustomMemo: TCustomMemo;
  const AAlignment: TAlignment);
begin
end;

class procedure TWSCustomMemo.SetScrollbars(const ACustomMemo: TCustomMemo; const NewScrollbars: TScrollStyle);
begin
end;

class procedure TWSCustomMemo.SetWantTabs(const ACustomMemo: TCustomMemo; const NewWantTabs: boolean);
begin
end;

class procedure TWSCustomMemo.SetWantReturns(const ACustomMemo: TCustomMemo; const NewWantReturns: boolean);
begin
end;

class procedure TWSCustomMemo.SetWordWrap(const ACustomMemo: TCustomMemo; const NewWordWrap: boolean);
begin
end;

{ TWSCustomStaticText }

class procedure TWSCustomStaticText.SetAlignment(const ACustomStaticText: TCustomStaticText; const NewAlignment: TAlignment);
begin
end;

class procedure TWSCustomStaticText.SetStaticBorderStyle(
  const ACustomStaticText: TCustomStaticText;
  const NewBorderStyle: TStaticBorderStyle);
begin
  // nothing
end;

{ TWSButton }

class procedure TWSButton.SetDefault(const AButton: TCustomButton; ADefault: Boolean);
begin
end;

class procedure TWSButton.SetShortCut(const AButton: TCustomButton; const OldShortCut, NewShortCut: TShortCut);
begin
end;

{ TWSCustomCheckBox }

class function  TWSCustomCheckBox.RetrieveState(const ACustomCheckBox: TCustomCheckBox): TCheckBoxState;
begin
  Result := cbUnchecked;
end;

class procedure TWSCustomCheckBox.SetShortCut(const ACustomCheckBox: TCustomCheckBox; const OldShortCut, NewShortCut: TShortCut);
begin
end;

class procedure TWSCustomCheckBox.SetState(const ACustomCheckBox: TCustomCheckBox; const NewState: TCheckBoxState);
begin
end;

initialization

////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
//  RegisterWSComponent(TScrollBar, TWSScrollBar);
//  RegisterWSComponent(TCustomGroupBox, TWSCustomGroupBox);
//  RegisterWSComponent(TGroupBox, TWSGroupBox);
//  RegisterWSComponent(TCustomComboBox, TWSCustomComboBox);
//  RegisterWSComponent(TComboBox, TWSComboBox);
//  RegisterWSComponent(TCustomListBox, TWSCustomListBox);
//  RegisterWSComponent(TListBox, TWSListBox);
//  RegisterWSComponent(TCustomEdit, TWSCustomEdit);
//  RegisterWSComponent(TCustomMemo, TWSCustomMemo);
//  RegisterWSComponent(TEdit, TWSEdit);
//  RegisterWSComponent(TMemo, TWSMemo);
//  RegisterWSComponent(TCustomStaticText, TWSCustomStaticText);
//  RegisterWSComponent(TStaticText, TWSStaticText);
//  RegisterWSComponent(TButtonControl, TWSButtonControl);
//  RegisterWSComponent(TCustomCheckBox, TWSCustomCheckBox);
//  RegisterWSComponent(TCheckBox, TWSCheckBox);
//  RegisterWSComponent(TCheckBox, TWSCheckBox);
//  RegisterWSComponent(TToggleBox, TWSToggleBox);
//  RegisterWSComponent(TRadioButton, TWSRadioButton);
//  RegisterWSComponent(TLabel, TWSLabel);
////////////////////////////////////////////////////
end.
