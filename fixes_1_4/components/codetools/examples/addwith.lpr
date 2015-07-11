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
    Demonstration how to remove a with block.
}
program addwith;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, CodeCache, CodeToolManager, FileProcs, AVL_Tree, CodeAtom,
  BasicCodeTools, SourceChanger, CodeTree, FindDeclarationTool, AddWith1;

const
  ConfigFilename = 'codetools.config';
var
  Filename: string;
  Code: TCodeBuffer;
  X1: Integer;
  Y1: Integer;
  X2: Integer;
  Y2: Integer;
  Candidates: TStrings;
  WithExpr: String;
begin
  Filename:='scanexamples/addwith1.pas';
  X1:=1;
  Y1:=35;
  X2:=1;
  Y2:=40;
  WithExpr:='Son1';

  if (ParamCount>=1) and (Paramcount<>6) then begin
    writeln('Usage:');
    writeln('  ',ParamStr(0));
    writeln('  ',ParamStr(0),' <filename> <X1> <Y1> <X2> <Y2> <WithExpression>');
    writeln('  ',ParamStr(0),' ',Filename,' ',X1,' ',Y1,' ',X2,' ',Y2,' ',WithExpr);
  end;

  CodeToolBoss.SimpleInit(ConfigFilename);

  // load the file
  if Paramcount=6 then begin
    Filename:=ParamStrUTF8(1);
    X1:=StrToIntDef(ParamStrUTF8(2),1);
    Y1:=StrToIntDef(ParamStrUTF8(3),1);
    X2:=StrToIntDef(ParamStrUTF8(4),1);
    Y2:=StrToIntDef(ParamStrUTF8(5),1);
    WithExpr:=ParamStrUTF8(6);
  end;

  Filename:=ExpandFileName(SetDirSeparators(Filename));
  Code:=CodeToolBoss.LoadFile(Filename,false,false);
  if Code=nil then
    raise Exception.Create('loading failed: '+Filename);

  // parse the unit and remove the with variable
  Candidates:=TStringList.Create;
  if not CodeToolBoss.AddWithBlock(Code,X1,Y1,X2,Y2,'',Candidates) then
    raise Exception.Create('Finding candidates for "With" block failed');
  Candidates.Free;
  if not CodeToolBoss.AddWithBlock(Code,X1,Y1,X2,Y2,WithExpr,nil) then
    raise Exception.Create('Adding "With" block for "'+WithExpr+'" failed');

  // write the new source:
  writeln('-----------------------------------');
  writeln('New source:');
  writeln(Code.Source);
  writeln('-----------------------------------');
end.

