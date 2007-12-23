{ Copyright (C) 2004

 *****************************************************************************
 *                                                                           *
 *  See the file COPYING.modifiedLGPL, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************


  implementing ActionList Editor

  authors:
     Radek Cervinka, radek.cervinka@centrum.cz
     Mattias Gaertner
     Pawel Piwowar, alfapawel@tlen.pl

  version:
    0.1 - 26-27.2.2004 - write all from scratch
    0.2 -  3.3.2004 - speed up filling listboxes
                      some ergonomic fixes (like stay in category after ADD)
                      fixed possible language problems
    0.3 - 27.3.2004 - rename action > actualise editor
    0.4 - 29.3.2004 - dblclick generate xxx.OnExecute code to editor
    0.5 - 10.03.2005 - New design
    0.6 - 14.03.2005 - multilanguage support

  TODO:- multiselect for the actions and categories
       - drag & drop for the actions and categories
       - standard icon for "Standard Action"
       - sometimes click in listbox causes selecting last item
         (it's an strange gtk error. The LCL and the gtk intf do not send any
          change to the gtk. Either it is a bug in the gtk1 or we are doing
          something wrong in the handlers.)
}
unit actionseditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, LCLProc, Forms, Controls, Dialogs,
  ActnList, ExtCtrls, ComCtrls, Buttons, StdCtrls, ObjInspStrConsts,
  ComponentEditors, PropEdits, DBActns, StdActns, LCLIntf, LCLType,
  Graphics, Menus, actionseditorstd;

type

  TActionListComponentEditor = class;
  
  { TActionListEditor }

  TActionListEditor = class(TForm)
    ActDelete: TAction;
    ActPanelToolBar: TAction;
    ActPanelDescr: TAction;
    ActMoveUp: TAction;
    ActMoveDown: TAction;
    ActNewStd: TAction;
    ActionListSelf: TActionList;
    ActNew: TAction;
    lblCategory: TLabel;
    lblName: TLabel;
    lstCategory: TListBox;
    lstActionName: TListBox;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    mItemActListPanelDescr: TMenuItem;
    mItemToolBarNewStdAction: TMenuItem;
    mItemToolBarNewAction: TMenuItem;
    mItemActListNewAction: TMenuItem;
    mItemActListNewStdAction: TMenuItem;
    mItemActListMoveUpAction: TMenuItem;
    mItemActListMoveDownAction: TMenuItem;
    MenuItem6: TMenuItem;
    mItemActListDelAction: TMenuItem;
    MenuItem8: TMenuItem;
    PanelToolbar: TPanel;
    PanelDescr: TPanel;
    btnAdd: TSpeedButton;
    btnDelete: TSpeedButton;
    btnUp: TSpeedButton;
    btnDown: TSpeedButton;
    PopMenuActions: TPopupMenu;
    PopMenuToolBarActions: TPopupMenu;
    SBShowMenuNewActions: TSpeedButton;
    Splitter: TSplitter;
    procedure ActDeleteExecute(Sender: TObject);
    procedure ActDeleteUpdate(Sender: TObject);
    procedure ActMoveDownExecute(Sender: TObject);
    procedure ActMoveDownUpdate(Sender: TObject);
    procedure ActMoveUpUpdate(Sender: TObject);
    procedure ActNewExecute(Sender: TObject);
    procedure ActNewStdExecute(Sender: TObject);
    procedure ActPanelDescrExecute(Sender: TObject);
    procedure ActPanelToolBarExecute(Sender: TObject);
    procedure ActionListEditorClose(Sender: TObject;
      var CloseAction: TCloseAction);
    procedure ActionListEditorKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ActionListEditorKeyPress(Sender: TObject; var Key: char);
    procedure SBShowMenuNewActionsClick(Sender: TObject);
    procedure SplitterCanResize(Sender: TObject; var NewSize: Integer;
      var Accept: Boolean);
    procedure lstActionNameKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure lstActionNameMouseDown(Sender: TOBject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure lstCategoryClick(Sender: TObject);
    procedure lstActionNameClick(Sender: TObject);
    procedure lstActionNameDblClick(Sender: TObject);
  protected
    procedure OnComponentRenamed(AComponent: TComponent);
    procedure OnComponentSelection(const OnSetSelection: TPersistentSelectionList);
    procedure OnRefreshPropertyValues;
    function GetSelectedAction: TContainedAction;
  private
    { private declarations }
    FActionList: TActionList;
    FDesigner: TComponentEditorDesigner;
    FComponentEditor: TActionListComponentEditor;
    procedure ResultStdActProc(const Category: string; ActionClass: TBasicActionClass; ActionProperty: TActStdPropItem; LastItem: Boolean);
  public
    { public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetActionList(AActionList: TActionList);
    procedure FillCategories;
    procedure FillActionByCategory(iIndex: Integer);
    property Designer:TComponentEditorDesigner read FDesigner write FDesigner;
    property ComponentEditor: TActionListComponentEditor write FComponentEditor;
  end; 

  { TActionListComponentEditor }

  TActionListComponentEditor = class(TComponentEditor)
  private
    FActionList: TActionList;
    FDesigner: TComponentEditorDesigner;
    FActionListEditorForm: TActionListEditor;
    fWindowClosed: Boolean;
  protected
  public
    constructor Create(AComponent: TComponent;
                       ADesigner: TComponentEditorDesigner); override;
    destructor Destroy; override;
    procedure Edit; override;
    property ActionList: TActionList read FActionList write FActionList;
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
    procedure EditorWindowClose;
  end;

  { Action Registration }

  TRegisteredAction = class
  private
    FActionClass: TBasicActionClass;
    FGroupId: Integer;
  public
    constructor Create(TheActionClass: TBasicActionClass; TheGroupID: integer);
    property ActionClass: TBasicActionClass read FActionClass;
    property GroupId: Integer read FGroupId;
  end;
  PRegisteredAction = ^TRegisteredAction;
  
  TRegisteredActionCategory = class
  private
    FCount: integer;
    FName: string;
    FItems: PRegisteredAction;
    FResource: TComponentClass;
    function GetItems(Index: integer): TRegisteredAction;
  public
    constructor Create(const CategoryName: string; AResource: TComponentClass);
    procedure Add(const AClasses: array of TBasicActionClass);
    destructor Destroy; override;
    function IndexOfClass(AClass: TBasicActionClass): Integer;
    procedure EnumActions(Proc: TEnumActionProc; Info: Pointer);
    property Count: integer read FCount;
    property Name: string read FName;
    property Items[Index: integer]: TRegisteredAction read GetItems;
    property Resource: TComponentClass read FResource;
  end;

  TRegisteredActionCategories = class
  private
    FItems: TList;
    function GetItems(Index: Integer): TRegisteredActionCategory;
  public
    procedure Add(const CategoryName: String;
                  const AClasses: array of TBasicActionClass;
                  AResource: TComponentClass);
    destructor Destroy; override;
    function IndexOfCategory(const CategoryName: String): integer;
    procedure EnumActions(Proc: TEnumActionProc; Info: Pointer);
    function FindResource(AClass: TBasicActionClass): TComponentClass;
    function Count: Integer;
    property Items[Index: Integer]: TRegisteredActionCategory read GetItems;
  end;

  TNotifyActionListChange = procedure;
  
var
  RegisteredActions: TRegisteredActionCategories;
  NotifyActionListChange: TNotifyActionListChange;

procedure RegisterActions(const ACategory: string;
                          const AClasses: array of TBasicActionClass;
                          AResource: TComponentClass);
procedure UnRegisterActions(const Classes: array of TBasicActionClass);
procedure EnumActions(Proc: TEnumActionProc; Info: Pointer);
function CreateAction(TheOwner: TComponent;
                      ActionClass: TBasicActionClass): TBasicAction;

implementation

procedure RegisterActions(const ACategory: string;
  const AClasses: array of TBasicActionClass; AResource: TComponentClass);
begin
  RegisteredActions.Add(ACategory,AClasses,AResource);
end;

procedure UnRegisterActions(const Classes: array of TBasicActionClass);
begin

end;

procedure EnumActions(Proc: TEnumActionProc; Info: Pointer);
begin
  RegisteredActions.EnumActions(Proc,Info);
end;

function CreateAction(TheOwner: TComponent;
  ActionClass: TBasicActionClass): TBasicAction;
var
  ResourceClass: TComponentClass;
  ResInstance: TComponent;
  i: Integer;
  Component: TComponent;
  Action: TBasicAction;
  Src: TCustomAction;
  Dest: TCustomAction;
begin
  Result := ActionClass.Create(TheOwner);
  // find a Resource component registered for this ActionClass
  ResourceClass := RegisteredActions.FindResource(ActionClass);
  if ResourceClass = nil then Exit;
  ResInstance := ResourceClass.Create(nil);
  try
    // find an action owned by the Resource component
    Action:=nil;
    for i:= 0 to ResInstance.ComponentCount-1 do begin
      Component := ResInstance.Components[i];
      if (CompareText(Component.ClassName, ActionClass.ClassName)=0)
         and (Component is TBasicAction) then begin
        Action := TBasicAction(Component);
        Break;
      end;
    end;
    if Action = nil then Exit;

    // copy TCustomAction properties
    if (Action is TCustomAction) and (Result is TCustomAction) then begin
      Src := TCustomAction(Action);
      Dest := TCustomAction(Result);
      Dest.AutoCheck := Src.AutoCheck;
      Dest.Caption:=Src.Caption;
      Dest.Category := Src.Category;
      Dest.Checked:=Src.Checked;
      Dest.Enabled:=Src.Enabled;
      Dest.HelpContext:=Src.HelpContext;
      Dest.HelpKeyword := Src.HelpKeyword;
      Dest.HelpType := Src.HelpType;
      Dest.Hint:=Src.Hint;
      Dest.ImageIndex:=Src.ImageIndex;
      Dest.SecondaryShortCuts := Src.SecondaryShortCuts;
      Dest.ShortCut:=Src.ShortCut;
      Dest.Visible:=Src.Visible;
//      Src.AssignTo(Dest);
      if (Dest is TContainedAction) and (Dest.ImageIndex>=0)
      and (Src is TContainedAction) then begin
        // ToDo: copy image

      end;
    end;
  finally
    ResInstance.Free;
  end;
end;

{ TActionListEditor }

procedure TActionListEditor.OnComponentRenamed(AComponent: TComponent);
begin
  if (not Self.Visible) or (not Assigned(FActionList.ActionByName(AComponent.Name)))
  then Exit;
  lstActionName.Items[lstActionName.ItemIndex] := AComponent.Name;
end;

procedure TActionListEditor.OnComponentSelection(const OnSetSelection: TPersistentSelectionList);
var
  CurSelect: TContainedAction;
  tmpCategory: String;
  function CategoryIndexOf(Name: String): Integer;
  var
    i: Integer;
  begin
    for i:= lstCategory.Items.Count-1 downto 0 do begin
      if lstCategory.Items[i] = Name
      then Break;
    end;
    Result := i;
    if (i = lstCategory.Items.IndexOf(cActionListEditorUnknownCategory))
       and (i = lstCategory.Items.IndexOf(cActionListEditorAllCategory))
    then Result := 0;
  end;
begin
  // TODO: multiselect
  if Self.Visible
     and Assigned(OnSetSelection)
     and (OnSetSelection.Count > 0)
     and (OnSetSelection.Items[0] is TContainedAction)
     and (TContainedAction(OnSetSelection.Items[0]).ActionList = FActionList) then
    begin
      if GetSelectedAction = OnSetSelection.Items[0]
      then Exit;
      CurSelect := TContainedAction(OnSetSelection.Items[0]);
      CurSelect.Category := Trim(CurSelect.Category);
      tmpCategory := CurSelect.Category;
      if (tmpCategory <> '')
         and (lstCategory.Items.IndexOf(tmpCategory) < 0)
      then FillCategories;
      if tmpCategory = ''
      then tmpCategory := cActionListEditorUnknownCategory;
      if (lstCategory.Items[lstCategory.ItemIndex] <> tmpCategory)
         or ((lstCategory.Items[lstCategory.ItemIndex] = tmpCategory)
              and (lstActionName.Items.IndexOf(CurSelect.Name) < 0)) then begin
        if CurSelect.Category = ''
        then lstCategory.ItemIndex := lstCategory.Items.IndexOf(tmpCategory)
        else lstCategory.ItemIndex := CategoryIndexOf(CurSelect.Category);
        lstCategory.Click;
      end;
      lstActionName.ItemIndex := lstActionName.Items.IndexOf(CurSelect.Name);
      lstActionName.Click;
    end
  else lstActionName.ItemIndex := -1;
end;

procedure TActionListEditor.OnRefreshPropertyValues;
  function ValidCategory: Boolean;
  // spr. czy wszystkie kategorie w ListBox'sie istniej� w TActionList
  // inaczej: czy istnieje kategoria elementu wywoluj�cego zdarzenie
  var
    i, j: Integer;
    bool: Boolean;
  begin
    Result := True;
    for i:= lstCategory.Items.Count-1 downto 0 do begin
      if (lstCategory.Items[i] = cActionListEditorUnknownCategory)
         and (i = lstCategory.Items.IndexOf(cActionListEditorAllCategory))
      then Break;
      bool := False;
      for j:= FActionList.ActionCount-1 downto 0 do begin
        if TContainedAction(FActionList.Actions[j]).Category = lstCategory.Items[i] then begin
          bool := True;
          Break;
        end;
      end;
      if not bool then begin
        Result := False;
        Break;
      end;
    end;  // for i
  end;
  function IsCategory(Category: String): Boolean;
  var
    i: Integer;
  begin
    Result := False;
    for i:= lstCategory.Items.Count-1 downto 0 do begin
      if lstCategory.Items[i] = Category then begin
        Result := True;
        Break;
      end;
    end;
    if (i >= 0)
       and ((i = lstCategory.Items.IndexOf(cActionListEditorUnknownCategory))
            or (i = lstCategory.Items.IndexOf(cActionListEditorAllCategory)))
    then Result := False;
  end;
var
  ASelections: TPersistentSelectionList;
  curSelect: TContainedAction;
  oldSelCategory, tmpCategory: String;
  tmpIndex: Integer;
  tmpValidCategory, tmpIsActCategory: Boolean;
begin
  if Self.Visible then begin
    ASelections:= TPersistentSelectionList.Create;
    GlobalDesignHook.GetSelection(ASelections);
    try
      if (ASelections.Count > 0)
         and (ASelections.Items[0] is TContainedAction)
         and (TContainedAction(ASelections.Items[0]).ActionList = FActionList) then begin
        curSelect := TContainedAction(ASelections.Items[0]);
        CurSelect.Category := Trim(CurSelect.Category);
        oldSelCategory := lstCategory.Items[lstCategory.ItemIndex];
        tmpCategory := CurSelect.Category;
        
        tmpValidCategory := ValidCategory;
        tmpIsActCategory := IsCategory(CurSelect.Category);
        
        if tmpCategory = '' then tmpCategory := cActionListEditorUnknownCategory;
           // je�eli nie ma tej kategorii na liscie
        if ((curSelect.Category <> '') and not tmpIsActCategory)
           // nie wszystkie kategorie z lstCategory istniej� w FActionList
           // (usuniecie kategorii)
           or not tmpValidCategory
           // je�eli kategoria jest inna od oznaczonej
           // oraz nie jest to kategoria '(All)' ani '(Unknown)'
           or ((tmpCategory <> lstCategory.Items[lstCategory.Items.IndexOf(tmpCategory)])
               and ((lstCategory.Items.IndexOf(cActionListEditorAllCategory) >= 0)
                      and (tmpCategory <> lstCategory.Items[lstCategory.Items.IndexOf(cActionListEditorAllCategory)]))
               and (tmpCategory <> lstCategory.Items[lstCategory.Items.IndexOf(cActionListEditorUnknownCategory)]))
        then FillCategories;

        tmpIndex := lstCategory.Items.IndexOf(tmpCategory);  // ???
        // s� kategorie (nie tylko Unknown) rownie� All i inne
        if (lstCategory.Items.Count > 1)
                  // nie istniala nowa kategoria
                  // nie istniala zaznaczona kategoria
           and ( ((not tmpIsActCategory) and (not tmpValidCategory))
                  // istniej zaznaczona kategoria
                  // nie istniala nowa kategoria
                 or ((lstCategory.Items.IndexOf(oldSelCategory) >=0) and (not tmpIsActCategory))
                  // nie istnieje zaznaczona kategoria
                  // istniej nowa kategoria
                 or ((lstCategory.Items.IndexOf(oldSelCategory) = -1) and (tmpIndex >= 0))
                  // istnieje zaznaczona kategoria
                  // istnieje nowa kategoria
                 or ((lstCategory.Items.IndexOf(oldSelCategory) >= 0) and (tmpIndex >= 0)) )
           // oraz poprzednio zaznaczona kategoria to nie (All)
           and (oldSelCategory <> cActionListEditorAllCategory) then begin
          lstCategory.ItemIndex := tmpIndex;
          lstCategory.Click;
        end;
        tmpIndex := lstActionName.items.IndexOf(CurSelect.Name);
        if lstActionName.ItemIndex <> tmpIndex then begin
          lstActionName.ItemIndex := tmpIndex;
          lstActionName.Click;
        end;
      end;
    finally
      ASelections.Free;
    end;
  end;
end;

function TActionListEditor.GetSelectedAction: TContainedAction;
begin
  if lstActionName.ItemIndex >= 0
  then Result := FActionList.ActionByName(lstActionName.Items[lstActionName.ItemIndex])
  else Result := nil;
end;

procedure TActionListEditor.ResultStdActProc(const Category: string;
  ActionClass: TBasicActionClass; ActionProperty: TActStdPropItem;
  LastItem: Boolean);
var
  NewAction: TContainedAction;
begin
  NewAction := ActionClass.Create(FActionList.Owner) as TContainedAction;
//  NewAction := CreateAction(FActionList.Owner, ActionClass) as TContainedAction;
  if Category <> cActionListEditorUnknownCategory
  then NewAction.Category := Category
  else NewAction.Category := '';
  NewAction.Name := FDesigner.CreateUniqueComponentName(NewAction.ClassName);
  
  if Assigned(ActionProperty) then begin
    TCustomAction(NewAction).Caption := ActionProperty.ActionProperty.Caption;
    TCustomAction(NewAction).ShortCut := ActionProperty.ActionProperty.ShortCut;
    TCustomAction(NewAction).Hint := ActionProperty.ActionProperty.Hint;
  end;

  NewAction.ActionList := FActionList;
  FDesigner.PropertyEditorHook.PersistentAdded(NewAction,True);

  FDesigner.Modified;
  if LastItem
  then FDesigner.SelectOnlyThisComponent(FActionList.ActionByName(NewAction.Name));
end;

procedure TActionListEditor.SplitterCanResize(Sender: TObject;
  var NewSize: Integer; var Accept: Boolean);
begin
  lblName.Left := lstActionName.Left + 3;
end;

procedure TActionListEditor.lstActionNameKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if (ssCtrl in Shift) then begin
     case key of
       VK_UP: if ActMoveUp.Enabled then begin
           ActMoveUp.OnExecute(ActMoveUp);
           Key := 0;
         end;
         
       VK_DOWN: if ActMoveDown.Enabled then begin
           ActMoveDown.OnExecute(ActMoveDown);
           Key := 0;
         end;
      end;
  end;
end;

procedure TActionListEditor.lstActionNameMouseDown(Sender: TOBject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  oldIndex, index: Integer;
begin
  if Button = mbRight then begin
    oldIndex := TListBox(Sender).ItemIndex;
    index := TListBox(Sender).GetIndexAtY(Y);
    if (index >= 0) and (oldIndex <> index) then begin
      TListBox(Sender).ItemIndex := index;
      TListBox(Sender).Click;
    end;
  end;
end;

procedure TActionListEditor.ActDeleteUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := lstActionName.SelCount > 0;
end;

procedure TActionListEditor.ActMoveDownExecute(Sender: TObject);
var
  fact0,fAct1: TContainedAction;
  lboxIndex: Integer;
  direction: Integer;
begin
  if TComponent(Sender).Name = 'ActMoveUp'
  then direction := -1
  else direction := 1;

  lboxIndex := lstActionName.ItemIndex;
  
  fact0 := FActionList.ActionByName(lstActionName.Items[lboxIndex]);
  fact1 := FActionList.ActionByName(lstActionName.Items[lboxIndex+direction]);
  fact1.Index := fact0.Index;

  lstActionName.Items.Move(lboxIndex, lboxIndex+direction);
  lstActionName.ItemIndex := lboxIndex+direction;
  FDesigner.Modified;
end;

procedure TActionListEditor.ActMoveDownUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := (lstActionName.Items.Count > 1)
                         and (lstActionName.ItemIndex >= 0)
                         and (lstActionName.ItemIndex < lstActionName.Items.Count-1);
end;

procedure TActionListEditor.ActMoveUpUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := (lstActionName.Items.Count > 1)
                         and (lstActionName.ItemIndex > 0);
end;

procedure TActionListEditor.ActNewExecute(Sender: TObject);
var
  NewAction: TContainedAction;
begin
  NewAction := TAction.Create(FActionList.Owner);
  NewAction.Name := FDesigner.CreateUniqueComponentName(NewAction.ClassName);

  if lstCategory.ItemIndex > 1 // ignore first two items (virtual categories)
  then NewAction.Category := lstCategory.Items[lstCategory.ItemIndex]
  else NewAction.Category := '';

  NewAction.ActionList := FActionList;

  FDesigner.PropertyEditorHook.PersistentAdded(NewAction,True);
  FDesigner.Modified;
end;

procedure TActionListEditor.ActNewStdExecute(Sender: TObject);
begin
  TFormActStandard.CreateEx(Self, @ResultStdActProc).ShowModal;
end;

procedure TActionListEditor.ActPanelDescrExecute(Sender: TObject);
begin
  PanelDescr.Visible := TAction(Sender).Checked;
end;

procedure TActionListEditor.ActPanelToolBarExecute(Sender: TObject);
begin
  PanelToolBar.Visible := TAction(Sender).Checked;
end;

procedure TActionListEditor.ActionListEditorClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;

procedure TActionListEditor.ActionListEditorKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
var
  MousePoint: TPoint;
begin
  MousePoint := Self.ClientToScreen(Point(0,0));
  if Key = VK_APPS
  then PopMenuActions.PopUp(MousePoint.X, MousePoint.Y);
end;

procedure TActionListEditor.ActionListEditorKeyPress(Sender: TObject;
  var Key: char);
begin
  if Ord(Key) = VK_ESCAPE then Self.Close;
end;

procedure TActionListEditor.SBShowMenuNewActionsClick(Sender: TObject);
var
  MousePoint: TPoint;
begin
  MousePoint := SBShowMenuNewActions.ClientToScreen(Point(0, btnAdd.Height-1));
  PopMenuToolBarActions.PopUp(MousePoint.X-btnAdd.Width, MousePoint.Y);
  SBShowMenuNewActions.Down := False;
end;

procedure TActionListEditor.ActDeleteExecute(Sender: TObject);
  function IsCategory(Category: String): Boolean;
  var
    i: Integer;
  begin
    Result := False;
    for i:= FActionList.ActionCount-1 downto 0 do begin
      if FActionList.Actions[i].Category = Category then begin
        Result := True;
        Break;
      end;
    end;
  end;
var
  iNameIndex: Integer;
  OldName: String;
  OldAction: TContainedAction;
  OldIndex: LongInt;
begin
  iNameIndex := lstActionName.ItemIndex;
  if iNameIndex < 0 then Exit;
  OldName := lstActionName.Items[iNameIndex];
  lstActionName.Items.Delete(iNameIndex);

  OldAction := FActionList.ActionByName(OldName);
  OldName := OldAction.Category;

  // be gone
  if Assigned(OldAction) then
  begin
    try
      FDesigner.PropertyEditorHook.DeletePersistent(OldAction);
      OldAction:=nil;
    except
      on E: Exception do begin
        MessageDlg('Error deleting action',
          'Error while deleting action:'#13
          +E.Message,mtError,[mbOk],0);
      end;
    end;
  end;

  if lstActionName.Items.Count = 0 then // last act in category > rebuild
    FillCategories
  else
  begin
    if iNameIndex >= lstActionName.Items.Count
    then lstActionName.ItemIndex := lstActionName.Items.Count -1
    else lstActionName.ItemIndex := iNameIndex;

    FDesigner.SelectOnlyThisComponent(
       FActionList.ActionByName(lstActionName.Items[lstActionName.ItemIndex]));
  end;

  If not IsCategory(OldName) then begin
    OldIndex:=lstCategory.Items.IndexOf(OldName);
    if OldIndex>=0 then
      lstCategory.Items.Delete(OldIndex);
  end;
  if lstActionName.ItemIndex < 0
  then FDesigner.SelectOnlyThisComponent(FActionList);
end;

procedure TActionListEditor.lstCategoryClick(Sender: TObject);
begin
  if lstCategory.ItemIndex >= 0
  then FillActionByCategory(lstCategory.ItemIndex);
end;

procedure TActionListEditor.lstActionNameClick(Sender: TObject);
var
  CurAction: TContainedAction;
begin
  // TODO: multiselect
  if lstActionName.ItemIndex < 0 then Exit;
  CurAction := GetSelectedAction;
  if CurAction = nil then Exit;

  FDesigner.SelectOnlyThisComponent(CurAction);
end;

procedure TActionListEditor.lstActionNameDblClick(Sender: TObject);
var
  CurAction: TContainedAction;
begin
  if lstActionName.GetIndexAtY(lstActionName.ScreenToClient(Mouse.CursorPos).Y) < 0
  then Exit;
  CurAction := GetSelectedAction;
  if CurAction = nil then Exit;
  // Add OnExecute for this action
  CreateComponentEvent(CurAction,'OnExecute');
end;

constructor TActionListEditor.Create(AOwner: TComponent);
var
  bmp: TBitMap;
begin
  inherited Create(AOwner);
  Caption := oisActionListEditor;
  lblCategory.Caption := oisCategory;
  lblName.Caption := oisAction;
  Splitter.MinSize := lblCategory.Left + lblCategory.Width;
  ActNew.Hint := cActionListEditorNewAction;
  ActNewStd.Hint := cActionListEditorNewStdAction;
  ActDelete.Hint := cActionListEditorDeleteActionHint;
  ActMoveUp.Hint := cActionListEditorMoveUpAction;
  ActMoveDown.Hint := cActionListEditorMoveDownAction;
  ActPanelDescr.Caption := cActionListEditorPanelDescrriptions;
  ActPanelToolBar.Caption := cActionListEditorPanelToolBar;
  SBShowMenuNewActions.Hint := cActionListEditorNewAction;
  mItemToolBarNewAction.Caption := cActionListEditorNewAction;
  mItemToolBarNewStdAction.Caption := cActionListEditorNewStdAction;
  mItemActListNewStdAction.Caption := cActionListEditorNewStdAction;
  mItemActListMoveDownAction.Caption := cActionListEditorMoveDownAction;
  mItemActListMoveUpAction.Caption := cActionListEditorMoveUpAction;
  mItemActListDelAction.Caption := cActionListEditorDeleteAction;

  bmp := LoadBitmapFromLazarusResource('add');
  btnAdd.Glyph.Assign(bmp);
  bmp.Free;
  
  bmp := LoadBitmapFromLazarusResource('delete');
  btnDelete.Glyph.Assign(bmp);
  bmp.Free;

  bmp := LoadBitmapFromLazarusResource('arrow_up');
  btnUp.Glyph.Assign(bmp);
  bmp.Free;

  bmp := LoadBitmapFromLazarusResource('arrow_down');
  btnDown.Glyph.Assign(bmp);
  bmp.Free;

  GlobalDesignHook.AddHandlerComponentRenamed(@OnComponentRenamed);
  GlobalDesignHook.AddHandlerSetSelection(@OnComponentSelection);
  GlobalDesignHook.AddHandlerRefreshPropertyValues(@OnRefreshPropertyValues);
end;

destructor TActionListEditor.Destroy;
begin
  if Assigned(GlobalDesignHook)
  then GlobalDesignHook.RemoveAllHandlersForObject(Self);
  FComponentEditor.EditorWindowClose;
  inherited Destroy;
end;

procedure TActionListEditor.SetActionList(AActionList: TActionList);
begin
  if FActionList <> AActionList then begin
    FActionList := AActionList;
    FillCategories;
    FillActionByCategory(-1);
  end;
end;

procedure TActionListEditor.FillCategories;
var
  i: Integer;
  sCategory: String;
  xIndex: Integer;
  sOldCategory: String;
  countCategory: Integer;
begin
  // try remember old category
  sOldCategory := '';
  if (lstCategory.Items.Count>0) and (lstCategory.ItemIndex>-1)
  then sOldCategory := lstCategory.Items[lstCategory.ItemIndex];

  lstCategory.Items.BeginUpdate;
  try
    countCategory := lstCategory.Items.Count;
    lstCategory.Clear;

    for i := 0 to FActionList.ActionCount-1 do begin
      sCategory := FActionList.Actions[i].Category;
      if sCategory = ''
      then Continue;
      xIndex := lstCategory.Items.IndexOf(sCategory);
      if xIndex < 0
      then lstCategory.Items.Add(sCategory);
    end;
    if lstCategory.Items.Count > 0
    then lstCategory.Sorted := True;
    lstCategory.Sorted := False;
    
    xIndex := lstCategory.Items.IndexOf(sOldCategory);
    
    if lstCategory.Items.Count > 0 then begin
      lstCategory.Items.Insert(0, cActionListEditorAllCategory);
      if xIndex > 0 then Inc(xIndex);
    end;
    if lstCategory.Items.Count > 0 then
      begin
        lstCategory.Items.Insert(1, cActionListEditorUnknownCategory);
        if xIndex > 0 then Inc(xIndex);
      end
    else lstCategory.Items.Add(cActionListEditorUnknownCategory);
  finally
    lstCategory.Items.EndUpdate;
  end;
  if xIndex < 0 then begin
    if Assigned(GetSelectedAction)
       and (GetSelectedAction.Category = '')
    then xIndex := lstCategory.Items.IndexOf(cActionListEditorUnknownCategory)
    else xIndex := 0;
  end;
  lstCategory.ItemIndex := xIndex;

  if ( ((lstCategory.ItemIndex <> lstCategory.items.IndexOf(cActionListEditorAllCategory))
         or (lstActionName.Items.Count = 0))
      or (countCategory <> lstCategory.Items.Count) )
  then FillActionByCategory(xIndex);
end;

procedure TActionListEditor.FillActionByCategory(iIndex:Integer);
var
  i: Integer;
  sCategory: String;
  IndexedActionName: String;
begin

  lstActionName.Items.BeginUpdate;
  if iIndex < 0 then iIndex := 0;  // the first possition
  try
    if lstActionName.ItemIndex > -1
    then IndexedActionName := lstActionName.Items[lstActionName.ItemIndex];

    lstActionName.Clear;
    // handle all
    if iIndex = lstCategory.Items.IndexOf(cActionListEditorAllCategory) then begin
      for i := 0 to FActionList.ActionCount-1 do
        lstActionName.Items.Add(FActionList.Actions[i].Name);
      Exit; //throught finally
    end;

    // handle unknown
    if iIndex = lstCategory.Items.IndexOf(cActionListEditorUnknownCategory) then begin
      for i := 0 to FActionList.ActionCount-1 do begin
        if Trim(FActionList.Actions[i].Category) = '' then
          lstActionName.Items.Add(FActionList.Actions[i].Name);
      end;
      Exit; //throught finally
    end;

    // else sort to categories
    sCategory := lstCategory.Items[iIndex];
    for i := 0 to FActionList.ActionCount-1 do
    begin
      if FActionList.Actions[i].Category = sCategory
      then lstActionName.Items.Add(FActionList.Actions[i].Name);
    end;
  finally
    lstActionName.Items.EndUpdate;
    if (IndexedActionName <> '')
       and (lstActionName.Items.IndexOf(IndexedActionName) > -1)
    then lstActionName.ItemIndex := lstActionName.Items.IndexOf(IndexedActionName)
    else if lstActionName.ItemIndex = -1
    then FDesigner.SelectOnlyThisComponent(FActionList);;
  end;
end;


{ TActionListComponentEditor }

procedure TActionListComponentEditor.EditorWindowClose;
begin
  fWindowClosed := True;
end;

constructor TActionListComponentEditor.Create(AComponent: TComponent;
  ADesigner: TComponentEditorDesigner);
begin
  inherited Create(AComponent, ADesigner);
  FDesigner := ADesigner;
  fWindowClosed := True;
end;

destructor TActionListComponentEditor.Destroy;
begin
  if not fWindowClosed
  then FreeThenNil(FActionListEditorForm);
  inherited Destroy;
end;

procedure TActionListComponentEditor.Edit;
var
  AActionList: TActionList;
begin
  AActionList := GetComponent as TActionList;
  if AActionList = nil
  then raise Exception.Create('TActionListComponentEditor.Edit AActionList=nil');
  if fWindowClosed then begin
    FActionListEditorForm := TActionListEditor.Create(Application);
    fWindowClosed := False;
  end;
  with FActionListEditorForm do begin
    lstActionName.ItemIndex := -1;
    Designer := Self.FDesigner;
    SetActionList(AActionList);
    ComponentEditor := Self;
    ShowOnTop;
  end;
end;

function TActionListComponentEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

function TActionListComponentEditor.GetVerb(Index: Integer): string;
begin
  Result := oisEditActionList;
end;

procedure TActionListComponentEditor.ExecuteVerb(Index: Integer);
begin
  Edit;
end;


{ TRegisteredAction }

constructor TRegisteredAction.Create(TheActionClass: TBasicActionClass;
  TheGroupID: integer);
begin
  FActionClass := TheActionClass;
  FGroupId := TheGroupID;
end;


{ TRegisteredActionCategory }

function TRegisteredActionCategory.GetItems(Index: integer): TRegisteredAction;
begin
  Result := FItems[Index];
end;

constructor TRegisteredActionCategory.Create(const CategoryName: string;
  AResource: TComponentClass);
begin
  FName := CategoryName;
  FResource := AResource;
end;

procedure TRegisteredActionCategory.Add(
  const AClasses: array of TBasicActionClass);
var
  i: integer;
  CurCount: Integer;
  IsDouble: Boolean;
  j: Integer;
  AClass: TBasicActionClass;
  l: Integer;
begin
  l := High(AClasses)-Low(AClasses)+1;
  if l = 0 then exit;
  CurCount := FCount;
  Inc(FCount,l);
  // add all classes (ignoring doubles)
  ReAllocMem(FItems,SizeOf(TBasicActionClass)*FCount);
  for i:=Low(AClasses) to High(AClasses) do begin
    AClass:=AClasses[i];
    // check if already exists
    IsDouble:=false;
    for j:=0 to CurCount-1 do begin
      if FItems[j].ActionClass = AClass then begin
        IsDouble := True;
        Break;
      end;
    end;
    // add
    if not IsDouble then begin
      // TODO use current designer group instead of -1
      FItems[CurCount] := TRegisteredAction.Create(AClass,-1);
      Inc(CurCount);
      RegisterNoIcon([AClass]);
      Classes.RegisterClass(AClass);
    end;
  end;
  // resize FItems
  if CurCount < FCount then begin
    FCount := CurCount;
    ReAllocMem(FItems,SizeOf(TBasicActionClass)*FCount);
  end;
end;

destructor TRegisteredActionCategory.Destroy;
var
  i: Integer;
begin
  for i:= Count-1 downto 0 do Items[i].Free;
  ReAllocMem(FItems,0);
  inherited Destroy;
end;

function TRegisteredActionCategory.IndexOfClass(AClass: TBasicActionClass
  ): integer;
begin
  Result:=Count-1;
  while (Result>=0) and (FItems[Result].ActionClass<>AClass) do Dec(Result);
end;

procedure TRegisteredActionCategory.EnumActions(Proc: TEnumActionProc;
  Info: Pointer);
var
  i: Integer;
begin
  for i := 0 to Count-1 do
    Proc(Name,FItems[i].ActionClass,Info);
end;


{ TRegisteredActionCategories }

function TRegisteredActionCategories.GetItems(Index: integer
  ): TRegisteredActionCategory;
begin
  Result:=TRegisteredActionCategory(FItems[Index]);
end;

procedure TRegisteredActionCategories.Add(const CategoryName: string;
  const AClasses: array of TBasicActionClass; AResource: TComponentClass);
var
  i: LongInt;
  Category: TRegisteredActionCategory;
begin
  i := IndexOfCategory(CategoryName);
  if i >= 0 then begin
    Category := Items[i];
    if Category.Resource<>AResource then
      raise Exception.Create('TRegisteredActionCategories.Add Resource<>OldResource');
  end else begin
    Category := TRegisteredActionCategory.Create(CategoryName,AResource);
    if FItems = nil then FItems := TList.Create;
    FItems.Add(Category);
  end;
  Category.Add(AClasses);
  if Assigned(NotifyActionListChange) then
    NotifyActionListChange;
end;

destructor TRegisteredActionCategories.Destroy;
var
  i: Integer;
begin
  for i:= Count-1 downto 0 do Items[i].Free;
  FItems.Free;
  inherited Destroy;
end;

function TRegisteredActionCategories.IndexOfCategory(const CategoryName: string
  ): integer;
begin
  Result := Count-1;
  while (Result>=0) and (CompareText(Items[Result].Name,CategoryName)<>0) do
    Dec(Result);
end;

procedure TRegisteredActionCategories.EnumActions(Proc: TEnumActionProc;
  Info: Pointer);
var
  i: Integer;
begin
  for i:=0 to Count-1 do
    Items[i].EnumActions(Proc,Info);
end;

function TRegisteredActionCategories.FindResource(AClass: TBasicActionClass
  ): TComponentClass;
var
  Category: TRegisteredActionCategory;
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count-1 do begin
    Category := Items[i];
    if Category.IndexOfClass(AClass) >= 0 then begin
      Result := Category.Resource;
      Break;
    end;
  end;
end;

function TRegisteredActionCategories.Count: integer;
begin
  if FItems = nil
  then Result := 0
  else Result := FItems.Count;
end;

procedure RegisterStandardActions;
begin
  // TODO
  //  - default images for actions

  RegisterActions(cActionListEditorUnknownCategory,[TAction],nil);
  // register edit actions
  RegisterActions(cActionListEditorEditCategory,[TEditCut,TEditCopy,TEditPaste,TEditSelectAll,
   TEditUndo,TEditDelete],nil);
  // register help actions
  RegisterActions(cActionListEditorHelpCategory,[THelpAction,THelpContents,THelpTopicSearch,
    THelpOnHelp,THelpContextAction],nil);
  // register dialog actions
  RegisterActions(cActionListEditorDialogCategory,[TColorSelect,TFontEdit],nil);
  // register file actions
  RegisterActions(cActionListEditorFileCategory,[TFileOpen,TFileOpenWith,TFileSaveAs,TFileExit],nil);
  // register database actions
  RegisterActions(cActionListEditorDatabaseCategory,[TDataSetFirst,TDataSetLast,TDataSetNext,
    TDataSetPrior,TDataSetRefresh,TDataSetCancel,TDataSetDelete,TDataSetEdit,
    TDataSetInsert,TDataSetPost],nil);
end;

initialization
  {$I actionseditor.lrs}
  NotifyActionListChange := nil;

  RegisteredActions := TRegisteredActionCategories.Create;
  RegisterActionsProc := @RegisterActions;
  UnRegisterActionsProc := @UnregisterActions;
  EnumRegisteredActionsProc := @EnumActions;
  CreateActionProc := @CreateAction;
  
  RegisterComponentEditor(TActionList,TActionListComponentEditor);
  RegisterStandardActions;

finalization
  RegisteredActions.Free;
  RegisteredActions := nil;
end.

