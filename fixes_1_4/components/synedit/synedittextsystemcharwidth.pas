unit SynEditTextSystemCharWidth;

(*
                      WARNING:
          This unit is highly experimental
*)

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

{$mode objfpc}{$H+}
{$IFDEF Windows} {$IFnDEF WINCE}
  {$DEFINE WindowsDesktop}
{$ENDIF} {$ENDIF}

interface

uses
  {$IFDEF WindowsDesktop} windows,  {$endif}
  Classes, SysUtils, LazSynEditText, LazUTF8, Controls, Graphics, LazLoggerBase;

type

  { TSynEditStringBidiChars }

  { TSynEditStringSystemWidthChars }

  TSynEditStringSystemWidthChars = class(TSynEditStringsLinked)
  private
    FHandleOwner: TCanvas;
  protected
    procedure DoGetPhysicalCharWidths(Line: PChar; LineLen, Index: Integer; PWidths: PPhysicalCharWidth); override;
  public
    constructor Create(ASynStringSource: TSynEditStrings; AHandleOwner: TCanvas);
    property HandleOwner: TCanvas read FHandleOwner;
  end;

implementation

var
  LOG_SynSystemWidthChars: PLazLoggerLogGroup;

{ TSynEditStringSystemWidthChars }

constructor TSynEditStringSystemWidthChars.Create(ASynStringSource: TSynEditStrings;
  AHandleOwner: TCanvas);
begin
  inherited Create(ASynStringSource);
  FHandleOwner := AHandleOwner;
end;

procedure TSynEditStringSystemWidthChars.DoGetPhysicalCharWidths(Line: PChar; LineLen,
  Index: Integer; PWidths: PPhysicalCharWidth);
  {$IFDEF WindowsDesktop}
var
  //s: UnicodeString;// wideString;
  i: DWORD;
  cpRes: TGCPRESULTS;
  outs: array of widechar;
  order, dx, caret: array of integer;
  cclass, glyph: array of word;

  s: WideString;
  j, k: Integer;
  l: SizeUInt;
  {$endif}
begin
  inherited DoGetPhysicalCharWidths(Line, LineLen, Index, PWidths);
  if (not IsUtf8) then
    exit;

  if (FHandleOwner is TControlCanvas) and
     (not TWinControl(TControlCanvas(FHandleOwner).Control).HandleAllocated) // SynEdit.HandleAllocated
  then begin
    debugln(LOG_SynSystemWidthChars, ['TSynEditStringSystemWidthChars NO HANDLE ']);
    exit;
  end;


  {$IFDEF WindowsDesktop}
  SetLength(s, LineLen+1);  // wide chars of UTF-16 <= bytes of UTF-8 string
  if ConvertUTF8ToUTF16(PWideChar(S), LineLen+1, Line, LineLen, [toInvalidCharToSymbol], l) <> trNoError then
    exit;
  SetLength(s, l - 1);

  cpRes.lStructSize := sizeof(cpRes);
  SetLength(outs, Length(s)+1);     cpRes.lpOutString := @outs[0];
  SetLength(order, Length(s)+1);    cpRes.lpOrder     := @order[0];
  SetLength(dx, Length(s)+1);       cpRes.lpDx        := @dx[0];
  SetLength(caret, Length(s)+1);    cpRes.lpCaretPos  := @caret[0];
  SetLength(cclass, Length(s)+1);   cpRes.lpClass     := @cclass[0];
  SetLength(glyph, Length(s)+1);    cpRes.lpGlyphs    := @glyph[0];
  cpRes.nGlyphs := length(s);

  i := GetCharacterPlacementW(FHandleOwner.Handle, pwidechar(s), length(s), 0,
                              @cpRes, GCP_DIACRITIC + GCP_KASHIDA + GCP_LIGATE);
  if i = 0 then begin
    debugln(LOG_SynSystemWidthChars, ['TSynEditStringSystemWidthChars FAILED for line ', Index]);
    exit;
  end;

  k := 0; // index for order

  for j := 0 to LineLen-1 do begin
    if Line^ in [#$00..#$7F, #$C0..#$FF] then begin
      if PWidths^ <> 0 then begin
        if (k > 0) and (order[k] = order[k-1]) then begin
          debugln(LOG_SynSystemWidthChars, ['TSynEditStringSystemWidthChars for line ', Index, ' set char at ', j, '(', k, ') to be drawn with previous']);
          PWidths^ := 0;
        end;
      end;
      inc(k);
    end;

    inc(PWidths);
    inc(Line);
  end;

  {$endif}
end;


initialization
  LOG_SynSystemWidthChars := DebugLogger.RegisterLogGroup('SynSystemWidthChars' {$IFDEF SynSystemWidthChars} , True {$ENDIF} );

end.

