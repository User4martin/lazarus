{*****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

  Author: Olivier GUILBAUD

  Abstract:
    Common component dialogs for select or setup printers

------------------------------------------------------------------------------}
unit PrintersDlgs;

{$mode objfpc}
{$IFDEF LCLCocoa}
  {$modeswitch objectivec1}
{$ENDIF}
{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, LResources, Printers, OsPrinters;

type

  TMeasureUnits = (unMM,unInch);
  { Type for compatibility with delphi }
  
  { TPageSetupDialog }
  
  TPageSetupDialog = class(TCustomPrinterSetupDialog)
  private
   fMargins : TRect;
   fUnits : TMeasureUnits;
  public
    constructor Create(TheOwner: TComponent); override;
    function Execute: Boolean; override;
    property Margins : TRect read fMargins write fMargins;
    property Units : TMeasureUnits read fUnits;
  end;

  { TPrinterDialog }
  
  TPrinterSetupDialog = class(TCustomPrinterSetupDialog)
  public
    function Execute: Boolean; override;
  end;

  { TPrintDialog }

  TPrintDialog = class(TCustomPrintDialog)
  public
    function Execute: Boolean; override;
  published
    property Collate;
    property Copies;
    property FromPage;
    property MinPage;
    property MaxPage;
    property Options;
    property PrintToFile;
    property PrintRange;
    property ToPage;
  end;

procedure Register;


implementation

{$R printersdlgs.res}

{$IFDEF UNIX}
  {$IFDEF DARWIN}
    {$IFDEF LCLCarbon}
      {$IFNDEF NativePrint}
        // add units as needed for carbon, for the moment use cups ones.
        uses udlgSelectPrinter, udlgPropertiesPrinter, udlgPageSetup, FileUtil;
        {$I cupsprndialogs.inc}
      {$ELSE}
        uses Math, CarbonProc, MacOSAll, LCLProc;
        {$I carbonprndialogs.inc}
      {$ENDIF}
    {$ENDIF}
    {$IFDEF LCLCocoa}
      uses Math, CocoaAll, MacOSAll, LCLProc;
      {$I cocoaprndialogs.inc}
    {$ENDIF}
    {$IFDEF LCLQt}
      uses qtobjects, qt4, qtint;
      {$I qtprndialogs.inc}
    {$ENDIF}
    {$IFDEF LCLGtk2}
      uses udlgSelectPrinter, udlgPropertiesPrinter, udlgPageSetup;
      {$I cupsprndialogs.inc}
    {$ENDIF}
  {$ELSE}
    {$IFDEF LCLQt}
      uses qtobjects, qt4, qtint;
      {$I qtprndialogs.inc}
    {$ELSE}
      uses udlgSelectPrinter, udlgPropertiesPrinter, udlgPageSetup;
      {$I cupsprndialogs.inc}
    {$ENDIF}
  {$ENDIF}
{$ENDIF}

{$IFDEF MSWindows}
  {$IFDEF LCLQt}
    uses Windows,
    qtobjects, qtwidgets, qt4, LCLIntf, LCLType;
    {$I qtprndialogs.inc}
  {$ELSE}
    uses Windows, WinUtilPrn, InterfaceBase, LCLIntf, LCLType, WinVer;
    {$I winprndialogs.inc}
  {$ENDIF}

{$ENDIF}

constructor TPageSetupDialog.Create(TheOwner: TComponent);
begin
 inherited Create(TheOwner);
 fMargins.Bottom := 0;
 fMargins.Left := 0;
 fMargins.Right := 0;
 fMargins.Top := 0;
end;

procedure Register;
begin
  RegisterComponents('Dialogs',[TPrinterSetupDialog,TPrintDialog,TPageSetupDialog]);
end;

end.
