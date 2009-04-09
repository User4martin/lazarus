{
 /***************************************************************************
                                Printers.pas
                                ------------
                            Basic Printer object
                               
 ****************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

  Author: Olivier Guilbaud
}
unit Printers;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, Graphics;
type
  TPrinter = Class;
  EPrinter = class(Exception);

  TPrinterOrientation = (poPortrait,poLandscape,poReverseLandscape,poReversePortrait);
  TPrinterCapability  = (pcCopies, pcOrientation, pcCollation);
  TPrinterCapabilities= Set of TPrinterCapability;
  TPrinterState       = (psNoDefine,psReady,psPrinting,psStopped);
  TPrinterType        = (ptLocal,ptNetWork);

  {
   This object it's a base class for TCanvas for TPrinter Object.
   Few properties it's replicate for can create an TPrinterCavas not
   associated with TPrinter or override few values.
   
   BeginDoc,NewPage and EndDoc it's called in Printer.BeginDoc ...
  }
  TPrinterCanvas = class(TCanvas)
  private
    fPrinter      : TPrinter;
    fTitle        : String;
    fPageHeight   : Integer;
    fPageWidth    : Integer;
    fPageNum      : Integer;
    fTopMargin    : Integer;
    fLeftMargin   : Integer;
    fBottomMargin : Integer;
    fRightMargin  : Integer;
    
    function GetPageHeight: Integer;
    function GetPageWidth: Integer;
    function GetTitle: string;
    procedure SetPageHeight(const AValue: Integer);
    procedure SetPageWidth(const AValue: Integer);
    procedure SetTitle(const AValue: string);
  protected
    procedure BeginDoc; virtual;
    procedure NewPage;  virtual;
    procedure EndDoc; virtual;
    function GetLeftMargin: Integer;
    function GetTopMargin: Integer;
    function GetBottomMargin: Integer;
    function GetRightMargin: Integer;
  public
    constructor Create(APrinter: TPrinter); virtual;
    procedure Changing; override;

    property Printer : TPrinter read fPrinter;
    
    property Title : string read GetTitle write SetTitle;
    property PageHeight : Integer read GetPageHeight write SetPageHeight;
    property PageWidth  : Integer read GetPageWidth write SetPageWidth;
    property PageNumber : Integer read fPageNum;
    property TopMargin : Integer read GetTopMargin write FTopMargin;
    property LeftMargin: Integer read GetLeftMargin write FLeftMargin;
    property BottomMargin: Integer read GetBottomMargin write FBottomMargin;
    property RightMargin: Integer read GetRightMargin write FRightMargin;

  end;

  TPrinterCanvasRef = Class of TPrinterCanvas;
  
  TPaperRect = Record
    PhysicalRect : TRect;
    WorkRect     : TRect;
  end;

  { TPaperSize }

  TPaperSize = Class(TObject)
  private
    //The width and length are in points;
    //there are 72 points per inch.

    fOwnedPrinter      : TPrinter;
    fSupportedPapers   : TStringList;  //List of Paper supported by the current printer
    fLastPrinterIndex  : Integer;      //Last index of printer used

    function GetDefaultPaperName: string;
    function GetPhysPaperHeight: Integer;
    function GetPaperName: string;
    function GetPaperRect: TPaperRect;
    function GetPhysPaperWidth: Integer;
    function GetSupportedPapers: TStrings;
    procedure SetPaperName(const AName: string);
    function PaperRectOfName(const AName: string) : TPaperRect;
  protected
  public
    constructor Create(aOwner : TPrinter); overload;
    destructor Destroy; override;

    property Width           : Integer read GetPhysPaperWidth;
    property Height          : Integer read GetPhysPaperHeight;
    property PaperName       : string read GetPaperName write SetPaperName;
    property DefaultPaperName: string read GetDefaultPaperName;

    property PaperRect       : TPaperRect read GetPaperRect;
    property SupportedPapers : TStrings read GetSupportedPapers;

    property PaperRectOf[aName : string] : TPaperRect read PaperRectOfName;
  end;

  { TPrinter }

  TPrinter = class(TObject)
  private
    fCanvas      : TCanvas;      //Active canvas object
    fFonts       : TStrings;     //Accepted font by printer
    fPageNumber  : Integer;      //Current page number
    fPrinters    : TStrings;     //Printers names list
    fPrintersValid: Boolean;
    fPrinterIndex: Integer;      //selected printer index
    fTitle       : string;       //Title of current document
    fPrinting    : Boolean;      //Printing
    fAborted     : Boolean;      //Abort  process
    //fCapabilities: TPrinterCapabilities;
    fPaperSize   : TPaperSize;
    fRawMode     : Boolean;
    
    function GetCanvas: TCanvas;
    procedure CheckPrinting(Value: Boolean);
    function GetCopies: Integer;
    function GetFonts: TStrings;
    function GetOrientation: TPrinterOrientation;
    function GetPageHeight: Integer;
    function GetPageWidth: Integer;
    function GetPaperSize: TPaperSize;
    function GetPrinterIndex: integer;
    function GetPrinters: TStrings;
    procedure SetCopies(AValue: Integer);
    procedure SetOrientation(const AValue: TPrinterOrientation);
    procedure SetPrinterIndex(AValue: integer);
    procedure SetRawMode(const AValue: boolean);
  protected
     procedure SelectCurrentPrinterOrDefault;
     
     function GetCanvasRef : TPrinterCanvasRef; virtual;
     
     procedure DoBeginDoc; virtual;
     procedure DoNewPage; virtual;
     procedure DoEndDoc(aAborded : Boolean); virtual;
     procedure DoAbort; virtual;
     procedure DoResetPrintersList; virtual;
     procedure DoResetFontsList; virtual;
     
     procedure DoEnumPrinters(Lst : TStrings); virtual;
     procedure DoEnumFonts(Lst : TStrings); virtual;
     procedure DoEnumPapers(Lst : TStrings); virtual;
     procedure DoInitialization; virtual;
     function DoSetPrinter(aName : string): Integer; virtual;
     function DoGetCopies : Integer; virtual;
     procedure DoSetCopies(aValue : Integer); virtual;
     function DoGetOrientation: TPrinterOrientation; virtual;
     procedure DoSetOrientation(aValue : TPrinterOrientation); virtual;
     function DoGetDefaultPaperName: string; virtual;
     function DoGetPaperName: string; virtual;
     procedure DoSetPaperName(aName : string); virtual;
     function DoGetPaperRect(aName : string; Var aPaperRc : TPaperRect) : Integer; virtual;
     function DoGetPrinterState: TPrinterState; virtual;
     function GetPrinterType : TPrinterType; virtual;
     function GetCanPrint : Boolean; virtual;
     function GetCanRenderCopies : Boolean; virtual;
     function GetXDPI: Integer; virtual;
     function GetYDPI: Integer; virtual;
     procedure CheckRawMode(const Value: boolean; Msg:string='');
     procedure RawModeChanging; virtual;
     procedure PrinterSelected; virtual;
  public
     constructor Create; virtual;
     destructor Destroy; override;

     procedure Abort;
     procedure BeginDoc;
     procedure EndDoc;
     procedure NewPage;
     procedure Refresh;
     procedure SetPrinter(aName : String);
     function  Write(const Buffer; Count:Integer; var Written: Integer): Boolean; virtual;


     property PrinterIndex : integer read GetPrinterIndex write SetPrinterIndex;
     property PaperSize : TPaperSize read GetPaperSize;
     property Orientation: TPrinterOrientation read GetOrientation write SetOrientation;
     property PrinterState : TPrinterState read DoGetPrinterState;
     property Copies : Integer read GetCopies write SetCopies;
     property Printers: TStrings read GetPrinters;
     property Fonts: TStrings read GetFonts;
     property Canvas: TCanvas read GetCanvas;
     property PageHeight: Integer read GetPageHeight;
     property PageWidth: Integer read GetPageWidth;
     property PageNumber : Integer read fPageNumber;
     property Aborted: Boolean read fAborted;
     property Printing: Boolean read FPrinting;
     property Title: string read fTitle write fTitle;
     property PrinterType : TPrinterType read GetPrinterType;
     property CanPrint : Boolean read GetCanPrint;
     property CanRenderCopies : Boolean read GetCanRenderCopies;
     property XDPI : Integer read GetXDPI;
     property YDPI : Integer read GetYDPI;
     property RawMode: boolean read FRawMode write SetRawMode;
  end;
  
var
  Printer : TPrinter;
  
implementation

{ TPrinter }

constructor TPrinter.Create;
begin
  if ClassType=TPrinter then
    raise Exception.Create('TPrinter is an abstract base class.'
    +' Please use a printer implementation like the package printers4lazarus.');
  Inherited Create;
  fPrinterIndex:=-1;  //By default, use the default printer
  fCanvas:=nil;
  fPaperSize:=nil;
  fTitle:='';
end;

destructor TPrinter.Destroy;
begin
  if Printing then
    Abort;

 
  if Assigned(fCanvas) then
    fCanvas.Free;
    
  if Assigned(fPaperSize) then
     fPaperSize.Free;
     

  if Assigned(fPrinters) then
  begin
    DoResetPrintersList;
    FreeAndNil(fPrinters);
  end;

  if Assigned(fFonts) then
  begin
    DoResetFontsList;
    FreeAndNil(fFonts);
  end;
     

  inherited Destroy;
end;

//Abort the current document
procedure TPrinter.Abort;
begin
  //Check if Printer print otherwise, exception
  CheckPrinting(True);

  DoAbort;
  
  fAborted:=True;
  EndDoc;
end;

//Begin a new document
procedure TPrinter.BeginDoc;
begin
  //Check if Printer not printing otherwise, exception
  CheckPrinting(False);
  
  //If not selected printer, set default printer
  SelectCurrentPrinterOrDefault;
  
  fPrinting := True;
  fAborted := False;
  fPageNumber := 1;
  
  if not FRawMode then begin
    Canvas.Refresh;
    TPrinterCanvas(Canvas).BeginDoc;
  end;
  //Call the specifique Begindoc
  DoBeginDoc;
  
  // Set font resolution
  if not FRawMode then
    Canvas.Font.PixelsPerInch := YDPI;
end;

//End the current document
procedure TPrinter.EndDoc;
begin
  //Check if Printer print otherwise, exception
  CheckPrinting(True);

  if not FRawMode then
    TPrinterCanvas(Canvas).EndDoc;
  
  DoEndDoc(fAborted);

  fPrinting := False;
  fAborted := False;
  fPageNumber := 0;
end;

//Create an new page
procedure TPrinter.NewPage;
begin
  CheckPrinting(True);
  Inc(fPageNumber);
  if not RawMode then
    TPrinterCanvas(Canvas).NewPage;
  DoNewPage;
end;

//Clear Printers & Fonts list
procedure TPrinter.Refresh;
var
  OldPrinter: string;
begin
  //Check if Printer not printing otherwise, exception
  CheckPrinting(False);

  if FPrinterIndex>=0 then
    OldPrinter := fPrinters[FPrinterIndex]
  else
    OldPrinter := '';

  if Assigned(fPrinters) then
  begin
    DoResetPrintersList;
    FreeAndNil(fPrinters);
  end;
  
  if Assigned(fFonts) then
  begin
    DoResetFontsList;
    FreeAndNil(fFonts);
  end;

  // need to refill printers here otherwise
  // it wont be filled on getting printers
  // due to only one initialization
  GetPrinters;

  fPrinterIndex:=-1;

  // try to locate old selected printer
  if OldPrinter<>'' then
    SetPrinter(OldPrinter);
end;

//Set the current printer
procedure TPrinter.SetPrinter(aName: String);
var
  i,oldIndex : Integer;
begin
  if aName='*' then begin
    // select default printer
    OldIndex := FPrinterIndex;
    fPrinterIndex := -1; // avoid to remember last printer
    Refresh;
    if Printers.count>0 then begin
      i:= doSetprinter(FPrinters[0]); // now first printer is default
      if i<>0 then begin
        // something went wrong, try to restore old printer
        if OldIndex>=0 then
          FPrinterIndex := doSetPrinter(FPrinters[OldIndex]);
        raise EPrinter.Create('Unable to set default printer!');
      end else
        FPrinterIndex := i;
    end;
  end else
  if (Printers.Count>0) then
  begin
    if (aName<>'') then
    begin
      //Printer changed ?
      if fPrinters.IndexOf(aName)<>fPrinterIndex then
      begin
        i:=DoSetPrinter(aName);
        if i<0 then
          raise EPrinter.Create(Format('Printer "%s" does''t exists.',[aName]));
        fPrinterIndex:=i;
      end;
    end;
  end;
  PrinterSelected;
end;

function TPrinter.Write(const Buffer; Count:Integer; var Written: Integer): Boolean;
begin
  result := False;
end;

//Return an Canvas object
function TPrinter.GetCanvas: TCanvas;
begin
  Result := nil;
  
  CheckRawMode(False, 'Canvas not allowed in Raw Mode');
  
  if not Assigned(fCanvas) then
  begin
    if not Assigned(GetCanvasRef) then
      raise Exception.Create('TCanvas not defined.');

    fCanvas:=GetCanvasRef.Create(Self);
  end;
  
  Result:=fCanvas;
end;

//Raise error if Printer.Printing is not Value
procedure TPrinter.CheckPrinting(Value: Boolean);
begin
  if Printing<>Value then
  begin
    if Value then
      raise EPrinter.Create('Printer not printing')
    else
      raise Eprinter.Create('Printer print');
  end;
end;

procedure TPrinter.CheckRawMode(const Value:boolean; msg:string ='');
begin
  if FRawMode<>Value then
  begin
    if msg='' then
      if Value then
        Msg:='Printer is in Raw Mode'
      else
        Msg:='Printer is not in Raw Mode';
    raise EPrinter.Create(msg);
  end;
end;

procedure TPrinter.RawModeChanging;
begin
  //
end;

procedure TPrinter.PrinterSelected;
begin
end;

//Get current copies number
function TPrinter.GetCopies: Integer;
Var i : Integer;
begin
  Result:=1;
  i:=DoGetCopies;
  if i>0 then
    Result:=i;
end;

//Return & initialize the Fonts list
function TPrinter.GetFonts: TStrings;
begin
  if not Assigned(fFonts) then
    fFonts:=TStringList.Create;
  Result:=fFonts;

  //Only 1 initialization
  if fFonts.Count=0 then
    DoEnumFonts(fFonts);
end;

function TPrinter.GetOrientation: TPrinterOrientation;
begin
  Result:=poPortrait;
  if Printers.Count>0 then
    Result:=DoGetOrientation;
end;

// Returns the height in points (pixels) of printable area
function TPrinter.GetPageHeight: Integer;
begin
  Result:=0;
  if (Printers.Count>0) then
    with PaperSize.PaperRect.WorkRect do
      Result:=Bottom-Top;
end;

// Returns the width in points (pixels) of the printable area
function TPrinter.GetPageWidth: Integer;
begin
  Result:=0;
  if (Printers.Count>0) then
    with PaperSize.PaperRect.WorkRect do
      // PageWidth is the size in "pixels" of the printable area
      Result:=Right-Left;
end;

function TPrinter.GetPaperSize: TPaperSize;
begin
  if not Assigned(fPaperSize)  then
    fPaperSize:=TPaperSize.Create(self);
  Result:=fPaperSize;
end;

//Return the current selected printer
function TPrinter.GetPrinterIndex: integer;
begin
  Result:=fPrinterIndex;
  if (Result<0) and (Printers.Count>0) then
     Result:=0; //printer by default
end;

//Return & initialize the printers list
function TPrinter.GetPrinters: TStrings;
begin
  if not Assigned(fPrinters) then
    fPrinters:=TStringList.Create;
  Result:=fPrinters;
  
  //Only 1 initialization
  if not fPrintersValid then begin
    fPrintersValid:=true;
    DoEnumPrinters(fPrinters);
    if FPrinters.Count>0 then
      SelectCurrentPrinterOrDefault;
    DoInitialization;
  end;
end;

//Return XDPI
function TPrinter.GetXDPI: Integer;
begin
  Result:=1;
end;

//Return YDPI
function TPrinter.GetYDPI: Integer;
begin
  Result:=1;
end;

//Set the copies numbers
procedure TPrinter.SetCopies(AValue: Integer);
begin
  CheckPrinting(False);
  if aValue<1 then aValue:=1;
  if Printers.Count>0 then
    DoSetCopies(aValue)
  else
    raise EPrinter.Create('No printer found.');
end;

procedure TPrinter.SetOrientation(const AValue: TPrinterOrientation);
begin
  CheckPrinting(False);
  if Printers.Count>0 then
    DoSetOrientation(aValue);
end;

//Set the selected printer
procedure TPrinter.SetPrinterIndex(AValue: integer);
Var aName : String;
begin
  if fPrinterIndex=AValue then exit;
  CheckPrinting(False);
  if Printers.Count>0 then
  begin
    if AValue=-1 then
      aName:='*'
    else
      if (AValue>=0) and (AValue<Printers.Count) then
        aName:=Printers.Strings[AValue]
      else
        raise EPrinter.Create('Printer index out of range !');
    SetPrinter(aName);
  end
  else
    raise EPrinter.Create('No printers defined !');
end;

procedure TPrinter.SetRawMode(const AValue: boolean);
begin
  if AValue<>FRawMode then begin
    CheckPrinting(False);
    RawModeChanging;
    FRawMode := AValue;
  end;
end;

//If not Printer selected, Select the default printer
procedure TPrinter.SelectCurrentPrinterOrDefault;
begin
  if fPrinterIndex<0 then
    PrinterIndex:=0;
end;

//Specify here the Canvas class used by your TPrinter object
function TPrinter.GetCanvasRef: TPrinterCanvasRef;
begin
  if FRawMode then
    result := nil
  else
    Result:=TPrinterCanvas;
end;


procedure TPrinter.DoBeginDoc;
begin
  //Override this methode
end;

procedure TPrinter.DoNewPage;
begin
  //Override this methode
end;

procedure TPrinter.DoEndDoc(aAborded : Boolean);
begin
  //Override this methode
end;

procedure TPrinter.DoAbort;
begin
 //Override this methode
end;

procedure TPrinter.DoResetPrintersList;
begin
 //Override this methode
 fPrintersValid:=false;
end;

procedure TPrinter.DoResetFontsList;
begin
 //Override this methode
end;

//Initialize the Lst with all definied printers
procedure TPrinter.DoEnumPrinters(Lst: TStrings);
begin
 //Override this methode
 //Warning : The default printer must be the first printer
 //          (fPrinters[0])
end;

//Initialize the Lst with all supported fonts
procedure TPrinter.DoEnumFonts(Lst: TStrings);
begin
 //Override this methode
end;

//Initialize the Lst with all supported papers names
procedure TPrinter.DoEnumPapers(Lst: TStrings);
begin
  //DebugLn(['TPrinter.DoEnumPapers ',dbgsName(Self)]);
  
 //Override this methode
end;

// This method is called once after the printer list
// is obtained for the first time.
procedure TPrinter.DoInitialization;
begin
  //Override this method
end;


//Set the current printer
function TPrinter.DoSetPrinter(aName : string): Integer;
begin
  //Override this methode. The result must be
  //the index of aName printer in Printers list
  //if the aName doesn't exists, return -1
  Result:=-1;
end;

//Get the current copies nulbers
function TPrinter.DoGetCopies: Integer;
begin
 //Override this methode
 Result:=1;
end;

//Set the copies numbers
procedure TPrinter.DoSetCopies(aValue: Integer);
begin
 //Override this methode
end;

//Return the current paper orientation
function TPrinter.DoGetOrientation: TPrinterOrientation;
begin
  Result:=poPortrait;
  //Override this methode
end;

//Set the paper Orientation
procedure TPrinter.DoSetOrientation(aValue: TPrinterOrientation);
begin
 //Override this methode
end;

//Return the default paper name for the selected printer
function TPrinter.DoGetDefaultPaperName: string;
begin
  Result:='';
  //Override this methode
end;

//Return the selected paper name for the current printer
function TPrinter.DoGetPaperName: string;
begin
  Result:='';
  //Override this methode
end;

procedure TPrinter.DoSetPaperName(aName: string);
begin
  //Override this methode
end;

//Initialise aPaperRc with the aName paper rect
//Result : -1 no result
//          0 aPaperRc.WorkRect is a margins
//          1 aPaperRc.WorkRect is really the work rect
function TPrinter.DoGetPaperRect(aName : string; var aPaperRc: TPaperRect): Integer;
begin
  Result:=-1;
  //Override this methode
end;

//Get a state of current printer
function TPrinter.DoGetPrinterState: TPrinterState;
begin
  //Override this methode
  Result:=psNoDefine;
end;

//Return the type of selected printer
function TPrinter.GetPrinterType: TPrinterType;
begin
  Result:=ptLocal;
end;

//Return True if selected printer can printing
function TPrinter.GetCanPrint: Boolean;
begin
  Result:=True;
end;

function TPrinter.GetCanRenderCopies: Boolean;
begin
  Result:=True;
end;

{ TPaperSize }

function TPaperSize.GetDefaultPaperName: string;
begin
  Result:=fOwnedPrinter.DoGetDefaultPaperName;
end;

function TPaperSize.GetPhysPaperHeight: Integer;
begin
  result := PaperRect.PhysicalRect.Bottom - PaperRect.PhysicalRect.Top;
end;

function TPaperSize.GetPaperName: string;
begin
  Result:=fOwnedPrinter.DoGetPaperName;
  if Result='' then
    Result:=DefaultPaperName;
end;

function TPaperSize.GetPaperRect: TPaperRect;
begin
  Result:=PaperRectOfName(PaperName);
end;

function TPaperSize.GetPhysPaperWidth: Integer;
begin
  result := PaperRect.PhysicalRect.Right - PaperRect.PhysicalRect.Left;
end;

function TPaperSize.GetSupportedPapers: TStrings;
begin
  if (fOwnedPrinter.Printers.Count>0) and
     ((fSupportedPapers.Count=0)
       or (fLastPrinterIndex<>fOwnedPrinter.PrinterIndex)) then
  begin
    fOwnedPrinter.SelectCurrentPrinterOrDefault;
    
    fSupportedPapers.Clear;
    //DebugLn(['TPaperSize.GetSupportedPapers ',dbgsName(fOwnedPrinter),' ',dbgsName(Printer),' ',fOwnedPrinter=Printer]);
    fOwnedPrinter.DoEnumPapers(fSupportedPapers);
    fLastPrinterIndex:=fOwnedPrinter.PrinterIndex;
  end;
  Result:=fSupportedPapers;
end;

procedure TPaperSize.SetPaperName(const AName: string);
begin
  if SupportedPapers.IndexOf(aName)<>-1 then
  begin
    if aName<>PaperName then
      fOwnedPrinter.DoSetPaperName(aName)
  end
  else
    raise EPrinter.Create(Format('Paper "%s" not supported !',[aName]));
end;

//Return an TPaperRect corresponding at an paper name
function TPaperSize.PaperRectOfName(const AName: string): TPaperRect;
var TmpPaperRect : TPaperRect;
    Margins      : Integer;
begin
  FillChar(Result,SizeOf(Result),0);

  if SupportedPapers.IndexOf(AName)<>-1 then
  begin
    Margins:=fOwnedPrinter.DoGetPaperRect(aName,TmpPaperRect);
    if Margins>=0 then
    begin
      Result := TmpPaperRect;
    end
    else raise EPrinter.Create(Format('The paper "%s" has no defined rectangle ! ',[aName]));
  {end else if (AName='') and (SupportedPapers.Count=0) then begin
    DebugLn(['WARNING: TPaperSize.PaperRectOfName: printer has no paper rect. Using 1000,1000']);
    Result.PhysicalRect:=Rect(0,0,1000,1000);
    Result.WorkRect:=Result.PhysicalRect;}
  end
  else raise EPrinter.Create(Format('Paper "%s" not supported !',[aName]));
end;

constructor TPaperSize.Create(aOwner: TPrinter);
begin
  if not assigned(aOwner) then
    raise Exception.Create('TMediaSize.Create, aOwner must be defined !');
  Inherited Create;

  fLastPrinterIndex:=-2;
  fOwnedPrinter:=aOwner;
  fSupportedPapers:=TStringList.Create;
end;

destructor TPaperSize.Destroy;
begin
  fSupportedPapers.Free;

  inherited Destroy;
end;

{ TPrinterCanvas }

function TPrinterCanvas.GetTitle: string;
begin
  if Assigned(fPrinter) then
    Result:=fPrinter.Title
  else
    Result:=fTitle;
end;

function TPrinterCanvas.GetPageHeight: Integer;
begin
  if Assigned(fPrinter) and (fPageHeight=0) then
     Result:=fPrinter.PageHeight
  else
    Result:=fPageHeight;
end;

function TPrinterCanvas.GetPageWidth: Integer;
begin
  if Assigned(fPrinter) and (fPageWidth=0) then
     Result:=fPrinter.PageWidth
  else
    Result:=fPageWidth;
end;

procedure TPrinterCanvas.SetPageHeight(const AValue: Integer);
begin
  fPageHeight:=aValue;
end;

procedure TPrinterCanvas.SetPageWidth(const AValue: Integer);
begin
  fPageWidth:=aValue;
end;

procedure TPrinterCanvas.SetTitle(const AValue: string);
begin
  if Assigned(fPrinter) then
    fPrinter.Title:=aValue
  else
    fTitle:=aValue;
end;

constructor TPrinterCanvas.Create(APrinter: TPrinter);
begin
  Inherited Create;
  fPageWidth      :=0;
  fPageHeight     :=0;
  fTopMargin      :=0;
  fLeftMargin     :=0;
  fRightMargin    :=0;
  fBottomMargin   :=0;
  fPrinter:=aPrinter;
end;

procedure TPrinterCanvas.Changing;
begin
  if Assigned(fPrinter)  then
    fPrinter.CheckPrinting(True);
  inherited Changing;
end;

procedure TPrinterCanvas.BeginDoc;
begin
  fPageNum:=1;
end;

procedure TPrinterCanvas.NewPage;
begin
  Inc(fPageNum);
end;

procedure TPrinterCanvas.EndDoc;
begin
  //No special action
end;

function TPrinterCanvas.GetLeftMargin: Integer;
begin
  if (fLeftMargin=0) and (fPrinter<>nil) then
    Result:=fPrinter.PaperSize.PaperRect.WorkRect.Left
  else
    Result:=FLeftMargin;
end;

function TPrinterCanvas.GetTopMargin: Integer;
begin
  if (fTopMargin=0) and (fPrinter<>nil) then
    Result:=fPrinter.PaperSize.PaperRect.WorkRect.Top
  else
    Result:=fTopMargin;
end;

function TPrinterCanvas.GetBottomMargin: Integer;
begin
  if (fBottomMargin=0) and (fPrinter<>nil) then
  begin
    with fPrinter.Papersize.PaperRect do
      Result := PhysicalRect.Bottom-WorkRect.Bottom;
  end else
    Result := fBottomMargin;
end;

function TPrinterCanvas.GetRightMargin: Integer;
begin
  if (fRightMargin=0) and (fPrinter<>nil) then
  begin
    with fPrinter.Papersize.PaperRect do
      Result := PhysicalRect.Right-WorkRect.Right;
  end else
    Result := fRightMargin;
end;

INITIALIZATION
  //TPrinter it's an basic object. If you override this object,
  //you must create an instance.
  Printer:=nil;
  
FINALIZATION
  If Assigned(Printer) then
    Printer.Free;
end.
