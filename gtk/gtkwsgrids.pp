{ $Id$}
{
 *****************************************************************************
 *                               GtkWSGrids.pp                               * 
 *                               -------------                               * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

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
}
unit GtkWSGrids;

{$mode objfpc}{$H+}

interface

uses
  Controls, Graphics, Grids, WSGrids, WSLCLClasses;

type
  { TGtkWSCustomGrid }

  TGtkWSCustomGrid = class(TWSCustomGrid)
  published
    class procedure SetFont(const AWinControl: TWinControl; const AFont: TFont); override;
  end;


implementation

{ TGtkWSCustomGrid }

class procedure TGtkWSCustomGrid.SetFont(const AWinControl: TWinControl;
  const AFont: TFont);
begin
  //
end;

end.
