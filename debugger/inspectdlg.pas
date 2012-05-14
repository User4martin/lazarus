{               ----------------------------------------------
                     inspectdlg.pas  -  Inspect Dialog
                ----------------------------------------------

 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************
}
unit InspectDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics,
  IDEWindowIntf, DebuggerStrConst, ComCtrls, ObjectInspector, PropEdits, Debugger, DebuggerDlg, BaseDebugManager,
  LazarusIDEStrConsts, LCLType, Grids, StdCtrls, Menus;

type

  { TOIDBGGrid }

  TOIDBGGrid=class(TOIPropertyGrid)
  private
  protected
    procedure BuildPropertyList(OnlyIfNeeded: boolean=false);
  public
  end;

  { TIDEInspectDlg }

  TIDEInspectDlg = class(TDebuggerDlg)
    EditInspected: TEdit;
    menuClassType: TMenuItem;
    PageControl: TPageControl;
    PopupMenu1: TPopupMenu;
    StatusBar1: TStatusBar;
    DataPage: TTabSheet;
    PropertiesPage: TTabSheet;
    MethodsPage: TTabSheet;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure menuClassTypeClick(Sender: TObject);
  private
    //FDataGridHook,
    //FPropertiesGridHook,
    //FMethodsGridHook: TPropertyEditorHook;
    //FDataGrid,
    //FPropertiesGrid,
    //FMethodsGrid: TOIDBGGrid;
    FExpression: ansistring;
    FHumanReadable: ansistring;
    FDBGInfo: TDBGType;
    FGridData: TStringGrid;
    FGridMethods: TStringGrid;
    procedure Localize;
    procedure InspectClass;
    procedure InspectRecord;
    procedure InspectVariant;
    procedure InspectSimple;
    procedure InspectEnum;
    procedure InspectSet;
    procedure InspectPointer;
    procedure GridDataSetup(Initial: Boolean = False);
    procedure GridMethodsSetup(Initial: Boolean = False);
    procedure ShowDataFields;
    procedure ShowMethodsFields;
    procedure Clear;
  protected
    function  ColSizeGetter(AColId: Integer; var ASize: Integer): Boolean;
    procedure ColSizeSetter(AColId: Integer; ASize: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Execute(const AExpression: ansistring);
    procedure UpdateData;
  end;

implementation

{$R *.lfm}

var
  InspectDlgWindowCreator: TIDEWindowCreator;

const
  COL_INSPECT_DNAME    = 1;
  COL_INSPECT_DTYPE    = 2;
  COL_INSPECT_DVALUE   = 3;
  COL_INSPECT_MNAME    = 11;
  COL_INSPECT_MTYPE    = 12;
  COL_INSPECT_MRETURNS = 13;
  COL_INSPECT_MADDRESS = 14;

function InspectDlgColSizeGetter(AForm: TCustomForm; AColId: Integer; var ASize: Integer): Boolean;
begin
  Result := AForm is TIDEInspectDlg;
  if Result then
    Result := TIDEInspectDlg(AForm).ColSizeGetter(AColId, ASize);
end;

procedure InspectDlgColSizeSetter(AForm: TCustomForm; AColId: Integer; ASize: Integer);
begin
  if AForm is TIDEInspectDlg then
    TIDEInspectDlg(AForm).ColSizeSetter(AColId, ASize);
end;

{ TIDEInspectDlg }

procedure TIDEInspectDlg.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  IDEDialogLayoutList.SaveLayout(Self);
end;

procedure TIDEInspectDlg.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    Close;
end;

procedure TIDEInspectDlg.menuClassTypeClick(Sender: TObject);
begin
  menuClassType.Checked := not menuClassType.Checked;
  UpdateData;
end;

procedure TIDEInspectDlg.Localize;
begin
  Caption := lisInspectDialog;
  DataPage.Caption := lisInspectData;
  PropertiesPage.Caption := lisInspectProperties;
  MethodsPage.Caption := lisInspectMethods;
  menuClassType.Caption := drsUseInstanceClassType;
end;

procedure TIDEInspectDlg.InspectClass;
begin
  DataPage.TabVisible:=true;
  PropertiesPage.TabVisible:=false;
  MethodsPage.TabVisible:=true;

  if not Assigned(FDBGInfo) then exit;
  if not Assigned(FDBGInfo.Fields) then exit;
  EditInspected.Text:=FExpression+' : Class '+FDBGInfo.TypeName+' inherits from '+FDBGInfo.Ancestor;
  GridDataSetup;
  ShowDataFields;
  //FGridData.AutoSizeColumn(1);
  //FGridData.AutoSizeColumn(2);
  GridMethodsSetup;
  ShowMethodsFields;
  //FGridMethods.AutoSizeColumn(1);
  //FGridMethods.AutoSizeColumn(3);
end;

procedure TIDEInspectDlg.InspectVariant;
begin
  DataPage.TabVisible:=true;
  PropertiesPage.TabVisible:=false;
  MethodsPage.TabVisible:=false;
  if not Assigned(FDBGInfo) then exit;
  EditInspected.Text:=FExpression+' : Variant';
  GridDataSetup;
  FGridData.Cells[0,1]:=FExpression;
  FGridData.Cells[1,1]:='Variant';
  FGridData.Cells[2,1]:=FDBGInfo.Value.AsString;
  //FGridData.AutoSizeColumn(1);
end;

procedure TIDEInspectDlg.InspectRecord;
begin
  DataPage.TabVisible:=true;
  PropertiesPage.TabVisible:=false;
  MethodsPage.TabVisible:=false;

  if not Assigned(FDBGInfo) then exit;
  if not Assigned(FDBGInfo.Fields) then exit;
  EditInspected.Text:=FExpression+' : '+FDBGInfo.TypeName;
  GridDataSetup;
  ShowDataFields;
  //FGridData.AutoSizeColumn(2);
end;

procedure TIDEInspectDlg.InspectSimple;
begin
  DataPage.TabVisible:=true;
  PropertiesPage.TabVisible:=false;
  MethodsPage.TabVisible:=false;
  if not Assigned(FDBGInfo) then exit;
  EditInspected.Text:=FExpression+' : '+FDBGInfo.TypeName + ' = ' + FDBGInfo.Value.AsString;
  GridDataSetup;
  FGridData.Cells[0,1]:=FExpression;
  FGridData.Cells[1,1]:=FDBGInfo.TypeName;
  FGridData.Cells[2,1]:=FDBGInfo.Value.AsString;
  //FGridData.AutoSizeColumn(2);
end;

procedure TIDEInspectDlg.InspectEnum;
begin
  DataPage.TabVisible:=true;
  PropertiesPage.TabVisible:=false;
  MethodsPage.TabVisible:=false;
  if not Assigned(FDBGInfo) then exit;
  EditInspected.Text:=FExpression+' : '+FDBGInfo.TypeName + ' = ' + FDBGInfo.Value.AsString;
  GridDataSetup;
  FGridData.Cells[0,1]:=FExpression;
  FGridData.Cells[1,1]:=FDBGInfo.TypeName;
  if (FDBGInfo.TypeName <> '') and (FDBGInfo.TypeDeclaration <> '')
  then FGridData.Cells[1,1] := FGridData.Cells[1,1] + ' = ';
  FGridData.Cells[1,1] := FGridData.Cells[1,1] + FDBGInfo.TypeDeclaration;
  FGridData.Cells[2,1]:=FDBGInfo.Value.AsString;
  //FGridData.AutoSizeColumn(2);
end;

procedure TIDEInspectDlg.InspectSet;
begin
  DataPage.TabVisible:=true;
  PropertiesPage.TabVisible:=false;
  MethodsPage.TabVisible:=false;
  if not Assigned(FDBGInfo) then exit;
  EditInspected.Text:=FExpression+' : '+FDBGInfo.TypeName + ' = ' + FDBGInfo.Value.AsString;
  GridDataSetup;
  FGridData.Cells[0,1]:=FExpression;
  FGridData.Cells[1,1]:=FDBGInfo.TypeName;
  if (FDBGInfo.TypeName <> '') and (FDBGInfo.TypeDeclaration <> '')
  then FGridData.Cells[1,1] := FGridData.Cells[1,1] + ' = ';
  FGridData.Cells[1,1] := FGridData.Cells[1,1] + FDBGInfo.TypeDeclaration;
  FGridData.Cells[2,1]:=FDBGInfo.Value.AsString;
  //FGridData.AutoSizeColumn(2);
end;

procedure TIDEInspectDlg.InspectPointer;
begin
  DataPage.TabVisible:=true;
  PropertiesPage.TabVisible:=false;
  MethodsPage.TabVisible:=false;
  if not Assigned(FDBGInfo) then exit;
  EditInspected.Text:=FExpression+' : '+FDBGInfo.TypeName + ' = ' + FDBGInfo.Value.AsString;
  GridDataSetup;
  FGridData.Cells[0,1]:=FExpression;
  if (FDBGInfo.TypeName <> '') and (FDBGInfo.TypeName[1] = '^')
  then FGridData.Cells[1,1]:='Pointer to '+copy(FDBGInfo.TypeName, 2, length(FDBGInfo.TypeName))
  else FGridData.Cells[1,1]:=FDBGInfo.TypeName;
  FGridData.Cells[2,1]:=format('$%x',[PtrUInt(FDBGInfo.Value.AsPointer)]);
  //FGridData.AutoSizeColumn(2);
end;

procedure TIDEInspectDlg.GridDataSetup(Initial: Boolean = False);
begin
  if Initial then
    with FGridData do begin
      Clear;
      BorderStyle:=bsNone;
      BorderWidth:=0;
      DefaultColWidth:=100;
      Options:=[goColSizing,goDblClickAutoSize,goDrawFocusSelected, goThumbTracking,
                          goVertLine,goHorzLine,goFixedHorzLine,goSmoothScroll,
                          goTabs,goRowSelect];
      Align:=alClient;
      TitleFont.Style:=[fsBold];
      ExtendedSelect:=false;
      RowCount:=2;
      FixedRows:=1;
      FixedCols:=0;
      ColCount:=3;
      Cols[0].Text:='Name';
      Cols[1].Text:='Type';
      Cols[2].Text:='Value';
      Color:=clBtnFace;
    end;
  FGridData.RowCount:=1;
  FGridData.RowCount:=2;
  FGridData.FixedRows:=1;
  FGridData.Visible := True;
end;

procedure TIDEInspectDlg.GridMethodsSetup(Initial: Boolean = False);
begin
  if Initial then
    with FGridMethods do begin
      Clear;
      BorderStyle:=bsNone;
      BorderWidth:=0;
      DefaultColWidth:=100;
      Options:=[goColSizing,goDblClickAutoSize,goDrawFocusSelected, goThumbTracking,
                          goVertLine,goHorzLine,goFixedHorzLine,goSmoothScroll,
                          goTabs,goRowSelect];
      Align:=alClient;
      TitleFont.Style:=[fsBold];
      ExtendedSelect:=false;
      RowCount:=2;
      FixedRows:=1;
      FixedCols:=0;
      ColCount:=4;
      Cols[0].Text:='Name';
      Cols[1].Text:='Type';
      Cols[2].Text:='Returns';
      Cols[3].Text:='Address';
      Color:=clBtnFace;
    end;
  FGridMethods.RowCount:=1;
  FGridMethods.RowCount:=2;
  FGridMethods.FixedRows:=1;
end;

procedure TIDEInspectDlg.ShowDataFields;
var
  j,k: SizeInt;
begin
  k:=0;
  for j := 0 to FDBGInfo.Fields.Count-1 do begin
    case FDBGInfo.Fields[j].DBGType.Kind of
      skSimple,skRecord,skPointer: inc(k);
    end;
  end;
  k:=k+1;
  if k<2 Then k:=2;
  FGridData.RowCount:=k;
  k:=0;
  for j := 0 to FDBGInfo.Fields.Count-1 do begin
    case FDBGInfo.Fields[j].DBGType.Kind of
      skSimple:
        begin
          inc(k);
          FGridData.Cells[0,k]:=FDBGInfo.Fields[j].Name;
          FGridData.Cells[1,k]:=FDBGInfo.Fields[j].DBGType.TypeName;
          if FDBGInfo.Fields[j].DBGType.Value.AsString='$0' then begin
            if FDBGInfo.Fields[j].DBGType.TypeName='ANSISTRING' then begin
              FGridData.Cells[2,k]:='''''';
            end else begin
              FGridData.Cells[2,k]:='nil';
            end;
          end else begin
            FGridData.Cells[2,k]:=FDBGInfo.Fields[j].DBGType.Value.AsString;
          end;
        end;
      skRecord:
        begin
          inc(k);
          FGridData.Cells[0,k]:=FDBGInfo.Fields[j].Name;
          FGridData.Cells[1,k]:='Record '+FDBGInfo.Fields[j].DBGType.TypeName;
          FGridData.Cells[2,k]:=FDBGInfo.Fields[j].DBGType.Value.AsString;
        end;
      skVariant:
        begin
          inc(k);
          FGridData.Cells[0,k]:=FDBGInfo.Fields[j].Name;
          FGridData.Cells[1,k]:='Variant';
          FGridData.Cells[2,k]:=FDBGInfo.Fields[j].DBGType.Value.AsString;
        end;
      skProcedure:
        begin
        end;
      skFunction:
        begin
        end;
       skPointer:
        begin
          inc(k);
          FGridData.Cells[0,k]:=FDBGInfo.Fields[j].Name;
          FGridData.Cells[1,k]:='Pointer '+FDBGInfo.Fields[j].DBGType.TypeName;
          FGridData.Cells[2,k]:=FDBGInfo.Fields[j].DBGType.Value.AsString;
        end;
      else
        raise Exception.Create('Inspect: Unknown type in record ->'+inttostr(ord(FDBGInfo.Fields[j].DBGType.Kind)));
    end;
  end;
end;

procedure TIDEInspectDlg.ShowMethodsFields;
var
  j,k: SizeInt;
begin
  k:=0;
  for j := 0 to FDBGInfo.Fields.Count-1 do begin
    case FDBGInfo.Fields[j].DBGType.Kind of
      skProcedure,skFunction: inc(k);
    end;
  end;
  k:=k+1;
  if k<2 Then k:=2;
  FGridMethods.RowCount:=k;
  k:=0;
  for j := 0 to FDBGInfo.Fields.Count-1 do begin
    case FDBGInfo.Fields[j].DBGType.Kind of
      skProcedure:
        begin
          inc(k);
          FGridMethods.Cells[0,k]:=FDBGInfo.Fields[j].Name;
          if ffDestructor in FDBGInfo.Fields[j].Flags then begin
            FGridMethods.Cells[1,k]:='Destructor';
          end else begin
            FGridMethods.Cells[1,k]:='Procedure';
          end;
          FGridMethods.Cells[2,k]:='';
          FGridMethods.Cells[3,k]:='???';
        end;
      skFunction:
        begin
          inc(k);
          FGridMethods.Cells[0,k]:=FDBGInfo.Fields[j].Name;
          if ffConstructor in FDBGInfo.Fields[j].Flags then begin
            FGridMethods.Cells[1,k]:='Constructor';
          end else begin
            FGridMethods.Cells[1,k]:='Function';
          end;
          if Assigned(FDBGInfo.Fields[j].DBGType.Result) then begin
            FGridMethods.Cells[2,k]:=FDBGInfo.Fields[j].DBGType.Result.TypeName;
          end else begin
            FGridMethods.Cells[2,k]:='';
          end;
          FGridMethods.Cells[3,k]:='???';
        end;
    end;
  end;
end;

procedure TIDEInspectDlg.Clear;
begin
  DataPage.TabVisible:=false;
  PropertiesPage.TabVisible:=false;
  MethodsPage.TabVisible:=false;
  GridDataSetup;
  FGridData.Visible := False;
  FreeAndNil(FDBGInfo);
  EditInspected.Text:='';
end;

function TIDEInspectDlg.ColSizeGetter(AColId: Integer; var ASize: Integer): Boolean;
begin
  ASize := -1;
  case AColId of
    COL_INSPECT_DNAME:    ASize := FGridData.ColWidths[0];
    COL_INSPECT_DTYPE:    ASize := FGridData.ColWidths[1];
    COL_INSPECT_DVALUE:   ASize := FGridData.ColWidths[2];
    COL_INSPECT_MNAME:    ASize := FGridMethods.ColWidths[0];
    COL_INSPECT_MTYPE:    ASize := FGridMethods.ColWidths[1];
    COL_INSPECT_MRETURNS: ASize := FGridMethods.ColWidths[2];
    COL_INSPECT_MADDRESS: ASize := FGridMethods.ColWidths[3];
  end;
  Result := (ASize > 0) and (ASize <> 100); // The default for all
end;

procedure TIDEInspectDlg.ColSizeSetter(AColId: Integer; ASize: Integer);
begin
  case AColId of
    COL_INSPECT_DNAME:    FGridData.ColWidths[0]:= ASize;
    COL_INSPECT_DTYPE:    FGridData.ColWidths[1]:= ASize;
    COL_INSPECT_DVALUE:   FGridData.ColWidths[2]:= ASize;
    COL_INSPECT_MNAME:    FGridMethods.ColWidths[0]:= ASize;
    COL_INSPECT_MTYPE:    FGridMethods.ColWidths[1]:= ASize;
    COL_INSPECT_MRETURNS: FGridMethods.ColWidths[2]:= ASize;
    COL_INSPECT_MADDRESS: FGridMethods.ColWidths[3]:= ASize;
  end;
end;

constructor TIDEInspectDlg.Create(AOwner: TComponent);

  function NewGrid(AName: String; AParent: TWinControl; AHook: TPropertyEditorHook): TOIDBGGrid;
  begin
    Result := TOIDBGGrid.Create(Self);
    with Result do
    begin
      Name := AName;
      Parent := AParent;
      Visible := True;
      Align := alClient;
    end;
  end;

begin
  inherited Create(AOwner);
  //FDataGridHook := TPropertyEditorHook.Create;
  //FDataGrid := NewGrid('DataGrid', DataPage, FDataGridHook);
  //
  //FPropertiesGridHook := TPropertyEditorHook.Create;
  //FPropertiesGrid := NewGrid('PropertiesGrid', PropertiesPage, FPropertiesGridHook);
  //
  //FMethodsGridHook := TPropertyEditorHook.Create;
  //FMethodsGrid := NewGrid('MethodsGrid', MethodsPage, FMethodsGridHook);

  Localize;

  FGridData:=TStringGrid.Create(DataPage);
  DataPage.InsertControl(FGridData);
  GridDataSetup(True);

  FGridMethods:=TStringGrid.Create(MethodsPage);
  MethodsPage.InsertControl(FGridMethods);
  GridMethodsSetup(True);

  Clear;
end;

destructor TIDEInspectDlg.Destroy;
begin
  FreeAndNil(FDBGInfo);
  //FreeAndNil(FDataGridHook);
  //FreeAndNil(FPropertiesGridHook);
  //FreeAndNil(FMethodsGridHook);
  inherited Destroy;
end;

procedure TIDEInspectDlg.Execute(const AExpression: ansistring);
begin
  FExpression:=AExpression;
  UpdateData;
end;

procedure TIDEInspectDlg.UpdateData;
var
  Opts: TDBGEvaluateFlags;
begin
  FreeAndNil(FDBGInfo);
  if FExpression = ''
  then exit;

  Opts := [defFullTypeInfo];
  if menuClassType.Checked then
    include(Opts, defClassAutoCast);
  if not DebugBoss.Evaluate(FExpression, FHumanReadable, FDBGInfo, Opts)
  or not assigned(FDBGInfo) then
  begin
    FreeAndNil(FDBGInfo);
    Clear;
    EditInspected.Text:=FExpression + ' : unavailable';
    Exit;
  end;
  case FDBGInfo.Kind of
    skClass: InspectClass();
    skRecord: InspectRecord();
    skVariant: InspectVariant();
    skEnum: InspectEnum;
    skSet: InspectSet;
    skProcedure: InspectSimple;
    skFunction: InspectSimple;
    skSimple: InspectSimple();
    skPointer: InspectPointer();
  //  skDecomposable: ;
  end;
end;

{ TOIDBGGrid }

procedure TOIDBGGrid.BuildPropertyList(OnlyIfNeeded: boolean);
begin

end;

initialization

  InspectDlgWindowCreator := IDEWindowCreators.Add(DebugDialogNames[ddtInspect]);
  InspectDlgWindowCreator.OnCreateFormProc := @CreateDebugDialog;
  InspectDlgWindowCreator.OnSetDividerSize := @InspectDlgColSizeSetter;
  InspectDlgWindowCreator.OnGetDividerSize := @InspectDlgColSizeGetter;
  InspectDlgWindowCreator.DividerTemplate.Add('InspectDataName',  COL_INSPECT_DNAME, @drsInspectColWidthDataName);
  InspectDlgWindowCreator.DividerTemplate.Add('InspectDataType',  COL_INSPECT_DTYPE, @drsInspectColWidthDataType);
  InspectDlgWindowCreator.DividerTemplate.Add('InspectDataValue', COL_INSPECT_DVALUE, @drsInspectColWidthDataValue);

  InspectDlgWindowCreator.DividerTemplate.Add('InspectMethName',    COL_INSPECT_MNAME,    @drsInspectColWidthMethName);
  InspectDlgWindowCreator.DividerTemplate.Add('InspectMethType',    COL_INSPECT_MTYPE,    @drsInspectColWidthMethType);
  InspectDlgWindowCreator.DividerTemplate.Add('InspectMethReturns', COL_INSPECT_MRETURNS, @drsInspectColWidthMethReturns);
  InspectDlgWindowCreator.DividerTemplate.Add('InspectMethAddress', COL_INSPECT_MADDRESS, @drsInspectColWidthMethAddress);
  InspectDlgWindowCreator.CreateSimpleLayout;

end.

