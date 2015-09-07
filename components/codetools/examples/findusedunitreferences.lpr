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

  Abstract:
    Simple demonstrating, how to setup the codetools, FPC and Lazarus Source
    directory to find what unit A uses of unit B.

  Usage:
    findusedunitreferences filename line column

    Filename is a unit.
    Line, column is a unit within a uses section.
}
program FindUsedUnitReferences;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, CodeCache, CodeToolManager,
  usedunitrefs1;

const
  ConfigFilename = 'codetools.config';
var
  Code: TCodeBuffer;
  Filename: String;
  ListOfPCodeXYPosition: TFPList;
  X: Integer;
  Y: Integer;
  UsedUnitFilename: string;
begin
  if (ParamCount>=1) and (Paramcount<3) then begin
    writeln('Usage:');
    writeln('  ',ParamStr(0));
    writeln('  ',ParamStr(0),' <filename> <X> <Y>');
    Halt(1);
  end;

  CodeToolBoss.SimpleInit(ConfigFilename);

  // Example: find all references to unit Math
  Filename:=ExpandFileName('scanexamples/usedunitrefs1.pas');
  X:=23;
  Y:=8;

  if (ParamCount>=3) then begin
    Filename:=CleanAndExpandFilename(ParamStr(1));
    X:=StrToInt(ParamStr(2));
    Y:=StrToInt(ParamStr(3));
    writeln('File: ',Filename,' Line=',Y,' Column=',X);
  end;

  // Step 1: load the file
  Code:=CodeToolBoss.LoadFile(Filename,false,false);
  if Code=nil then
    raise Exception.Create('loading failed '+Filename);

  // Step 2: find references
  writeln('Filename: ',Code.Filename);
  ListOfPCodeXYPosition:=nil;
  try
    if CodeToolBoss.FindUsedUnitReferences(Code,X,Y,false,UsedUnitFilename,
      ListOfPCodeXYPosition) then
    begin
      writeln('List of ',UsedUnitFilename,':');
      writeln(ListOfPCodeXYPositionToStr(ListOfPCodeXYPosition));
    end else begin
      writeln('CodeToolBoss.FindUsedUnitReferences failed: ',CodeToolBoss.ErrorMessage);
    end;
  finally
    FreeListOfPCodeXYPosition(ListOfPCodeXYPosition);
  end;
end.

