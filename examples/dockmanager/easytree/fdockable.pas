unit fDockable;

{$MODE Delphi}

interface

uses
  SysUtils, Forms, StdCtrls, ExtCtrls;

type

  { TDockable }

  TDockable = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Shape1: TShape;
    procedure Button1Click(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private

  public

  end;

implementation

{$R *.lfm}

procedure TDockable.Button1Click(Sender: TObject);
begin
  beep;
end;

procedure TDockable.FormResize(Sender: TObject);
begin
  Label1.Caption := Format('(%d,%d)-(%d,%d)',
  [Top, Left, Width, Height]);
  Label2.Caption := Format('(%d,%d)',
  [
  BaseBounds.Right - BaseBounds.Left, BaseBounds.Bottom - BaseBounds.Top
  //ClientWidth, ClientHeight
  ]);
end;

end.

