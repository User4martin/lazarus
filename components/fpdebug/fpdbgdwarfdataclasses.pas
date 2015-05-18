{
 ---------------------------------------------------------------------------
 fpdbgdwarfdataclasses.pas  -  Native Freepascal debugger - Dwarf symbol reader
 ---------------------------------------------------------------------------

 This unit contains helper classes for loading and resolving of DWARF debug
 symbols

 ---------------------------------------------------------------------------

 @created(Mon Aug 1st WET 2006)
 @lastmod($Date$)
 @author(Marc Weustink <marc@@dommelstein.nl>)
 @author(Martin Friebe)

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
unit FpDbgDwarfDataClasses;

{$mode objfpc}{$H+}
//{$INLINE OFF}
{off $DEFINE USE_ABBREV_TMAP}

interface

uses
  Classes, Types, SysUtils, FpDbgUtil, FpDbgInfo, FpDbgDwarfConst, Maps, Math, FpDbgLoader,
  FpImgReaderBase, FpdMemoryTools, FpErrorMessages, LazLoggerBase, // LazLoggerDummy,
  LazClasses, LazFileUtils, LazUTF8, contnrs, DbgIntfBaseTypes;

type
  TDwarfSection = (dsAbbrev, dsARanges, dsFrame,  dsInfo, dsLine, dsLoc, dsMacinfo, dsPubNames, dsPubTypes, dsRanges, dsStr);

const
  DWARF_SECTION_NAME: array[TDwarfSection] of String = (
    '.debug_abbrev', '.debug_aranges', '.debug_frame', '.debug_info',
    '.debug_line', '.debug_loc', '.debug_macinfo', '.debug_pubnames',
    '.debug_pubtypes', '.debug_ranges', '.debug_str'
  );

type
  TFpDwarfInfo = class;
  TDwarfCompilationUnit = class;

{%region Dwarf Header Structures }
  // compilation unit header
  {$PACKRECORDS 1}
  PDwarfCUHeader32 = ^TDwarfCUHeader32;
  TDwarfCUHeader32 = record
    Length: LongWord;
    Version: Word;
    AbbrevOffset: LongWord;
    AddressSize: Byte;
  end;

  PDwarfCUHeader64 = ^TDwarfCUHeader64;
  TDwarfCUHeader64 = record
    Signature: LongWord;
    Length: QWord;
    Version: Word;
    AbbrevOffset: QWord;
    AddressSize: Byte;
  end;
  
  // Line number program header
  PDwarfLNPInfoHeader = ^TDwarfLNPInfoHeader;
  TDwarfLNPInfoHeader = record
    MinimumInstructionLength: Byte;
    DefaultIsStmt: Byte;
    LineBase: ShortInt;
    LineRange: Byte;
    OpcodeBase: Byte;
    StandardOpcodeLengths: record end; {array[1..OpcodeBase-1] of Byte}
    {IncludeDirectories: asciiz, asciiz..z}
    {FileNames: asciiz, asciiz..z}
  end;

  PDwarfLNPHeader32 = ^TDwarfLNPHeader32;
  TDwarfLNPHeader32 = record
    UnitLength: LongWord;
    Version: Word;
    HeaderLength: LongWord;
    Info: TDwarfLNPInfoHeader;
  end;

  PDwarfLNPHeader64 = ^TDwarfLNPHeader64;
  TDwarfLNPHeader64 = record
    Signature: LongWord;
    UnitLength: QWord;
    Version: Word;
    HeaderLength: QWord;
    Info: TDwarfLNPInfoHeader;
  end;
  
  {$PACKRECORDS C}
{%endregion Dwarf Header Structures }

{%region Abbreviation Data / Section "debug_abbrev"}
  { TDwarfAbbrev }
  TDwarfAbbrevFlag = (
    dafHasChildren,
    dafHasName,
    dafHasLowAddr,
    dafHasStartScope,
    dafHasAbstractOrigin
  );
  TDwarfAbbrevFlags = set of TDwarfAbbrevFlag;

  TDwarfAbbrev = record
    tag: Cardinal;
    index: Integer;
    count: SmallInt; // Integer;
    flags: TDwarfAbbrevFlags;
  end;
  PDwarfAbbrev = ^TDwarfAbbrev;

  TDwarfAbbrevEntry = record
    Attribute: Cardinal;
    Form: Cardinal;
  end;
  PDwarfAbbrevEntry = ^TDwarfAbbrevEntry;

  TLeb128TableEntry = record
    LeadLow, LeadHigh: Byte; // bytes >= 128, more to follow
    EndLow,  EndHigh: Byte;  // bytes < 128, pointer to data
    LeadIndex: cardinal;     // first index in LeadTableData
    EndIndex: cardinal;      // first index in EndTableData
  end;
  PLeb128TableEntry = ^TLeb128TableEntry;

  TPointerDynArray = array of Pointer;
  TAttribPointerList = record
    List: TPointerDynArray;
    Abbrev: PDwarfAbbrev;
    EvalCount: Integer;
  end;

  { TLEB128PreFixTree }

  TLEB128PreFixTree = class
  private
    FTableList: Array of TLeb128TableEntry;
    FTableListGaps: Array of record LeadTable, EndTable: Byte; end;
    FTableListNextFreeIndex: Cardinal;

    FLeadTableData: Array of Cardinal; //  Next Table number
    FLeadTableNextFreeIndex: Cardinal;
    FEndTableData:  Array of TDwarfAbbrev; //Pointer;
    FEndTableNextFreeIndex: Cardinal;

    FDataGrowStep, FTableListGrowStep: Cardinal;
  protected
  public
    procedure SetCapacity(ACapacity: integer);
    procedure Finish;
    function AddLeb128FromPointer(APointer: Pointer; const AData: TDwarfAbbrev): Pointer;
    function FindLe128bFromPointer(APointer: Pointer; out AData: PDwarfAbbrev): Pointer; // returnns pointer to first address after LEB128
    function FindLe128bFromPointer(APointer: Pointer; out AData: TDwarfAbbrev): Pointer; inline; // returnns pointer to first address after LEB128
  end;

  { TDwarfAbbrevList }

  TDwarfAbbrevList = class{$IFnDEF USE_ABBREV_TMAP}(TLEB128PreFixTree){$Endif}
  private
    FAbbrDataEnd: Pointer;
    {$IFDEF USE_ABBREV_TMAP}
    FMap: TMap;  // Abbrevs
    {$Endif}
    FDefinitions: array of TDwarfAbbrevEntry;
    function GetEntryPointer(AIndex: Integer): PDwarfAbbrevEntry; inline;
  protected
    procedure LoadAbbrevs(AnAbbrevDataPtr: Pointer);
  public
    constructor Create(AnAbbrData, AnAbbrDataEnd: Pointer; AnAbbrevOffset, AInfoLen: QWord);
    destructor Destroy; override;
    {$IFDEF USE_ABBREV_TMAP}
    function FindLe128bFromPointer(AnAbbrevPtr: Pointer; out AData: TDwarfAbbrev{Pointer}): Pointer; reintroduce;
    {$Endif}
    property EntryPointer[AIndex: Integer]: PDwarfAbbrevEntry read GetEntryPointer;
  end;
{%endregion Abbreviation Data / Section "debug_abbrev"}

{%region Information Entry / Section "debug_info"}
  (* Link, can either be
     - "Next Sibling" (for the parent): Link will be greater than current index
     - "Parent": Link will be smaller than current index

     By Default link is "Parent".
     A first child does not need a "Parent" link (Parent is always at CurrentIndex - 1),
      it will therefore store "Parent"."Next Sibling"
     A first Child of a parent with no Next sibling, has Link = Parent

     "Next Sibling" is either CurrentIndex + 1 (no children), or can be found via
      the first childs link.
     A Sibling has the same Parent. (If there is no child, and CurrentIndex+1 has
      a diff parent, then there is no Next)

     TopLevel Scopes have Link=-1
  *)
  TDwarfScopeInfoRec = record
    Link: Integer;
    Entry: Pointer;
  end;
  PDwarfScopeInfoRec = ^TDwarfScopeInfoRec;

  TDwarfScopeArray = Array of TDwarfScopeInfoRec;
  TDwarfScopeList = record
    List: TDwarfScopeArray;
    HighestKnown: Integer;
  end;
  PDwarfScopeList = ^TDwarfScopeList;

  { TDwarfScopeInfo }

  TDwarfScopeInfo = object
  private
    FScopeList: PDwarfScopeList;
    FIndex: Integer;
    function GetChild: TDwarfScopeInfo; inline;
    function GetChildIndex: Integer; inline;
    function GetEntry: Pointer; inline;
    function GetNext: TDwarfScopeInfo; inline;
    function GetNextIndex: Integer; inline;
    function GetParent: TDwarfScopeInfo; inline;
    function GetParentIndex: Integer;
    procedure SetIndex(AIndex: Integer);
    function CreateScopeForEntry(AEntry: Pointer; ALink: Integer): Integer; inline;
  public
    procedure Init(AScopeList: PDwarfScopeList);
    function CreateNextForEntry(AEntry: Pointer): Integer; inline;
    function CreateChildForEntry(AEntry: Pointer): Integer; inline;

    function IsValid: Boolean; inline;
    property Index: Integer read FIndex write SetIndex;
    property Entry: Pointer read GetEntry;

    function HasParent: Boolean; inline;
    function HasNext: Boolean; inline;
    function HasChild: Boolean; inline;

    procedure GoParent; inline;
    procedure GoNext; inline;
    procedure GoChild; inline;

    property Parent: TDwarfScopeInfo read GetParent;
    property ParentIndex: Integer read GetParentIndex;
    property Next: TDwarfScopeInfo read GetNext;
    property NextIndex: Integer read GetNextIndex;
    property Child: TDwarfScopeInfo read GetChild;
    property ChildIndex: Integer read GetChildIndex;
  end;

  { TDwarfInformationEntry }

  TDwarfInformationEntry = class(TRefCountedObject)
  private
    FCompUnit: TDwarfCompilationUnit;
    FInformationEntry: Pointer; // pointer to the LEB128 Abbrev at the start of an Information entry in debug_info
    FInformationData: Pointer;  // poinetr after the LEB128
    FScope: TDwarfScopeInfo;
    FAbbrev: PDwarfAbbrev;
    FAbbrevData: PDwarfAbbrevEntry;
    FAbstractOrigin: TDwarfInformationEntry;
    FFlags: set of (dieAbbrevValid, dieAbbrevDataValid, dieAbstractOriginValid);

    procedure PrepareAbbrev; inline;
    function  PrepareAbbrevData: Boolean; inline;
    function  PrepareAbstractOrigin: Boolean; inline; // Onli call, if abbrev is valid AND dafHasAbstractOrigin set

    function SearchScope: Boolean;
    function MaybeSearchScope: Boolean; inline;
    procedure ScopeChanged; inline;

    function GetAbbrevTag: Cardinal; inline;
    function GetScopeIndex: Integer;
    procedure SetScopeIndex(AValue: Integer);
  public
    constructor Create(ACompUnit: TDwarfCompilationUnit; AnInformationEntry: Pointer);
    constructor Create(ACompUnit: TDwarfCompilationUnit; AScope: TDwarfScopeInfo);
    destructor Destroy; override;
    property CompUnit: TDwarfCompilationUnit read FCompUnit;

    function AttribIdx(AnAttrib: Cardinal; out AInfoPointer: pointer): Integer; inline;
    function HasAttrib(AnAttrib: Cardinal): Boolean; inline;

    function GoNamedChild(AName: String): Boolean;
    // find in enum too // TODO: control search with a flags param, if needed
    function GoNamedChildEx(ANameUpper, AnameLower: PChar): Boolean;
    function GoNamedChildEx(AName: String): Boolean; inline;

    function FindNamedChild(AName: String): TDwarfInformationEntry;
    function FindChildByTag(ATag: Cardinal): TDwarfInformationEntry;
    function FirstChild: TDwarfInformationEntry;
    function Clone: TDwarfInformationEntry;

    property AbbrevTag: Cardinal read GetAbbrevTag;

    function ReadValue(AnAttrib: Cardinal; out AValue: Integer): Boolean;
    function ReadValue(AnAttrib: Cardinal; out AValue: Int64): Boolean;
    function ReadValue(AnAttrib: Cardinal; out AValue: Cardinal): Boolean;
    function ReadValue(AnAttrib: Cardinal; out AValue: QWord): Boolean;
    function ReadValue(AnAttrib: Cardinal; out AValue: PChar): Boolean;
    function ReadValue(AnAttrib: Cardinal; out AValue: String): Boolean;
    function ReadValue(AnAttrib: Cardinal; out AValue: TByteDynArray): Boolean;
    function ReadReference(AnAttrib: Cardinal; out AValue: Pointer; out ACompUnit: TDwarfCompilationUnit): Boolean;

    function  ReadName(out AName: String): Boolean; inline;
    function  ReadName(out AName: PChar): Boolean; inline;
    function  ReadStartScope(out AStartScope: TDbgPtr): Boolean; inline;
    function  IsAddressInStartScope(AnAddress: TDbgPtr): Boolean; inline;
    function  IsArtificial: Boolean; inline;
  public
    // Scope
    procedure GoParent; inline;
    procedure GoNext; inline;
    procedure GoChild; inline;
    function HasValidScope: Boolean; inline;
    property ScopeIndex: Integer read GetScopeIndex write SetScopeIndex;

    function ScopeDebugText: String;
  end;
{%endregion Information Entry / Section "debug_info"}

{%region Line Info / Section "debug_line"}
  { TDwarfLineInfoStateMachine }

  TDwarfLineInfoStateMachine = class(TObject)
  private
    FOwner: TDwarfCompilationUnit;
    FLineInfoPtr: Pointer;
    FMaxPtr: Pointer;
    FEnded: Boolean;

    FAddress: QWord;
    FFileName: String;
    FLine: Cardinal;
    FColumn: Cardinal;
    FIsStmt: Boolean;
    FBasicBlock: Boolean;
    FEndSequence: Boolean;
    FPrologueEnd: Boolean;
    FEpilogueBegin: Boolean;
    FIsa: QWord;
    
    procedure SetFileName(AIndex: Cardinal);
  protected
  public
    constructor Create(AOwner: TDwarfCompilationUnit; ALineInfoPtr, AMaxPtr: Pointer);
    function Clone: TDwarfLineInfoStateMachine;
    function NextLine: Boolean;
    procedure Reset;
  
    property Address: QWord read FAddress;
    property FileName: String read FFileName;
    property Line: Cardinal read FLine;
    property Column: Cardinal read FColumn;
    property IsStmt: Boolean read FIsStmt;
    property BasicBlock: Boolean read FBasicBlock;
    property EndSequence: Boolean read FEndSequence;
    property PrologueEnd: Boolean read FPrologueEnd;
    property EpilogueBegin: Boolean read FEpilogueBegin;
    property Isa: QWord read FIsa;
    
    property Ended: Boolean read FEnded;
  end;

  PDwarfAddressInfo = ^TDwarfAddressInfo;
  TDwarfAddressInfo = record
    ScopeIndex: Integer;
    ScopeList: PDwarfScopeList;
    StartPC: QWord;
    EndPC: QWord;
    StateMachine: TDwarfLineInfoStateMachine; // set if info found
    Name: PChar;
  end;

  { TDWarfLineMap }

  TDWarfLineMap = object
  private
    NextAFterHighestLine: Cardinal;
    AddressList: array of QWord;
    //Count: Integer;
  public
    procedure Init;
    procedure SetAddressForLine(ALine: Cardinal; AnAddress: QWord); inline;
    function  GetAddressForLine(ALine: Cardinal): QWord; inline;
    procedure Compress;
  end;
  PDWarfLineMap = ^TDWarfLineMap;
{%endregion Line Info / Section "debug_line"}

{%region Base classes for handling Symbols in unit FPDbgDwarf}
  { TDbgDwarfSymbolBase }

  TDbgDwarfSymbolBase = class(TDbgSymbolForwarder)
  private
    FCU: TDwarfCompilationUnit;
    FInformationEntry: TDwarfInformationEntry;
  protected
    procedure Init; virtual;
  public
    constructor Create(AName: String; AnInformationEntry: TDwarfInformationEntry);
    constructor Create(AName: String; AnInformationEntry: TDwarfInformationEntry;
                       AKind: TDbgSymbolKind; AAddress: TFpDbgMemLocation);
    destructor Destroy; override;

    property CompilationUnit: TDwarfCompilationUnit read FCU;
    property InformationEntry: TDwarfInformationEntry read FInformationEntry;
  end;
  TDbgDwarfSymbolBaseClass = class of TDbgDwarfSymbolBase;

  { TFpDwarfSymbolClassMap
    Provides Symbol and VAlue evaluation classes depending on the compiler
  }

  TFpDwarfSymbolClassMap = class
  public
    class function HandleCompUnit(ACU: TDwarfCompilationUnit): Boolean; virtual; abstract;
    class function GetDwarfSymbolClass(ATag: Cardinal): TDbgDwarfSymbolBaseClass; virtual; abstract;
    class function CreateContext(AThreadId, AStackFrame: Integer; AnAddress: TDbgPtr; ASymbol: TFpDbgSymbol;
                                 ADwarf: TFpDwarfInfo): TFpDbgInfoContext; virtual; abstract;
    class function CreateProcSymbol(ACompilationUnit: TDwarfCompilationUnit;
                                    AInfo: PDwarfAddressInfo; AAddress: TDbgPtr): TDbgDwarfSymbolBase; virtual; abstract;
  end;
  TFpDwarfSymbolClassMapClass = class of TFpDwarfSymbolClassMap;

  { TFpDwarfSymbolClassMapList }

  TFpDwarfSymbolClassMapList = class
  private
    FDefaultMap: TFpDwarfSymbolClassMapClass;
    FMapList: array of TFpDwarfSymbolClassMapClass;
  public
    function FindMapForCompUnit(ACU: TDwarfCompilationUnit): TFpDwarfSymbolClassMapClass;
    procedure AddMap(AMap: TFpDwarfSymbolClassMapClass);
    procedure SetDefaultMap(AMap: TFpDwarfSymbolClassMapClass);
  end;
{%endregion Base classes for handling Symbols in unit FPDbgDwarf}

  TDwarfSectionInfo = record
    Section: TDwarfSection;
    VirtualAddress: QWord;
    Size: QWord; // the virtual size
    RawData: Pointer;
  end;
  PDwarfSectionInfo = ^TDwarfSectionInfo;

  TDwarfDebugFile = record
    Sections: array[TDwarfSection] of TDwarfSectionInfo;
    AddressMapList: TDbgAddressMapList;
  end;
  PDwarfDebugFile = ^TDwarfDebugFile;

  { TDwarfCompilationUnit }

  TDwarfCompilationUnitClass = class of TDwarfCompilationUnit;
  TDwarfCompilationUnit = class
  private
    FOwner: TFpDwarfInfo;
    FDebugFile: PDwarfDebugFile;
    FDwarfSymbolClassMap: TFpDwarfSymbolClassMapClass;
    FValid: Boolean; // set if the compilationunit has compile unit tag.
  
    // --- Header ---
    FLength: QWord;  // length of info
    FVersion: Word;
    FAbbrevOffset: QWord;
    FAddressSize: Byte;  // the address size of the target in bytes
    FIsDwarf64: Boolean; // Set if the dwarf info in this unit is 64bit
    // ------
    
    FInfoData: Pointer;
    FFileName: String;
    FCompDir:  String;
    FUnitName: String;
    FIdentifierCase: Integer;
    FProducer: String;

    FAbbrevList: TDwarfAbbrevList;

    FLineInfo: record
      Header: Pointer;
      DataStart: Pointer;
      DataEnd: Pointer;

      Valid: Boolean;
      Addr64: Boolean;
      MinimumInstructionLength: Byte;
      DefaultIsStmt: Boolean;
      LineBase: ShortInt;
      LineRange: Byte;
      StandardOpcodeLengths: array of Byte; //record end; {array[1..OpcodeBase-1] of Byte}
      Directories: TStringList;
      FileNames: TStringList;
      // the line info is build incrementy when needed
      StateMachine: TDwarfLineInfoStateMachine;
      StateMachines: TFPObjectList; // list of state machines to be freed
    end;
    
    FLineNumberMap: TStringList;

    FAddressMap: TMap;
    FAddressMapBuild: Boolean;
    
    FMinPC: QWord;  // the min and max PC value found in this unit.
    FMaxPC: QWord;  //
    FScope: TDwarfScopeInfo;
    FScopeList: TDwarfScopeList;
    FScannedToEnd: Boolean;

    procedure BuildAddressMap;
    function GetAddressMap: TMap;
    function GetUnitName: String;
    function  ReadAddressAtPointer(var AData: Pointer; AIncPointer: Boolean = False): TFpDbgMemLocation;
  protected
    function LocateEntry(ATag: Cardinal; out AResultScope: TDwarfScopeInfo): Boolean;
    function InitLocateAttributeList(AEntry: Pointer; var AList: TAttribPointerList): Boolean;
    function LocateAttribute(AEntry: Pointer; AAttribute: Cardinal; var AList: TAttribPointerList;
                             out AAttribPtr: Pointer; out AForm: Cardinal): Boolean;
    function LocateAttribute(AEntry: Pointer; AAttribute: Cardinal;
                             out AAttribPtr: Pointer; out AForm: Cardinal): Boolean;

    function ReadValue(AAttribute: Pointer; AForm: Cardinal; out AValue: Integer): Boolean;
    function ReadValue(AAttribute: Pointer; AForm: Cardinal; out AValue: Int64): Boolean;
    function ReadValue(AAttribute: Pointer; AForm: Cardinal; out AValue: Cardinal): Boolean;
    function ReadValue(AAttribute: Pointer; AForm: Cardinal; out AValue: QWord): Boolean;
    function ReadValue(AAttribute: Pointer; AForm: Cardinal; out AValue: String): Boolean;
    function ReadValue(AAttribute: Pointer; AForm: Cardinal; out AValue: PChar): Boolean;
    function ReadValue(AAttribute: Pointer; AForm: Cardinal; out AValue: TByteDynArray): Boolean;
    // Read a value that contains an address. The address is evaluated using MapAddressToNewValue
    function ReadAddressValue(AAttribute: Pointer; AForm: Cardinal; out AValue: QWord): Boolean;

  public
    constructor Create(AOwner: TFpDwarfInfo; ADebugFile: PDwarfDebugFile; ADataOffset: QWord; ALength: QWord; AVersion: Word; AAbbrevOffset: QWord; AAddressSize: Byte; AIsDwarf64: Boolean); virtual;
    destructor Destroy; override;
    procedure ScanAllEntries; inline;
    function GetDefinition(AAbbrevPtr: Pointer; out ADefinition: TDwarfAbbrev): Boolean; inline;
    function GetLineAddressMap(const AFileName: String): PDWarfLineMap;
    function GetLineAddress(const AFileName: String; ALine: Cardinal): TDbgPtr;
    procedure BuildLineInfo(AAddressInfo: PDwarfAddressInfo; ADoAll: Boolean);
    function FullFileName(const AFileName:string): String;
    // On Darwin it could be that the debug-information is not included into the executable by the linker.
    // This function is to map object-file addresses into the corresponding addresses in the executable.
    function MapAddressToNewValue(AValue: QWord): QWord;

    property Valid: Boolean read FValid;
    property FileName: String read FFileName;
    property UnitName: String read GetUnitName;
    property IdentifierCase: Integer read FIdentifierCase;
    property Producer: String read FProducer;

    property Version: Word read FVersion;
    //property AbbrevOffset: QWord read FAbbrevOffset;
    property AddressSize: Byte read FAddressSize;  // the address size of the target in bytes
    property IsDwarf64: Boolean read FIsDwarf64; // Set if the dwarf info in this unit is 64bit
    property Owner: TFpDwarfInfo read FOwner;
    property DebugFile: PDwarfDebugFile read FDebugFile;

    property DwarfSymbolClassMap: TFpDwarfSymbolClassMapClass read FDwarfSymbolClassMap;
    property FirstScope: TDwarfScopeInfo read FScope;

    // public for FpDbgDwarfVerbosePrinter
    property InfoData: Pointer read FInfoData;
    property InfoDataLength: QWord read FLength;  // length of info
    property AddressMap: TMap read GetAddressMap;
    property AbbrevList: TDwarfAbbrevList read FAbbrevList;

  end;
  
  { TFpDwarfInfo }

  TFpDwarfInfo = class(TDbgInfo)
  private
    FCompilationUnits: TList;
    FImageBase: QWord;
    FMemManager: TFpDbgMemManager;
    FFiles: array of TDwarfDebugFile;
    function GetCompilationUnit(AIndex: Integer): TDwarfCompilationUnit;
  protected
    function GetCompilationUnitClass: TDwarfCompilationUnitClass; virtual;
    function FindCompilationUnitByOffs(AOffs: QWord): TDwarfCompilationUnit;
    function FindProcSymbol(AAddress: TDbgPtr): TDbgDwarfSymbolBase;
  public
    constructor Create(ALoaderList: TDbgImageLoaderList); override;
    destructor Destroy; override;
    function FindContext(AThreadId, AStackFrame: Integer; AAddress: TDbgPtr = 0): TFpDbgInfoContext; override;
    function FindContext(AAddress: TDbgPtr): TFpDbgInfoContext; override;
    function FindSymbol(AAddress: TDbgPtr): TFpDbgSymbol; override;
    //function FindSymbol(const AName: String): TDbgSymbol; override;
    function GetLineAddress(const AFileName: String; ALine: Cardinal): TDbgPtr; override;
    function GetLineAddressMap(const AFileName: String): PDWarfLineMap;
    function LoadCompilationUnits: Integer;
    function PointerFromRVA(ARVA: QWord): Pointer;
    function CompilationUnitsCount: Integer;
    property CompilationUnits[AIndex: Integer]: TDwarfCompilationUnit read GetCompilationUnit;
    property MemManager: TFpDbgMemManager read FMemManager write FMemManager;

    property ImageBase: QWord read FImageBase;
  end;

  { TDwarfLocationStack }

  TDwarfLocationStackEntryKind = (
    lseRegister,      // value copied from register (data is in register)
    lseValue,         // unsigned number, or address at which value can be found
    lsePart,          // partial data in next stack entry
    lseError
  );

  TDwarfLocationStackEntry = record
    Value: TFpDbgMemLocation; // Address of data, unless lseRegister (in vhich case this holds the data (copy of register)
    Kind:  TDwarfLocationStackEntryKind;
  end;

  TDwarfLocationStack = object
  private
    FList: array of TDwarfLocationStackEntry;
    FCount: Integer;
    procedure IncCapacity;
  public
    procedure Clear;
    function  Count: Integer;
    function  Pop: TDwarfLocationStackEntry;
    function  Peek: TDwarfLocationStackEntry;
    function  PeekKind: TDwarfLocationStackEntryKind;
    function  Peek(AIndex: Integer): TDwarfLocationStackEntry;
    procedure Push(const AEntry: TDwarfLocationStackEntry);
    procedure Push(AValue: TFpDbgMemLocation; AKind: TDwarfLocationStackEntryKind);
    procedure Push(AValue: TDbgPtr; AKind: TDwarfLocationStackEntryKind); // mlfTargetMem
    procedure Modify(AIndex: Integer; const AEntry: TDwarfLocationStackEntry);
    procedure Modify(AIndex: Integer; AValue: TFpDbgMemLocation; AKind: TDwarfLocationStackEntryKind);
    procedure Modify(AIndex: Integer; AValue: TDbgPtr; AKind: TDwarfLocationStackEntryKind); // mlfTargetMem
  end;

  { TDwarfLocationExpression }

  TDwarfLocationExpression = class
  private
    FContext: TFpDbgAddressContext;
    FCurrentObjectAddress: TFpDbgMemLocation;
    FFrameBase: TDbgPtr;
    FLastError: TFpError;
    FOnFrameBaseNeeded: TNotifyEvent;
    FStack: TDwarfLocationStack;
    FCU: TDwarfCompilationUnit;
    FData: PByte;
    FMaxData: PByte;
    FMemManager: TFpDbgMemManager;
  public
  //TODO: caller keeps data, and determines livetime of data
    constructor Create(AExpressionData: Pointer; AMaxCount: Integer; ACU: TDwarfCompilationUnit;
      AMemManager: TFpDbgMemManager; AContext: TFpDbgAddressContext);
    procedure Evaluate;
    function  ResultKind: TDwarfLocationStackEntryKind;
    function  ResultData: TDbgPtr;
    procedure Push(AValue: TFpDbgMemLocation; AKind: TDwarfLocationStackEntryKind);
    property  FrameBase: TDbgPtr read FFrameBase write FFrameBase;
    property  OnFrameBaseNeeded: TNotifyEvent read FOnFrameBaseNeeded write FOnFrameBaseNeeded;
    property LastError: TFpError read FLastError;
    property MemManager: TFpDbgMemManager read FMemManager;
    property Context: TFpDbgAddressContext read FContext write FContext;
    // for DW_OP_push_object_address
    property CurrentObjectAddress: TFpDbgMemLocation read FCurrentObjectAddress write FCurrentObjectAddress;
    end;

function ULEB128toOrdinal(var p: PByte): QWord;
function SLEB128toOrdinal(var p: PByte): Int64;

function Dbgs(AInfoData: Pointer; ACompUnit: TDwarfCompilationUnit): String; overload;
function Dbgs(AScope: TDwarfScopeInfo; ACompUnit: TDwarfCompilationUnit): String; overload;
function Dbgs(AInfoEntry: TDwarfInformationEntry; ACompUnit: TDwarfCompilationUnit): String; overload;
function DbgsDump(AScope: TDwarfScopeInfo; ACompUnit: TDwarfCompilationUnit): String; overload;

function GetDwarfSymbolClassMapList: TFpDwarfSymbolClassMapList; inline;

property DwarfSymbolClassMapList: TFpDwarfSymbolClassMapList read GetDwarfSymbolClassMapList;

implementation

var
  FPDBG_DWARF_ERRORS, FPDBG_DWARF_WARNINGS, FPDBG_DWARF_SEARCH, FPDBG_DWARF_VERBOSE,
  // FPDBG_DWARF_DATA_WARNINGS,
  FPDBG_DWARF_VERBOSE_LOAD: PLazLoggerLogGroup;

var
  TheDwarfSymbolClassMapList: TFpDwarfSymbolClassMapList;

const
  SCOPE_ALLOC_BLOCK_SIZE = 4096; // Increase scopelist in steps of

function GetDwarfSymbolClassMapList: TFpDwarfSymbolClassMapList;
begin
  Result := TheDwarfSymbolClassMapList;
end;

function Dbgs(AInfoData: Pointer; ACompUnit: TDwarfCompilationUnit): String;
var
  Attrib: Pointer;
  Form: Cardinal;
  Name: String;
  Def: TDwarfAbbrev;
begin
  Result := '';

  if ACompUnit.LocateAttribute(AInfoData, DW_AT_name, Attrib, Form) then
    if (Form = DW_FORM_string) or (Form = DW_FORM_strp) then
      ACompUnit.ReadValue(Attrib, Form, Name);

  if ACompUnit.GetDefinition(AInfoData, Def) then
    Result := Format('Tag=%s Name=%s', [DwarfTagToString(Def.tag), Name])
  else
    Result := Format('Name=%s', [Name]);
end;

function dbgs(AScope: TDwarfScopeInfo; ACompUnit: TDwarfCompilationUnit): String;
begin
  if not AScope.IsValid then
    exit('Invalid-Scope');
  Result := Format('AScope(Idx=%d %s)', [AScope.Index, dbgs(AScope.Entry, ACompUnit)]);
end;

function Dbgs(AInfoEntry: TDwarfInformationEntry; ACompUnit: TDwarfCompilationUnit): String;
begin
  if AInfoEntry.HasValidScope
  then Result := Dbgs(AInfoEntry.FScope, ACompUnit)
  else Result := Dbgs(AInfoEntry.FInformationEntry, ACompUnit);
end;

function DbgsDump(AScope: TDwarfScopeInfo; ACompUnit: TDwarfCompilationUnit): String;
var
  Def: TDwarfAbbrev;
  i: Integer;
begin
  Result := '';
  if not AScope.IsValid then
    exit('Invalid-Scope');

  if ACompUnit.GetDefinition(AScope.Entry, Def) then begin
  Result := LineEnding;
    for i := Def.index to Def.index + Def.count - 1 do begin
      Result := Result +
        DwarfAttributeToString(ACompUnit.FAbbrevList.EntryPointer[i]^.Attribute) + ' ' +
        DwarfAttributeFormToString(ACompUnit.FAbbrevList.EntryPointer[i]^.Form) +
        LineEnding;
    end;
  end;
end;

function ULEB128toOrdinal(var p: PByte): QWord;
var
  n: Byte;
  Stop: Boolean;
begin
  Result := 0;
  n := 0;
  repeat
    Stop := (p^ and $80) = 0;
    Result := Result + QWord(p^ and $7F) shl n;
    Inc(n, 7);
    Inc(p);
  until Stop or (n > 128);
end;

function SLEB128toOrdinal(var p: PByte): Int64;
var
  n: Byte;
  Stop: Boolean;
begin
  Result := 0;
  n := 0;
  repeat
    Stop := (p^ and $80) = 0;
    Result := Result + Int64(p^ and $7F) shl n;
    Inc(n, 7);
    Inc(p);
  until Stop or (n > 128);

  // sign extend when msbit = 1
  if (p[-1] and $40) <> 0
  then Result := Result or (Int64(-1) shl n);
end;

function SkipEntryDataForForm(var AEntryData: Pointer; AForm: Cardinal; AddrSize: Byte; IsDwarf64: boolean; Version: word): Boolean; inline;
var
  UValue: QWord;
begin
  Result := True;
  case AForm of
    DW_FORM_addr     : Inc(AEntryData, AddrSize);
    DW_FORM_block    : begin
        UValue := ULEB128toOrdinal(AEntryData);
        Inc(AEntryData, UValue);
      end;
    DW_FORM_block1   : Inc(AEntryData, PByte(AEntryData)^ + 1);
    DW_FORM_block2   : Inc(AEntryData, PWord(AEntryData)^ + 2);
    DW_FORM_block4   : Inc(AEntryData, PLongWord(AEntryData)^ + 4);
    DW_FORM_data1    : Inc(AEntryData, 1);
    DW_FORM_data2    : Inc(AEntryData, 2);
    DW_FORM_data4    : Inc(AEntryData, 4);
    DW_FORM_data8    : Inc(AEntryData, 8);
    DW_FORM_sdata    : begin
        while (PByte(AEntryData)^ and $80) <> 0 do Inc(AEntryData);
        Inc(AEntryData);
      end;
    DW_FORM_udata    : begin
        while (PByte(AEntryData)^ and $80) <> 0 do Inc(AEntryData);
        Inc(AEntryData);
      end;
    DW_FORM_flag     : Inc(AEntryData, 1);
    DW_FORM_ref1     : Inc(AEntryData, 1);
    DW_FORM_ref2     : Inc(AEntryData, 2);
    DW_FORM_ref4     : Inc(AEntryData, 4);
    DW_FORM_ref8     : Inc(AEntryData, 8);
    DW_FORM_ref_udata: begin
        while (PByte(AEntryData)^ and $80) <> 0 do Inc(AEntryData);
        Inc(AEntryData);
      end;
    DW_FORM_strp: begin
        if IsDwarf64 then
          Inc(AEntryData, 8)
        else
          Inc(AEntryData, 4);
      end;
    DW_FORM_ref_addr : begin
        // In Dwarf-version 3 and higher, the size of a DW_FORM_ref_addr depends
        // on the Dwarf-format. In prior Dwarf-versions it is equal to the
        // Addres-size.
        if Version>2 then begin
          if IsDwarf64 then
            Inc(AEntryData, 8)
          else
            Inc(AEntryData, 4);
        end else begin
          Inc(AEntryData, AddrSize);
        end;
      end;
    DW_FORM_string   : begin
        while PByte(AEntryData)^ <> 0 do Inc(AEntryData);
        Inc(AEntryData);
      end;
    DW_FORM_indirect : begin
        while AForm = DW_FORM_indirect do AForm := ULEB128toOrdinal(AEntryData);
        Result := SkipEntryDataForForm(AEntryData, AForm, AddrSize, IsDwarf64, Version);
      end;
  else begin
      DebugLn(FPDBG_DWARF_WARNINGS, ['Error: Unknown Form: ', AForm]);
      Result := False;
    end;
  end;

end;

{ TLEB128PreFixTree }

procedure TLEB128PreFixTree.SetCapacity(ACapacity: integer);
begin
  FDataGrowStep      := Min(512, Max(64, ACapacity));
  FTableListGrowStep := Min(32,  Max(4,  ACapacity div 128));
//debugln(['TLEB128PreFixTree.SetCapacity ', ACapacity, '  ', FDataGrowStep, ' ', FTableListGrowStep]);

  SetLength(FTableList, 1); //FTableListGrowStep div 2);
  SetLength(FTableListGaps, 1); //FTableListGrowStep div 2);
  SetLength(FEndTableData, FDataGrowStep div 4);

  FTableList[0].LeadLow := 255;
  FTableList[0].LeadHigh := 0;
  FTableList[0].EndLow := 255;
  FTableList[0].EndHigh := 0;

  FTableListGaps[0].LeadTable := 0;
  FTableListGaps[0].EndTable  := 0;

  FLeadTableNextFreeIndex := 0; // first 16 are reserved
  FEndTableNextFreeIndex  := 0;
  FTableListNextFreeIndex := 1;

end;

procedure TLEB128PreFixTree.Finish;
begin
  //debugln(['TLEB128PreFixTree.Finish ',' t:', Length(FTableList) ,' => ', FTableListNextFreeIndex,' p:', Length(FLeadTableData) ,' => ', FLeadTableNextFreeIndex,' e:', Length(FEndTableData) ,' => ', FEndTableNextFreeIndex]);
  dec(FLeadTableNextFreeIndex, FTableListGaps[FTableListNextFreeIndex-1].LeadTable);
  dec(FEndTableNextFreeIndex, FTableListGaps[FTableListNextFreeIndex-1].EndTable);
  SetLength(FTableList,     FTableListNextFreeIndex);
  SetLength(FLeadTableData, FLeadTableNextFreeIndex);
  SetLength(FEndTableData,  FEndTableNextFreeIndex);
  // TODO: clear gaps
  SetLength(FTableListGaps, 0);
end;

function TLEB128PreFixTree.AddLeb128FromPointer(APointer: Pointer;
  const AData: TDwarfAbbrev): Pointer;
var
  TableListLen: Integer;

  procedure AllocLeadTableIndexes(AnAmount: Integer); inline;
  begin
    inc(FLeadTableNextFreeIndex, AnAmount);
    if Length(FLeadTableData) < FLeadTableNextFreeIndex then begin
      SetLength(FLeadTableData, FLeadTableNextFreeIndex + FDataGrowStep);
      //debugln(['IncreaseLeadTableListSize ', DbgS(self), ' ', FLeadTableNextFreeIndex ]);
    end;
  end;

  procedure AllocEndTableIndexes(AnAmount: Integer); inline;
  begin
    inc(FEndTableNextFreeIndex, AnAmount);
    if Length(FEndTableData) < FEndTableNextFreeIndex then begin
      SetLength(FEndTableData, FEndTableNextFreeIndex + FDataGrowStep);
      //debugln(['IncreaseEndTableListSize ', DbgS(self), ' ', FEndTableNextFreeIndex ]);
    end;
  end;

  function NewEntryInTableList: Cardinal; inline;
  begin
    if FTableListNextFreeIndex >= TableListLen then begin
      //debugln(['inc(TableListLen, 512) ', DbgS(self), ' ', TableListLen]);
      inc(TableListLen, FTableListGrowStep);
      SetLength(FTableList, TableListLen);
      SetLength(FTableListGaps, TableListLen);
    end;

    Result := FTableListNextFreeIndex;
    FTableList[Result].LeadLow  := 255;
    FTableList[Result].LeadHigh := 0;
    FTableList[Result].EndLow  := 255;
    FTableList[Result].EndHigh := 0;
    FTableListGaps[Result].LeadTable := 0;
    FTableListGaps[Result].EndTable  := 0;
    inc(FTableListNextFreeIndex);
  end;

  procedure AppendToLeadTable(ATableListIndex: Cardinal; AEntry: PLeb128TableEntry;
    ALeadByte: Byte; ATarget: Cardinal); //inline;
  var
    GapAvail, ANeeded: Integer;
    AtEnd: Boolean;
    i, NewIndex: Cardinal;
  begin
    if AEntry^.LeadLow > AEntry^.LeadHigh then
    begin // empty table // create new
      AEntry^.LeadLow := ALeadByte;
      AEntry^.LeadIndex := FLeadTableNextFreeIndex;
      AllocLeadTableIndexes(16);
      FTableListGaps[ATableListIndex].LeadTable := 15; // 16-1
    end
    else
    begin // append to existing
      GapAvail := FTableListGaps[ATableListIndex].LeadTable;
      assert(AEntry^.LeadIndex + AEntry^.LeadHigh - AEntry^.LeadLow + 1 + GapAvail <= FLeadTableNextFreeIndex);
      AtEnd := AEntry^.LeadIndex + AEntry^.LeadHigh - AEntry^.LeadLow + 1 + GapAvail = FLeadTableNextFreeIndex;
      ANeeded := ALeadByte - AEntry^.LeadHigh;

      if ANeeded <= GapAvail then begin
        dec(FTableListGaps[ATableListIndex].LeadTable, ANeeded);
      end
      else
      if AtEnd then begin
        AllocLeadTableIndexes(ANeeded + 16);
        FTableListGaps[ATableListIndex].LeadTable := 16;
      end
      else
      begin
        // Todo deal with the GAP at the old location
        i := AEntry^.LeadHigh - AEntry^.LeadLow + 1; // Current Size
        NewIndex := FLeadTableNextFreeIndex;
        //DebugLn(['MOVING LEAD', DbgS(self), ' From: ', AEntry^.LeadIndex, ' To: ', NewIndex] );
        AllocLeadTableIndexes(i + ANeeded +16);
        move(FLeadTableData[AEntry^.LeadIndex], FLeadTableData[NewIndex], i * SizeOf(FLeadTableData[0]));
        AEntry^.LeadIndex := NewIndex;
        FTableListGaps[ATableListIndex].LeadTable := 16;
      end;
    end; // append to existing

    AEntry^.LeadHigh := ALeadByte;
    i := AEntry^.LeadIndex + ALeadByte - AEntry^.LeadLow;
    FLeadTableData[i] := ATarget;
  end;

  procedure PrependToLeadTable(ATableListIndex: Cardinal; AEntry: PLeb128TableEntry;
    ALeadByte: Byte; ATarget: Cardinal); //inline;
  var
    GapAvail, ANeeded: Integer;
    AtEnd: Boolean;
    i, NewIndex: Cardinal;
  begin
    Assert(AEntry^.LeadLow <= AEntry^.LeadHigh, 'emty table must be handled by append');
    GapAvail := FTableListGaps[ATableListIndex].LeadTable;
    assert(AEntry^.LeadIndex + AEntry^.LeadHigh - AEntry^.LeadLow + 1 + GapAvail <= FLeadTableNextFreeIndex);
    AtEnd := AEntry^.LeadIndex + AEntry^.LeadHigh - AEntry^.LeadLow + 1 + GapAvail = FLeadTableNextFreeIndex;
    ANeeded := AEntry^.LeadLow - ALeadByte;

    if (ANeeded <= GapAvail) or AtEnd then begin
      if (ANeeded > GapAvail) then begin
        AllocLeadTableIndexes(ANeeded + 16);
        FTableListGaps[ATableListIndex].LeadTable := 16;
      end
      else
        dec(FTableListGaps[ATableListIndex].LeadTable, ANeeded);
      NewIndex := AEntry^.LeadIndex + ANeeded;
      i := AEntry^.LeadHigh - AEntry^.LeadLow + 1; // Current size
      move(FLeadTableData[AEntry^.LeadIndex], FLeadTableData[NewIndex], i * SizeOf(FLeadTableData[0]));
      FillByte(FLeadTableData[AEntry^.LeadIndex+1], Min(i, ANeeded-1) * SizeOf(FLeadTableData[0]), 0);
    end
    else
    begin
      // Todo deal with the GAP at the old location
      i := AEntry^.LeadHigh - AEntry^.LeadLow + 1; // Current Size
      NewIndex := FLeadTableNextFreeIndex;
      //DebugLn(['MOVING LEAD', DbgS(self), ' From: ', AEntry^.LeadIndex, ' To: ', NewIndex] );
      AllocLeadTableIndexes(i + ANeeded + 16);
      move(FLeadTableData[AEntry^.LeadIndex], FLeadTableData[NewIndex+ANeeded], i * SizeOf(FLeadTableData[0]));
      // FillByte only neede, if gap will be reclaimed
      //FillByte(FLeadTableData[AEntry^.LeadIndex], i * SizeOf(FLeadTableData[0]), 0);
      AEntry^.LeadIndex := NewIndex;
      FTableListGaps[ATableListIndex].LeadTable := 16;
    end;


    AEntry^.LeadLow := ALeadByte;
    FLeadTableData[AEntry^.LeadIndex] := ATarget;
  end;

  procedure AppendToEndTable(ATableListIndex: Cardinal; AEntry: PLeb128TableEntry;
    ALeadByte: Byte; const AData: TDwarfAbbrev {Pointer}); //inline;
  var
    GapAvail, ANeeded: Integer;
    AtEnd: Boolean;
    i, NewIndex: Cardinal;
  begin
    if AEntry^.EndLow > AEntry^.EndHigh then
    begin // empty table // create new
      AEntry^.EndLow := ALeadByte;
      AEntry^.EndIndex := FEndTableNextFreeIndex;
      AllocEndTableIndexes(16);
      FTableListGaps[ATableListIndex].EndTable := 15; // 16-1
    end
    else
    begin // append to existing
      GapAvail := FTableListGaps[ATableListIndex].EndTable;
      assert(AEntry^.EndIndex + AEntry^.LeadHigh - AEntry^.LeadLow + 1 + GapAvail <= FEndTableNextFreeIndex);
      AtEnd := AEntry^.EndIndex + AEntry^.EndHigh - AEntry^.EndLow + 1 + GapAvail = FEndTableNextFreeIndex;
      ANeeded := ALeadByte - AEntry^.EndHigh;

      if ANeeded <= GapAvail then begin
        dec(FTableListGaps[ATableListIndex].EndTable, ANeeded);
      end
      else
      if AtEnd then begin
        AllocEndTableIndexes(ANeeded + 16);
        FTableListGaps[ATableListIndex].EndTable := 16;
      end
      else
      begin
        // Todo deal with the GAP at the old location
        i := AEntry^.EndHigh - AEntry^.EndLow + 1; // Current Size
        NewIndex := FEndTableNextFreeIndex;
        //DebugLn(['MOVING END',  DbgS(self), ' From: ', AEntry^.EndIndex, ' To: ', NewIndex ]);
        AllocEndTableIndexes(i + ANeeded + 16);
        move(FEndTableData[AEntry^.EndIndex], FEndTableData[NewIndex], i * SizeOf(FEndTableData[0]));
        AEntry^.EndIndex := NewIndex;
        FTableListGaps[ATableListIndex].EndTable := 16;
      end;
    end; // append to existing

    AEntry^.EndHigh := ALeadByte;
    i := AEntry^.EndIndex + ALeadByte - AEntry^.EndLow;
    FEndTableData[i] := AData;
  end;

  procedure PrependToEndTable(ATableListIndex: Cardinal; AEntry: PLeb128TableEntry;
    AEndByte: Byte; const AData: TDwarfAbbrev); //inline;
  var
    GapAvail, ANeeded: Integer;
    AtEnd: Boolean;
    i, NewIndex: Cardinal;
  begin
    Assert(AEntry^.EndLow <= AEntry^.EndHigh, 'emty table must be handled by append');
    GapAvail := FTableListGaps[ATableListIndex].EndTable;
    assert(AEntry^.EndIndex + AEntry^.EndHigh - AEntry^.EndLow + 1 + GapAvail <= FEndTableNextFreeIndex);
    AtEnd := AEntry^.EndIndex + AEntry^.EndHigh - AEntry^.EndLow + 1 + GapAvail = FEndTableNextFreeIndex;
    ANeeded := AEntry^.EndLow - AEndByte;

    if (ANeeded <= GapAvail) or AtEnd then begin
      if (ANeeded > GapAvail) then begin
        AllocEndTableIndexes(ANeeded + 16);
        FTableListGaps[ATableListIndex].EndTable := 16;
      end
      else
        dec(FTableListGaps[ATableListIndex].EndTable, ANeeded);
      NewIndex := AEntry^.EndIndex + ANeeded;
      i := AEntry^.EndHigh - AEntry^.EndLow + 1; // Current size
      move(FEndTableData[AEntry^.EndIndex], FEndTableData[NewIndex], i * SizeOf(FEndTableData[0]));
      FillByte(FEndTableData[AEntry^.EndIndex+1], Min(i, ANeeded-1) * SizeOf(FEndTableData[0]), 0);
    end
    else
    begin
      // Todo deal with the GAP at the old location
      i := AEntry^.EndHigh - AEntry^.EndLow + 1; // Current Size
      NewIndex := FEndTableNextFreeIndex;
      //DebugLn(['MOVING END', DbgS(self), ' From: ', AEntry^.EndIndex, ' To: ', NewIndex] );
      AllocEndTableIndexes(i + ANeeded + 16);
      move(FEndTableData[AEntry^.EndIndex], FEndTableData[NewIndex+ANeeded], i * SizeOf(FEndTableData[0]));
      // FillByte only neede, if gap will be reclaimed
      //FillByte(FEndTableData[AEntry^.EndIndex], i * SizeOf(FEndTableData[0]), 0);
      AEntry^.EndIndex := NewIndex;
      FTableListGaps[ATableListIndex].EndTable := 16;
    end;


    AEntry^.EndLow := AEndByte;
    FEndTableData[AEntry^.EndIndex] := AData;
  end;

var
  LEB128: PByte;
  b: Byte;
  TableListIndex: Integer;
  e: PLeb128TableEntry;
  i, NewIdx: Cardinal;
begin
  LEB128 := APointer;
  i := 16; // Just an abort condition, for malformed data.
  while (LEB128^ >= 128) do begin
    inc(LEB128);
    dec(i);
    if i = 0 then begin
      DebugLn(FPDBG_DWARF_WARNINGS, ['ENDLESS LEB128']);
      exit;
    end;
  end;
  Result := LEB128 + 1;

  TableListIndex := 0;
  TableListLen := Length(FTableList);

  while (LEB128 > APointer) and ((LEB128^ and $7f) = 0) do
    dec(LEB128);

  // LeadByte
  while LEB128 > APointer do begin
    b := LEB128^ and $7f;

    Assert(TableListIndex < TableListLen);
    e := @FTableList[TableListIndex];
    if (b > e^.LeadHigh) or (e^.LeadHigh < e^.LeadLow) then begin
      NewIdx := NewEntryInTableList;
      e := @FTableList[TableListIndex];
      AppendToLeadTable(TableListIndex, e, b, NewIdx);
      TableListIndex := NewIdx;
    end
    else
    if (b < e^.LeadLow) then begin
      NewIdx := NewEntryInTableList;
      e := @FTableList[TableListIndex];
      PrependToLeadTable(TableListIndex, e, b, NewIdx);
      TableListIndex := NewIdx;
    end
    else
    begin
      // existing entry
      i := e^.LeadIndex + b - e^.LeadLow;
      TableListIndex := FLeadTableData[i];
      if TableListIndex = 0 then begin // not yet assigned (not allowed to point back to 0)
        TableListIndex := NewEntryInTableList;
        FLeadTableData[i] := TableListIndex;
      end;
    end;

    dec(LEB128);
  end;

  // EndByte
  //if AData = nil then AData := LEB128;
  Assert(TableListIndex < TableListLen);
  b := LEB128^ and $7f;
  e := @FTableList[TableListIndex];
  if (b > e^.EndHigh) or (e^.EndHigh < e^.EndLow) then begin
    AppendToEndTable(TableListIndex, e, b, AData);
  end
  else
  if (b < e^.EndLow) then begin
    PrependToEndTable(TableListIndex, e, b, AData);
  end
  else
  begin
    // in existingc range
    i := e^.EndIndex + b - e^.EndLow;
    //assert(FEndTableData[i] = nil, 'Duplicate LEB128');
    FEndTableData[i] := AData;
  end;

end;

function TLEB128PreFixTree.FindLe128bFromPointer(APointer: Pointer; out
  AData: PDwarfAbbrev): Pointer;
var
  LEB128: PByte;
  b: Byte;
  TableListIndex: Integer;
  e: PLeb128TableEntry;
  i: Cardinal;
  TableListLen: Integer;
  LEB128End: PByte;
begin
  AData := nil;
  Result := nil;

  TableListLen := Length(FTableList);
  if TableListLen = 0 then
    exit;

  LEB128 := APointer;
  i := 16; // Just an abort condition, for malformed data.
  while (LEB128^ >= 128) do begin
    inc(LEB128);
    dec(i);
    if i = 0 then begin
      DebugLn(FPDBG_DWARF_WARNINGS, ['ENDLESS LEB128']);
      exit;
    end;
  end;
  LEB128End := LEB128;

  while (LEB128 > APointer) and ((LEB128^ and $7f) = 0) do
    dec(LEB128);

  TableListIndex := 0;
  // LeadByte
  while LEB128 > APointer do begin
    b := LEB128^ and $7f;

    Assert(TableListIndex < TableListLen);
    e := @FTableList[TableListIndex];
    if (b > e^.LeadHigh) or (b < e^.LeadLow) then begin
      //debugln('1 OUT OF RANGE / NOT FOUND!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      exit;
    end
    else
    begin
      TableListIndex := FLeadTableData[e^.LeadIndex + b - e^.LeadLow];
      if TableListIndex = 0 then begin // not yet assigned (not allowed to point back to 0)
        //debugln('3 OUT OF RANGE / NOT FOUND!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
        exit;
      end;
    end;

    dec(LEB128);
  end;

  // EndByte
  Assert(TableListIndex < TableListLen);
  b := LEB128^ and $7f;
  e := @FTableList[TableListIndex];
  if (b > e^.EndHigh) or (b < e^.EndLow) then begin
    //debugln('4 OUT OF RANGE / NOT FOUND!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
    exit;
  end
  else
  begin
    i := e^.EndIndex + b - e^.EndLow;
    //assert(FEndTableData[i] = nil, 'Duplicate LEB128');
    AData := @FEndTableData[i];
    if AData^.tag > 0 then // tag 0 does not exist
      Result := LEB128End+1;
  end;

end;

function TLEB128PreFixTree.FindLe128bFromPointer(APointer: Pointer; out
  AData: TDwarfAbbrev): Pointer;
var
  p: PDwarfAbbrev;
begin
  Result := FindLe128bFromPointer(APointer, p);
  if p = nil then begin
    AData.index := -1;
    AData.tag := 0;
    AData.count := 0;
    AData.flags := [];
  end
  else
    AData := p^;
end;

{ TDwarfAbbrevList }

function TDwarfAbbrevList.GetEntryPointer(AIndex: Integer): PDwarfAbbrevEntry;
begin
  Result := @FDefinitions[AIndex];
end;

procedure TDwarfAbbrevList.LoadAbbrevs(AnAbbrevDataPtr: Pointer);
  procedure MakeRoom(AMinSize: Integer);
  var
    len: Integer;
  begin
    len := Length(FDefinitions);
    if len > AMinSize then Exit;
    if len > $4000
    then Inc(len, $4000)
    else len := len * 2;
    SetLength(FDefinitions, len);
  end;
var
  p: Pointer;
  Def: TDwarfAbbrev;
  Def2: PDwarfAbbrev;
  abbrev, attrib, form: Cardinal;
  n: Integer;
  CurAbbrevIndex: Integer;
  DbgVerbose: Boolean;
  f: TDwarfAbbrevFlags;
begin
  abbrev := 0;
  CurAbbrevIndex := 0;
  DbgVerbose := (FPDBG_DWARF_VERBOSE_LOAD <> nil) and (FPDBG_DWARF_VERBOSE_LOAD^.Enabled);

  while (pbyte(AnAbbrevDataPtr) < FAbbrDataEnd) and (pbyte(AnAbbrevDataPtr)^ <> 0) do
  begin
    p := AnAbbrevDataPtr;
    abbrev := ULEB128toOrdinal(pbyte(AnAbbrevDataPtr));
    Def.tag := ULEB128toOrdinal(pbyte(AnAbbrevDataPtr));

    {$IFDEF USE_ABBREV_TMAP}
    if FMap.HasId(abbrev)
    {$ELSE}
    if FindLe128bFromPointer(p, Def2) <> nil
    {$Endif}
    then begin
      DebugLn(FPDBG_DWARF_WARNINGS, ['Duplicate abbrev=', abbrev, ' found. Ignoring....']);
      while pword(AnAbbrevDataPtr)^ <> 0 do Inc(pword(AnAbbrevDataPtr));
      Inc(pword(AnAbbrevDataPtr));
      Continue;
    end;

    if DbgVerbose
    then begin
      DebugLn(FPDBG_DWARF_VERBOSE_LOAD, ['  abbrev:  ', abbrev]);
      DebugLn(FPDBG_DWARF_VERBOSE_LOAD, ['  tag:     ', Def.tag, '=', DwarfTagToString(Def.tag)]);
      DebugLn(FPDBG_DWARF_VERBOSE_LOAD, ['  children:', pbyte(AnAbbrevDataPtr)^, '=', DwarfChildrenToString(pbyte(AnAbbrevDataPtr)^)]);
    end;
    if pbyte(AnAbbrevDataPtr)^ = DW_CHILDREN_yes then
      f := [dafHasChildren]
    else
      f := [];
    Inc(pbyte(AnAbbrevDataPtr));

    n := 0;
    Def.Index := CurAbbrevIndex;

    while pword(AnAbbrevDataPtr)^ <> 0 do
    begin
      attrib := ULEB128toOrdinal(pbyte(AnAbbrevDataPtr));
      if attrib = DW_AT_name then
        Include(f, dafHasName)
      else
      if attrib = DW_AT_low_pc then
        Include(f, dafHasLowAddr)
      else
      if attrib = DW_AT_start_scope then
        Include(f, dafHasStartScope)
      else
      if attrib = DW_AT_abstract_origin then
        Include(f, dafHasAbstractOrigin);

      form := ULEB128toOrdinal(pbyte(AnAbbrevDataPtr));

      MakeRoom(CurAbbrevIndex + 1);
      FDefinitions[CurAbbrevIndex].Attribute := attrib;
      FDefinitions[CurAbbrevIndex].Form := form;
      Inc(CurAbbrevIndex);

      if DbgVerbose
      then DebugLn(FPDBG_DWARF_VERBOSE_LOAD, ['   [', n, '] attrib: ', attrib, '=', DwarfAttributeToString(attrib), ', form: ', form, '=', DwarfAttributeFormToString(form)]);
      Inc(n);
    end;
    Def.Count := n;
    Def.flags := f;
    {$IFDEF USE_ABBREV_TMAP}
    FMap.Add(abbrev, Def);
    {$ELSE}
    AddLeb128FromPointer(p, Def);
    {$Endif}

    Inc(pword(AnAbbrevDataPtr));
  end;
end;

constructor TDwarfAbbrevList.Create(AnAbbrData, AnAbbrDataEnd: Pointer; AnAbbrevOffset,
  AInfoLen: QWord);
begin
  inherited Create;
  FAbbrDataEnd := AnAbbrDataEnd;
  {$IFDEF USE_ABBREV_TMAP}
  FMap := TMap.Create(itu4, SizeOf(TDwarfAbbrev));
  {$ELSE}
  SetCapacity(AInfoLen div 16 + 1);
  {$Endif}
  SetLength(FDefinitions, 256);
  LoadAbbrevs(AnAbbrData + AnAbbrevOffset);
  {$IFnDEF USE_ABBREV_TMAP}
  Finish;
  {$Endif}
end;

destructor TDwarfAbbrevList.Destroy;
begin
  {$IFDEF USE_ABBREV_TMAP}
  FreeAndNil(FMap);
  {$Endif}
  inherited Destroy;
end;

{$IFDEF USE_ABBREV_TMAP}
function TDwarfAbbrevList.FindLe128bFromPointer(AnAbbrevPtr: Pointer; out
  AData: TDwarfAbbrev): Pointer;
begin
  Result := AnAbbrevPtr;
  if not FMap.GetData(ULEB128toOrdinal(Result), AData) then
    Result := nil;
end;
{$Endif}

{ TDwarfScopeInfo }

procedure TDwarfScopeInfo.Init(AScopeList: PDwarfScopeList);
begin
  FIndex := -1;
  FScopeList := AScopeList;
end;

function TDwarfScopeInfo.IsValid: Boolean;
begin
  Result := FIndex >= 0;
end;

function TDwarfScopeInfo.GetNextIndex: Integer;
var
  l: Integer;
  p: PDwarfScopeInfoRec;
begin
  Result := -1;
  if (not IsValid) or (FScopeList^.HighestKnown = FIndex) then exit;
  // Use pointer, to avoid calculating the index twice
  p := @FScopeList^.List[FIndex + 1];
  Result := p^.Link;
  assert(Result <= FScopeList^.HighestKnown);
  if (Result > FIndex + 1) then       // Index+1 is First Child, with pointer to Next
    exit;

  l := (p-1)^.Link; // GetParent  (or -1 for toplevel)
  assert(l <= FScopeList^.HighestKnown);
  if l > Index then l := Index - 1;   // This is a first child, make l = parent
  if (Result = l) then begin          // Index + 1 has same parent
    Result := Index + 1;
    exit;
  end;

  Result := -1;
end;

function TDwarfScopeInfo.GetNext: TDwarfScopeInfo;
begin
  Result.Init(FScopeList);
  if IsValid then
    Result.Index := GetNextIndex;
end;

function TDwarfScopeInfo.GetEntry: Pointer;
begin
  Result := nil;
  if IsValid then
    Result := FScopeList^.List[FIndex].Entry;
end;

function TDwarfScopeInfo.HasChild: Boolean;
var
  l2: Integer;
begin
  Result := (IsValid) and (FScopeList^.HighestKnown > FIndex);
  if not Result then exit;
  l2 := FScopeList^.List[FIndex + 1].Link;
  assert(l2 <= FScopeList^.HighestKnown);
  Result := (l2 > FIndex + 1) or        // Index+1 is First Child, with pointer to Next
            (l2 = FIndex);              // Index+1 is First Child, with pointer to parent (self)
end;

function TDwarfScopeInfo.GetChild: TDwarfScopeInfo;
begin
  Result.Init(FScopeList);
  if HasChild then begin
    Result.Index := FIndex + 1;
    assert(Result.Parent.Index = FIndex, 'child has self as parent');
  end;
end;

function TDwarfScopeInfo.GetChildIndex: Integer;
begin
  if HasChild then
    Result := FIndex + 1
  else
    Result := -1;
end;

function TDwarfScopeInfo.GetParent: TDwarfScopeInfo;
var
  l: Integer;
begin
  Result.Init(FScopeList);
  if not IsValid then exit;
  l := FScopeList^.List[FIndex].Link; // GetParent  (or -1 for toplevel)
  assert(l <= FScopeList^.HighestKnown);
  if l > Index then
    l := Index - 1;   // This is a first child, make l = parent
  Result.Index := l;
end;

function TDwarfScopeInfo.GetParentIndex: Integer;
begin
  Result := -1;
  if not IsValid then exit;
  Result := FScopeList^.List[FIndex].Link; // GetParent  (or -1 for toplevel)
  assert(Result <= FScopeList^.HighestKnown);
  if Result > Index then
    Result := Index - 1;   // This is a first child, make l = parent
end;

procedure TDwarfScopeInfo.SetIndex(AIndex: Integer);
begin
  if (AIndex >= 0) and (AIndex <= FScopeList^.HighestKnown) then
    FIndex := AIndex
  else
    FIndex := -1;
end;

function TDwarfScopeInfo.CreateScopeForEntry(AEntry: Pointer; ALink: Integer): Integer;
begin
  inc(FScopeList^.HighestKnown);
  Result := FScopeList^.HighestKnown;
  if Result >= Length(FScopeList^.List) then
    SetLength(FScopeList^.List, Result + SCOPE_ALLOC_BLOCK_SIZE);
  with FScopeList^.List[Result] do begin
    Entry := AEntry;
    Link := ALink;
  end;
end;

function TDwarfScopeInfo.HasParent: Boolean;
var
  l: Integer;
begin
  Result := (IsValid);
  if not Result then exit;
  l := FScopeList^.List[FIndex].Link;
  assert(l <= FScopeList^.HighestKnown);
  Result := (l >= 0);
end;

function TDwarfScopeInfo.HasNext: Boolean;
var
  l, l2: Integer;
begin
  Result := (IsValid) and (FScopeList^.HighestKnown > FIndex);
  if not Result then exit;
  l2 := FScopeList^.List[FIndex + 1].Link;
  assert(l2 <= FScopeList^.HighestKnown);
  Result := (l2 > FIndex + 1);        // Index+1 is First Child, with pointer to Next
  if Result then
    exit;

  l := FScopeList^.List[FIndex].Link; // GetParent  (or -1 for toplevel)
  assert(l <= FScopeList^.HighestKnown);
  if l > Index then
    l := Index - 1;   // This is a first child, make l = parent
  Result := (l2 = l);                 // Index + 1 has same parent
end;

procedure TDwarfScopeInfo.GoParent;
var
  l: Integer;
begin
  if not IsValid then exit;
  l := FScopeList^.List[FIndex].Link; // GetParent  (or -1 for toplevel)
  assert(l <= FScopeList^.HighestKnown);
  if l > Index then
    l := Index - 1;   // This is a first child, make l = parent
  FIndex := l;
end;

procedure TDwarfScopeInfo.GoNext;
begin
  FIndex := GetNextIndex;
end;

procedure TDwarfScopeInfo.GoChild;
begin
  if HasChild then
    FIndex := FIndex + 1
  else
    FIndex := -1;
end;

function TDwarfScopeInfo.CreateNextForEntry(AEntry: Pointer): Integer;
var
  l: Integer;
begin
  assert(IsValid, 'Creating Child for invalid scope');
  assert(NextIndex<0, 'Next already set');
  l := FScopeList^.List[FIndex].Link; // GetParent (or -1 for toplevel)
  assert(l <= FScopeList^.HighestKnown);
  if l > Index then l := Index - 1;   // This is a first child, make l = parent
  Result := CreateScopeForEntry(AEntry, l);
  if Result > FIndex + 1 then  // We have children
    FScopeList^.List[FIndex+1].Link := Result;
end;

function TDwarfScopeInfo.CreateChildForEntry(AEntry: Pointer): Integer;
begin
  assert(IsValid, 'Creating Child for invalid scope');
  assert(FIndex=FScopeList^.HighestKnown, 'Cannot creating Child.Not at end of list');
  Result := CreateScopeForEntry(AEntry, FIndex); // First Child, but no parent.next yet
end;

{ TDwarfLocationStack }

procedure TDwarfLocationStack.IncCapacity;
begin
  SetLength(FList, Max(Length(FList), FCount) + 64);
end;

procedure TDwarfLocationStack.Clear;
begin
  FCount := 0;
end;

function TDwarfLocationStack.Count: Integer;
begin
  Result := FCount;
end;

function TDwarfLocationStack.Pop: TDwarfLocationStackEntry;
begin
  if FCount = 0 then begin
    Result.Kind := lseError;
    exit;
  end;
  dec(FCount);
  Result := FList[FCount];
end;

function TDwarfLocationStack.Peek: TDwarfLocationStackEntry;
begin
  if FCount = 0 then begin
    Result.Kind := lseError;
    exit;
  end;
  Result := FList[FCount-1];
end;

function TDwarfLocationStack.PeekKind: TDwarfLocationStackEntryKind;
begin
  if FCount = 0 then begin
    Result := lseError;
    exit;
  end;
  Result := FList[FCount-1].Kind;
end;

function TDwarfLocationStack.Peek(AIndex: Integer): TDwarfLocationStackEntry;
begin
  if AIndex >= FCount then begin
    Result.Kind := lseError;
    exit;
  end;
  Result := FList[FCount-1-AIndex];
end;

procedure TDwarfLocationStack.Push(const AEntry: TDwarfLocationStackEntry);
begin
  if Length(FList) <= FCount then
    IncCapacity;
  FList[FCount] := AEntry;
  inc(FCount);
end;

procedure TDwarfLocationStack.Push(AValue: TFpDbgMemLocation;
  AKind: TDwarfLocationStackEntryKind);
begin
  if Length(FList) <= FCount then
    IncCapacity;
  FList[FCount].Value := AValue;
  FList[FCount].Kind  := AKind;
  inc(FCount);
end;

procedure TDwarfLocationStack.Push(AValue: TDbgPtr; AKind: TDwarfLocationStackEntryKind);
begin
  Push(TargetLoc(AValue), AKind);
end;

procedure TDwarfLocationStack.Modify(AIndex: Integer; const AEntry: TDwarfLocationStackEntry);
begin
  Assert(AIndex < FCount);
  if AIndex >= FCount then
    exit;
  FList[FCount-1-AIndex] := AEntry;
end;

procedure TDwarfLocationStack.Modify(AIndex: Integer; AValue: TFpDbgMemLocation;
  AKind: TDwarfLocationStackEntryKind);
begin
  Assert(AIndex < FCount);
  if AIndex >= FCount then
    exit;
  FList[FCount-1-AIndex].Value := AValue;
  FList[FCount-1-AIndex].Kind  := AKind;
end;

procedure TDwarfLocationStack.Modify(AIndex: Integer; AValue: TDbgPtr;
  AKind: TDwarfLocationStackEntryKind);
begin
  Assert(AIndex < FCount);
  if AIndex >= FCount then
    exit;
  FList[FCount-1-AIndex].Value := TargetLoc(AValue);
  FList[FCount-1-AIndex].Kind  := AKind;
end;

{ TDwarfLocationExpression }

constructor TDwarfLocationExpression.Create(AExpressionData: Pointer; AMaxCount: Integer;
  ACU: TDwarfCompilationUnit; AMemManager: TFpDbgMemManager; AContext: TFpDbgAddressContext);
begin
  FStack.Clear;
  FCU := ACU;
  FData := AExpressionData;
  FMaxData := FData + AMaxCount;
  FMemManager := AMemManager;
  FContext := AContext;
end;

procedure TDwarfLocationExpression.Evaluate;
var
  CurInstr, CurData: PByte;
  AddrSize: Byte;

  procedure SetError(AnInternalErrorCode: TFpErrorCode = fpErrNoError);
  begin
    FStack.Push(InvalidLoc, lseError); // Mark as failed
    if IsError(FMemManager.LastError)
    then FLastError := CreateError(fpErrLocationParserMemRead, FMemManager.LastError, [])
    else FLastError := CreateError(fpErrLocationParser, []);
    debugln(FPDBG_DWARF_ERRORS,
            ['DWARF ERROR in TDwarfLocationExpression: Failed at Pos=', CurInstr-FData,
             ' OpCode=', IntToHex(CurInstr^, 2), ' Depth=', FStack.Count,
             ' Data: ', dbgMemRange(FData, FMaxData-FData),
             ' MemReader.LastError: ', ErrorHandler.ErrorAsString(FMemManager.LastError),
             ' Extra: ', ErrorHandler.ErrorAsString(AnInternalErrorCode, []) ]);
  end;

  function AssertAddressOnStack: Boolean;
  begin
    Result := FStack.PeekKind in [lseValue, lseRegister]; // todo: allow register?
    if not Result then
      SetError(fpErrLocationParserNoAddressOnStack);
  end;

  function AssertMinCount(ACnt: Integer): Boolean;
  begin
    Result := FStack.Count >= ACnt;
    if not Result then
      SetError(fpErrLocationParserMinStack);
  end;

  function ReadAddressFromMemory(AnAddress: TFpDbgMemLocation; ASize: Cardinal; out AValue: TFpDbgMemLocation): Boolean;
  begin
    //TODO: zero fill / sign extend
    if (ASize > SizeOf(AValue)) or (ASize > AddrSize) then exit(False);
    Result := FMemManager.ReadAddress(AnAddress, ASize, AValue, FContext);
    if not Result then
      SetError;
  end;

  function ReadAddressFromMemoryEx(AnAddress: TFpDbgMemLocation; AnAddrSpace: TDbgPtr; ASize: Cardinal; out AValue: TFpDbgMemLocation): Boolean;
  begin
    //TODO: zero fill / sign extend
    if (ASize > SizeOf(AValue)) or (ASize > AddrSize) then exit(False);
    AValue := FMemManager.ReadAddressEx(AnAddress, AnAddrSpace, ASize, FContext);
    Result := IsValidLoc(AValue);
    if not Result then
      SetError;
  end;

  function ReadUnsignedFromExpression(var CurInstr: Pointer; ASize: Integer): TDbgPtr;
  begin
    case ASize of
      1: Result := PByte(CurInstr)^;
      2: Result := PWord(CurInstr)^;
      4: Result := PLongWord(CurInstr)^;
      8: Result := PQWord(CurInstr)^;
      0: Result := ULEB128toOrdinal(CurInstr);
    end;
    inc(CurInstr, ASize);
  end;

  function ReadSignedFromExpression(var CurInstr: Pointer; ASize: Integer): TDbgPtr;
  begin
    case ASize of
      1: Int64(Result) := PShortInt(CurInstr)^;
      2: Int64(Result) := PSmallInt(CurInstr)^;
      4: Int64(Result) := PLongint(CurInstr)^;
      8: Int64(Result) := PInt64(CurInstr)^;
      0: Int64(Result) := SLEB128toOrdinal(CurInstr);
    end;
    inc(CurInstr, ASize);
  end;

var
  NewLoc, Loc: TFpDbgMemLocation;
  NewValue: TDbgPtr;
  i: TDbgPtr;
  x : integer;
  Entry, Entry2: TDwarfLocationStackEntry;
begin
  AddrSize := FCU.FAddressSize;
  FMemManager.ClearLastError;
  FLastError := NoError;
  CurData := FData;
  while CurData < FMaxData do begin
    CurInstr := CurData;
    inc(CurData);
    case CurInstr^ of
      DW_OP_nop: ;
      DW_OP_addr:  FStack.Push(FCU.ReadAddressAtPointer(CurData, True), lseValue);
      DW_OP_deref: begin
          if not AssertAddressOnStack then exit;
          if not ReadAddressFromMemory(FStack.Pop.Value, AddrSize, NewLoc) then exit;
          FStack.Push(NewLoc, lseValue);
        end;
      DW_OP_xderef: begin
          if not AssertAddressOnStack  then exit;
          Loc := FStack.Pop.Value;
          if not AssertAddressOnStack then exit;
// TODO check address is valid
          if not ReadAddressFromMemoryEx(Loc, FStack.Pop.Value.Address, AddrSize, NewLoc) then exit;
          FStack.Push(NewLoc, lseValue);
        end;
      DW_OP_deref_size: begin
          if not AssertAddressOnStack then exit;
          if not ReadAddressFromMemory(FStack.Pop.Value, ReadUnsignedFromExpression(CurData, 1), NewLoc) then exit;
          FStack.Push(NewLoc, lseValue);
        end;
      DW_OP_xderef_size: begin
          if not AssertAddressOnStack  then exit;
          Loc := FStack.Pop.Value;
          if not AssertAddressOnStack then exit;
// TODO check address is valid
          if not ReadAddressFromMemoryEx(Loc, FStack.Pop.Value.Address, ReadUnsignedFromExpression(CurData, 1), NewLoc) then exit;
          FStack.Push(NewLoc, lseValue);
        end;

      DW_OP_const1u: FStack.Push(ReadUnsignedFromExpression(CurData, 1), lseValue);
      DW_OP_const2u: FStack.Push(ReadUnsignedFromExpression(CurData, 2), lseValue);
      DW_OP_const4u: FStack.Push(ReadUnsignedFromExpression(CurData, 4), lseValue);
      DW_OP_const8u: FStack.Push(ReadUnsignedFromExpression(CurData, 8), lseValue);
      DW_OP_constu:  FStack.Push(ReadUnsignedFromExpression(CurData, 0), lseValue);
      DW_OP_const1s: FStack.Push(ReadSignedFromExpression(CurData, 1), lseValue);
      DW_OP_const2s: FStack.Push(ReadSignedFromExpression(CurData, 2), lseValue);
      DW_OP_const4s: FStack.Push(ReadSignedFromExpression(CurData, 4), lseValue);
      DW_OP_const8s: FStack.Push(ReadSignedFromExpression(CurData, 8), lseValue);
      DW_OP_consts:  FStack.Push(ReadSignedFromExpression(CurData, 0), lseValue);
      DW_OP_lit0..DW_OP_lit31: FStack.Push(CurInstr^-DW_OP_lit0, lseValue);

      DW_OP_reg0..DW_OP_reg31: begin
          if not FMemManager.ReadRegister(CurInstr^-DW_OP_reg0, NewValue, FContext) then begin
            SetError;
            exit;
          end;
          FStack.Push(NewValue, lseRegister);
        end;
      DW_OP_regx: begin
          if not FMemManager.ReadRegister(ULEB128toOrdinal(CurData), NewValue, FContext) then begin
            SetError;
            exit;
          end;
          FStack.Push(NewValue, lseRegister);
        end;

      DW_OP_breg0..DW_OP_breg31: begin
          if not FMemManager.ReadRegister(CurInstr^-DW_OP_breg0, NewValue, FContext) then begin
            SetError;
            exit;
          end;
          {$PUSH}{$R-}{$Q-}
          FStack.Push(NewValue+SLEB128toOrdinal(CurData), lseValue);
          {$POP}
        end;
      DW_OP_bregx: begin
          if not FMemManager.ReadRegister(ULEB128toOrdinal(CurData), NewValue, FContext) then begin
            SetError;
            exit;
          end;
          {$PUSH}{$R-}{$Q-}
          FStack.Push(NewValue+SLEB128toOrdinal(CurData), lseValue);
          {$POP}
        end;

      DW_OP_fbreg: begin
          if (FFrameBase = 0) and (FOnFrameBaseNeeded <> nil) then FOnFrameBaseNeeded(Self);
          if FFrameBase = 0 then begin
            SetError;
            exit;
          end;
          {$PUSH}{$R-}{$Q-}
          FStack.Push(FFrameBase+SLEB128toOrdinal(CurData), lseValue);
          {$POP}
        end;

      DW_OP_dup: begin
          if not AssertMinCount(1) then exit;
          FStack.Push(FStack.Peek);
        end;
      DW_OP_drop: begin
          if not AssertMinCount(1) then exit;
          FStack.Pop;
        end;
      DW_OP_over: begin
          if not AssertMinCount(2) then exit;
          FStack.Push(FStack.Peek(1));
        end;
      DW_OP_pick: begin
          i := ReadUnsignedFromExpression(CurData, 1);
          if not AssertMinCount(i) then exit;
          FStack.Push(FStack.Peek(i));
        end;
      DW_OP_swap: begin
          if not AssertMinCount(2) then exit;
          Entry := FStack.Peek(0);
          FStack.Modify(0, FStack.Peek(1));
          FStack.Modify(1, Entry);
        end;
      DW_OP_rot: begin
          if not AssertMinCount(3) then exit;
          Entry := FStack.Peek(0);
          FStack.Modify(0, FStack.Peek(1));
          FStack.Modify(1, FStack.Peek(2));
          FStack.Modify(2, Entry);
        end;

      DW_OP_abs: begin
          if not AssertMinCount(1) then exit;
          Entry := FStack.Peek(0);
          FStack.Modify(0, abs(int64(Entry.Value.Address)), Entry.Kind); // treat as signed
        end;
      DW_OP_neg: begin
          if not AssertMinCount(1) then exit;
          Entry := FStack.Peek(0);
          FStack.Modify(0, TDbgPtr(-(int64(Entry.Value.Address))), Entry.Kind); // treat as signed
        end;
      DW_OP_plus: begin
          if not AssertMinCount(2) then exit;
          Entry  := FStack.Pop;
          Entry2 := FStack.Peek(0);
          {$PUSH}{$R-}{$Q-}
          //TODO: 32 bit overflow?
          FStack.Modify(0, Entry.Value.Address+Entry2.Value.Address, lseValue); // adding signed values works via overflow
          {$POP}
        end;
      DW_OP_plus_uconst: begin
          if not AssertMinCount(1) then exit;
          Entry := FStack.Peek(0);
          {$PUSH}{$R-}{$Q-}
          FStack.Modify(0, Entry.Value.Address+ULEB128toOrdinal(CurData), lseValue);
          {$POP}
        end;
      DW_OP_minus: begin
          if not AssertMinCount(2) then exit;
          Entry  := FStack.Pop;
          Entry2 := FStack.Peek(0);
          {$PUSH}{$R-}{$Q-}
          FStack.Modify(0, Entry2.Value.Address-Entry.Value.Address, lseValue); // adding signed values works via overflow
          {$POP}
        end;
      DW_OP_mul: begin
          if not AssertMinCount(2) then exit;
          Entry  := FStack.Pop;
          Entry2 := FStack.Peek(0);
          //{$PUSH}{$R-}{$Q-}
          FStack.Modify(0, TDbgPtr(int64(Entry2.Value.Address)*int64(Entry.Value.Address)), lseValue);
          //{$POP}
        end;
      DW_OP_div: begin
          if not AssertMinCount(2) then exit;
          Entry  := FStack.Pop;
          Entry2 := FStack.Peek(0);
          //{$PUSH}{$R-}{$Q-}
          FStack.Modify(0, TDbgPtr(int64(Entry2.Value.Address) div int64(Entry.Value.Address)), lseValue);
          //{$POP}
        end;
      DW_OP_mod: begin
          if not AssertMinCount(2) then exit;
          Entry  := FStack.Pop;
          Entry2 := FStack.Peek(0);
          //{$PUSH}{$R-}{$Q-}
          FStack.Modify(0, TDbgPtr(int64(Entry2.Value.Address) mod int64(Entry.Value.Address)), lseValue);
          //{$POP}
        end;

      DW_OP_and: begin
          if not AssertMinCount(2) then exit;
          Entry  := FStack.Pop;
          Entry2 := FStack.Peek(0);
          FStack.Modify(0, Entry2.Value.Address and Entry.Value.Address, lseValue);
        end;
      DW_OP_not: begin
          if not AssertMinCount(1) then exit;
          Entry := FStack.Peek(0);
          FStack.Modify(0, not Entry2.Value.Address and Entry.Value.Address, Entry.Kind);
        end;
      DW_OP_or: begin
          if not AssertMinCount(2) then exit;
          Entry  := FStack.Pop;
          Entry2 := FStack.Peek(0);
          FStack.Modify(0, Entry2.Value.Address or Entry.Value.Address, lseValue);
        end;
      DW_OP_xor: begin
          if not AssertMinCount(2) then exit;
          Entry  := FStack.Pop;
          Entry2 := FStack.Peek(0);
          FStack.Modify(0, Entry2.Value.Address xor Entry.Value.Address, lseValue);
        end;
      DW_OP_shl: begin
          if not AssertMinCount(2) then exit;
          Entry  := FStack.Pop;
          Entry2 := FStack.Peek(0);
          FStack.Modify(0, Entry2.Value.Address shl Entry.Value.Address, lseValue);
        end;
      DW_OP_shr: begin
          if not AssertMinCount(2) then exit;
          Entry  := FStack.Pop;
          Entry2 := FStack.Peek(0);
          FStack.Modify(0, Entry2.Value.Address shr Entry.Value.Address, lseValue);
        end;
      DW_OP_shra: begin
          if not AssertMinCount(2) then exit;
          Entry  := FStack.Pop;
          Entry2 := FStack.Peek(0);
          if Entry.Value.Address > 0 then
            FStack.Modify(0, Entry2.Value.Address div (1 shl (Entry.Value.Address - 1)), lseValue);
        end;

      DW_OP_skip: begin
          x := ReadSignedFromExpression(CurData, 2);
          CurData := CurData + x;
        end;
      DW_OP_bra: begin
          if not AssertMinCount(1) then exit;
          Entry  := FStack.Pop;
          x := ReadSignedFromExpression(CurData, 2);
          if Entry.Value.Address <> 0 then
            CurData := CurData + x;
        end;

      DW_OP_eq: begin
          if not AssertMinCount(2) then exit;
          Entry  := FStack.Pop;
          Entry2 := FStack.Peek(0);
          if Entry.Value.Address = Entry2.Value.Address
          then FStack.Modify(0, 1, lseValue)
          else FStack.Modify(0, 0, lseValue);
        end;
      DW_OP_ge: begin
          if not AssertMinCount(2) then exit;
          Entry  := FStack.Pop;
          Entry2 := FStack.Peek(0);
          if int64(Entry.Value.Address) >= int64(Entry2.Value.Address)
          then FStack.Modify(0, 1, lseValue)
          else FStack.Modify(0, 0, lseValue);
        end;
      DW_OP_gt: begin
          if not AssertMinCount(2) then exit;
          Entry  := FStack.Pop;
          Entry2 := FStack.Peek(0);
          if int64(Entry.Value.Address) > int64(Entry2.Value.Address)
          then FStack.Modify(0, 1, lseValue)
          else FStack.Modify(0, 0, lseValue);
        end;
      DW_OP_le: begin
          if not AssertMinCount(2) then exit;
          Entry  := FStack.Pop;
          Entry2 := FStack.Peek(0);
          if int64(Entry.Value.Address) <= int64(Entry2.Value.Address)
          then FStack.Modify(0, 1, lseValue)
          else FStack.Modify(0, 0, lseValue);
        end;
      DW_OP_lt: begin
          if not AssertMinCount(2) then exit;
          Entry  := FStack.Pop;
          Entry2 := FStack.Peek(0);
          if int64(Entry.Value.Address) < int64(Entry2.Value.Address)
          then FStack.Modify(0, 1, lseValue)
          else FStack.Modify(0, 0, lseValue);
        end;
      DW_OP_ne: begin
          if not AssertMinCount(2) then exit;
          Entry  := FStack.Pop;
          Entry2 := FStack.Peek(0);
          if Entry.Value.Address <> Entry2.Value.Address
          then FStack.Modify(0, 1, lseValue)
          else FStack.Modify(0, 0, lseValue);
        end;

      DW_OP_piece: begin
          if not AssertMinCount(1) then exit; // no piece avail
          FStack.Push(0, lsePart);
          exit;
        end;

      // dwarf 3
      DW_OP_push_object_address: begin
        if not IsValidLoc(FCurrentObjectAddress) then begin
          SetError;
          exit;
        end;
        Push(FCurrentObjectAddress, lseValue);
      end;
(*
  // --- DWARF3 ---
  DW_OP_call2                 = $98;    // 1 2-byte offset of DIE
  DW_OP_call4                 = $99;    // 1 4-byte offset of DIE
  DW_OP_call_ref              = $9a;    // 1 4- or 8-byte offset of DIE
  DW_OP_form_tls_address      = $9b;    // 0
  DW_OP_call_frame_cfa        = $9c;    // 0
  DW_OP_bit_piece             = $9d;    // 2
*)
      else
        begin
          debugln(FPDBG_DWARF_ERRORS, ['DWARF ERROR in TDwarfLocationExpression.Evaluate UNKNOWN ', CurInstr^]);
          SetError;
          exit;
        end;
    end;
  end;
end;

function TDwarfLocationExpression.ResultKind: TDwarfLocationStackEntryKind;
begin
  if FStack.Count > 0 then
    Result := FStack.PeekKind
  else
    Result := lseError;
end;

function TDwarfLocationExpression.ResultData: TDbgPtr;
begin
  if FStack.Count > 0 then
    Result := FStack.Peek.Value.Address
  else
    Result := 0;
end;

procedure TDwarfLocationExpression.Push(AValue: TFpDbgMemLocation;
  AKind: TDwarfLocationStackEntryKind);
begin
  FStack.Push(AValue, AKind);
end;

{ TDwarfInformationEntry }

procedure TDwarfInformationEntry.ScopeChanged;
begin
  FInformationEntry := FScope.Entry;
  FFlags := [];
  FInformationData := nil;
  if FAbstractOrigin <> nil then
    ReleaseRefAndNil(FAbstractOrigin);
end;

procedure TDwarfInformationEntry.PrepareAbbrev;
begin
  if dieAbbrevValid in FFlags then
    exit;
  FInformationData := FCompUnit.FAbbrevList.FindLe128bFromPointer(FInformationEntry, FAbbrev);
  Include(FFlags, dieAbbrevValid);
end;

function TDwarfInformationEntry.PrepareAbbrevData: Boolean;
var
  AbbrList: TDwarfAbbrevList;
begin
  Result := FAbbrevData <> nil;
  if dieAbbrevDataValid in FFlags then
    exit;
  AbbrList := FCompUnit.FAbbrevList;

  // PrepareAbbrev;
  if not(dieAbbrevValid in FFlags) then
    FInformationData := AbbrList.FindLe128bFromPointer(FInformationEntry, FAbbrev);
  Result := FInformationData <> nil;

  if Result
  then FAbbrevData := AbbrList.EntryPointer[FAbbrev^.index]
  else FAbbrevData := nil;
  FFlags := FFlags + [dieAbbrevValid, dieAbbrevDataValid];
end;

function TDwarfInformationEntry.PrepareAbstractOrigin: Boolean;
var
  FwdInfoPtr: Pointer;
  FwdCompUint: TDwarfCompilationUnit;
begin
  if (dieAbstractOriginValid in FFlags) then begin
    Result := FAbstractOrigin <> nil;
    exit;
  end;
  Assert(dieAbbrevValid in FFlags);
  Assert(dafHasAbstractOrigin in FAbbrev^.flags);
  Include(FFlags, dieAbstractOriginValid);
  if ReadReference(DW_AT_abstract_origin, FwdInfoPtr, FwdCompUint) then begin
    FAbstractOrigin := TDwarfInformationEntry.Create(FwdCompUint, FwdInfoPtr);
    // TODO, check correct tag
    Result := FAbstractOrigin <> nil;
  end
  else
    Result := False;
end;

function TDwarfInformationEntry.GetAbbrevTag: Cardinal;
begin
  PrepareAbbrev;
  if FAbbrev <> nil
  then Result := FAbbrev^.tag
  else Result := 0;
end;

procedure TDwarfInformationEntry.GoParent;
begin
  if not MaybeSearchScope then
    exit;
  FScope.GoParent;
  ScopeChanged;
end;

procedure TDwarfInformationEntry.GoNext;
begin
  if not MaybeSearchScope then
    exit;
  FScope.GoNext;
  ScopeChanged;
end;

procedure TDwarfInformationEntry.GoChild;
begin
  if not MaybeSearchScope then
    exit;
  FScope.GoChild;
  ScopeChanged;
end;

function TDwarfInformationEntry.HasValidScope: Boolean;
begin
  Result := FScope.IsValid;
end;

function TDwarfInformationEntry.ScopeDebugText: String;
begin
  Result := dbgs(FScope, FCompUnit);
end;

function TDwarfInformationEntry.SearchScope: Boolean;
var
  l, h, m: Integer;
  lst: TDwarfScopeArray;
begin
  Result := FInformationEntry <> nil;
  if not Result then exit;
  l := 0;
  h := FCompUnit.FScopeList.HighestKnown;
  lst := FCompUnit.FScopeList.List;
  while h > l do begin
    m := (h + l) div 2;
    if lst[m].Entry >= FInformationEntry
    then h := m
    else l := m + 1;
  end;

  Result := lst[h].Entry = FInformationEntry;
  if Result then
    ScopeIndex := h;
//debugln(['TDwarfInformationEntry.SearchScope ', h]);
end;

function TDwarfInformationEntry.MaybeSearchScope: Boolean;
begin
  Result := FScope.IsValid;
  if Result then exit;
  Result := SearchScope;
end;

function TDwarfInformationEntry.AttribIdx(AnAttrib: Cardinal; out
  AInfoPointer: pointer): Integer;
var
  i: Integer;
  AddrSize: Byte;
begin
  if not PrepareAbbrevData then exit(-1);
  AInfoPointer := FInformationData;
  AddrSize := FCompUnit.FAddressSize;
  for i := 0 to FAbbrev^.count - 1 do begin
    if FAbbrevData[i].Attribute = AnAttrib then
      exit(i);
    SkipEntryDataForForm(AInfoPointer, FAbbrevData[i].Form, AddrSize, FCompUnit.IsDwarf64, FCompUnit.Version);
  end;
  Result := -1;
end;

function TDwarfInformationEntry.HasAttrib(AnAttrib: Cardinal): Boolean;
var
  i: Integer;
begin
  Result := False;
  if not PrepareAbbrevData then exit;
  for i := 0 to FAbbrev^.count - 1 do
    if FAbbrevData[i].Attribute = AnAttrib then begin
      Result := True;
      exit;
  end;
end;

function TDwarfInformationEntry.GetScopeIndex: Integer;
begin
  Result := FScope.Index;
end;

procedure TDwarfInformationEntry.SetScopeIndex(AValue: Integer);
begin
  if FScope.Index = AValue then
    exit;
  FScope.Index := AValue;
  ScopeChanged;
end;

function TDwarfInformationEntry.GoNamedChild(AName: String): Boolean;
var
  EntryName: PChar;
  s1, s2: String;
begin
  Result := False;
  if AName = '' then
    exit;
  GoChild;
  if not HasValidScope then
    exit;
  s1 := UTF8UpperCase(AName);
  s2 := UTF8LowerCase(AName);
  while HasValidScope do begin
    PrepareAbbrev;
    if not (dafHasName in FAbbrev^.flags) then begin
      GoNext;
      Continue;
    end;
    if not ReadValue(DW_AT_name, EntryName) then begin
      GoNext;
      Continue;
    end;

      if CompareUtf8BothCase(@s1[1], @s2[1], EntryName) then begin
      // TODO: check DW_AT_start_scope;
      DebugLn(FPDBG_DWARF_SEARCH, ['GoNamedChild found ', dbgs(FScope, FCompUnit), '  Result=', DbgSName(Self), '  FOR ', AName]);
      Result := True;
      exit;
    end;

    GoNext;
  end;
end;

function TDwarfInformationEntry.GoNamedChildEx(ANameUpper, AnameLower: PChar): Boolean;
var
  EntryName: PChar;
  InEnum: Boolean;
  ParentScopIdx: Integer;
begin
  Result := False;
  InEnum := False;
  if ANameUpper = nil then
    exit;
  GoChild;
  if not HasValidScope then
    exit;
  while true do begin
    while HasValidScope do begin
      PrepareAbbrev;
      if not (dafHasName in FAbbrev^.flags) then begin
        GoNext;
        Continue;
      end;
      if not ReadValue(DW_AT_name, EntryName) then begin
        GoNext;
        Continue;
      end;

      if CompareUtf8BothCase(ANameUpper, AnameLower, EntryName) then begin
        // TODO: check DW_AT_start_scope;
        DebugLn(FPDBG_DWARF_SEARCH, ['GoNamedChildEX found ', dbgs(FScope, FCompUnit), '  Result=', DbgSName(Self), '  FOR ', AnameLower]);
        Result := True;
        exit;
      end;

      if FAbbrev^.tag = DW_TAG_enumeration_type then begin
        assert(not InEnum, 'nested enum');
        InEnum := True;
        ParentScopIdx := ScopeIndex;
        GoChild;
        Continue;
      end;

      GoNext;
    end;

    if InEnum then begin
      InEnum := False;
      ScopeIndex := ParentScopIdx;
      GoNext;
      continue;
    end;
    break;
  end;
end;

function TDwarfInformationEntry.GoNamedChildEx(AName: String): Boolean;
var
  s1, s2: String;
begin
  Result := False;
  if AName = '' then
    exit;
  s1 := UTF8UpperCase(AName);
  s2 := UTF8LowerCase(AName);
  Result := GoNamedChildEx(@s1[1], @s2[1]);
end;

constructor TDwarfInformationEntry.Create(ACompUnit: TDwarfCompilationUnit;
  AnInformationEntry: Pointer);
begin
  inherited Create;
  AddReference;
  FCompUnit := ACompUnit;
  FInformationEntry := AnInformationEntry;
  FScope.Init(@FCompUnit.FScopeList);
end;

constructor TDwarfInformationEntry.Create(ACompUnit: TDwarfCompilationUnit;
  AScope: TDwarfScopeInfo);
begin
  inherited Create;
  AddReference;
  FCompUnit := ACompUnit;
  FScope := AScope;
  ScopeChanged;
end;

destructor TDwarfInformationEntry.Destroy;
begin
  FAbstractOrigin.ReleaseReference;
  inherited Destroy;
end;

function TDwarfInformationEntry.FindNamedChild(AName: String): TDwarfInformationEntry;
begin
  Result := nil;
  if not MaybeSearchScope then
    exit;

  Result := TDwarfInformationEntry.Create(FCompUnit, FScope);
// TODO: parent
  if Result.GoNamedChild(AName) then
    exit;
  ReleaseRefAndNil(Result);
end;

function TDwarfInformationEntry.FindChildByTag(ATag: Cardinal): TDwarfInformationEntry;
var
  Scope: TDwarfScopeInfo;
  AbbrList: TDwarfAbbrevList;
  Abbr: TDwarfAbbrev;
begin
  Result := nil;
  if not MaybeSearchScope then
    exit;

  Scope := FScope.Child;
  while Scope.IsValid do begin
    AbbrList := FCompUnit.FAbbrevList;
    if AbbrList.FindLe128bFromPointer(Scope.Entry, Abbr) <> nil then begin
      if Abbr.tag = ATag then begin
        Result := TDwarfInformationEntry.Create(FCompUnit, Scope);
        exit;
      end;
    end;
    Scope.GoNext;
  end;
end;

function TDwarfInformationEntry.FirstChild: TDwarfInformationEntry;
var
  Scope: TDwarfScopeInfo;
begin
  Result := nil;
  if not MaybeSearchScope then
    exit;

  Scope := FScope.Child;
  if Scope.IsValid then
    Result := TDwarfInformationEntry.Create(FCompUnit, Scope);
end;

function TDwarfInformationEntry.Clone: TDwarfInformationEntry;
begin
  if FScope.IsValid then
    Result := TDwarfInformationEntry.Create(FCompUnit, FScope)
  else
    Result := TDwarfInformationEntry.Create(FCompUnit, FInformationEntry);
end;

function TDwarfInformationEntry.ReadValue(AnAttrib: Cardinal; out AValue: Integer): Boolean;
var
  AData: pointer;
  i: Integer;
begin
  i := AttribIdx(AnAttrib, AData);
  if i < 0 then begin
    if (dafHasAbstractOrigin in FAbbrev^.flags) and PrepareAbstractOrigin
    then Result := FAbstractOrigin.ReadValue(AnAttrib, AValue)
    else Result := False;
  end
  else
    Result := FCompUnit.ReadValue(AData, FAbbrevData[i].Form, AValue);
end;

function TDwarfInformationEntry.ReadValue(AnAttrib: Cardinal; out AValue: Int64): Boolean;
var
  AData: pointer;
  i: Integer;
begin
  i := AttribIdx(AnAttrib, AData);
  if i < 0 then begin
    if (dafHasAbstractOrigin in FAbbrev^.flags) and PrepareAbstractOrigin
    then Result := FAbstractOrigin.ReadValue(AnAttrib, AValue)
    else Result := False;
  end
  else
    Result := FCompUnit.ReadValue(AData, FAbbrevData[i].Form, AValue);
end;

function TDwarfInformationEntry.ReadValue(AnAttrib: Cardinal; out AValue: Cardinal): Boolean;
var
  AData: pointer;
  i: Integer;
begin
  i := AttribIdx(AnAttrib, AData);
  if i < 0 then begin
    if (dafHasAbstractOrigin in FAbbrev^.flags) and PrepareAbstractOrigin
    then Result := FAbstractOrigin.ReadValue(AnAttrib, AValue)
    else Result := False;
  end
  else
    Result := FCompUnit.ReadValue(AData, FAbbrevData[i].Form, AValue);
end;

function TDwarfInformationEntry.ReadValue(AnAttrib: Cardinal; out AValue: QWord): Boolean;
var
  AData: pointer;
  i: Integer;
begin
  i := AttribIdx(AnAttrib, AData);
  if i < 0 then begin
    if (dafHasAbstractOrigin in FAbbrev^.flags) and PrepareAbstractOrigin
    then Result := FAbstractOrigin.ReadValue(AnAttrib, AValue)
    else Result := False;
  end
  else
    Result := FCompUnit.ReadValue(AData, FAbbrevData[i].Form, AValue);
end;

function TDwarfInformationEntry.ReadValue(AnAttrib: Cardinal; out AValue: PChar): Boolean;
var
  AData: pointer;
  i: Integer;
begin
  i := AttribIdx(AnAttrib, AData);
  if i < 0 then begin
    if (dafHasAbstractOrigin in FAbbrev^.flags) and PrepareAbstractOrigin
    then Result := FAbstractOrigin.ReadValue(AnAttrib, AValue)
    else Result := False;
  end
  else
    Result := FCompUnit.ReadValue(AData, FAbbrevData[i].Form, AValue);
end;

function TDwarfInformationEntry.ReadValue(AnAttrib: Cardinal; out AValue: String): Boolean;
var
  AData: pointer;
  i: Integer;
begin
  i := AttribIdx(AnAttrib, AData);
  if i < 0 then begin
    if (dafHasAbstractOrigin in FAbbrev^.flags) and PrepareAbstractOrigin
    then Result := FAbstractOrigin.ReadValue(AnAttrib, AValue)
    else Result := False;
  end
  else
    Result := FCompUnit.ReadValue(AData, FAbbrevData[i].Form, AValue);
end;

function TDwarfInformationEntry.ReadValue(AnAttrib: Cardinal; out
  AValue: TByteDynArray): Boolean;
var
  AData: pointer;
  i: Integer;
begin
  i := AttribIdx(AnAttrib, AData);
  if i < 0 then begin
    if (dafHasAbstractOrigin in FAbbrev^.flags) and PrepareAbstractOrigin
    then Result := FAbstractOrigin.ReadValue(AnAttrib, AValue)
    else Result := False;
  end
  else
    Result := FCompUnit.ReadValue(AData, FAbbrevData[i].Form, AValue);
end;

function TDwarfInformationEntry.ReadReference(AnAttrib: Cardinal; out AValue: Pointer; out
  ACompUnit: TDwarfCompilationUnit): Boolean;
var
  InfoData: pointer;
  i: Integer;
  Form: Cardinal;
  Offs: QWord;
begin
  // reference to other debug info
  {Note: Dwarf2 defines DW_FORM_ref_addr as relocated address in the exe,
         Dwarf 3 defines it as offset.
         Since we load the debug_info section without applying any relocation (if indeed present at all),
         this field will always be an offset from start of the debug_info section
  }
  Result := False;
  i := AttribIdx(AnAttrib, InfoData);
  if i < 0 then begin
    if (dafHasAbstractOrigin in FAbbrev^.flags) and PrepareAbstractOrigin
    then Result := FAbstractOrigin.ReadReference(AnAttrib, AValue, ACompUnit);
    exit;
  end;
  Form := FAbbrevData[i].Form;
  if (Form = DW_FORM_ref1) or (Form = DW_FORM_ref2) or (Form = DW_FORM_ref4) or
     (Form = DW_FORM_ref8) or (Form = DW_FORM_ref_udata)
  then begin
    Result := FCompUnit.ReadValue(InfoData, Form, Offs);
    if not Result then
      exit;
    ACompUnit := FCompUnit;
    if ACompUnit.FIsDwarf64
    then AValue := ACompUnit.FScope.Entry + Offs - SizeOf(TDwarfCUHeader64)
    else AValue := ACompUnit.FScope.Entry + Offs - SizeOf(TDwarfCUHeader32);
  end
  else
  if (Form = DW_FORM_ref_addr) then begin
    if FCompUnit.Version=2 then
      Result := FCompUnit.ReadAddressValue(InfoData, Form, Offs)
    else
      Result := FCompUnit.ReadValue(InfoData, Form, Offs);
    if not Result then
      exit;
    AValue := FCompUnit.DebugFile^.Sections[dsInfo].RawData + Offs;
    if (AValue >= FCompUnit.FInfoData) and (AValue < FCompUnit.FInfoData + FCompUnit.FLength) then
      ACompUnit := FCompUnit
    else
      ACompUnit := FCompUnit.FOwner.FindCompilationUnitByOffs(Offs);
    Result := ACompUnit <> nil;
    if not Result then DebugLn(FPDBG_DWARF_WARNINGS, ['Comp unit not found DW_FORM_ref_addr']);
  end
  else begin
    DebugLn(FPDBG_DWARF_VERBOSE, ['FORM for DW_AT_type not expected ', DwarfAttributeFormToString(Form)]);
  end;
end;

function TDwarfInformationEntry.ReadName(out AName: String): Boolean;
var
  i: Integer;
  AData: pointer;
begin
  PrepareAbbrev;
  if dafHasName in FAbbrev^.flags then begin
    //Result := ReadValue(DW_AT_name, AName);
    i := AttribIdx(DW_AT_name, AData);
    assert(i >= 0, 'TDwarfInformationEntry.ReadName');
    Result := FCompUnit.ReadValue(AData, FAbbrevData[i].Form, AName);
  end
  else
  if (dafHasAbstractOrigin in FAbbrev^.flags) and PrepareAbstractOrigin then
    Result := FAbstractOrigin.ReadName(AName)
  else
    Result := False;
end;

function TDwarfInformationEntry.ReadName(out AName: PChar): Boolean;
var
  AData: pointer;
  i: Integer;
begin
  PrepareAbbrev;
  if dafHasName in FAbbrev^.flags then begin
    //Result := ReadValue(DW_AT_name, AName);
    i := AttribIdx(DW_AT_name, AData);
    assert(i >= 0, 'TDwarfInformationEntry.ReadName');
    Result := FCompUnit.ReadValue(AData, FAbbrevData[i].Form, AName);
  end
  else
  if (dafHasAbstractOrigin in FAbbrev^.flags) and PrepareAbstractOrigin then
    Result := FAbstractOrigin.ReadName(AName)
  else
    Result := False;
end;

function TDwarfInformationEntry.ReadStartScope(out AStartScope: TDbgPtr): Boolean;
var
  AData: pointer;
  i: Integer;
begin
  PrepareAbbrev;
  if dafHasStartScope in FAbbrev^.flags then begin
    //Result := ReadValue(DW_AT_start_scope, AStartScope)
    i := AttribIdx(DW_AT_start_scope, AData);
    assert(i >= 0, 'TDwarfInformationEntry.ReadStartScope');
    Result := FCompUnit.ReadValue(AData, FAbbrevData[i].Form, AStartScope);
  end
  else
  if (dafHasAbstractOrigin in FAbbrev^.flags) and PrepareAbstractOrigin then
    Result := FAbstractOrigin.ReadStartScope(AStartScope)
  else
    Result := False;
end;

function TDwarfInformationEntry.IsAddressInStartScope(AnAddress: TDbgPtr): Boolean;
var
  StartScope: TDbgPtr;
begin
  Result := not ReadStartScope(StartScope);
  if Result then exit; // no startscope, always in scope
  Result := AnAddress >= StartScope;
end;

function TDwarfInformationEntry.IsArtificial: Boolean;
var
  Val: Integer;
begin
  Result := ReadValue(DW_AT_artificial, Val);
  if Result then Result := Val <> 0;
end;

{ TDWarfLineMap }

procedure TDWarfLineMap.Init;
begin
  NextAFterHighestLine := 0;
  //Count := 0;
end;

procedure TDWarfLineMap.SetAddressForLine(ALine: Cardinal; AnAddress: QWord);
var
  i: Integer;
begin
  i := Length(AddressList);
  if i <= ALine then
    SetLength(AddressList, ALine + 2000);

  if AddressList[ALine] = 0 then begin
    AddressList[ALine] := AnAddress;
    //inc(Count);
  end;
  if ALine > NextAFterHighestLine then
    NextAFterHighestLine := ALine+1;
end;

function TDWarfLineMap.GetAddressForLine(ALine: Cardinal): QWord;
begin
  Result := 0;
  if ALine < Length(AddressList) then
    Result := AddressList[ALine];
end;

procedure TDWarfLineMap.Compress;
begin
  SetLength(AddressList, NextAFterHighestLine);
//DebugLn(['#### ',NextAFterHighestLine, ' / ',Count]);
end;

{ TFpDwarfInfo }

constructor TFpDwarfInfo.Create(ALoaderList: TDbgImageLoaderList);
var
  Section: TDwarfSection;
  p: PDbgImageSection;
  i: Integer;
begin
  inherited Create(ALoaderList);
  FCompilationUnits := TList.Create;
  FImageBase := ALoaderList.ImageBase;

  SetLength(FFiles, ALoaderList.Count);
  for i := 0 to ALoaderList.Count-1 do
  begin
    FFiles[i].AddressMapList:=ALoaderList[i].AddressMapList;
    for Section := Low(Section) to High(Section) do
    begin
      p := ALoaderList[i].Section[DWARF_SECTION_NAME[Section]];
      if p = nil then Continue;
      FFiles[i].Sections[Section].Section := Section;
      FFiles[i].Sections[Section].RawData := p^.RawData;
      FFiles[i].Sections[Section].Size := p^.Size;
      FFiles[i].Sections[Section].VirtualAddress := p^.VirtualAddress;
    end;
  end;
end;

destructor TFpDwarfInfo.Destroy;
var
  n: integer;
begin
  for n := 0 to FCompilationUnits.Count - 1 do
    TObject(FCompilationUnits[n]).Free;
  FreeAndNil(FCompilationUnits);
  inherited Destroy;
end;

function TFpDwarfInfo.FindContext(AThreadId, AStackFrame: Integer;
  AAddress: TDbgPtr): TFpDbgInfoContext;
var
  Proc: TDbgDwarfSymbolBase;
begin
  Result := nil;
  Proc := FindProcSymbol(AAddress);
  if Proc = nil then
    exit;

  Result := Proc.CompilationUnit.DwarfSymbolClassMap.CreateContext
    (AThreadId, AStackFrame, AAddress, Proc, Self);
  Proc.ReleaseReference;
end;

function TFpDwarfInfo.FindContext(AAddress: TDbgPtr): TFpDbgInfoContext;
begin
  result := FindContext(1, 0, AAddress);
end;

function TFpDwarfInfo.FindSymbol(AAddress: TDbgPtr): TFpDbgSymbol;
begin
  Result := FindProcSymbol(AAddress);
end;

function TFpDwarfInfo.GetCompilationUnit(AIndex: Integer): TDwarfCompilationUnit;
begin
  Result := TDwarfCompilationUnit(FCompilationUnits[Aindex]);
end;

function TFpDwarfInfo.GetCompilationUnitClass: TDwarfCompilationUnitClass;
begin
  Result := TDwarfCompilationUnit;
end;

function TFpDwarfInfo.FindCompilationUnitByOffs(AOffs: QWord): TDwarfCompilationUnit;
var
  l, h, m: Integer;
  p: Pointer;
begin
  Result := nil;
  l := 0;
  h := FCompilationUnits.Count - 1;
  while h > l do begin
    p := TDwarfCompilationUnit(FCompilationUnits[m]).DebugFile^.Sections[dsInfo].RawData + AOffs;
    m := (h + l + 1) div 2;
    if TDwarfCompilationUnit(FCompilationUnits[m]).FInfoData <= p
    then l := m
    else h := m - 1;
  end;

  Result := TDwarfCompilationUnit(FCompilationUnits[h]);
  if (p < Result.FInfoData) or (p > Result.FInfoData + Result.FLength) then
    Result := nil;
end;

function TFpDwarfInfo.FindProcSymbol(AAddress: TDbgPtr): TDbgDwarfSymbolBase;
var
  n: Integer;
  CU: TDwarfCompilationUnit;
  Iter: TMapIterator;
  Info: PDwarfAddressInfo;
  MinMaxSet: boolean;
begin
  Result := nil;
  for n := 0 to FCompilationUnits.Count - 1 do
  begin
    CU := TDwarfCompilationUnit(FCompilationUnits[n]);
    if not CU.Valid then Continue;
    MinMaxSet := CU.FMinPC <> CU.FMaxPC;
    if MinMaxSet and ((AAddress < CU.FMinPC) or (AAddress > CU.FMaxPC))
    then Continue;

    CU.BuildAddressMap;

    Iter := TMapIterator.Create(CU.FAddressMap);
    try
      if Iter.EOM
      then begin
        if MinMaxSet
        then Exit //  minmaxset and no procs defined ???
        else Continue;
      end;

      if not Iter.Locate(AAddress)
      then begin
        if not Iter.BOM
        then Iter.Previous;

        if Iter.BOM
        then begin
          if MinMaxSet
          then Exit //  minmaxset and no proc @ minpc ???
          else Continue;
        end;
      end;

      // iter is at the closest defined address before AAddress
      Info := Iter.DataPtr;
      if AAddress > Info^.EndPC
      then begin
        if MinMaxSet
        then Exit //  minmaxset and no proc @ maxpc ???
        else Continue;
      end;

      // TDbgDwarfProcSymbol
      Result := Cu.DwarfSymbolClassMap.CreateProcSymbol(CU, Iter.DataPtr, AAddress);
    finally
      Iter.Free;
    end;
  end;
end;

function TFpDwarfInfo.GetLineAddress(const AFileName: String; ALine: Cardinal): TDbgPtr;
var
  n: Integer;
  CU: TDwarfCompilationUnit;
begin
  for n := 0 to FCompilationUnits.Count - 1 do
  begin
    CU := TDwarfCompilationUnit(FCompilationUnits[n]);
    Result := CU.GetLineAddress(AFileName, ALine);
    if Result <> 0 then Exit;
  end;
  Result := 0;
end;

function TFpDwarfInfo.GetLineAddressMap(const AFileName: String): PDWarfLineMap;
var
  n: Integer;
  CU: TDwarfCompilationUnit;
begin
  // TODO: Deal with line info split on 2 compilation units?
  for n := 0 to FCompilationUnits.Count - 1 do
  begin
    CU := TDwarfCompilationUnit(FCompilationUnits[n]);
    Result := CU.GetLineAddressMap(AFileName);
    if Result <> nil then Exit;
  end;
  Result := nil;
end;

function TFpDwarfInfo.LoadCompilationUnits: Integer;
var
  p, pe: Pointer;
  CU32: PDwarfCUHeader32 absolute p;
  CU64: PDwarfCUHeader64 absolute p;
  CU: TDwarfCompilationUnit;
  CUClass: TDwarfCompilationUnitClass;
  inf: TDwarfSectionInfo;
  i: integer;
begin
  CUClass := GetCompilationUnitClass;
  for i := 0 to high(FFiles) do
  begin
    inf := FFiles[i].Sections[dsInfo];
    p := inf.RawData;
    pe := inf.RawData + inf.Size;
    while (p <> nil) and (p < pe) do
    begin
      if CU64^.Signature = DWARF_HEADER64_SIGNATURE
      then begin
        if CU64^.Version < 3 then
          DebugLn(FPDBG_DWARF_WARNINGS, ['Unexpected 64 bit signature found for DWARF version 2']); // or version 1...
        CU := CUClass.Create(
                Self,
                @FFiles[i],
                PtrUInt(CU64 + 1) - PtrUInt(inf.RawData),
                CU64^.Length - SizeOf(CU64^) + SizeOf(CU64^.Signature) + SizeOf(CU64^.Length),
                CU64^.Version,
                CU64^.AbbrevOffset,
                CU64^.AddressSize,
                True);
        p := Pointer(@CU64^.Version) + CU64^.Length;
      end
      else begin
        if CU32^.Length = 0 then Break;
        CU := CUClass.Create(
                Self,
                @FFiles[i],
                PtrUInt(CU32 + 1) - PtrUInt(inf.RawData),
                CU32^.Length - SizeOf(CU32^) + SizeOf(CU32^.Length),
                CU32^.Version,
                CU32^.AbbrevOffset,
                CU32^.AddressSize,
                False);
        p := Pointer(@CU32^.Version) + CU32^.Length;
      end;
      FCompilationUnits.Add(CU);
      if CU.Valid then SetHasInfo;
    end;
  end;
  Result := FCompilationUnits.Count;
end;

function TFpDwarfInfo.PointerFromRVA(ARVA: QWord): Pointer;
begin
  Result := Pointer(PtrUInt(FImageBase + ARVA));
end;

function TFpDwarfInfo.CompilationUnitsCount: Integer;
begin
  Result := FCompilationUnits.Count;
end;

{ TDbgDwarfSymbolBase }

procedure TDbgDwarfSymbolBase.Init;
begin
  //
end;

constructor TDbgDwarfSymbolBase.Create(AName: String;
  AnInformationEntry: TDwarfInformationEntry);
begin
  FCU := AnInformationEntry.CompUnit;
  FInformationEntry := AnInformationEntry;
  FInformationEntry.AddReference;

  inherited Create(AName);
  Init;
end;

constructor TDbgDwarfSymbolBase.Create(AName: String;
  AnInformationEntry: TDwarfInformationEntry; AKind: TDbgSymbolKind;
  AAddress: TFpDbgMemLocation);
begin
  FCU := AnInformationEntry.CompUnit;
  FInformationEntry := AnInformationEntry;
  FInformationEntry.AddReference;

  inherited Create(AName, AKind, AAddress);
  Init;
end;

destructor TDbgDwarfSymbolBase.Destroy;
begin
  ReleaseRefAndNil(FInformationEntry);
  inherited Destroy;
end;

{ TDwarfLineInfoStateMachine }

function TDwarfLineInfoStateMachine.Clone: TDwarfLineInfoStateMachine;
begin
  Result := TDwarfLineInfoStateMachine.Create(FOwner, FLineInfoPtr, FMaxPtr);
  Result.FAddress := FAddress;
  Result.FFileName := FFileName;
  Result.FLine := FLine;
  Result.FColumn := FColumn;
  Result.FIsStmt := FIsStmt;
  Result.FBasicBlock := FBasicBlock;
  Result.FEndSequence := FEndSequence;
  Result.FPrologueEnd := FPrologueEnd;
  Result.FEpilogueBegin := FEpilogueBegin;
  Result.FIsa := FIsa;
  Result.FEnded := FEnded;
end;

constructor TDwarfLineInfoStateMachine.Create(AOwner: TDwarfCompilationUnit; ALineInfoPtr, AMaxPtr: Pointer);
begin
  inherited Create;
  FOwner := AOwner;
  FLineInfoPtr := ALineInfoPtr;
  FMaxPtr := AMaxPtr;
  Reset;
end;

function TDwarfLineInfoStateMachine.NextLine: Boolean;
var
  p: Pointer;
  Opcode: Byte;
  instrlen: Cardinal;
  diridx: Cardinal;
begin
  Result := False;
  if FEndSequence
  then begin
    Reset;
  end
  else begin
    FBasicBlock := False;
    FPrologueEnd := False;
    FEpilogueBegin := False;
  end;
  
  while pbyte(FLineInfoPtr) < FMaxPtr do
  begin
    Opcode := pbyte(FLineInfoPtr)^;
    Inc(pbyte(FLineInfoPtr));
    if Opcode <= Length(FOwner.FLineInfo.StandardOpcodeLengths)
    then begin
      // Standard opcode
      case Opcode of
        DW_LNS_copy: begin
          Result := True;
          Exit;
        end;
        DW_LNS_advance_pc: begin
          Inc(FAddress, ULEB128toOrdinal(pbyte(FLineInfoPtr)));
        end;
        DW_LNS_advance_line: begin
          Inc(FLine, SLEB128toOrdinal(pbyte(FLineInfoPtr)));
        end;
        DW_LNS_set_file: begin
          SetFileName(ULEB128toOrdinal(pbyte(FLineInfoPtr)));
        end;
        DW_LNS_set_column: begin
          FColumn := ULEB128toOrdinal(pbyte(FLineInfoPtr));
        end;
        DW_LNS_negate_stmt: begin
          FIsStmt := not FIsStmt;
        end;
        DW_LNS_set_basic_block: begin
          FBasicBlock := True;
        end;
        DW_LNS_const_add_pc: begin
          Opcode := 255 - Length(FOwner.FLineInfo.StandardOpcodeLengths);
          if FOwner.FLineInfo.LineRange = 0
          then Inc(FAddress, Opcode * FOwner.FLineInfo.MinimumInstructionLength)
          else Inc(FAddress, (Opcode div FOwner.FLineInfo.LineRange) * FOwner.FLineInfo.MinimumInstructionLength);
        end;
        DW_LNS_fixed_advance_pc: begin
          Inc(FAddress, PWord(FLineInfoPtr)^);
          Inc(pbyte(FLineInfoPtr), 2);
        end;
        DW_LNS_set_prologue_end: begin
          FPrologueEnd := True;
        end;
        DW_LNS_set_epilogue_begin: begin
          FEpilogueBegin := True;
        end;
        DW_LNS_set_isa: begin
          FIsa := ULEB128toOrdinal(pbyte(FLineInfoPtr));
        end;
        // Extended opcode
        DW_LNS_extended_opcode: begin
          instrlen := ULEB128toOrdinal(pbyte(FLineInfoPtr)); // instruction length

          case pbyte(FLineInfoPtr)^ of
            DW_LNE_end_sequence: begin
              FEndSequence := True;
              Result := True;
              Exit;
            end;
            DW_LNE_set_address: begin
              if FOwner.FLineInfo.Addr64
              then FAddress := PQWord(pbyte(FLineInfoPtr)+1)^
              else FAddress := PLongWord(pbyte(FLineInfoPtr)+1)^;
              FAddress:=FOwner.MapAddressToNewValue(FAddress);
            end;
            DW_LNE_define_file: begin
              // don't move pb, it's done at the end by instruction length
              p := pbyte(FLineInfoPtr);
              FFileName := String(PChar(p));
              Inc(p, Length(FFileName) + 1);

              //diridx
              diridx := ULEB128toOrdinal(p);
              if diridx < FOwner.FLineInfo.Directories.Count
              then FFileName := FOwner.FLineInfo.Directories[diridx] + FFileName
              else FFileName := Format('Unknown dir(%u)', [diridx]) + DirectorySeparator + FFileName;
              //last modified
              //ULEB128toOrdinal(p);
              //length
              //ULEB128toOrdinal(p));
            end;
          else
            // unknown extendend opcode
          end;
          Inc(pbyte(FLineInfoPtr), instrlen);
        end;
      else
        // unknown opcode
        Inc(pbyte(FLineInfoPtr), FOwner.FLineInfo.StandardOpcodeLengths[Opcode])
      end;
      Continue;
    end;

    // Special opcode
    Dec(Opcode, Length(FOwner.FLineInfo.StandardOpcodeLengths)+1);
    if FOwner.FLineInfo.LineRange = 0
    then begin
      Inc(FAddress, Opcode * FOwner.FLineInfo.MinimumInstructionLength);
    end
    else begin
      Inc(FAddress, (Opcode div FOwner.FLineInfo.LineRange) * FOwner.FLineInfo.MinimumInstructionLength);
      Inc(FLine, FOwner.FLineInfo.LineBase + (Opcode mod FOwner.FLineInfo.LineRange));
    end;
    Result := True;
    Exit;
  end;
  Result := False;
  FEnded := True;
end;

procedure TDwarfLineInfoStateMachine.Reset;
begin
  FAddress := 0;
  SetFileName(1);
  FLine := 1;
  FColumn := 0;
  FIsStmt := FOwner.FLineInfo.DefaultIsStmt;
  FBasicBlock := False;
  FEndSequence := False;
  FPrologueEnd := False;
  FEpilogueBegin := False;
  FIsa := 0;
end;

procedure TDwarfLineInfoStateMachine.SetFileName(AIndex: Cardinal);
begin
  if (Aindex > 0) and (AIndex <= FOwner.FLineInfo.FileNames.Count)
  then FFileName := FOwner.FullFileName(FOwner.FLineInfo.FileNames[AIndex - 1])
  else FFileName := Format('Unknown fileindex(%u)', [AIndex]);
end;

{ TFpDwarfSymbolClassMapList }

function TFpDwarfSymbolClassMapList.FindMapForCompUnit(ACU: TDwarfCompilationUnit): TFpDwarfSymbolClassMapClass;
var
  i: Integer;
begin
  for i := 0 to length(FMapList) - 1 do
    if FMapList[i].HandleCompUnit(ACU) then begin
      Result := FMapList[i];
      exit;
    end;
  Result := FDefaultMap;
end;

procedure TFpDwarfSymbolClassMapList.AddMap(AMap: TFpDwarfSymbolClassMapClass);
var
  l: Integer;
begin
  l := length(FMapList);
  SetLength(FMapList, l + 1);
  FMapList[l] := AMap;
end;

procedure TFpDwarfSymbolClassMapList.SetDefaultMap(AMap: TFpDwarfSymbolClassMapClass);
begin
  FDefaultMap := AMap;
end;

{ TDwarfCompilationUnit }

procedure TDwarfCompilationUnit.BuildLineInfo(AAddressInfo: PDwarfAddressInfo; ADoAll: Boolean);
var
  Iter: TMapIterator;
  Info, NextInfo: PDwarfAddressInfo;
  idx: Integer;
  LineMap: PDWarfLineMap;
  Line: Cardinal;
  CurrentFileName: String;
  addr: QWord;
begin
  if not ADoAll
  then begin
    if AAddressInfo = nil then Exit;
    if AAddressInfo^.StateMachine <> nil then Exit;
  end;
  if FLineInfo.StateMachine = nil then Exit;
  if FLineInfo.StateMachine.Ended then Exit;

  BuildAddressMap;
  Iter := TMapIterator.Create(FAddressMap);
  idx := -1;
  Info := nil;
  NextInfo := nil;

  while FLineInfo.StateMachine.NextLine do
  begin
    Line := FLineInfo.StateMachine.Line;

    if (idx < 0) or (CurrentFileName <> FLineInfo.StateMachine.FileName) then begin
      idx := FLineNumberMap.IndexOf(FLineInfo.StateMachine.FileName);
      if idx = -1
      then begin
        LineMap := New(PDWarfLineMap);
        LineMap^.Init;
        FLineNumberMap.AddObject(FLineInfo.StateMachine.FileName, TObject(LineMap));
      end
      else begin
        LineMap := PDWarfLineMap(FLineNumberMap.Objects[idx]);
      end;
      CurrentFileName := FLineInfo.StateMachine.FileName;
    end;

    addr := FLineInfo.StateMachine.Address;
    LineMap^.SetAddressForLine(Line, addr);

    if (Info = nil) or
       (addr < Info^.StartPC) or
       ( (NextInfo <> nil) and (addr >= NextInfo^.StartPC) )
    then begin
      if Iter.Locate(FLineInfo.StateMachine.Address)
      then begin
        // set lineinfo
        Info := Iter.DataPtr;
        Iter.Next;
        if not Iter.EOM
        then NextInfo := Iter.DataPtr
        else NextInfo := nil;

        if Info^.StateMachine = nil
        then begin
          Info^.StateMachine := FLineInfo.StateMachine.Clone;
          FLineInfo.StateMachines.Add(Info^.StateMachine);
        end;
        if not ADoAll and (Info = AAddressInfo)
        then Break;
      end;
    end;
  end;

  Iter.Free;

  for Idx := 0 to FLineNumberMap.Count - 1 do
    PDWarfLineMap(FLineNumberMap.Objects[idx])^.Compress;
end;

function TDwarfCompilationUnit.GetAddressMap: TMap;
begin
  BuildAddressMap;
  Result := FAddressMap;
end;

function TDwarfCompilationUnit.FullFileName(const AFileName: String): String;
begin
  Result := AFileName;
  if FCompDir = '' then exit;
  Result := LazFileUtils.ResolveDots(FCompDir+AFileName);
end;

function TDwarfCompilationUnit.GetUnitName: String;
begin
  Result := FUnitName;
  if Result <> '' then exit;

  FUnitName := LazFileUtils.ExtractFileNameOnly(FileName);
  Result := FUnitName;
end;

function TDwarfCompilationUnit.GetDefinition(AAbbrevPtr: Pointer; out ADefinition: TDwarfAbbrev): Boolean;
begin
  Result := FAbbrevList.FindLe128bFromPointer(AAbbrevPtr, ADefinition) <> nil;
end;

procedure TDwarfCompilationUnit.ScanAllEntries;
var
  ResultScope: TDwarfScopeInfo;
begin
  if FScannedToEnd then exit;
  FScannedToEnd := True;
  // scan to end
  LocateEntry(0, ResultScope);
end;

procedure TDwarfCompilationUnit.BuildAddressMap;
var
  AttribList: TAttribPointerList;
  Attrib: Pointer;
  Form: Cardinal;
  Info: TDwarfAddressInfo;
  Scope: TDwarfScopeInfo;
  ScopeIdx: Integer;
  Abbrev: TDwarfAbbrev;
begin
  if FAddressMapBuild then Exit;

  ScanAllEntries;

  Scope := FScope;
  ScopeIdx := Scope.Index;

  while Scope.IsValid do
  begin
    if not GetDefinition(Scope.Entry, Abbrev) then begin
      inc(ScopeIdx);
      Scope.Index := ScopeIdx; // Child or Next, or parent.next
      continue;

      //DebugLn(FPDBG_DWARF_WARNINGS, ['No abbrev found']);
      //break;
    end;

    if Abbrev.tag = DW_TAG_subprogram then begin
      AttribList.EvalCount := 0;
      Info.ScopeIndex := Scope.Index;
      Info.ScopeList := Scope.FScopeList;
      // TODO: abstract origin
      if InitLocateAttributeList(Scope.Entry, AttribList) then begin // TODO: error if not
        if (dafHasLowAddr in AttribList.Abbrev^.flags) and
           LocateAttribute(Scope.Entry, DW_AT_low_pc, AttribList, Attrib, Form)
        then begin
          ReadAddressValue(Attrib, Form, Info.StartPC);

          if LocateAttribute(Scope.Entry, DW_AT_high_pc, AttribList, Attrib, Form)
          then ReadAddressValue(Attrib, Form, Info.EndPC)
          else Info.EndPC := Info.StartPC;

          // TODO (dafHasName in Abbrev.flags)
          if (dafHasName in AttribList.Abbrev^.flags) and
             LocateAttribute(Scope.Entry, DW_AT_name, AttribList, Attrib, Form)
          then ReadValue(Attrib, Form, Info.Name)
          else Info.Name := 'undefined';

          Info.StateMachine := nil;
          if Info.StartPC <> 0
          then begin
            if FAddressMap.HasId(Info.StartPC)
            then DebugLn(FPDBG_DWARF_WARNINGS, ['WARNING duplicate start address: ', IntToHex(Info.StartPC, FAddressSize * 2)])
            else FAddressMap.Add(Info.StartPC, Info);
          end;
        end;
      end;
    end;

    inc(ScopeIdx);
    Scope.Index := ScopeIdx; // Child or Next, or parent.next
  end;

  FAddressMapBuild := True;
end;

constructor TDwarfCompilationUnit.Create(AOwner: TFpDwarfInfo; ADebugFile: PDwarfDebugFile; ADataOffset: QWord; ALength: QWord; AVersion: Word; AAbbrevOffset: QWord; AAddressSize: Byte; AIsDwarf64: Boolean);
  procedure FillLineInfo(AData: Pointer);
  var
    LNP32: PDwarfLNPHeader32 absolute AData;
    LNP64: PDwarfLNPHeader64 absolute AData;
    Info: PDwarfLNPInfoHeader;

    UnitLength: QWord;
    Version: Word;
    HeaderLength: QWord;
    Name: PChar;
    diridx: Cardinal;
    S: String;
    pb: PByte absolute Name;
  begin
    FLineInfo.Header := AData;
    if LNP64^.Signature = DWARF_HEADER64_SIGNATURE
    then begin
      if FVersion < 3 then
        DebugLn(FPDBG_DWARF_WARNINGS, ['Unexpected 64 bit signature found for DWARF version 2']); // or version 1...
      FLineInfo.Addr64 := True;
      UnitLength := LNP64^.UnitLength;
      FLineInfo.DataEnd := Pointer(@LNP64^.Version) + UnitLength;
      Version := LNP64^.Version;
      HeaderLength := LNP64^.HeaderLength;
      Info := @LNP64^.Info;
    end
    else begin
      if (FVersion < 3) and (FAddressSize = 8) then
        FLineInfo.Addr64 := True
      else
        FLineInfo.Addr64 := False;
      UnitLength := LNP32^.UnitLength;
      FLineInfo.DataEnd := Pointer(@LNP32^.Version) + UnitLength;
      Version := LNP32^.Version;
      HeaderLength := LNP32^.HeaderLength;
      Info := @LNP32^.Info;
    end;
    if Version=0 then ;
    FLineInfo.DataStart := PByte(Info) + HeaderLength;

    FLineInfo.MinimumInstructionLength := Info^.MinimumInstructionLength;
    FLineInfo.DefaultIsStmt := Info^.DefaultIsStmt <> 0;
    FLineInfo.LineBase := Info^.LineBase;
    FLineInfo.LineRange := Info^.LineRange;

    // opcodelengths
    SetLength(FLineInfo.StandardOpcodeLengths, Info^.OpcodeBase - 1);
    Move(Info^.StandardOpcodeLengths, FLineInfo.StandardOpcodeLengths[0], Info^.OpcodeBase - 1);

    // directories & filenames
    FLineInfo.Directories := TStringList.Create;
    FLineInfo.Directories.Add(''); // current dir
    Name := @Info^.StandardOpcodeLengths;
    Inc(Name, Info^.OpcodeBase-1);
    // directories
    while Name^ <> #0 do
    begin
      S := String(Name);
      Inc(pb, Length(S)+1);
      FLineInfo.Directories.Add(S + DirectorySeparator);
    end;
    Inc(Name);

    // filenames
    FLineInfo.FileNames := TStringList.Create;
    while Name^ <> #0 do
    begin
      S := String(Name);
      Inc(pb, Length(S)+1);
      //diridx
      diridx := ULEB128toOrdinal(pb);
      if diridx < FLineInfo.Directories.Count
      then S := FLineInfo.Directories[diridx] + S
      else S := Format('Unknown dir(%u)', [diridx]) + DirectorySeparator + S;
      FLineInfo.FileNames.Add(S);
      //last modified
      ULEB128toOrdinal(pb);
      //length
      ULEB128toOrdinal(pb);
    end;

    FLineInfo.StateMachine := TDwarfLineInfoStateMachine.Create(Self, FLineInfo.DataStart, FLineInfo.DataEnd);
    FLineInfo.StateMachines := TFPObjectList.Create(True);

    FLineInfo.Valid := True;
  end;

var
  AttribList: TAttribPointerList;
  Attrib: Pointer;
  Form: Cardinal;
  StatementListOffs, Offs: QWord;
  Scope: TDwarfScopeInfo;
begin
  //DebugLn(FPDBG_DWARF_VERBOSE, ['-- compilation unit --']);
  //DebugLn(FPDBG_DWARF_VERBOSE, [' data offset: ', ADataOffset]);
  //DebugLn(FPDBG_DWARF_VERBOSE, [' length: ', ALength]);
  //DebugLn(FPDBG_DWARF_VERBOSE, [' version: ', AVersion]);
  //DebugLn(FPDBG_DWARF_VERBOSE, [' abbrev offset: ', AAbbrevOffset]);
  //DebugLn(FPDBG_DWARF_VERBOSE, [' address size: ', AAddressSize]);
  //DebugLn(FPDBG_DWARF_VERBOSE, [' 64bit: ', AIsDwarf64]);
  //DebugLn(FPDBG_DWARF_VERBOSE, ['----------------------']);
  inherited Create;
  FOwner := AOwner;
  FDebugFile := ADebugFile;
  FInfoData := ADebugFile^.Sections[dsInfo].RawData + ADataOffset;
  FLength := ALength;
  FVersion := AVersion;
  FAbbrevOffset := AAbbrevOffset;
  // check for address as offset
  if FAbbrevOffset > ADebugFile^.Sections[dsAbbrev].Size
  then begin
    Offs := FAbbrevOffset - FOwner.FImageBase - ADebugFile^.Sections[dsAbbrev].VirtualAddress;
    if (Offs >= 0) and (Offs < ADebugFile^.Sections[dsAbbrev].Size)
    then begin
      DebugLn(FPDBG_DWARF_WARNINGS, ['WARNING: Got Abbrev offset as address, adjusting..']);
      FAbbrevOffset := Offs;
    end;
  end;

  FAddressSize := AAddressSize;
  FIsDwarf64 := AIsDwarf64;

  FAbbrevList := TDwarfAbbrevList.Create(ADebugFile^.Sections[dsAbbrev].RawData,
    ADebugFile^.Sections[dsAbbrev].RawData + ADebugFile^.Sections[dsAbbrev].Size,
    FAbbrevOffset, FLength);

  // use internally 64 bit target pointer
  FAddressMap := TMap.Create(itu8, SizeOf(TDwarfAddressInfo));
  FLineNumberMap := TStringList.Create;
  FLineNumberMap.Sorted := True;
  FLineNumberMap.Duplicates := dupError;

  SetLength(FScopeList.List, Min(SCOPE_ALLOC_BLOCK_SIZE, FLength div 2 + 1));
  FScopeList.List[0].Link := -1;
  FScopeList.List[0].Entry  := FInfoData;
  FScopeList.HighestKnown := 0;
  FScope.Init(@FScopeList);
  FScope.Index := 0;
  // retrieve some info about this unit
  if not LocateEntry(DW_TAG_compile_unit, Scope)
  then begin
    DebugLn(FPDBG_DWARF_WARNINGS, ['WARNING compilation unit has no compile_unit tag']);
    Exit;
  end;
  FValid := True;

  AttribList.EvalCount := 0;
  /// TODO: (dafHasName in Abbrev.flags)
  if LocateAttribute(Scope.Entry, DW_AT_name, AttribList, Attrib, Form)
  then ReadValue(Attrib, Form, FFileName);

  if LocateAttribute(Scope.Entry, DW_AT_comp_dir, AttribList, Attrib, Form)
  then ReadValue(Attrib, Form, FCompDir);

  if LocateAttribute(Scope.Entry, DW_AT_producer, AttribList, Attrib, Form)
  then ReadValue(Attrib, Form, FProducer);

  FDwarfSymbolClassMap := DwarfSymbolClassMapList.FindMapForCompUnit(Self);
  assert(FDwarfSymbolClassMap <> nil, 'TDwarfCompilationUnit.Create: FDwarfSymbolClassMap <> nil');

  if not LocateAttribute(Scope.Entry, DW_AT_identifier_case, AttribList, Attrib, Form)
  and not ReadValue(Attrib, Form, FIdentifierCase)
  then FIdentifierCase := DW_ID_case_sensitive;

  if LocateAttribute(Scope.Entry, DW_AT_stmt_list, AttribList, Attrib, Form)
  and ReadValue(Attrib, Form, StatementListOffs)
  then begin
    // check for address as offset
    if StatementListOffs < ADebugFile^.Sections[dsLine].Size
    then begin
      FillLineInfo(ADebugFile^.Sections[dsLine].RawData + StatementListOffs);
    end
    else begin
      Offs := StatementListOffs - FOwner.FImageBase - ADebugFile^.Sections[dsLine].VirtualAddress;
      if (Offs >= 0) and (Offs < ADebugFile^.Sections[dsLine].Size)
      then begin
        DebugLn(FPDBG_DWARF_WARNINGS, ['WARNING: Got Lineinfo offset as address, adjusting..']);
        FillLineInfo(ADebugFile^.Sections[dsLine].RawData + Offs);
      end;
    end;
  end;

  if LocateAttribute(Scope.Entry, DW_AT_low_pc, AttribList, Attrib, Form)
  then ReadAddressValue(Attrib, Form, FMinPC);

  if LocateAttribute(Scope.Entry, DW_AT_high_pc, AttribList, Attrib, Form)
  then ReadAddressValue(Attrib, Form, FMaxPC);

  if FMinPC = 0 then FMinPC := FMaxPC;
  if FMaxPC = 0 then FMAxPC := FMinPC;
end;

destructor TDwarfCompilationUnit.Destroy;
  procedure FreeLineNumberMap;
  var
    n: Integer;
  begin
    for n := 0 to FLineNumberMap.Count - 1 do
      Dispose(PDWarfLineMap(FLineNumberMap.Objects[n]));
    FreeAndNil(FLineNumberMap);
  end;

begin
  FreeAndNil(FAbbrevList);
  FreeAndNil(FAddressMap);
  FreeLineNumberMap;
  FreeAndNil(FLineInfo.StateMachines);
  FreeAndNil(FLineInfo.StateMachine);
  FreeAndNil(FLineInfo.Directories);
  FreeAndNil(FLineInfo.FileNames);

  inherited Destroy;
end;

function TDwarfCompilationUnit.GetLineAddressMap(const AFileName: String): PDWarfLineMap;
  var
    Name: String;
  function FindIndex: Integer;
  begin
    // try fullname first
    Result := FLineNumberMap.IndexOf(AFileName);
    if Result <> -1 then Exit;
    
    Name := ExtractFileName(AFileName);
    Result := FLineNumberMap.IndexOf(Name);
    if Result <> -1 then Exit;

    Name := UpperCase(Name);
    for Result := 0 to FLineNumberMap.Count - 1 do
    begin
      if Name = UpperCase(ExtractFileName(FLineNumberMap[Result]))
      then Exit;
    end;
    Result := -1
  end;
var
  idx: Integer;
begin
  Result := nil;
  if not Valid then Exit;

  // make sure all filenames are there
  BuildLineInfo(nil, True);
  idx := FindIndex;
  if idx = -1 then Exit;
  
  Result := PDWarfLineMap(FLineNumberMap.Objects[idx]);
end;

function TDwarfCompilationUnit.GetLineAddress(const AFileName: String; ALine: Cardinal): TDbgPtr;
var
  Map: PDWarfLineMap;
begin
  Result := 0;
  Map := GetLineAddressMap(AFileName);
  if Map = nil then exit;
  Result := Map^.GetAddressForLine(ALine);
end;

function TDwarfCompilationUnit.InitLocateAttributeList(AEntry: Pointer;
  var AList: TAttribPointerList): Boolean;
var
  AbrCnt: Integer;
begin
  if FAbbrevList.FindLe128bFromPointer(AEntry, AList.Abbrev) = nil then begin
  //if not GetDefinition(AEntry, AList.Abbrev)
  //then begin      //???
    DebugLn(FPDBG_DWARF_WARNINGS, ['Error: Abbrev not found: ', ULEB128toOrdinal(AEntry)]);
    AList.EvalCount := -1;
    Result := False;
    Exit;
  end;

  AbrCnt := AList.Abbrev^.count;
  if AbrCnt = 0 then begin
    AList.EvalCount := -1;
    exit;
  end;
  SetLength(AList.List, AbrCnt);
  ULEB128toOrdinal(AEntry);
  AList.List[0] := AEntry;
  AList.EvalCount := 1;

  Result := True;
end;

function TDwarfCompilationUnit.LocateAttribute(AEntry: Pointer; AAttribute: Cardinal;
  var AList: TAttribPointerList; out AAttribPtr: Pointer; out AForm: Cardinal): Boolean;
var
  Abbrev: Cardinal;
  i, EvalCnt, AbrIdx, AbrCnt: Integer;
  ADefs: PDwarfAbbrevEntry;
begin
  Result := False;
  if AList.EvalCount < 0 then
    exit;

  if AList.EvalCount = 0 then begin
    if FAbbrevList.FindLe128bFromPointer(AEntry, AList.Abbrev) = nil then begin
    //if not GetDefinition(AEntry, AList.Abbrev)
    //then begin      //???
      Abbrev := ULEB128toOrdinal(AEntry);
      DebugLn(FPDBG_DWARF_WARNINGS, ['Error: Abbrev not found: ', Abbrev]);
      AList.EvalCount := -1;
      Exit;
    end;

    AbrIdx := AList.Abbrev^.count;
    if AbrIdx = 0 then begin
      AList.EvalCount := -1;
      exit;
    end;
    SetLength(AList.List, AbrIdx);
    ULEB128toOrdinal(AEntry);
    AList.List[0] := AEntry;
    AList.EvalCount := 1;
  end;

  ADefs := FAbbrevList.EntryPointer[0];
  AbrIdx := AList.Abbrev^.Index;
  AbrCnt := AList.Abbrev^.Count - 1;
  EvalCnt := AList.EvalCount - 1;
  i := 0;

  while true do begin
    if ADefs[AbrIdx].Attribute = AAttribute
    then begin
      Result := True;
      AAttribPtr := AList.List[i];
      AForm := ADefs[AbrIdx].Form;
      break;
    end;

    if i = AbrCnt then
      break;

    if (i < EvalCnt) then begin
      inc(i);
      inc(AbrIdx);
      Continue;
    end;

    AEntry := AList.List[i];
    if not SkipEntryDataForForm(AEntry, ADefs[AbrIdx].Form, FAddressSize, IsDwarf64, Version) then
      break;
    AList.List[i+1] := AEntry;
    inc(i);
    inc(AbrIdx);
  end;

  if i {+ 1} > EvalCnt {+ 1} then
    AList.EvalCount := i + 1
end;

function TDwarfCompilationUnit.LocateAttribute(AEntry: Pointer; AAttribute: Cardinal; out
  AAttribPtr: Pointer; out AForm: Cardinal): Boolean;
var
  Def: TDwarfAbbrev;
  n: Integer;
  ADefs: PDwarfAbbrevEntry;
begin
  AEntry := FAbbrevList.FindLe128bFromPointer(AEntry, Def);
  if AEntry = nil
  then begin
    //???
    //Abbrev := ULEB128toOrdinal(AEntry);
    DebugLn(FPDBG_DWARF_WARNINGS, ['Error: Abbrev not found: '{, Abbrev}]);
    Result := False;
    Exit;
  end;

  ADefs := FAbbrevList.EntryPointer[0];
  for n := Def.Index to Def.Index + Def.Count - 1 do
  begin
    if ADefs[n].Attribute = AAttribute
    then begin
      Result := True;
      AAttribPtr := AEntry;
      AForm := ADefs[n].Form;
      Exit;
    end
    else begin
      if not SkipEntryDataForForm(AEntry, ADefs[n].Form, FAddressSize, IsDwarf64, Version) then
        break;
    end;
  end;
  Result := False;
end;

//----------------------------------------
// Params
//   ATag: a tag to search for
//   AStartScope: a startpoint in the data
//   ACurrentOnly: if set, process only current entry
//   AResultScope: the located scope info
//----------------------------------------
function TDwarfCompilationUnit.LocateEntry(ATag: Cardinal; out
  AResultScope: TDwarfScopeInfo): Boolean;

  function ParseAttribs(const ADef: PDwarfAbbrev; var p: Pointer): Boolean;
  var
    idx: Integer;
    ADefs: PDwarfAbbrevEntry;
    AddrSize: Byte;
  begin
    ADefs := FAbbrevList.EntryPointer[ADef^.Index];
    AddrSize := FAddressSize;
    for idx := 0 to ADef^.Count - 1 do
    begin
      if not SkipEntryDataForForm(p, ADefs^.Form, AddrSize, IsDwarf64, Version) then
        exit(False);
      inc(ADefs);
    end;
    Result := True;
  end;

var
  Abbrev: Cardinal;
  Def: PDwarfAbbrev;
  MaxData: Pointer;
  p, EntryDataPtr, NextEntryDataPtr: Pointer;
  Scope: TDwarfScopeInfo;
  ni: Integer;
  AppendAsChild: Boolean;
begin
  Result := False;
  if not FScope.IsValid then Exit;
  MaxData := FInfoData + FLength;
  Scope := FScope;
  Scope.Index := FScopeList.HighestKnown; // last known scope

  // "last rounds" NextEntryDataPtr
  NextEntryDataPtr := Scope.Entry;
  while (NextEntryDataPtr < MaxData) do
  begin
    EntryDataPtr := NextEntryDataPtr;

    NextEntryDataPtr := FAbbrevList.FindLe128bFromPointer(EntryDataPtr, Def);
    if NextEntryDataPtr = nil then begin
      Abbrev := ULEB128toOrdinal(EntryDataPtr);
      DebugLn(FPDBG_DWARF_WARNINGS, ['Error: Abbrev not found: ', Abbrev]);
          // TODO shorten array
      exit;
    end;

    if (ATag <> 0) and (Def^.tag = ATag) then begin
      Result := True;
      AResultScope := Scope;
      Break;
    end;

    if not ParseAttribs(Def, NextEntryDataPtr) then begin
      DebugLn(FPDBG_DWARF_WARNINGS, ['Error: data not parsed:']);
      exit;
    end;
    // NextEntryDataPtr is now at next scope

    if NextEntryDataPtr >= MaxData then
      break;

    p := NextEntryDataPtr;
    Abbrev := ULEB128toOrdinal(p);
    if Abbrev = 0 then begin      // no more sibling
      AppendAsChild := False;     // children already done
      if (dafHasChildren in Def^.flags) then begin  // current has 0 children
        NextEntryDataPtr := p;
        if NextEntryDataPtr >= MaxData then
          break;
        Abbrev := ULEB128toOrdinal(p);
      end;
      while (Abbrev = 0) do begin
        NextEntryDataPtr := p;
        if NextEntryDataPtr >= MaxData then
          break;
        Scope.GoParent;
        if not Scope.IsValid then begin
          DebugLn(FPDBG_DWARF_WARNINGS, ['Error: Abbrev not found: ', Abbrev]);
          // TODO shorten array
          exit;
        end;
        Abbrev := ULEB128toOrdinal(p);
      end;
      if NextEntryDataPtr >= MaxData then
        break;
    end
    else
      AppendAsChild := (dafHasChildren in Def^.flags);

    if AppendAsChild then
      ni := Scope.CreateChildForEntry(NextEntryDataPtr)
    else
      ni := Scope.CreateNextForEntry(NextEntryDataPtr);

    Scope.FIndex := ni; // skip check, index was just created / must exist
  end;

  if (NextEntryDataPtr >= MaxData) then begin
    if (EntryDataPtr > MaxData) then
      debugln(FPDBG_DWARF_WARNINGS, ['LocateEntry went past end of memory: ', EntryDataPtr-MaxData]);
    SetLength(FScopeList.List, FScopeList.HighestKnown + 1);
  end;

end;

function TDwarfCompilationUnit.ReadAddressAtPointer(var AData: Pointer;
  AIncPointer: Boolean): TFpDbgMemLocation;
begin
  // do not need mem reader, address is in dwarf. Should be in correct format
  if ((Version>2) and IsDwarf64) or ((version < 3) and (FAddressSize = 8)) then
    Result := TargetLoc(PQWord(AData)^)
  else
    Result := TargetLoc(PLongWord(AData)^);
  if AIncPointer then inc(AData, FAddressSize);
end;

function TDwarfCompilationUnit.MapAddressToNewValue(AValue: QWord): QWord;
var
  i: Integer;
  AddrMap: TDbgAddressMap;
begin
  result := avalue;
  if assigned(DebugFile^.AddressMapList) then
    for i := 0 to DebugFile^.AddressMapList.Count-1 do
    begin
      AddrMap:=DebugFile^.AddressMapList[i];
      if AddrMap.OrgAddr=AValue then
      begin
        result:=AddrMap.NewAddr;
        break;
      end
      else if (AddrMap.OrgAddr<AValue) and (AValue<=(AddrMap.OrgAddr+AddrMap.Length)) then
      begin
        result:=AddrMap.NewAddr + (AValue-AddrMap.OrgAddr) ;
        break;
      end;
    end;
end;

function TDwarfCompilationUnit.ReadValue(AAttribute: Pointer; AForm: Cardinal; out AValue: Cardinal): Boolean;
begin
  Result := True;
  case AForm of
    DW_FORM_addr,
    DW_FORM_ref_addr : begin
      AValue := LocToAddrOrNil(ReadAddressAtPointer(AAttribute));
    end;
    DW_FORM_flag,
    DW_FORM_ref1,
    DW_FORM_data1    : begin
      AValue := PByte(AAttribute)^;
    end;
    DW_FORM_ref2,
    DW_FORM_data2    : begin
      AValue := PWord(AAttribute)^;
    end;
    DW_FORM_ref4,
    DW_FORM_data4    : begin
      AValue := PLongWord(AAttribute)^;
    end;
    DW_FORM_ref8,
    DW_FORM_data8    : begin
      AValue := PQWord(AAttribute)^;
    end;
    DW_FORM_sdata    : begin
      AValue := SLEB128toOrdinal(AAttribute);
    end;
    DW_FORM_ref_udata,
    DW_FORM_udata    : begin
      AValue := ULEB128toOrdinal(AAttribute);
    end;
  else
    Result := False;
  end;
end;

function TDwarfCompilationUnit.ReadValue(AAttribute: Pointer; AForm: Cardinal; out AValue: Int64): Boolean;
begin
  Result := True;
  case AForm of
    DW_FORM_addr,
    DW_FORM_ref_addr : begin
      AValue := LocToAddrOrNil(ReadAddressAtPointer(AAttribute));
    end;
    DW_FORM_flag,
    DW_FORM_ref1,
    DW_FORM_data1    : begin
      AValue := PShortInt(AAttribute)^;
    end;
    DW_FORM_ref2,
    DW_FORM_data2    : begin
      AValue := PSmallInt(AAttribute)^;
    end;
    DW_FORM_ref4,
    DW_FORM_data4    : begin
      AValue := PLongInt(AAttribute)^;
    end;
    DW_FORM_ref8,
    DW_FORM_data8    : begin
      AValue := PInt64(AAttribute)^;
    end;
    DW_FORM_sdata    : begin
      AValue := SLEB128toOrdinal(AAttribute);
    end;
    DW_FORM_ref_udata,
    DW_FORM_udata    : begin
      AValue := Int64(ULEB128toOrdinal(AAttribute));
    end;
  else
    Result := False;
  end;
end;

function TDwarfCompilationUnit.ReadValue(AAttribute: Pointer; AForm: Cardinal; out AValue: Integer): Boolean;
begin
  Result := True;
  case AForm of
    DW_FORM_addr,
    DW_FORM_ref_addr : begin
      AValue := LocToAddrOrNil(ReadAddressAtPointer(AAttribute));
    end;
    DW_FORM_flag,
    DW_FORM_ref1,
    DW_FORM_data1    : begin
      AValue := PShortInt(AAttribute)^;
    end;
    DW_FORM_ref2,
    DW_FORM_data2    : begin
      AValue := PSmallInt(AAttribute)^;
    end;
    DW_FORM_ref4,
    DW_FORM_data4    : begin
      AValue := PLongInt(AAttribute)^;
    end;
    DW_FORM_ref8,
    DW_FORM_data8    : begin
      AValue := PInt64(AAttribute)^;
    end;
    DW_FORM_sdata    : begin
      AValue := SLEB128toOrdinal(AAttribute);
    end;
    DW_FORM_ref_udata,
    DW_FORM_udata    : begin
      AValue := ULEB128toOrdinal(AAttribute);
    end;
  else
    Result := False;
  end;
end;

function TDwarfCompilationUnit.ReadValue(AAttribute: Pointer; AForm: Cardinal; out AValue: PChar): Boolean;
begin
  Result := True;
  case AForm of
    DW_FORM_string: begin
      AValue := PChar(AAttribute);
    end;
    DW_FORM_strp:   begin
      AValue := pchar(PtrUInt(FDebugFile^.Sections[dsStr].RawData)+PDWord(AAttribute)^);
    end;
  else
    Result := False;
  end;
end;

function TDwarfCompilationUnit.ReadValue(AAttribute: Pointer; AForm: Cardinal; out AValue: QWord): Boolean;
begin
  Result := True;
  case AForm of
    DW_FORM_addr,
    DW_FORM_ref_addr : begin
      AValue := LocToAddrOrNil(ReadAddressAtPointer(AAttribute));
    end;
    DW_FORM_flag,
    DW_FORM_ref1,
    DW_FORM_data1    : begin
      AValue := PByte(AAttribute)^;
    end;
    DW_FORM_ref2,
    DW_FORM_data2    : begin
      AValue := PWord(AAttribute)^;
    end;
    DW_FORM_ref4,
    DW_FORM_data4    : begin
      AValue := PLongWord(AAttribute)^;
    end;
    DW_FORM_ref8,
    DW_FORM_data8    : begin
      AValue := PQWord(AAttribute)^;
    end;
    DW_FORM_sdata    : begin
      AValue := QWord(SLEB128toOrdinal(AAttribute));
    end;
    DW_FORM_ref_udata,
    DW_FORM_udata    : begin
      AValue := ULEB128toOrdinal(AAttribute);
    end;
  else
    Result := False;
  end;
end;

function TDwarfCompilationUnit.ReadValue(AAttribute: Pointer; AForm: Cardinal; out AValue: String): Boolean;
begin
  Result := True;
  case AForm of
    DW_FORM_string: begin
      AValue := PChar(AAttribute);
    end;
    DW_FORM_strp:   begin
      AValue := PChar(PtrUInt(FDebugFile^.Sections[dsStr].RawData)+PDWord(AAttribute)^);
    end;
  else
    Result := False;
  end;
end;

function TDwarfCompilationUnit.ReadValue(AAttribute: Pointer; AForm: Cardinal; out AValue: TByteDynArray): Boolean;
var
  Size: Cardinal;
begin
  Result := True;
  case AForm of
    DW_FORM_block    : begin
      Size := ULEB128toOrdinal(AAttribute);
    end;
    DW_FORM_block1   : begin
      Size := PByte(AAttribute)^;
      Inc(AAttribute, 1);
    end;
    DW_FORM_block2   : begin
      Size := PWord(AAttribute)^;
      Inc(AAttribute, 2);
    end;
    DW_FORM_block4   : begin
      Size := PLongWord(AAttribute)^;
      Inc(AAttribute, 4);
    end;
  else
    Result := False;
    Size := 0;
  end;
  SetLength(AValue, Size);
  if Size > 0 then
    Move(AAttribute^, AValue[0], Size);
end;

function TDwarfCompilationUnit.ReadAddressValue(AAttribute: Pointer; AForm: Cardinal; out AValue: QWord): Boolean;
begin
  result := ReadValue(AAttribute, AForm, AValue);
  if result then
    AValue := MapAddressToNewValue(AValue);
end;

initialization
  TheDwarfSymbolClassMapList := TFpDwarfSymbolClassMapList.Create;

  FPDBG_DWARF_ERRORS        := DebugLogger.FindOrRegisterLogGroup('FPDBG_DWARF_ERRORS' {$IFDEF FPDBG_DWARF_ERRORS} , True {$ENDIF} );
  FPDBG_DWARF_WARNINGS      := DebugLogger.FindOrRegisterLogGroup('FPDBG_DWARF_WARNINGS' {$IFDEF FPDBG_DWARF_WARNINGS} , True {$ENDIF} );
  FPDBG_DWARF_VERBOSE       := DebugLogger.FindOrRegisterLogGroup('FPDBG_DWARF_VERBOSE' {$IFDEF FPDBG_DWARF_VERBOSE} , True {$ENDIF} );
  FPDBG_DWARF_VERBOSE_LOAD  := DebugLogger.FindOrRegisterLogGroup('FPDBG_DWARF_VERBOSE_LOAD' {$IFDEF FPDBG_DWARF_VERBOSE_LOAD} , True {$ENDIF} );
  FPDBG_DWARF_SEARCH        := DebugLogger.FindOrRegisterLogGroup('FPDBG_DWARF_SEARCH' {$IFDEF FPDBG_DWARF_SEARCH} , True {$ENDIF} );
  // Target data anormalities
  //FPDBG_DWARF_DATA_WARNINGS :=
  DebugLogger.FindOrRegisterLogGroup('FPDBG_DWARF_DATA_WARNINGS' {$IFDEF FPDBG_DWARF_DATA_WARNINGS} , True {$ENDIF} );

finalization
  FreeAndNil(TheDwarfSymbolClassMapList);
end.

