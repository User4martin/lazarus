unit Main;

{$mode objfpc}{$H+}

interface

uses
  ComCtrls, ExtCtrls, StdCtrls, SysUtils, Forms, TAGraph, TASeries, TASources,
  TANavigation, TATools, Classes;

type

  { TForm1 }

  TForm1 = class(TForm)
    Chart1: TChart;
    Chart1BarSeries1: TBarSeries;
    Chart1LineSeries1: TLineSeries;
    ChartNavPanel1: TChartNavPanel;
    ChartToolset1: TChartToolset;
    ChartToolset1PanDragTool1: TPanDragTool;
    ChartToolset1ZoomDragTool1: TZoomDragTool;
    cbMiniMap: TCheckBox;
    Panel1: TPanel;
    RandomChartSource1: TRandomChartSource;
    sbChartHor: TChartNavScrollBar;
    sbChartVert: TChartNavScrollBar;
    StaticText1: TStaticText;
    StatusBar1: TStatusBar;
    procedure cbMiniMapChange(Sender: TObject);
    procedure Chart1ExtentChanged(ASender: TChart);
    procedure FormCreate(Sender: TObject);
  end;

var
  Form1: TForm1; 

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.cbMiniMapChange(Sender: TObject);
begin
  ChartNavPanel1.MiniMap := cbMiniMap.Checked;
end;

procedure TForm1.Chart1ExtentChanged(ASender: TChart);
begin
  with ASender.LogicalExtent do
    StatusBar1.Panels[0].Text :=
      Format('(%.3g;%.3g) - (%.3g;%.3g)', [a.X, a.Y, b.X, b.Y]);
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  for i := 1 to 10 do
    Chart1BarSeries1.AddXY(i * 10, i * i / 5);
end;

end.

