program calleditorwithpkg;

{$mode objfpc}{$H+}

uses
  Interfaces, // this includes the LCL widgetset
  Forms,
  maincalleditor,
  lazreport, lr_add_function;

{$R calleditorwithpkg.res}

begin
  Application.Title:='LazReport Designer';
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.

