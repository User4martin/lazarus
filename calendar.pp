{
 /***************************************************************************
                               Calendar.pp
                             -------------------
                             Component Library Calendar Component
                   Initial Revision  : Wed Dec 05 2001

 ***************************************************************************/

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

{
@abstract(Calendar component)
@author(Shane Miller)
@created(05 Dev 2001)
}
unit Calendar;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, LCLType, LCLStrConsts, lMessages, Controls, LResources;
  
type
  TDisplaySetting = (
    dsShowHeadings,
    dsShowDayNames,
    dsNoMonthChange,
    dsShowWeekNumbers,
    dsStartMonday
  );
  TDisplaySettings = set of TDisplaySetting;
const
  DefaultDisplaySettings = [dsShowHeadings, dsShowDayNames];

type
  TCalendarPart = (
    cpNoWhere,      // somewhere
    cpDate,         // date part
    cpWeekNumber,   // week number
    cpTitle,        // somewhere in the title
    cpTitleBtn,     // button in the title
    cpTitleMonth,   // month value in the title
    cpTitleYear     // year value in the title
  );

  EInvalidDate = class(Exception);

  { TCustomCalendar }

  TCustomCalendar = class(TWinControl)
  private
    FDateAsString : String;
    FDate: TDateTime; // last valid date
    FDisplaySettings : TDisplaySettings;
    FOnChange: TNotifyEvent;
    FDayChanged: TNotifyEvent;
    FMonthChanged: TNotifyEvent;
    FYearChanged: TNotifyEvent;
    FPropsChanged: boolean;
    function GetDateTime: TDateTime;
    procedure SetDateTime(const AValue: TDateTime);
    procedure GetProps;
    procedure SetProps;
    function GetDisplaySettings: TDisplaySettings;
    procedure SetDisplaySettings(const AValue: TDisplaySettings);
    function GetDate: String;
    procedure SetDate(const AValue: String);
  protected
    procedure LMChanged(var Message: TLMessage); message LM_CHANGED;
    procedure LMMonthChanged(var Message: TLMessage); message LM_MONTHCHANGED;
    procedure LMYearChanged(var Message: TLMessage); message LM_YEARCHANGED;
    procedure LMDayChanged(var Message: TLMessage); message LM_DAYCHANGED;
    class function GetControlClassDefaultSize: TPoint; override;
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    function HitTest(APoint: TPoint): TCalendarPart;
    procedure InitializeWnd; override;
    property Date: String read GetDate write SetDate stored False;
    property DateTime: TDateTime read GetDateTime write SetDateTime;
    property DisplaySettings: TDisplaySettings read GetDisplaySettings
      write SetDisplaySettings default DefaultDisplaySettings;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnDayChanged: TNotifyEvent read FDayChanged write FDayChanged;
    property OnMonthChanged: TNotifyEvent read FMonthChanged write FMonthChanged;
    property OnYearChanged: TNotifyEvent read FYearChanged write FYearChanged;
  end;

  { TCalendar }
  
  TCalendar = class(TCustomCalendar)
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property Constraints;
    property Date;
    property DateTime;
    property DisplaySettings;
    property OnChange;
    property OnChangeBounds;
    property OnClick;
    property OnDayChanged;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMonthChanged;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnUTF8KeyPress;
    property OnYearChanged;
    property PopupMenu;
    property ShowHint;
    property TabStop;
    property Visible;
  end;

procedure Register;
  
implementation

uses
  WSCalendar;

procedure Register;
begin
  RegisterComponents('Misc',[TCalendar]);
end;

{ TCustomCalendar }

constructor TCustomCalendar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fCompStyle := csCalendar;
  SetInitialBounds(0,0,GetControlClassDefaultSize.X,GetControlClassDefaultSize.Y);
  FDisplaySettings := DefaultDisplaySettings;
  ControlStyle:=ControlStyle-[csTripleClicks,csQuadClicks,csAcceptsControls,csCaptureMouse];
  DateTime := Now;
end;

function TCustomCalendar.HitTest(APoint: TPoint): TCalendarPart;
begin
  if HandleAllocated then
    Result := TWSCustomCalendarClass(WidgetSetClass).HitTest(Self, APoint)
  else
    Result := cpNoWhere;
end;

procedure TCustomCalendar.Loaded;
begin
  inherited Loaded;
  if FPropsChanged then SetProps;
end;

procedure TCustomCalendar.InitializeWnd;
begin
  inherited InitializeWnd;
  if FPropsChanged then SetProps;
end;

function TCustomCalendar.GetDate: String;
begin
  Result := '';
  GetProps;
  Result := FDateAsString;
end;

procedure TCustomCalendar.SetDate(const AValue: String);
var
  NewDate: TDateTime;
begin
  if FDateAsString = AValue then Exit;

  NewDate:=StrToDate(AValue);  //test to see if date valid ....
  // no exception => set valid date
  FDateAsString := AValue;
  FDate := NewDate;
  SetProps;
end;

function TCustomCalendar.GetDisplaySettings: TDisplaySettings;
begin
  Result := FDisplaySettings;
end;

procedure TCustomCalendar.SetDisplaySettings(const AValue: TDisplaySettings);
begin
  if FDisplaySettings = AValue then exit;
  FDisplaySettings := AValue;
  SetProps;
end;

function TCustomCalendar.GetDateTime: TDateTime;
begin
  GetProps;
  Result:=FDate;
end;

procedure TCustomCalendar.SetDateTime(const AValue: TDateTime);
{$IFDEF WINDOWS}
var
  CalendarMinDate,CalendarMaxDate: integer;
{$ENDIF}
begin
  if AValue=FDate then exit;
  {$IFDEF WINDOWS} // TODO: move this test to the win32 interface?
  CalendarMinDate:=-53787;// 14 sep 1752, start of Gregorian calendar in England
  CalendarMaxDate:=trunc(MaxDateTime);
  if not ((AValue>=CalendarMinDate)and(AValue<=CalendarMaxDate)) then
    raise EInvalidDate.CreateFmt(rsInvalidDateRangeHint, [DateToStr(AValue),
        DateToStr(CalendarMinDate), DateToStr(CalendarMaxDate)]);
  {$ENDIF}
  FDate:=AValue;
  FDateAsString:=FormatDateTime(ShortDateFormat,FDate);
  {$IFDEF VerboseCalenderSetDate}
  DebugLn('TCustomCalendar.SetDateTime FDate=',FDate,' FDateAsString=',FDateAsString,' ShortDateFormat=',ShortDateFormat);
  {$ENDIF}
  SetProps;
end;

procedure TCustomCalendar.GetProps;
begin
  if HandleAllocated and ([csLoading,csDestroying]*ComponentState=[]) then
  begin
    FDate := TWSCustomCalendarClass(WidgetSetClass).GetDateTime(Self);
    FDateAsString := FormatDateTime(ShortDateFormat,FDate);
    {$IFDEF VerboseCalenderSetDate}
    DebugLn('TCustomCalendar.GetProps A ',FDate,' ',FDateAsString);
    {$ENDIF}
  end;
end;

procedure TCustomCalendar.SetProps;
begin
  if HandleAllocated and ([csLoading,csDestroying]*ComponentState=[]) then
  begin
    FPropsChanged := False;
    {$IFDEF VerboseCalenderSetDate}
    DebugLn('TCustomCalendar.SetProps A ',FDate,' ',FDateAsString);
    {$ENDIF}
    TWSCustomCalendarClass(WidgetSetClass).SetDateTime(Self, FDate);
    TWSCustomCalendarClass(WidgetSetClass).SetDisplaySettings(Self, FDisplaySettings);
  end
  else
    FPropsChanged := True;
end;

procedure TCustomCalendar.LMChanged(var Message: TLMessage);
var
  NewDate: TDateTime;
  OldDay, OldMonth, OldYear: word;
  NewDay, NewMonth, NewYear: word;
begin
  NewDate := TWSCustomCalendarClass(WidgetSetClass).GetDateTime(Self);
  if (NewDate=FDate) then exit;
  DecodeDate(NewDate, NewYear, NewMonth, NewDay);
  DecodeDate(FDate, OldYear, OldMonth, OldDay);
  FDate:= NewDate;
  if (OldYear<>NewYear) and Assigned(OnYearChanged) then OnYearChanged(self);
  if (OldMonth<>NewMonth) and Assigned(OnMonthChanged) then OnMonthChanged(self);
  if (OldDay<>NewDay) and Assigned(OnDayChanged) then OnDayChanged(self);
  if Assigned(OnChange) then OnChange(self);
end;

procedure TCustomCalendar.LMDAYChanged(var Message: TLMessage);
begin
  if Assigned(OnDayChanged) then OnDayChanged(self);
  if Assigned(OnChange) then OnChange(self);
end;

class function TCustomCalendar.GetControlClassDefaultSize: TPoint;
begin
  Result.X:=220;
  Result.Y:=190;
end;

procedure TCustomCalendar.LMMonthChanged(var Message: TLMessage);
begin
  if Assigned(OnMonthChanged) then OnMonthChanged(self);
  if Assigned(OnChange) then OnChange(self);
end;

procedure TCustomCalendar.LMYEARChanged(var Message: TLMessage);
begin
  if Assigned(OnYearChanged) then OnYearChanged(self);
  if Assigned(OnChange) then OnChange(self);
end;

initialization
  RegisterPropertyToSkip(TCalendar, 'ReadOnly', 'Obsoleted property', '');

end.
