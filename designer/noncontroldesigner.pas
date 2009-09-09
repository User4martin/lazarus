{  $Id$  }
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
    TNonControlForm is a designer form to design non TControl components like
    TDataModule.
}
unit NonControlDesigner;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, LCLProc, Graphics, GraphType, Forms, Controls,
  IDEProcs, DesignerProcs, CustomNonFormDesigner;
  
type

  { TNonControlDesignerForm }

  TNonControlDesignerForm = class(TCustomNonFormDesignerForm)
  private
    FFrameWidth: integer;
  protected
    procedure SetFrameWidth(const AValue: integer); virtual;
  public
    constructor Create(TheOwner: TComponent); override;
    procedure Paint; override;
    procedure DoLoadBounds; override;
    procedure DoSaveBounds; override;
  public
    property FrameWidth: integer read FFrameWidth write SetFrameWidth;
  end;
  
  
implementation


{ TNonControlDesignerForm }

procedure TNonControlDesignerForm.SetFrameWidth(const AValue: integer);
begin
  if FFrameWidth = AValue then 
    Exit;
  FFrameWidth := AValue;
  Invalidate;
end;

constructor TNonControlDesignerForm.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FFrameWidth := 1;
  ControlStyle := ControlStyle - [csAcceptsControls];
end;

procedure TNonControlDesignerForm.Paint;
var
  ARect: TRect;
begin
  inherited Paint;
  with Canvas do begin
    Brush.Color:=clWhite;
    ARect:=Rect(FrameWidth,FrameWidth,
        Self.ClientWidth-FrameWidth,
        Self.ClientHeight-FrameWidth);
    FillRect(ARect);
    ARect:=Rect(0,0,Self.ClientWidth+1,Self.ClientHeight+1);
    Pen.Color:=clBlack;
    Frame3d(ARect, FrameWidth, bvLowered);
  end;
end;

procedure TNonControlDesignerForm.DoLoadBounds;

  procedure SetNewBounds(NewLeft, NewTop, NewWidth, NewHeight: integer);
  begin
    if NewWidth<=0 then NewWidth:=Width;
    if NewHeight<=0 then NewHeight:=Height;

    NewWidth:=Max(20,Min(NewWidth,Screen.Width-50));
    NewHeight:=Max(20,Min(NewHeight,Screen.Height-50));
    NewLeft:=Max(0,Min(NewLeft,Screen.Width-NewWidth-50));
    NewTop:=Max(0,Min(NewTop,Screen.Height-NewHeight-50));

    //debugln('TNonControlDesignerForm.DoLoadBounds (TDataModule) ',dbgsName(LookupRoot),' ',dbgs(NewLeft),',',dbgs(NewTop),',',dbgs(NewWidth),',',dbgs(NewHeight));
    SetBounds(NewLeft,NewTop,Max(20,NewWidth),Max(NewHeight,20));
  end;

var
  CurDataModule: TDataModule;
  NewLeft, NewTop: SmallInt;
  NewWidth, NewHeight: Integer;
begin
  inherited DoLoadBounds;

  if LookupRoot is TDataModule then 
  begin
    CurDataModule := TDataModule(LookupRoot);
    NewLeft := CurDataModule.DesignOffset.X;
    NewTop := CurDataModule.DesignOffset.Y;
    NewWidth := CurDataModule.DesignSize.X;
    NewHeight := CurDataModule.DesignSize.Y;
    
    SetNewBounds(NewLeft, NewTop, NewWidth, NewHeight);
  end else 
  if LookupRoot <> nil then 
  begin
    DesignInfoTo(LookupRoot.DesignInfo, NewLeft, NewTop);
    SetNewBounds(NewLeft, NewTop, Width, Height);
  end;
end;

procedure TNonControlDesignerForm.DoSaveBounds;
begin
  if LookupRoot is TDataModule then begin
    with TDataModule(LookupRoot) do begin
      DesignOffset:=Point(Left,Top);
      DesignSize:=Point(Width,Height);
      //debugln('TNonControlDesignerForm.DoSaveBounds (TDataModule) ',dbgsName(LookupRoot),' ',dbgs(DesignOffset.X),',',dbgs(DesignOffset.Y));
    end;
  end else if LookupRoot<>nil then begin
    //debugln('TNonControlDesignerForm.DoSaveBounds ',dbgsName(LookupRoot),' ',dbgs(Left),',',dbgs(Top));
    LookupRoot.DesignInfo := DesignInfoFrom(Left, Top)
  end;
  inherited DoSaveBounds;
end;

end.

