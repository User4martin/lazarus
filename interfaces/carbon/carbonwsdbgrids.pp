{ $Id$}
{
 *****************************************************************************
 *                              CarbonWSDBGrids.pp                           *
 *                              --------------                               * 
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
unit CarbonWSDBGrids;

{$mode objfpc}{$H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
//  DBGrids,
////////////////////////////////////////////////////
  WSDBGrids, WSLCLClasses;

type

  { TCarbonWSCustomDbGrid }

  TCarbonWSCustomDbGrid = class(TWSCustomDbGrid)
  published
  end;

  { TCarbonWSdbGrid }

  TCarbonWSdbGrid = class(TWSdbGrid)
  published
  end;


implementation

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
//  RegisterWSComponent(TCustomDbGrid, TCarbonWSCustomDbGrid);
//  RegisterWSComponent(TdbGrid, TCarbonWSdbGrid);
////////////////////////////////////////////////////
end.
