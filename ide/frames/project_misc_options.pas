unit project_misc_options;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls,
  ProjectIntf, IDEOptionsIntf,
  IDEProcs, Project, LazarusIDEStrConsts;

type

  { TProjectMiscOptionsFrame }

  TProjectMiscOptionsFrame = class(TAbstractIDEOptionsEditor)
    AlwaysBuildCheckBox: TCheckBox;
    Bevel1: TBevel;
    Bevel2: TBevel;
    LRSInOutputDirCheckBox: TCheckBox;
    MainUnitHasCreateFormStatementsCheckBox: TCheckBox;
    MainUnitHasTitleStatementCheckBox: TCheckBox;
    MainUnitHasUsesSectionForAllUnitsCheckBox: TCheckBox;
    MainUnitIsPascalSourceCheckBox: TCheckBox;
    PathDelimComboBox: TComboBox;
    PathDelimLabel: TLabel;
    ResourceGroupBox: TGroupBox;
    RunnableCheckBox: TCheckBox;
    UseDesignTimePkgsCheckBox: TCheckBox;
    UseFPCResourcesRadioButton: TRadioButton;
    UseLRSFilesRadioButton: TRadioButton;
  private
  public
    function GetTitle: string; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

{$R *.lfm}

{ TProjectMiscOptionsFrame }

function TProjectMiscOptionsFrame.GetTitle: string;
begin
  Result := dlgPOMisc;
end;

procedure TProjectMiscOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  MainUnitIsPascalSourceCheckBox.Caption := lisMainUnitIsPascalSource;
  MainUnitIsPascalSourceCheckBox.Hint := lisMainUnitIsPascalSourceHint;
  MainUnitHasUsesSectionForAllUnitsCheckBox.Caption := lisMainUnitHasUsesSectionContainingAllUnitsOfProject;
  MainUnitHasUsesSectionForAllUnitsCheckBox.Hint := lisNewUnitsAreAddedToUsesSections;
  MainUnitHasCreateFormStatementsCheckBox.Caption := lisMainUnitHasApplicationCreateFormStatements;
  MainUnitHasCreateFormStatementsCheckBox.Hint := lisUsedForAutoCreatedForms;
  MainUnitHasTitleStatementCheckBox.Caption := lisMainUnitHasApplicationTitleStatements;
  MainUnitHasTitleStatementCheckBox.Hint := lisIdeMaintainsTheTitleInMainUnit;
  RunnableCheckBox.Caption := lisProjectIsRunnable;
  RunnableCheckBox.Hint := lisProjectIsRunnableHint;
  UseDesignTimePkgsCheckBox.Caption := lisUseDesignTimePackages;
  UseDesignTimePkgsCheckBox.Hint := lisThisIsTestProjectForDesignTimePackage;
  AlwaysBuildCheckBox.Caption := lisProjOptsAlwaysBuildEvenIfNothingChanged;
  AlwaysBuildCheckBox.Hint := lisProjOptsAlwaysBuildHint;
  LRSInOutputDirCheckBox.Caption := lisPutLrsFilesInOutputDirectory;
  LRSInOutputDirCheckBox.Hint := lisPutLrsFilesInOutputDirectoryHint;
  ResourceGroupBox.Caption := lisResourceTypeOfNewFiles;
  UseLRSFilesRadioButton.Caption := lisLrsIncludeFiles;
  UseLRSFilesRadioButton.Hint := lisAutomaticallyConvertLfmToLrs;
  UseFPCResourcesRadioButton.Caption := lisFPCResources;
  UseFPCResourcesRadioButton.Hint := lisDelphiCompatibleResources;
  PathDelimLabel.Caption:=lisStorePathDelimitersAndAs;
  PathDelimComboBox.Items.Text:=lisDoNotChange+LineEnding
                               +lisChangeToUnix+LineEnding
                               +lisChangeToWindows;
end;

procedure TProjectMiscOptionsFrame.ReadSettings(AOptions: TAbstractIDEOptions);
begin
  with (AOptions as TProjectIDEOptions).Project do
  begin
    MainUnitIsPascalSourceCheckBox.Checked := (pfMainUnitIsPascalSource in Flags);
    MainUnitHasUsesSectionForAllUnitsCheckBox.Checked := (pfMainUnitHasUsesSectionForAllUnits in Flags);
    MainUnitHasCreateFormStatementsCheckBox.Checked := (pfMainUnitHasCreateFormStatements in Flags);
    MainUnitHasTitleStatementCheckBox.Checked := (pfMainUnitHasTitleStatement in Flags);
    RunnableCheckBox.Checked := (pfRunnable in Flags);
    UseDesignTimePkgsCheckBox.Checked := (pfUseDesignTimePackages in Flags);
    AlwaysBuildCheckBox.Checked := (pfAlwaysBuild in Flags);
    LRSInOutputDirCheckBox.Checked := (pfLRSFilesInOutputDirectory in Flags);
    case ProjResources.ResourceType of
      rtLRS: UseLRSFilesRadioButton.Checked := True;
      rtRes: UseFPCResourcesRadioButton.Checked := True;
    end;
    case StorePathDelim of
    pdsNone: PathDelimComboBox.ItemIndex:=0;
    pdsSystem: if PathDelim='/' then {%H-}PathDelimComboBox.ItemIndex:=1
                                else {%H-}PathDelimComboBox.ItemIndex:=2;
    pdsUnix: PathDelimComboBox.ItemIndex:=1;
    pdsWindows: PathDelimComboBox.ItemIndex:=2;
    end;
  end;
end;

procedure TProjectMiscOptionsFrame.WriteSettings(AOptions: TAbstractIDEOptions);
var
  Project: TProject;
  NewFlags: TProjectFlags;

  procedure SetProjectFlag(AFlag: TProjectFlag; AValue: Boolean);
  begin
    if AValue then
      Include(NewFlags, AFlag)
    else
      Exclude(NewFlags, AFlag);
  end;

begin
  Project := (AOptions as TProjectIDEOptions).Project;
  NewFlags := Project.Flags;
  SetProjectFlag(pfMainUnitIsPascalSource,
                 MainUnitIsPascalSourceCheckBox.Checked);
  SetProjectFlag(pfMainUnitHasUsesSectionForAllUnits,
                 MainUnitHasUsesSectionForAllUnitsCheckBox.Checked);
  SetProjectFlag(pfMainUnitHasCreateFormStatements,
                 MainUnitHasCreateFormStatementsCheckBox.Checked);
  SetProjectFlag(pfMainUnitHasTitleStatement,
                 MainUnitHasTitleStatementCheckBox.Checked);
  SetProjectFlag(pfRunnable, RunnableCheckBox.Checked);
  SetProjectFlag(pfUseDesignTimePackages, UseDesignTimePkgsCheckBox.Checked);
  SetProjectFlag(pfAlwaysBuild, AlwaysBuildCheckBox.Checked);
  SetProjectFlag(pfLRSFilesInOutputDirectory, LRSInOutputDirCheckBox.Checked);
  Project.Flags := NewFlags;
  if UseLRSFilesRadioButton.Checked then
    Project.ProjResources.ResourceType := rtLRS
  else
    Project.ProjResources.ResourceType := rtRes;
  case PathDelimComboBox.ItemIndex of
  0: Project.StorePathDelim:=pdsNone;
  1: Project.StorePathDelim:=pdsUnix;
  2: Project.StorePathDelim:=pdsWindows;
  end;
end;

class function TProjectMiscOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TProjectIDEOptions;
end;

initialization
  RegisterIDEOptionsEditor(GroupProject, TProjectMiscOptionsFrame, ProjectOptionsMisc);

end.

