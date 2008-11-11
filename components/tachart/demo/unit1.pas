unit unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  TAGraph, TASeries, Buttons, StdCtrls;

type
  { TForm1 }

  TForm1 = class(TForm)
    btnClearArea: TButton;
    btnClearBar: TButton;
    btnClearLine: TButton;
    btnClearPie: TButton;
    btnAddBar: TButton;
    btnAddPie: TButton;
    btnAddLine: TButton;
    btnAddArea: TButton;
    Chart1: TChart;
    cbBottomAxis: TCheckBox;
    cbLeftAxis: TCheckBox;
    cbTitle: TCheckBox;
    cbFooter: TCheckBox;
    cbInverted: TCheckBox;
    cbLegend: TCheckBox;
    lblAdd: TLabel;
    lblAdd1: TLabel;
    Panel1: TPanel;
    procedure btnClearAreaClick(Sender: TObject);
    procedure btnClearBarClick(Sender: TObject);
    procedure btnClearLineClick(Sender: TObject);
    procedure btnClearPieClick(Sender: TObject);
    procedure cbInvertedChange(Sender: TObject);
    procedure btnAddAreaClick(Sender: TObject);
    procedure btnAddBarClick(Sender: TObject);
    procedure btnAddLineClick(Sender: TObject);
    procedure btnAddPieClick(Sender: TObject);
    procedure cbBottomAxisChange(Sender: TObject);
    procedure cbLeftAxisChange(Sender: TObject);
    procedure cbTitleChange(Sender: TObject);
    procedure cbFooterChange(Sender: TObject);
    procedure cbLegendChange(Sender: TObject);
  private
    FArea: TAreaSeries;
    FBar: TBarSeries;
    FLine: TSerie;
    FPie: TPieSeries;
    x, y, x1, y1, x3, y3: Double;
    procedure InitBar;
    procedure InitLine;
    procedure InitPie;
    procedure InitArea;
  end;

var
  Form1: TForm1; 

implementation

{ TForm1 }

procedure TForm1.btnAddAreaClick(Sender: TObject);
begin
  if FArea = nil then InitArea;

  X3 := X3 + 1;
  if random(2) >= 0.7 then Y3 := Y3 + random(5)
  else if random(2) >= 0.7 then Y3 := 0
  else Y3 := Y3 - random(5);
  FArea.AddXY(x3, y3, '', clTAColor);
end;

procedure TForm1.btnAddBarClick(Sender: TObject);
begin
  if FBar = nil then InitBar;

  FBar.AddXY(x, y, '', clRed);
  X := X + 1;
  if random(2) >= 0.7 then Y := Y + random(5)
  else if random(2) >= 0.7 then Y := 0
  else Y := Y - random(5);
end;

procedure TForm1.btnAddLineClick(Sender: TObject);
begin
  if FLine = nil then InitLine;

  FLine.AddXY(x1, y1, '', clGreen);
  X1 := X1 + 1.5;
  if random(2) >= 0.5 then Y1 := Y1 + random(10)
  else Y1 := Y1 - random(5);
end;

procedure TForm1.btnAddPieClick(Sender: TObject);
begin
  if FPie = nil then InitPie;

  FPie.AddPie(3.4234235235, 'sde21312', clTAColor);
  FPie.AddPie(0.2323, 'adassssssdddddd', clTAColor);
  FPie.AddPie(30, 'filipe romao', clTAColor);
  FPie.AddPie(40, '234eds sa', clTAColor);
end;

procedure TForm1.btnClearAreaClick(Sender: TObject);
begin
  FreeAndNil(FArea);
end;

procedure TForm1.btnClearBarClick(Sender: TObject);
begin
  FreeAndNil(FBar);
end;

procedure TForm1.btnClearLineClick(Sender: TObject);
begin
  FreeAndNil(FLine);
end;

procedure TForm1.btnClearPieClick(Sender: TObject);
begin
  FreeAndNil(FPie);
end;

procedure TForm1.cbBottomAxisChange(Sender: TObject);
begin
  Chart1.BottomAxis.Visible := cbBottomAxis.Checked;
end;

procedure TForm1.cbFooterChange(Sender: TObject);
begin
  Chart1.Foot.Visible := cbFooter.Checked;
end;

procedure TForm1.cbInvertedChange(Sender: TObject);
begin
  Chart1.BottomAxis.Inverted := cbInverted.Checked;
  Chart1.LeftAxis.Inverted := cbInverted.Checked;
end;

procedure TForm1.cbLegendChange(Sender: TObject);
begin
  Chart1.Legend.Visible := cbLegend.Checked;
end;

procedure TForm1.cbLeftAxisChange(Sender: TObject);
begin
  Chart1.LeftAxis.Visible := cbLeftAxis.Checked;
end;

procedure TForm1.cbTitleChange(Sender: TObject);
begin
  Chart1.Title.Visible := cbTitle.Checked;
end;

procedure TForm1.InitArea;
begin
  FArea := TAreaSeries.Create(Chart1);
  Chart1.AddSerie(FArea);
  FArea.SeriesColor := clred;
  FArea.Stairs := true;
  FArea.InvertedStairs := false;
end;

procedure TForm1.InitBar;
begin
  FBar := TBarSeries.Create(Chart1);
  Chart1.AddSerie(FBar);
  FBar.Title := 'bars';
  FBar.SeriesColor := clRed;
end;

procedure TForm1.InitLine;
begin
  FLine := TSerie.Create(Chart1);
  FLine.ShowLines := true;
  FLine.ShowPoints := true;
  FLine.Pointer.Style := psRectangle;
  FLine.Title := 'line';
  FLine.SeriesColor := clRed;
  Chart1.AddSerie(FLine);
end;

procedure TForm1.InitPie;
begin
  FPie := TPieSeries.Create(Chart1);
  Chart1.AddSerie(FPie);
  FPie.Title := 'pie';
  FPie.SeriesColor := clRed;
  FPie.MarksStyle := smsLabelPercent;
end;

initialization
  {$I unit1.lrs}

end.

