{ $Id$}
{
 *****************************************************************************
 *                            TestMockWSControls.pp                          *
 *                            ------------------                             *
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit TestMockWSControls;

{$mode objfpc}{$H+}
{$OPTIMIZATION NOREMOVEEMPTYPROCS}

interface

uses
  WSControls, WSLCLClasses, LCLType, Controls, LMessages,
  SysUtils;
  //{ LCL }
  //InterfaceBase;

type

  { TTestMockWSControl }

  TTestMockWSControl = class(TWSControl)
  published
  end;

  { TTestMockWSWinControl }

  TTestMockWSWinControl = class(TWSWinControl)
  published
    class function  CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): HWND; override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;

    class procedure SetBounds(const AWinControl: TWinControl; const ALeft, ATop, AWidth,
      AHeight: Integer); override;
  end;

  { TTestMockWSGraphicControl }

  TTestMockWSGraphicControl = class(TWSGraphicControl)
  published
  end;

  { TTestMockWSCustomControl }

  TTestMockWSCustomControl = class(TWSCustomControl)
  published
  end;



implementation


{ TTestMockWSWinControl }

class function TTestMockWSWinControl.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
begin
  Result := HWND(AWinControl);
end;

class procedure TTestMockWSWinControl.DestroyHandle(const AWinControl: TWinControl);
begin
end;

class procedure TTestMockWSWinControl.SetBounds(const AWinControl: TWinControl; const ALeft, ATop,
  AWidth, AHeight: Integer);
begin
  inherited SetBounds(AWinControl, ALeft, ATop, AWidth, AHeight);

  // send


  // LM_WINDOWPOSCHANGED
  // TLMWindowPosChanged

  // LM_WINDOWPOSCHANGING
  //
end;

end.
