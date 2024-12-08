{
   File generated automatically by Lazarus Package Manager

   fpmake.pp for IdeProjectDsgn 0.0

   This file was generated on 08/12/2024
}

{$ifndef ALLPACKAGES} 
{$mode objfpc}{$H+}
program fpmake;

uses fpmkunit;
{$endif ALLPACKAGES}

procedure add_IdeProjectDsgn(const ADirectory: string);

var
  P : TPackage;
  T : TTarget;
  D : TDependency;

begin
  with Installer do
    begin
    P:=AddPackage('ideprojectdsgn');
    P.Version:='<none>';

    P.Directory:=ADirectory;

    P.Author:='Lazarus Team';
    P.License:='GPLv2';
    P.Description:='-- This package is part of the IDE --'#13#10'This package does not guarantee any particular interface/API. Files are maintained for the use by the IDE.'#13#10''#13#10'Files in this package provide GUI elements for Project and Package handling.';

    P.Flags.Add('LazarusDsgnPkg');

    D := P.Dependencies.Add('ideproject');
    D := P.Dependencies.Add('ideintf');
    D := P.Dependencies.Add('lcl');
    D := P.Dependencies.Add('fcl');
    P.Options.Add('-MObjFPC');
    P.Options.Add('-Scghi');
    P.Options.Add('-O1');
    P.Options.Add('-g');
    P.Options.Add('-gl');
    P.Options.Add('-l');
    P.Options.Add('-vewnhibq');
    P.Options.Add('-dLCL');
    P.Options.Add('-dLCL$(LCLWidgetType)');
    P.UnitPath.Add('.');
    T:=P.Targets.AddUnit('ideprojectdsgn.pas');
    t.Dependencies.AddUnit('lazprojpackworkspaceoptionsdsgn');
    t.Dependencies.AddUnit('project_workspace_options');

    T:=P.Targets.AddUnit('lazprojpackworkspaceoptionsdsgn.pas');
    T:=P.Targets.AddUnit('project_workspace_options.pas');

    // copy the compiled file, so the IDE knows how the package was compiled
    P.Sources.AddSrc('ideprojectdsgn.compiled');
    P.InstallFiles.Add('ideprojectdsgn.compiled',AllOSes,'$(unitinstalldir)');

    end;
end;

{$ifndef ALLPACKAGES}
begin
  add_IdeProjectDsgn('');
  Installer.Run;
end.
{$endif ALLPACKAGES}
