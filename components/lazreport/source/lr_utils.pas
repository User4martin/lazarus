
{*****************************************}
{                                         }
{             FastReport v2.3             }
{            Various routines             }
{                                         }
{  Copyright (c) 1998-99 by Tzyganenko A. }
{                                         }
{*****************************************}

unit LR_Utils;

interface

{$I LR_Vers.inc}

uses
  SysUtils, Classes, Graphics, Controls,
  LR_DBRel, Forms, StdCtrls, ClipBrd, Menus,db,
  {$IFDEF WIN32}
  Windows,
  {$ENDIF}
  LCLType,LCLIntf,LCLProc;


procedure frReadMemo(Stream: TStream; l: TStrings);
procedure frReadMemo22(Stream: TStream; l: TStrings);
procedure frWriteMemo(Stream: TStream; l: TStrings);
function frReadString(Stream: TStream): String;
function frReadString22(Stream: TStream): String;
{$IFDEF FREEREP2217READ}
function frReadMemoText2217(Stream: TStream): String;
function frReadString2217(Stream: TStream): String;
{$ENDIF}
procedure frWriteString(Stream: TStream; s: String);
procedure frEnableControls(c: Array of TControl; e: Boolean);
function frControlAtPos(Win: TWinControl; p: TPoint): TControl;
function frGetDataSet(const ComplexName: String): TfrTDataSet;
procedure frGetDataSetAndField(ComplexName: String;
  var DataSet: TfrTDataSet; out Field: TfrTField);
function frGetFontStyle(Style: TFontStyles): Integer;
function frSetFontStyle(Style: Integer): TFontStyles;
procedure frInitFont(aFont : TFont; aColor : TColor; {%H-}aSize : Integer; aStyle : TFontStyles);
function frFindComponent(Owner: TComponent; const Name: String): TComponent;
procedure frGetComponents(Owner: TComponent; ClassRef: TClass;
  List: TStrings; Skip: TComponent);

function frGetWindowsVersion: String;

function frTypeObjectToStr(ot : Byte):string;
function StrTofrTypeObject(St : string) : Byte;


function lrGetUnBrackedStr(const S:string):string; //remove '[' from begion of string and ']' from end
function lrValidFieldReference(s: string):boolean;

// utf8 tools
function UTF8Desc(S:string; var Desc: string): Integer;
function UTF8Char(S:string; index:Integer; Desc:string): TUTF8Char;
function UTF8Range(S:string; index,count:Integer; Desc:String):string;
function UTF8Index(index:integer; desc:string): Integer;
function UTF8CharIn(ch:TUTF8Char; const arrstr:array of string): boolean;
function UTF8QuotedStr(s:string; Quote: TUTF8Char; desc:string=''): string;

implementation

uses LR_Class, LR_Const;

procedure frInitFont(aFont : TFont; aColor : TColor; aSize : Integer; aStyle : TFontStyles);
begin
  with aFont do
  begin
    aFont.BeginUpdate;
    try
      aFont.Name :='default';
      aFont.Color:=aColor;
      aFont.Size :=0; //aSize;
      aFont.Style:=aStyle;
      aFont.Pitch:=fpDefault; //fpFixed;
      aFont.CharSet:=1;
    finally
      aFont.EndUpdate;
    end;
  end;
end;

function frSetFontStyle(Style: Integer): TFontStyles;
begin
  Result := [];
  if (Style and $1) <> 0 then Result := Result + [fsItalic];
  if (Style and $2) <> 0 then Result := Result + [fsBold];
  if (Style and $4) <> 0 then Result := Result + [fsUnderLine];
end;

function frGetFontStyle(Style: TFontStyles): Integer;
begin
  Result := 0;
  if fsItalic in Style then Result := Result or $1;
  if fsBold in Style then Result := Result or $2;
  if fsUnderline in Style then Result := Result or $4;
end;

procedure RemoveQuotes(var s: String);
begin
  if (s[1] = '"') and (s[Length(s)] = '"') then
    s := Copy(s, 2, Length(s) - 2);
end;

procedure frReadMemo(Stream: TStream; l: TStrings);
var
  s: String;
  b: Byte;
  n: Word;
begin
  l.Clear;
  n := 0;
  Stream.Read(n, 2);
  if n > 0 then
    repeat
      Stream.Read(n, 2);
      SetLength(s, n);
      Stream.Read(s[1], n);
      l.Add(s);
      b := 0;
      Stream.Read(b, 1);
    until b = 0
  else
    Stream.Read(b, 1);
end;

procedure frWriteMemo(Stream: TStream; l: TStrings);
var
  s: String;
  i: Integer;
  n: Word;
  b: Byte;
begin
  n := l.Count;
  Stream.Write(n, 2);
  for i := 0 to l.Count - 1 do
  begin
    s := l[i];
    n := Length(s);
    Stream.Write(n, 2);
    Stream.Write(s[1], n);
    b := 13;
    if i <> l.Count - 1 then Stream.Write(b, 1);
  end;
  b := 0;
  Stream.Write(b, 1);
end;

function frReadString(Stream: TStream): String;
var
  s: String;
  n: Word;
  b: Byte;
begin
  n := 0;
  Stream.Read(n, 2);
  SetLength(s, n);
  Stream.Read(s[1], n);
  b := 0;
  Stream.Read(b, 1);
  Result := s;
end;

procedure frWriteString(Stream: TStream; s: String);
var
  b: Byte;
  n: Word;
begin
  n := Length(s);
  Stream.Write(n, 2);
  Stream.Write(s[1], n);
  b := 0;
  Stream.Write(b, 1);
end;

procedure frReadMemo22(Stream: TStream; l: TStrings);
var
  s: String;
  i: Integer;
  b: Byte;
begin
  SetLength(s, 4096);
  l.Clear;
  i := 1;
  repeat
    b := 0;
    Stream.Read(b,1);
    if (b = 13) or (b = 0) then
    begin
      SetLength(s, i - 1);
      if not ((b = 0) and (i = 1)) then l.Add(s);
      SetLength(s, 4096);
      i := 1;
    end
    else if b <> 0 then
    begin
      s[i] := Chr(b);
      Inc(i);
      if i > 4096 then
        SetLength(s, Length(s) + 4096);
    end;
  until b = 0;
end;

function frReadString22(Stream: TStream): String;
var
  s: String;
  i: Integer;
  b: Byte;
begin
  SetLength(s, 4096);
  i := 1;
  repeat
    b := 0;
    Stream.Read(b, 1);
    if b = 0 then
      SetLength(s, i - 1)
    else
    begin
      s[i] := Chr(b);
      Inc(i);
      if i > 4096 then
        SetLength(s, Length(s) + 4096);
    end;
  until b = 0;
  Result := s;
end;

{$IFDEF FREEREP2217READ}
function frReadMemoText2217(Stream: TStream): String;
var
  I: Integer;
begin
  Stream.ReadBuffer(I, SizeOf(I));
  SetLength(Result, I);
  Stream.ReadBuffer(PChar(Result)^, I);
end;

function frReadString2217(Stream: TStream): String;
var
  I: Integer;
begin
  Result := frReadMemoText2217(Stream);
  I := Pos(#13, Result);
  if I > 0 then
    Result := Copy(Result, 1, I - 1);
end;
{$ENDIF}

type
  THackWinControl = class(TWinControl)
  end;

procedure frEnableControls(c: Array of TControl; e: Boolean);
const
  Clr1: Array[Boolean] of TColor = (clGrayText,clWindowText);
  Clr2: Array[Boolean] of TColor = (clBtnFace,clWindow);
var
  i: Integer;
begin
  for i := Low(c) to High(c) do
    if c[i] is TLabel then
      with c[i] as TLabel do
      begin
        Font.Color := Clr1[e];
        Enabled := e;
      end
    else if c[i] is TWinControl then
      with THackWinControl(c[i]) do
      begin
        Color := Clr2[e];
        Enabled := e;
      end;
end;

function frControlAtPos(Win: TWinControl; p: TPoint): TControl;
var
  i: Integer;
  c: TControl;
  p1: TPoint;
begin
  Result := nil;
  with Win do
  begin
    for i := ControlCount - 1 downto 0 do
    begin
      c := Controls[i];
      if c.Visible and PtInRect(Classes.Rect(c.Left, c.Top, c.Left + c.Width, c.Top + c.Height), p) then
        if (c is TWinControl) and (csAcceptsControls in c.ControlStyle) and
           (TWinControl(c).ControlCount > 0) then
        begin
          p1 := p;
          Dec(p1.X, c.Left); Dec(p1.Y, c.Top);
          c := frControlAtPos(TWinControl(c), p1);
          if c <> nil then
          begin
            Result := c;
            Exit;
          end;
        end
        else
        begin
          Result := c;
          Exit;
        end;
    end;
  end;
end;

function frGetDataSet(const ComplexName: String): TfrTDataSet;
var
  Component: TComponent;
begin
  Component := frFindComponent(CurReport.Owner, ComplexName);
  if Assigned(Component) then
  begin
    if Component is TDataSet then
      Result := TfrTDataSet(Component)
    else if Component is TDataSource then
      Result := TfrTDataSet(TDataSource(Component).DataSet);
  end
  else
    Result := nil;
end;

procedure frGetDataSetAndField(ComplexName: String; var DataSet: TfrTDataSet;
  out Field: TfrTField);
var
  n: Integer;
  Owner, Component: TComponent;
  s1, s2, s3, s4: String;
begin
  Field := nil;
  Owner := CurReport.Owner;
  n := Pos('.', ComplexName);
  if n <> 0 then
  begin
    s1 := Copy(ComplexName, 1, n - 1);        // table name
    s2 := Copy(ComplexName, n + 1, 255);      // field name
    if Pos('.', s2) <> 0 then                 // module name present
    begin
      s3 := Copy(s2, Pos('.', s2) + 1, 255);
      s2 := Copy(s2, 1, Pos('.', s2) - 1);
      Owner:=FindGlobalComponent(S1);
      if Owner <> nil then
      begin
        n:=Pos('.', S3);                      //test for frame name
        if n>0 then                           //if frame name present
        begin
          S4:=Copy(S3, 1, n-1);
          Delete(S3, 1, n);
          Owner:=Owner.FindComponent(S2);
          if Assigned(Owner)then
            DataSet := TfrTDataSet(Owner.FindComponent(s4));
        end
        else
          DataSet := TfrTDataSet(Owner.FindComponent(s2));
        RemoveQuotes(s3);
        if DataSet <> nil then
          Field := TfrTField(DataSet.FindField(s3));
      end;
    end
    else
    begin
      Component := frFindComponent(Owner, s1);
      if Assigned(Component) then
        begin
          if Component is TDataSet then
            DataSet := TfrTDataSet(Component)
          else if Component is TDataSource then
            DataSet := TfrTDataSet(TDataSource(Component).DataSet);
        end;
      RemoveQuotes(s2);
      if DataSet <> nil then
        Field := TfrTField(DataSet.FindField(s2));
    end;
  end
  else if DataSet <> nil then
  begin
    RemoveQuotes(ComplexName);
    Field := TfrTField(DataSet.FindField(ComplexName));
  end;
end;

function frFindComponent(Owner: TComponent; const Name: String): TComponent;
var
  n: Integer;
  s1, s2, s3: String;
begin
  Result := nil;
  n := Pos('.', Name);
  try
    if n = 0 then
      Result := Owner.FindComponent(Name)
    else
    begin
      s1 := Copy(Name, 1, n - 1);        // module name
      s2 := Copy(Name, n + 1, Length(Name));      // component name

      n := Pos('.', S2); //check for frames
      if n = 0 then
        S3:=''
      else
      begin
        s3 := Copy(S2, 1, n - 1);        // module name
        Delete(S2, 1, n);
      end;

      Owner := FindGlobalComponent(s1);
      if Owner <> nil then
      begin
        if s3<>'' then
          Owner:=Owner.FindComponent(s3);
        if Assigned(Owner) then
          Result := Owner.FindComponent(s2);
      end;
    end;
  except
    on Exception do
      raise EClassNotFound.CreateFmt(sObjectNotFound, [Name]);
  end;
end;

{$HINTS OFF}
procedure frGetComponents(Owner: TComponent; ClassRef: TClass;
  List: TStrings; Skip: TComponent);
var
  i, j: Integer;

  procedure EnumComponents(f: TComponent);
  var
    i: Integer;
    c: TComponent;
  begin
{$IFDEF Delphi5}
    if f is TForm then
      for i := 0 to TForm(f).ControlCount - 1 do
      begin
        c := TForm(f).Controls[i];
        if c is TFrame then
          EnumComponents(c);
      end;
{$ENDIF}
    for i := 0 to f.ComponentCount - 1 do
    begin
      c := f.Components[i];
      if c is TFrame then
        EnumComponents(c)
      else
      if (c <> Skip) and (c is ClassRef) then
        if f = Owner then
          List.Add(c.Name)
        else
        if ((f is TForm) or (f is TDataModule) or (f is TFrame)) then
          List.Add(f.Name + '.' + c.Name)
        else
          List.Add(TControl(f).Owner.Name + '.' + f.Name + '.' + c.Name)
    end;
  end;

begin
  {$IFDEF DebugLR}
  DebugLn('frGetComponents 1');
  {$ENDIF}
  List.Clear;
  for i := 0 to Screen.FormCount - 1 do
    EnumComponents(Screen.Forms[i]);

  {$IFDEF DebugLR}
  DebugLn('frGetComponents 2');
  {$ENDIF}
  for i := 0 to Screen.DataModuleCount - 1 do
    EnumComponents(Screen.DataModules[i]);

  with Screen do
  begin
    {$IFDEF DebugLR}
    DebugLn('frGetComponents 3');
    {$ENDIF}
    for i := 0 to CustomFormCount - 1 do
    begin
      with CustomForms[i] do
      begin
        if (UpperCase(ClassName)='TDATAMODULEFORM')  then
          for j := 0 to ComponentCount - 1 do
          begin
            if (Components[j] is TDataModule) then
              EnumComponents(Components[j]);
          end;
      end;
    end;
  end;
end;
{$HINTS ON}  

function frGetWindowsVersion: String;
{$IFDEF WIN32}
var Ver: TOsVersionInfo;
begin
  Ver.dwOSVersionInfoSize := SizeOf(Ver);
  GetVersionEx(Ver);
  with Ver do begin
    case dwPlatformId of
      VER_PLATFORM_WIN32s: Result := '32s';
      VER_PLATFORM_WIN32_WINDOWS:
        begin
          dwBuildNumber := dwBuildNumber and $0000FFFF;
          if (dwMajorVersion > 4) or ((dwMajorVersion = 4) and
            (dwMinorVersion >= 10)) then
            Result := '98' else
            Result := '95';
        end;
      VER_PLATFORM_WIN32_NT: Result := 'NT';
    end;
  end;
end;
{$ELSE}
begin
  Result:='LINUX';
end;
{$ENDIF}

{**
* Return the string value of type object
**}
function frTypeObjectToStr(ot : Byte): string;
begin
  Result:='undef';
  Case ot of
    gtMemo     : result:='gtMemo';
    gtPicture  : result:='gtPicture';
    gtBand     : result:='gtBand';
    gtSubReport: result:='gtSubReport';
    gtLine     : result:='gtLine';
    gtAddIn    : result:='gtAddIn';
  end;
end;

function StrTofrTypeObject(St : string) : Byte;
begin
  Result:=StrToIntDef(St,gtMemo);
  
  if SameText(St,'gtMemo') then
    result:=gtMemo
  else
    if SameText(St,'gtPicture') then
      result:=gtPicture
    else
     if SameText(St,'gtBand') then
       result:=gtBand
      else
       if SameText(St,'gtSubReport') then
          result:=gtSubReport
       else
        if SameText(St,'gtLine') then
          result:=gtLine
        else
         if SameText(St,'gtAddIn') then
           result:=gtAddIn;
end;

function lrGetUnBrackedStr(const S: string): string;
var
  Cnt, i:integer;
begin
  Cnt:=Length(S);
  if (Cnt>2) and (S[1]='[') then
  begin
    for i := Cnt downto 2 do
      if S[i]=']' then
      begin
        Result:=Copy(S, 2, i-2);
        exit;
      end;
  end;
  Result:=S;
end;

function lrValidFieldReference(s: string): boolean;
var
  i,j,k,n: Integer;
begin
  result := false;

  s := lrGetUnbrackedStr(Trim(s));

  if length(s)<3 then
    exit;

  n := 0;
  i := Length(s);
  while i>0 do begin

    // get item
    j := i;
    while (i>0) and (s[i]<>'.') do
      dec(i);

    // validate item
    k := i+1;

    // trim
    while (k<=j) and (s[k] in [' ',#9]) do
      inc(k);
    while (j>=k) and (s[j] in [' ',#9,#10,#13]) do
      dec(j);

    if s[k]='"' then  // quoted field

      result := (n=0) and (j>(k+1)) and (s[j]='"')

    else begin  // identifier

      result := (k<=j) and (s[k] in ['A'..'Z','a'..'z','_']);
      inc(k);
      while result and (k<=j) do begin
        result := result and (s[k] in ['A'..'Z','a'..'z','0'..'9','_']);
        inc(k);
      end;

    end;

    if not result then
      exit;

    inc(n);
    dec(i);
  end;
  result := n>1;
end;

function UTF8Desc(S: string; var Desc: string): Integer;
var
    i,b: Integer;
begin
  i := 1;
  Result := 0;
  SetLength(Desc, Length(S));
  while i<=Length(s) do begin
    b := UTF8CharacterStrictLength(@S[i]);
    inc(i,b);
    inc(Result);
    Desc[Result] := Char(b);
  end;
  Setlength(Desc, Result);
end;

function UTF8Char(S: string; index: Integer; Desc: string): TUTF8Char;
var
  i,j: Integer;
begin
  Result := '';
  if (index<1) or (index>Length(Desc)) then begin
    //Result := #$EF#$BF#$BD  // replacement character
    exit;
  end;

  i:=0; j:=1;
  while i<Length(Desc) do begin
    inc(i);
    if i=index then begin
      Move(S[j],Result[1],ord(Desc[i]));
      Result[0]:=Desc[i];
      break;
    end;
    inc(j, ord(Desc[i]));
  end;

end;

function UTF8Range(S: string; index, count: Integer; Desc: String
  ): string;
var
  c,i: Integer;
begin
  result := '';
  c := 0;
  i := index;
  while (Count>0) and (i<=Length(Desc)) do begin
    c := c + ord(Desc[i]);
    inc(i);
    Dec(Count);
  end;
  i := UTF8Index(Index, Desc);
  if i>0 then begin
    SetLength(Result, c);
    Move(S[i],Result[1],c);
  end;
end;

// this assume index is in valid range
function UTF8Index(index: integer; desc: string): Integer;
var
  i,c: integer;
begin
  result := 0;
  c := 0;
  for i:=1 to Length(Desc) do begin
    inc(c);
    if i=index then begin
      result := c;
      break;
    end;
    c := c + ord(Desc[i]) - 1;
  end;
end;

function UTF8CharIn(ch:TUTF8Char; const arrstr: array of string): boolean;
var
  i: Integer;
begin
  result := false;
  for i:=low(arrstr) to high(arrstr) do
    if arrstr[i]=ch then begin
      result := true;
      break;
    end;
end;

// converted from FPC AnsiQuotedStr()
function UTF8QuotedStr(s: string; Quote: TUTF8Char; desc:string=''): string;
var
    i, j, count: integer;
begin
  result := '' + Quote;
  if desc='' then
    count := UTF8Desc(s, desc)
  else
    count := length(s);

  i := 0;
  j := 0;
  while i < count do begin
    i := i + 1;
    if UTF8Char(s,i,desc) = Quote then begin
      result := result + UTF8Range(S, 1 + j, i - j, desc) + Quote;
      j := i;
    end;
  end;

  if i <> j then
    result := result + UTF8Range(S, 1 + j, i - j, desc);
  result := result + Quote;
end ;

end.
