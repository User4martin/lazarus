{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

Alternatively, the contents of this file may be used under the terms of the
GNU General Public License Version 2 or later (the "GPL"), in which case
the provisions of the GPL are applicable instead of those above.
If you wish to allow use of your version of this file only under the terms
of the GPL and not to allow others to use your version of this file
under the MPL, indicate your decision by deleting the provisions above and
replace them with the notice and other provisions required by the GPL.
If you do not delete the provisions above, a recipient may use your version
of this file under either the MPL or the GPL.

-------------------------------------------------------------------------------}
unit SynEditMarkup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, SynEditTextBase, SynEditTextBuffer, SynEditMiscClasses, Controls, SynEditHighlighter;

type

  TInvalidateLines = procedure(FirstLine, LastLine: integer) of Object;

type
  { TSynEditMarkup }

  TSynEditMarkup = class(TObject)
  private
    fMarkupInfo : TSynSelectedColor;
    fLines : TSynEditStrings;
    fCaret : TPoint;
    fTopLine, FLinesInWindow : Integer;
    fSynEdit : TCustomControl;
    fInvalidateLinesMethod : TInvalidateLines;

    function GetBGColor : TColor;
    function GetFGColor : TColor;
    function GetFrameColor: TColor;
    function GetStyle : TFontStyles;
    procedure SetBGColor(const AValue : TColor);
    procedure SetFGColor(const AValue : TColor);
    procedure SetFrameColor(const AValue : TColor);
    procedure SetStyle(const AValue : TFontStyles);

    procedure MarkupChanged(AMarkup: TObject);
  protected
    procedure SetInvalidateLinesMethod(const AValue : TInvalidateLines); virtual;
    procedure SetLines(const AValue : TSynEditStrings); virtual;
    procedure SetTopLine(const AValue : Integer); virtual;
    procedure SetLinesInWindow(const AValue : Integer); virtual;
    procedure SetCaret(const AValue : TPoint); virtual;

    procedure DoCaretChanged(OldCaret : TPoint); virtual;
    procedure DoTopLineChanged(OldTopLine : Integer); virtual;
    procedure DoLinesInWindoChanged(OldLinesInWindow : Integer); virtual;
    procedure DoMarkupChanged(AMarkup: TSynSelectedColor); virtual;

    procedure InvalidateSynLines(FirstLine, LastLine: integer); // Call Synedt to invalidate lines
    function ScreenRowToRow(aRow : Integer) : Integer;
    function RowToScreenRow(aRow : Integer) : Integer;
    function LogicalToPhysicalPos(const p: TPoint): TPoint;
    function Highlighter: TSynCustomHighlighter;

    property SynEdit : TCustomControl read fSynEdit;
  public
    constructor Create(ASynEdit : TCustomControl);
    destructor Destroy; override;
    Procedure PrepareMarkupForRow(aRow : Integer); virtual;
    Procedure FinishMarkupForRow(aRow : Integer); virtual;
    Procedure EndMarkup; virtual;
    Function GetMarkupAttributeAtRowCol(const aRow, aCol : Integer) : TSynSelectedColor; virtual; abstract;
    Function GetNextMarkupColAfterRowCol(const aRow, aCol : Integer) : Integer; virtual; abstract;

    property MarkupInfo : TSynSelectedColor read fMarkupInfo;
    property FGColor : TColor read GetFGColor;
    property BGColor : TColor read GetBGColor;
    property FrameColor: TColor read GetFrameColor;
    property Style : TFontStyles read GetStyle;
    property Lines : TSynEditStrings read fLines write SetLines;
    property Caret : TPoint read fCaret write SetCaret;
    property TopLine : Integer read fTopLine write SetTopLine;
    property LinesInWindow : Integer read fLinesInWindow write SetLinesInWindow;
    property InvalidateLinesMethod : TInvalidateLines write SetInvalidateLinesMethod;
  end;

  { TSynEditMarkupManager }

  TSynEditMarkupManager = class(TSynEditMarkup) { TODO: Forward onchange calls to all others }
  private
    fMarkUpList : TList;

  protected
    procedure SetInvalidateLinesMethod(const AValue : TInvalidateLines); override;
    procedure SetLines(const AValue : TSynEditStrings); override;
    procedure SetTopLine(const AValue : Integer); override;
    procedure SetLinesInWindow(const AValue : Integer); override;
    procedure SetCaret(const AValue : TPoint); override;
  public
    constructor Create(ASynEdit : TCustomControl);
    destructor Destroy; override;
    
    Procedure AddMarkUp(aMarkUp : TSynEditMarkup);

    Procedure PrepareMarkupForRow(aRow : Integer); override;
    Procedure FinishMarkupForRow(aRow : Integer); override;
    Procedure EndMarkup; override;
    Function GetMarkupAttributeAtRowCol(const aRow, aCol : Integer) : TSynSelectedColor; override;
    Function GetNextMarkupColAfterRowCol(const aRow, aCol : Integer) : Integer; override;
  end;


  
implementation
uses SynEdit, SynEditMiscProcs;

{ TSynEditMarkup }

function TSynEditMarkup.GetBGColor : TColor;
begin
  result := fMarkupInfo.Background;
end;

function TSynEditMarkup.GetFGColor : TColor;
begin
  result := fMarkupInfo.Foreground;
end;

function TSynEditMarkup.GetFrameColor: TColor;
begin
  Result := fMarkupInfo.FrameColor;
end;

function TSynEditMarkup.GetStyle : TFontStyles;
begin
  Result := fMarkupInfo.Style;
end;

procedure TSynEditMarkup.SetBGColor(const AValue : TColor);
begin
  if fMarkupInfo.Background = AValue then exit;
  fMarkupInfo.Background := AValue;
end;

procedure TSynEditMarkup.SetFGColor(const AValue : TColor);
begin
  if fMarkupInfo.Foreground = AValue then exit;
  fMarkupInfo.Foreground := AValue;
end;

procedure TSynEditMarkup.SetFrameColor(const AValue: TColor);
begin
  if fMarkupInfo.FrameColor = AValue then exit;
  fMarkupInfo.FrameColor := AValue;
end;

procedure TSynEditMarkup.SetStyle(const AValue : TFontStyles);
begin
  if fMarkupInfo.Style = AValue then exit;
  fMarkupInfo.Style := AValue;
end;

procedure TSynEditMarkup.MarkupChanged(AMarkup : TObject);
begin
  DoMarkupChanged(AMarkup as TSynSelectedColor);
end;

procedure TSynEditMarkup.SetLines(const AValue : TSynEditStrings);
begin
  if fLines = AValue then exit;
  fLines := AValue;
end;

procedure TSynEditMarkup.SetInvalidateLinesMethod(const AValue : TInvalidateLines);
begin
  if fInvalidateLinesMethod = AValue then exit;
  fInvalidateLinesMethod := AValue;
end;

procedure TSynEditMarkup.SetCaret(const AValue : TPoint);
var
  OldValue : TPoint;
begin
  if (fCaret.x = AValue.X) and (fCaret.Y = AValue.Y) then exit;
  OldValue := fCaret;
  fCaret := AValue;
  DoCaretChanged(OldValue);
end;

procedure TSynEditMarkup.SetTopLine(const AValue : Integer);
var
  OldValue : Integer;
begin
  if fTopLine = AValue then exit;
  OldValue :=fTopLine;
  fTopLine := AValue;
  DoTopLineChanged(OldValue);
end;

procedure TSynEditMarkup.SetLinesInWindow(const AValue : Integer);
var
  OldValue : Integer;
begin
  if FLinesInWindow = AValue then exit;
  OldValue :=FLinesInWindow;
  FLinesInWindow := AValue;
  DoLinesInWindoChanged(OldValue);
end;

procedure TSynEditMarkup.DoCaretChanged(OldCaret : TPoint);
begin
end;

procedure TSynEditMarkup.DoTopLineChanged(OldTopLine : Integer);
begin
end;

procedure TSynEditMarkup.DoLinesInWindoChanged(OldLinesInWindow : Integer);
begin
end;

procedure TSynEditMarkup.DoMarkupChanged(AMarkup : TSynSelectedColor);
begin
end;

procedure TSynEditMarkup.InvalidateSynLines(FirstLine, LastLine : integer);
begin
  if assigned(fInvalidateLinesMethod)
  then fInvalidateLinesMethod(FirstLine, LastLine);
end;

function TSynEditMarkup.ScreenRowToRow(aRow : Integer) : Integer;
begin
  Result := TSynEdit(SynEdit).ScreenRowToRow(aRow);
end;

function TSynEditMarkup.RowToScreenRow(aRow : Integer) : Integer;
begin
  Result := TSynEdit(SynEdit).RowToScreenRow(aRow);
end;

function TSynEditMarkup.LogicalToPhysicalPos(const p : TPoint) : TPoint;
begin
  Result := TSynEdit(SynEdit).LogicalToPhysicalPos(p);
end;

function TSynEditMarkup.Highlighter : TSynCustomHighlighter;
begin
  Result := TSynEdit(SynEdit).Highlighter;
end;

constructor TSynEditMarkup.Create(ASynEdit : TCustomControl);
begin
  inherited Create();
  fSynEdit := ASynEdit;
  fMarkupInfo := TSynSelectedColor.Create;
  fMarkupInfo.OnChange := @MarkupChanged;
end;

destructor TSynEditMarkup.Destroy;
begin
  FreeAndNil(fMarkupInfo);
  inherited Destroy;
end;

procedure TSynEditMarkup.FinishMarkupForRow(aRow : Integer);
begin
end;

procedure TSynEditMarkup.EndMarkup;
begin
end;

procedure TSynEditMarkup.PrepareMarkupForRow(aRow : Integer);
begin
end;

{ TSynEditMarkupManager }

constructor TSynEditMarkupManager.Create(ASynEdit : TCustomControl);
begin
  inherited Create(ASynEdit);
  fMarkUpList := TList.Create;
end;

destructor TSynEditMarkupManager.Destroy;
var
  i : integer;
begin
  for i := 0 to fMarkUpList.Count-1 do
    TSynEditMarkup(fMarkUpList[i]).destroy;
  FreeAndNil(fMarkUpList);
  inherited Destroy;
end;

procedure TSynEditMarkupManager.AddMarkUp(aMarkUp : TSynEditMarkup);
begin
  fMarkUpList.Add(aMarkUp);
end;

procedure TSynEditMarkupManager.FinishMarkupForRow(aRow : Integer);
var
  i : integer;
begin
  for i := 0 to fMarkUpList.Count-1 do
    TSynEditMarkup(fMarkUpList[i]).FinishMarkupForRow(aRow);
end;

procedure TSynEditMarkupManager.EndMarkup;
var
  i : integer;
begin
  for i := 0 to fMarkUpList.Count-1 do
    TSynEditMarkup(fMarkUpList[i]).EndMarkup;
end;

procedure TSynEditMarkupManager.PrepareMarkupForRow(aRow : Integer);
var
  i : integer;
begin
  for i := 0 to fMarkUpList.Count-1 do
    TSynEditMarkup(fMarkUpList[i]).PrepareMarkupForRow(aRow);
end;

function TSynEditMarkupManager.GetMarkupAttributeAtRowCol(const aRow, aCol : Integer) : TSynSelectedColor;
var
  i : integer;
  c : TSynSelectedColor;
  sMask : TFontStyles;
begin
  Result := nil;

  for i := 0 to fMarkUpList.Count-1 do begin
    c := TSynEditMarkup(fMarkUpList[i]).GetMarkupAttributeAtRowCol(aRow, aCol);
    if assigned(c) then begin
      if not Assigned(Result) then begin
        Result := MarkupInfo;
        Result.Assign(c);
      end else begin
        if c.Background <> clNone then Result.Background := c.Background;
        if c.Foreground <> clNone then Result.Foreground := c.Foreground;
        if c.FrameColor <> clNone then Result.FrameColor := c.FrameColor;
        sMask := c.StyleMask + (fsNot(c.StyleMask) * c.Style); // Styles to be taken from c
        Result.Style:= (Result.Style * fsNot(sMask)) + (c.Style * sMask);
        Result.StyleMask:= (Result.StyleMask * fsNot(sMask)) + (c.StyleMask * sMask);
      end;
    end;
  end;
end;

function TSynEditMarkupManager.GetNextMarkupColAfterRowCol(const aRow, aCol : Integer) : Integer;
var
  i, j : integer;
begin
  if fMarkUpList.Count = 0
  then exit(-1);
  Result := TSynEditMarkup(fMarkUpList[0]).GetNextMarkupColAfterRowCol(aRow, aCol);
  for i := 1 to fMarkUpList.Count-1 do begin
    j := TSynEditMarkup(fMarkUpList[i]).GetNextMarkupColAfterRowCol(aRow, aCol);
    if ((j>0) and (j < Result)) or (Result<0) then Result := j;
  end;
end;

procedure TSynEditMarkupManager.SetInvalidateLinesMethod(const AValue : TInvalidateLines);
var
  i : integer;
begin
  inherited SetInvalidateLinesMethod(AValue);
  for i := 0 to fMarkUpList.Count-1 do
    TSynEditMarkup(fMarkUpList[i]).SetInvalidateLinesMethod(AValue);
end;

procedure TSynEditMarkupManager.SetLines(const AValue : TSynEditStrings);
var
  i : integer;
begin
  inherited SetLines(AValue);
  for i := 0 to fMarkUpList.Count-1 do
    TSynEditMarkup(fMarkUpList[i]).SetLines(AValue) ;
end;

procedure TSynEditMarkupManager.SetTopLine(const AValue : Integer);
var
  i : integer;
begin
  inherited SetTopLine(AValue);
  for i := 0 to fMarkUpList.Count-1 do
    TSynEditMarkup(fMarkUpList[i]).SetTopLine(AValue);
end;

procedure TSynEditMarkupManager.SetLinesInWindow(const AValue : Integer);
var
  i : integer;
begin
  inherited SetLinesInWindow(AValue);
  for i := 0 to fMarkUpList.Count-1 do
    TSynEditMarkup(fMarkUpList[i]).SetLinesInWindow(AValue);
end;

procedure TSynEditMarkupManager.SetCaret(const AValue : TPoint);
var
  i : integer;
begin
  inherited SetCaret(AValue);
  for i := 0 to fMarkUpList.Count-1 do
    TSynEditMarkup(fMarkUpList[i]).SetCaret(AValue);
end;

end.


(*
  procedure CalculateNextChangePos(FromPos: Integer);
    begin
      ChangePos:= nc2+1; // Draw the Rest
      ChangeTyp := [];

      hsCol1   := fMarkupHighAll.GetNextMarkupColAfterRowCol(CurLine, FromPos-1);

      if (nC1Sel >= FromPos) then begin
        ChangePos := nC1Sel;
        ChangeTyp := [cSelOn];
      end;
      if ((nC2Sel >= FromPos) and (nC2Sel <= ChangePos)) then begin
        if (nC2Sel < ChangePos)
        then ChangeTyp := [cSelOff]
        else include(ChangeTyp, cSelOff);
        ChangePos := nC2Sel;
      end;

      if ((hsCol1 >= FromPos) and (hsCol1 <= ChangePos)) then begin
        hsMarkup := fMarkupHighAll.GetMarkupAttributeAtRowCol(CurLine, hsCol1);
if hsMarkup<>nil then begin;
        if (hsCol1 < ChangePos)
        then ChangeTyp := [CHLightOn]
        else include(ChangeTyp, CHLightOn);
end else begin
        if (hsCol1 < ChangePos)
        then ChangeTyp := [CHLightOff]
        else include(ChangeTyp, CHLightOff);
end;
        ChangePos := hsCol1;

        // only because this is last
      end;

    end;
  var
    CurrentColor : TDrawingColors;
    WantedColor : Set of TDrawingColors;
  procedure ExecuteChangePos;
    var
      NewColor : TDrawingColors;
    begin
      if (cSelOn in ChangeTyp)     then include(WantedColor, dcSelected);
      if (cSelOff in ChangeTyp)    then exclude(WantedColor, dcSelected);
      if (CHLightOn in ChangeTyp)  then include(WantedColor, dcHighlighted);
      if (CHLightOff in ChangeTyp) then exclude(WantedColor, dcHighlighted);

      if dcSelected in WantedColor
      then NewColor:= dcSelected
      else if dcHighlighted in WantedColor
      then NewColor:= dcHighlighted
      else NewColor:= dcNormal;

      if NewColor <> CurrentColor then SetDrawingColors(NewColor);
      CurrentColor:=NewColor;
    end;


*)
