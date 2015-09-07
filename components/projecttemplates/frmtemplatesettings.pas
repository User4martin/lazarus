unit frmtemplatesettings; 

{$mode objfpc}{$H+}

interface

uses
  Forms, StdCtrls, EditBtn, ButtonPanel, ProjectTemplates;

type

  { TTemplateSettingsForm }

  TTemplateSettingsForm = class(TForm)
    ButtonPanel1: TButtonPanel;
    DETemplates: TDirectoryEdit;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
  private
    FTemplates : TProjectTemplates;
    procedure SetTemplates(const AValue: TProjectTemplates);
  public
    Property Templates : TProjectTemplates Read FTemplates Write SetTemplates;
  end;

var
  TemplateSettingsForm: TTemplateSettingsForm;

implementation

resourcestring
  STitle = 'Project templates settings';
  SDirect= '&Directory with templates:';

{$R *.lfm}

{ TTemplateSettingsForm }

procedure TTemplateSettingsForm.FormCreate(Sender: TObject);
begin
  Caption := STitle;
  Label1.Caption := SDirect;
  ButtonPanel1.OKButton.Caption:=SbtnOK;
  ButtonPanel1.CancelButton.Caption:=SbtnCancel;
end;

procedure TTemplateSettingsForm.OKButtonClick(Sender: TObject);
begin
  if (Templates.TemplateDir<>DETemplates.Directory) then
    FTemplates.Initialize(DETemplates.Directory);
end;

procedure TTemplateSettingsForm.SetTemplates(const AValue: TProjectTemplates);
begin
  FTemplates:=AValue;
  DEtemplates.Directory:=Ftemplates.TemplateDir;
end;

end.

