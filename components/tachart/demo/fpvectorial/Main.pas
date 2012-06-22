// NOTE: This is very experimental code. Do not expect it to work!

unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, ExtCtrls, StdCtrls, SysUtils, FileUtil, Forms, Controls, Graphics,
  Dialogs, TAGraph, TASeries, TASources;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnSVG: TButton;
    btnGCode: TButton;
    Chart1: TChart;
    Chart1BarSeries1: TBarSeries;
    Chart1LineSeries1: TLineSeries;
    Panel1: TPanel;
    RandomChartSource1: TRandomChartSource;
    procedure btnGCodeClick(Sender: TObject);
    procedure btnSVGClick(Sender: TObject);
  end;

var
  Form1: TForm1; 

implementation

{$R *.lfm}

uses
  FPVectorial, SVGVectorialWriter, avisocncgcodewriter, TADrawerFPVectorial,
  TADrawUtils, TADrawerCanvas;

procedure SaveAs(AChart: TChart; AFormat: TvVectorialFormat);
const
  ext: array [TvVectorialFormat] of String = (
    'pdf', 'svg', 'cdr', 'wmf', 'dxf', 'laf', 'laz', 'ps', 'eps',
    'gcode5', 'gcode6', 'mathml', 'raw');
var
  d: TvVectorialDocument;
  v: IChartDrawer;
begin
  d := TvVectorialDocument.Create;
  d.AddPage;
  d.Width := AChart.Width;
  d.Height := AChart.Height;
  v := TFPVectorialDrawer.Create(d.GetCurrentPage);
  v.DoChartColorToFPColor := @ChartColorSysToFPColor;
  with AChart do
    Draw(v, Rect(0, 100, Width, Height + 100));
  d.WriteToFile('test.' + ext[AFormat], AFormat);
end;

{ TForm1 }

procedure TForm1.btnGCodeClick(Sender: TObject);
begin
  SaveAs(Chart1, vfGCodeAvisoCNCPrototipoV5);
end;

procedure TForm1.btnSVGClick(Sender: TObject);
begin
  SaveAs(Chart1, vfSVG);
end;

end.

