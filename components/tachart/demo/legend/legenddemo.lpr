program legenddemo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, main, TAChartLazarusPkg
  { you can add units after this };

{$IFDEF WINDOWS}{$R legenddemo.rc}{$ENDIF}

begin
  Application.Title := 'TAChart legend demo';
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

