{
 *****************************************************************************
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

  Author: Mattias Gaertner

}
unit GLCarbonAGLContext;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, LCLType, gl, Forms,
  MacOSAll,
  AGL, CarbonProc, CarbonDef, CarbonPrivate,
  WSLCLClasses, CarbonWSControls, CarbonUtils,
  Controls;

procedure LOpenGLViewport(Left, Top, Width, Height: integer);
procedure LOpenGLSwapBuffers(Handle: HWND);
function LOpenGLMakeCurrent(Handle: HWND): boolean;
function LOpenGLCreateContext(AWinControl: TWinControl;
              WSPrivate: TWSPrivateClass; SharedControl: TWinControl;
              DoubleBuffered, RGBA: boolean;
              const AParams: TCreateParams): HWND;
procedure LOpenGLDestroyContextInfo(AWinControl: TWinControl);
function CreateOpenGLContextAttrList(DoubleBuffered: boolean;
  RGBA: boolean): PInteger;
  
type
  TWidgetSetWSWinControl = TCarbonWSWinControl;

  TAGLControlInfo = record
    Control: ControlRef;
    AGLContext: TAGLContext;
  end;
  PAGLControlInfo = ^TAGLControlInfo;

var
  AGLControlInfo_FOURCC: FourCharCode;

function CreateAGLControlInfo(Control: ControlRef; AGLContext: TAGLContext
  ): PAGLControlInfo;
function GetAGLControlInfo(Control: ControlRef): PAGLControlInfo;
procedure FreeAGLControlInfo(Control: ControlRef);
function GetAGLContext(Control: ControlRef): TAGLContext;

implementation

procedure LOpenGLViewport(Left, Top, Width, Height: integer);
begin
  glViewport(Left,Top,Width,Height);
end;

procedure LOpenGLSwapBuffers(Handle: HWND);
var
  AGLContext: TAGLContext;
begin
  AGLContext:=GetAGLContext(ControlRef(Handle));
  aglSwapBuffers(AGLContext);
end;

function LOpenGLMakeCurrent(Handle: HWND): boolean;
var
  AGLContext: TAGLContext;
begin
  AGLContext:=GetAGLContext(ControlRef(Handle));
  Result:=aglSetCurrentContext(aglContext)<>0;
end;

function LOpenGLCreateContext(AWinControl: TWinControl;
  WSPrivate: TWSPrivateClass; SharedControl: TWinControl;
  DoubleBuffered, RGBA: boolean;
  const AParams: TCreateParams): HWND;
var
  disp: GDHandle;
  aglPixFmt: TAGLPixelFormat;
  aglContext: TAGLContext;
  Control: TCarbonCustomControl;
  AttrList: PInteger;
  C: TCreateParams;
  AGLInfo: PAGLControlInfo;
begin
  Result:=0;
  if AWinControl.Parent=nil then
    RaiseGDBException('GLCarbonAGLContext.LOpenGLCreateContext no parent');

  C.X := AWinControl.Left;
  C.Y := AWinControl.Top;
  C.Width := AWinControl.Width;
  C.Height := AWinControl.Height;
  // create a custom control
  Control := TCarbonCustomControl.Create(AWinControl, C);
  debugln(['LOpenGLCreateContext ',dbgsName(Control)]);

  // create the AGL context
  disp := GetMainDevice ();
  AttrList:=CreateOpenGLContextAttrList(DoubleBuffered,RGBA);
  aglPixFmt := aglChoosePixelFormat (@disp, 1, AttrList);
  System.FreeMem(AttrList);
  aglContext := aglCreateContext (aglPixFmt, NIL);
  aglDestroyPixelFormat(aglPixFmt);

  // use the carbon window.
  // TODO: find a way to use only the control for the context
  aglSetDrawable(aglContext,
    GetWindowPort(TCarbonWindow(GetParentForm(AWinControl).Handle).Widget));

  AGLControlInfo_FOURCC := MakeFourCC('ACI ');

  AGLInfo:=CreateAGLControlInfo(Control.Widget, AGLContext);
  if AGLInfo<>GetAGLControlInfo(Control.Widget) then
    RaiseGDBException('GLCarbonAGLContext.LOpenGLCreateContext inconsistency');
  Result:=HWnd(Control);
end;

procedure LOpenGLDestroyContextInfo(AWinControl: TWinControl);
var
  Ref: ControlRef;
  Info: PAGLControlInfo;
begin
  if not AWinControl.HandleAllocated then exit;
  Ref := ControlRef(TCarbonControl(AWinControl.Handle).Widget);
  Info := GetAGLControlInfo(Ref);
  if Info=nil then exit;
  aglDestroyContext(Info^.AGLContext);
  Info^.AGLContext := nil;
  FreeAGLControlInfo(Ref);
end;

function CreateOpenGLContextAttrList(DoubleBuffered: boolean; RGBA: boolean
  ): PInteger;
var
  p: integer;

  procedure Add(i: integer);
  begin
    if Result<>nil then
      Result[p]:=i;
    inc(p);
  end;

  procedure CreateList;
  begin
    Add(AGL_WINDOW);
    if DoubleBuffered then
      Add(AGL_DOUBLEBUFFER);
    if RGBA then
      Add(AGL_RGBA);
    Add(AGL_NO_RECOVERY);
    Add(AGL_MAXIMUM_POLICY);
    Add(AGL_SINGLE_RENDERER);
    Add(AGL_RED_SIZE); Add(1);
    Add(AGL_GREEN_SIZE); Add(1);
    Add(AGL_BLUE_SIZE); Add(1);
    Add(AGL_DEPTH_SIZE); Add(1);
    Add(AGL_NONE);
  end;

begin
  Result:=nil;
  p:=0;
  CreateList;
  GetMem(Result,SizeOf(integer)*p);
  p:=0;
  CreateList;
end;

function CreateAGLControlInfo(Control: ControlRef; AGLContext: TAGLContext
  ): PAGLControlInfo;
begin
  New(Result);
  FillByte(Result^, SizeOf(Result^), 0);
  Result^.Control:=Control;
  Result^.AGLContext:=AGLContext;

  SetControlProperty(Control, LAZARUS_FOURCC, AGLControlInfo_FOURCC,
                     SizeOf(Result), @Result);
end;

function GetAGLControlInfo(Control: ControlRef): PAGLControlInfo;
var
  m: LongWord;
begin
  GetControlProperty(Control, LAZARUS_FOURCC, AGLControlInfo_FOURCC,
                     SizeOf(Result), @m, @Result);
end;

procedure FreeAGLControlInfo(Control: ControlRef);
var
  Info: PAGLControlInfo;
begin
  Info:=GetAGLControlInfo(Control);
  if Info=nil then exit;
  RemoveControlProperty(Control, LAZARUS_FOURCC, AGLControlInfo_FOURCC);
  System.FreeMem(Info);
end;

function GetAGLContext(Control: ControlRef): TAGLContext;
begin
  Result:=GetAGLControlInfo(TCarbonCustomControl(Control).Widget)^.AGLContext;
end;

end.

