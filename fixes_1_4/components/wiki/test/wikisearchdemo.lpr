program WikiSearchDemo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, WikiSearchMain, WikiHelpManager, WikiSearchOptions
  { you can add units after this };

{$R *.res}

begin
  Application.Title:='project1';
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TWikiSearchDemoForm, WikiSearchDemoForm);
  Application.Run;
end.

