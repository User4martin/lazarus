{ $Id$ }
{
 ---------------------------------------------------------------------------
 fpdbgloader.pp  -  Native Freepascal debugger - Section loader
 ---------------------------------------------------------------------------

 This unit contains helper classes for loading secions form images.

 This file contains some functionality ported from DUBY. See svn log for details

 ---------------------------------------------------------------------------

 @created(Mon Aug 1st WET 2006)
 @lastmod($Date$)
 @author(Marc Weustink <marc@@dommelstein.nl>)

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
}
unit FpDbgLoader;

{$mode objfpc}{$H+}

interface

uses
  LCLType,
  FpImgReaderBase, FpImgReaderWinPE, FpImgReaderElf, FpImgReaderMacho,
  fpDbgSymTable,
  Classes, SysUtils, contnrs;

type

  {$ifdef windows}
    {$define USE_WIN_FILE_MAPPING}
  {$endif}
  { TDbgImageLoader }

  TDbgImageLoader = class(TObject)
  private
    FFileLoader: TDbgFileLoader;
    FImgReader: TDbgImageReader;
    function GetAddressMapList: TDbgAddressMapList;
    function GetSubFiles: TStrings;
    function GetImage64Bit: Boolean;
    function GetUUID: TGuid;
  protected
    FImageBase: QWord unimplemented;
    function GetSection(const AName: String): PDbgImageSection; virtual;
    //procedure SetImageBase(ABase: QWord);
    property ImgReader: TDbgImageReader read FImgReader write FImgReader;
  public
    constructor Create; virtual;
    constructor Create(AFileName: String; ADebugMap: TObject = nil);
    procedure ParseSymbolTable(AFpSymbolInfo: TfpSymbolList);
    {$ifdef USE_WIN_FILE_MAPPING}
    constructor Create(AFileHandle: THandle; ADebugMap: TObject = nil);
    {$endif}
    destructor Destroy; override;
    function IsValid: Boolean;
    property ImageBase: QWord read FImageBase; unimplemented;
    Property Image64Bit: Boolean read GetImage64Bit;
    property UUID: TGuid read GetUUID;
    property Section[const AName: String]: PDbgImageSection read GetSection;
    // On Darwin, the Dwarf-debuginfo is not linked into the main
    // executable, but has to be read from the object files.
    property SubFiles: TStrings read GetSubFiles;
    // This is to map the addresses inside the object file
    // to their corresponding addresses in the executable. (Darwin)
    property AddressMapList: TDbgAddressMapList read GetAddressMapList;
  end;

  { TDbgImageLoaderList }

  TDbgImageLoaderList = class(TFPObjectList)
  private
    function GetImage64Bit: Boolean;
    function GetImageBase: QWord;
    function GetItem(Index: Integer): TDbgImageLoader;
    procedure SetItem(Index: Integer; AValue: TDbgImageLoader);
  public
    property Items[Index: Integer]: TDbgImageLoader read GetItem write SetItem; default;
    property ImageBase: QWord read GetImageBase;
    Property Image64Bit: Boolean read GetImage64Bit;
  end;

implementation

{ TDbgImageLoaderList }

function TDbgImageLoaderList.GetImage64Bit: Boolean;
begin
  if Count<0 then
    result := Items[0].Image64Bit
  else
    {$ifdef CPU64}
    result := true
    {$else}
    result := false;
    {$endif}
end;

function TDbgImageLoaderList.GetImageBase: QWord;
begin
  if Count<0 then
    result := Items[0].ImageBase
  else
    result := 0;
end;

function TDbgImageLoaderList.GetItem(Index: Integer): TDbgImageLoader;
begin
  result := TDbgImageLoader(inherited GetItem(Index));
end;

procedure TDbgImageLoaderList.SetItem(Index: Integer; AValue: TDbgImageLoader);
begin
  inherited SetItem(Index, AValue);
end;

{ TDbgImageLoader }

function TDbgImageLoader.GetImage64Bit: Boolean;
begin
  if not assigned(ImgReader) then
    {$ifdef cpui386}
    result := false
    {$else}
    result := true
    {$endif}
  else
    result := ImgReader.Image64Bit;
end;

function TDbgImageLoader.GetAddressMapList: TDbgAddressMapList;
begin
  if IsValid then
    result := FImgReader.AddressMapList
  else
    result := nil
end;

function TDbgImageLoader.GetSubFiles: TStrings;
begin
  if IsValid then
    result := FImgReader.SubFiles
  else
    result := nil;
end;

function TDbgImageLoader.GetUUID: TGuid;
begin
  if assigned(FImgReader) then
    result := FImgReader.UUID
  else
    result := GUID_NULL;
end;

function TDbgImageLoader.GetSection(const AName: String): PDbgImageSection;
begin
  if FImgReader <> nil then
    Result := FImgReader.Section[AName]
  else
    Result := nil;
end;

constructor TDbgImageLoader.Create;
begin
  inherited Create;
end;

constructor TDbgImageLoader.Create(AFileName: String; ADebugMap: TObject = nil);
begin
  FFileLoader := TDbgFileLoader.Create(AFileName);
  FImgReader := GetImageReader(FFileLoader, ADebugMap, True);
end;

procedure TDbgImageLoader.ParseSymbolTable(AFpSymbolInfo: TfpSymbolList);
begin
  if IsValid then
    FImgReader.ParseSymbolTable(AFpSymbolInfo);
end;

{$ifdef USE_WIN_FILE_MAPPING}
constructor TDbgImageLoader.Create(AFileHandle: THandle; ADebugMap: TObject = nil);
begin
  FFileLoader := TDbgFileLoader.Create(AFileHandle);
  FImgReader := GetImageReader(FFileLoader, ADebugMap, True);
end;
{$endif}

destructor TDbgImageLoader.Destroy;
begin
  FreeAndNil(FImgReader);
  inherited Destroy;
end;

function TDbgImageLoader.IsValid: Boolean;
begin
  Result := FImgReader <> nil;
end;

end.

