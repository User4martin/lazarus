{
 /***************************************************************************
                               stringhashlist.pas
                               ------------------
                             Component Library Code


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

  Thanks to Markus Waldenburg.

}
unit StringHashList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLStrConsts;

type
  PStringHashItem = ^TStringHashItem;
  TStringHashItem = record
    HashValue: Cardinal;
    Key: String;
    Data: Pointer;
  end;

  PStringHashItemList = ^PStringHashItem;

  TStringHashList = class(TObject)
  private
    FList: PStringHashItemList;
    FCount: Integer;
    fCaseSensitive: Boolean;
    function CompareString(const Value1, Value2: String): Boolean;
    function CompareValue(const Value1, Value2: Cardinal): Integer;
    function GetData(const S: String): Pointer;
    procedure SetCaseSensitive(const Value: Boolean);
    procedure Delete(Index: Integer);
    procedure SetData(const S: String; const AValue: Pointer);
  protected
    function HashOf(const Key: string): Cardinal;
    procedure Insert(Index: Integer; Item: PStringHashItem);
  public
    constructor Create(CaseSensitivity: boolean);
    destructor Destroy; override;
    function Add(const S: String): Integer;
    function Add(const S: String; ItemData: Pointer): Integer;
    procedure Clear;
    function Find(const S: String): Integer;
    function Remove(const S: String): Integer;
    property CaseSensitive: Boolean read fCaseSensitive write SetCaseSensitive;
    property Count: Integer read FCount;
    property Data[const S: String]: Pointer read GetData write SetData; default;
    property List: PStringHashItemList read FList;
  end;


implementation

var
  UpperCaseChars: array[char] of char;

{ TStringHashList }

function TStringHashList.Add(const S: String): Integer;
begin
  Result:=Add(S,nil);
end;

function TStringHashList.Add(const S: String; ItemData: Pointer): Integer;
var
  Item: PStringHashItem;
  First, Last, I: Integer;
  Val: Cardinal;
  Larger: boolean;
begin
  New(Item);
  Val:= HashOf(S);
  Item^.HashValue := Val;
  Item^.Key := S;
  Item^.Data := ItemData;
  if FCount > 0 then
  begin
    First:=0;
    Last:= FCount-1;
    Larger:=False;
    while First<=Last do
    begin
      I:=(First+Last)shr 1;
      Case CompareValue(Val, fList[I]^.HashValue)<=0 of
        True:
          begin
            Last:=I-1;
            Larger:=False;
          end;
        False:
          begin
            First:=I+1;
            Larger:=True;
          end;
      end;
    end;
    Case Larger of
      True: Result:=I+1;
      False: Result:=I;
    end;
  end else
    Result:=0;
  Insert(Result,Item);
end;

procedure TStringHashList.Clear;
var
  I: Integer;
begin
  if fCount = 0 then exit;
  for I:= 0 to fCount -1 do
    Dispose(fList[I]);
  if FList<>nil then begin
    FreeMem(FList);
    FList:=nil;
  end;
  fCount:= 0;
end;

function TStringHashList.CompareString(const Value1, Value2: String): Boolean;
var
  I, Len: Integer;
  P1,P2: PChar;
begin
  Result:= False;
  P1:= PChar(Value1);
  Len:= Length(Value1);
  P2:= PChar(Value2);
  if Len = Length(Value2) then
  begin
    Result:= True;
    case fCaseSensitive of
    True:
      for I:= Len -1 downto 0 do
        if P1[I] <> P2[I] then begin
          Result:= False;
          break;
        end;
    False:
      for I:= Len -1 downto 0 do
        if UpperCaseChars[P1[I]] <> UpperCaseChars[P2[I]] then begin
          Result:= False;
          break;
        end;
    end;
  end;
end;

function TStringHashList.CompareValue(const Value1, Value2: Cardinal): Integer;
begin
  Result:= 0;
  if Value1 > Value2 then
    Result:= 1
  else if Value1 < Value2 then
    Result:= -1;
end;

function TStringHashList.GetData(const S: String): Pointer;
var i: integer;
begin
  i:=Find(S);
  if i>=0 then
    Result:=FList[i]^.Data
  else
    Result:=nil;
end;

procedure TStringHashList.Delete(Index: Integer);
begin
  if (Index >= 0) and (Index < FCount) then
  begin
    dec(FCount);
    if Index < FCount then
      System.Move(FList[Index + 1], FList[Index],
        (FCount - Index) * SizeOf(PStringHashItem));
  end;
end;

procedure TStringHashList.SetData(const S: String; const AValue: Pointer);
var i: integer;
begin
  i:=Find(S);
  if i>=0 then
    FList[i]^.Data:=AValue
  else
    Add(S,AValue);
end;

destructor TStringHashList.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TStringHashList.Find(const S: String): Integer;
var
  Value: Cardinal;
  First, Last, Temp, I: Integer;
begin
  Value:= HashOf(s);
  Result:= -1;
  First:= 0;
  Last:= Count -1;
  while First <= Last do
  begin
    Temp:= (First + Last) div 2;
    case CompareValue(Value, FList[Temp]^.HashValue) of
     1: First:= Temp + 1;
     0:
       begin
         Result:= Temp;
         if CompareString(S, FList[Temp]^.Key) then
           exit
         else
           break;
       end;
     -1: Last:= Temp-1;
    end;
    end;
  if Result <> -1 then
  begin
    Result:= -1;
    First:= Temp -1;
    if First > 0 then
    while CompareValue(Value, FList[First]^.HashValue) = 0 do
      dec(First);
    inc(First);
    Last:= Temp +1;
    if Last < Count -1 then
    while CompareValue(Value, FList[Last]^.HashValue) = 0 do
      inc(Last);
    dec(Last);
    for I:= First to Last do
      if CompareString(S, FList[I]^.Key) then
      begin
        Result:= I;
        Exit;
      end;
  end;
end;

function TStringHashList.HashOf(const Key: string): Cardinal;
var
  P: PChar;
  I, Len: Integer;
begin
  P:= PChar(Key);
  Len:= Length(Key);
  Result := Len;  
  {$IFOPT R+}{$DEFINE RangeChecking}{$ELSE}{$UNDEF RangeChecking}{$ENDIF}
  {$IFOPT Q+}{$DEFINE OverflowChecking}{$ELSE}{$UNDEF OverflowChecking}{$ENDIF}
  {$R-}{$Q-}
  // use the last 30 characters to compute the hash
  case fCaseSensitive of
    True:
      for I := Len - 1 downto 0 do
        inc(Result, cardinal(ord(P[I])) shl I);
    False:
      for I := Len - 1 downto 0 do
        inc(Result, cardinal(ord(UpperCaseChars[P[I]])) shl I);
  end;
  {$IFDEF OverflowChecking}{$Q+}{$UNDEF OverflowChecking}{$ENDIF}
  {$IFDEF RangeChecking}{$R+}{$UNDEF RangeChecking}{$ENDIF}
end;

procedure TStringHashList.Insert(Index: Integer; Item: PStringHashItem);
begin
  ReallocMem(FList, (fCount +1) * SizeOf(PStringHashItem));
  if Index > fCount then Index:= fCount;
  if Index < 0 then Index:= 0;
  if Index < FCount then
    System.Move(FList[Index], FList[Index + 1],
      (FCount - Index) * SizeOf(PStringHashItem));
  FList[Index] := Item;
  Inc(FCount);
end;

constructor TStringHashList.Create(CaseSensitivity: boolean);
begin
  fCaseSensitive:=CaseSensitivity;
  inherited Create;
end;

function TStringHashList.Remove(const S: String): Integer;
begin
  Result:= Find(S);
  if Result > -1 then
  begin
    Dispose(fList[Result]);
    Delete(Result);
  end;
end;

procedure TStringHashList.SetCaseSensitive(const Value: Boolean);
begin
  if fCaseSensitive <> Value then
  begin
    if Count > 0 then
    begin
      raise EListError.Create(rsListMustBeEmpty);
      exit;
    end;
    fCaseSensitive := Value;
  end;
end;

//------------------------------------------------------------------------------
procedure InternalInit;
var c: char;
begin
  for c:=Low(char) to High(char) do begin
    UpperCaseChars[c]:=upcase(c);
  end;
end;

initialization
  InternalInit;

end.
