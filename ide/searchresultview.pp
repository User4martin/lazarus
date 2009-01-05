{
 /***************************************************************************
                       searchresultviewView.pp - SearchResult view
                       -------------------------------------------
                   TSearchResultsView is responsible for displaying the
                   Search Results of a find operation.


                   Initial Revision  : Sat Nov 8th 2003


 ***************************************************************************/

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
unit SearchResultView;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, LResources, Forms, Controls, Graphics, Dialogs,
  ComCtrls, ExtCtrls, StdCtrls, Buttons, LCLType,
  IDEOptionDefs, LazarusIDEStrConsts, EnvironmentOpts, EditorOptions, InputHistory,
  IDEProcs, FindInFilesDlg, Project, MainIntf;

type
  { TLazSearchMatchPos }
  
  TLazSearchMatchPos = class(TObject)
  private
    FFileEndPos: TPoint;
    FFilename: string;
    FFileStartPos: TPoint;
    fMatchStart: integer;
    fMatchLen: integer;
    FNextInThisLine: TLazSearchMatchPos;
    FShownFilename: string;
    FTheText: string;
  public
    property MatchStart: integer read fMatchStart write fMatchStart;// start in TheText
    property MatchLen: integer read fMatchLen write fMatchLen; // length in TheText
    property Filename: string read FFilename write FFilename;
    property FileStartPos: TPoint read FFileStartPos write FFileStartPos;
    property FileEndPos: TPoint read FFileEndPos write FFileEndPos;
    property TheText: string read FTheText write FTheText;
    property ShownFilename: string read FShownFilename write FShownFilename;
    property NextInThisLine: TLazSearchMatchPos read FNextInThisLine write FNextInThisLine;
    destructor Destroy; override;
  end;//TLazSearchMatchPos


  { TLazSearch }

  TLazSearch = Class(TObject)
  private
    FReplaceText: string;
    fSearchString: string;
    fSearchOptions: TLazFindInFileSearchOptions;
    fSearchDirectory: string;
    fSearchMask: string;
  public
    property SearchString: string read fSearchString write fSearchString;
    property ReplaceText: string read FReplaceText write FReplaceText;
    property SearchOptions: TLazFindInFileSearchOptions read fSearchOptions
                                                        write fSearchOptions;
    property SearchDirectory: string read fSearchDirectory
                                     write fSearchDirectory;
    property SearchMask: string read fSearchMask write fSearchMask;
  end;//TLazSearch


  { TLazSearchResultTV }

  TLazSearchResultTV = class(TCustomTreeView)
  private
    fSearchObject: TLazSearch;
    FSkipped: integer;
    fUpdateStrings: TStrings;
    fBackUpStrings: TStrings;
    fUpdating: boolean;
    fUpdateCount: integer;
    fShortenPathNeeded: boolean;
    FSearchInListPhrases: string;
    fFiltered: Boolean;
    procedure SetSkipped(const AValue: integer);
    procedure AddNode(Line: string; MatchPos: TLazSearchMatchPos);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property SearchObject: TLazSearch read fSearchObject write fSearchObject;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure ShortenPaths;
    procedure FreeObjectsTN(tnItems: TTreeNodes);
    procedure FreeObjects(slItems: TStrings);
    function BeautifyLine(const Filename: string; X, Y: integer;
                          const Line: string): string;
    function BeautifyLine(SearchPos: TLazSearchMatchPos): string;
    property BackUpStrings: TStrings read fBackUpStrings write fBackUpStrings;
    property Filtered: Boolean read fFiltered write fFiltered;
    property SearchInListPhrases: string read FSearchInListPhrases write FSearchInListPhrases;
    property UpdateItems: TStrings read fUpdateStrings write fUpdateStrings;
    property UpdateState: boolean read fUpdating;
    property Skipped: integer read FSkipped write SetSkipped;
    property Items;
    function ItemsAsStrings: TStrings;
  end;


  { TSearchResultsView }

  TSearchResultsView = class(TForm)
    SearchInListEdit: TEdit;
    ImageList: TImageList;
    ResultsNoteBook: TNotebook;
    ToolBar: TToolBar;
    SearchAgainButton: TToolButton;
    ToolButton3: TToolButton;
    FilterButton: TToolButton;
    ClosePageButton: TToolButton;
    ForwardSearchButton: TToolButton;
    ResetResultsButton: TToolButton;
    procedure ClosePageButtonClick(Sender: TObject);
    procedure Form1Create(Sender: TObject);
    procedure TreeViewKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ResultsNoteBookClosetabclicked(Sender: TObject);
    procedure SearchAgainButtonClick(Sender: TObject);
    procedure TreeViewAdvancedCustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; State: TCustomDrawState; Stage: TCustomDrawStage;
      var PaintImages, DefaultDraw: Boolean);
    procedure LazTVShowHint(Sender: TObject; HintInfo: PHintInfo);
    procedure LazTVMousemove(Sender: TObject; Shift: TShiftState;
                             X, Y: Integer);
    Procedure LazTVMouseWheel(Sender: TObject; Shift: TShiftState;
                   WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure edSearchInListChange(Sender: TObject );
    procedure ResultsNoteBookPageChanged (Sender: TObject );
    procedure ForwardSearchButtonClick(Sender: TObject );
    procedure ResetResultsButtonClick(Sender: TObject );
    procedure SearchInListEditKeyDown(Sender: TObject; var Key: Word;
                                    Shift: TShiftState );
    procedure FilterButtonClick (Sender: TObject );
  private
    FMaxItems: integer;
    FOnSelectionChanged: TNotifyEvent;
    FMouseOverIndex: integer;
    function BeautifyPageName(const APageName: string): string;
    function PageExists(const APageName: string): boolean;
    function GetPageIndex(const APageName: string): integer;
    function GetTreeView(APageIndex: integer): TLazSearchResultTV;
    procedure TreeViewClicked(Sender: TObject);
    procedure TreeViewDoubleClicked(Sender: TObject);
    procedure SetItems(Index: Integer; Value: TStrings);
    function GetItems(Index: integer): TStrings;
    procedure SetMaxItems(const AValue: integer);
  public
    function AddSearch(const ResultsName: string;
                       const SearchText: string;
                       const ReplaceText: string;
                       const ADirectory: string;
                       const AMask: string;
                       const TheOptions: TLazFindInFileSearchOptions): integer;
    function GetSourcePositon: TPoint;
    function GetSourceFileName: string;
    function GetSelectedText: string;
    function GetSelectedMatchPos: TLazSearchMatchPos;
    procedure BringResultsToFront(const APageName: string);
    procedure AddMatch(const APageIndex: integer;
                       const Filename: string; const StartPos, EndPos: TPoint;
                       const TheText: string;
                       const MatchStart: integer; const MatchLen: integer);
    procedure BeginUpdate(APageIndex: integer);
    procedure EndUpdate(APageIndex: integer);
    procedure Parse_Search_Phrases(var slPhrases: TStrings);
    procedure ClosePage(PageIndex: integer);
    property OnSelectionChanged: TNotifyEvent read fOnSelectionChanged
                                              write fOnSelectionChanged;
    property Items[Index: integer]: TStrings read GetItems write SetItems;
    property MaxItems: integer read FMaxItems write SetMaxItems;
  end; 

var
  SearchResultsView: TSearchResultsView;

implementation

{ TSearchResultsView }

const
  MaxTextLen = 80;
  
function CopySearchMatchPos(var Src, Dest: TLazSearchMatchPos): Boolean;
begin
  Result := False;
  if ((Src = nil) or (Dest = nil)) then Exit;
  Dest.MatchStart := Src.MatchStart;
  Dest.MatchLen := Src.MatchLen;
  Dest.Filename := Src.Filename;
  Dest.FileStartPos := Src.FileStartPos;
  Dest.FileEndPos := Src.FileEndPos;
  Dest.TheText := Src.TheText;
  Dest.ShownFilename := Src.ShownFilename;
  Result := True;
end;
  
procedure TSearchResultsView.Form1Create(Sender: TObject);
var
  ALayout: TIDEWindowLayout;
begin
  FMaxItems:=50000;
  
  ResultsNoteBook.Options:= ResultsNoteBook.Options+[nboShowCloseButtons];
  ResultsNoteBook.Update;

  Caption:=lisMenuViewSearchResults;

  SearchAgainButton.Hint:=rsStartANewSearch;
  ClosePageButton.Hint := rsCloseCurrentPage;
  FilterButton.Hint:=rsFilterTheListWithTheCurrentFilterExpression;
  ForwardSearchButton.Hint:=rsGoToTheNextItemInTheSearchList;
  ResetResultsButton.Hint:=rsResetFilter;
  SearchInListEdit.Hint:=rsEnterOneOrMorePhrasesThatYouWantToSearchOrFilterIn;

  Name := NonModalIDEWindowNames[nmiwSearchResultsViewName];
  ALayout:=EnvironmentOptions.IDEWindowLayoutList.
                                          ItemByEnum(nmiwSearchResultsViewName);
  ALayout.Form:=TForm(Self);
  ALayout.Apply;
  fOnSelectionChanged:= nil;
  ShowHint:= True;
  fMouseOverIndex:= -1;
end;//Create

procedure TSearchResultsView.ClosePageButtonClick(Sender: TObject);
begin
  ClosePage(ResultsNoteBook.PageIndex);
end;

{Keeps track of the Index of the Item the mouse is over, Sets ShowHint to true
if the Item length is longer than the TreeView client width.}
procedure TSearchResultsView.LazTVMousemove(Sender: TObject; Shift: TShiftState;
                                       X, Y: Integer);
begin
  if Sender is TLazSearchResultTV then
  begin
    with Sender as TLazSearchResultTV do
    begin
      if Assigned(GetNodeAt(X, Y)) then
        fMouseOverIndex:=GetNodeAt(X, Y).Index
      else
        fMouseOverIndex:=-1;
      if (fMouseOverIndex > -1) and (fMouseOverIndex < Items.Count)
      and (Canvas.TextWidth(Items[fMouseOverIndex].Text) > Width) then
        ShowHint:= True
      else
        ShowHint:= False;
    end;//with
  end;//
end;//LazTVMousemove

{Keep track of the mouse position over the treeview when the wheel is used}
procedure TSearchResultsView.LazTVMouseWheel(Sender: TObject;
                                             Shift: TShiftState;
                                             WheelDelta: Integer;
                                             MousePos: TPoint;
                                             var Handled: Boolean);
begin
  LazTVMouseMove(Sender,Shift,MousePos.X, MousePos.Y);
  Handled:= false;
end;//LazTVMouseWheel

procedure TSearchResultsView.edSearchInListChange (Sender: TObject );
var CurrentTV: TLazSearchResultTV;
begin
 CurrentTV := GetTreeView(ResultsNoteBook.PageIndex);
 if Assigned(CurrentTV) then
  CurrentTV.SearchInListPhrases := SearchInListEdit.Text;
end;

procedure TSearchResultsView.ResultsNoteBookPageChanged (Sender: TObject );
var CurrentTV: TLazSearchResultTV;
begin
 CurrentTV := GetTreeView(ResultsNoteBook.PageIndex);
 if Assigned(CurrentTV) then
  SearchInListEdit.Text := CurrentTV.SearchInListPhrases;
end;

procedure TSearchResultsView.ForwardSearchButtonClick (Sender: TObject );
var CurrentTV: TLazSearchResultTV;
    slPhrases: TStrings;
    i, j, iCurrentIndex: Integer;
    S: string;
begin
 CurrentTV := GetTreeView(ResultsNoteBook.PageIndex);
 if Assigned(CurrentTV) then
  begin
   if (Length(SearchInListEdit.Text) = 0) then Exit;//No Search Phrases specified.
   if (CurrentTV.Items.Count <= 0) then Exit;
   slPhrases := TStringList.Create;
   try
     if Assigned(CurrentTV.Selected) then
      iCurrentIndex := CurrentTV.Selected.Index + 1
    else
      iCurrentIndex := 0;
    if (iCurrentIndex > CurrentTV.Items.Count) then iCurrentIndex := CurrentTV.Items.Count;
    if (iCurrentIndex < 0) then iCurrentIndex := 0;//Set to 1st list-item if none are selected
    //Parse Phrases
    Parse_Search_Phrases(slPhrases);
    if (slPhrases.Count > 0) then
     begin
      for i:=iCurrentIndex to CurrentTV.Items.Count-1 do
       begin
        S := UpperCase(CurrentTV.Items[i].Text);//for case-insensitive search
        for j:=0 to slPhrases.Count-1 do
         begin
          if (Pos(slPhrases[j], S) <> 0) then
           begin
            CurrentTV.Items[i].Selected:=True;//Set TreeView's itemindex
            Exit;//Found what we looking for, exit
           end;//End if (Pos(slPhrases[j], CurrentTV.Items[i]) <> 0)
         end;//End for-loop j
       end;//End for-loop i
     end;//End if if (slPhrases.Count > 0)
   finally
    FreeAndNil(slPhrases);
    SearchInListEdit.SetFocus;
   end;//End try-finally
  end;//End if Assigned(CurrentTV)
end;

procedure TSearchResultsView.ResetResultsButtonClick (Sender: TObject );
var
  i: Integer;
  CurrentTV: TLazSearchResultTV;
  mpMatchPos, mpOrgMatchPos: TLazSearchMatchPos;
begin
 CurrentTV := GetTreeView(ResultsNoteBook.PageIndex);
 try
  if assigned(CurrentTV) and CurrentTV.Filtered then
   begin
    if (CurrentTV.Items.Count > 0) then
     begin
      CurrentTV.FreeObjectsTN(CurrentTV.Items);//Free the objects
      CurrentTV.Items.Clear;
     end;//End if (CurrentTV.Items.Count > 0)

    if (CurrentTV.BackUpStrings.Count > 0) then
     begin
      CurrentTV.Items.BeginUpdate;
      for i:=0 to CurrentTV.BackUpStrings.Count-1 do
      begin
        mpOrgMatchPos := TLazSearchMatchPos(CurrentTV.BackUpStrings.Objects[i]);
        if Assigned(mpOrgMatchPos) then
        begin
          mpMatchPos := TLazSearchMatchPos.Create;
          if CopySearchMatchPos(mpOrgMatchPos, mpMatchPos) then
            CurrentTV.AddNode(CurrentTV.BackUpStrings[i], mpMatchPos);
        end;//End if Assigned(mpOrgMatchPos)
      end;//End for-loop i
    end;//End if (CurrentTV.BackUpStrings.Count > 0)
    CurrentTV.Items.EndUpdate;
    CurrentTV.Filtered := False;
   end;//End if CurrentTV.Filtered
 finally
  SearchInListEdit.SetFocus;
 end;//End try-finally
end;

procedure TSearchResultsView.SearchInListEditKeyDown (Sender: TObject;
 var Key: Word; Shift: TShiftState );
begin
 if (Key = VK_RETURN) then
  ForwardSearchButtonClick(ForwardSearchButton);
end;

procedure TSearchResultsView.FilterButtonClick (Sender: TObject );
var
  CurrentTV: TLazSearchResultTV;
  mpMatchPos, mpOrgMatchPos: TLazSearchMatchPos;
  slPhrases: TStrings;
  i, j: Integer;
  S: string;
begin
 CurrentTV := GetTreeView(ResultsNoteBook.PageIndex);
 if Assigned(CurrentTV) then
  begin
   if (Length(SearchInListEdit.Text) = 0) then Exit;//No Filter Phrases specified.
   slPhrases := TStringList.Create;
   try
    //Parse Phrases
    Parse_Search_Phrases(slPhrases);
    //BackUp Result List
    if not (CurrentTV.Filtered or (CurrentTV.BackUpStrings.Count > 0)) then
     begin
      if (CurrentTV.Items.Count <= 1) then Exit;
      for i:=0 to CurrentTV.Items.Count-1 do
       begin
        mpOrgMatchPos := TLazSearchMatchPos(CurrentTV.Items[i].Data);
        if Assigned(mpOrgMatchPos) then
         begin
          mpMatchPos := TLazSearchMatchPos.Create;
          if CopySearchMatchPos(mpOrgMatchPos, mpMatchPos) then
            CurrentTV.BackUpStrings.AddObject(CurrentTV.Items[i].Text, mpMatchPos);
         end;//End if Assigned(mpOrgMatchPos)
       end;//End for-loop i
     end;//End if not (CurrentTV.Filtered or (CurrentTV.BackUpStrings.Count > 0))
     
    if (CurrentTV.BackUpStrings.Count <= 0) then Exit;//Empty list

    if (CurrentTV.Items.Count > 0) then
     begin
      CurrentTV.FreeObjectsTN(CurrentTV.Items);//Free the objects
      CurrentTV.Items.Clear;//Clear the list
      //Clear update items as their objects are freed together with CurrentTV.Items
      CurrentTV.UpdateItems.Clear;
     end;//End if (CurrentTV.Items.Count > 0)

    if (slPhrases.Count > 0) then
    begin
      CurrentTV.Items.BeginUpdate;
      for i:=0 to CurrentTV.BackUpStrings.Count-1 do
       begin
        S := UpperCase(CurrentTV.BackUpStrings[i]);//for case-insensitive search
        for j:=0 to slPhrases.Count-1 do
        begin
          if (Pos(slPhrases[j], S) <> 0) then
          begin
            mpOrgMatchPos := TLazSearchMatchPos(CurrentTV.BackUpStrings.Objects[i]);
            if Assigned(mpOrgMatchPos) then
            begin
              mpMatchPos := TLazSearchMatchPos.Create;
              if CopySearchMatchPos(mpOrgMatchPos, mpMatchPos) then
                CurrentTV.AddNode(CurrentTV.BackUpStrings[i], mpMatchPos);
            end;//End if Assigned(mpOrgMatchPos)
          end;//End if (Pos(slPhrases[j], S) <> 0)
        end;//End for-loop j
      end;//End for-loop i
      CurrentTV.Items.EndUpdate;
      CurrentTV.Filtered := True;
     end;//End if if (slPhrases.Count > 0)
   finally
    FreeAndNil(slPhrases);
    SearchInListEdit.SetFocus;
    if (CurrentTV.Items.Count > 0) then CurrentTV.Items[0].Selected:=True;//Goto first item
   end;//End try-finally
  end;//End if Assigned(CurrentTV)
end;

function TSearchResultsView.BeautifyPageName(const APageName: string): string;
const
  MaxPageName = 25;
begin
  Result:=SpecialCharsToHex(APageName);
  if UTF8Length(Result)>MaxPageName then
    Result:=UTF8Copy(Result,1,15)+'...';
end;

procedure TSearchResultsView.AddMatch(const APageIndex: integer;
  const Filename: string; const StartPos, EndPos: TPoint;
  const TheText: string;
  const MatchStart: integer; const MatchLen: integer);
var
  CurrentTV: TLazSearchResultTV;
  SearchPos: TLazSearchMatchPos;
  ShownText: String;
  LastPos: TLazSearchMatchPos;
begin
  CurrentTV:=GetTreeView(APageIndex);
  if Assigned(CurrentTV) then
  begin
    if CurrentTV.UpdateState then begin
      if CurrentTV.UpdateItems.Count>=MaxItems then begin
        CurrentTV.Skipped:=CurrentTV.Skipped+1;
        exit;
      end;
    end else begin
      if CurrentTV.Items.Count>=MaxItems then begin
        CurrentTV.Skipped:=CurrentTV.Skipped+1;
        exit;
      end;
    end;

    SearchPos:= TLazSearchMatchPos.Create;
    SearchPos.MatchStart:=MatchStart;
    SearchPos.MatchLen:=MatchLen;
    SearchPos.Filename:=Filename;
    SearchPos.FileStartPos:=StartPos;
    SearchPos.FileEndPos:=EndPos;
    SearchPos.TheText:=TheText;
    SearchPos.ShownFilename:=SearchPos.Filename;
    ShownText:=CurrentTV.BeautifyLine(SearchPos);
    LastPos:=nil;
    if CurrentTV.UpdateState then begin
      if (CurrentTV.UpdateItems.Count>0) and (CurrentTV.UpdateItems.Objects[CurrentTV.UpdateItems.Count-1] is TLazSearchMatchPos) then
        LastPos:=TLazSearchMatchPos(CurrentTV.UpdateItems.Objects[CurrentTV.UpdateItems.Count-1]);
    end else
      if (CurrentTV.Items.Count>0) and Assigned(CurrentTV.Items[CurrentTV.Items.Count-1].Data) then
        LastPos:=TLazSearchMatchPos(CurrentTV.Items[CurrentTV.Items.Count-1].Data);
    if (LastPos<>nil) and (LastPos.Filename=SearchPos.Filename) and
       (LastPos.FFileStartPos.Y=SearchPos.FFileStartPos.Y) and
       (LastPos.FFileEndPos.Y=SearchPos.FFileEndPos.Y) then
    begin
      while (LastPos.NextInThisLine<>nil) do
        LastPos := LastPos.NextInThisLine;
      LastPos.NextInThisLine:=SearchPos
    end
    else if CurrentTV.UpdateState then
      CurrentTV.UpdateItems.AddObject(ShownText, SearchPos)
    else
      CurrentTV.AddNode(ShownText, SearchPos);
    CurrentTV.ShortenPaths;
  end;//if
end;//AddMatch

Procedure TSearchResultsView.BeginUpdate(APageIndex: integer);
var
  CurrentTV: TLazSearchResultTV;
begin
  CurrentTV:= GetTreeView(APageIndex);
  if Assigned(CurrentTV) then
    CurrentTV.BeginUpdate;
end;//BeginUpdate

procedure TSearchResultsView.EndUpdate(APageIndex: integer);
var
  CurrentTV: TLazSearchResultTV;
begin
  CurrentTV:= GetTreeView(APageIndex);
  if Assigned(CurrentTV) then
  begin
    CurrentTV.EndUpdate;
    if CurrentTV.Items.Count>0 then begin
      CurrentTV.Items[0].Selected:=True;
    end;
  end;
end;

procedure TSearchResultsView.Parse_Search_Phrases(var slPhrases: TStrings);
var i, iLength: Integer;
    sPhrases, sPhrase: string;
begin
 //Parse Phrases
 sPhrases := SearchInListEdit.Text;
 iLength := Length(sPhrases);
 sPhrase := '';
 for i:=1 to iLength do
  begin
   if ((sPhrases[i] = ' ') or (sPhrases[i] = ',') or (i = iLength)) then
    begin
     if not ((sPhrases[i] = ' ') or (sPhrases[i] = ',')) then
      sPhrase := sPhrase + sPhrases[i];
     if (sPhrase > ' ') then
      slPhrases.Add(UpperCase(sPhrase));//End of phrase, add to phrase list
     sPhrase := '';//Reset sPhrase
    end else
    begin
     if (sPhrases[i] > ' ') then
      sPhrase := sPhrase + sPhrases[i];
    end;//End if ((sPhrases[i] = ' ') or (sPhrases[i] = ','))
  end;//End for-loop i
end;

procedure TSearchResultsView.ClosePage(PageIndex: integer);
begin
  if (PageIndex<0) or (PageIndex>=ResultsNoteBook.Pages.Count) then exit;
  ResultsNoteBook.Pages.Delete(PageIndex);
  if ResultsNoteBook.Pages.Count = 0 then
    Hide;
end;

{Brings the results tab named APageName to front.
 If APageName does not exist, does nothing}
procedure TSearchResultsView.BringResultsToFront(const APageName: string);
begin
  if PageExists(APageName) then
  begin
    ResultsNoteBook.PageIndex:= GetPageIndex(APageName);
  end;//if
end;//BringResultsToFront

{Sets the Items from the treeview on the currently selected page in the
 TNoteBook}
procedure TSearchResultsView.SetItems(Index: integer; Value: TStrings);
var
  CurrentTV: TLazSearchResultTV;
begin
  if Index > -1 then
  begin
    CurrentTV:= GetTreeView(Index);
    if Assigned(CurrentTV) then
    begin
      if CurrentTV.UpdateState then
        CurrentTV.UpdateItems.Assign(Value)
      else
        CurrentTV.Items.Assign(Value);
      CurrentTV.Skipped:=0;
    end;//if
  end//if
end;//SetItems

function TSearchResultsView.GetItems(Index: integer): TStrings;
var
  CurrentTV: TLazSearchResultTV;
begin
  result:= nil;
  CurrentTV:= GetTreeView(Index);
  if Assigned(CurrentTV) then
  begin
    if CurrentTV.UpdateState then
      result:= CurrentTV.UpdateItems
    else
      Result := CurrentTV.ItemsAsStrings;
  end;//if
end;//GetItems

procedure TSearchResultsView.SetMaxItems(const AValue: integer);
begin
  if FMaxItems=AValue then exit;
  FMaxItems:=AValue;
end;

procedure TSearchResultsView.ResultsNoteBookCloseTabclicked(Sender: TObject);
begin
  if (Sender is TPage) then
  begin
    with Sender as TPage do
    begin
      ClosePage(PageIndex);
    end;//with
  end;//if
end;//ResultsNoteBookClosetabclicked

procedure TSearchResultsView.SearchAgainButtonClick(Sender: TObject);
var
  CurrentTV: TLazSearchResultTV;
  SearchObj: TLazSearch;
begin
  CurrentTV:= GetTreeView(ResultsNoteBook.PageIndex);
  if not Assigned(CurrentTV) then begin
    MainIDEInterface.FindInFilesPerDialog(Project1);
  end
  else begin
    SearchObj:= CurrentTV.SearchObject;
    if Assigned(FindInFilesDialog) then
    begin
      with FindInFilesDialog do
      begin
        DirectoryComboBox.Text:= SearchObj.SearchDirectory;
        Options:= SearchObj.SearchOptions;
        FileMaskComboBox.Text:= SearchObj.SearchMask;
      end;//with
      MainIDEInterface.FindInFiles(Project1, SearchObj.SearchString);
    end;//if
  end;
end;

{Searched the notebook control for a page with APageName name, returns true if
 found}
function TSearchResultsView.PageExists(const APageName: string): boolean;
var
  i: integer;
  CurPagename: String;
begin
  Result:= false;
  CurPagename:=BeautifyPageName(APageName);
  for i:= 0 to ResultsNoteBook.Pages.Count - 1 do
  begin
    if (ResultsNoteBook.Pages[i] = CurPageName) then
    begin
      Result:= true;
      exit;
    end;//if
  end;//for
end;//PageExists

procedure TSearchResultsView.TreeViewKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Key:=VK_UNKNOWN;
    Close;
  end
  else if (Key = VK_RETURN) and (Shift = []) then
  begin
    Key:=VK_UNKNOWN;
    FOnSelectionChanged(Self);
  end;
end;

{ Add Result will create a tab in the Results view window with an new
  treeview or focus an existing TreeView and update it's searchoptions.}
function TSearchResultsView.AddSearch(const ResultsName: string;
  const SearchText: string;
  const ReplaceText: string;
  const ADirectory: string;
  const AMask: string;
  const TheOptions: TLazFindInFileSearchOptions): integer;
var
  NewTreeView: TLazSearchResultTV;
  NewPage: LongInt;
  i: integer;
  SearchObj: TLazSearch;
  NewPageName: String;
begin
  Result:= -1;
  if Assigned(ResultsNoteBook) then
  begin
    NewPageName:=BeautifyPageName(ResultsName);
    //DebugLn(['TSearchResultsView.AddSearch NewPageName=',dbgstr(NewPageName),' ResultsName="',dbgstr(ResultsName),'"']);
    with ResultsNoteBook do
    begin
      i:= GetPageIndex(NewPageName);
      if i>=0 then
      begin
        NewTreeView:= GetTreeView(i);
        ResultsNoteBook.PageIndex:= i;
        //Free backup objects and list since its a new search with the same TreeView
        NewTreeView.FreeObjects(NewTreeView.BackUpStrings);
        NewTreeView.BackUpStrings.Clear;
        NewTreeView.Filtered := False;
      end//if
      else
      begin
        NewPage:= Pages.Add(NewPageName);
        ResultsNoteBook.PageIndex:= NewPage;
        ResultsNoteBook.Page[ResultsNoteBook.PageIndex].OnKeyDown := @TreeViewKeyDown;
        if NewPage > -1 then
        begin
          NewTreeView:= TLazSearchResultTV.Create(Page[NewPage]);
          with NewTreeView do
          begin
            Parent:= Page[NewPage];
            Align:= alClient;
            BorderSpacing.Around := 0;
            OnClick:= @TreeViewClicked;
            OnDblClick:= @TreeViewDoubleClicked;
            OnKeyDown := @TreeViewKeyDown;
            OnAdvancedCustomDrawItem:= @TreeViewAdvancedCustomDrawItem;
            OnShowHint:= @LazTVShowHint;
            OnMouseMove:= @LazTVMousemove;
            OnMouseWheel:= @LazTVMouseWheel;
            ShowHint:= true;
            RowSelect := True;
            NewTreeView.Canvas.Brush.Color:= clWhite;
          end;//with
        end;//if
      end;//else
    end;//with
    SearchObj:=NewTreeView.SearchObject;
    if SearchObj<>nil then begin
      SearchObj.SearchString:= SearchText;
      SearchObj.ReplaceText := ReplaceText;
      SearchObj.SearchDirectory:= ADirectory;
      SearchObj.SearchMask:= AMask;
      SearchObj.SearchOptions:= TheOptions;
    end;
    NewTreeView.Skipped:=0;
    Result:= ResultsNoteBook.PageIndex;
    SearchInListEdit.Clear;
  end;//if
end;//AddResult

procedure TSearchResultsView.LazTVShowHint(Sender: TObject;
  HintInfo: PHintInfo);
var
  MatchPos: TLazSearchMatchPos;
  HintStr: string;
begin
  if Sender is TLazSearchResultTV then
  begin
    With Sender as TLazSearchResultTV do
    begin
      if (fMouseOverIndex >= 0) and (fMouseOverIndex < Items.Count) then
      begin
        if Assigned(Items[fMouseOverIndex].Data) then
          MatchPos:= TLazSearchMatchPos(Items[fMouseOverIndex].Data)
        else
          MatchPos:= nil;
        if MatchPos<>nil then
          HintStr:=MatchPos.Filename
                   +' ('+IntToStr(MatchPos.FileStartPos.Y)
                   +','+IntToStr(MatchPos.FileStartPos.X)+')'
                   +' '+MatchPos.TheText
        else
          HintStr:=Items[fMouseOverIndex].Text;
        Hint:= HintStr;
      end;//if
    end;//with
  end;//if
end;//LazTVShowHint

procedure TSearchResultsView.TreeViewAdvancedCustomDrawItem(
  Sender: TCustomTreeView; Node: TTreeNode; State: TCustomDrawState;
  Stage: TCustomDrawStage; var PaintImages, DefaultDraw: Boolean);
var
  CurPart: string;
  TheText: string;
  TheTop: integer;
  MatchObj: TObject;
  MatchPos,FirstMatchPos: TLazSearchMatchPos;

  TextEnd, DrawnTextLength: integer;
  ARect: TRect;
begin
  With Sender as TLazSearchResultTV do
  begin
    ARect:=Node.DisplayRect(true);
    Canvas.FillRect(ARect);
    MatchObj := TLazSearchMatchPos(Node.Data);
    if assigned(MatchObj) and (MatchObj is TLazSearchMatchPos) then
      MatchPos:= TLazSearchMatchPos(Node.Data)
    else
      MatchPos:= nil;

    if Assigned(MatchPos) then
    begin
      FirstMatchPos:=MatchPos;
      TheTop:= ARect.Top;
      TextEnd:=ARect.Left;
      DrawnTextLength:=0;

      CurPart:=MatchPos.ShownFilename+' ('+IntToStr(MatchPos.FileStartPos.Y)
          +':'+IntToStr(MatchPos.FileStartPos.X);
      MatchPos:=MatchPos.NextInThisLine;
      while assigned(MatchPos) do begin
        CurPart:=CurPart+','+IntToStr(MatchPos.FileStartPos.X);
        MatchPos:=MatchPos.NextInThisLine;
      end;
      CurPart:=CurPart+') ';
      Canvas.TextOut(TextEnd, TheTop, CurPart);
      TextEnd:= TextEnd + Canvas.TextWidth(CurPart);

      MatchPos:=FirstMatchPos;
      while assigned(MatchPos) do begin
        CurPart:=SpecialCharsToHex(copy(MatchPos.TheText,DrawnTextLength+1,MatchPos.MatchStart-1-DrawnTextLength));
        DrawnTextLength:=MatchPos.MatchStart-1;
        Canvas.TextOut(TextEnd, TheTop, CurPart);
        TextEnd:= TextEnd + Canvas.TextWidth(CurPart);

        CurPart:=SpecialCharsToHex(copy(MatchPos.TheText,DrawnTextLength+1,MatchPos.MatchLen));
        DrawnTextLength:=DrawnTextLength+MatchPos.MatchLen;
        if UTF8Length(CurPart)>MaxTextLen then
          CurPart:=UTF8Copy(CurPart,1,MaxTextLen)+'...';
        Canvas.Font.Style:= Canvas.Font.Style + [fsBold];
        Canvas.TextOut(TextEnd, TheTop, CurPart);
        TextEnd:= TextEnd + Canvas.TextWidth(CurPart);
        Canvas.Font.Style:= Canvas.Font.Style - [fsBold];

        if MatchPos.NextInThisLine=nil then begin
          CurPart:=SpecialCharsToHex(copy(MatchPos.TheText, DrawnTextLength+1,Length(MatchPos.TheText)));
          Canvas.TextOut(TextEnd, TheTop, CurPart);
        end;
        MatchPos:=MatchPos.NextInThisLine;
      end;
    end//if
    else
    begin
      TheText:=Node.Text;
      Canvas.TextOut(ARect.Left, ARect.Top, TheText);
    end;//else
  end;//with
end;//TreeViewDrawItem

procedure TSearchResultsView.TreeViewClicked(Sender: TObject);
begin
  if EnvironmentOptions.MsgViewDblClickJumps then exit;
  if Assigned(fOnSelectionChanged) then
    fOnSelectionChanged(Self)
end;//TreeViewClicked

procedure TSearchResultsView.TreeViewDoubleClicked(Sender: TObject);
begin
  if not EnvironmentOptions.MsgViewDblClickJumps then exit;
  if Assigned(fOnSelectionChanged) then
    fOnSelectionChanged(Self)
end;//TreeViewDoubleClicked

{Returns the Position within the source file from a properly formated search
 result}
function TSearchResultsView.GetSourcePositon: TPoint;
var
  MatchPos: TLazSearchMatchPos;
begin
  Result.x:= -1;
  Result.y:= -1;
  MatchPos:=GetSelectedMatchPos;
  if MatchPos=nil then exit;
  Result:=MatchPos.FileStartPos;
end;//GetSourcePositon

{Returns The file name portion of a properly formated search result}
function TSearchResultsView.GetSourceFileName: string;
var
  MatchPos: TLazSearchMatchPos;
begin
  MatchPos:=GetSelectedMatchPos;
  if MatchPos=nil then
    Result:=''
  else
    Result:=MatchPos.Filename;
end;//GetSourceFileName

{Returns the selected text in the currently active TreeView.}
function TSearchResultsView.GetSelectedText: string;
var
  ThePage: TPage;
  TheTreeView: TLazSearchResultTV;
  i: integer;
begin
  result:= '';
  i:= ResultsNoteBook.PageIndex;
  if i > -1 then
  begin
    ThePage:= ResultsNoteBook.Page[i];
    if Assigned(ThePage) then
    begin
      TheTreeView:= GetTreeView(ThePage.PageIndex);
      if Assigned(TheTreeView.Selected) then
        Result:= TheTreeView.Selected.Text;
    end;//if
  end;//if
end;//GetSelectedText

function TSearchResultsView.GetSelectedMatchPos: TLazSearchMatchPos;
var
  ThePage: TPage;
  TheTreeView: TLazSearchResultTV;
  i: integer;
begin
  Result:= nil;
  i:= ResultsNoteBook.PageIndex;
  if i > -1 then
  begin
    ThePage:= ResultsNoteBook.Page[i];
    if Assigned(ThePage) then
    begin
      TheTreeView:= GetTreeView(ThePage.PageIndex);
      if Assigned(TheTreeView.Selected) then
        Result := TLazSearchMatchPos(TheTreeView.Selected.Data);
    end;//if
  end;//if
end;

function TSearchResultsView.GetPageIndex(const APageName: string): integer;
var
  i: integer;
  CurPagename: String;
begin
  Result:= -1;
  CurPagename:=BeautifyPageName(APageName);
  for i:= 0 to ResultsNoteBook.Pages.Count - 1 do
  begin
    if (ResultsNoteBook.Pages[i] = CurPageName) then
    begin
      Result:= i;
      break;
    end;//if
  end;//for
end;//GetPageIndex

{Returns a the TreeView control from a Tab if both the page and the TreeView
 exist else returns nil}
function TSearchResultsView.GetTreeView(APageIndex: integer): TLazSearchResultTV;
var
  i: integer;
  ThePage: TPage;
begin
  Result:= nil;
  if (APageIndex > -1) and (APageIndex < ResultsNoteBook.Pages.Count) then
  begin
    ThePage:= ResultsNoteBook.Page[APageIndex];
    if Assigned(ThePage) then
    begin
      for i:= 0 to ThePage.ComponentCount - 1 do
      begin
        if ThePage.Components[i] is TLazSearchResultTV then
        begin
          result:= TLazSearchResultTV(ThePage.Components[i]);
          break;
        end;//if
      end;//for
    end;//if
  end;//if
end;//GetTreeView

procedure TLazSearchResultTV.SetSkipped(const AValue: integer);
var
  SrcList: TStrings;
  s: String;
  HasSkippedLine: Boolean;
  SkippedLine: String;
begin
  if FSkipped=AValue then exit;
  FSkipped:=AValue;
  s:=rsFoundButNotListedHere;
  if fUpdating then
    SrcList:=fUpdateStrings
  else
    SrcList:=ItemsAsStrings;
  if (SrcList.Count>0) and (copy(SrcList[SrcList.Count-1],1,length(s))=s) then
    HasSkippedLine:=true
  else
    HasSkippedLine:=false;
  SkippedLine:=s+IntToStr(FSkipped);
  if FSkipped>0 then begin
    if HasSkippedLine then begin
      SrcList[SrcList.Count-1]:=SkippedLine;
    end else begin
      SrcList.add(SkippedLine);
    end;
  end else begin
    if HasSkippedLine then
      SrcList.Delete(SrcList.Count-1);
  end;
end;

procedure TLazSearchResultTV.AddNode(Line: string; MatchPos: TLazSearchMatchPos);
var
  Node: TTreeNode;
begin
  Node := Items.FindNodeWithText(MatchPos.FileName);

  //enter a new file entry
  if not Assigned(Node) then
    Node := Items.AddFirst(Node, MatchPos.FileName);

  Node := Items.AddChildFirst(Node, Line);
  Node.Data := MatchPos;
end;

{******************************************************************************
  TLazSearchResultTV
******************************************************************************}
Constructor TLazSearchResultTV.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fSearchObject:= TLazSearch.Create;
  fUpdating:= false;
  fUpdateCount:= 0;
  fUpdateStrings:= TStringList.Create;
  fBackUpStrings := TStringList.Create;
  FSearchInListPhrases := '';
  fFiltered := False;
end;//Create

Destructor TLazSearchResultTV.Destroy;
begin
  if Assigned(fSearchObject) then
    FreeAndNil(fSearchObject);
  //if UpdateStrings is empty,
  //means the objects are stored in Items due to filtering
  //filtering clears UpdateStrings
  if (fUpdateStrings.Count = 0) then
   FreeObjectsTN(Items);
  if Assigned(fUpdateStrings) then
  begin
    FreeObjects(fUpdateStrings);
    FreeAndNil(fUpdateStrings);
  end;//if
  if Assigned(fBackUpStrings) then
  begin
   FreeObjects(fBackUpStrings);
   FreeAndNil(fBackUpStrings);
  end;//End if Assigned(fBackUpStrings)
  inherited Destroy;
end;//Destroy

procedure TLazSearchResultTV.BeginUpdate;
var
  s: TStrings;
begin
  inc(fUpdateCount);
  if (fUpdateCount = 1) then
  begin
    if Assigned(Items) then
    begin
      s := ItemsAsStrings;
      fUpdateStrings.Assign(s);
      s.Free;
    end;
    fUpdating:= true;
  end;//if
end;//BeginUpdate

procedure TLazSearchResultTV.EndUpdate;
var
  i: integer;
begin
  if (fUpdateCount = 0) then
    RaiseGDBException('TLazSearchResultTV.EndUpdate');

  Dec(fUpdateCount);
  if (fUpdateCount = 0) then
  begin
    ShortenPaths;
    fUpdating:= false;
    FreeObjectsTN(Items);

    Items.BeginUpdate;

    for i := 0 to fUpdateStrings.Count - 1 do
      AddNode(fUpdateStrings[i], TLazSearchMatchPos(fUpdateStrings.Objects[i]));

    Items.EndUpdate;
  end;//if
end;//EndUpdate

procedure TLazSearchResultTV.ShortenPaths;
var
  i: Integer;
  AnObject: TObject;
  SharedPath: String;
  MatchPos: TLazSearchMatchPos;
  SrcList: TStrings;
  SharedLen: Integer;
  ShownText: String;
begin
  if fUpdateCount>0 then begin
    fShortenPathNeeded:=true;
    exit;
  end;
  fShortenPathNeeded:=false;
  
  if fUpdating then
    SrcList:=fUpdateStrings
  else
    SrcList:=ItemsAsStrings;
  
  // find shared path (the path of all filenames, that is the same)
  SharedPath:='';
  for i:=0 to SrcList.Count-1 do begin
    AnObject:=SrcList.Objects[i];
    if AnObject is TLazSearchMatchPos then begin
      MatchPos:=TLazSearchMatchPos(AnObject);
      if i=0 then
        SharedPath:=ExtractFilePath(MatchPos.Filename)
      else if (SharedPath<>'') then begin
        SharedLen:=0;
        while (SharedLen<length(MatchPos.Filename))
        and (SharedLen<length(SharedPath))
        and (MatchPos.Filename[SharedLen+1]=SharedPath[SharedLen+1])
        do
          inc(SharedLen);
        while (SharedLen>0) and (SharedPath[SharedLen]<>PathDelim) do
          dec(SharedLen);
        if SharedLen<>length(SharedPath) then
          SharedPath:=copy(SharedPath,1,SharedLen);
      end;
    end;
  end;
  
  // shorten shown paths
  SharedLen:=length(SharedPath);
  for i:=0 to SrcList.Count-1 do begin
    AnObject:=SrcList.Objects[i];
    if AnObject is TLazSearchMatchPos then begin
      MatchPos:=TLazSearchMatchPos(AnObject);
      MatchPos.ShownFilename:=copy(MatchPos.Filename,SharedLen+1,
                                   length(MatchPos.Filename));
      ShownText:=BeautifyLine(MatchPos);
      SrcList[i]:=ShownText;
      SrcList.Objects[i]:=MatchPos;
    end;
  end;
end;

procedure TLazSearchResultTV.FreeObjectsTN(tnItems: TTreeNodes);
var i: Integer;
begin
 for i:=0 to tnItems.Count-1 do
   if Assigned(tnItems[i].Data) then
    TLazSearchMatchPos(tnItems[i].Data).Free;
end;

procedure TLazSearchResultTV.FreeObjects(slItems: TStrings);
var i: Integer;
begin
 if (slItems.Count <= 0) then Exit;
 for i:=0 to slItems.Count-1 do
  begin
   if Assigned(slItems.Objects[i]) then
    slItems.Objects[i].Free;
  end;//End for-loop
end;

function TLazSearchResultTV.BeautifyLine(const Filename: string; X, Y: integer;
  const Line: string): string;
begin
  Result:=SpecialCharsToHex(Line);
  if UTF8Length(Result)>MaxTextLen then
    Result:=UTF8Copy(Result,1,MaxTextLen)+'...';
  Result:=Filename
          +' ('+IntToStr(Y)
          +','+IntToStr(X)+')'
          +' '+Result;
end;

function TLazSearchResultTV.BeautifyLine(SearchPos: TLazSearchMatchPos
  ): string;
begin
  Result:=BeautifyLine(SearchPos.ShownFilename,SearchPos.FileStartPos.X,
                       SearchPos.FileStartPos.Y,SearchPos.TheText);
end;

function TLazSearchResultTV.ItemsAsStrings: TStrings;
var
  i: integer;
begin
  Result := TStringList.Create;

  for i := 0 to Items.Count - 1 do
    Result.Add(Items[i].Text);
end;

{ TLazSearchMatchPos }

destructor TLazSearchMatchPos.Destroy;
begin
  FreeAndNil(FNextInThisLine);
  inherited Destroy;
end;

initialization
  {$I searchresultview.lrs}

end.

