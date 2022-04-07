unit IdeDebuggerWatchResult;

{$mode objfpc}{$H+}
{$ModeSwitch typehelpers}

interface

uses
  Classes, SysUtils, Types, IdeDebuggerUtils, LazDebuggerIntf,
  LazDebuggerIntfBaseTypes, LazUTF8, Laz2_XMLCfg, StrUtils;

type

  TWatchResultDataKind = (
    rdkUnknown,
    rdkError, rdkPrePrinted,
    rdkString, rdkWideString,
    rdkSignedNumVal, rdkUnsignedNumVal, rdkPointerVal, rdkFloatVal,
    rdkEnum, rdkSet,
    rdkPCharOrString,
    rdkArray
  );

  TWatchResultData = class;
  TWatchResultDataArrayStorageHelper = class;

  { TWatchResultValue }

  TWatchResultValue = object
  protected
    function GetAsString: String; inline;
    function GetAsWideString: WideString; inline;
    function GetAsQWord: QWord; inline;
    function GetAsInt64: Int64; inline;
    function GetAsFloat: Extended; inline;
    function GetByteSize: Integer; inline;                         // Int, Enum
    function GetFloatPrecission: TLzDbgFloatPrecission; inline;
    function GetCount: Integer; inline;                            // Set (Active Elements)
    function GetElementName(AnIndex: integer): String; inline;     // Set/Array
    function GetDerefData: TWatchResultData; inline;               // Ptr

    function GetSelectedEntry: TWatchResultData; inline;

    procedure AfterAssign;
    procedure DoFree;
    procedure LoadDataFromXMLConfig(const AConfig: TXMLConfig; const APath: string);
    procedure SaveDataToXMLConfig(const AConfig: TXMLConfig; const APath: string);
  end;

  { TWatchResultValueTextBase }

  TWatchResultValueTextBase = object(TWatchResultValue)
  private
    FText: String;
  protected
    property GetAsString: String read FText;
    procedure LoadDataFromXMLConfig(const AConfig: TXMLConfig; const APath: string);
    procedure SaveDataToXMLConfig(const AConfig: TXMLConfig; const APath: string);
  end;

  { TWatchResultValuePrePrinted }

  TWatchResultValuePrePrinted = object(TWatchResultValueTextBase)
  protected const
    VKind = rdkPrePrinted;
  end;

  { TWatchResultValueString }

  TWatchResultValueString = object(TWatchResultValueTextBase)
  protected const
    VKind = rdkString;
  end;

  { TWatchResultValueWideString }

  TWatchResultValueWideString = object(TWatchResultValue)
  protected const
    VKind = rdkWideString;
  private
    FWideText: WideString;
  protected
    property GetAsWideString: WideString read FWideText;
    function GetAsString: String; inline;
    procedure LoadDataFromXMLConfig(const AConfig: TXMLConfig; const APath: string);
    procedure SaveDataToXMLConfig(const AConfig: TXMLConfig; const APath: string);
  end;

  { TWatchResultValueOrdNumBase }

  TWatchResultValueOrdNumBase = object(TWatchResultValue)
  private
    FNumValue: QWord;
  protected
    property GetAsQWord: QWord read FNumValue;
    function GetAsInt64: Int64; inline;
    procedure LoadDataFromXMLConfig(const AConfig: TXMLConfig; const APath: string);
    procedure SaveDataToXMLConfig(const AConfig: TXMLConfig; const APath: string);
  end;

  { TWatchResultTypeOrdNum }

  TWatchResultTypeOrdNum = object(TWatchResultValue)
  private
    FNumByteSize: Integer; // SmallInt
  protected
    property GetByteSize: Integer read FNumByteSize;
    procedure LoadDataFromXMLConfig(const AConfig: TXMLConfig; const APath: string);
    procedure SaveDataToXMLConfig(const AConfig: TXMLConfig; const APath: string);
  end;

  { TWatchResultValueSignedNum }

  TWatchResultValueSignedNum = object(TWatchResultValueOrdNumBase)
  protected const
    VKind = rdkSignedNumVal;
  protected
    function GetAsString: String; inline;
  end;

  { TWatchResultValueUnsignedNum }

  TWatchResultValueUnsignedNum = object(TWatchResultValueOrdNumBase)
  protected const
    VKind = rdkUnsignedNumVal;
  protected
    function GetAsString: String; inline;
  end;

  { TWatchResultValuePointer }

  TWatchResultValuePointer = object(TWatchResultValueOrdNumBase)
  protected const
    VKind = rdkPointerVal;
  protected
    function GetAsString: String; inline;
  end;

  { TWatchResultTypePointer }

  TWatchResultTypePointer = object(TWatchResultValue)
  private
    FDerefData: TWatchResultData;
  protected
    property GetDerefData: TWatchResultData read FDerefData;
    function GetAsString: String; inline;
    procedure AfterAssign;
    procedure DoFree;
    procedure LoadDataFromXMLConfig(const AConfig: TXMLConfig; const APath: string);
    procedure SaveDataToXMLConfig(const AConfig: TXMLConfig; const APath: string);
  end;

  { TWatchResultValueFloat }

  TWatchResultValueFloat = object(TWatchResultValue)
  protected const
    VKind = rdkFloatVal;
  private
    FFloatValue: Extended;
  protected
    property GetAsFloat: Extended read FFloatValue;
    function GetAsString: String; inline;
    procedure LoadDataFromXMLConfig(const AConfig: TXMLConfig; const APath: string);
    procedure SaveDataToXMLConfig(const AConfig: TXMLConfig; const APath: string);
  end;

  { TWatchResultTypeFloat }

  TWatchResultTypeFloat = object(TWatchResultValue)
  private
    FFloatPrecission: TLzDbgFloatPrecission;
  protected
    property FloatPrecission: TLzDbgFloatPrecission read FFloatPrecission;
    function GetAsString: String; inline;
    procedure LoadDataFromXMLConfig(const AConfig: TXMLConfig; const APath: string);
    procedure SaveDataToXMLConfig(const AConfig: TXMLConfig; const APath: string);
  end;

  { TWatchResultValueEnum }

  TWatchResultValueEnum = object(TWatchResultValueOrdNumBase)
  protected const
    VKind = rdkEnum;
  private
    FName: String;
  protected
    property GetAsString: String read FName;
    procedure LoadDataFromXMLConfig(const AConfig: TXMLConfig; const APath: string);
    procedure SaveDataToXMLConfig(const AConfig: TXMLConfig; const APath: string);
  end;

  { TWatchResultValueSet }

  TWatchResultValueSet = object(TWatchResultValue)
  protected const
    VKind = rdkSet;
  private
    FNames: Array of String;
  protected
    function GetCount: Integer; inline;
    function GetElementName(AnIndex: integer): String; inline;
    procedure LoadDataFromXMLConfig(const AConfig: TXMLConfig; const APath: string);
    procedure SaveDataToXMLConfig(const AConfig: TXMLConfig; const APath: string);
  end;

  { TWatchResultValueError }

  TWatchResultValueError = object(TWatchResultValueTextBase)
  protected const
    VKind = rdkError;
  end;

  { TWatchResultValueArrayBase }

  TWatchResultValueArrayBase = object(TWatchResultValue)
  private
    FEntries: TWatchResultDataArrayStorageHelper;
  protected
    function GetCount: Integer;
    procedure AfterAssign;
    procedure DoFree;
  end;

  TWatchResultTypeArrayBase = object(TWatchResultValue)
  private
    FEntryWithType: TWatchResultData;
    //FBoundType // static array
    //FLow, FHigh // static array
  protected
    property GetSelectedEntry: TWatchResultData read FEntryWithType;
    procedure AfterAssign;
    procedure DoFree;
  end;

  TWatchResultValuePCharOrString = object(TWatchResultValueArrayBase)
  protected const
    VKind = rdkPCharOrString;
  end;

  { TWatchResultValueArray }

  TWatchResultValueArray = object(TWatchResultValueArrayBase)
  protected const
    VKind = rdkArray;
  private
    // FLength // DynArray
  protected
  end;

  { TWatchResultTypeArrayBase }

  TWatchResultTypeArray = object(TWatchResultValue)
  private
    //FBoundType // static array
    //FLow, FHigh // static array
  protected
  end;


  { TWatchResultDataArrayStorageHelper }

  TWatchResultDataArrayStorageHelper = class
  protected
    function  GetCount: integer; virtual; abstract;
    procedure SetCount(AValue: integer); virtual; abstract;
    procedure SetNestedStorage(AValue: TWatchResultDataArrayStorageHelper); virtual;
    function  GetNestedStorage: TWatchResultDataArrayStorageHelper; virtual;
    procedure Assign(ASource: TWatchResultDataArrayStorageHelper); virtual; abstract;
  public
    function CreateCopy: TWatchResultDataArrayStorageHelper; virtual;
    procedure ClearData(AData: TWatchResultData); virtual; abstract;
    procedure SaveToIndex(AnIndex: Integer; AData: TWatchResultData); virtual; abstract;
    procedure LoadFromIndex(AnIndex: Integer; AData: TWatchResultData); virtual; abstract;
    property Count: integer read GetCount write SetCount;
    property NestedStorage: TWatchResultDataArrayStorageHelper read GetNestedStorage write SetNestedStorage;
  end;
  TWatchResultDataArrayStorageHelperClass = class of TWatchResultDataArrayStorageHelper;

  { TGenericWatchResultDataArrayStorageHelper }

  generic TGenericWatchResultDataArrayStorageHelper<_DATA> = class(TWatchResultDataArrayStorageHelper)
  private
    FDataArray: packed array of _DATA;
  protected
    function GetCount: integer; override;
    procedure SetCount(AValue: integer); override;
    procedure Assign(ASource: TWatchResultDataArrayStorageHelper); override;
  public
    destructor Destroy; override; // DoFree() for items
  end;

  TWatchResultDataClassID = (
    wdPrePrint,  // TWatchResultDataPrePrinted
    wdString,    // TWatchResultDataString
    wdWString,   // TWatchResultDataWideString
    wdSNum,      // TWatchResultDataSignedNum
    wdUNum,      // TWatchResultDataUnSignedNum
    wdPtr,       // TWatchResultDataPointer
    wdFloat,     // TWatchResultDataFloat
    wdEnum,      // TWatchResultDataEnum
    wdSet,       // TWatchResultDataSet
    wdPChrStr,   // TWatchResultDataPCharOrString
    wdErr        // TWatchResultDataError
  );

  { TWatchResultData }

  TWatchResultData = class // (TRefCountedObject)
  private
    FTypeName: String;
  //  ValidData: TWatchValueDataFlags;
  //  Addr: TDbgPtr;
  // MemDump
    function GetClassID: TWatchResultDataClassID; virtual; //abstract;
  protected
    function GetArrayStorageHelperClass: TWatchResultDataArrayStorageHelperClass; virtual; abstract;
    function CreateArrayStorageHelper: TWatchResultDataArrayStorageHelper; virtual; abstract;
    procedure WriteDataToStorage (AStorage: TWatchResultDataArrayStorageHelper; AnIndex: Integer); virtual;
    procedure ReadDataFromStorage(AStorage: TWatchResultDataArrayStorageHelper; AnIndex: Integer); virtual;
    procedure ClearData(AStorage: TWatchResultDataArrayStorageHelper); virtual;
  protected
    function GetValueKind: TWatchResultDataKind; virtual; //abstract;
    function GetAsString: String; virtual; abstract;
    function GetAsWideString: WideString; virtual; abstract;
    function GetAsQWord: QWord; virtual; abstract;
    function GetAsInt64: Int64; virtual; abstract;
    function GetAsFloat: Extended; virtual; abstract;

    function GetByteSize: Integer; virtual; abstract;
    function GetFloatPrecission: TLzDbgFloatPrecission; virtual; abstract;
    function GetCount: Integer; virtual; abstract;
    function GetElementName(AnIndex: integer): String; virtual; abstract;
    function GetDerefData: TWatchResultData; virtual; abstract;

    function GetSelectedEntry: TWatchResultData;  virtual; abstract;
  public
    class function CreateFromXMLConfig(const AConfig: TXMLConfig; const APath: string): TWatchResultData;
    procedure LoadDataFromXMLConfig(const AConfig: TXMLConfig; const APath: string); virtual;
    procedure SaveDataToXMLConfig(const AConfig: TXMLConfig; const APath: string); virtual;
    procedure Assign(ASource: TWatchResultData); virtual;
    function  CreateCopy: TWatchResultData;

    procedure SetTypeName(ATypeName: String);

    property ValueKind: TWatchResultDataKind read GetValueKind;
    property TypeName: String read FTypeName;

    property AsString: String read GetAsString;
    property AsWideString: WideString read GetAsWideString;
    property AsQWord: QWord read GetAsQWord;
    property AsInt64: Int64 read GetAsInt64;
    property AsFloat: Extended read GetAsFloat;

    property ByteSize: Integer read GetByteSize;
    property FloatPrecission: TLzDbgFloatPrecission read GetFloatPrecission;
    property DerefData: TWatchResultData read GetDerefData;

    // Array
    property Count: Integer read GetCount;
    procedure SetSelectedIndex(AnIndex: Integer); virtual;
    property SelectedEntry: TWatchResultData read GetSelectedEntry;
  end;

  TWatchResultDataClass = class of TWatchResultData;

  { TGenericWatchResultData }

  generic TGenericWatchResultData<_DATA> = class(TWatchResultData)
  private
    FData: _DATA;
  protected type

    { TDataArrayStorageHelper }

    TDataArrayStorageHelper = class(specialize TGenericWatchResultDataArrayStorageHelper<_DATA>)
    public
      procedure ClearData(AData: TWatchResultData); override;
      procedure SaveToIndex(AnIndex: Integer; AData: TWatchResultData); override;
      procedure LoadFromIndex(AnIndex: Integer; AData: TWatchResultData); override;
    end;

    { TDataArrayNestedStorageHelper }

    TDataArrayNestedStorageHelper = class(TDataArrayStorageHelper)
    private
      FNestedStorage: TWatchResultDataArrayStorageHelper;
    protected
      procedure SetCount(AValue: integer); override;
      function  GetNestedStorage: TWatchResultDataArrayStorageHelper; override;
      procedure SetNestedStorage(AValue: TWatchResultDataArrayStorageHelper); override;
      procedure Assign(ASource: TWatchResultDataArrayStorageHelper); override;
    public
      destructor Destroy; override;
    end;

  protected
    function GetArrayStorageHelperClass: TWatchResultDataArrayStorageHelperClass; override;
    function CreateArrayStorageHelper: TWatchResultDataArrayStorageHelper; override;
  protected
    function GetValueKind: TWatchResultDataKind; override;
    function GetAsString: String; override;
    function GetAsWideString: WideString; override;
    function GetAsQWord: QWord; override;
    function GetAsInt64: Int64; override;
    function GetAsFloat: Extended; override;
    function GetCount: Integer; override;
    function GetElementName(AnIndex: integer): String; override;
    function GetDerefData: TWatchResultData; override;

    function GetByteSize: Integer; override;
    function GetFloatPrecission: TLzDbgFloatPrecission; override;
    function GetSelectedEntry: TWatchResultData; override;
  public
    destructor Destroy; override;
    procedure LoadDataFromXMLConfig(const AConfig: TXMLConfig; const APath: string); override;
    procedure SaveDataToXMLConfig(const AConfig: TXMLConfig; const APath: string); override;
    procedure Assign(ASource: TWatchResultData); override;
  end;

  { TGenericWatchResultDataWithType }

  generic TGenericWatchResultDataWithType<_DATA, _TYPE> = class(specialize TGenericWatchResultData<_DATA>)
  private
    FType: _TYPE;
  protected
    function GetByteSize: Integer; override;
    function GetFloatPrecission: TLzDbgFloatPrecission; override;
    function GetSelectedEntry: TWatchResultData; override;
  public
    destructor Destroy; override;
    procedure LoadDataFromXMLConfig(const AConfig: TXMLConfig; const APath: string); override;
    procedure SaveDataToXMLConfig(const AConfig: TXMLConfig; const APath: string); override;
    procedure Assign(ASource: TWatchResultData); override;
  end;

  { TWatchResultDataPrePrinted }

  TWatchResultDataPrePrinted = class(specialize TGenericWatchResultData<TWatchResultValuePrePrinted>)
  private
    function GetClassID: TWatchResultDataClassID; override;
  public
    constructor Create(APrintedVal: String);
  end;

  { TWatchResultDataString }

  TWatchResultDataString = class(specialize TGenericWatchResultData<TWatchResultValueString>)
  private
    function GetClassID: TWatchResultDataClassID; override;
  public
    constructor Create(AStringVal: String);
  end;

  { TWatchResultDataWideString }

  TWatchResultDataWideString = class(specialize TGenericWatchResultData<TWatchResultValueWideString>)
  private
    function GetClassID: TWatchResultDataClassID; override;
  public
    constructor Create(AStringVal: WideString);
  end;

  { TWatchResultDataSignedNum }

  TWatchResultDataSignedNum = class(specialize TGenericWatchResultDataWithType<TWatchResultValueSignedNum, TWatchResultTypeOrdNum>)
  private
    function GetClassID: TWatchResultDataClassID; override;
  public
    constructor Create(ANumValue: Int64; AByteSize: Integer = 0);
  end;

  { TWatchResultDataUnSignedNum }

  TWatchResultDataUnSignedNum = class(specialize TGenericWatchResultDataWithType<TWatchResultValueUnsignedNum, TWatchResultTypeOrdNum>)
  private
    function GetClassID: TWatchResultDataClassID; override;
  public
    constructor Create(ANumValue: QWord; AByteSize: Integer = 0);
  end;

  { TWatchResultDataPointer }

  TWatchResultDataPointer = class(specialize TGenericWatchResultDataWithType<TWatchResultValuePointer, TWatchResultTypePointer>)
  private
    function GetClassID: TWatchResultDataClassID; override;
  protected
    function GetAsString: String; override;
    function GetDerefData: TWatchResultData; override;
    function GetArrayStorageHelperClass: TWatchResultDataArrayStorageHelperClass; override;
    function CreateArrayStorageHelper: TWatchResultDataArrayStorageHelper; override;
    procedure WriteDataToStorage(AStorage: TWatchResultDataArrayStorageHelper; AnIndex: Integer); override;
    procedure ReadDataFromStorage(AStorage: TWatchResultDataArrayStorageHelper; AnIndex: Integer); override;
    procedure ClearData(AStorage: TWatchResultDataArrayStorageHelper); override;
  public
    procedure SetDerefData(ADerefData: TWatchResultData);
  public
    constructor Create(AnAddr: TDBGPtr);
  end;

  { TWatchResultDataFloat }

  TWatchResultDataFloat = class(specialize TGenericWatchResultDataWithType<TWatchResultValueFloat, TWatchResultTypeFloat>)
  private
    function GetClassID: TWatchResultDataClassID; override;
  public
    constructor Create(AFloatValue: Extended; APrecission: TLzDbgFloatPrecission);
  end;

  { TWatchResultDataEnum }

  TWatchResultDataEnum = class(specialize TGenericWatchResultDataWithType<TWatchResultValueEnum, TWatchResultTypeOrdNum>)
  private
    function GetClassID: TWatchResultDataClassID; override;
  public
    constructor Create(ANumValue: QWord; AName: String; AByteSize: Integer = 0);
  end;

  { TWatchResultDataSet }

  TWatchResultDataSet = class(specialize TGenericWatchResultData<TWatchResultValueSet>)
  private
    function GetClassID: TWatchResultDataClassID; override;
  public
    constructor Create(const ANames: TStringDynArray);
  end;

  { TWatchResultDataArrayBase }

  generic TWatchResultDataArrayBase<_DATA, _TYPE> = class(specialize TGenericWatchResultDataWithType<_DATA, _TYPE>)
  public
    procedure SetEntryPrototype(AnEntry: TWatchResultData);
    procedure WriteEntryToStorage(AnIndex: Integer);
    procedure WriteValueToStorage(AnIndex: Integer; AValue: TWatchResultData);
    procedure SetEntryCount(ACount: Integer);
  public
    destructor Destroy; override;
    procedure Assign(ASource: TWatchResultData); override;
    procedure SetSelectedIndex(AnIndex: Integer); override; // ReadEntryFromStorage
  end;

  TWatchResultDataPCharOrString = class(specialize TWatchResultDataArrayBase<TWatchResultValuePCharOrString, TWatchResultTypeArrayBase>)
  end;

  TWatchResultDataArray = class(specialize TWatchResultDataArrayBase<TWatchResultValueArray, TWatchResultTypeArrayBase>)
  // ReadDataFromStorage should also procedure SetSelectedIndex(0) ???
  end;

(*
// DynArray
    //////property Length: Integere read FLength;
    //property High: Integere read FHigh;
    //FirstIdx
    //CountIdx

// Stat array
    //property Low: Integere read FLow;  // constant 0
    //property High: Integere read FHigh;
    //FirstIdx
    //CountIdx
*)

  { TWatchResultDataError }

  TWatchResultDataError = class(specialize TGenericWatchResultData<TWatchResultValueError>)
  private
    function GetClassID: TWatchResultDataClassID; override;
  public
    constructor Create(APrintedVal: String);
  end;

function PrintWatchValue(AResValue: TWatchResultData; ADispFormat: TWatchDisplayFormat): String;

implementation

function PrintWatchValueEx(AResValue: TWatchResultData; ADispFormat: TWatchDisplayFormat; ANestLvl: Integer): String;
const
  MAX_ALLOWED_NEST_LVL = 100;

  function PrintNumber(ANumValue: TWatchResultData; AnIsPointer: Boolean; ADispFormat: TWatchDisplayFormat): String;
  var
    num: QWord;
    n, i, j: Integer;
  begin
    case ADispFormat of
      //wdfString: // get pchar(num)^ ?
      wdfChar: begin
        num := ANumValue.AsQWord;
        Result := '';
        while num <> 0 do begin
          Result := chr(num and $ff) + Result;
          num := num >> 8;
        end;
        if Result <> '' then begin
          i := 1;
          while i <= length(Result) do begin
            j := UTF8CodepointStrictSize(@Result[i]);
            if j = 0 then begin
              Result := copy(Result, 1, i-1) + '''#$'+ IntToHex(byte(Result[i]), 2) + '''' + copy(Result, i + 6, 99);
              inc(i, 6);
            end
            else
              inc(i, j);
          end;
          Result := '''' + Result + '''';
        end
        else
          Result := '#$00';
      end;
      wdfUnsigned: begin
        Result := IntToStr(ANumValue.AsQWord)
      end;
      wdfHex: begin
        n := HexDigicCount(ANumValue.AsQWord, ANumValue.ByteSize, AnIsPointer);
        Result := '$'+IntToHex(ANumValue.AsQWord, n);
      end;
      wdfBinary: begin
        n := HexDigicCount(ANumValue.AsQWord, ANumValue.ByteSize, AnIsPointer);
        Result := '%'+IntToBin(ANumValue.AsInt64, n*4);
      end;
      wdfPointer: begin
        n := HexDigicCount(ANumValue.AsQWord, ANumValue.ByteSize, True);
        Result := '$'+IntToHex(ANumValue.AsQWord, n);
      end;
      else begin // wdfDecimal
        Result := IntToStr(ANumValue.AsInt64);
      end;
    end;
  end;

  function PrintEnum: String;
  begin
    case ADispFormat of
      wdfStructure:
        Result := AResValue.AsString + ' (' +  PrintNumber(AResValue, False, wdfDecimal) + ')';
      wdfUnsigned,
      wdfDecimal,
      wdfHex,
      wdfBinary:
        Result := PrintNumber(AResValue, False, ADispFormat);
      else
        Result := AResValue.AsString;
    end;
  end;

  function PrintSet: String;
  var
    i: Integer;
  begin
    Result := '';
    for i := 0 to AResValue.GetCount - 1 do
      Result := Result + ',' + AResValue.GetElementName(i);
    if Result = '' then
      Result := '[]'
    else begin
      Result[1] := '[';
      Result := Result + ']'
    end;
  end;

var
  PointerValue: TWatchResultDataPointer absolute AResValue;
  ResTypeName: String;
  PtrDeref: TWatchResultData;
  i: Integer;
begin
  inc(ANestLvl);
  if ANestLvl > MAX_ALLOWED_NEST_LVL then
    exit('...');

  Result := '';
  case AResValue.ValueKind of
    rdkError:
      Result := 'Error: ' + AResValue.AsString;
    rdkUnknown:
      Result := 'Error: Unknown';
    rdkPrePrinted: begin
      Result := AResValue.AsString;
    end;
    rdkSignedNumVal,
    rdkUnsignedNumVal: begin
      if (ADispFormat = wdfPointer) and (AResValue.AsQWord = 0) then begin
        Result := 'nil';
      end
      else begin
        if (AResValue.ValueKind = rdkUnsignedNumVal) and (ADispFormat = wdfDecimal) then
          ADispFormat := wdfUnsigned
        else
        if not (ADispFormat in [wdfDecimal, wdfUnsigned, wdfHex, wdfBinary, wdfPointer]) then begin
          //wdfDefault, wdfStructure, wdfChar, wdfString, wdfFloat
          if AResValue.ValueKind = rdkUnsignedNumVal then
            ADispFormat := wdfUnsigned
          else
            ADispFormat := wdfDecimal;
        end;

        Result := PrintNumber(AResValue, False, ADispFormat);
      end;
    end;
    rdkPointerVal: begin
      ResTypeName := '';
      if (ADispFormat = wdfStructure) or
         ((ADispFormat = wdfDefault) and (PointerValue.DerefData = nil))
      then
        ResTypeName := AResValue.TypeName;

      if (ADispFormat in [wdfDefault, wdfStructure, wdfPointer]) and (AResValue.AsQWord = 0)
      then begin
        Result := 'nil';
      end
      else begin
        if not (ADispFormat in [wdfDecimal, wdfUnsigned, wdfHex, wdfBinary, wdfPointer]) then
          //wdfDefault, wdfStructure, wdfChar, wdfString, wdfFloat
          ADispFormat := wdfPointer;

        Result := PrintNumber(AResValue, True, ADispFormat);
      end;

      if ResTypeName <> '' then
        Result := ResTypeName + '(' + Result + ')';

      PtrDeref :=  PointerValue.DerefData;
      if PtrDeref <> nil then begin
        while (PtrDeref.ValueKind = rdkPointerVal) and (PtrDeref.DerefData <> nil) do begin
          Result := Result + '^';
          PtrDeref :=  PtrDeref.DerefData;
        end;
        Result := Result + '^: ' + PrintWatchValueEx(PointerValue.DerefData, wdfDefault, ANestLvl);
      end;
    end;
    rdkFloatVal: begin
      case AResValue.FloatPrecission of
        dfpSingle:   Result := FloatToStrF(AResValue.AsFloat, ffGeneral,  8, 0);
        dfpDouble:   Result := FloatToStrF(AResValue.AsFloat, ffGeneral, 12, 0);
        dfpExtended: Result := FloatToStrF(AResValue.AsFloat, ffGeneral, 15, 0);
      end;
    end;
    rdkString:     Result := QuoteText(AResValue.AsString);
    rdkWideString: Result := QuoteWideText(AResValue.AsWideString);
    rdkEnum:       Result := PrintEnum;
    rdkSet:        Result := PrintSet;
    rdkPCharOrString: begin
      AResValue.SetSelectedIndex(0); // pchar res
      Result := 'PChar: ' + PrintWatchValueEx(AResValue.SelectedEntry, ADispFormat, ANestLvl);
      AResValue.SetSelectedIndex(1); // string res
      Result := Result + LineEnding
              + 'String: ' + PrintWatchValueEx(AResValue.SelectedEntry, ADispFormat, ANestLvl);
    end;
    rdkArray: begin
      Result := '';
      for i := 0 to AResValue.Count - 1 do begin
        if Result <> '' then
          Result := Result +', ';
        AResValue.SetSelectedIndex(i);
        Result := Result + PrintWatchValueEx(AResValue.SelectedEntry, ADispFormat, ANestLvl);
      end;
      Result := '(' + Result +')';
    end;
  end;
end;

function PrintWatchValue(AResValue: TWatchResultData; ADispFormat: TWatchDisplayFormat): String;
begin
  Result := PrintWatchValueEx(AResValue, ADispFormat, -1);
end;

const
  WatchResNameToClass: array [TWatchResultDataClassID] of TWatchResultDataClass = (
    TWatchResultDataPrePrinted,    // wdPrePrint
    TWatchResultDataString,        // wdString
    TWatchResultDataWideString,    // wdWString
    TWatchResultDataSignedNum,     // wdSNum
    TWatchResultDataUnSignedNum,   // wdUNum
    TWatchResultDataPointer,       // wdPtr
    TWatchResultDataFloat,         // wdFloat
    TWatchResultDataEnum,          // wdEnum
    TWatchResultDataSet,           // wdSet
    TWatchResultDataPCharOrString, // wdPChrStr
    TWatchResultDataError          // wdErr
  );

{ TWatchResultValue }

function TWatchResultValue.GetAsString: String;
begin
  Result := '';
end;

function TWatchResultValue.GetAsWideString: WideString;
begin
  Result := '';
end;

function TWatchResultValue.GetAsQWord: QWord;
begin
  Result := 0;
end;

function TWatchResultValue.GetAsInt64: Int64;
begin
  Result := 0;
end;

function TWatchResultValue.GetAsFloat: Extended;
begin
  Result := 0;
end;

function TWatchResultValue.GetByteSize: Integer;
begin
  Result := 0;
end;

function TWatchResultValue.GetFloatPrecission: TLzDbgFloatPrecission;
begin
  Result := dfpSingle;
end;

function TWatchResultValue.GetCount: Integer;
begin
  Result := 0;
end;

function TWatchResultValue.GetElementName(AnIndex: integer): String;
begin
  Result := '';
end;

function TWatchResultValue.GetDerefData: TWatchResultData;
begin
  Result := nil;
end;

function TWatchResultValue.GetSelectedEntry: TWatchResultData;
begin
  Result := nil;
end;

procedure TWatchResultValue.AfterAssign;
begin
  //
end;

procedure TWatchResultValue.DoFree;
begin
  //
end;

procedure TWatchResultValue.LoadDataFromXMLConfig(
  const AConfig: TXMLConfig; const APath: string);
begin
  //
end;

procedure TWatchResultValue.SaveDataToXMLConfig(const AConfig: TXMLConfig;
  const APath: string);
begin
  //
end;

{ TWatchResultValueTextBase }

procedure TWatchResultValueTextBase.LoadDataFromXMLConfig(
  const AConfig: TXMLConfig; const APath: string);
begin
  inherited LoadDataFromXMLConfig(AConfig, APath);
  FText := AConfig.GetValue(APath + 'Value', '');
end;

procedure TWatchResultValueTextBase.SaveDataToXMLConfig(
  const AConfig: TXMLConfig; const APath: string);
begin
  inherited SaveDataToXMLConfig(AConfig, APath);
  AConfig.SetValue(APath + 'Value', FText);
end;

{ TWatchResultValueWideString }

function TWatchResultValueWideString.GetAsString: String;
begin
  Result := FWideText;
end;

procedure TWatchResultValueWideString.LoadDataFromXMLConfig(
  const AConfig: TXMLConfig; const APath: string);
begin
  inherited LoadDataFromXMLConfig(AConfig, APath);
  FWideText := AConfig.GetValue(APath + 'Value', '');
end;

procedure TWatchResultValueWideString.SaveDataToXMLConfig(
  const AConfig: TXMLConfig; const APath: string);
begin
  inherited SaveDataToXMLConfig(AConfig, APath);
  AConfig.SetValue(APath + 'Value', FWideText);
end;

{ TWatchResultValueOrdNumBase }

function TWatchResultValueOrdNumBase.GetAsInt64: Int64;
begin
  Result := Int64(FNumValue);
end;

procedure TWatchResultValueOrdNumBase.LoadDataFromXMLConfig(
  const AConfig: TXMLConfig; const APath: string);
begin
  inherited LoadDataFromXMLConfig(AConfig, APath);
  FNumValue := QWord(AConfig.GetValue(APath + 'Value', int64(0)));
end;

procedure TWatchResultValueOrdNumBase.SaveDataToXMLConfig(
  const AConfig: TXMLConfig; const APath: string);
begin
  inherited SaveDataToXMLConfig(AConfig, APath);
  AConfig.SetValue(APath + 'Value', Int64(FNumValue));
end;

{ TWatchResultTypeOrdNum }

procedure TWatchResultTypeOrdNum.LoadDataFromXMLConfig(
  const AConfig: TXMLConfig; const APath: string);
begin
  FNumByteSize := AConfig.GetValue(APath + 'Value', 0);
end;

procedure TWatchResultTypeOrdNum.SaveDataToXMLConfig(const AConfig: TXMLConfig;
  const APath: string);
begin
  inherited SaveDataToXMLConfig(AConfig, APath);
  AConfig.SetDeleteValue(APath + 'ByteSize', FNumByteSize, 0);
end;

{ TWatchResultValueSignedNum }

function TWatchResultValueSignedNum.GetAsString: String;
begin
  Result := IntToStr(Int64(FNumValue));
end;

{ TWatchResultValueUnsignedNum }

function TWatchResultValueUnsignedNum.GetAsString: String;
begin
  Result := IntToStr(QWord(FNumValue))
end;

{ TWatchResultValuePointer }

function TWatchResultValuePointer.GetAsString: String;
begin
  Result := '$'+IntToHex(QWord(FNumValue), HexDigicCount(FNumValue, 0, True));
end;

{ TWatchResultTypePointer }

function TWatchResultTypePointer.GetAsString: String;
begin
  if FDerefData = nil then
    Result := ''
  else
    Result := '^: ' + FDerefData.AsString;
end;

procedure TWatchResultTypePointer.AfterAssign;
begin
  FDerefData := FDerefData.CreateCopy;
end;

procedure TWatchResultTypePointer.DoFree;
begin
  FDerefData.Free;
end;

procedure TWatchResultTypePointer.LoadDataFromXMLConfig(
  const AConfig: TXMLConfig; const APath: string);
begin
  inherited LoadDataFromXMLConfig(AConfig, APath);
  if AConfig.HasPath(APath + 'Deref', False) then
    FDerefData := TWatchResultData.CreateFromXMLConfig(AConfig, APath + 'Deref/');
end;

procedure TWatchResultTypePointer.SaveDataToXMLConfig(
  const AConfig: TXMLConfig; const APath: string);
begin
  inherited SaveDataToXMLConfig(AConfig, APath);
  if FDerefData <> nil then
    FDerefData.SaveDataToXMLConfig(AConfig, APath + 'Deref/')
  else
    AConfig.DeletePath(APath + 'Deref');
end;

{ TWatchResultValueFloat }

function TWatchResultValueFloat.GetAsString: String;
begin
  Result := FloatToStr(FFloatValue);
end;

procedure TWatchResultValueFloat.LoadDataFromXMLConfig(
  const AConfig: TXMLConfig; const APath: string);
begin
  inherited LoadDataFromXMLConfig(AConfig, APath);
  FFloatValue := AConfig.GetExtendedValue(APath + 'Value', 0);
end;

procedure TWatchResultValueFloat.SaveDataToXMLConfig(const AConfig: TXMLConfig;
  const APath: string);
begin
  inherited SaveDataToXMLConfig(AConfig, APath);
  AConfig.SetExtendedValue(APath + 'Value', FFloatValue);
end;

{ TWatchResultTypeFloat }

function TWatchResultTypeFloat.GetAsString: String;
begin
  WriteStr(Result, FFloatPrecission);
end;

procedure TWatchResultTypeFloat.LoadDataFromXMLConfig(
  const AConfig: TXMLConfig; const APath: string);
begin
  inherited LoadDataFromXMLConfig(AConfig, APath);
  AConfig.GetValue(APath + 'Prec', int64(ord(dfpSingle)), FFloatPrecission, TypeInfo(TLzDbgFloatPrecission));
end;

procedure TWatchResultTypeFloat.SaveDataToXMLConfig(const AConfig: TXMLConfig;
  const APath: string);
begin
  inherited SaveDataToXMLConfig(AConfig, APath);
  AConfig.SetDeleteValue(APath + 'Prec', FFloatPrecission, ord(dfpSingle), TypeInfo(TLzDbgFloatPrecission));
end;

{ TWatchResultValueEnum }

procedure TWatchResultValueEnum.LoadDataFromXMLConfig(
  const AConfig: TXMLConfig; const APath: string);
begin
  inherited LoadDataFromXMLConfig(AConfig, APath);
  FName := AConfig.GetValue(APath + 'Enum', '');
end;

procedure TWatchResultValueEnum.SaveDataToXMLConfig(const AConfig: TXMLConfig;
  const APath: string);
begin
  inherited SaveDataToXMLConfig(AConfig, APath);
  AConfig.SetDeleteValue(APath + 'Enum', FName, '');
end;


{ TWatchResultValueSet }

function TWatchResultValueSet.GetCount: Integer;
begin
  Result := Length(FNames);
end;

function TWatchResultValueSet.GetElementName(AnIndex: integer): String;
begin
  Result := FNames[AnIndex];
end;

procedure TWatchResultValueSet.LoadDataFromXMLConfig(const AConfig: TXMLConfig;
  const APath: string);
begin
  inherited LoadDataFromXMLConfig(AConfig, APath);
  FNames := AConfig.GetValue(APath + 'Set', '').Split([',']);
end;

procedure TWatchResultValueSet.SaveDataToXMLConfig(const AConfig: TXMLConfig;
  const APath: string);
begin
  inherited SaveDataToXMLConfig(AConfig, APath);
  AConfig.SetDeleteValue(APath + 'Set', ''.Join(',', FNames), '');
end;

{ TWatchResultValueArrayBase }

function TWatchResultValueArrayBase.GetCount: Integer;
begin
  if FEntries = nil then
    exit(0);
  Result := FEntries.Count;
end;

procedure TWatchResultValueArrayBase.AfterAssign;
begin
  FEntries := FEntries.CreateCopy;
end;

procedure TWatchResultValueArrayBase.DoFree;
begin
  FEntries.Free;
end;

{ TWatchResultTypeArrayBase }

procedure TWatchResultTypeArrayBase.AfterAssign;
begin
  FEntryWithType := FEntryWithType.CreateCopy;
end;

procedure TWatchResultTypeArrayBase.DoFree;
begin
  FEntryWithType.Free;
end;

{ TWatchResultDataArrayStorageHelper }

procedure TWatchResultDataArrayStorageHelper.SetNestedStorage(
  AValue: TWatchResultDataArrayStorageHelper);
begin
  assert(False, 'TWatchResultDataArrayStorageHelper.SetNestedStorage: False');
end;

function TWatchResultDataArrayStorageHelper.GetNestedStorage: TWatchResultDataArrayStorageHelper;
begin
  Result := nil;
end;

function TWatchResultDataArrayStorageHelper.CreateCopy: TWatchResultDataArrayStorageHelper;
begin
  if Self = nil then
    exit(nil);
  Result := TWatchResultDataArrayStorageHelper(ClassType.Create);
  Result.Assign(Self);
end;

{ TGenericWatchResultDataArrayStorageHelper }

function TGenericWatchResultDataArrayStorageHelper.GetCount: integer;
begin
  Result := Length(FDataArray);
end;

procedure TGenericWatchResultDataArrayStorageHelper.SetCount(AValue: integer);
var
  i: SizeInt;
begin
  for i := AValue to Length(FDataArray) - 1 do
    FDataArray[i].DoFree;
  SetLength(FDataArray, AValue);
end;

procedure TGenericWatchResultDataArrayStorageHelper.Assign(
  ASource: TWatchResultDataArrayStorageHelper);
var
  Src: TGenericWatchResultDataArrayStorageHelper absolute ASource;
  i: Integer;
begin
  assert(ASource.ClassType = ClassType, 'TGenericWatchResultDataArrayStorageHelper.Assign: ASource.ClassType = ClassType');
  if not (ASource is TGenericWatchResultDataArrayStorageHelper) then
    exit;

  FDataArray := Src.FDataArray;
  // TODO: refcounted
  if @_DATA.AfterAssign <> @TWatchResultValue.AfterAssign then begin
    SetLength(FDataArray, Length(FDataArray));
    for i := 0 to Length(FDataArray) - 1 do
      FDataArray[i].AfterAssign;
  end;
end;

destructor TGenericWatchResultDataArrayStorageHelper.Destroy;
begin
  Count := 0;
  inherited Destroy;
end;

{ TWatchResultData }

function TWatchResultData.GetValueKind: TWatchResultDataKind;
begin
  Result := rdkUnknown;
end;

function TWatchResultData.GetClassID: TWatchResultDataClassID;
begin
  Result := wdPrePrint;
end;

procedure TWatchResultData.WriteDataToStorage(
  AStorage: TWatchResultDataArrayStorageHelper; AnIndex: Integer);
begin
  assert(AStorage.ClassType = GetArrayStorageHelperClass, 'TWatchResultData.WriteDataToStorage: AStorage.ClassType = GetArrayStorageHelperClass');
  AStorage.SaveToIndex(AnIndex, Self);
  AStorage.ClearData(Self);
end;

procedure TWatchResultData.ReadDataFromStorage(
  AStorage: TWatchResultDataArrayStorageHelper; AnIndex: Integer);
begin
  assert(AStorage.ClassType = GetArrayStorageHelperClass, 'TWatchResultData.ReadDataFromStorage: AStorage.ClassType = GetArrayStorageHelperClass');
  AStorage.LoadFromIndex(AnIndex, Self);
end;

procedure TWatchResultData.ClearData(
  AStorage: TWatchResultDataArrayStorageHelper);
begin
  if (AStorage <> nil) and (AStorage.Count > 0) then
    AStorage.ClearData(Self);
end;

class function TWatchResultData.CreateFromXMLConfig(const AConfig: TXMLConfig;
  const APath: string): TWatchResultData;
var
  AnId: TWatchResultDataClassID;
begin
  Result := nil;
  try
    AConfig.GetValue(APath + 'CID', Int64(ord(wdPrePrint)), AnId, TypeInfo(TWatchResultDataClassID));
    Result := WatchResNameToClass[AnId].Create;
    Result.LoadDataFromXMLConfig(AConfig, APath);
  except
    Result := TWatchResultDataError.Create('Error: Failed to load from XML'); // TODO: create a class, that will not overwrite the broken xml
  end;
end;

procedure TWatchResultData.LoadDataFromXMLConfig(const AConfig: TXMLConfig;
  const APath: string);
begin
  FTypeName := AConfig.GetValue(APath + 'TypeName', '');
end;

procedure TWatchResultData.SaveDataToXMLConfig(const AConfig: TXMLConfig;
  const APath: string);
begin
  AConfig.SetDeleteValue(APath + 'CID', GetClassID, int64(ord(wdPrePrint)), TypeInfo(TWatchResultDataClassID));
  AConfig.SetDeleteValue(APath + 'TypeName', FTypeName, '');
end;

procedure TWatchResultData.Assign(ASource: TWatchResultData);
begin
  FTypeName := ASource.FTypeName;
end;

function TWatchResultData.CreateCopy: TWatchResultData;
begin
  if Self = nil then
    exit(nil);
  Result := TWatchResultData(ClassType.Create);
  Result.Assign(Self);
end;

procedure TWatchResultData.SetTypeName(ATypeName: String);
begin
  FTypeName := ATypeName;
end;

procedure TWatchResultData.SetSelectedIndex(AnIndex: Integer);
begin
  //
end;

{ TGenericWatchResultData.TDataArrayStorageHelper }

procedure TGenericWatchResultData.TDataArrayStorageHelper.ClearData(
  AData: TWatchResultData);
begin
  if AData <> nil then
    TGenericWatchResultData(AData).FData := Default(_DATA);
end;

procedure TGenericWatchResultData.TDataArrayStorageHelper.SaveToIndex(
  AnIndex: Integer; AData: TWatchResultData);
begin
  FDataArray[AnIndex] := TGenericWatchResultData(AData).FData
end;

procedure TGenericWatchResultData.TDataArrayStorageHelper.LoadFromIndex(
  AnIndex: Integer; AData: TWatchResultData);
begin
  TGenericWatchResultData(AData).FData := FDataArray[AnIndex];
end;

{ TGenericWatchResultData.TDataArrayNestedStorageHelper }

procedure TGenericWatchResultData.TDataArrayNestedStorageHelper.SetCount(
  AValue: integer);
begin
  inherited SetCount(AValue);
  if FNestedStorage <> nil then
    FNestedStorage.Count := AValue;
end;

function TGenericWatchResultData.TDataArrayNestedStorageHelper.GetNestedStorage: TWatchResultDataArrayStorageHelper;
begin
  Result := FNestedStorage;
end;

procedure TGenericWatchResultData.TDataArrayNestedStorageHelper.SetNestedStorage
  (AValue: TWatchResultDataArrayStorageHelper);
begin
  FNestedStorage := AValue;
  if FNestedStorage <> nil then
    FNestedStorage.Count := Count;
end;

procedure TGenericWatchResultData.TDataArrayNestedStorageHelper.Assign(
  ASource: TWatchResultDataArrayStorageHelper);
begin
  inherited Assign(ASource);
  FNestedStorage := ASource.NestedStorage.CreateCopy;
  if NestedStorage <> nil then
    NestedStorage.Assign(ASource.NestedStorage);
end;

destructor TGenericWatchResultData.TDataArrayNestedStorageHelper.Destroy;
begin
  FNestedStorage.Free;
  inherited Destroy;
end;

{ TGenericWatchResultData }

function TGenericWatchResultData.GetArrayStorageHelperClass: TWatchResultDataArrayStorageHelperClass;
begin
  Result := TDataArrayStorageHelper;
end;

function TGenericWatchResultData.CreateArrayStorageHelper: TWatchResultDataArrayStorageHelper;
begin
  Result := GetArrayStorageHelperClass.Create;
end;

function TGenericWatchResultData.GetValueKind: TWatchResultDataKind;
begin
  Result := FData.VKind;
end;

function TGenericWatchResultData.GetAsString: String;
begin
  Result := FData.GetAsString;
end;

function TGenericWatchResultData.GetAsWideString: WideString;
begin
  Result := FData.GetAsWideString;
end;

function TGenericWatchResultData.GetAsQWord: QWord;
begin
  Result := FData.GetAsQWord;
end;

function TGenericWatchResultData.GetAsInt64: Int64;
begin
  Result := FData.GetAsInt64;
end;

function TGenericWatchResultData.GetAsFloat: Extended;
begin
  Result := FData.GetAsFloat;
end;

function TGenericWatchResultData.GetCount: Integer;
begin
  Result := FData.GetCount;
end;

function TGenericWatchResultData.GetElementName(AnIndex: integer): String;
begin
  Result := FData.GetElementName(AnIndex);
end;

function TGenericWatchResultData.GetDerefData: TWatchResultData;
begin
  Result := FData.GetDerefData;
end;

function TGenericWatchResultData.GetByteSize: Integer;
begin
  Result := FData.GetByteSize;
end;

function TGenericWatchResultData.GetFloatPrecission: TLzDbgFloatPrecission;
begin
  Result := FData.GetFloatPrecission;
end;

function TGenericWatchResultData.GetSelectedEntry: TWatchResultData;
begin
  Result := FData.GetSelectedEntry;
end;

destructor TGenericWatchResultData.Destroy;
begin
  FData.DoFree;
  inherited Destroy;
end;

procedure TGenericWatchResultData.LoadDataFromXMLConfig(
  const AConfig: TXMLConfig; const APath: string);
begin
  inherited LoadDataFromXMLConfig(AConfig, APath);
  FData.LoadDataFromXMLConfig(AConfig, APath);
end;

procedure TGenericWatchResultData.SaveDataToXMLConfig(
  const AConfig: TXMLConfig; const APath: string);
begin
  inherited SaveDataToXMLConfig(AConfig, APath);
  FData.SaveDataToXMLConfig(AConfig, APath);
end;

procedure TGenericWatchResultData.Assign(ASource: TWatchResultData);
var
  Src: TGenericWatchResultData absolute ASource;
begin
  inherited Assign(ASource);
  if not (ASource is TGenericWatchResultData) then
    exit;
  FData := Src.FData;
  FData.AfterAssign;
end;

{ TGenericWatchResultDataWithType }

function TGenericWatchResultDataWithType.GetByteSize: Integer;
begin
  Result := FType.GetByteSize;
end;

function TGenericWatchResultDataWithType.GetFloatPrecission: TLzDbgFloatPrecission;
begin
  Result := FType.GetFloatPrecission;
end;

function TGenericWatchResultDataWithType.GetSelectedEntry: TWatchResultData;
begin
  Result := FType.GetSelectedEntry;
end;

destructor TGenericWatchResultDataWithType.Destroy;
begin
  FType.DoFree;
  inherited Destroy;
end;

procedure TGenericWatchResultDataWithType.LoadDataFromXMLConfig(
  const AConfig: TXMLConfig; const APath: string);
begin
  inherited LoadDataFromXMLConfig(AConfig, APath);
  FType.LoadDataFromXMLConfig(AConfig, APath);
end;

procedure TGenericWatchResultDataWithType.SaveDataToXMLConfig(
  const AConfig: TXMLConfig; const APath: string);
begin
  inherited SaveDataToXMLConfig(AConfig, APath);
  FType.SaveDataToXMLConfig(AConfig, APath);
end;

procedure TGenericWatchResultDataWithType.Assign(ASource: TWatchResultData);
var
  Src: TGenericWatchResultDataWithType absolute ASource;
begin
  inherited Assign(ASource);
  if not (ASource is TGenericWatchResultDataWithType) then
    exit;
  FType := Src.FType;
  FType.AfterAssign;
end;

{ TWatchResultDataPrePrinted }

function TWatchResultDataPrePrinted.GetClassID: TWatchResultDataClassID;
begin
  Result := wdPrePrint;
end;

constructor TWatchResultDataPrePrinted.Create(APrintedVal: String);
begin
  inherited Create;
  FData.FText := APrintedVal;
end;

{ TWatchResultDataString }

function TWatchResultDataString.GetClassID: TWatchResultDataClassID;
begin
  Result := wdString;
end;

constructor TWatchResultDataString.Create(AStringVal: String);
begin
  inherited Create;
  FData.FText := AStringVal;
end;

{ TWatchResultDataWideString }

function TWatchResultDataWideString.GetClassID: TWatchResultDataClassID;
begin
  Result := wdWString;
end;

constructor TWatchResultDataWideString.Create(AStringVal: WideString);
begin
  inherited Create;
  FData.FWideText := AStringVal;
end;

{ TWatchResultDataSignedNum }

function TWatchResultDataSignedNum.GetClassID: TWatchResultDataClassID;
begin
  Result := wdSNum;
end;

constructor TWatchResultDataSignedNum.Create(ANumValue: Int64;
  AByteSize: Integer);
begin
  inherited Create();
  FData.FNumValue := QWord(ANumValue);
  FType.FNumByteSize := AByteSize;
end;

{ TWatchResultDataUnSignedNum }

function TWatchResultDataUnSignedNum.GetClassID: TWatchResultDataClassID;
begin
  Result := wdUNum;
end;

constructor TWatchResultDataUnSignedNum.Create(ANumValue: QWord;
  AByteSize: Integer);
begin
  inherited Create();
  FData.FNumValue := QWord(ANumValue);
  FType.FNumByteSize := AByteSize;
end;

{ TWatchResultDataPointer }

function TWatchResultDataPointer.GetClassID: TWatchResultDataClassID;
begin
  Result := wdPtr;
end;

function TWatchResultDataPointer.GetAsString: String;
begin
  Result := FData.GetAsString + FType.GetAsString;
end;

function TWatchResultDataPointer.GetDerefData: TWatchResultData;
begin
  Result := FType.GetDerefData;
end;

function TWatchResultDataPointer.GetArrayStorageHelperClass: TWatchResultDataArrayStorageHelperClass;
begin
  Result := TDataArrayNestedStorageHelper;
end;

function TWatchResultDataPointer.CreateArrayStorageHelper: TWatchResultDataArrayStorageHelper;
begin
  Result := inherited CreateArrayStorageHelper;
  if FType.FDerefData <> nil then
    TDataArrayNestedStorageHelper(Result).FNestedStorage := FType.FDerefData.CreateArrayStorageHelper;
end;

procedure TWatchResultDataPointer.WriteDataToStorage(
  AStorage: TWatchResultDataArrayStorageHelper; AnIndex: Integer);
begin
  assert(AStorage is TDataArrayNestedStorageHelper, 'TWatchResultDataPointer.WriteDataToStorage: AStorage is TDataArrayNestedStorageHelper');
  inherited WriteDataToStorage(AStorage, AnIndex);

  if (FType.FDerefData <> nil) then begin
    if (AStorage.NestedStorage = nil) then
      AStorage.NestedStorage := FType.FDerefData.CreateArrayStorageHelper;

    FType.FDerefData.WriteDataToStorage(AStorage.NestedStorage, AnIndex);
  end;
end;

procedure TWatchResultDataPointer.ReadDataFromStorage(
  AStorage: TWatchResultDataArrayStorageHelper; AnIndex: Integer);
begin
  assert(AStorage is TDataArrayNestedStorageHelper, 'TWatchResultDataPointer.ReadDataFromStorage: AStorage is TDataArrayNestedStorageHelper');
  inherited ReadDataFromStorage(AStorage, AnIndex);

  if (FType.FDerefData <> nil) then begin
    if (AStorage.NestedStorage <> nil) then
      FType.FDerefData.ReadDataFromStorage(AStorage.NestedStorage, AnIndex);
// else ?? mark as "has no deref data"
  end;
end;

procedure TWatchResultDataPointer.ClearData(
  AStorage: TWatchResultDataArrayStorageHelper);
begin
  if AStorage = nil then
    exit;
  inherited ClearData(AStorage);
  if (FType.FDerefData <> nil) then
    FType.FDerefData.ClearData(AStorage.NestedStorage);
end;

procedure TWatchResultDataPointer.SetDerefData(ADerefData: TWatchResultData);
begin
  FType.FDerefData := ADerefData;
end;

constructor TWatchResultDataPointer.Create(AnAddr: TDBGPtr);
begin
  inherited Create();
  FData.FNumValue := QWord(AnAddr);
end;


{ TWatchResultDataFloat }

function TWatchResultDataFloat.GetClassID: TWatchResultDataClassID;
begin
  Result := wdFloat;
end;

constructor TWatchResultDataFloat.Create(AFloatValue: Extended;
  APrecission: TLzDbgFloatPrecission);
begin
  inherited Create;
  FData.FFloatValue := AFloatValue;
  FType.FFloatPrecission := APrecission;
end;

{ TWatchResultDataEnum }

function TWatchResultDataEnum.GetClassID: TWatchResultDataClassID;
begin
  Result := wdEnum;
end;

constructor TWatchResultDataEnum.Create(ANumValue: QWord; AName: String;
  AByteSize: Integer);
begin
  inherited Create;
  FData.FNumValue    := ANumValue;
  FData.FName        := AName;
  FType.FNumByteSize := AByteSize;
end;

{ TWatchResultDataSet }

function TWatchResultDataSet.GetClassID: TWatchResultDataClassID;
begin
  Result := wdSet;
end;

constructor TWatchResultDataSet.Create(const ANames: TStringDynArray);
begin
  inherited Create;
  FData.FNames := ANames;
end;

{ TWatchResultDataArrayBase }

procedure TWatchResultDataArrayBase.SetEntryPrototype(AnEntry: TWatchResultData
  );
begin
  assert((FType.FEntryWithType=nil) and (FData.FEntries= nil), 'TWatchResultDataArrayBase.SetEntryPrototype: (FType.FEntryWithType=nil) and (FData.FEntries= nil)');
  FType.FEntryWithType := AnEntry;
end;

procedure TWatchResultDataArrayBase.WriteEntryToStorage(AnIndex: Integer);
begin
  if FData.FEntries = nil then begin
    assert((AnIndex=0) and (FType.FEntryWithType<>nil), 'TWatchResultDataArrayBase.WriteEntryToStorage: (AnIndex=0) and (FType.FEntryWithType<>nil)');
    FData.FEntries := FType.FEntryWithType.CreateArrayStorageHelper;
// TODO: now count is zero, and below assert will fail
  end;

  assert(AnIndex<FData.FEntries.Count, 'TWatchResultDataArrayBase.WriteEntryToStorage: AnIndex<FData.FEntries.Count');
  FType.FEntryWithType.WriteDataToStorage(FData.FEntries, AnIndex);
end;

procedure TWatchResultDataArrayBase.WriteValueToStorage(AnIndex: Integer; AValue: TWatchResultData);
begin
  assert(AValue <> nil, 'TWatchResultDataArrayBase.WriteValueToStorage: AValue <> nil');
  if FData.FEntries = nil then begin
    assert(AnIndex=0, 'TWatchResultDataArrayBase.WriteValueToStorage: AnIndex=0');
    FData.FEntries := AValue.CreateArrayStorageHelper;
// TODO: now count is zero, and below assert will fail
  end;

  assert(AnIndex<FData.FEntries.Count, 'TWatchResultDataArrayBase.WriteValueToStorage: AnIndex<FData.FEntries.Count');
  AValue.WriteDataToStorage(FData.FEntries, AnIndex);
end;

procedure TWatchResultDataArrayBase.SetEntryCount(ACount: Integer);
begin
  assert(FType.FEntryWithType<>nil, 'TWatchResultDataArrayBase.SetEntryCount: FType.FEntryWithType<>nil');
  if FData.FEntries = nil then
    FData.FEntries := FType.FEntryWithType.CreateArrayStorageHelper;
  FData.FEntries.Count := ACount;
end;

destructor TWatchResultDataArrayBase.Destroy;
begin
  FType.FEntryWithType.ClearData(FData.FEntries);
  inherited Destroy;
end;

procedure TWatchResultDataArrayBase.Assign(ASource: TWatchResultData);
var
  Src: TWatchResultDataArrayBase absolute ASource;
begin
  if ASource is TWatchResultDataArrayBase then begin
    // Do not copy >> FType.FEntryWithType.FData <<, if the FData is stored in >> FData.FEntries
    Src.FType.FEntryWithType.ClearData(FData.FEntries);
  end;

  inherited Assign(ASource);

  //if ASource is TWatchResultDataArrayBase then
  //  Src.SetSelectedIndex(0);
end;

procedure TWatchResultDataArrayBase.SetSelectedIndex(AnIndex: Integer);
begin
  FType.FEntryWithType.ReadDataFromStorage(FData.FEntries, AnIndex);
end;

{ TWatchResultDataError }

function TWatchResultDataError.GetClassID: TWatchResultDataClassID;
begin
  Result := wdErr;
end;

constructor TWatchResultDataError.Create(APrintedVal: String);
begin
  inherited Create;
  FData.FText := APrintedVal;
end;

end.

