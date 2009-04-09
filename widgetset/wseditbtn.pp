{ $Id$}
{
 *****************************************************************************
 *                               WSEditBtn.pp                                * 
 *                               ------------                                * 
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
unit WSEditBtn;

{$mode objfpc}{$H+}

interface
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// 1) Only class methods allowed
// 2) Class methods have to be published and virtual
// 3) To get as little as posible circles, the uses
//    clause should contain only those LCL units 
//    needed for registration. WSxxx units are OK
// 4) To improve speed, register only classes in the 
//    initialization section which actually 
//    implement something
// 5) To enable your XXX widgetset units, look at
//    the uses clause of the XXXintf.pp
////////////////////////////////////////////////////
uses
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
//  EditBtn,
////////////////////////////////////////////////////
  WSLCLClasses, WSStdCtrls;

type
  { TWSCustomEditButton }

  TWSCustomEditButton = class(TWSEdit)
  published
  end;

  { TWSEditButton }

  TWSEditButton = class(TWSCustomEditButton)
  published
  end;

  { TWSFileNameEdit }

  TWSFileNameEdit = class(TWSCustomEditButton)
  published
  end;

  { TWSDirectoryEdit }

  TWSDirectoryEdit = class(TWSCustomEditButton)
  published
  end;

  { TWSDateEdit }

  TWSDateEdit = class(TWSCustomEditButton)
  published
  end;

  { TWSCalcEdit }

  TWSCalcEdit = class(TWSCustomEditButton)
  published
  end;


implementation

////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
//initialization
//  RegisterWSComponent(TCustomEditButton, TWSCustomEditButton);
//  RegisterWSComponent(TEditButton, TWSEditButton);
//  RegisterWSComponent(TFileNameEdit, TWSFileNameEdit);
//  RegisterWSComponent(TDirectoryEdit, TWSDirectoryEdit);
//  RegisterWSComponent(TDateEdit, TWSDateEdit);
//  RegisterWSComponent(TCalcEdit, TWSCalcEdit);
////////////////////////////////////////////////////
end.