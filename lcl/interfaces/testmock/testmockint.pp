{ $Id$ }
{
 /***************************************************************************
                         TestMockINT.pp  -  Test Mock Interface Object
                             -------------------



 ***************************************************************************/

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}

unit TestMockInt;

{$mode objfpc}{$H+}{$T-}
{$OPTIMIZATION NOREMOVEEMPTYPROCS}

interface

uses InterfaceBase, LCLType, Types;

type

  { TTestMockWidgetSet }

  TTestMockWidgetSet = class(TWidgetSet)
  private
  public
    function EnumDisplayMonitors(hdc: HDC; lprcClip: PRect; lpfnEnum: MonitorEnumProc; dwData: LPARAM): LongBool; override;
    //function MonitorFromPoint(ptScreenCoords: TPoint; dwFlags: DWord): HMONITOR; override;
    function MonitorFromRect(lprcScreenCoords: PRect; dwFlags: DWord): HMONITOR; override;
    //function MonitorFromWindow(hWnd: HWND; dwFlags: DWord): HMONITOR; override;

    function GetTextMetrics(DC: HDC; var TM: TTextMetric): Boolean; override;

    //procedure AppProcessMessages; override;

    function GetDC(hWnd: HWND): HDC; override;
    function RestoreDC(DC: HDC; SavedDC: Integer): Boolean; override;
    function SaveDC(DC: HDC): Integer; override;
  end;


var
  TestMockWidgetSet: TTestMockWidgetSet absolute WidgetSet;

implementation

uses
  TestMockWSFactory;

{ TTestMockWidgetSet }

function TTestMockWidgetSet.EnumDisplayMonitors(hdc: HDC; lprcClip: PRect;
  lpfnEnum: MonitorEnumProc; dwData: LPARAM): LongBool;
var r: TRect;
begin
  r.Top  := 0;
  r.Left := 0;
  r.Height := 1200;
  r.Width  := 1920;
  lpfnEnum(1, 1, @r, dwData);
  Result := True;
end;

function TTestMockWidgetSet.MonitorFromRect(lprcScreenCoords: PRect; dwFlags: DWord): HMONITOR;
begin
  Result := 1;
end;

function TTestMockWidgetSet.GetTextMetrics(DC: HDC; var TM: TTextMetric): Boolean;
begin
  TM.tmHeight           := 15;
  TM.tmAscent           := 10;
  TM.tmDescent          := 5;
  TM.tmInternalLeading  := 20;
  TM.tmExternalLeading  := 20;
  TM.tmAveCharWidth     := 20;
  TM.tmMaxCharWidth     := 20;
  TM.tmWeight           := 1;
  TM.tmOverhang         := 0;
  TM.tmDigitizedAspectX := 1;
  TM.tmDigitizedAspectY := 1;
  TM.tmFirstChar        := #32;
  TM.tmLastChar         := #127;
  TM.tmDefaultChar      := #32;
  TM.tmBreakChar        := #10;
  TM.tmItalic           := 0;
  TM.tmUnderlined       := 0;
  TM.tmStruckOut        := 0;
  TM.tmPitchAndFamily   := 0;
  TM.tmCharSet          := 0;
  Result := True;
end;

function TTestMockWidgetSet.GetDC(hWnd: HWND): HDC;
begin
  Result := 1;
end;

function TTestMockWidgetSet.RestoreDC(DC: HDC; SavedDC: Integer): Boolean;
begin
  Result := True;
end;

function TTestMockWidgetSet.SaveDC(DC: HDC): Integer;
begin
  Result := 1;
end;



end.
