{ Copyright (C) 2004

 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

  Author: Lagunov Aleksey

  Abstract:
    Property Editors for Database components of FCL and LCL.
}
unit DBPropEdits;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ObjInspStrConsts, PropEdits, PropEditUtils,
  ComponentEditors,
  TypInfo, DB, DbCtrls, DBGrids;

type
  TFieldProperty = class(TStringPropertyEditor)
  public
    function  GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure FillValues(const Values: TStringList); virtual;
  end;

  { TLookupFieldProperty }

  TLookupFieldProperty = class(TFieldProperty)
  public
    procedure FillValues(const Values: TStringList); override;
  end;

  TDBGridFieldProperty = class(TFieldProperty)
  public
    procedure FillValues(const Values: TStringList); override;
  end;

  { TDBGridComponentEditor }

  TDBGridComponentEditor = class(TComponentEditor)
  public
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
  end;

function GetFieldDefsLookupRoot(APersistent: TPersistent): TPersistent;

implementation

procedure LoadDataSourceFields(DataSource: TDataSource; List: TStrings);
var
  DataSet: TDataSet;
  i: Integer;
begin
  if Assigned(DataSource) then
  begin
    DataSet := DataSource.DataSet;
    if Assigned(DataSet) then
    begin
      if DataSet.Fields.Count > 0 then
        DataSet.GetFieldNames(List)
      else
      begin
        for i := 0 to DataSet.FieldDefs.Count - 1 do
          List.Add(DataSet.FieldDefs[i].Name);
      end;
    end;
  end;
end;

function GetFieldDefsLookupRoot(APersistent: TPersistent): TPersistent;
var
  aFieldDefs: TFieldDefs;
begin
  Result:=nil;
  if not (APersistent is TFieldDefs) then exit;
  aFieldDefs:=TFieldDefs(APersistent);
  Result:=aFieldDefs.Owner;
  if Result=nil then
    Result:=aFieldDefs.Dataset;
  Result:=GetLookupRootForComponent(Result);
end;

{ TFieldProperty }

function TFieldProperty.GetAttributes: TPropertyAttributes;
begin
  Result:= [paValueList, paSortList, paMultiSelect];
end;

procedure TFieldProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
  Values: TStringList;
begin
  Values := TStringList.Create;
  try
    FillValues(Values);
    for I := 0 to Values.Count - 1 do Proc(Values[I]);
  finally
    Values.Free;
  end;
end;

procedure TFieldProperty.FillValues(const Values: TStringList);
var
  DataSource: TDataSource;
begin
  DataSource := GetObjectProp(GetComponent(0), 'DataSource') as TDataSource;
  LoadDataSourceFields(DataSource, Values);
end;

{ TDBGridFieldProperty }

procedure TDBGridFieldProperty.FillValues(const Values: TStringList);
var
  Column: TColumn;
  Grid: TdbGrid;
begin
  Column:=TColumn(GetComponent(0));
  if not (Column is TColumn) then exit;
  Grid:=TdbGrid(Column.Grid);
  if not (Grid is TdbGrid) then exit;
  LoadDataSourceFields(Grid.DataSource, Values);
end;

{ TDBGridComponentEditor }

function TDBGridComponentEditor.GetVerbCount: Integer;
begin
  Result:= 1;
end;

function TDBGridComponentEditor.GetVerb(Index: Integer): string;
begin
  Result:= sccsLvColEdt;
end;

procedure TDBGridComponentEditor.ExecuteVerb(Index: Integer);
var
  Hook: TPropertyEditorHook;
  DBGrid: TDBGrid;
begin
  DBGrid := GetComponent as TDBGrid;
  GetHook(Hook);
  EditCollection(DBGrid, DBGrid.Columns, 'Columns');
  if Assigned(Hook) then Hook.Modified(Self);
end;

{ TLookupFieldProperty }

procedure TLookupFieldProperty.FillValues(const Values: TStringList);
var
  DataSource: TDataSource;
begin
  DataSource := GetObjectProp(GetComponent(0), 'ListSource') as TDataSource;
  LoadDataSourceFields(DataSource, Values);
end;

initialization
  RegisterPropertyEditor(TypeInfo(string), TComponent, 'DataField', TFieldProperty);
  RegisterPropertyEditor(TypeInfo(string), TDBLookupListBox, 'KeyField', TLookupFieldProperty);
  RegisterPropertyEditor(TypeInfo(string), TDBLookupListBox, 'ListField', TLookupFieldProperty);
  RegisterPropertyEditor(TypeInfo(string), TDBLookupComboBox, 'KeyField', TLookupFieldProperty);
  RegisterPropertyEditor(TypeInfo(string), TDBLookupComboBox, 'ListField', TLookupFieldProperty);
  RegisterPropertyEditor(TypeInfo(string), TColumn, 'FieldName', TDBGridFieldProperty);
  RegisterComponentEditor(TDBGrid,TDBGridComponentEditor);
  RegisterGetLookupRoot(@GetFieldDefsLookupRoot);

end.

