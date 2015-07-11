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
}
unit ProjPackIntf;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IDEOptionsIntf, CompOptsIntf;

type

  {$M+}
  TIDEOwnedFile = class
  protected
    function GetFilename: string; virtual; abstract;
    procedure SetFilename(const AValue: string); virtual; abstract;
  public
    function GetFullFilename: string; virtual; abstract; // if no path, the file was not saved yet
    function GetShortFilename(UseUp: boolean): string; virtual; abstract;
    function GetFileOwner: TObject; virtual; abstract;
    function GetFileOwnerName: string; virtual; abstract;
    property Filename: string read GetFilename write SetFilename;
  end;
  {$M-}

  { TIDEProjPackBase }

  TIDEProjPackBase = class(TComponent)
  private
  protected
    FIDEOptions: TAbstractIDEOptions; //actually TProjectIDEOptions or TPackageIDEOptions;
    FLazCompilerOptions: TLazCompilerOptions;
    function GetLazCompilerOptions: TLazCompilerOptions;
  public
    property LazCompilerOptions: TLazCompilerOptions read GetLazCompilerOptions;
  end;


implementation

{ TIDEProjPackBase }

function TIDEProjPackBase.GetLazCompilerOptions: TLazCompilerOptions;
begin
  Result := FLazCompilerOptions;
end;

end.

