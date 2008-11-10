{
 *****************************************************************************
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
unit ObjInspStrConsts;

{$mode objfpc}{$H+}

interface

resourcestring

  // Object Inspector
  oisObjectInspector = 'Object Inspector';
  oisAll = 'All';
  oisError = 'Error';
  oisItemsSelected = '%u items selected';
  
  oiscAdd = '&Add';
  oiscDelete = '&Delete';
  oisConfirmDelete = 'Confirm delete';
  oisDeleteItem = 'Delete item %s%s%s?';
  oisUnknown = 'Unknown';
  oisObject = 'Object';
  oisClass = 'Class';
  oisWord = 'Word';
  oisString = 'String';
  oisFloat = 'Float';
  oisSet = 'Set';
  oisMethod = 'Method';
  oisVariant = 'Variant';
  oisArray = 'Array';
  oisRecord = 'Record';
  oisInterface = 'Interface';

  oisProperties='Properties';
  oisEvents='Events';
  oisFavorites = 'Favorites';
  oisRestricted = 'Restricted';
  
  oisWidgetSetRestrictions = 'General widget set restrictions: ';
  oisComponentRestrictions = 'Component restrictions: ';

  
  //Object Inspector Popup Menu
  oisSetToDefault = 'Set to default: %s';
  oisSetToDefaultValue = 'Set to default value';
  oisAddToFavorites = 'Add to Favorites';
  oisViewRestrictedProperties = 'View restricted properties';
  oisRemoveFromFavorites = 'Remove from Favorites';
  oisUndo = 'Undo';
  oisFinddeclaration = 'Jump to declaration';
  oisCutComponents = 'Cut components';
  oisCopyComponents = 'Copy components';
  oisPasteComponents = 'Paste components';
  oisDeleteComponents = 'Delete components';
  oisDelete = 'Delete';
  rscdMoveUp = 'Move up';
  rscdMoveDown = 'Move down';
  rscdOK = 'OK';
  oisShowHints = 'Show Hints';
  oisShowComponentTree = 'Show Component Tree';
  oisOptions = 'Options';

  
  // typeinfo
  oisValue = 'Value:';
  oisInteger = 'Integer';
  oisInt64 = 'Int64';
  oisBoolean = 'Boolean';
  oisEnumeration = 'Enumeration';
  oisChar = 'Char';
  
  // TreeView Items Editor
  sccsTrEdtCaption         = 'TreeView Items Editor';
  sccsTrEdt                = 'Edit TreeView Items...';
  sccsTrEdtGrpLCaption     = 'Items';
  sccsTrEdtGrpRCaption     = 'Item Properties';
  sccsTrEdtNewItem         = 'New Item';
  sccsTrEdtNewSubItem      = 'New SubItem';
  sccsTrEdtDelete          = 'Delete';
  sccsTrEdtApply           = 'Apply';
  sccsTrEdtLoad            = 'Load';
  sccsTrEdtSave            = 'Save';
  sccsTrEdtLabelText       = 'Text:';
  sccsTrEdtLabelImageIndex = 'Image Index:';
  sccsTrEdtLabelSelIndex   = 'Selected Index:';
  sccsTrEdtLabelStateIndex = 'State Index:';
  sccsTrEdtItem            = 'Item';
  sccsTrEdtOpenDialog      = 'Open';
  sccsTrEdtSaveDialog      = 'Save';

  // ListView Items Editor
  sccsLvEdtCaption         = 'ListView Items Editor';
  sccsLvEdt                = 'Edit ListView Items...';
  sccsLvColEdt             = 'Edit Columns ...';
  sccsLvEdtGrpLCaption     = 'Items';
  sccsLvEdtGrpRCaption     = 'Item Properties';
  sccsLvEdtNewItem         = 'New Item';
  sccsLvEdtNewSubItem      = 'New SubItem';
  sccsLvEdtApply           = 'Apply';
  sccsLvEdtDelete          = 'Delete';
  sccsLvEdtLabelCaption    = 'Caption:';
  sccsLvEdtLabelImageIndex = 'Image Index:';
  sccsLvEdtLabelStateIndex = 'State Index:';
  sccsLvEdtItem            = 'Item';

  // Image editor strings
  sccsILEdtCaption     = 'ImageList Editor';
  sccsILEdtGrpLCaption = 'Images';
  sccsILEdtGrpRCaption = 'Selected Image';
  sccsILEdtAdd         = 'Add...';
  sccsILEdtDelete      = 'Delete';
  sccsILEdtApply       = 'Apply';
  sccsILEdtClear       = 'Clear';
  sccsILEdtMoveUp      = 'Move Up';
  sccsILEdtMoveDown    = 'Move Down';
  sccsILEdtSave        = 'Save...';
  sccsILEdtSaveAll     = 'Save All...';
  sccsILEdtransparentColor = 'Transparent Color:';
  sccsILEdtAdjustment  = 'Adjustment';
  sccsILEdtNone        = 'None';
  sccsILEdtStretch     = 'Stretch';
  sccsILEdtCrop        = 'Crop';
  sccsILEdtCenter      = 'Center';
  rscdRight = 'Right';
  rscdVisible = 'Visible';
  rscdAutoSize = 'Auto Size';
  sccsILEdtOpenDialog  = 'Add Images';
  sccsILEdtSaveDialog  = 'Save Image';
  
  // StringGrid Editor
  sccsSGEdt           = 'Edit StringGrid...';
  sccsSGEdtCaption    = 'StringGrid Editor';
  sccsSGEdtGrp        = 'String Grid';
  sccsSGEdtApply      = 'Apply';
  sccsSGEdtClean      = 'Clean';
  sccsSGEdtLoad       = 'Load...';
  sccsSGEdtSave       = 'Save...';
  sccsSGEdtOpenDialog = 'Open';
  sccsSGEdtSaveDialog = 'Save';
  sccsSGEdtMoveRowsCols = 'Move Rows/Cols';

  // HeaderControl Editor
  sccsHCEditSections  = 'Sections Editor ...';

  // StatusBar Editor
  sccsSBEditPanels    = 'Panels Editor ...';

  // component editors
  nbcesAddPage  = 'Add page';
  nbcesInsertPage = 'Insert page';
  nbcesDeletePage = 'Delete page';
  nbcesMovePageLeft = 'Move page left';
  nbcesMovePageRight = 'Move page right';
  nbcesShowPage = 'Show page ...';
  oisCreateDefaultEvent = 'Create default event';
  tccesAddTab  = 'Add tab';
  tccesInsertTab = 'Insert tab';
  tccesDeleteTab = 'Delete tab';
  tccesMoveTabLeft = 'Move tab left';
  tccesMoveTabRight = 'Move tab right';

  //checklistbox editor
  clbCheckListBoxEditor = 'CheckListBox Editor';
  clbUp = 'Up';
  clbDown = 'Down';
  clbModify = 'Modify the Item';
  clbAdd = 'Add new Item';
  clbDeleteHint = 'Delete the Item';
  clbDeleteQuest = 'Delete the Item %d "%s"?';

  //checkgroup editor
  cgCheckGroupEditor = 'CheckGroup Editor';
  cgDisable = 'Popup to disable/enable items';
  cgColumns = 'Columns:';
  cgCheckDuplicate = 'On Add, Check for Duplicate in Items';
  cgCheckDuplicateMsg = 'The "%s" Item is already listed. Add it anyway?';

  // Collection Editor

  oiColEditAdd = 'Add';
  oiColEditDelete = 'Delete';
  oiColEditUp = 'Up';
  oiColEditDown = 'Down';
  oiColEditEditing = 'Editing';

  // Actions Editor
  cActionListEditorUnknownCategory = '(Unknown)';
  cActionListEditorAllCategory = '(All)';
  cActionListEditorEditCategory = 'Edit';
  cActionListEditorSearchCategory = 'Search';
  cActionListEditorHelpCategory = 'Help';
  oisCategory = 'Category';
  oisAction = 'Action';
  oisMasks = 'Masks...';
  oisSaveLiteralCharacters = 'Save Literal Characters';
  oisInputMask = 'Input Mask:';
  oisSampleMasks = 'Sample Masks:';
  oisCharactersForBlanks = 'Characters for Blanks';
  oisTestInput = 'Test Input';
  oisOpenMaskFile = 'Open masks file (*.dem)';
  cActionListEditorDialogCategory = 'Dialog';
  cActionListEditorFileCategory = 'File';
  cActionListEditorDatabaseCategory = 'Database';
  
  oisEditActionList = 'Edit action list...';
  oisActionListEditor = 'Action List Editor';
  cActionListEditorNewAction = 'New Action';
  cActionListEditorNewStdAction = 'New Standard Action';
  cActionListEditorMoveDownAction = 'Move Down';
  ilesAdd = 'Add';
  cActionListEditorMoveUpAction = 'Move Up';
  cActionListEditorDeleteActionHint = 'Delete Action';
  cActionListEditorDeleteAction = 'Delete';
  cActionListEditorPanelDescrriptions = 'Panel Descriptions';
  cActionListEditorPanelToolBar = 'Toolbar';

  oiStdActEditCutHeadLine = 'Cu&t';
  oiStdActEditCopyHeadLine = '&Copy';
  oiStdActEditPasteHeadLine = '&Paste';
  oiStdActEditSelectAllHeadLine = 'Select &All';
  oiStdActEditUndoHeadLine = '&Undo';
  oiStdActEditDeleteHeadLine = '&Delete';
  oiStdActSearchFindHeadLine = '&Find...';
  oiStdActSearchFindFirstHeadLine = 'F&ind First';
  oiStdActSearchFindNextHeadLine = 'Find &Next';
  oiStdActSearchReplaceHeadLine = '&Replace';
  oiStdActHelpContentsHeadLine = '&Contents';
  oiStdActHelpTopicSearchHeadLine = '&Topic Search';
  oiStdActHelpHelpHelpHeadLine = '&Help on Help';
  oiStdActFileOpenHeadLine = '&Open...';
  oiStdActFileOpenWithHeadLine = 'Open with...';
  oiStdActFileSaveAsHeadLine = 'Save &As...';
  oiStdActFileExitHeadLine = 'E&xit';
  oiStdActColorSelect1HeadLine = 'Select &Color...';
  oiStdActFontEditHeadLine = 'Select &Font...';

  oiStdActDataSetFirstHeadLine = '&First';
  oiStdActDataSetPriorHeadLine = '&Prior';
  oiStdActDataSetNextHeadLine = '&Next';
  oiStdActDataSetLastHeadLine = '&Last';
  oiStdActDataSetInsertHeadLine = '&Insert';
  oiStdActDataSetDeleteHeadLine = '&Delete';
  oiStdActDataSetEditHeadLine = '&Edit';
  oiStdActDataSetPostHeadLine = 'P&ost';
  oiStdActDataSetCancelHeadLine = '&Cancel';
  oiStdActDataSetRefreshHeadLine = '&Refresh';

  oiStdActEditCutShortCut = 'Ctrl+X';
  oiStdActEditCopyShortCut = 'Ctrl+C';
  oiStdActEditPasteShortCut = 'Ctrl+V';
  oiStdActEditSelectAllShortCut = 'Ctrl+A';
  oiStdActEditUndoShortCut = 'Ctrl+Z';
  oiStdActEditDeleteShortCut = 'Del';
  oiStdActSearchFindShortCut = 'Ctrl+F';
  oiStdActSearchFindNextShortCut = 'F3';
  oiStdActFileOpenShortCut = 'Ctrl+O';

  oiStdActEditCutShortHint = 'Cut';
  oiStdActEditCopyShortHint = 'Copy';
  oiStdActEditPasteShortHint = 'Paste';
  oiStdActEditSelectAllShortHint = 'Select All';
  oiStdActEditUndoShortHint = 'Undo';
  oiStdActEditDeleteShortHint = 'Delete';
  oiStdActSearchFindHint = 'Find';
  oiStdActSearchFindFirstHint = 'Find first';
  oiStdActSearchFindNextHint = 'Find next';
  oiStdActSearchReplaceHint = 'Replace';
  oiStdActHelpContentsHint = 'Help Contents';
  oiStdActHelpTopicSearchHint = 'Topic Search';
  oiStdActHelpHelpHelpHint = 'Help on help';
  oiStdActFileOpenHint = 'Open';
  oiStdActFileOpenWithHint = 'Open with';
  oiStdActFileSaveAsHint = 'Save As';
  oiStdActFileExitHint = 'Exit';
  oiStdActColorSelectHint = 'Color Select';
  oiStdActFontEditHint = 'Font Select';
  oiStdActDataSetFirstHint = 'First';
  oiStdActDataSetPriorHint = 'Prior';
  oiStdActDataSetNextHint = 'Next';
  oiStdActDataSetLastHint = 'Last';
  oiStdActDataSetInsertHint = 'Insert';
  oiStdActDataSetDeleteHint = 'Delete';
  oiStdActDataSetEditHint = 'Edit';
  oiStdActDataSetPostHint = 'Post';
  oiStdActDataSetCancel1Hint = 'Cancel';
  oisComponents = 'Components';
  oiStdActDataSetRefreshHint = 'Refresh';
  
  oisStdActionListEditor = 'Standard Action Classes';
  oisStdActionListEditorClass = 'Available Action Classes:';

  // TFileNamePropertyEditor
  oisSelectAFile = 'Select a file';
  oisPropertiesOf = 'Properties of %s';
  oisAllFiles = 'All files';
  
  // TCommonDialogComponentEditor
  oisTestDialog = 'Test dialog...';

  // property editors
  oisSort = 'Sort';
  oisDLinesDChars = '%d lines, %d chars';
  ois1LineDChars = '1 line, %d chars';
  oisStringsEditorDialog = 'Strings Editor Dialog';
  ois0Lines0Chars = '0 lines, 0 chars';
  oisInvalidPropertyValue = 'Invalid property value';
  oisNone = '(none)';
  oisSelectShortCut = 'Select short cut';
  srGrabKey = 'Grab key';
  oisComponentNameIsNotAValidIdentifier = 'Component name %s%s%s is not a '
    +'valid identifier';
  oisLoadImageDialog = 'Load Image Dialog';
  oisOK = '&OK';
  oisPEPicture = 'Picture';
  oisCancel = '&Cancel';
  oisLoadPicture = 'Load picture';
  oisSavePicture = 'Save picture';
  oisClearPicture = 'Clear picture';
  oisLoad = '&Load';
  oisSave = '&Save';
  oisClear = 'C&lear';
  oisPEOpenImageFile = 'Open image file';
  oisPESaveImageAs = 'Save image as';
  oisErrorLoadingImage = 'Error loading image';
  oisErrorLoadingImage2 = 'Error loading image %s%s%s:%s%s';
  oisOk2 = 'Ok';
  oisCreateANewPascalUnit = 'Create a new pascal unit.';
  rscdColumnEditor = 'Column Editor';
  rscdCaption = 'Caption';
  rscdInvalidNumericValue = 'Invalid numeric Value';
  rscdWidth = 'Width';
  rscdAlignment = 'Alignment';
  rscdLeft = 'Left';

  // image list editor
  s_SuggestSplitImage = 'Do you want to split the image?';
  s_AddAsSingle = 'Add as single';
  s_SplitImage = 'Split image';
  
  // Fields Editor
  fesFeTitle = 'Edit Fields';
  fesNoFields = 'It was not possible to get the dataset field''s list';
  fesCheckDset = 'Check dataset settings';
  fesFlTitle = 'FieldDefs';
  fesNoFieldsNote = 'Field''s list is not available, can''t check for duplicates';
  oisIncompatibleIdentifier = 'Incompatible Identifier';
  oisTheIdentifierIsNotAMethodPressCancelToUndoPressIgn = 'The identifier %s%'
    +'s%s is not a method.%sPress Cancel to undo,%spress Ignore to force it.';
  oisIncompatibleMethod = 'Incompatible Method';
  oisTheMethodIsNotPublishedPressCancelToUndoPressIgnor = 'The method %s%s%s '
    +'is not published.%sPress Cancel to undo,%spress Ignore to force it.';
  oisTheMethodIsIncompatibleToThisEventPressCancelToUnd = 'The method %s%s%s '
    +'is incompatible to this event (%s).%sPress Cancel to undo,%spress '
    +'Ignore to force it.';
  peFilterEditor = 'Filter editor';
  peFilterName = 'Filter name';
  peFilter = 'Filter';
  
  //Key strings
  srVK_UNKNOWN    = 'Unknown';
  srVK_LBUTTON    = 'Mouse Button Left';
  srVK_RBUTTON    = 'Mouse Button Right';
  //srVK_CANCEL     = 'Cancel'; = dlgCancel
  srVK_MBUTTON    = 'Mouse Button Middle';
  srVK_BACK       = 'Backspace';
  srVK_TAB        = 'Tab';
  srVK_CLEAR      = 'Clear';
  srVK_RETURN     = 'Return';
  srVK_SHIFT      = 'Shift';
  srVK_CONTROL    = 'Control';
  srVK_SUPER      = 'Super';
  srVK_META       = 'Meta';
  srVK_CMD        = 'Cmd';
  srVK_MENU       = 'Menu';
  srVK_PAUSE      = 'Pause key';
  srVK_CAPITAL    = 'Capital';
  srVK_KANA       = 'Kana';
  srVK_JUNJA      = 'Junja';
  srVK_FINAL      = 'Final';
  srVK_HANJA      = 'Hanja';
  srVK_ESCAPE     = 'Escape';
  srVK_CONVERT    = 'Convert';
  srVK_NONCONVERT = 'Nonconvert';
  srVK_ACCEPT     = 'Accept';
  srVK_MODECHANGE = 'Mode Change';
  srVK_SPACE      = 'Space key';
  srVK_PRIOR      = 'Prior';
  srVK_NEXT       = 'Next';
  srVK_END        = 'End';
  srVK_HOME       = 'Home';
  srVK_LEFT       = 'Left';
  srVK_UP         = 'Up';
  srVK_RIGHT      = 'Right';
  //srVK_DOWN       = 'Down'; = dlgdownword
  //srVK_SELECT     = 'Select'; = lismenuselect
  srVK_PRINT      = 'Print';
  srSelect = 'Select';
  srVK_EXECUTE    = 'Execute';
  srVK_SNAPSHOT   = 'Snapshot';
  srVK_INSERT     = 'Insert';
  //srVK_DELETE     = 'Delete'; dlgeddelete
  srVK_HELP       = 'Help';
  srVK_LWIN       = 'left windows key';
  srVK_RWIN       = 'right windows key';
  srVK_APPS       = 'application key';
  srVK_NUMPAD     = 'Numpad %d';
  srVK_NUMLOCK    = 'Numlock';
  srVK_SCROLL     = 'Scroll';
  srVK_IRREGULAR  = 'Irregular ';
  srVK_NONE       = 'none';
  srkm_Alt        = 'Alt';
  srkm_Ctrl       = 'Ctrl';

implementation

end.

