{  $Id$  }
{
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
 
  Author: Mattias Gaertner

  Abstract:
    Editor options container and editor options dialog.
    The editor options are stored in XML format in the
     ~/.lazarus/editoroptions.xml file.
    Currently only for TSynEdit.
}
unit EditorOptions;

{$mode objfpc}{$H+}

interface

uses
  // RTL, FCL
  Classes, SysUtils,
  // LCL
  Controls, Graphics, LCLProc, FileUtil, LResources,
  // synedit
  SynEdit, SynEditAutoComplete, SynEditHighlighter, SynEditKeyCmds,
  SynEditStrConst,
  SynHighlighterCPP, SynHighlighterHTML, SynHighlighterJava, SynHighlighterLFM,
  SynHighlighterPas, SynHighlighterPerl, SynHighlighterPHP, SynHighlighterSQL,
  SynHighlighterPython, SynHighlighterUNIXShellScript, SynHighlighterXML,
  SynHighlighterJScript, SynEditMiscClasses,
  // codetools
  LinkScanner, CodeToolManager, Laz_XMLCfg,
  // IDEIntf
  IDECommands, IDEWindowIntf, SrcEditorIntf, IDEOptionsIntf,
  // IDE
  LazarusIDEStrConsts, IDEOptionDefs, IDEProcs, InputHistory, KeyMapping,
  KeymapSchemeDlg, KeyMapShortCutDlg, LazConf;

type
  TPreviewPasSyn = TSynFreePascalSyn;
  TSrcIDEHighlighter = TSynCustomHighlighter;
  TSynHighlightElement = TSynHighlighterAttributes;
  TCustomSynClass = class of TSrcIDEHighlighter;

  TLazSyntaxHighlighter =
    (lshNone, lshText, lshFreePascal, lshDelphi, lshLFM, lshXML, lshHTML,
    lshCPP, lshPerl, lshJava, lshBash, lshPython, lshPHP, lshSQL, lshJScript);
    
  TPascalHilightAttribute = (
    phaAssembler, phaComment, phaDirective, phaReservedWord, phaNumber,
    phaString, phaSymbol
  );
  
const
  PascalHilightAttributeNames: array[TPascalHilightAttribute] of String = (
    SYNS_AttrAssembler,
    SYNS_AttrComment,
    SYNS_AttrDirective,
    SYNS_AttrReservedWord,
    SYNS_AttrNumber,
    SYNS_AttrString,
    SYNS_AttrSymbol
  );

  SynEditPreviewIncludeOptions = [eoNoCaret, eoNoSelection];
  SynEditPreviewExcludeOptions = [eoDragDropEditing, eoDropFiles,
                                  eoScrollPastEof];
  SynEditPreviewIncludeOptions2 = [];
  SynEditPreviewExcludeOptions2 = [eoAlwaysVisibleCaret];

type
  TAdditionalHilightAttribute = (ahaNone, ahaTextBlock, ahaExecutionPoint,
    ahaEnabledBreakpoint, ahaDisabledBreakpoint,
    ahaInvalidBreakpoint, ahaUnknownBreakpoint,
    ahaErrorLine, ahaIncrementalSearch, ahaHighlightAll, ahaBracketMatch,
    ahaMouseLink, ahaLineNumber);

const
  AdditionalHighlightAttributes: array[TAdditionalHilightAttribute] of String =
    (
    '',
    'Text block',
    'Execution point',
    'Enabled breakpoint',
    'Disabled breakpoint',
    'Invalid breakpoint',
    'Unknown breakpoint',
    'Error line',
    'Incremental search match',
    'Highlight all',
    'Matching Brackets',
    'Mouse Link',
    'Line Number'
    );
    
type
  TSchemeAttribute = record
    BG, FG: TColor;
    Styles: TFontStyles;
    StylesMask: TFontStyles; // For Markup, normal Attributes will ignore this
  end;

  TPascalColorScheme = record
    Name: String;
    Default: TSchemeAttribute;
    Attributes: array[TPascalHilightAttribute] of TSchemeAttribute;
    Additional: array[TAdditionalHilightAttribute] of TSchemeAttribute;
  end;
  
const
  DEFAULT_COLOR_SCHEME: TPascalColorScheme = (
    Name: 'Default';
    Default: (BG: clNone;  FG: clNone; Styles: []; StylesMask: []);
    Attributes: (
      { phaAssembler    } (BG: clNone;  FG: clGreen; Styles: [];       StylesMask: []),
      { phaComment      } (BG: clNone;  FG: clBlue;  Styles: [fsBold]; StylesMask: []),
      { phaDirective    } (BG: clNone;  FG: clRed;   Styles: [fsBold]; StylesMask: []),
      { phaReservedWord } (BG: clNone;  FG: clNone;  Styles: [fsBold]; StylesMask: []),
      { phaNumber       } (BG: clNone;  FG: clNavy;  Styles: [];       StylesMask: []),
      { phaString       } (BG: clNone;  FG: clBlue;  Styles: [];       StylesMask: []),
      { phaSymbol       } (BG: clNone;  FG: clRed;   Styles: [];       StylesMask: [])
    );
    Additional: (
      { ahaNone               } (BG: clWhite;  FG: clBlack; Styles: []; StylesMask: []),
      { ahaTextBlock          } (BG: clNavy;   FG: clWhite; Styles: []; StylesMask: []),
      { ahaExecutionPoint     } (BG: clDKGray; FG: clWhite; Styles: []; StylesMask: []),
      { ahaEnabledBreakpoint  } (BG: clRed;    FG: clBlack; Styles: []; StylesMask: []),
      { ahaDisabledBreakpoint } (BG: clGreen;  FG: clBlack; Styles: []; StylesMask: []),
      { ahaInvalidBreakpoint  } (BG: clOlive;  FG: clGreen; Styles: []; StylesMask: []),
      { ahaUnknownBreakpoint  } (BG: clRed;    FG: clBlack; Styles: []; StylesMask: []),
      { ahaErrorLine          } (BG: $50a0ff;  FG: clBlack; Styles: []; StylesMask: []),
      { ahaIncrementalSearch  } (BG: $30D070;  FG: clWhite; Styles: []; StylesMask: []),
      { ahaHighlightAll       } (BG: clYellow; FG: clNone;  Styles: []; StylesMask: []),
      { ahaBracketMatch       } (BG: clNone;   FG: clNone;  Styles: [fsBold]; StylesMask: []),
      { ahaMouseLink          } (BG: clNone;   FG: clBlue;  Styles: []; StylesMask: []),
      { ahaLineNumber         } (BG: clNone;   FG: clNone;  Styles: []; StylesMask: [])
    )
  );
  
  TWILIGHT_COLOR_SCHEME: TPascalColorScheme = (
    Name: 'Twilight';
    Default: (BG: clBlack;  FG: clWhite; Styles: []; StylesMask: []);
    Attributes: (
      { phaAssembler    } (BG: clNone;  FG: clLime;    Styles: [];       StylesMask: []),
      { phaComment      } (BG: clNone;  FG: clGray;    Styles: [];       StylesMask: []),
      { phaDirective    } (BG: clNone;  FG: clRed;     Styles: [];       StylesMask: []),
      { phaReservedWord } (BG: clNone;  FG: clAqua;    Styles: [fsBold]; StylesMask: []),
      { phaNumber       } (BG: clNone;  FG: clFuchsia; Styles: [];       StylesMask: []),
      { phaString       } (BG: clNone;  FG: clYellow;  Styles: [];       StylesMask: []),
      { phaSymbol       } (BG: clNone;  FG: clAqua;    Styles: [];       StylesMask: [])
    );
    Additional: (
      { ahaNone               } (BG: clNone;   FG: clNone;  Styles: []; StylesMask: []),
      { ahaTextBlock          } (BG: clWhite;  FG: clBlack; Styles: []; StylesMask: []),
      { ahaExecutionPoint     } (BG: clBlue;   FG: clWhite; Styles: []; StylesMask: []),
      { ahaEnabledBreakpoint  } (BG: clRed;    FG: clWhite; Styles: []; StylesMask: []),
      { ahaDisabledBreakpoint } (BG: clLime;   FG: clRed;   Styles: []; StylesMask: []),
      { ahaInvalidBreakpoint  } (BG: clOlive;  FG: clGreen; Styles: []; StylesMask: []),
      { ahaUnknownBreakpoint  } (BG: clRed;    FG: clBlack; Styles: []; StylesMask: []),
      { ahaErrorLine          } (BG: $50a0ff;  FG: clBlack; Styles: []; StylesMask: []),
      { ahaIncrementalSearch  } (BG: $30D070;  FG: clWhite; Styles: []; StylesMask: []),
      { ahaHighlightAll       } (BG: clYellow; FG: clNone;  Styles: []; StylesMask: []),
      { ahaBracketMatch       } (BG: clNone;   FG: clNone;  Styles: [fsBold]; StylesMask: []),
      { ahaMouseLink          } (BG: clNone;   FG: clBlue;  Styles: []; StylesMask: []),
      { ahaLineNumber         } (BG: clNone;   FG: clNone;  Styles: []; StylesMask: [])
    )
  );

  CLASSIC_COLOR_SCHEME: TPascalColorScheme = (
    Name: 'Pascal Classic';
    Default: (BG: clNavy;  FG: clYellow; Styles: []; StylesMask: []);
    Attributes: (
      { phaAssembler    } (BG: clNone;  FG: clLime;    Styles: []; StylesMask: []),
      { phaComment      } (BG: clNone;  FG: clSilver;  Styles: []; StylesMask: []),
      { phaDirective    } (BG: clNone;  FG: clSilver;  Styles: []; StylesMask: []),
      { phaReservedWord } (BG: clNone;  FG: clWhite;   Styles: []; StylesMask: []),
      { phaNumber       } (BG: clNone;  FG: clYellow;  Styles: []; StylesMask: []),
      { phaString       } (BG: clNone;  FG: clYellow;  Styles: []; StylesMask: []),
      { phaSymbol       } (BG: clNone;  FG: clYellow;  Styles: []; StylesMask: [])
    );
    Additional: (
      { ahaNone               } (BG: clNone;   FG: clNone;  Styles: []; StylesMask: []),
      { ahaTextBlock          } (BG: clBlue;   FG: clWhite; Styles: []; StylesMask: []),
      { ahaExecutionPoint     } (BG: clAqua;   FG: clBlack; Styles: []; StylesMask: []),
      { ahaEnabledBreakpoint  } (BG: clRed;    FG: clWhite; Styles: []; StylesMask: []),
      { ahaDisabledBreakpoint } (BG: clLime;   FG: clRed;   Styles: []; StylesMask: []),
      { ahaInvalidBreakpoint  } (BG: clOlive;  FG: clLime;  Styles: []; StylesMask: []),
      { ahaUnknownBreakpoint  } (BG: clNone;   FG: clNone;  Styles: []; StylesMask: []),
      { ahaErrorLine          } (BG: clMaroon; FG: clWhite; Styles: []; StylesMask: []),
      { ahaIncrementalSearch  } (BG: $30D070;  FG: clWhite; Styles: []; StylesMask: []),
      { ahaHighlightAll       } (BG: clYellow; FG: clNone;  Styles: []; StylesMask: []),
      { ahaBracketMatch       } (BG: clNone;   FG: clNone;  Styles: [fsBold]; StylesMask: []),
      { ahaMouseLink          } (BG: clNone;   FG: clBlue;  Styles: []; StylesMask: []),
      { ahaLineNumber         } (BG: clNone;   FG: clNone;  Styles: []; StylesMask: [])
    )
  );
  
  OCEAN_COLOR_SCHEME: TPascalColorScheme = (
    Name: 'Ocean';
    Default: (BG: clNavy;  FG: clYellow; Styles: []; StylesMask: []);
    Attributes: (
      { phaAssembler    } (BG: clNone;  FG: clLime;    Styles: [];       StylesMask: []),
      { phaComment      } (BG: clNone;  FG: clGray;    Styles: [];       StylesMask: []),
      { phaDirective    } (BG: clNone;  FG: clRed;     Styles: [];       StylesMask: []),
      { phaReservedWord } (BG: clNone;  FG: clAqua;    Styles: [fsBold]; StylesMask: []),
      { phaNumber       } (BG: clNone;  FG: clFuchsia; Styles: [];       StylesMask: []),
      { phaString       } (BG: clNone;  FG: clYellow;  Styles: [];       StylesMask: []),
      { phaSymbol       } (BG: clNone;  FG: clAqua;    Styles: [];       StylesMask: [])
    );
    Additional: (
      { ahaNone               } (BG: clNone;   FG: clNone;  Styles: []; StylesMask: []),
      { ahaTextBlock          } (BG: clWhite;  FG: clBlack; Styles: []; StylesMask: []),
      { ahaExecutionPoint     } (BG: clBlue;   FG: clWhite; Styles: []; StylesMask: []),
      { ahaEnabledBreakpoint  } (BG: clRed;    FG: clWhite; Styles: []; StylesMask: []),
      { ahaDisabledBreakpoint } (BG: clLime;   FG: clRed;   Styles: []; StylesMask: []),
      { ahaInvalidBreakpoint  } (BG: clOlive;  FG: clGreen; Styles: []; StylesMask: []),
      { ahaUnknownBreakpoint  } (BG: clRed;    FG: clBlack; Styles: []; StylesMask: []),
      { ahaErrorLine          } (BG: $50A0FF;  FG: clBlack; Styles: []; StylesMask: []),
      { ahaIncrementalSearch  } (BG: $30D070;  FG: clWhite; Styles: []; StylesMask: []),
      { ahaHighlightAll       } (BG: clYellow; FG: clNone;  Styles: []; StylesMask: []),
      { ahaBracketMatch       } (BG: clNone;   FG: clNone;  Styles: [fsBold]; StylesMask: []),
      { ahaMouseLink          } (BG: clNone;   FG: clBlue;  Styles: []; StylesMask: []),
      { ahaLineNumber         } (BG: clNone;   FG: clNone;  Styles: []; StylesMask: [])
    )
  );

  DELPHI_COLOR_SCHEME: TPascalColorScheme = (
    Name: 'Delphi';
    Default: (BG: clNone;  FG: clNone; Styles: []; StylesMask: []);
    Attributes: (
      { phaAssembler    } (BG: clNone;  FG: clBlack;   Styles: [];         StylesMask: []),
      { phaComment      } (BG: clNone;  FG: clGreen;   Styles: [fsItalic]; StylesMask: []),
      { phaDirective    } (BG: clNone;  FG: clTeal;    Styles: [];         StylesMask: []),
      { phaReservedWord } (BG: clNone;  FG: clNavy;    Styles: [fsBold];   StylesMask: []),
      { phaNumber       } (BG: clNone;  FG: clBlue;    Styles: [];         StylesMask: []),
      { phaString       } (BG: clNone;  FG: clBlue;    Styles: [];         StylesMask: []),
      { phaSymbol       } (BG: clNone;  FG: clNone;    Styles: [];         StylesMask: [])
    );
    Additional: (
      { ahaNone               } (BG: clNone;      FG: clNone;          Styles: []; StylesMask: []),
      { ahaTextBlock          } (BG: $A56D53;     FG: clWhite;         Styles: []; StylesMask: []),
      { ahaExecutionPoint     } (BG: $9999CC;     FG: clBlack;         Styles: []; StylesMask: []),
      { ahaEnabledBreakpoint  } (BG: $FFC7C7;     FG: clBlack;         Styles: []; StylesMask: []),
      { ahaDisabledBreakpoint } (BG: $FFC7C7;     FG: clGray;          Styles: []; StylesMask: []),
      { ahaInvalidBreakpoint  } (BG: clGreen;     FG: clWhite;         Styles: []; StylesMask: []),
      { ahaUnknownBreakpoint  } (BG: $FFC7C7;     FG: clBlack;         Styles: []; StylesMask: []),
      { ahaErrorLine          } (BG: clRed;       FG: clWhite;         Styles: []; StylesMask: []),
      { ahaIncrementalSearch  } (BG: clBlack;     FG: $FCFDCD;         Styles: []; StylesMask: []),
      { ahaHighlightAll       } (BG: clYellow;    FG: clNone;          Styles: []; StylesMask: []),
      { ahaBracketMatch       } (BG: clAqua;      FG: clNone;{ $CCCCD6; }Styles: []; StylesMask: []), // delphi uses FG color as a frame for box
      { ahaMouseLink          } (BG: clNone;      FG: clBlue;          Styles: []; StylesMask: []),
      { ahaLineNumber         } (BG: $F4F4F4;     FG: $CC9999;         Styles: []; StylesMask: [])
    )
  );

const
  EditorOptsFormatVersion = 4;

  LazSyntaxHighlighterClasses: array[TLazSyntaxHighlighter] of
    TCustomSynClass =
    (nil, nil, TSynFreePascalSyn, TSynPasSyn, TSynLFMSyn, TSynXMLSyn,
    TSynHTMLSyn, TSynCPPSyn, TSynPerlSyn, TSynJavaSyn, TSynUNIXShellScriptSyn,
    TSynPythonSyn, TSynPHPSyn, TSynSQLSyn, TSynJScriptSyn);


{ Comments }
const
  DefaultCommentTypes: array[TLazSyntaxHighlighter] of TCommentType = (
    comtNone,  // lshNone
    comtNone,  // lshText
    comtPascal,// lshFreePascal
    comtPascal,// lshDelphi
    comtDelphi,// lshLFM
    comtHtml,  // lshXML
    comtHtml,  // lshHTML
    comtCPP,   // lshCPP
    comtPerl,  // lshPerl
    comtCPP,   // lshJava
    comtPerl,  // lshBash
    comtPerl,  // lshPython
    comtHTML,  // lshPHP
    comtCPP,   // lshSQL
    comtCPP    // lshJScript
    );

const
  SynEditDefaultOptions = SYNEDIT_DEFAULT_OPTIONS - [eoShowScrollHint]
                                                  + [eoHalfPageScroll];
  SynEditDefaultOptions2 = SYNEDIT_DEFAULT_OPTIONS2;

type
  { TEditOptLanguageInfo stores lazarus IDE additional information
    of a highlighter, such as samplesource, which sample lines are special
    lines, file extensions
    MappedAttributes is a list of the format "AttributName=PascalAttributName"
      This mapping attributes are used for default values. For example:
      The comment attribute of HTML is mapped to the comment attribute of
      pascal "Comment=Comment". If there is no mapping attribute for an
      attribute the default values are taken from an untouched highlighter.
      For example Symbol in HTML is not mapped and therefore has as default
      value fo style [fsBold] as defined in synhighlighterhtml.pp.
    }
  TEditOptLanguageInfo = class
  public
    SynClass: TCustomSynClass;
    TheType:  TLazSyntaxHighlighter;
    FileExtensions: String; // divided by semicolon, e.g. 'pas;pp;inc'
    DefaultFileExtensions: string;
    ColorScheme: String;
    SampleSource: String;
    AddAttrSampleLines: array[TAdditionalHilightAttribute] of
    Integer; // first line = 1
    MappedAttributes: TStringList; // map attributes to pascal
    DefaultCommentType: TCommentType;
    CaretXY: TPoint;
    constructor Create;
    destructor Destroy; override;
    function GetDefaultFilextension: String;
    procedure SetBothFilextensions(const Extensions: string);
    function SampleLineToAddAttr(Line: Integer): TAdditionalHilightAttribute;
  end;

  { TEditOptLangList }

  TEditOptLangList = class(TList)
  private
    function GetInfos(Index: Integer): TEditOptLanguageInfo;
  public
    constructor Create;
    procedure Clear; override;
    destructor Destroy; override;
    function FindByName(const Name: String): Integer;
    function FindByClass(CustomSynClass: TCustomSynClass): Integer;
    function FindByHighlighter(Hilighter: TSynCustomHighlighter): Integer;
    function FindByType(AType: TLazSyntaxHighlighter): Integer;
    function GetDefaultFilextension(AType: TLazSyntaxHighlighter): String;
    function GetInfoByType(AType: TLazSyntaxHighlighter): TEditOptLanguageInfo;
    property Items[Index: Integer]: TEditOptLanguageInfo read GetInfos;
      default;
  end;


  { TEditorOptions - Editor Options object used to hold the editor options }

  TEditorOptions = class(TAbstractIDEOptions)
  private
    xmlconfig: TXMLConfig;

    // general options
    fFindTextAtCursor: Boolean;
    fShowTabCloseButtons: Boolean;
    fSynEditOptions: TSynEditorOptions;
    fSynEditOptions2: TSynEditorOptions2;
    fCtrlMouseLinks: Boolean;
    fUndoAfterSave: Boolean;
    fUseSyntaxHighlight: Boolean;
    FCopyWordAtCursorOnCopyNone: Boolean;
    FShowGutterHints: Boolean;
    fBlockIndent: Integer;
    fUndoLimit: Integer;
    fTabWidth:  Integer;

    // Display options
    fVisibleRightMargin: Boolean;
    fVisibleGutter: Boolean;
    fShowLineNumbers: Boolean;
    fShowOnlyLineNumbersMultiplesOf: integer;
    fGutterColor: TColor;
    fGutterWidth: Integer;
    fRightMargin: Integer;
    fRightMarginColor: TColor;
    fEditorFont:  String;
    fEditorFontHeight: Integer;
    fExtraCharSpacing: Integer;
    fExtraLineSpacing: Integer;
    fDisableAntialiasing: Boolean;
    FDoNotWarnForFont: string;

    // Key Mappings options
    fKeyMappingScheme: String;
    fKeyMap: TKeyCommandRelationList;

    // Color options
    fHighlighterList: TEditOptLangList;

    // Code tools options (MG: these will move to an unit of their own)
    fAutoIdentifierCompletion: Boolean;
    fAutoCodeParameters: Boolean;
    fAutoToolTipExprEval: Boolean;
    fAutoToolTipSymbTools: Boolean;
    fAutoDelayInMSec: Integer;
    fCodeTemplateFileName: String;
    fCTemplIndentToTokenStart: Boolean;
    
    // Code Folding
    FUseCodeFolding: Boolean;
    FCFDividerDrawLevel: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load;
    procedure Save;
    function GetSynEditOptionName(SynOption: TSynEditorOption): string;

    procedure GetHighlighterSettings(Syn: TSrcIDEHighlighter); // read highlight settings from config file
    procedure SetHighlighterSettings(Syn: TSrcIDEHighlighter); // write highlight settings to config file
    procedure GetSynEditSettings(ASynEdit: TSynEdit); // read synedit settings from config file
    procedure SetSynEditSettings(ASynEdit: TSynEdit); // write synedit settings to file
    procedure GetSynEditPreviewSettings(APreviewEditor: TObject);
    procedure AddSpecialHilightAttribsToHighlighter(Syn: TSrcIDEHighlighter);

    function CreateSyn(LazSynHilighter: TLazSyntaxHighlighter): TSrcIDEHighlighter;
    function ReadColorScheme(const LanguageName: String): String;
    function ReadPascalColorScheme: String;
    procedure WriteColorScheme(const LanguageName, SynColorScheme: String);
    procedure GetDefaultsForPascalAttribute(Attr: TSynHighlightElement;
                                            const SynColorScheme: String);
    procedure ReadHighlighterSettings(Syn: TSrcIDEHighlighter;
                                      SynColorScheme: String);
    procedure ReadDefaultsForHighlighterSettings(Syn: TSrcIDEHighlighter;
                                                 SynColorScheme: String;
                                                 DefaultPascalSyn: TPreviewPasSyn);
    procedure WriteHighlighterSettings(Syn: TSrcIDEHighlighter;
                                       SynColorScheme: String);
    function GetLineColors(Syn: TSrcIDEHighlighter;
          AddHilightAttr: TAdditionalHilightAttribute; {TODO: MFR maybe remove?}
          out FG, BG: TColor; out Styles, StylesMask: TFontStyles): Boolean;
    procedure SetMarkupColor(Syn: TSrcIDEHighlighter;
                             AddHilightAttr: TAdditionalHilightAttribute;
                             aMarkup: TSynSelectedColor);
    procedure SetMarkupColors(Syn: TSrcIDEHighlighter; aSynEd: TSynEdit);
  published
    // general options
    property SynEditOptions: TSynEditorOptions
      read fSynEditOptions write fSynEditOptions default SynEditDefaultOptions;
    property SynEditOptions2: TSynEditorOptions2
      read fSynEditOptions2 write fSynEditOptions2 default SynEditDefaultOptions2;
    property CtrlMouseLinks: Boolean
      read fCtrlMouseLinks write fCtrlMouseLinks;// ctrl = SYNEDIT_LINK_MODIFIER
    property ShowTabCloseButtons: Boolean
      read fShowTabCloseButtons write fShowTabCloseButtons;
    property UndoAfterSave: Boolean read fUndoAfterSave
      write fUndoAfterSave default True;
    property FindTextAtCursor: Boolean
      read fFindTextAtCursor write fFindTextAtCursor default True;
    property UseSyntaxHighlight: Boolean
      read fUseSyntaxHighlight write fUseSyntaxHighlight default True;
    property CopyWordAtCursorOnCopyNone: Boolean
      read FCopyWordAtCursorOnCopyNone write FCopyWordAtCursorOnCopyNone;
    property ShowGutterHints: Boolean read FShowGutterHints
      write FShowGutterHints;
    property BlockIndent: Integer
      read fBlockIndent write fBlockIndent default 2;
    property UndoLimit: Integer read fUndoLimit write fUndoLimit default 32767;
    property TabWidth: Integer read fTabWidth write fTabWidth default 8;

    // Display options
    property VisibleRightMargin: Boolean
      read fVisibleRightMargin write fVisibleRightMargin default True;
    property VisibleGutter: Boolean read fVisibleGutter
      write fVisibleGutter default True;
    property ShowLineNumbers: Boolean read fShowLineNumbers
      write fShowLineNumbers default False;
    property ShowOnlyLineNumbersMultiplesOf: integer read fShowOnlyLineNumbersMultiplesOf
      write fShowOnlyLineNumbersMultiplesOf;
    property GutterColor: TColor
      read fGutterColor write fGutterColor default clBtnFace;
    property GutterWidth: Integer
      read fGutterWidth write fGutterWidth default 30;
    property RightMargin: Integer
      read fRightMargin write fRightMargin default 80;
    property RightMarginColor: Integer
      read fRightMarginColor write fRightMarginColor default clBtnFace;
    property EditorFont: String read fEditorFont write fEditorFont;
    property EditorFontHeight: Integer
      read fEditorFontHeight write FEditorFontHeight;
    property ExtraCharSpacing: Integer
      read fExtraCharSpacing write fExtraCharSpacing default 0;
    property ExtraLineSpacing: Integer
      read fExtraLineSpacing write fExtraLineSpacing default 1;
    property DisableAntialiasing: Boolean
      read fDisableAntialiasing write fDisableAntialiasing default True;
    property DoNotWarnForFont: string
      read FDoNotWarnForFont write FDoNotWarnForFont;

    // Key Mappings
    property KeyMappingScheme: String
      read fKeyMappingScheme write fKeyMappingScheme;
    property KeyMap: TKeyCommandRelationList read fKeyMap;

    // Color options
    property HighlighterList: TEditOptLangList
      read fHighlighterList write fHighlighterList;

    // Code Tools options
    property AutoIdentifierCompletion: Boolean
      read fAutoIdentifierCompletion write fAutoIdentifierCompletion default True;
    property AutoCodeParameters: Boolean
      read fAutoCodeParameters write fAutoCodeParameters default True;
    property AutoToolTipExprEval: Boolean
      read fAutoToolTipExprEval write fAutoToolTipExprEval default True;
    property AutoToolTipSymbTools: Boolean
      read fAutoToolTipSymbTools write fAutoToolTipSymbTools default True;
    property AutoDelayInMSec: Integer read fAutoDelayInMSec
      write fAutoDelayInMSec default 1000;
    property CodeTemplateFileName: String
      read fCodeTemplateFileName write fCodeTemplateFileName;
    property CodeTemplateIndentToTokenStart: Boolean
      read fCTemplIndentToTokenStart write fCTemplIndentToTokenStart;

    // Code Folding
    property UseCodeFolding: Boolean
        read FUseCodeFolding write FUseCodeFolding default True;
    property CFDividerDrawLevel: Integer
        read FCFDividerDrawLevel write FCFDividerDrawLevel default 3;
  end;

const
  LazSyntaxHighlighterNames: array[TLazSyntaxHighlighter] of String = (
    'None',
    'Text',
    'FreePascal',
    'Delphi',
    'LFM',
    'XML',
    'HTML',
    'C++',
    'Perl',
    'Java',
    'Bash',
    'Python',
    'PHP',
    'SQL',
    'JScript'
    );

var
  EditorOpts: TEditorOptions;

function StrToLazSyntaxHighlighter(const s: String): TLazSyntaxHighlighter;
function ExtensionToLazSyntaxHighlighter(Ext: String): TLazSyntaxHighlighter;
function FilenameToLazSyntaxHighlighter(Filename: String): TLazSyntaxHighlighter;
procedure RepairEditorFontHeight(var FontHeight: integer);
procedure CopyHiLightAttributeValues(Src, Dest: TSynHighlightElement);

function BuildBorlandDCIFile(ACustomSynAutoComplete: TCustomSynAutoComplete): Boolean;

implementation

uses
  IDEContextHelpEdit;

const
  ValidAttribChars = ['a'..'z', 'A'..'Z', '_', '0'..'9'];

  // several language types can be redirected. For example there are FreePascal
  // and Delphi, but currently both are hilighted with the FreePascal
  // highlighter
  CompatibleLazSyntaxHilighter: array[TLazSyntaxHighlighter] of
    TLazSyntaxHighlighter = (
    lshNone,
    lshText,
    lshFreePascal,
    lshFreePascal,
    lshLFM,
    lshXML,
    lshHTML,
    lshCPP,
    lshPerl,
    lshJava,
    lshBash,
    lshPython,
    lshPHP,
    lshSQL,
    lshJScript
    );

procedure RepairEditorFontHeight(var FontHeight: integer);
begin
  if ((FontHeight>=0) and (FontHeight<=5))
  or ((FontHeight<0) and (FontHeight>=-5)) then
    FontHeight:=12;
end;

function StrToLazSyntaxHighlighter(const s: String): TLazSyntaxHighlighter;
begin
  for Result := Low(TLazSyntaxHighlighter) to High(TLazSyntaxHighlighter) do
    if (AnsiCompareText(s, LazSyntaxHighlighterNames[Result]) = 0) then
      exit;
  Result := lshFreePascal;
end;

function ExtensionToLazSyntaxHighlighter(Ext: String): TLazSyntaxHighlighter;
var
  s, CurExt: String;
  LangID, StartPos, EndPos: Integer;
begin
  Result := lshNone;
  if (Ext = '') or (Ext = '.') or (EditorOpts.HighlighterList = Nil) then
    exit;
  Ext := lowercase(Ext);
  if (Ext[1] = '.') then
    Ext := copy(Ext, 2, length(Ext) - 1);
  LangID := 0;
  while LangID < EditorOpts.HighlighterList.Count do
  begin
    s := EditorOpts.HighlighterList[LangID].FileExtensions;
    StartPos := 1;
    while StartPos <= length(s) do
    begin
      Endpos := StartPos;
      while (EndPos <= length(s)) and (s[EndPos] <> ';') do
        inc(EndPos);
      CurExt := copy(s, Startpos, EndPos - StartPos);
      if (CurExt <> '') and (CurExt[1] = '.') then
        CurExt := copy(CurExt, 2, length(CurExt) - 1);
      if lowercase(CurExt) = Ext then
      begin
        Result := EditorOpts.HighlighterList[LangID].TheType;
        exit;
      end;
      Startpos := EndPos + 1;
    end;
    inc(LangID);
  end;
end;

function FilenameToLazSyntaxHighlighter(Filename: String
  ): TLazSyntaxHighlighter;
var
  CompilerMode: TCompilerMode;
begin
  Result:=ExtensionToLazSyntaxHighlighter(ExtractFileExt(Filename));
  if Result in [lshFreePascal,lshDelphi] then begin
    CompilerMode:=CodeToolBoss.GetCompilerModeForDirectory(ExtractFilePath(Filename));
    if CompilerMode in [cmDELPHI,cmTP] then
      Result:=lshDelphi
    else
      Result:=lshFreePascal;
  end;
end;

const
  EditOptsConfFileName = 'editoroptions.xml';


function BuildBorlandDCIFile(
  ACustomSynAutoComplete: TCustomSynAutoComplete): Boolean;
  // returns if something has changed
var
  sl: TStringList;
  i, sp, ep: Integer;
  Token, Comment, Value: String;
  Attributes: TStrings;
begin
  Result := False;
  sl     := TStringList.Create;
  try
    for i := 0 to ACustomSynAutoComplete.Completions.Count - 1 do
    begin
      Token := ACustomSynAutoComplete.Completions[i];
      Comment := ACustomSynAutoComplete.CompletionComments[i];
      Value := ACustomSynAutoComplete.CompletionValues[i];
      sl.Add('[' + Token + ' | ' + Comment + ']');
      Attributes:=ACustomSynAutoComplete.CompletionAttributes[i];
      if (Attributes<>nil) and (Attributes.Count>0) then begin
        sl.Add(CodeTemplateAttributesStartMagic);
        sl.AddStrings(Attributes);
        sl.Add(CodeTemplateAttributesEndMagic);
      end;
      sp    := 1;
      ep    := 1;
      while ep <= length(Value) do
        if Value[ep] in [#10, #13] then
        begin
          sl.Add(copy(Value, sp, ep - sp));
          inc(ep);
          if (ep <= length(Value)) and (Value[ep] in [#10, #13]) and
            (Value[ep] <> Value[ep - 1]) then
            inc(ep);
          sp := ep;
        end
        else
          inc(ep);
      if (ep > sp) or ((Value <> '') and (Value[length(Value)] in [#10, #13])) then
        sl.Add(copy(Value, sp, ep - sp));
    end;
    if ACustomSynAutoComplete.AutoCompleteList.Equals(sl) = False then
    begin
      Result := True;
      ACustomSynAutoComplete.AutoCompleteList := sl;
    end;
  finally
    sl.Free;
  end;
end;

function StrToValidXMLName(const s: String): String;
var
  i: Integer;
begin
  Result := s;
  // replace invalid characters
  for i := 1 to length(Result) do
    if (not (Result[i] in ValidAttribChars)) then
      Result[i] := '_';
end;

procedure CopyHiLightAttributeValues(Src, Dest: TSynHighlightElement);
begin
  Dest.Background := Src.Background;
  Dest.Foreground := Src.Foreground;
  Dest.Style      := Src.Style;
  Dest.StyleMask  := Src.StyleMask;
end;

{ TEditOptLanguageInfo }

constructor TEditOptLanguageInfo.Create;
begin
  inherited Create;

end;

destructor TEditOptLanguageInfo.Destroy;
begin
  MappedAttributes.Free;
  inherited Destroy;
end;

function TEditOptLanguageInfo.SampleLineToAddAttr(
  Line: Integer): TAdditionalHilightAttribute;
begin
  if Line < 1 then
  begin
    Result := ahaNone;
    exit;
  end;
  for Result := Low(TAdditionalHilightAttribute)
    to High(TAdditionalHilightAttribute) do
    if (Result <> ahaNone) and (AddAttrSampleLines[Result] = Line) then
      exit;
  Result := ahaNone;
end;

function TEditOptLanguageInfo.GetDefaultFilextension: String;
var
  p: Integer;
begin
  // read the first file extension
  p := 1;
  while (p <= length(FileExtensions)) and (FileExtensions[p] <> ';') do
    inc(p);
  if p > 1 then
    Result := '.' + copy(FileExtensions, 1, p - 1)
  else
    Result := '';
end;

procedure TEditOptLanguageInfo.SetBothFilextensions(const Extensions: string);
begin
  FileExtensions:=Extensions;
  DefaultFileExtensions:=Extensions;
end;

{ TEditOptLangList }

function TEditOptLangList.GetInfos(Index: Integer): TEditOptLanguageInfo;
begin
  if (Index < 0) or (Index >= Count) then
    raise Exception.Create('TEditOptLangList.GetInfos Index '
      + IntToStr(Index) + ' out of bounds. Count=' + IntToStr(Count));
  Result := TEditOptLanguageInfo(inherited Items[Index]);
end;

procedure TEditOptLangList.Clear;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    Items[i].Free;
  inherited Clear;
end;

constructor TEditOptLangList.Create;
var
  NewInfo: TEditOptLanguageInfo;
begin
  inherited Create;

  { create the meta information for each available highlighter.
    Please keep the pascal highlighter at the top. The rest can be ordered as you
    like.
  }

  // create info for pascal
  NewInfo := TEditOptLanguageInfo.Create;
  with NewInfo do
  begin
    TheType := lshFreePascal;
    DefaultCommentType := DefaultCommentTypes[TheType];
    SynClass := LazSyntaxHighlighterClasses[TheType];
    SetBothFilextensions('pp;pas;inc;lpr;lrs;dpr;dpk;fpd');
    SampleSource :=
      '{ Comment }'#13 +
      '{$R- compiler directive}'#13 +
      'procedure TForm1.Button1Click(Sender: TObject);'#13 +
      'var  // Delphi Comment'#13 +
      '  Number, I, X: Integer;'#13 +
      'begin'#13 +
      '  Number := 12345 * (2 + 9) // << Matching Brackets ;'#13 +
      '  Caption := ''The number is '' + IntToStr(Number);'#13 +
      '  asm'#13 + '    MOV AX,1234h'#13 +
      '    MOV Number,AX'#13 +
      '  end;'#13 +
      '  X := 10;'#13 +
      '  inc(X); {$R+} { Search Match, Text Block }'#13 +
      '  for I := 0 to Number do {$R-} { execution point }'#13 +
      '  begin'#13 +
      '    Inc(X, 2); {$R+} { Enabled breakpoint }'#13 +
      '    Dec(X, 3); {$R+} { Disabled breakpoint }'#13 +
      '    {$R-} // { Invalid breakpoint }'#13 +
      '    WriteLN(X); {$R-} { Unknown breakpoint }'#13 +
      '    X := X + 1.0; {$R-} { Error line }'#13 +
      '    ListBox1.Items.Add(IntToStr(X));'#13 +
      '  end;'#13 +
      'end;'#13 + #13;
    AddAttrSampleLines[ahaDisabledBreakpoint] := 18;
    AddAttrSampleLines[ahaEnabledBreakpoint] := 17;
    AddAttrSampleLines[ahaInvalidBreakpoint] := 19;
    AddAttrSampleLines[ahaUnknownBreakpoint] := 20;
    AddAttrSampleLines[ahaErrorLine] := 21;
    AddAttrSampleLines[ahaExecutionPoint] := 15;
    AddAttrSampleLines[ahaTextBlock] := 14;
    CaretXY := Point(21, 7);
  end;
  Add(NewInfo);

  // create info for html
  NewInfo := TEditOptLanguageInfo.Create;
  with NewInfo do
  begin
    TheType := lshHTML;
    DefaultCommentType := DefaultCommentTypes[TheType];
    SynClass := LazSyntaxHighlighterClasses[TheType];
    SetBothFilextensions('htm;html');
    SampleSource :=
      '<html>'#13 + '<title>Lazarus Sample source for html</title>'#13 +
      '<body bgcolor=#ffffff background="bg.jpg">'#13 +
      '<!-- Comment -->'#13 + '<img src="lazarus.jpg">'#13 +
      '<p>'#13 + '  Some Text'#13 +
      '  Ampersands: &nbsp;F&nbsp;P&nbsp;C'#13 + '</p>'#13 +
      '<invalid_tag>'#13 + '<!-- Text Block -->'#13 +
      '</body>'#13 + '</html>'#13 + #13;
    AddAttrSampleLines[ahaTextBlock] := 11;
    MappedAttributes := TStringList.Create;
    with MappedAttributes do
    begin
      Add('Comment=Comment');
      Add('Space=Space');
    end;
    CaretXY := Point(1,1);
  end;
  Add(NewInfo);

  // create info for cpp
  NewInfo := TEditOptLanguageInfo.Create;
  with NewInfo do
  begin
    TheType := lshCPP;
    DefaultCommentType := DefaultCommentTypes[TheType];
    SynClass := LazSyntaxHighlighterClasses[TheType];
    SetBothFilextensions('c;cc;cpp;h;hpp;hh');
    SampleSource :=
      '/* Comment */'#13 + '#include <stdio.h>'#13 +
      '#include <stdlib.h>'#13 + #13 +
      'static char line_buf[LINE_BUF];'#13 + #13 +
      'int main(int argc,char **argv){'#13 + '  FILE *file;'#13 +
      '  line_buf[0]=0;'#13 + '  printf("\n");'#13 +
      '  return 0;'#13 + '}'#13 + ''#13 + #13;
    AddAttrSampleLines[ahaTextBlock] := 11;
    MappedAttributes := TStringList.Create;
    with MappedAttributes do
    begin
      Add('Assembler=Assembler');
      Add('Comment=Comment');
      Add('Preprocessor=Comment');
      Add('Identifier=Identifier');
      Add('Reserved_word=Reserved_word');
      Add('Number=Number');
      Add('Space=Space');
      Add('String=String');
      Add('Symbol=Symbol');
    end;
    CaretXY := Point(1,1);
  end;
  Add(NewInfo);

  // create info for XML
  NewInfo := TEditOptLanguageInfo.Create;
  with NewInfo do
  begin
    TheType := lshXML;
    DefaultCommentType := DefaultCommentTypes[TheType];
    SynClass := LazSyntaxHighlighterClasses[TheType];
    SetBothFilextensions('xml;xsd;xsl;xslt;dtd;lpi;lps;lpk');
    SampleSource :=
      '<?xml version="1.0"?>'#13 + '<!DOCTYPE root ['#13 +
      '  ]>'#13 + '<!-- Comment -->'#13 + '<root version="&test;">'#13 +
      '  <![CDATA[ **CDATA section** ]]>'#13 + '</root>'#13 +
      '<!-- Text Block -->'#13 + ''#13 + #13;
    AddAttrSampleLines[ahaTextBlock] := 8;
    MappedAttributes := TStringList.Create;
    with MappedAttributes do
    begin
      Add('Element=Reserved_word');
      Add('Comment=Comment');
      Add('Text=Identifier');
      Add('Space=Space');
      Add('Symbol=Symbol');
    end;
    CaretXY := Point(1,1);
  end;
  Add(NewInfo);

  // create info for LFM
  NewInfo := TEditOptLanguageInfo.Create;
  with NewInfo do
  begin
    TheType := lshLFM;
    DefaultCommentType := DefaultCommentTypes[TheType];
    SynClass := LazSyntaxHighlighterClasses[TheType];
    SetBothFilextensions('lfm;dfm;xfm');
    SampleSource :=
      '{ Lazarus Form Definitions }'#13 + 'object TestForm: TTestForm'#13 +
      '  Left = 273'#13 + '  Top = 103'#13 +
      '  Caption = ''sample source'''#13 + 'end'#13 +
      '{ Text Block }'#13 + ''#13 + #13;
    AddAttrSampleLines[ahaTextBlock] := 7;
    MappedAttributes := TStringList.Create;
    with MappedAttributes do
    begin
      Add('Element=Reserved_word');
      Add('Comment=Comment');
      Add('Identifier=Identifier');
      Add('Key=Reserved_word');
      Add('Number=Number');
      Add('Space=Space');
      Add('String=String');
      Add('Symbol=Symbol');
    end;
    CaretXY := Point(1,1);
  end;
  Add(NewInfo);

  // create info for Perl
  NewInfo := TEditOptLanguageInfo.Create;
  with NewInfo do
  begin
    TheType := lshPerl;
    DefaultCommentType := DefaultCommentTypes[TheType];
    SynClass := LazSyntaxHighlighterClasses[TheType];
    SetBothFilextensions('pl;pm;cgi');
    SampleSource :=
      '#!/usr/bin/perl'#13 + '# Perl sample code'#13 +
      ''#13 + '$i = "10";'#13 + 'print "$ENV{PATH}\n";'#13 +
      '($i =~ /\d+/) || die "Error\n";'#13 + ''#13 +
      '# Text Block'#13 + ''#13 + #13;
    AddAttrSampleLines[ahaTextBlock] := 8;
    MappedAttributes := TStringList.Create;
    with MappedAttributes do
    begin
      Add('Comment=Comment');
      Add('Identifier=Identifier');
      Add('KeyAttri=Reserved_word');
      Add('NumberAttri=Number');
      Add('SpaceAttri=Space');
      Add('StringAttri=String');
      Add('Symbol=Symbol');
    end;
    CaretXY := Point(1,1);
  end;
  Add(NewInfo);

  // create info for Java
  NewInfo := TEditOptLanguageInfo.Create;
  with NewInfo do
  begin
    TheType := lshJava;
    DefaultCommentType := DefaultCommentTypes[TheType];
    SynClass := LazSyntaxHighlighterClasses[TheType];
    SetBothFilextensions('java');
    SampleSource :=
      '/* Java syntax highlighting */'#13#10 +
      'import java.util.*;'#13#10 + #13#10 +
      '/** Example class */'#13#10 +
      'public class Sample {'#13#10 +
      '  public static void main(String[] args) {'#13#10 +
      '    int i = 0;'#13#10 +
      '    for(i = 0; i < 10; i++)'#13#10 +
      '      System.out.println("Hello world");'#13#10 +
      '  }'#13#10 + '}'#13#10 +
      '/* Text Block */'#13#10 + #13#10;
    AddAttrSampleLines[ahaTextBlock] := 12;
    MappedAttributes := TStringList.Create;
    with MappedAttributes do
    begin
      Add('Comment=Comment');
      Add('Documentation=Comment');
      Add('Identifier=Identifier');
      Add('Reserved_word=Reserved_word');
      Add('Number=Number');
      Add('Space=Space');
      Add('String=String');
      Add('Symbol=Symbol');
    end;
    CaretXY := Point(1,1);
  end;
  Add(NewInfo);

  // create info for Bash
  NewInfo := TEditOptLanguageInfo.Create;
  with NewInfo do
  begin
    TheType := lshBash;
    DefaultCommentType := DefaultCommentTypes[TheType];
    SynClass := LazSyntaxHighlighterClasses[TheType];
    SetBothFilextensions('sh');
    SampleSource :=
      '#!/bin/bash'#13#13 +
      '# Bash syntax highlighting'#13#10 + 'set -x'#13#10 +
      'set -e'#13#10 +
      'Usage="Usage: $0 devel|stable"'#13#10 +
      'FPCVersion=$1'#13#10 +
      'for ver in devel stable; do'#13#10 +
      '  if [ "x$FPCVersion" = "x$ver" ]; then'#13#10 +
      '  fi'#13#10 + 'done'#13#10 +
      '# Text Block'#13#10 + #13#10;
    AddAttrSampleLines[ahaTextBlock] := 12;
    MappedAttributes := TStringList.Create;
    with MappedAttributes do
    begin
      Add('Comment=Comment');
      Add('Variable=Identifier');
      Add('Key=Reserved_word');
      Add('Number=Number');
      Add('Space=Space');
      Add('String=String');
      Add('Symbol=Symbol');
    end;
    CaretXY := Point(1,1);
  end;
  Add(NewInfo);

  // create info for Python
  NewInfo := TEditOptLanguageInfo.Create;
  with NewInfo do
  begin
    TheType := lshPython;
    DefaultCommentType := DefaultCommentTypes[TheType];
    SynClass := LazSyntaxHighlighterClasses[TheType];
    SetBothFilextensions('py');
    SampleSource :=
      '# Python syntax highlighting'#13#10 +
      'import math'#13#10 + #13#10 +
      '""" Documentation """'#13#10 +
      'def DoSomething(Liste1,Liste2,param3=3):'#13#10 +
      '  for i in Liste1:'#13#10 +
      '    if i in Liste2:'#13#10 +
      '      Liste1.remove(i)'#13#10 +
      '/* Text Block */'#13#10 + #13#10;
    AddAttrSampleLines[ahaTextBlock] := 9;
    MappedAttributes := TStringList.Create;
    with MappedAttributes do
    begin
      Add('Comment=Comment');
      Add('Identifier=Identifier');
      Add('Documentation=Comment');
      Add('Reserved_word=Reserved_word');
      Add('Number=Number');
      Add('Space=Space');
      Add('String=String');
      Add('Symbol=Symbol');
    end;
    CaretXY := Point(1,1);
  end;
  Add(NewInfo);

  // create info for PHP
  NewInfo := TEditOptLanguageInfo.Create;
  with NewInfo do
  begin
    TheType := lshPHP;
    DefaultCommentType := DefaultCommentTypes[TheType];
    SynClass := LazSyntaxHighlighterClasses[TheType];
    SetBothFilextensions('php;php3;php4');
    SampleSource :=
      '<?if ( ($HTTP_HOST == "www.lazarus.com") || ($HTTP_HOST == "lazarus.com") ){'#10 + '   HEADER("Location:http://www.lazarus.freepascal.org/\n\n");'#10
      + '};'#10 + '?>'#10 + #10;
    AddAttrSampleLines[ahaTextBlock] := 8;
    MappedAttributes := TStringList.Create;
    with MappedAttributes do
    begin
      Add('Element=Reserved_word');
      Add('Comment=Comment');
      Add('Variable=Identifier');
      Add('Space=Space');
      Add('Symbol=Symbol');
      Add('Number=Number');
      Add('Key=Key');
      Add('String=String');
    end;
    CaretXY := Point(1,1);
  end;
  Add(NewInfo);

  // create info for SQL
  NewInfo := TEditOptLanguageInfo.Create;
  with NewInfo do
  begin
    TheType := lshSQL;
    DefaultCommentType := DefaultCommentTypes[TheType];
    SynClass := LazSyntaxHighlighterClasses[TheType];
    SetBothFilextensions('sql');
    SampleSource :=
      '-- ansi sql sample source'#10 +
        'select name , region'#10 +
        'from cia'#10 +
        'where area < 2000'#10 +
        'and gdp > 5000000000'#10 + #10;
    AddAttrSampleLines[ahaTextBlock] := 4;
    MappedAttributes := TStringList.Create;
    with MappedAttributes do
    begin
      Add('Comment=Comment');
      Add('Element=Reserved_word');
      Add('Variable=Identifier');
      Add('Space=Space');
      Add('Symbol=Symbol');
      Add('Number=Number');
      Add('Key=Key');
      Add('String=String');
    end;
    CaretXY := Point(1,1);
  end;
  Add(NewInfo);

  // create info for JScript
  NewInfo := TEditOptLanguageInfo.Create;
  with NewInfo do
  begin
    TheType := lshJScript;
    DefaultCommentType := DefaultCommentTypes[TheType];
    SynClass := LazSyntaxHighlighterClasses[TheType];
    SetBothFilextensions('js');
    SampleSource :=
      '/* JScript */'#13#10 +
      '/* To be written ... /*'#13#10 + #13#10 +
      '/* Text Block */'#13#10 + #13#10;
    AddAttrSampleLines[ahaTextBlock] := 2;
    MappedAttributes := TStringList.Create;
    with MappedAttributes do
    begin
      Add('Comment=Comment');
      Add('Documentation=Comment');
      Add('Identifier=Identifier');
      Add('Reserved_word=Reserved_word');
      Add('Number=Number');
      Add('Space=Space');
      Add('String=String');
      Add('Symbol=Symbol');
    end;
    CaretXY := Point(1,1);
  end;
  Add(NewInfo);
end;

destructor TEditOptLangList.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TEditOptLangList.FindByName(const Name: String): Integer;
begin
  Result := Count - 1;
  while (Result >= 0) and (AnsiCompareText(
      Items[Result].SynClass.GetLanguageName, Name) <> 0) do
    dec(Result);
end;

function TEditOptLangList.FindByClass(
  CustomSynClass: TCustomSynClass): Integer;
begin
  Result := Count - 1;
  while (Result >= 0) and (Items[Result].SynClass <> CustomSynClass) do
    dec(Result);
end;

function TEditOptLangList.FindByHighlighter(Hilighter:
  TSynCustomHighlighter): Integer;
begin
  if Hilighter <> Nil then
    Result := FindByClass(TCustomSynClass(Hilighter.ClassType))
  else
    Result := -1;
end;

function TEditOptLangList.FindByType(AType: TLazSyntaxHighlighter): Integer;
begin
  AType := CompatibleLazSyntaxHilighter[AType];
  Result := Count - 1;
  while (Result >= 0) and (Items[Result].TheType <> AType) do
    dec(Result);
end;

function TEditOptLangList.GetDefaultFilextension(
  AType: TLazSyntaxHighlighter): String;
var
  i: Integer;
begin
  i := FindByType(AType);
  if i >= 0 then
    Result := Items[i].GetDefaultFilextension
  else
    Result := '';
end;

function TEditOptLangList.GetInfoByType(AType: TLazSyntaxHighlighter
  ): TEditOptLanguageInfo;
var
  i: LongInt;
begin
  i:=FindByType(AType);
  if i>=0 then
    Result:=Items[i]
  else
    Result:=nil;
end;

{ TEditorOptions }

constructor TEditorOptions.Create;
var
  ConfFileName: String;
  fs: TFileStream;
  res: TLResource;
begin
  inherited Create;
  ConfFileName := SetDirSeparators(GetPrimaryConfigPath + '/' +
    EditOptsConfFileName);
  CopySecondaryConfigFile(EditOptsConfFileName);
  try
    if (not FileExistsUTF8(ConfFileName)) then
    begin
      DebugLn('NOTE: editor options config file not found - using defaults');
      XMLConfig := TXMLConfig.CreateClean(ConfFileName);
    end
    else
      XMLConfig := TXMLConfig.Create(ConfFileName);
  except
    on E: Exception do
    begin
      DebugLn('WARNING: unable to read ', ConfFileName, ' ', E.Message);
      XMLConfig := Nil;
    end;
  end;

  // set defaults

  // General options
  fCtrlMouseLinks := True;
  fShowTabCloseButtons := True;
  FCopyWordAtCursorOnCopyNone := True;
  FShowGutterHints := True;
  fBlockIndent := 2;
  fUndoLimit := 32767;
  fTabWidth := 8;

  // Display options
  fEditorFont := SynDefaultFontName;
  fEditorFontHeight := SynDefaultFontHeight;
  fDisableAntialiasing := True;

  // Key Mappings
  fKeyMappingScheme := KeyMapSchemeNames[kmsLazarus];
  fKeyMap := TKeyCommandRelationList.Create;

  // Color options
  fHighlighterList := TEditOptLangList.Create;

  // Code Tools options
  fCodeTemplateFileName := SetDirSeparators(GetPrimaryConfigPath + '/lazarus.dci');
  CopySecondaryConfigFile('lazarus.dci');
  if not FileExistsUTF8(fCodeTemplateFileName) then
  begin
    res := LazarusResources.Find('lazarus_dci_file');
    if (res <> Nil) and (res.Value <> '') and (res.ValueType = 'DCI') then
      try
        InvalidateFileStateCache;
        fs := TFileStream.Create(UTF8ToSys(fCodeTemplateFileName), fmCreate);
        try
          fs.Write(res.Value[1], length(res.Value));
        finally
          fs.Free;
        end;
      except
        DebugLn('WARNING: unable to write code template file "',
          fCodeTemplateFileName, '"');
      end;
  end;
  
  // Code Folding
  FCFDividerDrawLevel := 3;
end;

destructor TEditorOptions.Destroy;
begin
  fHighlighterList.Free;
  fKeyMap.Free;
  XMLConfig.Free;
  inherited Destroy;
end;

procedure TEditorOptions.Load;
// load options from XML file
var
  SynEditOpt: TSynEditorOption;
  SynEditOptName: String;
  i: Integer;
  SynEditOpt2: TSynEditorOption2;
  FileVersion: LongInt;
begin
  try
    FileVersion:=XMLConfig.GetValue('EditorOptions/Version', 0);

    // general options
    for SynEditOpt := Low(TSynEditorOption) to High(TSynEditorOption) do
    begin
      SynEditOptName := GetSynEditOptionName(SynEditOpt);
      if SynEditOptName <> '' then
        if XMLConfig.GetValue('EditorOptions/General/Editor/' + SynEditOptName,
          SynEditOpt in SynEditDefaultOptions) then
          Include(fSynEditOptions, SynEditOpt)
        else
          Exclude(fSynEditOptions, SynEditOpt);
    end;
    for SynEditOpt2 := Low(TSynEditorOption2) to High(TSynEditorOption2) do
    begin
      case SynEditOpt2 of
        eoCaretSkipsSelection:
          SynEditOptName := 'CaretSkipsSelection';
        eoAlwaysVisibleCaret:
          SynEditOptName := 'AlwaysVisibleCaret';
        else
          SynEditOptName := '';
      end;
      if SynEditOptName <> '' then
        if XMLConfig.GetValue('EditorOptions/General/Editor/' + SynEditOptName,
          SynEditOpt2 in SynEditDefaultOptions2) then
          Include(fSynEditOptions2, SynEditOpt2)
        else
          Exclude(fSynEditOptions2, SynEditOpt2);
    end;

    fCtrlMouseLinks :=
      XMLConfig.GetValue('EditorOptions/General/Editor/CtrlMouseLinks', True);
    fShowTabCloseButtons :=
      XMLConfig.GetValue(
      'EditorOptions/General/Editor/ShowTabCloseButtons', True);
    FCopyWordAtCursorOnCopyNone :=
      XMLConfig.GetValue(
      'EditorOptions/General/Editor/CopyWordAtCursorOnCopyNone', True);
    FShowGutterHints :=
      XMLConfig.GetValue('EditorOptions/General/Editor/ShowGutterHints', True);
    fUndoAfterSave :=
      XMLConfig.GetValue('EditorOptions/General/Editor/UndoAfterSave', True);
    fFindTextAtCursor :=
      XMLConfig.GetValue('EditorOptions/General/Editor/FindTextAtCursor', True);
    fUseSyntaxHighlight :=
      XMLConfig.GetValue(
      'EditorOptions/General/Editor/UseSyntaxHighlight', True);
    fBlockIndent :=
      XMLConfig.GetValue('EditorOptions/General/Editor/BlockIndent', 2);
    fUndoLimit :=
      XMLConfig.GetValue('EditorOptions/General/Editor/UndoLimit', 32767);
    fTabWidth :=
      XMLConfig.GetValue('EditorOptions/General/Editor/TabWidth', 8);

    // Display options
    fVisibleRightMargin :=
      XMLConfig.GetValue('EditorOptions/Display/VisibleRightMargin', True);
    fVisibleGutter :=
      XMLConfig.GetValue('EditorOptions/Display/VisibleGutter', True);
    if (FileVersion>0) and (FileVersion<4) then begin
      fShowLineNumbers :=
        XMLConfig.GetValue('EditorOptions/Display/ShowLineNumbers', False);
      fShowOnlyLineNumbersMultiplesOf :=
        XMLConfig.GetValue('EditorOptions/Display/ShowOnlyLineNumbersMultiplesOf', 1);
    end else begin
      fShowLineNumbers :=
        XMLConfig.GetValue('EditorOptions/Display/ShowLineNumbers', True);
      fShowOnlyLineNumbersMultiplesOf :=
        XMLConfig.GetValue('EditorOptions/Display/ShowOnlyLineNumbersMultiplesOf', 5);
    end;
    fGutterColor :=
      XMLConfig.GetValue('EditorOptions/Display/GutterColor', clBtnFace);
    fGutterWidth :=
      XMLConfig.GetValue('EditorOptions/Display/GutterWidth', 30);
    fRightMargin :=
      XMLConfig.GetValue('EditorOptions/Display/RightMargin', 80);
    fRightMarginColor :=
      XMLConfig.GetValue('EditorOptions/Display/RightMarginColor'
      , clBtnFace);
    fEditorFont  :=
      XMLConfig.GetValue('EditorOptions/Display/EditorFont', SynDefaultFontName);
    fEditorFontHeight :=
      XMLConfig.GetValue('EditorOptions/Display/EditorFontHeight',
      SynDefaultFontHeight);
    RepairEditorFontHeight(fEditorFontHeight);
    fExtraCharSpacing :=
      XMLConfig.GetValue('EditorOptions/Display/ExtraCharSpacing', 0);
    fExtraLineSpacing :=
      XMLConfig.GetValue('EditorOptions/Display/ExtraLineSpacing', 1);
    fDisableAntialiasing :=
      XMLConfig.GetValue('EditorOptions/Display/DisableAntialiasing', True);
    FDoNotWarnForFont :=
      XMLConfig.GetValue('EditorOptions/Display/DoNotWarnForFont', '');

    // Key Mappings options
    fKeyMappingScheme :=
      XMLConfig.GetValue('EditorOptions/KeyMapping/Scheme',
      StrToValidXMLName(KeyMapSchemeNames[kmsLazarus]));
    fKeyMap.LoadFromXMLConfig(XMLConfig
      , 'EditorOptions/KeyMapping/' + fKeyMappingScheme + '/');

    // Color options
    for i := 0 to fHighlighterList.Count - 1 do
      fHighlighterList[i].FileExtensions :=
        XMLConfig.GetValue('EditorOptions/Color/Lang' +
        StrToValidXMLName(fHighlighterList[i].SynClass.GetLanguageName) +
        '/FileExtensions/Value', fHighlighterList[i].DefaultFileExtensions)
      // color attributes are stored in the highlighters
    ;

    // Code Tools options
    fAutoIdentifierCompletion :=
      XMLConfig.GetValue(
      'EditorOptions/CodeTools/AutoIdentifierCompletion', True);
    fAutoCodeParameters :=
      XMLConfig.GetValue('EditorOptions/CodeTools/AutoCodeParameters', True);
    fAutoToolTipExprEval :=
      XMLConfig.GetValue('EditorOptions/CodeTools/AutoToolTipExprEval', True);
    fAutoToolTipSymbTools :=
      XMLConfig.GetValue('EditorOptions/CodeTools/AutoToolTipSymbTools', True);
    fAutoDelayInMSec    :=
      XMLConfig.GetValue('EditorOptions/CodeTools/AutoDelayInMSec', 1000);
    fCodeTemplateFileName :=
      XMLConfig.GetValue('EditorOptions/CodeTools/CodeTemplateFileName'
      , SetDirSeparators(GetPrimaryConfigPath + '/lazarus.dci'));
    fCTemplIndentToTokenStart :=
      XMLConfig.GetValue(
      'EditorOptions/CodeTools/CodeTemplateIndentToTokenStart/Value', False);

    // Code Folding
    FUseCodeFolding :=
      XMLConfig.GetValue(
      'EditorOptions/CodeFolding/UseCodeFolding', True);
    FCFDividerDrawLevel :=
      XMLConfig.GetValue('EditorOptions/CodeFolding/DividerDrawLevel', 3);
  except
    on E: Exception do
      DebugLn('[TEditorOptions.Load] ERROR: ', e.Message);
  end;
end;

procedure TEditorOptions.Save;
// save options to XML file
var
  SynEditOpt: TSynEditorOption;
  SynEditOptName: String;
  i: Integer;
  SynEditOpt2: TSynEditorOption2;
begin
  try
    XMLConfig.SetValue('EditorOptions/Version', EditorOptsFormatVersion);

    // general options
    for SynEditOpt := Low(TSynEditorOption) to High(TSynEditorOption) do
    begin
      SynEditOptName := GetSynEditOptionName(SynEditOpt);
      if SynEditOptName <> '' then
        XMLConfig.SetDeleteValue('EditorOptions/General/Editor/' + SynEditOptName,
          SynEditOpt in fSynEditOptions, SynEditOpt in SynEditDefaultOptions);
    end;
    // general options
    for SynEditOpt2 := Low(TSynEditorOption2) to High(TSynEditorOption2) do
    begin
      case SynEditOpt2 of
        eoCaretSkipsSelection:
          SynEditOptName := 'CaretSkipsSelection';
        eoAlwaysVisibleCaret:
          SynEditOptName := 'AlwaysVisibleCaret';
        else
          SynEditOptName := '';
      end;
      if SynEditOptName <> '' then
        XMLConfig.SetDeleteValue('EditorOptions/General/Editor/' + SynEditOptName,
          SynEditOpt2 in fSynEditOptions2, SynEditOpt2 in SynEditDefaultOptions2);
    end;

    XMLConfig.SetDeleteValue('EditorOptions/General/Editor/CtrlMouseLinks'
      , fCtrlMouseLinks, True);
    XMLConfig.SetDeleteValue('EditorOptions/General/Editor/ShowTabCloseButtons'
      , fShowTabCloseButtons, True);
    XMLConfig.SetDeleteValue(
      'EditorOptions/General/Editor/CopyWordAtCursorOnCopyNone',
      FCopyWordAtCursorOnCopyNone, True);
    XMLConfig.SetDeleteValue(
      'EditorOptions/General/Editor/ShowGutterHints',
      FShowGutterHints, True);
    XMLConfig.SetDeleteValue('EditorOptions/General/Editor/UndoAfterSave'
      , fUndoAfterSave, True);
    XMLConfig.SetDeleteValue('EditorOptions/General/Editor/FindTextAtCursor'
      , fFindTextAtCursor, True);
    XMLConfig.SetDeleteValue('EditorOptions/General/Editor/UseSyntaxHighlight'
      , fUseSyntaxHighlight, True);
    XMLConfig.SetDeleteValue('EditorOptions/General/Editor/BlockIndent'
      , fBlockIndent, 2);
    XMLConfig.SetDeleteValue('EditorOptions/General/Editor/UndoLimit'
      , fUndoLimit, 32767);
    XMLConfig.SetDeleteValue('EditorOptions/General/Editor/TabWidth'
      , fTabWidth, 8);

    // Display options
    XMLConfig.SetDeleteValue('EditorOptions/Display/VisibleRightMargin'
      , fVisibleRightMargin, True);
    XMLConfig.SetDeleteValue('EditorOptions/Display/VisibleGutter',
      fVisibleGutter, True);
    XMLConfig.SetDeleteValue('EditorOptions/Display/ShowLineNumbers',
      fShowLineNumbers, True);
    XMLConfig.SetDeleteValue('EditorOptions/Display/ShowOnlyLineNumbersMultiplesOf',
      fShowOnlyLineNumbersMultiplesOf, 5);
    XMLConfig.SetDeleteValue('EditorOptions/Display/GutterColor',
      fGutterColor, clBtnFace);
    XMLConfig.SetDeleteValue('EditorOptions/Display/GutterWidth',
      fGutterWidth, 30);
    XMLConfig.SetDeleteValue('EditorOptions/Display/RightMargin',
      fRightMargin, 80);
    XMLConfig.SetDeleteValue('EditorOptions/Display/RightMarginColor',
      fRightMarginColor, clBtnFace);
    XMLConfig.SetDeleteValue('EditorOptions/Display/EditorFont',
      fEditorFont, SynDefaultFontName);
    XMLConfig.SetDeleteValue('EditorOptions/Display/EditorFontHeight'
      ,fEditorFontHeight, SynDefaultFontHeight);
    XMLConfig.SetDeleteValue('EditorOptions/Display/ExtraCharSpacing'
      ,fExtraCharSpacing, 1);
    XMLConfig.SetDeleteValue('EditorOptions/Display/ExtraLineSpacing'
      ,fExtraLineSpacing, 1);
    XMLConfig.SetDeleteValue('EditorOptions/Display/DisableAntialiasing'
      ,fDisableAntialiasing, True);
    XMLConfig.SetDeleteValue('EditorOptions/Display/DoNotWarnForFont'
      ,FDoNotWarnForFont, '');

    // Key Mappings options
    XMLConfig.SetDeleteValue('EditorOptions/KeyMapping/Scheme', fKeyMappingScheme,
       KeyMapSchemeNames[kmsLazarus]);
    fKeyMap.SaveToXMLConfig(
              XMLConfig, 'EditorOptions/KeyMapping/' + fKeyMappingScheme + '/');

    // Color options
    for i := 0 to fHighlighterList.Count - 1 do
      XMLConfig.SetDeleteValue('EditorOptions/Color/Lang' +
        StrToValidXMLName(fHighlighterList[i].SynClass.GetLanguageName) +
        '/FileExtensions/Value', fHighlighterList[i].FileExtensions,
        fHighlighterList[i].DefaultFileExtensions)
      // color attributes are stored in the highlighters
    ;

    // Code Tools options
    XMLConfig.SetDeleteValue('EditorOptions/CodeTools/AutoIdentifierCompletion'
      , fAutoIdentifierCompletion, True);
    XMLConfig.SetDeleteValue('EditorOptions/CodeTools/AutoCodeParameters'
      , fAutoCodeParameters, True);
    XMLConfig.SetDeleteValue('EditorOptions/CodeTools/AutoToolTipExprEval'
      , fAutoToolTipExprEval, True);
    XMLConfig.SetDeleteValue('EditorOptions/CodeTools/AutoToolTipSymbTools'
      , fAutoToolTipSymbTools, True);
    XMLConfig.SetDeleteValue('EditorOptions/CodeTools/AutoDelayInMSec'
      , fAutoDelayInMSec, 1000);
    XMLConfig.SetDeleteValue('EditorOptions/CodeTools/CodeTemplateFileName'
      , fCodeTemplateFileName, '');
    XMLConfig.SetDeleteValue(
      'EditorOptions/CodeTools/CodeTemplateIndentToTokenStart/Value'
      , fCTemplIndentToTokenStart, False);

    // Code Folding
    XMLConfig.SetDeleteValue('EditorOptions/CodeFolding/UseCodeFolding',
        FUseCodeFolding, True);
    XMLConfig.SetDeleteValue('EditorOptions/CodeFolding/DividerDrawLevel',
        FCFDividerDrawLevel, 3);

    InvalidateFileStateCache;
    XMLConfig.Flush;
  except
    on E: Exception do
      DebugLn('[TEditorOptions.Save] ERROR: ', e.Message);
  end;
end;

function TEditorOptions.GetSynEditOptionName(SynOption: TSynEditorOption
  ): string;
begin
  case SynOption of
    eoAltSetsColumnMode:
      Result := 'AltSetsColumnMode';
    eoAutoIndent:
      Result := 'AutoIndent';
    eoBracketHighlight:
      Result := 'BracketHighlight';
    eoDoubleClickSelectsLine:
      Result := 'DoubleClickSelectsLine';
    eoDragDropEditing:
      Result := 'DragDropEditing';
    eoDropFiles:
      Result := 'DropFiles';
    eoEnhanceHomeKey:
      Result := 'EnhanceHomeKey';
    eoGroupUndo:
      Result := 'GroupUndo';
    eoHalfPageScroll:
      Result := 'HalfPageScroll';
    eoKeepCaretX:
      Result := 'KeepCaretX';
    eoPersistentCaret:
      Result := 'PersistentCaret';
    eoScrollByOneLess:
      Result := 'ScrollByOneLess';
    eoScrollPastEof:
      Result := 'ScrollPastEof';
    eoScrollPastEol:
      Result := 'ScrollPastEol';
    eoShowScrollHint:
      Result := 'ShowScrollHint';
    eoShowSpecialChars:
      Result := 'ShowSpecialChars';
    eoSmartTabs:
      Result := 'SmartTabs';
    eoTabsToSpaces:
      Result := 'TabsToSpaces';
    eoTabIndent:
      Result := 'TabIndent';
    eoTrimTrailingSpaces:
      Result := 'TrimTrailingSpaces';
    else
      Result := '';
  end;
end;

function TEditorOptions.CreateSyn(LazSynHilighter: TLazSyntaxHighlighter):
TSrcIDEHighlighter;
begin
  if LazSyntaxHighlighterClasses[LazSynHilighter] <> Nil then
  begin
    Result := LazSyntaxHighlighterClasses[LazSynHilighter].Create(Nil);
    AddSpecialHilightAttribsToHighlighter(Result);
    GetHighlighterSettings(Result);
  end
  else
    Result := Nil;
end;

function TEditorOptions.ReadColorScheme(const LanguageName: String): String;
begin
  if LanguageName = '' then
  begin
    Result := DEFAULT_COLOR_SCHEME.Name;
    exit;
  end;
  if LanguageName <> TPreviewPasSyn.GetLanguageName then
    Result := XMLConfig.GetValue(
      'EditorOptions/Color/Lang' + StrToValidXMLName(LanguageName) +
      '/ColorScheme/Value', '')
  else
    Result := '';
  if Result = '' then
    Result := ReadPascalColorScheme;
end;

function TEditorOptions.ReadPascalColorScheme: String;
var
  FormatVersion: Integer;
begin
  FormatVersion := XMLConfig.GetValue('EditorOptions/Color/Version', 0);
  if FormatVersion > 1 then
    Result := XMLConfig.GetValue(
      'EditorOptions/Color/Lang' + StrToValidXMLName(
      TPreviewPasSyn.GetLanguageName) + '/ColorScheme/Value', '')
  else
    Result := XMLConfig.GetValue('EditorOptions/Color/ColorScheme', '');
  if Result = '' then
    Result := DEFAULT_COLOR_SCHEME.Name;
end;

procedure TEditorOptions.WriteColorScheme(
  const LanguageName, SynColorScheme: String);
begin
  if (LanguageName = '') or (SynColorScheme = '') then
    exit;
  XMLConfig.SetValue('EditorOptions/Color/Lang' + StrToValidXMLName(
    LanguageName) + '/ColorScheme/Value', SynColorScheme);
  XMLConfig.SetValue('EditorOptions/Color/Version', EditorOptsFormatVersion);
end;

procedure TEditorOptions.GetDefaultsForPascalAttribute(
  Attr: TSynHighlightElement; const SynColorScheme: String);
var
  AttriName: String;
  Scheme: TPascalColorScheme;
  pha: TPascalHilightAttribute;
  aha: TAdditionalHilightAttribute;
begin
  AttriName := LowerCase(Attr.Name);
  if AttriName = '' then
    exit;

  case StringCase(SynColorScheme, [
    TWILIGHT_COLOR_SCHEME.Name,
    CLASSIC_COLOR_SCHEME.Name,
    OCEAN_COLOR_SCHEME.Name,
    DELPHI_COLOR_SCHEME.Name
  ], True, False) of
    0: Scheme := TWILIGHT_COLOR_SCHEME;
    1: Scheme := CLASSIC_COLOR_SCHEME;
    2: Scheme := OCEAN_COLOR_SCHEME;
    3: Scheme := DELPHI_COLOR_SCHEME;
  else
    Scheme := DEFAULT_COLOR_SCHEME;
  end;

  for pha := low(pha) to High(pha) do
  begin
    if AttriName <> LowerCase(PascalHilightAttributeNames[pha]) then Continue;
    if Scheme.Attributes[pha].FG = clNone
    then Attr.Foreground := Scheme.Default.FG
    else Attr.Foreground := Scheme.Attributes[pha].FG;
    if Scheme.Attributes[pha].BG = clNone
    then Attr.Background := Scheme.Default.BG
    else Attr.Background := Scheme.Attributes[pha].BG;
    //DebugLn(['TEditorOptions.GetDefaultsForPascalAttribute SynColorScheme=',SynColorScheme,' AttriName=',AttriName,' BG=',ColorToString(Scheme.Attributes[pha].BG),' Background=',ColorToString(Attr.Background),' SchemeBG=',ColorToString(Scheme.Default.BG)]);
    Attr.Style := Scheme.Attributes[pha].Styles;
    Attr.StyleMask := Scheme.Attributes[pha].StylesMask;
    Exit;
  end;
  
  for aha := low(aha) to High(aha) do
  begin
    if AttriName <> LowerCase(AdditionalHighlightAttributes[aha]) then Continue;
    if Scheme.Additional[aha].FG = clNone
    then Attr.Foreground := Scheme.Default.FG
    else Attr.Foreground := Scheme.Additional[aha].FG;
    if Scheme.Additional[aha].BG = clNone
    then Attr.Background := Scheme.Default.BG
    else Attr.Background := Scheme.Additional[aha].BG;
    Attr.Style := Scheme.Additional[aha].Styles;
    Attr.StyleMask := Scheme.Additional[aha].StylesMask;
    Exit;
  end;
  
  Attr.Foreground := Scheme.Default.FG;
  Attr.Background := Scheme.Default.BG;
  Attr.Style := Scheme.Default.Styles;
  Attr.StyleMask := Scheme.Default.StylesMask;
end;

procedure TEditorOptions.ReadDefaultsForHighlighterSettings(Syn: TSrcIDEHighlighter;
  SynColorScheme: String; DefaultPascalSyn: TPreviewPasSyn);
// if SynColorScheme='' then default ColorScheme will be used
var
  VirginSyn, DefaultSyn: TSrcIDEHighlighter;
  i, j: Integer;
  MappedAttriName, AttriName: String;
  HilightInfo: TEditOptLanguageInfo;
  aha:  TAdditionalHilightAttribute;
  CustomPascalSyn: Boolean;
begin
  if SynColorScheme = '' then
    SynColorScheme := ReadColorScheme(Syn.LanguageName);
  if SynColorScheme = '' then
    exit;
  CustomPascalSyn := (DefaultPascalSyn <> Nil);
  if (Syn is TPreviewPasSyn) or (Syn is TSynPasSyn) then
  begin
    for i := 0 to Syn.AttrCount - 1 do
      GetDefaultsForPascalAttribute(Syn.Attribute[i], SynColorScheme);
    // the defaults for pascal are fix programmed
  end
  else
  begin
    // the defaults of all non pascal languages are the mapped current values of
    // pascal or the non mapped values of an untouched highlighter of the same
    // type
    i := HighlighterList.FindByClass(TCustomSynClass(Syn.ClassType));
    if i < 0 then
      exit;
    HilightInfo := HighlighterList[i];
    if not CustomPascalSyn then
      DefaultPascalSyn := TPreviewPasSyn.Create(Nil);
    VirginSyn := TCustomSynClass(Syn.ClassType).Create(Nil);
    try
      if not CustomPascalSyn then
      begin
        AddSpecialHilightAttribsToHighlighter(DefaultPascalSyn);
        ReadHighlighterSettings(DefaultPascalSyn, SynColorScheme);
      end;
      // map attributes
      for i := 0 to Syn.AttrCount - 1 do
      begin
        AttriName := StrToValidXMLName(Syn.Attribute[i].Name);
        if AttriName = '' then
          continue;
        // check, if there is a known mapping for this attribute
        if HilightInfo.MappedAttributes <> Nil then
          MappedAttriName :=
            HilightInfo.MappedAttributes.Values[AttriName]
        else
          MappedAttriName := '';
        if MappedAttriName = '' then
          for aha := Low(TAdditionalHilightAttribute)
            to High(TAdditionalHilightAttribute) do
            if AnsiCompareText(
              StrToValidXMLName(AdditionalHighlightAttributes[aha]), AttriName) =
              0 then
              MappedAttriName :=
                AttriName// all special line color attributes can be mapped 1:1
        ;
        if MappedAttriName <> '' then
          DefaultSyn := DefaultPascalSyn
        else
          DefaultSyn := VirginSyn;
        // read defaults
        j := DefaultSyn.AttrCount - 1;
        while (j >= 0) do
        begin
          if AnsiCompareText(StrToValidXMLName(DefaultSyn.Attribute[j].Name),
            MappedAttriName) = 0 then
          begin
            CopyHiLightAttributeValues(DefaultSyn.Attribute[j],
              Syn.Attribute[i]);
            break;
          end;
          dec(j);
        end;
      end;
    finally
      VirginSyn.Free;
      if not CustomPascalSyn then
        DefaultPascalSyn.Free;
    end;
  end;
end;

procedure TEditorOptions.ReadHighlighterSettings(Syn: TSrcIDEHighlighter;
  SynColorScheme: String);
// if SynColorScheme='' then default ColorScheme will be used
var
  FormatVersion: Integer;
  i: Integer;
  AttriName: String;
  Attri: TSynHighlightElement;
  b: Boolean;
  fs: TFontStyles;
  Path: String;
begin
  // initialize with defaults
  if SynColorScheme = '' then
    SynColorScheme := ReadColorScheme(Syn.LanguageName);
  //DebugLn(['TEditorOptions.ReadHighlighterSettings ',SynColorScheme,' Syn.ClassName=',Syn.ClassName]);
  if (SynColorScheme = '') or (Syn.LanguageName = '') then
    exit;
  ReadDefaultsForHighlighterSettings(Syn, SynColorScheme, Nil);
  // read settings, that are different from the defaults
  FormatVersion := XMLConfig.GetValue(
    'EditorOptions/Color/Lang' + StrToValidXMLName(Syn.LanguageName) +
    '/Version', 0);
  if FormatVersion > 1 then
    for i := 0 to Syn.AttrCount - 1 do
    begin
      Attri := Syn.Attribute[i];
      AttriName := StrToValidXMLName(Attri.Name);
      if AttriName = '' then
        continue;
      Path := 'EditorOptions/Color/Lang' + StrToValidXMLName(
        Syn.LanguageName) + '/Scheme' + StrToValidXMLName(
        SynColorScheme) + '/' + StrToValidXMLName(AttriName) + '/';
      Attri.BackGround := XMLConfig.GetValue(Path + 'BackgroundColor/Value',
        Attri.Background);
      Attri.ForeGround := XMLConfig.GetValue(Path + 'ForegroundColor/Value',
        Attri.Foreground);
      fs   := [];
      b    := XMLConfig.GetValue(Path + 'Style/Bold', fsBold in Attri.Style);
      if b then
        Include(fs, fsBold);
      b := XMLConfig.GetValue(Path + 'Style/Italic', fsItalic in Attri.Style);
      if b then
        Include(fs, fsItalic);
      b := XMLConfig.GetValue(Path + 'Style/Underline', fsUnderline in Attri.Style);
      if b then
        Include(fs, fsUnderline);
      Attri.Style := fs;
      fs   := [];
      b    := XMLConfig.GetValue(Path + 'StyleMask/Bold', fsBold in Attri.StyleMask);
      if b then
        Include(fs, fsBold);
      b := XMLConfig.GetValue(Path + 'StyleMask/Italic', fsItalic in Attri.StyleMask);
      if b then
        Include(fs, fsItalic);
      b := XMLConfig.GetValue(Path + 'StyleMask/Underline', fsUnderline in Attri.StyleMask);
      if b then
        Include(fs, fsUnderline);
      Attri.StyleMask := fs;
    end// read all attributes
  else
  if Syn is TPreviewPasSyn then
    for i := 0 to Syn.AttrCount - 1 do
    begin
      Attri := Syn.Attribute[i];
      AttriName := StrToValidXMLName(Attri.Name);
      if AttriName = '' then
        continue;
      Path := 'EditorOptions/Color/' + StrToValidXMLName(
        SynColorScheme) + '/' + StrToValidXMLName(AttriName) + '/';
      Attri.BackGround := XMLConfig.GetValue(Path + 'BackgroundColor',
        Attri.Background);
      Attri.ForeGround := XMLConfig.GetValue(Path + 'ForegroundColor',
        Attri.Foreground);
      fs   := [];
      b    := XMLConfig.GetValue(Path + 'Bold', fsBold in Attri.Style);
      if b then
        Include(fs, fsBold);
      b := XMLConfig.GetValue(Path + 'Italic', fsItalic in Attri.Style);
      if b then
        Include(fs, fsItalic);
      b := XMLConfig.GetValue(Path + 'Underline', fsUnderline in Attri.Style);
      if b then
        Include(fs, fsUnderline);
      Attri.Style := fs;
      Attri.StyleMask := [];
    end// FormatVersion < 2
       // the oldest format only supports pascal
  ;
end;

procedure TEditorOptions.WriteHighlighterSettings(Syn: TSrcIDEHighlighter;
  SynColorScheme: String);
var
  OldSyn: TSrcIDEHighlighter;
  i:      Integer;
  AttriName: String;
  Attri, OldAttri: TSynHighlightElement;
  Path:   String;
begin
  // read the old settings, compare and write only the differences
  if SynColorScheme = '' then
    SynColorScheme := ReadColorScheme(Syn.LanguageName);
  OldSyn := TCustomSynClass(Syn.ClassType).Create(Nil);
  try
    AddSpecialHilightAttribsToHighlighter(OldSyn);
    ReadHighlighterSettings(OldSyn, SynColorScheme);
    // write colorscheme
    XMLConfig.SetValue('EditorOptions/Color/Lang' +
      StrToValidXMLName(Syn.LanguageName) + '/Version',
      EditorOptsFormatVersion);
    // write all attributes
    for i := 0 to Syn.AttrCount - 1 do
    begin
      Attri := Syn.Attribute[i];
      OldAttri := OldSyn.Attribute[i];
      AttriName := StrToValidXMLName(Attri.Name);
      if AttriName = '' then
        continue;
      Path := 'EditorOptions/Color/Lang' + StrToValidXMLName(
        Syn.LanguageName) + '/Scheme' + StrToValidXMLName(
        SynColorScheme) + '/' + StrToValidXMLName(AttriName) + '/';
      if Attri.Background <> OldAttri.Background then
        XMLConfig.SetValue(Path + 'BackgroundColor/Value', Attri.Background);
      if Attri.Foreground <> OldAttri.Foreground then
        XMLConfig.SetValue(Path + 'ForegroundColor/Value', Attri.Foreground);
      if Attri.Style <> OldAttri.Style then
      begin
        XMLConfig.SetValue(Path + 'Style/Bold', fsBold in Attri.Style);
        XMLConfig.SetValue(Path + 'Style/Italic', fsItalic in Attri.Style);
        XMLConfig.SetValue(Path + 'Style/Underline', fsUnderline in Attri.Style);
      end;
      if Attri.StyleMask <> OldAttri.StyleMask then
      begin
        XMLConfig.SetValue(Path + 'StyleMask/Bold', fsBold in Attri.StyleMask);
        XMLConfig.SetValue(Path + 'StyleMask/Italic', fsItalic in Attri.StyleMask);
        XMLConfig.SetValue(Path + 'StyleMask/Underline', fsUnderline in Attri.StyleMask);
      end;
    end;
  finally
    OldSyn.Free;
  end;
end;

procedure TEditorOptions.GetHighlighterSettings(Syn: TSrcIDEHighlighter);
// read highlight settings from config file
begin
  ReadHighlighterSettings(Syn, '');
end;

procedure TEditorOptions.SetHighlighterSettings(Syn: TSrcIDEHighlighter);
// write highlight settings to config file
begin
  WriteHighlighterSettings(Syn, '');
end;

function TEditorOptions.GetLineColors(Syn: TSrcIDEHighlighter;
  AddHilightAttr: TAdditionalHilightAttribute;
  out FG, BG: TColor; out Styles, StylesMask: TFontStyles): Boolean;
var
  i: Integer;
  Attrib: TSynHighlighterAttributes;
begin
  if Syn <> nil
  then begin
    for i := 0 to Syn.AttrCount - 1 do
    begin
      Attrib := Syn.Attribute[i];
      if Attrib.Name = '' then Continue;
      if LowerCase(Attrib.Name) <> LowerCase(AdditionalHighlightAttributes[AddHilightAttr])
      then Continue;
      
      FG := Attrib.Foreground;
      BG := Attrib.Background;
      Styles := Attrib.Style;
      StylesMask := Attrib.StyleMask;
      Exit((FG <> clNone) or (BG <> clNone) or (Styles <> []) or (StylesMask <> []));
    end;
  end;
    
  // set default
  FG := DEFAULT_COLOR_SCHEME.Additional[AddHilightAttr].FG;
  BG := DEFAULT_COLOR_SCHEME.Additional[AddHilightAttr].BG;
  Styles := DEFAULT_COLOR_SCHEME.Additional[AddHilightAttr].Styles;
  StylesMask := DEFAULT_COLOR_SCHEME.Additional[AddHilightAttr].StylesMask;
  Result := True;
end;

procedure TEditorOptions.SetMarkupColors(Syn : TSrcIDEHighlighter; aSynEd : TSynEdit);
begin
  SetMarkupColor(aSynEd.Highlighter, ahaTextBlock, aSynEd.SelectedColor);
  SetMarkupColor(aSynEd.Highlighter, ahaIncrementalSearch, aSynEd.IncrementColor);
  SetMarkupColor(aSynEd.Highlighter, ahaHighlightAll, aSynEd.HighlightAllColor);
  SetMarkupColor(aSynEd.Highlighter, ahaBracketMatch, aSynEd.BracketMatchColor);
  SetMarkupColor(aSynEd.Highlighter, ahaMouseLink, aSynEd.MouseLinkColor);
  SetMarkupColor(aSynEd.Highlighter, ahaLineNumber, aSynEd.LineNumberColor);
end;

procedure TEditorOptions.SetMarkupColor(Syn : TSrcIDEHighlighter;
  AddHilightAttr : TAdditionalHilightAttribute; aMarkup : TSynSelectedColor);
var
  i: Integer;
  Attrib: TSynHighlighterAttributes;
begin
  if Syn <> nil
  then begin
    for i := 0 to Syn.AttrCount - 1 do
    begin
      Attrib := Syn.Attribute[i];
      if Attrib.Name = '' then Continue;
      if SysUtils.CompareText(Attrib.Name,AdditionalHighlightAttributes[AddHilightAttr])<>0
      then Continue;

      aMarkup.Foreground := Attrib.Foreground;
      aMarkup.Background := Attrib.Background;
      aMarkup.Style      := Attrib.Style;
      aMarkup.StyleMask  := Attrib.StyleMask;
      Exit;
    end;
  end;

  // set default
  aMarkup.Foreground := DEFAULT_COLOR_SCHEME.Additional[AddHilightAttr].FG;;
  aMarkup.Background := DEFAULT_COLOR_SCHEME.Additional[AddHilightAttr].BG;
  aMarkup.Style := DEFAULT_COLOR_SCHEME.Additional[AddHilightAttr].Styles;
  aMarkup.StyleMask := DEFAULT_COLOR_SCHEME.Additional[AddHilightAttr].StylesMask;
end;

procedure TEditorOptions.GetSynEditSettings(ASynEdit: TSynEdit);
// read synedit settings from config file
begin
  // general options
  ASynEdit.Options := fSynEditOptions;
  ASynEdit.Options2 := fSynEditOptions2;
  ASynEdit.BlockIndent := fBlockIndent;
  ASynEdit.TabWidth := fTabWidth;

  // Display options
  ASynEdit.Gutter.Visible := fVisibleGutter;
  ASynEdit.Gutter.ShowLineNumbers := fShowLineNumbers;
  ASynEdit.Gutter.AutoSize := true;
  ASynEdit.Gutter.ShowOnlyLineNumbersMultiplesOf := fShowOnlyLineNumbersMultiplesOf;

  //ASynEdit.Gutter.AutoSize:= fShowLineNumbers;
  if ASynEdit.Gutter.ShowCodeFolding<>FUseCodeFolding then begin
    ASynEdit.Gutter.ShowCodeFolding := FUseCodeFolding;
    if not FUseCodeFolding then
      ASynEdit.UnfoldAll;
  end;
  ASynEdit.Gutter.Color := fGutterColor;
  ASynEdit.Gutter.Width := fGutterWidth;
  ASynEdit.Gutter.LeftOffset := 2*11; // bookmark + breakpoint
  if fVisibleRightMargin then
    ASynEdit.RightEdge := fRightMargin
  else
    ASynEdit.RightEdge := 0;
  ASynEdit.RightEdgeColor := fRightMarginColor;
  ASynEdit.Font.Height := fEditorFontHeight;// set height before name for XLFD !
  ASynEdit.Font.Name := fEditorFont;
  if fDisableAntialiasing then
    ASynEdit.Font.Quality := fqNonAntialiased
  else
    ASynEdit.Font.Quality := fqDefault;
  //debugln(['TEditorOptions.GetSynEditSettings ',ASynEdit.font.height]);
  
  ASynEdit.ExtraCharSpacing := fExtraCharSpacing;
  ASynEdit.ExtraLineSpacing := fExtraLineSpacing;
  ASynEdit.MaxUndo := fUndoLimit;
  SetMarkupColors(ASynEdit.Highlighter, ASynEdit);

  // Code Folding
  ASynEdit.CFDividerDrawLevel := FCFDividerDrawLevel;

  KeyMap.AssignTo(ASynEdit.KeyStrokes, TSourceEditorWindowInterface);
end;

procedure TEditorOptions.SetSynEditSettings(ASynEdit: TSynEdit);
// copy settings from a synedit to the options
begin
  // general options
  fSynEditOptions := ASynEdit.Options;
  fSynEditOptions2 := ASynEdit.Options2;
  fBlockIndent := ASynEdit.BlockIndent;
  fTabWidth := ASynEdit.TabWidth;

  // Display options
  fVisibleGutter := ASynEdit.Gutter.Visible;
  fShowLineNumbers := ASynEdit.Gutter.ShowLineNumbers;
  fShowOnlyLineNumbersMultiplesOf := ASynEdit.Gutter.ShowOnlyLineNumbersMultiplesOf;
  FUseCodeFolding := ASynEdit.Gutter.ShowCodeFolding;
  fGutterColor   := ASynEdit.Gutter.Color;
  fGutterWidth   := ASynEdit.Gutter.Width;
  fVisibleRightMargin := ASynEdit.RightEdge>0;
  if fVisibleRightMargin then
    fRightMargin   := ASynEdit.RightEdge;
  fRightMarginColor := ASynEdit.RightEdgeColor;
  fEditorFont    := ASynEdit.Font.Name;
  fEditorFontHeight := ASynEdit.Font.Height;
  fExtraCharSpacing := ASynEdit.ExtraCharSpacing;
  fExtraLineSpacing := ASynEdit.ExtraLineSpacing;
  fDisableAntialiasing := (ASynEdit.Font.Quality = fqNonAntialiased);
  fUndoLimit     := ASynEdit.MaxUndo;
end;

procedure TEditorOptions.AddSpecialHilightAttribsToHighlighter(
  Syn: TSrcIDEHighlighter);
type
  THasSpecialAttribute = array[TAdditionalHilightAttribute] of Boolean;
var
  HasSpecialAttribute: THasSpecialAttribute;
  a: TAdditionalHilightAttribute;
  i: Integer;
begin
  for a := Low(TAdditionalHilightAttribute)
    to High(TAdditionalHilightAttribute) do
    HasSpecialAttribute[a] := False;
  for i := 0 to Syn.AttrCount - 1 do
    with Syn.Attribute[i] do
    begin
      if Name = '' then
        continue;
      for a := Low(TAdditionalHilightAttribute)
        to High(TAdditionalHilightAttribute) do
        if AdditionalHighlightAttributes[a] = Name then
          HasSpecialAttribute[a] := True;
    end;
  for a := Low(TAdditionalHilightAttribute)
    to High(TAdditionalHilightAttribute) do
    if not HasSpecialAttribute[a] then
      Syn.AddSpecialAttribute(AdditionalHighlightAttributes[a]);
end;

procedure TEditorOptions.GetSynEditPreviewSettings(APreviewEditor: TObject);
// read synedit setings from config file
var
  ASynEdit: TSynEdit;
begin
  if not (APreviewEditor is TSynEdit) then
    exit;
  ASynEdit := TSynEdit(APreviewEditor);
  
  // Get real settings
  GetSynEditSettings(ASynEdit);

  // Change to preview settings
  ASynEdit.Options := ASynEdit.Options
    - SynEditPreviewExcludeOptions + SynEditPreviewIncludeOptions;
  ASynEdit.Options2 := ASynEdit.Options2 - SynEditPreviewExcludeOptions2;
  ASynEdit.ReadOnly := True;
end;


initialization
  RegisterIDEOptionsGroup(GroupEditor, dlgGroupEditor);
  {$I lazarus_dci.lrs}
end.
