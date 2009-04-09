{ $Id$}
{
 *****************************************************************************
 *                              CarbonWSExtDlgs.pp                           *
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
unit CarbonWSExtDlgs;

{$mode objfpc}{$H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
//  ExtDlgs,
////////////////////////////////////////////////////
  WSExtDlgs, WSLCLClasses;

type

  { TCarbonWSPreviewFileControl }

  TCarbonWSPreviewFileControl = class(TWSPreviewFileControl)
  published
  end;

  { TCarbonWSPreviewFileDialog }

  TCarbonWSPreviewFileDialog = class(TWSPreviewFileDialog)
  published
  end;

  { TCarbonWSOpenPictureDialog }

  TCarbonWSOpenPictureDialog = class(TWSOpenPictureDialog)
  published
  end;

  { TCarbonWSSavePictureDialog }

  TCarbonWSSavePictureDialog = class(TWSSavePictureDialog)
  published
  end;

  { TCarbonWSCalculatorDialog }

  TCarbonWSCalculatorDialog = class(TWSCalculatorDialog)
  published
  end;

  { TCarbonWSCalculatorForm }

  TCarbonWSCalculatorForm = class(TWSCalculatorForm)
  published
  end;

  { TCarbonWSCalendarDialogForm }

  TCarbonWSCalendarDialogForm = class(TWSCalendarDialogForm)
  published
  end;

  { TCarbonWSCalendarDialog }

  TCarbonWSCalendarDialog = class(TWSCalendarDialog)
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
//  RegisterWSComponent(TPreviewFileControl, TCarbonWSPreviewFileControl);
//  RegisterWSComponent(TPreviewFileDialog, TCarbonWSPreviewFileDialog);
//  RegisterWSComponent(TOpenPictureDialog, TCarbonWSOpenPictureDialog);
//  RegisterWSComponent(TSavePictureDialog, TCarbonWSSavePictureDialog);
//  RegisterWSComponent(TCalculatorDialog, TCarbonWSCalculatorDialog);
//  RegisterWSComponent(TCalculatorForm, TCarbonWSCalculatorForm);
//  RegisterWSComponent(TCalendarDialogForm, TCarbonWSCalendarDialogForm);
//  RegisterWSComponent(TCalendarDialog, TCarbonWSCalendarDialog);
////////////////////////////////////////////////////
end.
