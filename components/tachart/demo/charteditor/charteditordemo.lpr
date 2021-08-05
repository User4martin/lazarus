program ChartEditorDemo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, ceMain, ceSeriesDlg, cePointerFrame, ceTitleFootFrame, ceAxisFrame,
  ceSeriesFrame, ceChartEditor, ceImages, ceSimplePenFrame, ceSimpleBrushFrame,
  ceMarksForm, ceArrowFrame;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TChartImagesDM, ChartImagesDM);
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TMarksForm, MarksForm);
  Application.Run;
end.

