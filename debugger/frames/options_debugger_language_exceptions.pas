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
unit options_debugger_language_exceptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, StdCtrls, CheckLst,
  Buttons, Dialogs,
  LazarusIDEStrConsts, IDEOptionsIntf, Debugger, BaseDebugManager;

type

  { TDebuggerLanguageExceptionsOptions }

  TDebuggerLanguageExceptionsOptions = class(TAbstractIDEOptionsEditor)
    bgIgnoreExceptions: TGroupBox;
    chkBreakOnException: TCheckBox;
    clbExceptions: TCheckListBox;
    cmdExceptionAdd: TBitBtn;
    cmdExceptionRemove: TBitBtn;
    procedure cmdExceptionAddClick(Sender: TObject);
    procedure cmdExceptionRemoveClick(Sender: TObject);
  private
    FExceptionDeleteList: TStringList;
    procedure AddExceptionLine(const AException: TIDEException; AName: String);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetTitle: String; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

{ TDebuggerLanguageExceptionsOptions }

procedure TDebuggerLanguageExceptionsOptions.cmdExceptionAddClick(
  Sender: TObject);
var
  idx: Integer;
  S: String;
begin
  if not InputQuery('Add Exception', 'Enter the name of the exception', S)
  then Exit;

  if clbExceptions.Items.IndexOf(S) = -1
  then begin
    idx := FExceptionDeleteList.IndexOf(S);
    if idx = -1
    then begin
      AddExceptionLine(nil, S);
    end
    else begin
      AddExceptionLine(TIDEException(FExceptionDeleteList.Objects[idx]), S);
      FExceptionDeleteList.Delete(idx);
    end;
  end
  else begin
    MessageDlg('Duplicate Exception name', mtError, [mbOK], 0);
  end;
end;

procedure TDebuggerLanguageExceptionsOptions.cmdExceptionRemoveClick(
  Sender: TObject);
var
  idx: Integer;
  obj: TObject;
begin
  idx := clbExceptions.ItemIndex;
  if idx <> -1
  then begin
    obj := clbExceptions.Items.Objects[idx];
    if obj <> nil
    then FExceptionDeleteList.AddObject(clbExceptions.Items[idx], obj);
    clbExceptions.Items.Delete(idx);
  end;
  cmdExceptionRemove.Enabled :=  clbExceptions.ItemIndex <> -1;
end;

procedure TDebuggerLanguageExceptionsOptions.AddExceptionLine(
  const AException: TIDEException; AName: String);
var
  idx: Integer;
begin
  if (AName = '') and (AException <> nil)
  then AName := AException.Name;
  if AName = '' then Exit;

  idx := clbExceptions.Items.AddObject(AName, AException);
  clbExceptions.Checked[idx] := (AException = nil) or AException.Enabled;
end;

constructor TDebuggerLanguageExceptionsOptions.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FExceptionDeleteList := TStringList.Create;
  FExceptionDeleteList.Sorted := True;
end;

destructor TDebuggerLanguageExceptionsOptions.Destroy;
begin
  FreeAndNil(FExceptionDeleteList);
  inherited Destroy;
end;

function TDebuggerLanguageExceptionsOptions.GetTitle: String;
begin
  Result := lisDebugOptionsFrmLanguageExceptions;
end;

procedure TDebuggerLanguageExceptionsOptions.Setup(
  ADialog: TAbstractOptionsEditorDialog);
begin
  bgIgnoreExceptions.Caption := lisDebugOptionsFrmIgnoreTheseExceptions;
  cmdExceptionRemove.Caption := lisExtToolRemove;
  cmdExceptionAdd.Caption := lisCodeTemplAdd;
  cmdExceptionRemove.LoadGlyphFromLazarusResource('laz_delete');
  cmdExceptionAdd.LoadGlyphFromLazarusResource('laz_add');
  chkBreakOnException.Caption := lisDebugOptionsFrmBreakOnLazarusExceptions;
end;

procedure TDebuggerLanguageExceptionsOptions.ReadSettings(
  AOptions: TAbstractIDEOptions);
var
  n: integer;
begin
  for n := 0 to DebugBoss.Exceptions.Count - 1 do
    AddExceptionLine(DebugBoss.Exceptions[n], '');
end;

procedure TDebuggerLanguageExceptionsOptions.WriteSettings(
  AOptions: TAbstractIDEOptions);
var
  n: integer;
  ie: TIDEException;
begin
  for n := 0 to FExceptionDeleteList.Count - 1 do
    FExceptionDeleteList.Objects[n].Free;

  for n := 0 to clbExceptions.Items.Count - 1 do
  begin
    ie := TIDEException(clbExceptions.Items.Objects[n]);
    if ie = nil
    then begin
      ie := DebugBoss.Exceptions.Add(clbExceptions.Items[n]);
      ie.Enabled := clbExceptions.Checked[n];
    end
    else begin
      ie.BeginUpdate;
      try
        ie.Name := clbExceptions.Items[n];
        ie.Enabled := clbExceptions.Checked[n];
      finally
        ie.EndUpdate;
      end;
    end;
  end;
end;

class function TDebuggerLanguageExceptionsOptions.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := nil;
end;

initialization
  {$I options_debugger_language_exceptions.lrs}
  RegisterIDEOptionsEditor(GroupDebugger, TDebuggerLanguageExceptionsOptions, DbgOptionsLanguageExceptions);
end.

