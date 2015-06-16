unit fpDbgSymTableContext;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  FpDbgLoader,
  FpImgReaderBase,
  DbgIntfBaseTypes,
  fpDbgSymTable,
  FpdMemoryTools,
  FpDbgInfo;

type

  TFpSymbolInfo = class;

  { TFpSymbolContext }

  TFpSymbolContext = class(TFpDbgInfoContext)
  private
    FFpSymbolInfo: TFpSymbolInfo;
    FSizeOfAddress: integer;
  protected
    function GetAddress: TDbgPtr; override;
    function GetStackFrame: Integer; override;
    function GetThreadId: Integer; override;
    function GetSizeOfAddress: Integer; override;
  public
    constructor Create(AFpSymbolInfo: TFpSymbolInfo);
    function FindSymbol(const AName: String): TFpDbgValue; override;
  end;

  { TFpSymbolInfo }

  TFpSymbolInfo = class(TDbgInfo)
  private
    FSymbolList: TfpSymbolList;
    FContext: TFpSymbolContext;
    FImage64Bit: boolean;
  public
    constructor Create(ALoaderList: TDbgImageLoaderList); override;
    destructor Destroy; override;
    function FindContext(AThreadId, AStackFrame: Integer; AAddress: TDbgPtr = 0): TFpDbgInfoContext; override;
    function FindContext(AAddress: TDbgPtr): TFpDbgInfoContext; override;
    function FindSymbol(AAddress: TDbgPtr): TFpDbgSymbol; override;
    function FindSymbol(const AName: String): TFpDbgSymbol; override;
    function GetLineAddress(const AFileName: String; ALine: Cardinal): TDbgPtr; override;
    property Image64Bit: boolean read FImage64Bit;
  end;

implementation

{ TFpSymbolContext }

function TFpSymbolContext.GetAddress: TDbgPtr;
begin
  result := 0;
end;

function TFpSymbolContext.GetStackFrame: Integer;
begin
  result := 0;
end;

function TFpSymbolContext.GetThreadId: Integer;
begin
  result := 1;
end;

function TFpSymbolContext.GetSizeOfAddress: Integer;
begin
  result := FSizeOfAddress;
end;

constructor TFpSymbolContext.Create(AFpSymbolInfo: TFpSymbolInfo);
begin
  inherited create;
  FFpSymbolInfo:=AFpSymbolInfo;
  if AFpSymbolInfo.Image64Bit then
    FSizeOfAddress:=8
  else
    FSizeOfAddress:=4;
end;

function TFpSymbolContext.FindSymbol(const AName: String): TFpDbgValue;
var
  i: integer;
  val: TFpDbgMemLocation;
begin
  i := FFpSymbolInfo.FSymbolList.IndexOf(AName);
  if i > -1 then
  begin
    val.Address:=TDbgPtr(pointer(FFpSymbolInfo.FSymbolList.Objects[i]));
    val.MType:=mlfTargetMem;
    result := TFpDbgValueConstAddress.Create(val);
  end
  else
    result := nil;
end;

{ TFpSymbolInfo }

constructor TFpSymbolInfo.Create(ALoaderList: TDbgImageLoaderList);

var
  i: Integer;
begin
  inherited Create(ALoaderList);
  FContext := TFpSymbolContext.Create(self);

  FSymbolList := TfpSymbolList.Create;
  for i := 0 to ALoaderList.Count-1 do
    ALoaderList[i].ParseSymbolTable(FSymbolList);
  FImage64Bit := ALoaderList.Image64Bit;
end;

destructor TFpSymbolInfo.Destroy;
begin
  FSymbolList.Free;
  FContext.Free;
  inherited Destroy;
end;

function TFpSymbolInfo.FindContext(AThreadId, AStackFrame: Integer;
  AAddress: TDbgPtr): TFpDbgInfoContext;
begin
  Result:=FContext;
end;

function TFpSymbolInfo.FindContext(AAddress: TDbgPtr): TFpDbgInfoContext;
begin
  Result:=FContext;
end;

function TFpSymbolInfo.FindSymbol(AAddress: TDbgPtr): TFpDbgSymbol;
begin
  Result:=inherited FindSymbol(AAddress);
end;

function TFpSymbolInfo.FindSymbol(const AName: String): TFpDbgSymbol;
begin
  result := nil;
  //Result:=FContext.FindSymbol(AName);
end;

function TFpSymbolInfo.GetLineAddress(const AFileName: String; ALine: Cardinal): TDbgPtr;
begin
  Result:=inherited GetLineAddress(AFileName, ALine);
end;

end.

