{ $Id$}
{
 *****************************************************************************
 *                             Gtk2WSCalendar.pp                             * 
 *                             -----------------                             * 
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
unit Gtk2WSCalendar;

{$mode objfpc}{$H+}

interface

uses
  // Bindings
  {$IFDEF gtk2}
  glib2, gdk2pixbuf, gdk2, gtk2, Pango,
  {$ELSE}
  glib, gdk, gtk, gdkpixbuf, GtkFontCache,
  {$ENDIF}
  // RTL, FCL, LCL
  SysUtils, Classes, Controls, Calendar, LCLType, LMessages,
  InterfaceBase,
  // Widgetset
  GtkProc, GtkDef, Gtk2Int, Gtk2WsControls,
  WSCalendar, WSLCLClasses, WSProc;

type

  { TGtk2WSCalendar }

  { TGtk2WSCustomCalendar }

  TGtk2WSCustomCalendar = class(TWSCustomCalendar)
  protected
    class procedure SetCallbacks(const AGtkWidget: PGtkWidget; const AWidgetInfo: PWidgetInfo); virtual;
    class function GetCalendar(const ACalendar: TCustomCalendar): PGtkCalendar; inline;
  published
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;

    class function  GetDateTime(const ACalendar: TCustomCalendar): TDateTime; override;
    class procedure SetDateTime(const ACalendar: TCustomCalendar; const ADateTime: TDateTime); override;
    class procedure SetDisplaySettings(const ACalendar: TCustomCalendar;
      const ADisplaySettings: TDisplaySettings); override;
    class procedure SetReadOnly(const ACalendar: TCustomCalendar; const AReadOnly: boolean); override;
  end;


implementation

{ TGtk2WSCustomCalendar }

class procedure TGtk2WSCustomCalendar.SetCallbacks(const AGtkWidget: PGtkWidget;
  const AWidgetInfo: PWidgetInfo);
begin
  TGtk2WSWinControl.SetCallbacks(PGtkObject(AGtkWidget), TComponent(AWidgetInfo^.LCLObject));
  with TGtk2Widgetset(Widgetset) do
  begin
    SetCallback(LM_MONTHCHANGED, PGtkObject(AGtkWidget), AWidgetInfo^.LCLObject);
    SetCallback(LM_YEARCHANGED, PGtkObject(AGtkWidget), AWidgetInfo^.LCLObject);
    SetCallback(LM_DAYCHANGED, PGtkObject(AGtkWidget), AWidgetInfo^.LCLObject);
  end;
end;

class function TGtk2WSCustomCalendar.GetCalendar(const ACalendar: TCustomCalendar): PGtkCalendar; inline;
begin
  Result := PGtkCalendar(GetWidgetInfo(PGtkWidget(ACalendar.Handle))^.CoreWidget);
end;

class function TGtk2WSCustomCalendar.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams
  ): TLCLIntfHandle;
var
  FrameWidget, CalendarWidget: PGtkWidget;
  WidgetInfo: PWidgetInfo;
  Allocation: TGtkAllocation;
begin
  FrameWidget := gtk_frame_new(nil);
  CalendarWidget := gtk_calendar_new();
  gtk_container_add(PGtkContainer(FrameWidget), CalendarWidget);
  gtk_widget_show_all(FrameWidget);

  Result := TLCLIntfHandle(PtrUInt(FrameWidget));
  {$IFDEF DebugLCLComponents}
  DebugGtkWidgets.MarkCreated(FrameWidget, dbgsName(AWinControl));
  {$ENDIF}

  WidgetInfo := CreateWidgetInfo(FrameWidget, AWinControl, AParams);
  WidgetInfo^.CoreWidget := CalendarWidget;
  SetMainWidget(FrameWidget, CalendarWidget);

  Allocation.X := AParams.X;
  Allocation.Y := AParams.Y;
  Allocation.Width := AParams.Width;
  Allocation.Height := AParams.Height;
  gtk_widget_size_allocate(PGtkWidget(Result), @Allocation);

  Set_RC_Name(AWinControl, FrameWidget);
  SetCallBacks(FrameWidget, WidgetInfo);
end;

class function TGtk2WSCustomCalendar.GetDateTime(const ACalendar: TCustomCalendar): TDateTime;
var
  Year, Month, Day: guint;  //used for csCalendar
begin
  Result := 0;
  if not WSCheckHandleAllocated(ACalendar, 'GetDateTime') then
    Exit;
  gtk_calendar_get_date(GetCalendar(ACalendar), @Year, @Month, @Day);
  //For some reason, the month is zero based.
  Result := EncodeDate(Year, Month + 1, Day);
end;

class procedure TGtk2WSCustomCalendar.SetDateTime(const ACalendar: TCustomCalendar; const ADateTime: TDateTime);
var
  Year, Month, Day: string;
  GtkCalendar: PGtkCalendar;
begin
  if not WSCheckHandleAllocated(ACalendar, 'SetDateTime') then
    Exit;
  GtkCalendar := GetCalendar(ACalendar);
  Year := FormatDateTime('yyyy', ADateTime);
  Month := FormatDateTime('mm', ADateTime);
  Day := FormatDateTime('dd', ADateTime);
  gtk_calendar_select_month(GtkCalendar, StrtoInt(Month) - 1, StrToInt(Year));
  gtk_calendar_select_day(GtkCalendar, StrToInt(Day));
end;

class procedure TGtk2WSCustomCalendar.SetDisplaySettings(const ACalendar: TCustomCalendar;
  const ADisplaySettings: TDisplaySettings);
var
  num: dword;
  gtkcalendardisplayoptions : TGtkCalendarDisplayOptions;
begin
  if not WSCheckHandleAllocated(ACalendar, 'SetDisplaySettings') then
    Exit;
  num := 0;
  if (dsShowHeadings in ADisplaySettings) then
    num := Num + (1 shl 0);

  if (dsShowDayNames in ADisplaySettings) then
    num := Num  + (1 shl 1);

  if (dsNoMonthChange in ADisplaySettings) then
    num := Num  + (1 shl 2);

  if (dsShowWeekNumbers in ADisplaySettings) then
     num := Num  + (1 shl 3);

  if (dsStartMonday in ADisplaySettings) then
     num := Num  + (1 shl 4);

  gtkCalendarDisplayOptions := TGtkCalendarDisplayOptions(num);
  gtk_Calendar_Display_options(GetCalendar(ACalendar), gtkCalendarDisplayOptions);
end;

class procedure TGtk2WSCustomCalendar.SetReadOnly(const ACalendar: TCustomCalendar;
  const AReadOnly: boolean);
begin
  if not WSCheckHandleAllocated(ACalendar, 'SetReadOnly') then
    Exit;
  if AReadOnly then
    gtk_calendar_freeze(GetCalendar(ACalendar))
  else
    gtk_calendar_thaw(GetCalendar(ACalendar));
end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
  RegisterWSComponent(TCustomCalendar, TGtk2WSCustomCalendar);
////////////////////////////////////////////////////
end.
