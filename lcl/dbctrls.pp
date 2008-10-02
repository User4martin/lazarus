{ $Id$}
{
 /***************************************************************************
                               DbCtrls.pp
                               ----------
                     An interface to DB aware Controls
                     Initial Revision : Sun Sep 14 2003


 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
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
{
@abstract(common db aware controls, as in Delphi)
@author(Andrew Johnson <acjgenius@@earthlink.net>)
@created(Sun Sep 14 2003)
@lastmod($Date$)
}
unit DbCtrls;

{$mode objfpc}
{$H+}

interface          

uses
  Classes, SysUtils, DB,
  LCLStrConsts, LCLProc, LMessages, LCLType, LResources, GraphType,
  Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons, MaskEdit, ExtCtrls,
  Calendar, Chart;

Type
  { TFieldDataLink }

  TFieldDataLink = class(TDataLink)
  private
    FField: TField;
    FFieldName: string;

    FControl: TComponent;

    // Curent State of Affairs
    FEditing: Boolean;
    IsModified: Boolean;

    // Callbacks
    FOnDataChange: TNotifyEvent;
    FOnEditingChange: TNotifyEvent;
    FOnUpdateData: TNotifyEvent;
    FOnActiveChange: TNotifyEvent;
    FOnFocusRequest: TNotifyEvent;
    FOnLayoutChange: TNotifyEvent;

    function FieldCanModify: Boolean;
    function GetCanModify: Boolean;

    // set current field
    procedure SetFieldName(const Value: string);

    // make sure the field/fieldname is valid before we do stuff with it
    function ValidateField : Boolean;
  protected
    // Testing Events
    procedure ActiveChanged; override;
    procedure DataSetChanged; override;
    procedure EditingChanged; override;
    procedure LayoutChanged; override;
    procedure RecordChanged(aField: TField); override;
    procedure UpdateData; override;

    procedure FocusControl(aField: TFieldRef); Override;
  public
    constructor Create;
    destructor Destroy; override;

    // for control intitiating db changes etc
    function Edit: Boolean;

    procedure Modified;
    procedure Reset;

    // Attached control
    property Control: TComponent read FControl write FControl;


    // Basic DB interfaces
    property Field: TField read FField;
    property FieldName: string read FFieldName write SetFieldName;

    // Current State of DB
    property CanModify: Boolean read GetCanModify;
    property Editing: Boolean read FEditing;

    // Our Callbacks
    property OnDataChange: TNotifyEvent read FOnDataChange write FOnDataChange;
    property OnEditingChange: TNotifyEvent read FOnEditingChange write FOnEditingChange;
    property OnUpdateData: TNotifyEvent read FOnUpdateData write FOnUpdateData;
    property OnActiveChange: TNotifyEvent read FOnActiveChange write FOnActiveChange;
    property OnFocusRequest: TNotifyEvent read FOnFocusRequest write FOnFocusRequest;
    property OnLayoutChange: TNotifyevent read FOnLayoutChange write FOnLayoutChange;
  end;


  { TDBEdit }

  TDBEdit = class(TCustomMaskEdit)
  private
    FDataLink: TFieldDataLink;
    FUpdatingRecord: boolean;

    procedure DataChange(Sender: TObject);
    procedure UpdateData(Sender: TObject);
    procedure FocusRequest(Sender: TObject);
    procedure ActiveChange(Sender: TObject);
    procedure LayoutChange(Sender: TObject);
    
    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;


    procedure SetDataField(Value: string);
    procedure SetDataSource(Value: TDataSource);
    function IsReadOnly: boolean;
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    function GetReadOnly: Boolean; override;
    procedure SetReadOnly(Value: Boolean); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: char); override;

    procedure Loaded; override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;

    function EditCanModify: Boolean; override;
    function GetEditText: string; override;

    procedure Change; override;
    procedure Reset; override;

    procedure EditingDone; override;
    procedure WMSetFocus(var Message: TLMSetFocus); message LM_SETFOCUS;
    procedure WMKillFocus(var Message: TLMKillFocus); message LM_KILLFOCUS;
    procedure LMPasteFromClip(var Message: TLMessage); message LM_PASTE;
    procedure LMCutToClip(var Message: TLMessage); message LM_CUT;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Field: TField read GetField;
  published
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;

    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;

    property Anchors;
    property AutoSize;
    property BorderSpacing;
    property CharCase;
    property Color;
    property Constraints;
    property Ctl3D;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property EditMask;
    property Font;
    property MaxLength;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PasswordChar;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnChange;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDrag;
    property OnUTF8KeyPress;
  end;


  { TDBText }

  TDBText = class(TLabel)
  private
    FDataLink: TFieldDataLink;

    procedure DataChange(Sender: TObject);
    procedure ActiveChange(Sender: TObject);

    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;

    procedure SetDataField(Value: string);
    procedure SetDataSource(Value: TDataSource);
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Field: TField read GetField;
  published
    property Align;
    property Alignment;
    property Anchors;
    property AutoSize;
    property Caption;
    property Color;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DragCursor;
    property DragMode;
    property FocusControl;
    property Font;
    property Layout;
    property ShowAccelChar;
    property Visible;
    property WordWrap;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnStartDrag;
  end;


  { TDBListBox }

  TDBListBox = class(TCustomListBox)
    FDataLink: TFieldDataLink;

    procedure DataChange(Sender: TObject);
    procedure EditingChange(Sender: TObject);
    procedure UpdateData(Sender: TObject);
    procedure FocusRequest(Sender: TObject);

    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;

    procedure SetItems(Values : TStrings); override;

    function GetReadOnly: Boolean;
    procedure SetReadOnly(Value: Boolean);

    procedure SetDataField(Value: string);
    procedure SetDataSource(Value: TDataSource);
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

    procedure Loaded; override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure Click; override;
    procedure EditingDone; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Field: TField read GetField;
  published
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;

    // we need to overrride the write method for db aware.
    // the Read isn't an issue since the list will be updated
    // on data change anyway
    property Items write SetItems;

    //same as dbedit need to match the datalink status
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;

    property Align;
    property Anchors;
    property BorderSpacing;
    property BorderStyle;
    property DragCursor;
    property DragMode;
    property ExtendedSelect;
    property ItemHeight;
    property MultiSelect;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDrawItem;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyPress;
    property OnKeyDown;
    property OnKeyUp;
    property OnMouseMove;
    property OnMouseDown;
    property OnMouseUp;
    property OnResize;
    property OnStartDrag;
    property OnUTF8KeyPress;
    property ParentShowHint;
    property ShowHint;
    property Sorted;
    property Style;
    property TabOrder;
    property TabStop;
    property TopIndex;
    property Visible;
  end;


  { TDBRadioGroup }

  TDBRadioGroup = class(TCustomRadioGroup)
  private
    FDataLink: TFieldDataLink;
    FOnChange: TNotifyEvent;
    FValue: string;
    FInSetValue: boolean;
    FValues: TStrings;
    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;
    function GetReadOnly: Boolean;
    procedure SetDataField(const AValue: string);
    procedure SetDataSource(const AValue: TDataSource);
    procedure SetItems(const AValue: TStrings);
    procedure SetReadOnly(const AValue: Boolean);
    procedure SetValue(const AValue: string);
    procedure SetValues(const AValue: TStrings);
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    procedure Change; virtual;
    procedure Notification(AComponent: TComponent;
                           Operation: TOperation); override;
    procedure DataChange(Sender: TObject);
    procedure UpdateData(Sender: TObject);
    property DataLink: TFieldDataLink read FDataLink;
    function GetButtonValue(Index: Integer): string;
    procedure UpdateRadioButtonStates; override;
    procedure Loaded; override;
    procedure EditingDone; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    property Field: TField read GetField;
    property ItemIndex;
    property Value: string read FValue write SetValue;
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property Caption;
    property Columns;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DragCursor;
    property DragMode;
    property Enabled;
    property Items write SetItems;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnChangeBounds;
    property OnClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseuP;
    property OnResize;
    property OnStartDrag;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property TabOrder;
    property Values: TStrings read FValues write SetValues;
    property Visible;
  end;


  { TDBCheckBox }

  TDBCheckBox = class(TCustomCheckBox)
  private
    FDataLink: TFieldDataLink;
    FValueCheck: string;
    FValueUncheck: string;
    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;
    function GetReadOnly: Boolean;
    procedure SetDataField(const AValue: string);
    procedure SetDataSource(const AValue: TDataSource);
    procedure SetReadOnly(const AValue: Boolean);
    procedure SetValueCheck(const AValue: string);
    procedure SetValueUncheck(const AValue: string);
    function ValueEqualsField(const AValue, AFieldText: string): boolean;
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    function GetFieldCheckState: TCheckBoxState; virtual;
    procedure DataChange(Sender: TObject); virtual;
    procedure UpdateData(Sender: TObject); virtual;
    procedure FocusRequest(Sender: TObject); virtual;
    procedure Notification(AComponent: TComponent;
                           Operation: TOperation); override;
    procedure Loaded; override;
    procedure EditingDone; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    property Checked;
    property Field: TField read GetField;
    property State;
  published
    property AllowGrayed;
    property Anchors;
    property AutoSize;
    property BorderSpacing;
    property Caption;
    property Color;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Hint;
    property OnChange;
    property OnClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDrag;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property UseOnChange;
    property ValueChecked: string read FValueCheck write SetValueCheck;
    property ValueUnchecked: string read FValueUncheck write SetValueUncheck;
    property Visible;
  end;
  
  
  { TDBComboBox }

  TDBComboBox = class(TCustomComboBox)
  private
    FDataLink: TFieldDataLink;
    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;
    function GetReadOnly: Boolean;
    procedure SetDataField(const AValue: string);
    procedure SetDataSource(const AValue: TDataSource);
    procedure SetReadOnly(const AValue: Boolean);
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    procedure DataChange(Sender: TObject); virtual;
    procedure ActiveChange(Sender: TObject); //virtual;
    procedure EditingChange(Sender: TObject); virtual;
    procedure Notification(AComponent: TComponent;
                           Operation: TOperation); override;
    procedure Change; override;
    procedure UpdateData(Sender: TObject); virtual;
    procedure FocusRequest(Sender: TObject); virtual;
    procedure Loaded; override;
    procedure EditingDone; override;
    procedure UpdateText;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    property Field: TField read GetField;
    property Text;
    property ItemIndex;
  published
    property Anchors;
    property ArrowKeysTraverseList;
    property AutoDropDown;
    property AutoSize;
    property BorderSpacing;
    property Color;
    property Ctl3D;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DragCursor;
    property DragMode;
    property DropDownCount;
    property Enabled;
    property Font;
    property ItemHeight;
    property Items;
    property ItemWidth;
    property MaxLength default -1;
    property OnChange;
    property OnChangeBounds;
    property OnClick;
    property OnCloseUp;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDrawItem;
    property OnDropDown;
    property OnEditingDone;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnSelect;
    property OnStartDrag;
    property OnUTF8KeyPress;
    property ParentCtl3D;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property ShowHint;
    property Sorted;
    property Style;
    property TabOrder;
    property TabStop;
    property Visible;
  end;
  
  
  { TDBMemo }

  TDBMemo = class(TCustomMemo)
  private
    FDataLink: TFieldDataLink;
    FAutoDisplay: Boolean;
    FDBMemoFocused: Boolean;
    FDBMemoLoaded: Boolean;
    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;
    procedure SetAutoDisplay(const AValue: Boolean);
    procedure SetDataField(const AValue: string);
    procedure SetDataSource(const AValue: TDataSource);
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    function GetReadOnly: Boolean; override;
    procedure SetReadOnly(AValue: Boolean); override;
    function WordWrapIsStored: boolean; override;
    procedure DataChange(Sender: TObject); virtual;
    procedure ActiveChange(Sender: TObject); virtual;
    procedure Notification(AComponent: TComponent;
                           Operation: TOperation); override;
    procedure UpdateData(Sender: TObject); virtual;
    procedure FocusRequest(Sender: TObject); virtual;
    procedure Loaded; override;
    procedure EditingDone; override;
    procedure Change; override;
    procedure KeyPress(var Key:Char); override;
    procedure WndProc(var AMessage : TLMessage); override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure LoadMemo; virtual;
    property Field: TField read GetField;
  published
    property Align;
    property Anchors;
    property AutoDisplay: Boolean read FAutoDisplay write SetAutoDisplay default True;
    property BorderSpacing;
    property Color;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DragCursor;
    property DragMode;
    property Font;
    property Lines;
    property MaxLength;
    property OnChange;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnStartDrag;
    property OnUTF8KeyPress;
    property ParentFont;
    property PopupMenu;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property ScrollBars;
    property TabOrder;
    property Tabstop;
    property Visible;
    property WordWrap stored WordWrapIsStored;
  end;
  
  
  { TDBGroupBox }
  
  TDBGroupBox = class(TCustomGroupBox)
    FDataLink: TFieldDataLink;
    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;
    procedure SetDataField(const AValue: string);
    procedure SetDataSource(const AValue: TDataSource);
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    procedure DataChange(Sender: TObject); virtual;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    property Field: TField read GetField;
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property Caption;
    property ClientHeight;
    property ClientWidth;
    property Color;
    property Constraints;
    property Ctl3D;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DragCursor;
    property DragMode;
    property Enabled;
    property Font;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDrag;
    property OnUTF8KeyPress;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
  end;
  

  { TDBImage }

  TDBImage = class(TCustomImage)
  private
    FAutoDisplay: Boolean;
    FDataLink: TFieldDataLink;
    FQuickDraw: Boolean;
    FPictureLoaded: boolean;
    FUpdatingRecord: boolean;
    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;
    function GetReadOnly: Boolean;
    procedure SetAutoDisplay(const AValue: Boolean);
    procedure SetDataField(const AValue: string);
    procedure SetDataSource(const AValue: TDataSource);
    procedure SetReadOnly(const AValue: Boolean);
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure DataChange(Sender: TObject); virtual;
    procedure UpdateData(Sender: TObject); virtual;
    procedure ActiveChange(Sender: TObject); virtual;
    procedure PictureChanged(Sender: TObject); override;
    procedure LoadPicture; virtual;
    procedure Loaded; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    property Field: TField read GetField;
    procedure Change; virtual;
  published
    property Align;
    property Anchors;
    property AutoDisplay: Boolean read FAutoDisplay write SetAutoDisplay default True;
    property AutoSize;
    property BorderSpacing;
    property Center;
    property Constraints;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DragCursor;
    property DragMode;
    property OnClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDrag;
    property Picture;
    property Proportional;
    property QuickDraw: Boolean read FQuickDraw write FQuickDraw default True;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property Stretch;
    property Transparent;
    property Visible;
  end;


  { TDBCalender }

  { TDBCalendar }

  TDBCalendar = class(TCalendar)
    FDataLink: TFieldDataLink;

    procedure DataChange(Sender: TObject);
    procedure UpdateData(Sender: TObject);
    procedure FocusRequest(Sender: TObject);

    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;

    function GetReadOnly: Boolean;
    procedure SetReadOnly(Value: Boolean);

    procedure SetDate(const AValue: String);

    procedure SetDataField(Value: string);
    procedure SetDataSource(Value: TDataSource);
    procedure UpdateDate(const AValue: string);
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure EditingDone; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;

    property Field: TField read GetField;
  published
    property BorderSpacing;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;

    Property Date write SetDate stored False;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;

    property DisplaySettings stored False;
    property DragCursor;
    property DragMode;
    property Visible;
    property OnClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnMouseMove;
    property OnMouseDown;
    property OnDayChanged;
    property OnMonthChanged;
    property OnStartDrag;
    property OnYearChanged;
  end;


  { TDBCustomNavigator }

type
  TDBNavButton = class;
  TDBNavDataLink = class;

  TDBNavGlyph = (ngEnabled, ngDisabled);
  TDBNavButtonType = (nbFirst, nbPrior, nbNext, nbLast,
                  nbInsert, nbDelete, nbEdit, nbPost, nbCancel, nbRefresh);
  TDBNavButtonSet = set of TDBNavButtonType;
  TDBNavButtonStyle = set of (nsAllowTimer, nsFocusRect);
  TDBNavButtonDirection = (nbdHorizontal,nbdVertical);
  
  // for Delphi compatibility
  TNavigateBtn = TDBNavButtonType;

  TDBNavClickEvent = procedure(Sender: TObject;
                                Button: TDBNavButtonType) of object;
  
const
  DefaultDBNavigatorButtons = [nbFirst, nbPrior, nbNext, nbLast,
    nbInsert, nbDelete, nbEdit, nbPost, nbCancel, nbRefresh];
  DBNavButtonResourceName: array[TDBNavButtonType] of string = (
 { nbFirst   } 'DBNavFirst',
 { nbPrior   } 'DBNavPrior',
 { nbNext    } 'DBNavNext',
 { nbLast    } 'DBNavLast',
 { nbInsert  } 'DBNavInsert',
 { nbDelete  } 'DBNavDelete',
 { nbEdit    } 'DBNavEdit',
 { nbPost    } 'DBNavPost',
 { nbCancel  } 'DBNavCancel',
 { nbRefresh } 'DBNavRefresh'
    );
  DBNavButtonDefaultHint: array[TDBNavButtonType] of string = (
 { nbFirst   } rsFirstRecordHint,
 { nbPrior   } rsPriorRecordHint,
 { nbNext    } rsNextRecordHint,
 { nbLast    } rsLastRecordHint,
 { nbInsert  } rsInsertRecordHint,
 { nbDelete  } rsDeleteRecordHint,
 { nbEdit    } rsEditRecordHint,
 { nbPost    } rsPostRecordHint,
 { nbCancel  } rsCancelRecordHint,
 { nbRefresh } rsRefreshRecordsHint
  );

type

  { TDBCustomNavigator }

  TDBCustomNavigator = class(TCustomPanel)
  private
    FBeforeAction: TDBNavClickEvent;
    FConfirmDelete: Boolean;
    FDataLink: TDBNavDataLink;
    FDirection: TDBNavButtonDirection;
    FFlat: Boolean;
    FOnNavClick: TDBNavClickEvent;
    FShowButtonHints: boolean;
    FVisibleButtons: TDBNavButtonSet;
    FDefaultHints: TStrings;
    FHints: TStrings;
    FUpdateButtonsNeeded: boolean;
    FUpdateButtonsLock: integer;
    FOriginalHints: String;
    procedure DefaultHintsChanged(Sender: TObject);
    function GetDataSource: TDataSource;
    function GetHints: TStrings;
    procedure SetDataSource(const AValue: TDataSource);
    procedure SetDirection(const AValue: TDBNavButtonDirection);
    procedure SetFlat(const AValue: Boolean);
    procedure SetHints(const AValue: TStrings);
    procedure SetShowButtonHints(const AValue: boolean);
    procedure SetVisibleButtons(const AValue: TDBNavButtonSet);
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    Buttons: array[TDBNavButtonType] of TDBNavButton;
    procedure DataChanged; virtual;
    procedure EditingChanged; virtual;
    procedure ActiveChanged; virtual;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure UpdateButtons; virtual;
    procedure UpdateHints; virtual;
    procedure HintsChanged(Sender: TObject); virtual;
    procedure ButtonClickHandler(Sender: TObject); virtual;
    procedure DoOnResize; override;
    class function GetControlClassDefaultSize: TPoint; override;
    procedure BeginUpdateButtons; virtual;
    procedure EndUpdateButtons; virtual;
    procedure SetEnabled(Value: Boolean); override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure BtnClick(Index: TNavigateBtn); virtual;
    function VisibleButtonCount: integer; virtual;
  public
    property BeforeAction: TDBNavClickEvent read FBeforeAction write FBeforeAction;
    property ConfirmDelete: Boolean read FConfirmDelete write FConfirmDelete default True;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property Direction: TDBNavButtonDirection read FDirection write SetDirection default nbdHorizontal;
    property Flat: Boolean read FFlat write SetFlat default False;
    property Hints: TStrings read GetHints write SetHints;
    property OnClick: TDBNavClickEvent read FOnNavClick write FOnNavClick;
    property VisibleButtons: TDBNavButtonSet read FVisibleButtons
                             write SetVisibleButtons default DefaultDBNavigatorButtons;
    property ShowButtonHints: boolean read FShowButtonHints write SetShowButtonHints default true;
  end;
  
  
  { TDBNavButton }

  TDBNavButton = class(TSpeedButton)
  private
    FIndex: TDBNavButtonType;
    FNavStyle: TDBNavButtonStyle;
  protected
  public
    destructor Destroy; override;
    property NavStyle: TDBNavButtonStyle read FNavStyle write FNavStyle;
    property Index: TDBNavButtonType read FIndex write FIndex;
  end;


  { TNavDataLink }

  TDBNavDataLink = class(TDataLink)
  private
    FNavigator: TDBCustomNavigator;
  protected
    procedure EditingChanged; override;
    procedure DataSetChanged; override;
    procedure ActiveChanged; override;
  public
    constructor Create(TheNavigator: TDBCustomNavigator);
    destructor Destroy; override;
  end;


  { TDBNavigator }

  TDBNavigator = class(TDBCustomNavigator)
  published
    property Align default alNone;
    property Alignment;
    property Anchors;
    property AutoSize;
    property BeforeAction;
    property BevelInner;
    property BevelOuter;
    property BevelWidth;
    property BorderSpacing;
    property BorderStyle;
    property BorderWidth;
    property Caption;
    property ClientHeight;
    property ClientWidth;
    property Color default clBackground;
    property ConfirmDelete;
    property DataSource;
    property Direction;
    property DragCursor;
    property DragMode;
    property Enabled;
    property Flat;
    property Font;
    property Hints;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDrag;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default False;
    property Visible;
    property VisibleButtons;
  end;
  

// ToDo: Move this to db.pp
function ExtractFieldName(const Fields: string; var StartPos: Integer): string;

procedure FillBarChart(BC: TBarChart; DS: TDataset;
  const LabelField, ValueField: String; AColor: TColor);

procedure ChangeDataSource(AControl: TControl; Link: TDataLink;
  NewDataSource: TDataSource);

procedure Register;

implementation

var
  FieldClasses: TList;

procedure RegFields(const AFieldClasses: array of TFieldClass);
var I: Integer;
    FieldClass: TFieldClass;
begin
  if FieldClasses = nil then FieldClasses := TList.Create;
  for I := Low(AFieldClasses) to High(AFieldClasses) do begin
    FieldClass := AFieldClasses[I];
    if (FieldClass <> Nil) And (FieldClasses.IndexOf(FieldClass) = -1) then
    begin
      FieldClasses.Add(FieldClass);
      RegisterNoIcon([FieldClass]);
      RegisterClass(FieldClass);
    end;
  end;
end;

function ExtractFieldName(const Fields: string; var StartPos: Integer): string;
var
  i: Integer;
begin
  i:=StartPos;
  while (i<=Length(Fields)) and (Fields[i]<>';') do Inc(i);
  Result:=Trim(Copy(Fields,StartPos,i-StartPos));
  if (i<=Length(Fields)) and (Fields[i]=';') then Inc(i);
  StartPos:=i;
end;

procedure FillBarChart(BC: TBarChart; DS: TDataset;
  const LabelField, ValueField: String; AColor: TColor);
Var
  LF : TList;
  VF : TField;
  I : Integer;
  L : String;
begin
  VF:=DS.FieldByName(ValueField);
  LF:=TList.Create;
  Try
    DS.GetFieldList(LF,LabelField);
    With DS do
      begin
      While Not EOF do
        begin
        L:='';
        For I:=0 to LF.Count-1 do
          begin
          If L<>'' then
            L:=L+' ';
          L:=L+TField(LF[i]).AsString;
          end;
        BC.AddBar(L, VF.AsInteger, AColor);
        Next;
        end;
      end;
  Finally
    LF.Free;
  end;
end;

procedure ChangeDataSource(AControl: TControl; Link: TDataLink;
  NewDataSource: TDataSource);
begin
  if Link.DataSource=NewDataSource then exit;
  if Link.DataSource<>nil then
    Link.DataSource.RemoveFreeNotification(AControl);
  Link.DataSource:=NewDataSource;
  if Link.DataSource<>nil then
    Link.DataSource.FreeNotification(AControl);
end;

procedure Register;
begin
  RegisterComponents('Data Controls',[TDBNavigator,TDBText,TDBEdit,TDBMemo,
    TDBImage,TDBListBox,TDBComboBox,TDBCheckBox,TDBRadioGroup,TDBCalendar,
    TDBGroupBox]);
  {$IFNDEF VER2_0}
  RegFields(DefaultFieldClasses);
  {$ENDIF}
end;


{TFieldDataLink  Private Methods}

{hack around broken Field method by using this instead}
function TFieldDataLink.FieldCanModify: Boolean;
begin
  Result:=Not FField.ReadOnly;
  If Result then
    begin
    Result:=Assigned(FField.DataSet);
    If Result then
      Result:=FField.DataSet.CanModify;
    end;
end;

{
  If the field exists and can be modified, then
  we CanModify as long as this hasn't been set
  ReadOnly somewhere else. Do we need any extra tests here?
}
function TFieldDataLink.GetCanModify: Boolean;
begin
  if Assigned(FField) and (FieldCanModify) then
     Result := not ReadOnly
  else
    Result := False;
end;

{
  Set the FieldName and then update the field to match,

  If we are changing the field from a previously valid field
  we need to make sure the editing state is updated, and that the
  DataChanged method is called, easiest way I think is to set the field
  to nil then call EditingChanged and Reset before we actually set the
  proper field. This way if this turns out to be an invalid fieldname we
  are already nil anyway and all the changes to state have been made.

  Next we look up the FieldByName on the attatched DataSource.. which we have
  to make sure exists first. assuming this worked properly, then we will have a
  valid Field again, so now we need to update the Editing state again
  and call the DataChanged again, so Reset. And then we are done... I think.

  If I am missing anything or am doing this all wrong please fix :)
}
procedure TFieldDataLink.SetFieldName(const Value: string);
begin
  if FFieldName <> Value then
  begin
    FFieldName :=  Value;
    If Assigned(FField) then begin
      FField := nil;
      EditingChanged;
      Reset;
    end;

    If Assigned(DataSource) and Assigned(DataSource.DataSet) then
      FField := DataSource.DataSet.FieldByName(FFieldName);

    If Assigned(FField) then begin
      EditingChanged;
      Reset;
    end;
  end;
end;

{
  Several functions seem to need to test the validity of
  the field/fieldname, so lets put it into its own function.
  I do not really know what all to put here so just check for a
  non empty FieldName and a non-nil Field, and if a valid name, but
  not a valid Field, try and re-call SetFieldName.
}
function TFieldDataLink.ValidateField : Boolean;
var
  RealFieldName : String;
begin
  RealFieldName := FFieldName;
  If (RealFieldName <> '') and not Assigned(FField) then begin
    FFieldName := '';
    SetFieldName(RealFieldName);
  end;

  result := (RealFieldName <> '') and Assigned(FField);
end;


{TFieldDataLink  Protected Methods}

{ Delphi Help ->
    Changes to the Active property trigger the ActiveChanged method.
    If an OnActiveChange event handler is assigned, ActiveChanged calls
    this event handler. If ActiveChanged is triggered by a transition into
    an active state, then before calling the event handler, ActiveChanged makes
    sure that the Field for this TFieldDataLink is still valid.
  <-- Delphi Help

   So... just call event if exists? unles Active then we test validity of
   field. does this simply mean not nil? or is more involved?
   call mock routine for now
   
   if it becomes inactive then the field is not valid anymore isn't?
}
procedure TFieldDataLink.ActiveChanged;
begin
  if Active and not ValidateField
  then
    exit;

  if not Active then
    FField := nil;
    
  if Assigned(FOnActiveChange) then
    FOnActiveChange(Self);
end;

{ not in the delphi version(well not int the help anyway)
  but the db version is calling RecordChange with nil,
  which is invalid if we have a real value, so just call reset
}
procedure TFieldDataLink.DataSetChanged;
begin
  reset;
end;


{ Delphi Help ->
    Changing the field binding can change the validity of the CanModify
    property, since individual field components can disallow edits. If
    TFieldDataLink is in an editing state when the Field property is changed,
    EditingChanged checks the CanModify property. If CanModify is False, it
    changes back out of the editing state.

    Note: This differs significantly from the inherited EditingChanged method
    of TDataLink. The functionality of the inherited method is replaced in
    TFieldDataLink by the OnEditingChange event handler.
  <-- Delphi Help

  ok so another event... but this time we simply change modified state
  if Editing and not CanModify? or do we also change to match if
  if not Editing and CanModify? i.e If Editing <> CanModify??  Will assume
  the latter just in case. easy to change back if I am wrong.

  Also based on this we replace parent routine, so do we need to keep track
  of Editing state ourself? I hope this is right. Anyone know for sure?

  OK .. based on the Modified routine we need to turn off
  our IsModified routine when succesfull right? so for now just turn
  it off as per my example.
}
procedure TFieldDataLink.EditingChanged;
var
  RealEditState : Boolean;
begin
  RealEditState := (CanModify and Inherited Editing);

  if (FEditing <> RealEditState) then
  begin
    FEditing := RealEditState;
    IsModified := False;
    if Assigned(FOnEditingChange) then
      FOnEditingChange(Self);
  end;
end;

{ Delphi Help ->
    LayoutChanged is called after changes in the layout of one of the
    containers of the Control for this TFieldDataLink that might change the
    validity of its field binding. For example, if the Control is embedded
    within a TCustomDBGrid, and one of the columns is deleted, the Field
    property for the Control might become invalid.
  <-- Delphi Help

  So... just another field validity check? call our mock routine...
}
procedure TFieldDataLink.LayoutChanged;
begin
  ValidateField;
  if Assigned(FOnLayoutChange) then
    FOnLayoutChange(Self);
end;

{ Delphi Help ->
    Applications can not call this protected method. It is triggered
    automatically when the contents of the current record change.
    RecordChanged calls the OnDataChange event handler if there is one.
  <-- Delphi Help

  Ok so just a simple Event Handler.. what. no extra tests? we gotta
  have at least one.. :)

  yeah lets go ahead and make sure the field matches the
  internal one. can it ever not? and if not what about nil? do we
  need to do something special? maybe another test is needed later....

  does this only get called after Modified? assume so till I know otherwise
  and turn off IsModified.

  hah. same thing as Reset but with a test so lets just call Reset and let
  it do the work
}
procedure TFieldDataLink.RecordChanged(aField: TField);
begin
  if (aField = FField) then
     Reset;
end;

{ Delphi Help ->
    UpdateData overrides the default UpdateData method to call the
    OnUpdateData event handler where the data-aware control can write any
    pending edits to the record in the dataset.
  <-- Delphi Help

  where..can write pending events. So I guess when we have already
  called Modified? Aka if not IsModified exit otherwise call event?
  works for me.
}
procedure TFieldDataLink.UpdateData;
begin
  if not IsModified then
    exit;

  if Assigned(FOnUpdateData) then
    FOnUpdateData(Self);

  IsModified := False;
end;

{ Delphi Help ->
    Call FocusControl to give the Control associated with this TFieldDataLink
    object the input focus. FocusControl checks whether the Control can receive
    input focus, and if so, calls its SetFocus method to move focus to the
    Control.
  <-- Delphi Help

  so seems it just calls SetFocus on TWinControls, since this DataLink should
  really go into the FCL, we just add our own callback which the DB aware
  controls that can get focus then assign to do the real SetFocus, thus removing
  need for visual dependency.
}

procedure TFieldDataLink.FocusControl(aField: TFieldRef);
begin
  If Assigned(aField) and (aField^ = FField) then
    if Assigned(FOnFocusRequest) then begin
      aField^ := nil;
      FOnFocusRequest(Self);
    end;
end;

{TFieldDataLink  Public Methods}

constructor TFieldDataLink.Create;
begin
  inherited Create;
  VisualControl := True;
  FField := nil;
  FFieldname := '';
end;

destructor TFieldDataLink.Destroy;
begin
  inherited Destroy;
end;

{ Delphi Help ->
    Use Edit to try to ensure that the contents of the field can be modified.
    A return value of True indicates that the field was already in an editing
    state, or that the DataSource was successfully changed to allow editing.
    A return value of False indicates that the DataSource could not be changed
    to allow editing. For example, if the CanModify property is False, Edit
    fails, and returns False.
  <-- Delphi Help

  ok so the way I see it, since the inherited function calls EditingChanged,
  which we have already overriden to modify our own Editing state if its invalid,
  I should just be calling the inherited routine here, but only if CanModify,
  since there is no point otherwise. But since we _are_ keeping track of editing
  state ourselves we return our own state, not the inherited. If anyone know
  better please fix.
}
function TFieldDataLink.Edit: Boolean;
begin
  if CanModify then
    inherited Edit;

  Result := FEditing;
end;

{ Delphi Help ->
    Call Modified when the Control for this TFieldDataLink begins processing
    edits.
  <-- Delphi Help

  ok so. well _that's_ helpfull. for the moment going to keep track
  by adding an IsModified... based on the other functions thus far
  we need to know whether we are in state, so I am assuming it goes

  Call Modified ->
    IsModified:=True;//Waiting for modifications

  Call SomeFunction->
    If IsModified then begin
      (do something)
      IsModified := False;//All modifications complete
    end
    else
     (do something else? exit?);
}
procedure TFieldDataLink.Modified;
begin
  IsModified := True;
end;

{ Delphi Help ->
    The Control that owns a TFieldDataLink object calls its Reset method to
    process a UI action that cancels edits to the field. Reset calls the
    OnDataChange event handler without writing any pending changes to the
    record in the dataset.
  <-- Delphi Help

  hrmm. just call to the OnDataChange Event, and turn off IsModified I guess
  better ideas anyone?

  oh huh. same thing as RecordChanged but without the test so I can just
  have it call this instead :)
}
procedure TFieldDataLink.Reset;
begin
  if active and Assigned(FOnDataChange) then
    FOnDataChange(Self);

  IsModified := False;
end;

{$Include dbedit.inc}
{$Include dbtext.inc}
{$Include dblistbox.inc}
{$Include dbradiogroup.inc}
{$Include dbcheckbox.inc}
{$Include dbcombobox.inc}
{$Include dbmemo.inc}
{$Include dbgroupbox.inc}
{$Include dbimage.inc}
{$Include dbcalendar.inc}
{$Include dbcustomnavigator.inc}

initialization
  {$I lcl_dbnav_images.lrs}

finalization
  FieldClasses.Free;

end.
