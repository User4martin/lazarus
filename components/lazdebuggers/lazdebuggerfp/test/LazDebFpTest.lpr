program LazDebFpTest;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  TestDbgControlForm,
  Interfaces, Forms, GuiTestRunner, TestVarious,  TestWatches, TestBase;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGuiTestRunner, TestRunner);
  Application.Run;
end.

