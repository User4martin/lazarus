{ $Id$}
{
 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

  Author: Vincent Snijders

  Abstract:
     Shows a non-modal calendar popup for a TDateEdit
}

unit CalendarPopup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Calendar, LCLProc, LCLType;
  
type
  TReturnDateEvent = procedure (Sender: TObject; const Date: TDateTime) of object;

  { TCalendarPopupForm }

  TCalendarPopupForm = class(TForm)
    Calendar: TCalendar;
    procedure CalendarDblClick(Sender: TObject);
    procedure CalendarKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
  private
    FClosed: boolean;
    FOnReturnDate: TReturnDateEvent;
    procedure Initialize(const PopupOrigin: TPoint; ADate: TDateTime;
                         const DisplaySettings: TDisplaySettings);
    procedure ReturnDate;
  protected
    procedure Paint; override;
  end;

procedure ShowCalendarPopup(const Position: TPoint; ADate: TDateTime;
    const CalendarDisplaySettings: TDisplaySettings;
    const OnReturnDate: TReturnDateEvent; const OnShowHide: TNotifyEvent = nil);

implementation

{$R *.lfm}

procedure ShowCalendarPopup(const Position: TPoint; ADate: TDateTime;
  const CalendarDisplaySettings: TDisplaySettings;
  const OnReturnDate: TReturnDateEvent; const OnShowHide: TNotifyEvent = nil);
var
  PopupForm: TCalendarPopupForm;
begin
  PopupForm := TCalendarPopupForm.Create(nil);
  PopupForm.Initialize(Position, ADate, CalendarDisplaySettings);
  PopupForm.FOnReturnDate := OnReturnDate;
  PopupForm.OnShow := OnShowHide;
  PopupForm.OnHide := OnShowHide;
  PopupForm.Show;
end;

{ TCalendarPopupForm }

procedure TCalendarPopupForm.FormCreate(Sender: TObject);
begin
  FClosed := false;
  Application.AddOnDeactivateHandler(@FormDeactivate);
end;

procedure TCalendarPopupForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  //DebugLn(['TCalendarPopupForm.FormClose ']);
  FClosed := true;
  Application.RemoveOnDeactivateHandler(@FormDeactivate);
  CloseAction := caFree;
end;

procedure TCalendarPopupForm.CalendarDblClick(Sender: TObject);
var
  P: TPoint;
begin
  P := Calendar.ScreenToClient(Mouse.CursorPos);
  if Calendar.HitTest(P) in [cpNoWhere, cpDate] then
    ReturnDate;
end;

procedure TCalendarPopupForm.CalendarKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Handled: Boolean;
begin
  if Shift=[] then
  begin
    Handled := true;
    case Key of
    VK_ESCAPE:
      Close;
    VK_RETURN, VK_SPACE:
      ReturnDate;
    else
      Handled := false;
    end;
    if Handled then
      Key := 0;
  end;
end;

procedure TCalendarPopupForm.FormDeactivate(Sender: TObject);
begin
  //DebugLn(['TCalendarPopupForm.FormDeactivate ',DbgSName(GetCaptureControl)]);
  //Immediately hide the form, otherwise it stays visible while e.g. user is draging
  //another form (Issue #0020647)
  Hide;
  if (not FClosed) then
    Close;
end;

procedure TCalendarPopupForm.Initialize(const PopupOrigin: TPoint;
  ADate: TDateTime; const DisplaySettings: TDisplaySettings);
var
  ABounds: TRect;
begin
  ABounds := Screen.MonitorFromPoint(PopupOrigin).BoundsRect;
  if PopupOrigin.X + Width > ABounds.Right then
    Left := ABounds.Right - Width
  else
    Left := PopupOrigin.X;
  if PopupOrigin.Y + Height > ABounds.Bottom then
    Top := ABounds.Bottom - Height
  else
    Top := PopupOrigin.Y;
  Calendar.DateTime := ADate;
  Calendar.DisplaySettings:=DisplaySettings;
end;

procedure TCalendarPopupForm.ReturnDate;
begin
  if Assigned(FOnReturnDate) then
    FOnReturnDate(Self, Calendar.DateTime);
  if not FClosed then
    Close;
end;

procedure TCalendarPopupForm.Paint;
begin
  inherited Paint;
  Canvas.Pen.Color := clWindowText;
  Canvas.Pen.Style := psSolid;
  Canvas.Rectangle(0, 0, Width-1, Height-1);
end;

end.
