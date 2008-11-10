{
 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
unit ButtonPanel;

{$mode objfpc}{$h+}

interface

uses
  Buttons, Classes, LCLProc, Controls, Dialogs, ExtCtrls, Forms, Graphics,
  GraphType, LCLType, SysUtils, LCLStrConsts;

type
  TButtonOrder  = (boDefault, boCloseCancelOK, boCloseOKCancel);
  TPanelButton  = (pbOK, pbCancel, pbClose, pbHelp);
  TPanelButtons = set of TPanelButton;

const
  DefShowButtons = [pbOK, pbCancel, pbClose, pbHelp];
  DefShowGlyphs = [pbOK, pbCancel, pbClose, pbHelp];

type
  TPanelBitBtn = class(TCustomBitBtn)
  public
    constructor Create(AOwner: TComponent); override;
  published
    // the translation of the IDE at designtime is used default item
    property Caption stored True;
    property Enabled;
    property Font;
    property Glyph;
    property OnClick;
  end;

  { TCustomButtonPanel }

  TCustomButtonPanel = class(TCustomPanel)
  private
    FCancelGlyph: TBitmap;
    FCloseGlyph: TBitmap;
    FHelpGlyph:  TBitmap;
    FOKGlyph:    TBitmap;
    FShowButtons: TPanelButtons;
    FShowGlyphs: TPanelButtons;
    FBevel:      TBevel;
    FCancelButton: TPanelBitBtn;
    FCloseButton: TPanelBitBtn;
    FHelpButton: TPanelBitBtn;
    FOKButton:   TPanelBitBtn;
    FButtonOrder: TButtonOrder;
    FDefaultButton: TPanelButton;
    procedure OrderButtonsRightToLeft(TheButtons: array of TControl);
    procedure ButtonOrderCloseCancelOK;
    procedure ButtonOrderCloseOKCancel;
    procedure DoButtonOrder;
    procedure DoDefaultButton;
    procedure DoRestoreCancel;
    procedure DoShowButtons;
    procedure DoShowGlyphs;
    procedure SetButtonOrder(Value: TButtonOrder);
    procedure SetDefaultButton(Value: TPanelButton);
    procedure SetShowButtons(Value: TPanelButtons);
    procedure SetShowGlyphs(Value: TPanelButtons);
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property OKButton: TPanelBitBtn read FOKButton stored False;
    property HelpButton: TPanelBitBtn read FHelpButton stored False;
    property CloseButton: TPanelBitBtn read FCloseButton stored False;
    property CancelButton: TPanelBitBtn read FCancelButton stored False;
    property ButtonOrder: TButtonOrder read FButtonOrder write SetButtonOrder;

    property DefaultButton: TPanelButton read FDefaultButton write SetDefaultButton;
    property ShowButtons: TPanelButtons read FShowButtons write SetShowButtons default DefShowButtons;
    property ShowGlyphs: TPanelButtons read FShowGlyphs write SetShowGlyphs default DefShowGlyphs;
  published
  end;

  { TButtonPanel }

  TButtonPanel = class(TCustomButtonPanel)
  published
    property Align;
    property Anchors;
    property AutoSize;
    property OKButton;
    property HelpButton;
    property CloseButton;
    property CancelButton;
    property ButtonOrder;
    property TabOrder;
    property DefaultButton;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnUTF8KeyPress;
    property ShowButtons;
    property ShowGlyphs;
    property Visible;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Misc', [TButtonPanel]);
end;

constructor TPanelBitBtn.Create(AOwner: TComponent);
begin
  inherited;

  Include(FComponentStyle, csSubComponent);
end;

procedure TCustomButtonPanel.DoShowButtons;
begin
  if FOKButton<>nil then
    FOKButton.Visible     := (pbOK in FShowButtons);
  if FCancelButton<>nil then
    FCancelButton.Visible := (pbCancel in FShowButtons);
  if FCloseButton<>nil then
    FCloseButton.Visible  := (pbClose in FShowButtons);
  if FHelpButton<>nil then
    FHelpButton.Visible   := (pbHelp in FShowButtons);

  DoButtonOrder;
end;

procedure TCustomButtonPanel.SetShowButtons(Value: TPanelButtons);
begin
  if FShowButtons = Value then
    Exit;

  FShowButtons := Value;

  DoShowButtons;
end;

procedure TCustomButtonPanel.DoShowGlyphs;
begin
  if FOKButton<>nil then
  begin
    if not (pbOK in FShowGlyphs) then
    begin
      FOKGlyph.Assign(FOKButton.Glyph);
      FOKButton.Glyph.Assign(nil);
    end
    else
      FOKButton.Glyph.Assign(FOKGlyph);
  end;

  if FCancelButton<>nil then
  begin
    if not (pbCancel in FShowGlyphs) then
    begin
      FCancelGlyph.Assign(FCancelButton.Glyph);
      FCancelButton.Glyph.Assign(nil);
    end
    else
      FCancelButton.Glyph.Assign(FCancelGlyph);
  end;

  if FCloseButton<>nil then
  begin
    if not (pbClose in FShowGlyphs) then
    begin
      FCloseGlyph.Assign(FCloseButton.Glyph);
      FCloseButton.Glyph.Assign(nil);
    end
    else
      FCloseButton.Glyph.Assign(FCloseGlyph);
  end;

  if FHelpButton<>nil then
  begin
    if not (pbHelp in FShowGlyphs) then
    begin
      FHelpGlyph.Assign(FHelpButton.Glyph);
      FHelpButton.Glyph.Assign(nil);
    end
    else
      FHelpButton.Glyph.Assign(FHelpGlyph);
  end;
end;

procedure TCustomButtonPanel.SetShowGlyphs(Value: TPanelButtons);
begin
  if FShowGlyphs = Value then
    Exit;

  FShowGlyphs := Value;

  DoShowGlyphs;
end;

procedure TCustomButtonPanel.DoButtonOrder;
begin
  case FButtonOrder of
    boCloseCancelOK: ButtonOrderCloseCancelOK;
    boCloseOKCancel: ButtonOrderCloseOKCancel;
    else
      //boDefault
      {$IFDEF UNIX}
        ButtonOrderCloseCancelOK;
      {$ELSE}
        ButtonOrderCloseOKCancel;
      {$ENDIF}
  end;
end;

procedure TCustomButtonPanel.OrderButtonsRightToLeft(TheButtons: array of TControl);
 // reorder aligned buttons from left to right.
 // The buttons are Align=alRight. The order is determined by the right edge.
 // Set the Left+Wifth property to some values in ascending order and the LCL
 // will do the rest.
var
  i, x: integer;
begin
  i := High(TheButtons);
  while (i >= Low(TheButtons)) and (TheButtons[i]=nil) do dec(i);
  if i < Low(TheButtons) then
    exit; // no buttons
  x:=TheButtons[i].Left+TheButtons[i].Width;
  Dec(i);
  while (i >= Low(TheButtons)) and (TheButtons[i].Left+TheButtons[i].Width < x) do
  begin
    x:=TheButtons[i].Left+TheButtons[i].Width;
    Dec(i);
  end;
  if i < Low(TheButtons) then
    exit; // all buttons are already in the correct order

  DisableAlign;
  try
    x := ClientWidth;
    for i := High(TheButtons) downto Low(TheButtons) do
    begin
      if TheButtons[i]=nil then continue;
      Dec(x, TheButtons[i].Width);
      TheButtons[i].Left := x;
    end;
  finally
    EnableAlign;
  end;
end;

procedure TCustomButtonPanel.ButtonOrderCloseCancelOK;
begin
  OrderButtonsRightToLeft([FCloseButton, FCancelButton, FOKButton]);

  //set taborder
  if FOKButton<>nil then
    FOKButton.TabOrder     := 0;
  if FCancelButton<>nil then
    FCancelButton.TabOrder := 1;
  if FCloseButton<>nil then
    FCloseButton.TabOrder  := 2;
  if FHelpButton<>nil then
    FHelpButton.TabOrder   := 3;
end;

procedure TCustomButtonPanel.ButtonOrderCloseOKCancel;
begin
  OrderButtonsRightToLeft([FCloseButton, FOKButton, FCancelButton]);

  //set taborder
  if FCancelButton<>nil then
    FCancelButton.TabOrder := 0;
  if FOKButton<>nil then
    FOKButton.TabOrder     := 1;
  if FCloseButton<>nil then
    FCloseButton.TabOrder  := 2;
  if FHelpButton<>nil then
    FHelpButton.TabOrder   := 3;
end;

procedure TCustomButtonPanel.SetButtonOrder(Value: TButtonOrder);
begin
  if FButtonOrder = Value then
    Exit;

  FButtonOrder := Value;

  DoButtonOrder;
end;

procedure TCustomButtonPanel.DoDefaultButton;
begin
  if FOKButton<>nil then
    FOKButton.Default     := FDefaultButton = pbOk;
  if FCancelButton<>nil then
    FCancelButton.Default := FDefaultButton = pbCancel;
  if FCloseButton<>nil then
    FCloseButton.Default  := FDefaultButton = pbClose;
  if FHelpButton<>nil then
    FHelpButton.Default   := FDefaultButton = pbHelp;
end;

procedure TCustomButtonPanel.DoRestoreCancel;
begin
  if FCancelButton <> nil then
  begin
    // to restore cancel button we need to do this hack
    FCancelButton.Cancel := False;
    FCancelButton.Cancel := True;
  end;
end;

procedure TCustomButtonPanel.SetDefaultButton(Value: TPanelButton);
begin
  if FDefaultButton = Value then
    Exit;

  FDefaultButton := Value;

  DoDefaultButton;
end;

procedure TCustomButtonPanel.Loaded;
begin
  inherited Loaded;
  DoRestoreCancel;
  DoDefaultButton;
  DoShowGlyphs;
  DoShowButtons;
end;

procedure TCustomButtonPanel.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  if Operation=opRemove then begin
    if AComponent=FOKButton then
    begin
      FOKButton:=nil;
      Exclude(FShowButtons,pbOK);
    end else if AComponent=FCancelButton then
    begin
      FCancelButton:=nil;
      Exclude(FShowButtons,pbCancel);
    end else if AComponent=FCloseButton then
    begin
      FCloseButton:=nil;
      Exclude(FShowButtons,pbClose);
    end else if AComponent=FHelpButton then
    begin
      FHelpButton:=nil;
      Exclude(FShowButtons,pbHelp);
    end;
  end;
  inherited Notification(AComponent, Operation);
end;

constructor TCustomButtonPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csOwnedChildsSelectable];

  Align      := alBottom;
  BevelInner := bvNone;
  BevelOuter := bvNone;
  Caption    := '';
  ControlStyle := ControlStyle - [csSetCaption];
  AutoSize   := True;
  BorderSpacing.Left := 6;
  BorderSpacing.Right := 6;

  FBevel := TBevel.Create(Self);
  FBevel.Parent := Self;
  with FBevel do
  begin
    Name   := 'Bevel';
    Shape  := bsTopLine;
    Align  := alTop;
    Height := 2;
    BorderSpacing.Left := 6;
    BorderSpacing.Right := 6;
  end;
  FCancelButton := TPanelBitBtn.Create(Self);
  with FCancelButton do
  begin
    Name     := 'CancelButton';
    Parent   := Self;
    Kind     := bkCancel;
    BorderSpacing.Around := 6;
    AutoSize := True;
    Align    := alRight;
    Caption  := rsMbCancel;
  end;
  FCloseButton := TPanelBitBtn.Create(Self);
  with FCloseButton do
  begin
    Name     := 'CloseButton';
    Parent   := Self;
    Kind     := bkClose;
    BorderSpacing.Around := 6;
    AutoSize := True;
    Align    := alRight;
    Caption  := rsMbClose;
  end;
  FHelpButton := TPanelBitBtn.Create(Self);
  with FHelpButton do
  begin
    Name     := 'HelpButton';
    Parent   := Self;
    Kind     := bkHelp;
    BorderSpacing.Around := 6;
    AutoSize := True;
    Align    := alLeft;
    Caption  := rsMbHelp;
  end;
  FOKButton := TPanelBitBtn.Create(Self);
  with FOKButton do
  begin
    Name     := 'OKButton';
    Parent   := Self;
    Kind     := bkOK;
    BorderSpacing.Around := 6;
    AutoSize := True;
    Align    := alRight;
    Caption  := rsMbOK;
  end;

  FCancelGlyph := TBitmap.Create;
  FCloseGlyph  := TBitmap.Create;
  FHelpGlyph   := TBitmap.Create;
  FOKGlyph     := TBitmap.Create;

  FOKGlyph.Assign(FOKButton.Glyph);
  FCancelGlyph.Assign(FCancelButton.Glyph);
  FCloseGlyph.Assign(FCloseButton.Glyph);
  FHelpGlyph.Assign(FHelpButton.Glyph);

  FDefaultButton := pbOK;
  FButtonOrder   := boDefault;
  FShowButtons   := DefShowButtons;
  FShowGlyphs    := DefShowGlyphs;

  if not (csLoading in ComponentState) then
  begin
    DoDefaultButton;
    DoShowButtons;
    DoShowGlyphs;
  end;
end;

destructor TCustomButtonPanel.Destroy;
begin
  FreeAndNil(FCancelGlyph);
  FreeAndNil(FCloseGlyph);
  FreeAndNil(FHelpGlyph);
  FreeAndNil(FOKGlyph);
  inherited Destroy;
end;

end.
