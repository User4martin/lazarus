unit ProjectForPackage;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  // BuildIntf
  ProjectIntf, Forms,
  // IdeProject
  Project;

type

  { TIdePackageProjectBackend }

  TIdePackageProjectBackend = class(TLazProjectBackend)
  private
    FProject: TProject;
  public
    class function Caption: string; override;
    class function FileExtension: string; override;
    class function FileFilter: string; override;
  public
    constructor Create(AProject: TLazProject); override;
    function ReadProject(const NewProjectInfoFile: string;
                         LoadAllOptions: Boolean = True): TModalResult; override;
    function WriteProject(const OverrideProjectInfoFile: string;
                          ProjectWriteFlags: TProjectWriteFlags): TModalResult; override;
  end;

implementation

{ TIdePackageProjectBackend }

class function TIdePackageProjectBackend.Caption: string;
begin
  Result := 'Package';
end;

class function TIdePackageProjectBackend.FileExtension: string;
begin
  Result := 'lpk';
end;

class function TIdePackageProjectBackend.FileFilter: string;
begin
  Result := 'Package as project (*.lpk)|*.lpk';
end;

constructor TIdePackageProjectBackend.Create(AProject: TLazProject);
begin
  FProject := AProject as TProject;
  inherited Create(AProject);
end;

function TIdePackageProjectBackend.ReadProject(const NewProjectInfoFile: string;
  LoadAllOptions: Boolean): TModalResult;
begin
  //
end;

function TIdePackageProjectBackend.WriteProject(const OverrideProjectInfoFile: string;
  ProjectWriteFlags: TProjectWriteFlags): TModalResult;
begin
  //
end;

initialization
  RegisterProjectBackendClass(TIdePackageProjectBackend);

end.

