{ $Id$}
{
 *****************************************************************************
 *                             CarbonWSForms.pp                              *
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
unit CarbonWSForms;

{$mode objfpc}{$H+}

interface

// defines
{$I carbondefines.inc}

uses
  // Libs
  MacOSAll,
  CarbonUtils,
  // LCL
  Controls, Forms, Graphics, LCLType, LMessages, LCLProc, Classes,
  // Widgetset
  WSForms, WSLCLClasses, WSProc,
  // LCL Carbon
  CarbonDef, CarbonPrivate, CarbonWSControls;

type

  { TCarbonWSScrollingWinControl }

  TCarbonWSScrollingWinControl = class(TWSScrollingWinControl)
  published
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure ScrollBy(const AWinControl: TScrollingWinControl; const DeltaX, DeltaY: integer); override;
  end;

  { TCarbonWSScrollBox }

  TCarbonWSScrollBox = class(TWSScrollBox)
  published
  end;

  { TCarbonWSCustomFrame }

  TCarbonWSCustomFrame = class(TWSCustomFrame)
  published
  end;

  { TCarbonWSFrame }

  TCarbonWSFrame = class(TWSFrame)
  published
  end;

  { TCarbonWSCustomForm }
  TCarbonWSCustomFormClass = class of TCarbonWSCustomForm;
  TCarbonWSCustomForm = class(TWSCustomForm)
  published
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;

    class procedure CloseModal(const ACustomForm: TCustomForm); override;
    class procedure ShowModal(const ACustomForm: TCustomForm); override;
    
    class procedure SetBorderIcons(const AForm: TCustomForm; const ABorderIcons: TBorderIcons); override;
    class procedure SetFormBorderStyle(const AForm: TCustomForm; const AFormBorderStyle: TFormBorderStyle); override;
  end;

  { TCarbonWSForm }

  TCarbonWSForm = class(TWSForm)
  published
  end;

  { TCarbonWSHintWindow }

  TCarbonWSHintWindow = class(TWSHintWindow)
  published
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
  end;

  { TCarbonWSScreen }

  TCarbonWSScreen = class(TWSScreen)
  published
  end;

  { TCarbonWSApplicationProperties }

  TCarbonWSApplicationProperties = class(TWSApplicationProperties)
  published
  end;


implementation

uses
  CarbonProc, CarbonDbgConsts;
  

{ TCarbonWSScrollingWinControl }

{------------------------------------------------------------------------------
  Method:  TCarbonWSScrollingWinControl.CreateHandle
  Params:  AWinControl - LCL control
           AParams     - Creation parameters
  Returns: Handle to the window in Carbon interface

  Creates new scrolling window control in Carbon interface with the specified
  parameters
 ------------------------------------------------------------------------------}
class function TCarbonWSScrollingWinControl.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
begin
  Result := TLCLIntfHandle(TCarbonScrollingWinControl.Create(AWinControl, AParams));
end;

{------------------------------------------------------------------------------
  Method:  TCarbonWSScrollingWinControl.ScrollBy
  Params:  AWinControl - LCL scrolling win control
           DX, DY      -

  Scrolls the content of the passed window
 ------------------------------------------------------------------------------}
class procedure TCarbonWSScrollingWinControl.ScrollBy(const AWinControl: TScrollingWinControl; const DeltaX, DeltaY: integer);
begin
  if not CheckHandle(AWinControl, Self, 'ScrollBy') then Exit;

  TCarbonWidget(AWinControl.Handle).ScrollBy(DeltaX, DeltaY);
end;

{ TCarbonWSCustomForm }

{------------------------------------------------------------------------------
  Method:  TCarbonWSCustomForm.CreateHandle
  Params:  AWinControl - LCL control
           AParams     - Creation parameters
  Returns: Handle to the window in Carbon interface

  Creates new window in Carbon interface with the specified parameters
 ------------------------------------------------------------------------------}
class function TCarbonWSCustomForm.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
begin
  if csDesigning in AWinControl.ComponentState then
    Result := TLCLIntfHandle(TCarbonDesignWindow.Create(AWinControl, AParams))
  else
    Result := TLCLIntfHandle(TCarbonWindow.Create(AWinControl, AParams));
end;

{------------------------------------------------------------------------------
  Method:  TCarbonWSCustomForm.CloseModal
  Params:  ACustomForm - LCL custom form

  Closes modal window in Carbon interface
 ------------------------------------------------------------------------------}
class procedure TCarbonWSCustomForm.CloseModal(const ACustomForm: TCustomForm);
begin
  if not CheckHandle(ACustomForm, Self, 'CloseModal') then Exit;
  
  TCarbonWindow(ACustomForm.Handle).CloseModal;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonWSCustomForm.ShowModal
  Params:  ACustomForm - LCL custom form

  Shows modal window in Carbon interface
 ------------------------------------------------------------------------------}
class procedure TCarbonWSCustomForm.ShowModal(const ACustomForm: TCustomForm);
begin
  if not CheckHandle(ACustomForm, Self, SShowModal) then Exit;

  TCarbonWindow(ACustomForm.Handle).ShowModal;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonWSCustomForm.SetBorderIcons
  Params:  AForm        - LCL custom form
           ABorderIcons - Border icons

  Sets the border icons of window  in Carbon interface
 ------------------------------------------------------------------------------}
class procedure TCarbonWSCustomForm.SetBorderIcons(const AForm: TCustomForm;
  const ABorderIcons: TBorderIcons);
begin
  if not CheckHandle(AForm, Self, 'SetBorderIcons') then Exit;

  TCarbonWindow(AForm.Handle).SetBorderIcons(ABorderIcons);
end;

{------------------------------------------------------------------------------
  Method:  TCarbonWSCustomForm.SetFormBorderStyle
  Params:  AForm            - LCL custom form
           AFormBorderStyle - Form border style

  Sets the form border style of window in Carbon interface
 ------------------------------------------------------------------------------}
class procedure TCarbonWSCustomForm.SetFormBorderStyle(const AForm: TCustomForm;
  const AFormBorderStyle: TFormBorderStyle);
begin
  if not CheckHandle(AForm, Self, 'SetFormBorderStyle') then Exit;

  TCarbonWindow(AForm.Handle).SetFormBorderStyle(AFormBorderStyle);
end;

{ TCarbonWSHintWindow }

{------------------------------------------------------------------------------
  Method:  TCarbonWSHintWindow.CreateHandle
  Params:  AWinControl - LCL control
           AParams     - Creation parameters
  Returns: Handle to the window in Carbon interface

  Creates new hint window in Carbon interface with the specified parameters
 ------------------------------------------------------------------------------}
class function TCarbonWSHintWindow.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
begin
  Result := TLCLIntfHandle(TCarbonHintWindow.Create(AWinControl, AParams));
end;

end.
