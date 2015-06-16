{
 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

  Author: Juha Manninen / Antônio Galvão

  Abstract:
    This is an unsorted StringList with a fast lookup feature.
     Internally it uses a map container to store the strings again
      which is then used for Contains, IndexOf and Find methods.

    The extra container does not reserve too much memory because the strings are
     reference counted and not really copied.

    All Duplicates property values are fully supported,
     including dupIgnore and dupError, unlike in unsorted StringList.

    This class is useful only when you must preserve the order in list, but
     also need to do fast lookups to see if a string exists, or must prevent duplicates.
}
unit DictionaryStringList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, AvgLvlTree;

type

  { TDictionaryStringList }

  TDictionaryStringList = class(TStringList)
  private
    FMap: TStringMap;
  protected
    procedure InsertItem(Index: Integer; const S: string); override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    function Add(const S: string): Integer; override;
    function AddObject(const S: string; AObject: TObject): Integer; override;
    function Contains(const S: string): Boolean; // A new function
    function Find(const S: string; out Index: Integer): Boolean; override;
    function IndexOf(const S: string): Integer; override;
  end;

function Deduplicate(AStrings: TStrings): Boolean;

implementation

{
  Removes duplicate strings (case sensitive) from AStrings.
  When the AStrings owns and contains objects, the function will return false.
}
function Deduplicate(AStrings: TStrings): Boolean;
var
  i: Integer;
  DSL: TDictionaryStringList;
begin
  Result := False;
  DSL := TDictionaryStringList.Create;
  try
    DSL.Assign(AStrings);
    AStrings.Assign(DSL);
    Result := True;
  finally
    DSL.Free;
  end;
end;

{ TDictionaryStringList }

constructor TDictionaryStringList.Create;
begin
  inherited Create;
  FMap := TStringMap.Create(True);
end;

destructor TDictionaryStringList.Destroy;
begin
  FMap.Free;
  inherited Destroy;
end;

procedure TDictionaryStringList.Assign(Source: TPersistent);
begin
  inherited Assign(Source);
  if Source is TDictionaryStringList then
    FMap.Assign(TDictionaryStringList(Source).FMap);
end;

procedure TDictionaryStringList.Clear;
begin
  inherited Clear;
  FMap.Clear;
end;

procedure TDictionaryStringList.Delete(Index: Integer);
var
  s: String;
begin
  s := Strings[Index];
  inherited Delete(Index);
  // The string must not be deleted from map if there are duplicates.
  // Calling IndexOf is slow but it is needed.
  if (Duplicates <> dupAccept) or (inherited IndexOf(s) = -1) then
    FMap.Remove(s);
end;

function TDictionaryStringList.Add(const S: string): Integer;
begin
  if not Sorted and (Duplicates = dupIgnore) and FMap.Contains(S) then
    Result := -1
  else
    Result := inherited Add(S);
end;

function TDictionaryStringList.AddObject(const S: string; AObject: TObject): Integer;
begin
  Result := Add(S);
  if Result > -1 then
    Objects[Result] := AObject;
end;

procedure TDictionaryStringList.InsertItem(Index: Integer; const S: string);
begin
  if not Sorted and (Duplicates <> dupAccept) then
    if FMap.Contains(S) then
      case Duplicates of
        DupIgnore : Exit;
        DupError : raise Exception.Create('TDictionaryStringList.InsertItem:'
                                         +' Duplicates are not allowed.');
      end;
  inherited InsertItem(Index, S);
  FMap.Add(S);     // Insert string to map, too.
end;

function TDictionaryStringList.Contains(const S: string): Boolean;
begin
  Result := FMap.Contains(S);
end;

function TDictionaryStringList.Find(const S: string; out Index: Integer): Boolean;
begin
  Index := IndexOf(S);
  Result := Index <> -1;
end;

function TDictionaryStringList.IndexOf(const S: string): Integer;
begin
  if FMap.Contains(S) then
    Result := inherited IndexOf(S)
  else
    Result := -1
end;

end.

