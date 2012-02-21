{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: SynEditAutoComplete.pas, released 2000-06-25.

The Initial Author of the Original Code is Michael Hieke.
Portions written by Michael Hieke are Copyright 2000 Michael Hieke.
Portions written by Cyrille de Brebisson (from mwCompletionProposal.pas) are
Copyright 1999 Cyrille de Brebisson.
All Rights Reserved.

Contributors to the SynEdit and mwEdit projects are listed in the
Contributors.txt file.

Alternatively, the contents of this file may be used under the terms of the
GNU General Public License Version 2 or later (the "GPL"), in which case
the provisions of the GPL are applicable instead of those above.
If you wish to allow use of your version of this file only under the terms
of the GPL and not to allow others to use your version of this file
under the MPL, indicate your decision by deleting the provisions above and
replace them with the notice and other provisions required by the GPL.
If you do not delete the provisions above, a recipient may use your version
of this file under either the MPL or the GPL.

$Id$

You may retrieve the latest version of this file at the SynEdit home page,
located at http://SynEdit.SourceForge.net

Known Issues:
-------------------------------------------------------------------------------}

unit SynEditAutoComplete;

{$I synedit.inc}

interface

uses
  {$IFDEF SYN_LAZARUS}
  LCLIntf, LCLType, LCLProc,
  {$ELSE}
  Windows,
  {$ENDIF}
  Classes, SynEdit, SynEditKeyCmds,
  Controls;

{$IFDEF SYN_LAZARUS}
const
  CodeTemplateMacroMagic = '$(EnableMakros)';
  CodeTemplateEnableMacros = 'EnableMakros';
  CodeTemplateAttributesStartMagic = '$(AttributesStart)';
  CodeTemplateAttributesEndMagic = '$(AttributesEnd)';
{$ENDIF}

type
  {$IFDEF SYN_LAZARUS}
  TCustomSynAutoComplete = class;
  
  TOnTokenNotFound = procedure(Sender: TObject; AToken: string; 
                           AEditor: TCustomSynEdit; var Index:integer) of object;
  TOnExecuteCompletion = procedure(ASynAutoComplete: TCustomSynAutoComplete;
                                   Index: integer) of object;
  {$ENDIF}

  { TCustomSynAutoComplete }

  TCustomSynAutoComplete = class(TComponent)
  private
    {$IFDEF SYN_LAZARUS}
    fOnTokenNotFound: TOnTokenNotFound;
    fIndentToTokenStart: boolean;
    FOnExecuteCompletion: TOnExecuteCompletion;
    fAttributes: TFPList;// list of TStrings
    function GetCompletionAttributes(Index: integer): TStrings;
    procedure ClearAttributes;
    {$ENDIF}
  protected
    fAutoCompleteList: TStrings;
    fCompletions: TStrings;
    fCompletionComments: TStrings;
    fCompletionValues: TStrings;
    fEditor: TCustomSynEdit;
    fEditors: TList;
    fEOTokenChars: string;
    fCaseSensitive: boolean;
    fParsed: boolean;
    procedure CompletionListChanged(Sender: TObject);
    function GetCompletions: TStrings;
    function GetCompletionComments: TStrings;
    function GetCompletionValues: TStrings;
    function GetEditorCount: integer;
    function GetNthEditor(Index: integer): TCustomSynEdit;
    procedure ParseCompletionList; virtual;
    procedure SetAutoCompleteList(Value: TStrings); virtual;
    procedure SetEditor(Value: TCustomSynEdit);
    procedure SynEditCommandHandler(Sender: TObject; AfterProcessing: boolean;
      var Handled: boolean; var Command: TSynEditorCommand;
      var AChar: {$IFDEF SYN_LAZARUS}TUTF8Char{$ELSE}Char{$ENDIF};
      Data: pointer; HandlerData: pointer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure AddCompletion(AToken, AValue, AComment: string
      {$IFDEF SYN_LAZARUS}; TheAttributes: TStrings = nil{$ENDIF}
      );
    {$IFDEF SYN_LAZARUS}
    procedure DeleteCompletion(Index: integer);
    {$ENDIF}
    function AddEditor(AEditor: TCustomSynEdit): boolean;
    procedure Execute(AEditor: TCustomSynEdit); virtual;
    procedure ExecuteCompletion(AToken: string; AEditor: TCustomSynEdit);
      virtual;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation);
      override;
    function RemoveEditor(AEditor: TCustomSynEdit): boolean;
  public
    property AutoCompleteList: TStrings read fAutoCompleteList
      write SetAutoCompleteList;
    property CaseSensitive: boolean read fCaseSensitive write fCaseSensitive;
    property Completions: TStrings read GetCompletions;
    property CompletionComments: TStrings read GetCompletionComments;
    property CompletionValues: TStrings read GetCompletionValues;
    property Editor: TCustomSynEdit read fEditor write SetEditor;
    property EditorCount: integer read GetEditorCount;
    property Editors[Index: integer]: TCustomSynEdit read GetNthEditor;
    property EndOfTokenChr: string read fEOTokenChars write fEOTokenChars;
    {$IFDEF SYN_LAZARUS}
    property CompletionAttributes[Index: integer]: TStrings
                                                   read GetCompletionAttributes;
    property OnTokenNotFound: TOnTokenNotFound
      read fOnTokenNotFound write fOnTokenNotFound;
    property IndentToTokenStart: boolean
      read fIndentToTokenStart write fIndentToTokenStart;
    property OnExecuteCompletion: TOnExecuteCompletion read FOnExecuteCompletion
                                                     write FOnExecuteCompletion;
    {$ENDIF}
  end;

  { TSynEditAutoComplete }

  TSynEditAutoComplete = class(TCustomSynAutoComplete)
  published
    property AutoCompleteList;
    property CaseSensitive;
    property Editor;
    property EndOfTokenChr;
    {$IFDEF SYN_LAZARUS}
    property OnTokenNotFound;
    property IndentToTokenStart;
    property OnExecuteCompletion;
    {$ENDIF}
  end;

implementation

uses
  SysUtils, Menus;

{ TCustomSynAutoComplete }

procedure TCustomSynAutoComplete.AddCompletion(AToken, AValue, AComment: string
  {$IFDEF SYN_LAZARUS}; TheAttributes: TStrings {$ENDIF});
begin
  if AToken <> '' then begin
    fCompletions.Add(AToken);
    fCompletionComments.Add(AComment);
    fCompletionValues.Add(AValue);
    {$IFDEF SYN_LAZARUS}
    if TheAttributes=nil then
      TheAttributes:=TStringList.Create;
    fAttributes.Add(TheAttributes);
    {$ENDIF}
  end;
end;

function TCustomSynAutoComplete.AddEditor(AEditor: TCustomSynEdit): boolean;
var
  i: integer;
begin
  if AEditor <> nil then begin
    i := fEditors.IndexOf(AEditor);
    if i = -1 then begin
      AEditor.FreeNotification(Self);
      fEditors.Add(AEditor);
      if ComponentState * [csDesigning, csLoading] = [] then
        AEditor.RegisterCommandHandler({$IFDEF FPC}@{$ENDIF}SynEditCommandHandler, nil);
    end;
    Result := TRUE;
  end else
    Result := FALSE;
end;

procedure TCustomSynAutoComplete.CompletionListChanged(Sender: TObject);
begin
  fParsed := FALSE;
end;

constructor TCustomSynAutoComplete.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fAutoCompleteList := TStringList.Create;
  TStringList(fAutoCompleteList).OnChange :=
     {$IFDEF FPC}@{$ENDIF}CompletionListChanged;
  fCompletions := TStringList.Create;
  fCompletionComments := TStringList.Create;
  fCompletionValues := TStringList.Create;
  fEditors := TList.Create;
  fEOTokenChars := '()[]{}.';
  {$IFDEF SYN_LAZARUS}
  fAttributes:=TFPList.Create;
  {$ENDIF}
end;

{$IFDEF SYN_LAZARUS}
function TCustomSynAutoComplete.GetCompletionAttributes(Index: integer
  ): TStrings;
begin
  Result:=TStrings(fAttributes[Index]);
end;

procedure TCustomSynAutoComplete.ClearAttributes;
var
  i: Integer;
begin
  for i:=0 to fAttributes.Count-1 do
    TObject(fAttributes[i]).Free;
  fAttributes.Clear;
end;

procedure TCustomSynAutoComplete.DeleteCompletion(Index: integer);
begin
  fCompletions.Delete(Index);
  fCompletionComments.Delete(Index);
  fCompletionValues.Delete(Index);
  TObject(fAttributes[Index]).Free;
  fAttributes.Delete(Index);
end;
{$ENDIF}

destructor TCustomSynAutoComplete.Destroy;
begin
  fEditors.Free;
  fCompletions.Free;
  fCompletionComments.Free;
  fCompletionValues.Free;
  fAutoCompleteList.Free;
  {$IFDEF SYN_LAZARUS}
  ClearAttributes;
  fAttributes.Free;
  {$ENDIF}
  inherited Destroy;
end;

procedure TCustomSynAutoComplete.Execute(AEditor: TCustomSynEdit);
var
  s: string;
  i, j: integer;
begin
  if AEditor <> nil then begin
    // get token
    s := AEditor.LineText;
    j := AEditor.LogicalCaretXY.x;
    i := j - 1;
    if i <= Length(s) then begin
      while (i > 0) and (s[i] > ' ') and (Pos(s[i], fEOTokenChars) = 0) do
        Dec(i);
      Inc(i);
      s := Copy(s, i, j - i);
      ExecuteCompletion(s, AEditor);
    end else begin
      {$IFDEF SYN_LAZARUS}
      i:=-1;
      if Assigned(OnTokenNotFound) then
        OnTokenNotFound(Self,'',AEditor,i);
      if i>=0 then
        ExecuteCompletion(FCompletions[i], AEditor);
      {$ENDIF}
    end;
  end;
end;

procedure TCustomSynAutoComplete.ExecuteCompletion(AToken: string;
  AEditor: TCustomSynEdit);
var
  i, j, Len, IndentLen, TokenStartX: integer;
  s: string;
  IdxMaybe, NumMaybe: integer;
  p: TPoint;
  NewCaretPos: boolean;
  Temp: TStringList;
begin
  if not fParsed then
    ParseCompletionList;
  Len := Length(AToken);
  {$IFDEF SYN_LAZARUS}
  if (Len=0) and Assigned(OnTokenNotFound) then
    OnTokenNotFound(Self,AToken,AEditor,i);
  {$ENDIF}
  if (Len > 0) and (AEditor <> nil) and not AEditor.ReadOnly
    and (fCompletions.Count > 0)
  then begin
    // find completion for this token - not all chars necessary if unambiguous
    i := fCompletions.Count - 1;
    IdxMaybe := -1;
    NumMaybe := 0;
    if fCaseSensitive then begin
      while i > -1 do begin
        s := fCompletions[i];
        if AnsiCompareStr(s, AToken) = 0 then
          break
        else if AnsiCompareStr(Copy(s, 1, Len), AToken) = 0 then begin
          Inc(NumMaybe);
          IdxMaybe := i;
        end;
        Dec(i);
      end;
    end else begin
      while i > -1 do begin
        s := fCompletions[i];
        if AnsiCompareText(s, AToken) = 0 then
          break
        else if AnsiCompareText(Copy(s, 1, Len), AToken) = 0 then begin
          Inc(NumMaybe);
          IdxMaybe := i;
        end;
        Dec(i);
      end;
    end;
    if (i = -1) and (NumMaybe = 1) then
      i := IdxMaybe;
    {$IFDEF SYN_LAZARUS}
    if (i < 0) and Assigned(fOnTokenNotFound) then
      fOnTokenNotFound(Self,AToken,AEditor,i);
    {$ENDIF}
    if i > -1 then begin
      // select token in editor
      p := AEditor.LogicalCaretXY;
{begin}
      {$IFDEF SYN_LAZARUS}
      if Assigned(OnExecuteCompletion) then
        OnExecuteCompletion(Self,i)
      else begin
      {$ENDIF}
        AEditor.BeginUpdate;
        try
          {$IFDEF SYN_LAZARUS}
          TokenStartX:=p.x;
          s:=AEditor.Lines[p.y-1];
          if TokenStartX>length(s) then TokenStartX:=length(s);
          while (TokenStartX > 1) and (s[TokenStartX-1] > ' ')
          and (Pos(s[TokenStartX-1], fEOTokenChars) = 0) do
            Dec(TokenStartX);
          AEditor.BlockBegin := Point(TokenStartX, p.y);
          AEditor.BlockEnd := p;
          // indent the completion string if necessary, determine the caret pos
          if IndentToTokenStart then begin
            IndentLen := p.x - Len - 1;
          end else begin
            // indent the same as the first line
            IndentLen:=1;
            if (p.y>0) and (p.y<=AEditor.Lines.Count) then begin
              s:=AEditor.Lines[p.y-1];
              while (IndentLen<p.x)
              and ((IndentLen>length(s)) or (s[IndentLen]<=' ')) do
                inc(IndentLen);
            end;
            dec(IndentLen);
          end;
          {$ELSE}
          AEditor.BlockBegin := Point(p.x - Len, p.y);
          AEditor.BlockEnd := p;
          // indent the completion string if necessary, determine the caret pos
          IndentLen := p.x - Len - 1;
          {$ENDIF}
          p := AEditor.BlockBegin;
          NewCaretPos := FALSE;
          Temp := TStringList.Create;
          try
            Temp.Text := fCompletionValues[i];
            {$IFDEF SYN_LAZARUS}
            s:=fCompletionValues[i];
            if (s<>'') and (s[length(s)] in [#10,#13]) then
              Temp.Add('');
            {$ENDIF}

            // indent lines
            if (IndentLen > 0) and (Temp.Count > 1) then
            begin
              s := StringOfChar(' ', IndentLen);
              for i := 1 to Temp.Count - 1 do
                Temp[i] := s + Temp[i];
            end;
            // find first '|' and use it as caret position
            for i := 0 to Temp.Count - 1 do
            begin
              s := Temp[i];
              j := Pos('|', s);
              if j > 0 then
              begin
                Delete(s, j, 1);
                Temp[i] := s;
  //              if j > 1 then
  //                Dec(j);
                NewCaretPos := TRUE;
                Inc(p.y, i);
                if i = 0 then
  //                Inc(p.x, j)
                  Inc(p.x, j - 1)
                else
                  p.x := j;
                break;
              end;
            end;
            s := Temp.Text;
            // strip the trailing #13#10 that was appended by the stringlist
            i := Length(s);
            {$IFDEF SYN_LAZARUS}
            if (i>=1) and (s[i] in [#10,#13]) then begin
              dec(i);
              if (i>=1) and (s[i] in [#10,#13]) and (s[i]<>s[i+1]) then
                dec(i);
              SetLength(s, i);
            end;
            {$ENDIF}
          finally
            Temp.Free;
          end;
          // replace the selected text and position the caret
          AEditor.SelText := s;
          if NewCaretPos then
            AEditor.CaretXY := p;
          {$IFDEF SYN_LAZARUS}
          AEditor.EnsureCursorPosVisible;
          {$ENDIF}
        finally
          AEditor.EndUpdate;
        end;
      {$IFDEF SYN_LAZARUS}
      end;
      {$ENDIF}
{end}                                                                           //mh 2000-11-08
    end;
  end;
end;

function TCustomSynAutoComplete.GetCompletions: TStrings;
begin
  if not fParsed then
    ParseCompletionList;
  Result := fCompletions;
end;

function TCustomSynAutoComplete.GetCompletionComments: TStrings;
begin
  if not fParsed then
    ParseCompletionList;
  Result := fCompletionComments;
end;

function TCustomSynAutoComplete.GetCompletionValues: TStrings;
begin
  if not fParsed then
    ParseCompletionList;
  Result := fCompletionValues;
end;

function TCustomSynAutoComplete.GetEditorCount: integer;
begin
  Result := fEditors.Count;
end;

function TCustomSynAutoComplete.GetNthEditor(Index: integer): TCustomSynEdit;
begin
  if (Index >= 0) and (Index < fEditors.Count) then
    Result := TCustomSynEdit(fEditors[Index])
  else
    Result := nil;
end;

procedure TCustomSynAutoComplete.Loaded;
var
  i: integer;
  O: TObject;
begin
  inherited Loaded;
  for i := 0 to fEditors.Count - 1 do begin
    O := TObject(fEditors[i]);
    (O as TCustomSynEdit).RegisterCommandHandler(
       {$IFDEF FPC}@{$ENDIF}SynEditCommandHandler, nil);
  end;
end;

procedure TCustomSynAutoComplete.Notification(AComponent: TComponent;
  Operation: TOperation);
var
  i: integer;
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove)
  {$IFDEF SYN_LAZARUS}and (AComponent is TCustomSynEdit){$ENDIF} then begin
    i := fEditors.IndexOf(AComponent);
    if i > -1 then
      RemoveEditor(AComponent as TCustomSynEdit);
  end;
end;

procedure TCustomSynAutoComplete.ParseCompletionList;

  {$IFDEF SYN_LAZARUS}
  procedure RemoveFirstLine(var Pattern: string);
  var
    i: Integer;
  begin
    // remove first line (i.e. macro enabled flag)
    i:=1;
    while (i<=length(Pattern)) and (not (Pattern[i] in [#10,#13])) do inc(i);
    if (i<length(Pattern)) and (Pattern[i+1] in [#10,#13])
    and (Pattern[i+1]<>Pattern[i]) then
      inc(i);
    Pattern:=copy(Pattern,i+1,length(Pattern));
  end;
  {$ENDIF}

var
  BorlandDCI: boolean;
  i, j, Len: integer;
  s, sCompl, sComment, sComplValue: string;
  {$IFDEF SYN_LAZARUS}
  TemplateStarted: Boolean;
  {$ENDIF}

  procedure SaveEntry;
  {$IFDEF SYN_LAZARUS}
  var
    CurAttributes: TStrings;
    Lines: TStringList;
    LastLineHasEnding: boolean;
    l: Integer;
  {$ENDIF}
  begin
    fCompletions.Add(sCompl);
    sCompl := '';
    fCompletionComments.Add(sComment);
    sComment := '';
    {$IFDEF SYN_LAZARUS}
    CurAttributes:=TStringList.Create;
    if copy(sComplValue,1,length(CodeTemplateMacroMagic))=CodeTemplateMacroMagic
    then begin
      RemoveFirstLine(sComplValue);
      CurAttributes.Values[CodeTemplateEnableMacros]:='true';
    end else if copy(sComplValue,1,length(CodeTemplateAttributesStartMagic))
      =CodeTemplateAttributesStartMagic
    then begin
      Lines:=TStringList.Create;
      Lines.Text:=sComplValue;
      LastLineHasEnding:=(sComplValue<>'') and (sComplValue[length(sComplValue)] in [#10,#13]);
      Lines.Delete(0);
      while (Lines.Count>0) and (Lines[0]<>CodeTemplateAttributesEndMagic) do
      begin
        CurAttributes.Add(Lines[0]);
        Lines.Delete(0);
      end;
      if Lines.Count>0 then
        Lines.Delete(0);
      sComplValue:=Lines.Text;
      if not LastLineHasEnding then begin
        l:=length(sComplValue);
        if (l>0) and (sComplValue[l] in [#10,#13]) then begin
          dec(l);
          if (l>0) and (sComplValue[l] in [#10,#13])
          and (sComplValue[l]<>sComplValue[l+1]) then
            dec(l);
          sComplValue:=copy(sComplValue,1,l);
        end;
      end;
      Lines.Free;
    end;
    {$ENDIF}
    fCompletionValues.Add(sComplValue);
    sComplValue := '';
    fAttributes.Add(CurAttributes);
  end;

begin
  fCompletions.Clear;
  fCompletionComments.Clear;
  fCompletionValues.Clear;
  ClearAttributes;

  if fAutoCompleteList.Count > 0 then begin
    s := fAutoCompleteList[0];
    BorlandDCI := (s <> '') and (s[1] = '[');

    sCompl := '';
    sComment := '';
    sComplValue := '';
    {$IFDEF SYN_LAZARUS}
    TemplateStarted:=false;
    {$ENDIF}
    for i := 0 to fAutoCompleteList.Count - 1 do begin
      s := fAutoCompleteList[i];
      Len := Length(s);
      if BorlandDCI then begin
        // the style of the Delphi32.dci file
        if (Len > 0) and (s[1] = '[') then begin
          // save last entry
          if sCompl <> '' then
            SaveEntry;
          // new completion entry
          j := 2;
          while (j <= Len) and (s[j] > ' ') do
            Inc(j);
          sCompl := Copy(s, 2, j - 2);
          // start of comment in DCI file
          while (j <= Len) and (s[j] <= ' ') do
            Inc(j);
          if (j <= Len) and (s[j] = '|') then
            Inc(j);
          while (j <= Len) and (s[j] <= ' ') do
            Inc(j);
          sComment := Copy(s, j, Len);
          if sComment[Length(sComment)] = ']' then
            SetLength(sComment, Length(sComment) - 1);
          {$IFDEF SYN_LAZARUS}
          TemplateStarted:=true;
          {$ENDIF}
        end else begin
          {$IFDEF SYN_LAZARUS}
          if not TemplateStarted then
            sComplValue := sComplValue + #13#10;
          TemplateStarted:=false;
          {$ELSE}
          if sComplValue <> '' then
            sComplValue := sComplValue + #13#10;
          {$ENDIF}
          sComplValue := sComplValue + s;
        end;
      end else begin
        // the original style
        if (Len > 0) and (s[1] <> '=') then begin
          // save last entry
          if sCompl <> '' then
            SaveEntry;
          // new completion entry
          sCompl := s;
          {$IFDEF SYN_LAZARUS}
          TemplateStarted:=true;
          {$ENDIF}
        end else if (Len > 0) and (s[1] = '=') then begin
          {$IFDEF SYN_LAZARUS}
          if not TemplateStarted then
            sComplValue := sComplValue + #13#10;
          TemplateStarted:=false;
          {$ELSE}
          if sComplValue <> '' then
            sComplValue := sComplValue + #13#10;
          {$ENDIF}
          sComplValue := sComplValue + Copy(s, 2, Len);
        end;
      end;
    end;
    if sCompl <> '' then                                                        //mg 2000-11-07
      SaveEntry;
  end;
  {$IFDEF SYN_LAZARUS}
  fParsed:=true;
  {$ENDIF}
end;

function TCustomSynAutoComplete.RemoveEditor(AEditor: TCustomSynEdit): boolean;
var
  i: integer;
begin
  if AEditor <> nil then begin
    i := fEditors.IndexOf(AEditor);
    if i > -1 then begin
      if fEditor = AEditor then
        fEditor := nil;
      fEditors.Delete(i);
      AEditor.RemoveFreeNotification(Self);
      if ComponentState * [csDesigning, csLoading] = [] then
        AEditor.UnregisterCommandHandler(
          {$IFDEF FPC}@{$ENDIF}SynEditCommandHandler);
    end;
  end;
  Result := FALSE;
end;

procedure TCustomSynAutoComplete.SetAutoCompleteList(Value: TStrings);
begin
  fAutoCompleteList.Assign(Value);
  fParsed := FALSE;
end;

procedure TCustomSynAutoComplete.SetEditor(Value: TCustomSynEdit);
begin
  if Value <> fEditor then begin
    if fEditor <> nil then
      RemoveEditor(fEditor);
    fEditor := nil;
    if (Value <> nil) and AddEditor(Value) then
      fEditor := Value;
  end;
end;

procedure TCustomSynAutoComplete.SynEditCommandHandler(Sender: TObject;
  AfterProcessing: boolean; var Handled: boolean;
  var Command: TSynEditorCommand;
  var AChar: {$IFDEF SYN_LAZARUS}TUTF8Char{$ELSE}Char{$ENDIF}; Data: pointer;
  HandlerData: pointer);
begin
  if not AfterProcessing and not Handled and (Command = ecAutoCompletion) then
  begin
    Handled := TRUE;
    Execute(Sender as TCustomSynEdit);
  end;
end;

end.

