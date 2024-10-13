unit Test_AnchorDock;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, AnchorDocking, fpcunit, testutils, testregistry;

type

  TTestAnchorDock = class(TTestCase)
  published
    procedure TestHookUp;
  end;

implementation

procedure TTestAnchorDock.TestHookUp;
var
  FForm, FForm2, FForm1: TForm;
begin
  FForm := TForm.CreateNew(nil);
  FForm.Name := 'form';

  FForm1 := TForm.CreateNew(nil);
  FForm1.Name := 'abc';
  FForm2 := TForm.CreateNew(nil);
  FForm2.Name := 'def';

  DockMaster.MakeDockSite(FForm,[akTop, akLeft, akRight, akBottom],admrpChild);

  DockMaster.MakeDockable(FForm1);
  DockMaster.MakeDockable(FForm2);


  DockMaster.ManualDock(TAnchorDockHostSite(FForm1.Parent), FForm , alTop);

end;



initialization

  RegisterTest(TTestAnchorDock);
end.

