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
}
unit options_debugger_signals;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, StdCtrls, Menus,
  ComCtrls, Buttons,
  LazarusIDEStrConsts, IDEOptionsIntf, Debugger, BaseDebugManager;
type

  { TDebuggerSignalsOptions }

  TDebuggerSignalsOptions = class(TAbstractIDEOptionsEditor)
    cmdSignalAdd: TBitBtn;
    cmdSignalRemove: TBitBtn;
    gbSignals: TGroupBox;
    lvSignals: TListView;
    mnuHandledByProgram: TMenuItem;
    mnuiHandledByDebugger: TMenuItem;
    mnuResumeHandled: TMenuItem;
    mnuResumeUnhandled: TMenuItem;
    N1: TMenuItem;
    popSignal: TPopupMenu;
  private
    procedure AddSignalLine(const ASignal: TIDESignal);
  public
    function GetTitle: String; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation
const
  HANDLEDBY_CAPTION: array [Boolean] of String = ('Program', 'Debugger');
  RESUME_CAPTION: array[Boolean] of String = ('Unhandled', 'Handled');

{ TDebuggerSignalsOptions }

procedure TDebuggerSignalsOptions.AddSignalLine(const ASignal: TIDESignal);
var
  Item: TListItem;
begin
  Item := lvSignals.Items.Add;
  Item.Caption := ASignal.Name;
  Item.SubItems.Add(IntToStr(ASignal.ID));
  Item.SubItems.Add(HANDLEDBY_CAPTION[ASignal.HandledByDebugger]);
  Item.SubItems.Add(RESUME_CAPTION[ASignal.ResumeHandled]);
  Item.Data := ASignal;
end;

function TDebuggerSignalsOptions.GetTitle: String;
begin
  Result := lisDebugOptionsFrmOSExceptions;
end;

procedure TDebuggerSignalsOptions.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  gbSignals.Caption := lisDebugOptionsFrmSignals;
  lvSignals.Column[0].Caption := lisDebugOptionsFrmName;
  lvSignals.Column[1].Caption := lisDebugOptionsFrmID;
  lvSignals.Column[2].Caption := lisDebugOptionsFrmHandledBy;
  lvSignals.Column[3].Caption := lisDebugOptionsFrmResume;
  cmdSignalAdd.Caption := lisCodeTemplAdd;
  cmdSignalRemove.Caption := lisExtToolRemove;
  cmdSignalAdd.LoadGlyphFromLazarusResource('laz_add');
  cmdSignalRemove.LoadGlyphFromLazarusResource('laz_delete');

  mnuHandledByProgram.Caption := lisDebugOptionsFrmHandledByProgram;
  mnuiHandledByDebugger.Caption := lisDebugOptionsFrmHandledByDebugger;
  mnuResumeHandled.Caption := lisDebugOptionsFrmResumeHandled;
  mnuResumeUnhandled.Caption := lisDebugOptionsFrmResumeUnhandled;
end;

procedure TDebuggerSignalsOptions.ReadSettings(AOptions: TAbstractIDEOptions);
var
  n: integer;
begin
  for n := 0 to DebugBoss.Signals.Count - 1 do
    AddSignalLine(DebugBoss.Signals[n]);
end;

procedure TDebuggerSignalsOptions.WriteSettings(AOptions: TAbstractIDEOptions);
begin
  // todo
end;

class function TDebuggerSignalsOptions.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := nil;
end;

initialization
  {$I options_debugger_signals.lrs}
  RegisterIDEOptionsEditor(GroupDebugger, TDebuggerSignalsOptions, DbgOptionsSignals);
end.

