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
  Controls, Graphics, LCLProc, FileUtil, LResources, Forms,
  // synedit
  SynEdit, SynEditAutoComplete, SynEditHighlighter, SynEditHighlighterFoldBase, SynEditKeyCmds,
  SynEditStrConst, SynEditMarkupBracket, SynEditMarkupHighAll, SynEditMarkupWordGroup,
  SynGutter, SynGutterBase, SynGutterCodeFolding, SynGutterLineNumber, SynGutterChanges,
  SynHighlighterCPP, SynHighlighterHTML, SynHighlighterJava, SynHighlighterLFM,
  SynHighlighterPas, SynHighlighterPerl, SynHighlighterPHP, SynHighlighterSQL,
  SynHighlighterPython, SynHighlighterUNIXShellScript, SynHighlighterXML,
  SynHighlighterJScript, SynEditMiscClasses, SynBeautifier, SynEditTextTrimmer,
  SynEditMouseCmds, SynPluginTemplateEdit, SynPluginSyncroEdit,
  // codetools
  LinkScanner, CodeToolManager, Laz_XMLCfg,
  // IDEIntf
  IDECommands, SrcEditorIntf, IDEOptionsIntf,
  // IDE
  LazarusIDEStrConsts, IDEProcs, KeyMapping, LazConf, typinfo;

type
  TPreviewPasSyn = TSynFreePascalSyn;
  TSrcIDEHighlighter = TSynCustomHighlighter;
  TSynHighlightElement = TSynHighlighterAttributes;
  TCustomSynClass = class of TSrcIDEHighlighter;

  TLazSyntaxHighlighter =
    (lshNone, lshText, lshFreePascal, lshDelphi, lshLFM, lshXML, lshHTML,
    lshCPP, lshPerl, lshJava, lshBash, lshPython, lshPHP, lshSQL, lshJScript);

  // TODO: add defaults for other highlighters too (like html, xml...)
  TPascalHilightAttribute = (
    phaAssembler, phaComment, phaDirective, phaReservedWord, phaNumber,
    phaString, phaSymbol
  );

  TLazSynPluginTemplateEditForm = class(TForm)     end;
  TLazSynPluginTemplateEditFormOff = class(TForm)  end;
  TLazSynPluginSyncroEditFormSel = class(TForm)    end;
  TLazSynPluginSyncroEditForm = class(TForm)       end;
  TLazSynPluginSyncroEditFormOff = class(TForm)    end;

const
  // Initialized *before* localisation. Compared witl StoredName
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
    ahaMouseLink, ahaLineNumber, ahaLineHighlight, ahaModifiedLine,
    ahaCodeFoldingTree, ahaHighlightWord, ahaFoldedCode, ahaWordGroup,
    ahaTemplateEditCur, ahaTemplateEditSync, ahaTemplateEditOther,
    ahaSyncroEditCur, ahaSyncroEditSync, ahaSyncroEditOther, ahaSyncroEditArea,
    ahaGutterSeparator, ahaGutter, ahaRightMargin);

  TAhaGroupName = (agnText, agnLine, agnGutter, agnTemplateMode, agnSyncronMode);

  TAhaSupportedFeatures = Record
    FG, BG, FF: Boolean; // ForeGround, BackGroun, Frame
    Style: Boolean;
    Group: TAhaGroupName;
  end;

const
  ahaXmlNames: array[TAdditionalHilightAttribute] of String =
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
    'Brackets highlight',
    'Mouse link',
    'Line number',
    'Line highlight',
    'Modified line',
    'Code folding tree',
    'Highlight current word',
    'Folded code',
    'Word-Brackets',
    'TemplateEdit Current',
    'TemplateEdit Sync',
    'TemplateEdit Cells',
    'SyncronEdit Current Cells',
    'SyncronEdit Syncron Cells',
    'SyncronEdit Other Cells',
    'SyncronEdit Range',
    '', // scaGutterSeparator => uses RTTI only
    '', // ahaGutter
    ''  // ahaRightMargin
  );

  ahaSupportedFeatures: array[TAdditionalHilightAttribute] of TAhaSupportedFeatures =
  (
    { ahaNone }               (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnText),
    { ahaTextBlock }          (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnText),
    { ahaExecutionPoint }     (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnLine),
    { ahaEnabledBreakpoint }  (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnLine),
    { ahaDisabledBreakpoint } (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnLine),
    { ahaInvalidBreakpoint }  (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnLine),
    { ahaUnknownBreakpoint }  (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnLine),
    { ahaErrorLine }          (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnLine),
    { ahaIncrementalSearch }  (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnText),
    { ahaHighlightAll }       (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnText),
    { ahaBracketMatch }       (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnText),
    { ahaMouseLink }          (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnText),
    { ahaLineNumber }         (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnGutter),
    { ahaLineHighlight }      (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnLine),
    { ahaModifiedLine }       (FG: True;  BG: True;  FF: True;  Style: False; Group: agnGutter),
    { ahaCodeFoldingTree }    (FG: True;  BG: True;  FF: False; Style: False; Group: agnGutter),
    { ahaHighlightWord }      (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnText),
    { ahaFoldedCode }         (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnGutter),
    { ahaWordGroup }          (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnText),
    { ahaTemplateEditCur }    (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnTemplateMode),
    { ahaTemplateEditSync }   (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnTemplateMode),
    { ahaTemplateEditOther }  (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnTemplateMode),
    { ahaSyncroEditCur }      (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnSyncronMode),
    { ahaSyncroEditSync }     (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnSyncronMode),
    { ahaSyncroEditOther }    (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnSyncronMode),
    { ahaSyncroEditArea }     (FG: True;  BG: True;  FF: True;  Style: True;  Group: agnSyncronMode),
    { ahaGutterSeparator }    (FG: True;  BG: True;  FF: False; Style: False; Group: agnGutter),
    { ahaGutter }             (FG: False; BG: True;  FF: False; Style: False; Group: agnGutter),
    { ahaRightMargin}         (FG: True;  BG: False; FF: False; Style: False; Group: agnGutter)
  );


var
  AdditionalHighlightAttributes: array[TAdditionalHilightAttribute] of String;
  AdditionalHighlightGroupNames: array[TAhaGroupName] of String;

type
  TSchemeAttribute = record
    BG, FG, FC: TColor;
    Styles: TFontStyles;
    StylesMask: TFontStyles; // For Markup, normal Attributes will ignore this
  end;

  TPascalColorScheme = record
    Name: String;
    Default: TSchemeAttribute;
    Attributes: array[TPascalHilightAttribute] of TSchemeAttribute;
    Additional: array[TAdditionalHilightAttribute] of TSchemeAttribute;
  end;

  TColorSchemeMapping = class(TObject)
  private
    FName: string;
    FColorScheme: TPascalColorScheme;
  public
    constructor CreateEx(const AName: string; const AColorScheme: TPascalColorScheme);
    property    Name: string read FName;
    property    ColorScheme: TPascalColorScheme read FColorScheme;
  end;

  TColorSchemeFactory = class(TObject)
  private
    FMappings: TStringList;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure   RegisterScheme(const AName: string; const AColorScheme: TPascalColorScheme);
    function    GetColorScheme(const AName: string): TPascalColorScheme;
    procedure   GetRegisteredSchemes(AList: TStrings);
  end;


const
  (* How it works:
     - All color settings (highlighter, markup, others are stored on the Highlighters.
        For this each Highlighter is extended by:
        AddSpecialHilightAttribsToHighlighter

     - GetDefaultsForPascalAttribute
        replaces all clDefault with the values from the 'Default' colors
        which can be clNone (The SynEdit default is Black on White; see SetMarkupColors)

     - ReadDefaultsForHighlighterSettings
       - for a 'pascal' highlighter
          will set all values as provided by:  GetDefaultsForPascalAttribute
       - for any other highlighte
         ^ Will read the user's configuration (ReadHighlighterSettings) for 'pascal',
           which starts with GetDefaultsForPascalAttribute
         ^ All defaults for  AdditionalAttributes  and  selected language attributes
           (MappedAttributes) will be set to the user's pascal config
         ^ The remaining language attributes are left to the Values defined in the
           Highlighters Create
           //Todo: Add them to TPascalHilightAttribute, so they can have defaults
                   per colorscheme too

     - ReadHighlighterSettings
        loads the differences between the users setting and the defaults

   * clDefault vs clNone
     - clDefault is replaced with the values from the 'Default' colors (GetDefaultsForPascalAttribute)
       this can be clNone
     - clDefault should not make it outside GetDefaultsForPascalAttribute
     - editor_color_option_frame expects clNone (but will take and convert clDefault)
     - clNone is handled inside SynEdit / clDefault is not expected in SynEdit
       ^ clnone in Additional Attributes means the pascal/ language Attribute is used
       ^ clnone in pascal/ language Attributes means the SynEdit.Font.Color is used
         for forground / SynEdit.Color is used for BackGround

   * Additional Attributes should use clNone. They always fallback to a pascal/language attribute
  *)
  DEFAULT_COLOR_SCHEME: TPascalColorScheme = (
    Name: 'Default';
    Default: (BG: clNone;  FG: clNone; FC: clNone; Styles: []; StylesMask: []);
    Attributes: (
      { phaAssembler    } (BG: clDefault;  FG: clGreen;    FC: clNone; Styles: [];       StylesMask: []),
      { phaComment      } (BG: clDefault;  FG: clBlue;     FC: clNone; Styles: [fsBold]; StylesMask: []),
      { phaDirective    } (BG: clDefault;  FG: clRed;      FC: clNone; Styles: [fsBold]; StylesMask: []),
      { phaReservedWord } (BG: clDefault;  FG: clDefault;  FC: clNone; Styles: [fsBold]; StylesMask: []),
      { phaNumber       } (BG: clDefault;  FG: clNavy;     FC: clNone; Styles: [];       StylesMask: []),
      { phaString       } (BG: clDefault;  FG: clBlue;     FC: clNone; Styles: [];       StylesMask: []),
      { phaSymbol       } (BG: clDefault;  FG: clRed;      FC: clNone; Styles: [];       StylesMask: [])
    );
    Additional: (
      { ahaNone               } (BG: clWhite;     FG: clBlack;    FC: clNone; Styles: []; StylesMask: []),
      { ahaTextBlock          } (BG: clNavy;      FG: clWhite;    FC: clNone; Styles: []; StylesMask: []),
      { ahaExecutionPoint     } (BG: clDKGray;    FG: clWhite;    FC: clNone; Styles: []; StylesMask: []),
      { ahaEnabledBreakpoint  } (BG: clRed;       FG: clBlack;    FC: clNone; Styles: []; StylesMask: []),
      { ahaDisabledBreakpoint } (BG: clGreen;     FG: clBlack;    FC: clNone; Styles: []; StylesMask: []),
      { ahaInvalidBreakpoint  } (BG: clOlive;     FG: clGreen;    FC: clNone; Styles: []; StylesMask: []),
      { ahaUnknownBreakpoint  } (BG: clRed;       FG: clBlack;    FC: clNone; Styles: []; StylesMask: []),
      { ahaErrorLine          } (BG: $50a0ff;     FG: clBlack;    FC: clNone; Styles: []; StylesMask: []),
      { ahaIncrementalSearch  } (BG: $30D070;     FG: clWhite;    FC: clNone; Styles: []; StylesMask: []),
      { ahaHighlightAll       } (BG: clYellow;    FG: clDefault;  FC: clNone; Styles: []; StylesMask: []),
      { ahaBracketMatch       } (BG: clDefault;   FG: clDefault;  FC: clNone; Styles: [fsBold]; StylesMask: []),
      { ahaMouseLink          } (BG: clDefault;   FG: clBlue;     FC: clNone; Styles: []; StylesMask: []),
      { ahaLineNumber         } (BG: clNone;      FG: clNone;     FC: clNone; Styles: []; StylesMask: []),
      { ahaLineHighlight      } (BG: clNone;      FG: clNone;     FC: clNone; Styles: []; StylesMask: []),
      { ahaModifiedLine       } (BG: clNone;      FG: clGreen;    FC: $00E9FC; Styles: []; StylesMask: []),
      { ahaCodeFoldingTree    } (BG: clWhite;     FG: clSilver;   FC: clNone; Styles: []; StylesMask: []),
      { ahaHighlightWord      } (BG: $E6E6E6;     FG: clDefault;  FC: clSilver; Styles: []; StylesMask: []),
      { ahaFoldedCode         } (BG: clWhite;     FG: clSilver;   FC: clSilver; Styles: []; StylesMask: []),
      { ahaWordGroup          } (BG: clNone;      FG: clNone;     FC: clRed;    Styles: []; StylesMask: []),
      { ahaTemplateEditCur    } (BG: clNone;      FG: clNone;     FC: clAqua;    Styles: []; StylesMask: []),
      { ahaTemplateEditSync   } (BG: clNone;      FG: clNone;     FC: clFuchsia; Styles: []; StylesMask: []),
      { ahaTemplateEditOther  } (BG: clNone;      FG: clNone;     FC: clMaroon;  Styles: []; StylesMask: []),
      { ahaSyncroEditCur      } (BG: clNone;      FG: clNone;     FC: clFuchsia;     Styles: []; StylesMask: []),
      { ahaSyncroEditSync     } (BG: clNone;      FG: clNone;     FC: clRed;        Styles: []; StylesMask: []),
      { ahaSyncroEditOther    } (BG: clNone;      FG: clNone;     FC: $94b094;      Styles: []; StylesMask: []),
      { ahaSyncroEditArea     } (BG: clMoneyGreen;      FG: clNone;     FC: clNone; Styles: []; StylesMask: []),
      { ahaGutterSeparator    } (BG: clWhite;     FG: clDkGray;   FC: clNone; Styles: []; StylesMask: []),
      { ahaGutter             } (BG: clBtnFace;   FG: clNone;     FC: clNone; Styles: []; StylesMask: []),
      { ahaRightMargin        } (BG: clNone;      FG: clSilver;   FC: clNone; Styles: []; StylesMask: [])
    );
  );

  TWILIGHT_COLOR_SCHEME: TPascalColorScheme = (
    Name: 'Twilight';
    Default: (BG: clBlack;  FG: clWhite; FC: clNone; Styles: []; StylesMask: []);
    Attributes: (
      { phaAssembler    } (BG: clDefault;  FG: clLime;    FC: clNone; Styles: [];       StylesMask: []),
      { phaComment      } (BG: clDefault;  FG: clGray;    FC: clNone; Styles: [];       StylesMask: []),
      { phaDirective    } (BG: clDefault;  FG: clRed;     FC: clNone; Styles: [];       StylesMask: []),
      { phaReservedWord } (BG: clDefault;  FG: clAqua;    FC: clNone; Styles: [fsBold]; StylesMask: []),
      { phaNumber       } (BG: clDefault;  FG: clFuchsia; FC: clNone; Styles: [];       StylesMask: []),
      { phaString       } (BG: clDefault;  FG: clYellow;  FC: clNone; Styles: [];       StylesMask: []),
      { phaSymbol       } (BG: clDefault;  FG: clAqua;    FC: clNone; Styles: [];       StylesMask: [])
    );
    Additional: (
      { ahaNone               } (BG: clDefault;   FG: clDefault;  FC: clNone; Styles: []; StylesMask: []),
      { ahaTextBlock          } (BG: clWhite;     FG: clBlack;    FC: clNone; Styles: []; StylesMask: []),
      { ahaExecutionPoint     } (BG: clBlue;      FG: clWhite;    FC: clNone; Styles: []; StylesMask: []),
      { ahaEnabledBreakpoint  } (BG: clRed;       FG: clWhite;    FC: clNone; Styles: []; StylesMask: []),
      { ahaDisabledBreakpoint } (BG: clLime;      FG: clRed;      FC: clNone; Styles: []; StylesMask: []),
      { ahaInvalidBreakpoint  } (BG: clOlive;     FG: clGreen;    FC: clNone; Styles: []; StylesMask: []),
      { ahaUnknownBreakpoint  } (BG: clRed;       FG: clBlack;    FC: clNone; Styles: []; StylesMask: []),
      { ahaErrorLine          } (BG: $50a0ff;     FG: clBlack;    FC: clNone; Styles: []; StylesMask: []),
      { ahaIncrementalSearch  } (BG: $30D070;     FG: clWhite;    FC: clNone; Styles: []; StylesMask: []),
      { ahaHighlightAll       } (BG: clYellow;    FG: clDefault;  FC: clNone; Styles: []; StylesMask: []),
      { ahaBracketMatch       } (BG: clDefault;   FG: clDefault;  FC: clNone; Styles: [fsBold]; StylesMask: []),
      { ahaMouseLink          } (BG: clDefault;   FG: clBlue;     FC: clNone; Styles: []; StylesMask: []),
      { ahaLineNumber         } (BG: clNone;      FG: clNone;     FC: clNone; Styles: []; StylesMask: []),
      { ahaLineHighlight      } (BG: clNone;      FG: clNone;     FC: clNone; Styles: []; StylesMask: []),
      { ahaModifiedLine       } (BG: clNone;      FG: clGreen;    FC: $00E9FC; Styles: []; StylesMask: []),
      { ahaCodeFoldingTree    } (BG: clDefault;   FG: clSilver;   FC: clNone; Styles: []; StylesMask: []),
      { ahaHighlightWord      } (BG: $303030;     FG: clDefault;  FC: clSilver; Styles: []; StylesMask: []),
      { ahaFoldedCode         } (BG: clDefault;   FG: clSilver;   FC: clSilver; Styles: []; StylesMask: []),
      { ahaWordGroup          } (BG: clNone;      FG: clNone;     FC: clRed;    Styles: []; StylesMask: []),
      { ahaTemplateEditCur    } (BG: clNone;      FG: clNone;     FC: clAqua;    Styles: []; StylesMask: []),
      { ahaTemplateEditSync   } (BG: clNone;      FG: clNone;     FC: clFuchsia; Styles: []; StylesMask: []),
      { ahaTemplateEditOther  } (BG: clNone;      FG: clNone;     FC: clMaroon;  Styles: []; StylesMask: []),
      { ahaSyncroEditCur      } (BG: clNone;      FG: clNone;     FC: clFuchsia;     Styles: []; StylesMask: []),
      { ahaSyncroEditSync     } (BG: clNone;      FG: clNone;     FC: clRed;        Styles: []; StylesMask: []),
      { ahaSyncroEditOther    } (BG: clNone;      FG: clNone;     FC: $94b094;      Styles: []; StylesMask: []),
      { ahaSyncroEditArea     } (BG: clMoneyGreen;      FG: clNone;     FC: clNone; Styles: []; StylesMask: []),
      { ahaGutterSeparator    } (BG: clWhite;     FG: clDkGray;   FC: clNone; Styles: []; StylesMask: []),
      { ahaGutter             } (BG: clBtnFace;   FG: clNone;     FC: clNone; Styles: []; StylesMask: []),
      { ahaRightMargin        } (BG: clNone;      FG: clSilver;   FC: clNone; Styles: []; StylesMask: [])
    );
  );

  CLASSIC_COLOR_SCHEME: TPascalColorScheme = (
    Name: 'Pascal Classic';
    Default: (BG: clNavy;  FG: clYellow; FC: clNone; Styles: []; StylesMask: []);
    Attributes: (
      { phaAssembler    } (BG: clDefault;  FG: clLime;    FC: clNone; Styles: []; StylesMask: []),
      { phaComment      } (BG: clDefault;  FG: clSilver;  FC: clNone; Styles: []; StylesMask: []),
      { phaDirective    } (BG: clDefault;  FG: clSilver;  FC: clNone; Styles: []; StylesMask: []),
      { phaReservedWord } (BG: clDefault;  FG: clWhite;   FC: clNone; Styles: []; StylesMask: []),
      { phaNumber       } (BG: clDefault;  FG: clYellow;  FC: clNone; Styles: []; StylesMask: []),
      { phaString       } (BG: clDefault;  FG: clYellow;  FC: clNone; Styles: []; StylesMask: []),
      { phaSymbol       } (BG: clDefault;  FG: clYellow;  FC: clNone; Styles: []; StylesMask: [])
    );
    Additional: (
      { ahaNone               } (BG: clDefault;   FG: clDefault;  FC: clNone; Styles: []; StylesMask: []),
      { ahaTextBlock          } (BG: clBlue;      FG: clWhite;    FC: clNone; Styles: []; StylesMask: []),
      { ahaExecutionPoint     } (BG: clAqua;      FG: clBlack;    FC: clNone; Styles: []; StylesMask: []),
      { ahaEnabledBreakpoint  } (BG: clRed;       FG: clWhite;    FC: clNone; Styles: []; StylesMask: []),
      { ahaDisabledBreakpoint } (BG: clLime;      FG: clRed;      FC: clNone; Styles: []; StylesMask: []),
      { ahaInvalidBreakpoint  } (BG: clOlive;     FG: clLime;     FC: clNone; Styles: []; StylesMask: []),
      { ahaUnknownBreakpoint  } (BG: clDefault;   FG: clDefault;  FC: clNone; Styles: []; StylesMask: []),
      { ahaErrorLine          } (BG: clMaroon;    FG: clWhite;    FC: clNone; Styles: []; StylesMask: []),
      { ahaIncrementalSearch  } (BG: $30D070;     FG: clWhite;    FC: clNone; Styles: []; StylesMask: []),
      { ahaHighlightAll       } (BG: clYellow;    FG: clDefault;  FC: clNone; Styles: []; StylesMask: []),
      { ahaBracketMatch       } (BG: clDefault;   FG: clDefault;  FC: clNone; Styles: [fsBold]; StylesMask: []),
      { ahaMouseLink          } (BG: clDefault;   FG: clBlue;     FC: clNone; Styles: []; StylesMask: []),
      { ahaLineNumber         } (BG: clNone;      FG: clNone;     FC: clNone; Styles: []; StylesMask: []),
      { ahaLineHighlight      } (BG: clNone;      FG: clNone;     FC: clNone; Styles: []; StylesMask: []),
      { ahaModifiedLine       } (BG: clNone;      FG: clGreen;    FC: $00E9FC; Styles: []; StylesMask: []),
      { ahaCodeFoldingTree    } (BG: clDefault;   FG: clSilver;   FC: clNone; Styles: []; StylesMask: []),
      { ahaHighlightWord      } (BG: clDefault;   FG: clDefault;  FC: clSilver; Styles: []; StylesMask: []),
      { ahaFoldedCode         } (BG: clDefault;   FG: clSilver;   FC: clSilver; Styles: []; StylesMask: []),
      { ahaWordGroup          } (BG: clNone;      FG: clNone;     FC: clRed;    Styles: []; StylesMask: []),
      { ahaTemplateEditCur    } (BG: clNone;      FG: clNone;     FC: clAqua;    Styles: []; StylesMask: []),
      { ahaTemplateEditSync   } (BG: clNone;      FG: clNone;     FC: clFuchsia; Styles: []; StylesMask: []),
      { ahaTemplateEditOther  } (BG: clNone;      FG: clNone;     FC: clMaroon;  Styles: []; StylesMask: []),
      { ahaSyncroEditCur      } (BG: clNone;      FG: clNone;     FC: clFuchsia;     Styles: []; StylesMask: []),
      { ahaSyncroEditSync     } (BG: clNone;      FG: clNone;     FC: clRed;        Styles: []; StylesMask: []),
      { ahaSyncroEditOther    } (BG: clNone;      FG: clNone;     FC: $94b094;      Styles: []; StylesMask: []),
      { ahaSyncroEditArea     } (BG: clMoneyGreen;      FG: clNone;     FC: clNone; Styles: []; StylesMask: []),
      { ahaGutterSeparator    } (BG: clWhite;     FG: clDkGray;   FC: clNone; Styles: []; StylesMask: []),
      { ahaGutter             } (BG: clBtnFace;   FG: clNone;     FC: clNone; Styles: []; StylesMask: []),
      { ahaRightMargin        } (BG: clNone;      FG: clSilver;   FC: clNone; Styles: []; StylesMask: [])
    );
  );

  OCEAN_COLOR_SCHEME: TPascalColorScheme = (
    Name: 'Ocean';
    Default: (BG: clNavy;  FG: clYellow; FC: clNone; Styles: []; StylesMask: []);
    Attributes: (
      { phaAssembler    } (BG: clDefault;  FG: clLime;    FC: clNone; Styles: [];       StylesMask: []),
      { phaComment      } (BG: clDefault;  FG: clGray;    FC: clNone; Styles: [];       StylesMask: []),
      { phaDirective    } (BG: clDefault;  FG: clRed;     FC: clNone; Styles: [];       StylesMask: []),
      { phaReservedWord } (BG: clDefault;  FG: clAqua;    FC: clNone; Styles: [fsBold]; StylesMask: []),
      { phaNumber       } (BG: clDefault;  FG: clFuchsia; FC: clNone; Styles: [];       StylesMask: []),
      { phaString       } (BG: clDefault;  FG: clYellow;  FC: clNone; Styles: [];       StylesMask: []),
      { phaSymbol       } (BG: clDefault;  FG: clAqua;    FC: clNone; Styles: [];       StylesMask: [])
    );
    Additional: (
      { ahaNone               } (BG: clDefault;   FG: clDefault;  FC: clNone; Styles: []; StylesMask: []),
      { ahaTextBlock          } (BG: clWhite;     FG: clBlack;    FC: clNone; Styles: []; StylesMask: []),
      { ahaExecutionPoint     } (BG: clBlue;      FG: clWhite;    FC: clNone; Styles: []; StylesMask: []),
      { ahaEnabledBreakpoint  } (BG: clRed;       FG: clWhite;    FC: clNone; Styles: []; StylesMask: []),
      { ahaDisabledBreakpoint } (BG: clLime;      FG: clRed;      FC: clNone; Styles: []; StylesMask: []),
      { ahaInvalidBreakpoint  } (BG: clOlive;     FG: clGreen;    FC: clNone; Styles: []; StylesMask: []),
      { ahaUnknownBreakpoint  } (BG: clRed;       FG: clBlack;    FC: clNone; Styles: []; StylesMask: []),
      { ahaErrorLine          } (BG: $50A0FF;     FG: clBlack;    FC: clNone; Styles: []; StylesMask: []),
      { ahaIncrementalSearch  } (BG: $30D070;     FG: clWhite;    FC: clNone; Styles: []; StylesMask: []),
      { ahaHighlightAll       } (BG: clYellow;    FG: clDefault;  FC: clNone; Styles: []; StylesMask: []),
      { ahaBracketMatch       } (BG: clDefault;   FG: clDefault;  FC: clNone; Styles: [fsBold]; StylesMask: []),
      { ahaMouseLink          } (BG: clDefault;   FG: clBlue;     FC: clNone; Styles: []; StylesMask: []),
      { ahaLineNumber         } (BG: clNone;      FG: clNone;     FC: clNone; Styles: []; StylesMask: []),
      { ahaLineHighlight      } (BG: clNone;      FG: clNone;     FC: clNone; Styles: []; StylesMask: []),
      { ahaModifiedLine       } (BG: clNone;      FG: clGreen;    FC: $00E9FC; Styles: []; StylesMask: []),
      { ahaCodeFoldingTree    } (BG: clDefault;   FG: clSilver;   FC: clNone; Styles: []; StylesMask: []),
      { ahaHighlightWord      } (BG: clDefault;   FG: clDefault;  FC: clSilver; Styles: []; StylesMask: []),
      { ahaFoldedCode         } (BG: clDefault;   FG: clSilver;   FC: clSilver; Styles: []; StylesMask: []),
      { ahaWordGroup          } (BG: clNone;      FG: clNone;     FC: clRed;    Styles: []; StylesMask: []),
      { ahaTemplateEditCur    } (BG: clNone;      FG: clNone;     FC: clAqua;    Styles: []; StylesMask: []),
      { ahaTemplateEditSync   } (BG: clNone;      FG: clNone;     FC: clFuchsia; Styles: []; StylesMask: []),
      { ahaTemplateEditOther  } (BG: clNone;      FG: clNone;     FC: clMaroon;  Styles: []; StylesMask: []),
      { ahaSyncroEditCur      } (BG: clNone;      FG: clNone;     FC: clFuchsia;     Styles: []; StylesMask: []),
      { ahaSyncroEditSync     } (BG: clNone;      FG: clNone;     FC: clRed;        Styles: []; StylesMask: []),
      { ahaSyncroEditOther    } (BG: clNone;      FG: clNone;     FC: $94b094;      Styles: []; StylesMask: []),
      { ahaSyncroEditArea     } (BG: clMoneyGreen;      FG: clNone;     FC: clNone; Styles: []; StylesMask: []),
      { ahaGutterSeparator    } (BG: clWhite;     FG: clDkGray;   FC: clNone; Styles: []; StylesMask: []),
      { ahaGutter             } (BG: clBtnFace;   FG: clNone;     FC: clNone; Styles: []; StylesMask: []),
      { ahaRightMargin        } (BG: clNone;      FG: clSilver;   FC: clNone; Styles: []; StylesMask: [])
    );
  );

  DELPHI_COLOR_SCHEME: TPascalColorScheme = (
    Name: 'Delphi';
    Default: (BG: clNone;  FG: clNone; FC: clNone; Styles: []; StylesMask: []);
    Attributes: (
      { phaAssembler    } (BG: clDefault;  FG: clBlack;      FC: clNone; Styles: [];         StylesMask: []),
      { phaComment      } (BG: clDefault;  FG: clGreen;      FC: clNone; Styles: [fsItalic]; StylesMask: []),
      { phaDirective    } (BG: clDefault;  FG: clTeal;       FC: clNone; Styles: [];         StylesMask: []),
      { phaReservedWord } (BG: clDefault;  FG: clNavy;       FC: clNone; Styles: [fsBold];   StylesMask: []),
      { phaNumber       } (BG: clDefault;  FG: clBlue;       FC: clNone; Styles: [];         StylesMask: []),
      { phaString       } (BG: clDefault;  FG: clBlue;       FC: clNone; Styles: [];         StylesMask: []),
      { phaSymbol       } (BG: clDefault;  FG: clDefault;    FC: clNone; Styles: [];         StylesMask: [])
    );
    Additional: (
      { ahaNone               } (BG: clDefault;   FG: clDefault;   FC: clNone;  Styles: []; StylesMask: []),
      { ahaTextBlock          } (BG: $A56D53;     FG: clWhite;     FC: clNone;  Styles: []; StylesMask: []),
      { ahaExecutionPoint     } (BG: $9999CC;     FG: clBlack;     FC: clNone;  Styles: []; StylesMask: []),
      { ahaEnabledBreakpoint  } (BG: $FFC7C7;     FG: clBlack;     FC: clNone;  Styles: []; StylesMask: []),
      { ahaDisabledBreakpoint } (BG: $FFC7C7;     FG: clGray;      FC: clNone;  Styles: []; StylesMask: []),
      { ahaInvalidBreakpoint  } (BG: clGreen;     FG: clWhite;     FC: clNone;  Styles: []; StylesMask: []),
      { ahaUnknownBreakpoint  } (BG: $FFC7C7;     FG: clBlack;     FC: clNone;  Styles: []; StylesMask: []),
      { ahaErrorLine          } (BG: clRed;       FG: clWhite;     FC: clNone;  Styles: []; StylesMask: []),
      { ahaIncrementalSearch  } (BG: clBlack;     FG: $FCFDCD;     FC: clNone;  Styles: []; StylesMask: []),
      { ahaHighlightAll       } (BG: clYellow;    FG: clDefault;   FC: clNone;  Styles: []; StylesMask: []),
      { ahaBracketMatch       } (BG: clAqua;      FG: clDefault;   FC: $CCCCD6; Styles: []; StylesMask: []),
      { ahaMouseLink          } (BG: clDefault;   FG: clBlue;      FC: clNone;  Styles: []; StylesMask: []),
      { ahaLineNumber         } (BG: $F4F4F4;     FG: $CC9999;     FC: clNone;  Styles: []; StylesMask: []),
      { ahaLineHighlight      } (BG: $E6FFFA;     FG: clNone;      FC: clNone;  Styles: []; StylesMask: []),
      { ahaModifiedLine       } (BG: $F4F4F4;     FG: clLime;      FC: clYellow;Styles: []; StylesMask: []),
      { ahaCodeFoldingTree    } (BG: $F4F4F4;     FG: $CC9999;     FC: clNone;  Styles: []; StylesMask: []),
      { ahaHighlightWord      } (BG: clDefault;   FG: clDefault;   FC: $CCCCD6; Styles: []; StylesMask: []),
      { ahaFoldedCode         } (BG: clDefault;   FG: $CC9999;     FC: $CC9999; Styles: []; StylesMask: []),
      { ahaWordGroup          } (BG: clNone;      FG: clNone;      FC: clRed;   Styles: []; StylesMask: []),
      { ahaTemplateEditCur    } (BG: clNone;      FG: clNone;      FC: clAqua;    Styles: []; StylesMask: []),
      { ahaTemplateEditSync   } (BG: clNone;      FG: clNone;      FC: clFuchsia; Styles: []; StylesMask: []),
      { ahaTemplateEditOther  } (BG: clNone;      FG: clNone;      FC: clMaroon;  Styles: []; StylesMask: []),
      { ahaSyncroEditCur      } (BG: clNone;      FG: clNone;      FC: clFuchsia; Styles: []; StylesMask: []),
      { ahaSyncroEditSync     } (BG: clNone;      FG: clNone;      FC: clRed;     Styles: []; StylesMask: []),
      { ahaSyncroEditOther    } (BG: clNone;      FG: clNone;      FC: clBlue;    Styles: []; StylesMask: []),
      { ahaSyncroEditArea     } (BG: $FAFFE6;     FG: clNone;      FC: clNone;    Styles: []; StylesMask: []),
      { ahaGutterSeparator    } (BG: clWhite;     FG: clDkGray;   FC: clNone; Styles: []; StylesMask: []),
      { ahaGutter             } (BG: clBtnFace;   FG: clNone;     FC: clNone; Styles: []; StylesMask: []),
      { ahaRightMargin        } (BG: clNone;      FG: clSilver;   FC: clNone; Styles: []; StylesMask: [])
    );
  );

type

  TEditorOptionsDividerInfo = record
    Name: String;      // Name for display
    Xml: String;       // Name for XML
    BoolOpt: Boolean;  // Checkbox only
    MaxLevel: Integer;
  end;
  TEditorOptionsDividerInfoList = Array [0..999] of TEditorOptionsDividerInfo;
  PEditorOptionsDividerInfoList = ^TEditorOptionsDividerInfoList;

  TEditorOptionsDividerRecord = record
    Count: Integer;
    Info: PEditorOptionsDividerInfoList;
  end;

var

  EditorOptionsDividerInfoPas: Array [0..8] of TEditorOptionsDividerInfo
  = (
      (Name: dlgDivPasUnitSectionName;  Xml: 'Sect';    BoolOpt: True;  MaxLevel: 1),
      (Name: dlgDivPasUsesName;         Xml: 'Uses';    BoolOpt: True;  MaxLevel: 0),
      (Name: dlgDivPasVarGlobalName;    Xml: 'GVar';    BoolOpt: True;  MaxLevel: 1),
      (Name: dlgDivPasVarLocalName;     Xml: 'LVar';    BoolOpt: False; MaxLevel: 0),
      (Name: dlgDivPasStructGlobalName; Xml: 'GStruct'; BoolOpt: False; MaxLevel: 1),
      (Name: dlgDivPasStructLocalName;  Xml: 'LStruct'; BoolOpt: False; MaxLevel: 0),
      (Name: dlgDivPasProcedureName;    Xml: 'Proc';    BoolOpt: False; MaxLevel: 1),
      (Name: dlgDivPasBeginEndName;     Xml: 'Begin';   BoolOpt: False; MaxLevel: 0),
      (Name: dlgDivPasTryName;          Xml: 'Try';     BoolOpt: False; MaxLevel: 0)
    );

const

  EditorOptionsDividerDefaults: array[TLazSyntaxHighlighter] of
    TEditorOptionsDividerRecord =
    ( (Count: 0; Info: nil), // none
      (Count: 0; Info: nil), // text
      (Count: 9; Info: {$IFDEF FPC}@{$ENDIF}EditorOptionsDividerInfoPas[0]), // Freepas
      (Count: 9; Info: {$IFDEF FPC}@{$ENDIF}EditorOptionsDividerInfoPas[0]), // pas
      (Count: 0; Info: nil), // lfm
      (Count: 0; Info: nil), // xml
      (Count: 0; Info: nil), // html
      (Count: 0; Info: nil), // cpp
      (Count: 0; Info: nil), // perl
      (Count: 0; Info: nil), // java
      (Count: 0; Info: nil), // shell
      (Count: 0; Info: nil), // python
      (Count: 0; Info: nil), // php
      (Count: 0; Info: nil), // sql
      (Count: 0; Info: nil)  // jscript
    );

type

  TEditorOptionsFoldInfo = record
    Name: String;      // Name for display
    Xml: String;       // Name for XML
    Index: Integer;    // FHighlighter.FoldConf[index]
    Enabled: Boolean;
  end;
  TEditorOptionsFoldInfoList = Array [0..999] of TEditorOptionsFoldInfo;
  PEditorOptionsFoldInfoList = ^TEditorOptionsFoldInfoList;

  TEditorOptionsFoldRecord = record
    Count: Integer;
    Info: PEditorOptionsFoldInfoList;
  end;

type

  { TSynEditMouseActionKeyCmdHelper }

  TSynEditMouseActionKeyCmdHelper = class(TSynEditMouseAction)
  private
    function GetOptionKeyCmd: TSynEditorCommand;
    procedure SetOptionKeyCmd(const AValue: TSynEditorCommand);
  published
    property Option: TSynEditorCommand read GetOptionKeyCmd write SetOptionKeyCmd;
  end;


const

  EditorOptionsFoldInfoPas: Array [0..19] of TEditorOptionsFoldInfo
  = (
      (Name:  dlgFoldPasProcedure;     Xml:     'Procedure';
       Index: ord(cfbtProcedure)-1;    Enabled: True),
      (Name:  dlgFoldLocalPasVarType;  Xml:     'LocalVarType';
       Index: ord(cfbtLocalVarType)-1; Enabled: True),
      (Name:  dlgFoldPasProcBeginEnd;  Xml:     'ProcBeginEnd';
       Index: ord(cfbtTopBeginEnd)-1;  Enabled: True),
      (Name:  dlgFoldPasBeginEnd;      Xml:     'BeginEnd';
       Index: ord(cfbtBeginEnd)-1;     Enabled: True),
      (Name:  dlgFoldPasRepeat;        Xml:     'Repeat';
       Index: ord(cfbtRepeat)-1;       Enabled: False),
      (Name:  dlgFoldPasCase;          Xml:     'Case';
       Index: ord(cfbtCase)-1;         Enabled: False),
      (Name:  dlgFoldPasTry;           Xml:     'Try';
       Index: ord(cfbtTry)-1;          Enabled: False),
      (Name:  dlgFoldPasExcept;        Xml:     'Except';
       Index: ord(cfbtExcept)-1;       Enabled: False),
      (Name:  dlgFoldPasAsm;           Xml:     'Asm';
       Index: ord(cfbtAsm)-1;          Enabled: True),

      (Name:  dlgFoldPasProgram;       Xml:     'Program';
       Index: ord(cfbtProgram)-1;      Enabled: False),
      (Name:  dlgFoldPasUnit;          Xml:     'Unit';
       Index: ord(cfbtUnit)-1;         Enabled: False),
      (Name:  dlgFoldPasUnitSection;   Xml:     'UnitSection';
       Index: ord(cfbtUnitSection)-1;  Enabled: False),
      (Name:  dlgFoldPasUses;          Xml:     'Uses';
       Index: ord(cfbtUses)-1;         Enabled: True),

      (Name:  dlgFoldPasVarType;       Xml:     'VarType';
       Index: ord(cfbtVarType)-1;      Enabled: False),
      (Name:  dlgFoldPasClass;         Xml:     'Class';
       Index: ord(cfbtClass)-1;        Enabled: True),
      (Name:  dlgFoldPasClassSection;  Xml:     'ClassSection';
       Index: ord(cfbtClassSection)-1; Enabled: True),
      (Name:  dlgFoldPasRecord;        Xml:     'Record';
       Index: ord(cfbtRecord)-1;       Enabled: True),

      (Name:  dlgFoldPasNestedComment; Xml:     'NestedComment';
       Index: ord(cfbtNestedComment)-1;Enabled: True),

      (Name:  dlgFoldPasIfDef;         Xml:     'IfDef';
       Index: ord(cfbtIfDef)-1;        Enabled: False),
      (Name:  dlgFoldPasUserRegion;    Xml:     'UserRegion';
       Index: ord(cfbtRegion)-1;       Enabled: True)
    );

  EditorOptionsFoldDefaults: array[TLazSyntaxHighlighter] of
    TEditorOptionsFoldRecord =
    ( (Count:  0; Info: nil), // none
      (Count:  0; Info: nil), // text
      (Count: 20; Info: {$IFDEF FPC}@{$ENDIF}EditorOptionsFoldInfoPas[0]), // Freepas
      (Count: 20; Info: {$IFDEF FPC}@{$ENDIF}EditorOptionsFoldInfoPas[0]), // pas
      (Count:  0; Info: nil), // lfm
      (Count:  0; Info: nil), // xml
      (Count:  0; Info: nil), // html
      (Count:  0; Info: nil), // cpp
      (Count:  0; Info: nil), // perl
      (Count:  0; Info: nil), // java
      (Count:  0; Info: nil), // shell
      (Count:  0; Info: nil), // python
      (Count:  0; Info: nil), // php
      (Count:  0; Info: nil), // sql
      (Count:  0; Info: nil)  // jscript
    );

const
  EditorOptsFormatVersion = 5;

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

  TEditorOptions = class;
  TMouseOptGutterLeftType = (moGLDownClick, moglUpClickAndSelect);
  TMouseOptTextMiddleType = (moTMPaste, moTMIgnore, moTMDeclarationJump);
  TMouseOptTextCtrlLeft = (moTCLJump, moTCLNone, moTCLJumpOrBlock);

  { TEditorMouseOptions }

  TEditorMouseOptions = class(TPersistent)
  private
    FAltColumnMode: Boolean;
    FGutterLeft: TMouseOptGutterLeftType;
    FTextMiddleClick: TMouseOptTextMiddleType;
    FTextCtrlLeftClick: TMouseOptTextCtrlLeft;
    FTextDoubleSelLine: Boolean;
    FTextDrag: Boolean;
    FTextRightMoveCaret: Boolean;
  private
    FCustomSavedActions: Boolean;
    FOptions: TEditorOptions;
    FMainActions, FSelActions: TSynEditMouseActions;
    FGutterActions: TSynEditMouseActions;
    FGutterActionsFold, FGutterActionsFoldExp, FGutterActionsFoldCol: TSynEditMouseActions;
    FGutterActionsLines: TSynEditMouseActions;
  public
    constructor Create(AOptions: TEditorOptions);
    destructor Destroy; override;
    procedure Reset;
    procedure Read;
    procedure WriteBack;
    procedure ResetGutterToDefault;
    procedure ResetTextToDefault;
    procedure Assign(Src: TEditorMouseOptions); reintroduce;
    function IsPresetEqualToMouseActions: Boolean;
    function CalcCustomSavedActions: Boolean;

    property MainActions: TSynEditMouseActions read FMainActions;
    property SelActions: TSynEditMouseActions read FSelActions;
    property GutterActions: TSynEditMouseActions read FGutterActions;
    property GutterActionsFold: TSynEditMouseActions read FGutterActionsFold;
    property GutterActionsFoldExp: TSynEditMouseActions read FGutterActionsFoldExp;
    property GutterActionsFoldCol: TSynEditMouseActions read FGutterActionsFoldCol;
    property GutterActionsLines: TSynEditMouseActions read FGutterActionsLines;
  published
    property GutterLeft: TMouseOptGutterLeftType read FGutterLeft write FGutterLeft;
    property AltColumnMode: Boolean read FAltColumnMode write FAltColumnMode;
    property TextDrag: Boolean read FTextDrag write FTextDrag;
    property TextDoubleSelLine: Boolean read FTextDoubleSelLine write FTextDoubleSelLine;
    property TextRightMoveCaret: Boolean read FTextRightMoveCaret  write FTextRightMoveCaret;
    property TextMiddleClick: TMouseOptTextMiddleType read FTextMiddleClick write FTextMiddleClick;
    property TextCtrlLeftClick: TMouseOptTextCtrlLeft read FTextCtrlLeftClick write FTextCtrlLeftClick;
    // the flag below is set by CalcCustomSavedActions
    property CustomSavedActions: Boolean read FCustomSavedActions write FCustomSavedActions;
  end;

  { TRttiXMLConfig }

  TRttiXMLConfig = class(TXMLConfig)
  protected
    procedure WriteProperty(Path: String; Instance: TPersistent;
                            PropInfo: Pointer; DefInstance: TPersistent = nil;
                            OnlyProperty: String= '');
    procedure ReadProperty(Path: String; Instance: TPersistent;
                            PropInfo: Pointer; DefInstance: TPersistent = nil;
                            OnlyProperty: String= '');
  public
    procedure WriteObject(Path: String; Obj: TPersistent;
                          DefObject: TPersistent= nil; OnlyProperty: String= '');
    procedure ReadObject(Path: String; Obj: TPersistent;
                          DefObject: TPersistent= nil; OnlyProperty: String= '');
  end;


  { TEditorOptions - Editor Options object used to hold the editor options }

  TEditorOptions = class(TAbstractIDEOptions)
  private
    xmlconfig: TRttiXMLConfig;

    // general options
    fFindTextAtCursor: Boolean;
    fShowTabCloseButtons: Boolean;
    fSynEditOptions: TSynEditorOptions;
    fSynEditOptions2: TSynEditorOptions2;
    fUndoAfterSave: Boolean;
    fUseSyntaxHighlight: Boolean;
    FCopyWordAtCursorOnCopyNone: Boolean;
    FShowGutterHints: Boolean;
    fBlockIndent: Integer;
    fBlockIndentType: TSynBeautifierIndentType;
    FTrimSpaceType: TSynEditStringTrimmingType;
    fUndoLimit: Integer;
    fTabWidth:  Integer;
    FBracketHighlightStyle: TSynEditBracketHighlightStyle;

    // Display options
    fVisibleRightMargin: Boolean;
    fVisibleGutter: Boolean;
    fShowLineNumbers: Boolean;
    fShowOnlyLineNumbersMultiplesOf: integer;
    fGutterWidth: Integer;
    FGutterSeparatorIndex: Integer;
    fRightMargin: Integer;
    fEditorFont:  String;
    fEditorFontHeight: Integer;
    fExtraCharSpacing: Integer;
    fExtraLineSpacing: Integer;
    fDisableAntialiasing: Boolean;
    FDoNotWarnForFont: string;

    // Key Mappings options
    fKeyMappingScheme: String;
    fKeyMap: TKeyCommandRelationList;

    // Mouse Mappings options
    fMouseMap: TSynEditMouseActions;
    fMouseSelMap: TSynEditMouseActions;
    FMouseGutterActions: TSynEditMouseActions;
    FMouseGutterActionsFold: TSynEditMouseActions;
    FMouseGutterActionsFoldCol: TSynEditMouseActions;
    FMouseGutterActionsFoldExp: TSynEditMouseActions;
    FMouseGutterActionsLines: TSynEditMouseActions;
    FTempMouseSettings: TEditorMouseOptions;

    // Color options
    fHighlighterList: TEditOptLangList;

    // Markup Current Word
    FMarkupCurWordTime: Integer;
    FMarkupCurWordFullLen: Integer;
    FMarkupCurWordNoKeyword: Boolean;
    FMarkupCurWordTrim: Boolean;
    FMarkupCurWordNoTimer: Boolean;

    // Code tools options (MG: these will move to an unit of their own)
    fAutoBlockCompletion: Boolean;
    fAutoCodeParameters: Boolean;
    fAutoDelayInMSec: Integer;
    FAutoRemoveEmptyMethods: Boolean;
    fAutoToolTipExprEval: Boolean;
    fAutoToolTipSymbTools: Boolean;
    fCodeTemplateFileName: String;
    fCTemplIndentToTokenStart: Boolean;

    // Code Folding
    FUseCodeFolding: Boolean;

    function OldAdditionalAttributeName(NewAha:String): string;
  public
    class function GetGroupCaption:string; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load;
    procedure Save;
    function GetAdditionalAttributeName(aha:TAdditionalHilightAttribute): string;
    function GetSynEditOptionName(SynOption: TSynEditorOption): string;
    function GetSynBeautifierIndentName(IndentType: TSynBeautifierIndentType): string;
    function GetSynBeautifierIndentType(IndentName: String): TSynBeautifierIndentType;
    function GetTrimSpaceName(IndentType: TSynEditStringTrimmingType): string;
    function GetTrimSpaceType(IndentName: String): TSynEditStringTrimmingType;

    procedure GetHighlighterSettings(Syn: TSrcIDEHighlighter); // read highlight settings from config file
    procedure SetHighlighterSettings(Syn: TSrcIDEHighlighter); // write highlight settings to config file
    procedure GetSynEditSettings(ASynEdit: TSynEdit); // read synedit settings from config file
    procedure SetSynEditSettings(ASynEdit: TSynEdit); // write synedit settings to file
    procedure GetSynEditPreviewSettings(APreviewEditor: TObject);
    procedure AddSpecialHilightAttribsToHighlighter(Syn: TSrcIDEHighlighter);
    procedure ApplyFontSettingsTo(ASynEdit: TSynEdit);

    function CreateSyn(LazSynHilighter: TLazSyntaxHighlighter): TSrcIDEHighlighter;
    function ReadColorScheme(const LanguageName: String): String;
    function ReadPascalColorScheme: String;
    procedure WriteColorScheme(const LanguageName, SynColorScheme: String);
    function GetColorScheme(const SynColorScheme: String): TPascalColorScheme;
    procedure GetDefaultsForPascalAttribute(Attr: TSynHighlightElement;
                                            const SynColorScheme: String);
    procedure ReadHighlighterSettings(Syn: TSrcIDEHighlighter;
                                      SynColorScheme: String);
    procedure ReadDefaultsForHighlighterSettings(Syn: TSrcIDEHighlighter;
                                                 SynColorScheme: String;
                                                 DefaultPascalSyn: TPreviewPasSyn);
    procedure WriteHighlighterSettings(Syn: TSrcIDEHighlighter;
                                       SynColorScheme: String);

    procedure ReadHighlighterFoldSettings(Syn: TSrcIDEHighlighter);
    procedure ReadDefaultsForHighlighterFoldSettings(Syn: TSrcIDEHighlighter);
    procedure WriteHighlighterFoldSettings(Syn: TSrcIDEHighlighter);

    procedure ReadHighlighterDivDrawSettings(Syn: TSrcIDEHighlighter);
    procedure ReadDefaultsForHighlighterDivDrawSettings(Syn: TSrcIDEHighlighter);
    procedure WriteHighlighterDivDrawSettings(Syn: TSrcIDEHighlighter);

    function GetLineColors(Syn: TSrcIDEHighlighter;
          AddHilightAttr: TAdditionalHilightAttribute; {TODO: MFR maybe remove?}
          out FG, BG: TColor; out Styles, StylesMask: TFontStyles): Boolean;
    function  GetSynAttributeByAha(Syn : TSrcIDEHighlighter;
                   Aha: TAdditionalHilightAttribute): TSynHighlighterAttributes;
    procedure SetMarkupColor(Syn: TSrcIDEHighlighter;
                             AddHilightAttr: TAdditionalHilightAttribute;
                             aMarkup: TSynSelectedColor);
    procedure SetMarkupColors(Syn: TSrcIDEHighlighter; aSynEd: TSynEdit; SynColorScheme: String = '');
  published
    // general options
    property SynEditOptions: TSynEditorOptions
      read fSynEditOptions write fSynEditOptions default SynEditDefaultOptions;
    property SynEditOptions2: TSynEditorOptions2
      read fSynEditOptions2 write fSynEditOptions2 default SynEditDefaultOptions2;
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
    property BlockIndentType: TSynBeautifierIndentType
      read fBlockIndentType write fBlockIndentType default sbitCopySpaceTab;
    property TrimSpaceType: TSynEditStringTrimmingType
      read FTrimSpaceType write FTrimSpaceType default settLeaveLine;
    property UndoLimit: Integer read fUndoLimit write fUndoLimit default 32767;
    property TabWidth: Integer read fTabWidth write fTabWidth default 8;
    property BracketHighlightStyle: TSynEditBracketHighlightStyle read FBracketHighlightStyle write FBracketHighlightStyle default sbhsBoth;

    // Display options
    property VisibleRightMargin: Boolean
      read fVisibleRightMargin write fVisibleRightMargin default True;
    property VisibleGutter: Boolean read fVisibleGutter
      write fVisibleGutter default True;
    property ShowLineNumbers: Boolean read fShowLineNumbers
      write fShowLineNumbers default False;
    property ShowOnlyLineNumbersMultiplesOf: integer read fShowOnlyLineNumbersMultiplesOf
      write fShowOnlyLineNumbersMultiplesOf;
    property GutterWidth: Integer
      read fGutterWidth write fGutterWidth default 30;
    property GutterSeparatorIndex: Integer read FGutterSeparatorIndex
      write FGutterSeparatorIndex default 3;
    property RightMargin: Integer
      read fRightMargin write fRightMargin default 80;
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

    // Mouse Mappings
    property MouseMap: TSynEditMouseActions read fMouseMap;
    property MouseSelMap: TSynEditMouseActions read fMouseSelMap;
    property MouseGutterActions: TSynEditMouseActions read FMouseGutterActions;
    property MouseGutterActionsFold: TSynEditMouseActions read FMouseGutterActionsFold;
    property MouseGutterActionsFoldExp: TSynEditMouseActions read FMouseGutterActionsFoldExp;
    property MouseGutterActionsFoldCol: TSynEditMouseActions read FMouseGutterActionsFoldCol;
    property MouseGutterActionsLines: TSynEditMouseActions read FMouseGutterActionsLines;
    // Used by the 2 Mouse-option pages, so they share data
    property TempMouseSettings: TEditorMouseOptions read FTempMouseSettings write FTempMouseSettings;

    // Color options
    property HighlighterList: TEditOptLangList
      read fHighlighterList write fHighlighterList;

    // Markup Current Word
    property MarkupCurWordTime: Integer
      read FMarkupCurWordTime write FMarkupCurWordTime default 1500;
    property MarkupCurWordFullLen: Integer
      read FMarkupCurWordFullLen write FMarkupCurWordFullLen default 3;
    property MarkupCurWordNoKeyword: Boolean
      read FMarkupCurWordNoKeyword write FMarkupCurWordNoKeyword default False;
    property MarkupCurWordTrim: Boolean
      read FMarkupCurWordTrim write FMarkupCurWordTrim default True;
    property MarkupCurWordNoTimer: Boolean
      read FMarkupCurWordNoTimer write FMarkupCurWordNoTimer default False;

    // Code Tools options
    property AutoBlockCompletion: Boolean
      read fAutoBlockCompletion write FAutoBlockCompletion default True;
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
    property AutoRemoveEmptyMethods: Boolean read FAutoRemoveEmptyMethods
      write FAutoRemoveEmptyMethods default False;

    // Code Folding
    property UseCodeFolding: Boolean
        read FUseCodeFolding write FUseCodeFolding default True;
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
function ColorSchemeFactory: TColorSchemeFactory;

implementation



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

{ TSynEditMouseActionKeyCmdHelper }

function TSynEditMouseActionKeyCmdHelper.GetOptionKeyCmd: TSynEditorCommand;
begin
  Result := inherited Option;
end;

procedure TSynEditMouseActionKeyCmdHelper.SetOptionKeyCmd(
  const AValue: TSynEditorCommand);
begin
  inherited Option := AValue;
end;


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

// The lazy-man color scheme factory
function ColorSchemeFactory: TColorSchemeFactory;
const
  Singleton: TColorSchemeFactory = nil;
begin
  if not Assigned(Singleton) then
    Singleton := TColorSchemeFactory.Create;
  Result := Singleton;
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
  Dest.FrameColor := Src.FrameColor;
  Dest.Style      := Src.Style;
  Dest.StyleMask  := Src.StyleMask;
end;

{ TRttiXMLConfig }

procedure TRttiXMLConfig.WriteObject(Path: String; Obj: TPersistent;
  DefObject: TPersistent; OnlyProperty: String = '');
var
  PropCount,i : integer;
  PropList  : PPropList;
begin
  PropCount:=GetPropList(Obj,PropList);
  if PropCount>0 then begin
    try
      for i := 0 to PropCount-1 do
        WriteProperty(Path, Obj, PropList^[i], DefObject, OnlyProperty);
    finally
      Freemem(PropList);
    end;
  end;
end;

// based on FPC TWriter
procedure TRttiXMLConfig.WriteProperty(Path: String; Instance: TPersistent;
  PropInfo: Pointer; DefInstance: TPersistent; OnlyProperty: String= '');
type
  tset = set of 0..31;
var
  i: Integer;
  PropType: PTypeInfo;
  Value, DefValue: LongInt;
  Ident: String;
  IntToIdentFn: TIntToIdent;
  SetType: Pointer;
  FloatValue, DefFloatValue: Extended;
  //WStrValue, WDefStrValue: WideString;
  StrValue, DefStrValue: String;
  //Int64Value, DefInt64Value: Int64;
  BoolValue, DefBoolValue: boolean;

begin
  // do not stream properties without getter and setter
  if not (Assigned(PPropInfo(PropInfo)^.GetProc) and
          Assigned(PPropInfo(PropInfo)^.SetProc)) then
    exit;

  PropType := PPropInfo(PropInfo)^.PropType;
  Path := Path + PPropInfo(PropInfo)^.Name;
  if (OnlyProperty <> '') and (OnlyProperty <> PPropInfo(PropInfo)^.Name) then
    exit;

  case PropType^.Kind of
    tkInteger, tkChar, tkEnumeration, tkSet, tkWChar:
      begin
        Value := GetOrdProp(Instance, PropInfo);
        if (DefInstance <> nil) then
          DefValue := GetOrdProp(DefInstance, PropInfo);
        if (DefInstance <> nil)  and (Value = DefValue) then
          DeleteValue(Path)
        else begin
          case PropType^.Kind of
            tkInteger:
              begin                      // Check if this integer has a string identifier
                IntToIdentFn := FindIntToIdent(PPropInfo(PropInfo)^.PropType);
                if Assigned(IntToIdentFn) and IntToIdentFn(Value, Ident) then
                  SetValue(Path, Ident) // Integer can be written a human-readable identifier
                else
                  SetValue(Path, Value); // Integer has to be written just as number
              end;
            tkChar:
              SetValue(Path, Chr(Value));
            tkWChar:
              SetValue(Path, Value);
            tkSet:
              begin
                SetType := GetTypeData(PropType)^.CompType;
                Ident := '';
                for i := 0 to 31 do
                  if (i in tset(Value)) then begin
                    if Ident <> '' then Ident := Ident + ',';
                    Ident := Ident + GetEnumName(PTypeInfo(SetType), i);
                  end;
                SetValue(Path, Ident);
              end;
            tkEnumeration:
              SetValue(Path, GetEnumName(PropType, Value));
          end;
        end;
      end;
    tkFloat:
      begin
        FloatValue := GetFloatProp(Instance, PropInfo);
        if (DefInstance <> nil) then
         DefFloatValue := GetFloatProp(DefInstance, PropInfo);
        if (DefInstance <> nil)  and (DefFloatValue = FloatValue) then
          DeleteValue(Path)
        else
          SetValue(Path, FloatToStr(FloatValue));
      end;
    tkSString, tkLString, tkAString:
      begin
        StrValue := GetStrProp(Instance, PropInfo);
        if (DefInstance <> nil) then
           DefStrValue := GetStrProp(DefInstance, PropInfo);
        if (DefInstance <> nil)  and (DefStrValue = StrValue) then
          DeleteValue(Path)
        else
          SetValue(Path, StrValue);
      end;
(*    tkWString:
      begin
        WStrValue := GetWideStrProp(Instance, PropInfo);
        if (DefInstance <> nil) then
           WDefStrValue := GetWideStrProp(DefInstance, PropInfo);
        if (DefInstance <> nil)  and (WDefStrValue = WStrValue) then
          DeleteValue(Path)
        else
          SetValue(Path, WStrValue);
      end;*)
(*    tkInt64, tkQWord:
      begin
        Int64Value := GetInt64Prop(Instance, PropInfo);
        if (DefInstance <> nil) then
          DefInt64Value := GetInt64Prop(DefInstance, PropInfo)
        if (DefInstance <> nil) and (Int64Value = DefInt64Value) then
          DeleteValue(Path, Path)
        else
          SetValue(StrValue);
      end;*)
    tkBool:
      begin
        BoolValue := GetOrdProp(Instance, PropInfo)<>0;
        if (DefInstance <> nil) then
          DefBoolValue := GetOrdProp(DefInstance, PropInfo)<>0;
        if (DefInstance <> nil) and (BoolValue = DefBoolValue) then
          DeleteValue(Path)
        else
          SetValue(Path, BoolValue);
      end;
  end;
end;

procedure TRttiXMLConfig.ReadProperty(Path: String; Instance: TPersistent; PropInfo: Pointer;
  DefInstance: TPersistent; OnlyProperty: String);
type
  tset = set of 0..31;
var
  i, j: Integer;
  PropType: PTypeInfo;
  Value, DefValue: LongInt;
  Ident, s: String;
  IdentToIntFn: TIdentToInt;
  SetType: Pointer;
  FloatValue, DefFloatValue: Extended;
  //WStrValue, WDefStrValue: WideString;
  StrValue, DefStrValue: String;
  //Int64Value, DefInt64Value: Int64;
  BoolValue, DefBoolValue: boolean;

begin
  // do not stream properties without getter and setter
  if not (Assigned(PPropInfo(PropInfo)^.GetProc) and
          Assigned(PPropInfo(PropInfo)^.SetProc)) then
    exit;

  PropType := PPropInfo(PropInfo)^.PropType;
  Path := Path + PPropInfo(PropInfo)^.Name;
  if (OnlyProperty <> '') and (OnlyProperty <> PPropInfo(PropInfo)^.Name) then
    exit;
  if DefInstance = nil then
    DefInstance := Instance;

  case PropType^.Kind of
    tkInteger, tkChar, tkEnumeration, tkSet, tkWChar:
      begin
        DefValue := GetOrdProp(DefInstance, PropInfo);
        case PropType^.Kind of
          tkInteger:
            begin                      // Check if this integer has a string identifier
              Ident := GetValue(Path, IntToStr(DefValue));
              IdentToIntFn := FindIdentToInt(PPropInfo(PropInfo)^.PropType);
              if TryStrToInt(Ident, Value) then
                SetOrdProp(Instance, PropInfo, Value)
              else if Assigned(IdentToIntFn) and IdentToIntFn(Ident, Value) then
                SetOrdProp(Instance, PropInfo, Value)
              else
                SetOrdProp(Instance, PropInfo, DefValue)
            end;
          tkChar:
            begin
              Ident := GetValue(Path, chr(DefValue));
              if Length(Ident) > 0 then
                SetOrdProp(Instance, PropInfo, ord(Ident[1]))
              else
                SetOrdProp(Instance, PropInfo, DefValue);
            end;
          tkWChar:
            SetOrdProp(Instance, PropInfo, GetValue(Path, DefValue));
          tkSet:
            begin
              SetType := GetTypeData(PropType)^.CompType;
              Ident := GetValue(Path, '-');
              If Ident = '-' then
                Value := DefValue
              else begin
                Value := 0;
                while length(Ident) > 0 do begin
                  i := Pos(',', Ident);
                  if i < 1 then
                    i := length(Ident) + 1;
                  s := copy(Ident, 1, i-1);
                  Ident := copy(Ident, i+1, length(Ident));
                  j := GetEnumValue(PTypeInfo(SetType), s);
                  if j <> -1 then
                    include(tset(Value), j)
                  else Begin
                    Value := DefValue;
                    break;
                  end;
                end;
              end;
              SetOrdProp(Instance, PropInfo, Value);
            end;
          tkEnumeration:
            begin
              Ident := GetValue(Path, '-');
              If Ident = '-' then
                Value := DefValue
              else
                Value := GetEnumValue(PropType, Ident);
              if Value <> -1 then
                SetOrdProp(Instance, PropInfo, Value)
              else
                SetOrdProp(Instance, PropInfo, DefValue);
            end;
        end;
      end;
    tkFloat:
      begin
        DefFloatValue := GetFloatProp(DefInstance, PropInfo);
        Ident := GetValue(Path, FloatToStr(DefFloatValue));
        if TryStrToFloat(Ident, FloatValue) then
          SetFloatProp(Instance, PropInfo, FloatValue)
        else
          SetFloatProp(Instance, PropInfo, DefFloatValue)
      end;
    tkSString, tkLString, tkAString:
      begin
        DefStrValue := GetStrProp(DefInstance, PropInfo);
        StrValue := GetValue(Path, DefStrValue);
        SetStrProp(Instance, PropInfo, StrValue)
      end;
(*    tkWString:
      begin
      end;*)
(*    tkInt64, tkQWord:
      begin
      end;*)
    tkBool:
      begin
        DefBoolValue := GetOrdProp(DefInstance, PropInfo) <> 0;
        BoolValue := GetValue(Path, DefBoolValue);
        SetOrdProp(Instance, PropInfo, ord(BoolValue));
      end;
  end;
end;

procedure TRttiXMLConfig.ReadObject(Path: String; Obj: TPersistent; DefObject: TPersistent;
  OnlyProperty: String);
var
  PropCount,i : integer;
  PropList  : PPropList;
begin
  PropCount:=GetPropList(Obj,PropList);
  if PropCount>0 then begin
    try
      for i := 0 to PropCount-1 do
        ReadProperty(Path, Obj, PropList^[i], DefObject, OnlyProperty);
    finally
      Freemem(PropList);
    end;
  end;
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
      '  {%region /fold}'#13 +
      '  {%endregion}'#13 +
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
    AddAttrSampleLines[ahaDisabledBreakpoint] := 20;
    AddAttrSampleLines[ahaEnabledBreakpoint] := 19;
    AddAttrSampleLines[ahaInvalidBreakpoint] := 21;
    AddAttrSampleLines[ahaUnknownBreakpoint] := 22;
    AddAttrSampleLines[ahaErrorLine] := 23;
    AddAttrSampleLines[ahaExecutionPoint] := 17;
    AddAttrSampleLines[ahaTextBlock] := 16;
    AddAttrSampleLines[ahaFoldedCode] := 13;
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

{ TEditorMouseOptions }

constructor TEditorMouseOptions.Create(AOptions: TEditorOptions);
begin
  inherited Create;
  Reset;
  FOptions := AOptions;
  FMainActions := TSynEditMouseActions.Create(nil);
  FSelActions := TSynEditMouseActions.Create(nil);
  FGutterActions := TSynEditMouseActions.Create(nil);
  FGutterActionsFold := TSynEditMouseActions.Create(nil);
  FGutterActionsFoldExp := TSynEditMouseActions.Create(nil);
  FGutterActionsFoldCol := TSynEditMouseActions.Create(nil);
  FGutterActionsLines := TSynEditMouseActions.Create(nil);
end;

destructor TEditorMouseOptions.Destroy;
begin
  FMainActions.Free;
  FSelActions.Free;
  FGutterActions.Free;
  FGutterActionsFold.Free;
  FGutterActionsFoldExp.Free;
  FGutterActionsFoldCol.Free;
  FGutterActionsLines.Free;
  inherited Destroy;
end;

procedure TEditorMouseOptions.Reset;
begin
  FCustomSavedActions := False;
  FGutterLeft := moGLDownClick;
  FTextMiddleClick := moTMPaste;
  FTextCtrlLeftClick := moTCLJump;
  FTextDoubleSelLine := False;
  FTextRightMoveCaret := False;
  FAltColumnMode := True;
  FTextDrag := True;
end;

procedure TEditorMouseOptions.Read;
begin
  FMainActions.Assign(FOptions.MouseMap);
  FSelActions.Assign(FOptions.MouseSelMap);
  FGutterActions.Assign(FOptions.MouseGutterActions);
  FGutterActionsFold.Assign(FOptions.MouseGutterActionsFold);
  FGutterActionsFoldExp.Assign(FOptions.MouseGutterActionsFoldExp);
  FGutterActionsFoldCol.Assign(FOptions.MouseGutterActionsFoldCol);
  FGutterActionsLines.Assign(FOptions.MouseGutterActionsLines);
end;

procedure TEditorMouseOptions.WriteBack;
begin
  FOptions.MouseMap.Assign(FMainActions);
  FOptions.MouseSelMap.Assign(FSelActions);
  FOptions.MouseGutterActions.Assign(FGutterActions);
  FOptions.MouseGutterActionsFold.Assign(FGutterActionsFold);
  FOptions.MouseGutterActionsFoldExp.Assign(FGutterActionsFoldExp);
  FOptions.MouseGutterActionsFoldCol.Assign(FGutterActionsFoldCol);
  FOptions.MouseGutterActionsLines.Assign(FGutterActionsLines);
end;

procedure TEditorMouseOptions.ResetGutterToDefault;
var
  CDir: TSynMAClickDir;
begin
  FGutterActions.Clear;
  FGutterActionsFold.Clear;
  FGutterActionsFoldExp.Clear;
  FGutterActionsFoldCol.Clear;
  FGutterActionsLines.Clear;
  //TMouseOptGutterLeftType = (moGLDownClick, moglUpClickAndSelect);

  with FGutterActions do begin
    AddCommand(emcContextMenu,         False, mbRight,  ccSingle, cdUp, [], []);
  end;
  with FGutterActionsFold do begin
    AddCommand(emcCodeFoldContextMenu, False, mbRight,  ccSingle, cdUp, [], []);
  end;

  CDir := cdDown;
  if FGutterLeft = moglUpClickAndSelect then begin
    CDir := cdUp;
    with FGutterActions do begin
      if FAltColumnMode then begin
        AddCommand(emcStartSelections,   True, mbLeft, ccAny, cdDown, [],               [ssShift, ssAlt], emcoSelectionStart);
        AddCommand(emcStartSelections,   True, mbLeft, ccAny, cdDown, [ssShift],        [ssShift, ssAlt], emcoSelectionContinue);
        AddCommand(emcStartColumnSelections, True, mbLeft, ccAny, cdDown, [ssAlt],          [ssShift, ssAlt], emcoSelectionStart);
        AddCommand(emcStartColumnSelections, True, mbLeft, ccAny, cdDown, [ssAlt, ssShift], [ssShift, ssAlt], emcoSelectionContinue);
      end else begin
        AddCommand(emcStartSelections,   True, mbLeft, ccAny, cdDown, [],               [ssShift], emcoSelectionStart);
        AddCommand(emcStartSelections,   True, mbLeft, ccAny, cdDown, [ssShift],        [ssShift], emcoSelectionContinue);
      end;
    end;
  end;
  with FGutterActions do begin
    AddCommand(emcOnMainGutterClick,   False, mbLeft,   ccAny,    CDir, [], []);  // breakpoint
  end;
  with FGutterActionsFold do begin
    AddCommand(emcNone,                False, mbLeft,   ccAny,    CDir, [], []);
  end;
  with FGutterActionsFoldCol do begin
    AddCommand(emcCodeFoldCollaps,     False, mbLeft,   ccAny,    CDir, [ssAlt],   [ssAlt, ssCtrl], emcoCodeFoldCollapsOne);
    AddCommand(emcCodeFoldExpand,      False, mbLeft,   ccAny,    CDir, [ssCtrl],  [ssAlt, ssCtrl], emcoCodeFoldExpandAll);
    AddCommand(emcCodeFoldExpand,      False, mbLeft,   ccAny,    CDir, [],        [],              emcoCodeFoldExpandOne);
    if FTextMiddleClick <> moTMIgnore then
      AddCommand(emcCodeFoldCollaps,   False, mbMiddle, ccAny,    CDir, [],       [],               emcoCodeFoldCollapsOne);
  end;
  with FGutterActionsFoldExp do begin
    AddCommand(emcCodeFoldCollaps,     False, mbLeft,   ccAny,    CDir, [],       [ssCtrl], emcoCodeFoldCollapsOne);
    AddCommand(emcCodeFoldCollaps,     False, mbLeft,   ccAny,    CDir, [ssCtrl], [ssCtrl], emcoCodeFoldCollapsAll);
    if FTextMiddleClick <> moTMIgnore then
      AddCommand(emcCodeFoldCollaps,   False, mbMiddle, ccAny,    CDir, [],       [],       emcoCodeFoldCollapsOne);
  end;

end;

procedure TEditorMouseOptions.ResetTextToDefault;
begin
  FMainActions.Clear;
  FSelActions.Clear;

  with FMainActions do begin
    if FAltColumnMode then begin
      AddCommand(emcStartSelections, True, mbLeft, ccSingle, cdDown, [],        [ssShift, ssAlt], emcoSelectionStart);
      AddCommand(emcStartSelections, True, mbLeft, ccSingle, cdDown, [ssShift], [ssShift, ssAlt], emcoSelectionContinue);
      AddCommand(emcStartColumnSelections, True, mbLeft, ccSingle, cdDown, [ssAlt],          [ssShift, ssAlt], emcoSelectionStart);
      AddCommand(emcStartColumnSelections, True, mbLeft, ccSingle, cdDown, [ssShift, ssAlt], [ssShift, ssAlt], emcoSelectionContinue);
    end else begin
      AddCommand(emcStartSelections, True, mbLeft, ccSingle, cdDown, [],        [ssShift], emcoSelectionStart);
      AddCommand(emcStartSelections, True, mbLeft, ccSingle, cdDown, [ssShift], [ssShift], emcoSelectionContinue);
    end;

    if FTextDoubleSelLine then begin
      AddCommand(emcSelectLine, True, mbLeft, ccDouble, cdDown, [], [], emcoSelectLineSmart);
      AddCommand(emcSelectLine, True, mbLeft, ccTriple, cdDown, [], [], emcoSelectLineFull);
    end else begin
      AddCommand(emcSelectWord, True, mbLeft, ccDouble, cdDown, [], []);
      AddCommand(emcSelectLine, True, mbLeft, ccTriple, cdDown, [], []);
    end;
    AddCommand(emcSelectPara, True, mbLeft, ccQuad, cdDown, [], []);

    case FTextMiddleClick of
      moTMPaste:
        AddCommand(emcPasteSelection, True, mbMiddle, ccSingle, cdDown, [], []);
      moTMIgnore: {nothing} ;
      moTMDeclarationJump:
        AddCommand(emcMouseLink, False, mbMiddle, ccSingle, cdDown, [], []);
    end;

    AddCommand(emcContextMenu, FTextRightMoveCaret, mbRight, ccSingle, cdUp, [], []);

    case FTextCtrlLeftClick of
      moTCLJump:
        AddCommand(emcMouseLink, False, mbLeft, ccSingle, cdUp, [SYNEDIT_LINK_MODIFIER], [ssShift, ssAlt, ssCtrl]);
      moTCLNone: {nothing};
      moTCLJumpOrBlock: begin
          AddCommand(emcMouseLink, False, mbLeft, ccSingle, cdUp, [SYNEDIT_LINK_MODIFIER], [ssShift, ssAlt, ssCtrl]);
          AddCommand(emcSynEditCommand, False, mbLeft, ccSingle, cdUp, [SYNEDIT_LINK_MODIFIER], [ssShift, ssAlt, ssCtrl], ecFindBlockOtherEnd, 1);
        end;
    end;
  end;

  if FTextDrag then
    with FSelActions do begin
      AddCommand(emcStartDragMove, False, mbLeft, ccSingle, cdDown, [], []);
    end;

  with FMainActions do begin
    AddCommand(emcSynEditCommand, False, mbExtra1, ccAny, cdDown, [], [], ecJumpBack);
    AddCommand(emcSynEditCommand, False, mbExtra2, ccAny, cdDown, [], [], ecJumpForward);
  end;
end;

procedure TEditorMouseOptions.Assign(Src: TEditorMouseOptions);
begin
  FAltColumnMode      := Src.AltColumnMode;
  FGutterLeft         := Src.GutterLeft;
  FTextMiddleClick    := Src.TextMiddleClick;
  FTextCtrlLeftClick  := Src.TextCtrlLeftClick;
  FTextDoubleSelLine  := Src.TextDoubleSelLine;
  FTextDrag           := Src.TextDrag;
  FTextRightMoveCaret := Src.TextRightMoveCaret;

  FMainActions.Assign         (Src.MainActions);
  FSelActions.Assign          (Src.SelActions);
  FGutterActions.Assign       (Src.GutterActions);
  FGutterActionsFold.Assign   (Src.GutterActionsFold);
  FGutterActionsFoldExp.Assign(Src.GutterActionsFoldExp);
  FGutterActionsFoldCol.Assign(Src.GutterActionsFoldCol);
  FGutterActionsLines.Assign  (Src.GutterActionsLines);
end;

function TEditorMouseOptions.IsPresetEqualToMouseActions: Boolean;
var
  Temp: TEditorMouseOptions;
begin
  Temp := TEditorMouseOptions.Create(nil);
  Temp.Assign(self);
  Temp.ResetTextToDefault;
  Temp.ResetGutterToDefault;
  Result :=
    Temp.MainActions.Equals(self.MainActions) and
    Temp.SelActions.Equals (self.SelActions) and
    Temp.GutterActions.Equals       (self.GutterActions) and
    Temp.GutterActionsFold.Equals   (self.GutterActionsFold) and
    Temp.GutterActionsFoldCol.Equals(self.GutterActionsFoldCol) and
    Temp.GutterActionsFoldExp.Equals(self.GutterActionsFoldExp) and
    Temp.GutterActionsLines.Equals  (self.GutterActionsLines);
  Temp.Free;
end;

function TEditorMouseOptions.CalcCustomSavedActions: Boolean;
var
  Temp: TEditorMouseOptions;
begin
  Temp := TEditorMouseOptions.Create(FOptions);
  Temp.Assign(self);
  Temp.Read;
  Result := not Temp.IsPresetEqualToMouseActions;
  Temp.Free;
  FCustomSavedActions := Result;
end;

{ TEditorOptions }

constructor TEditorOptions.Create;
var
  ConfFileName: String;
  fs: TFileStream;
  res: TLResource;
begin
  inherited Create;
  FTempMouseSettings := TEditorMouseOptions.Create(self);
  ConfFileName := SetDirSeparators(GetPrimaryConfigPath + '/' +
    EditOptsConfFileName);
  CopySecondaryConfigFile(EditOptsConfFileName);
  try
    if (not FileExistsUTF8(ConfFileName)) then
    begin
      DebugLn('NOTE: editor options config file not found - using defaults');
      XMLConfig := TRttiXMLConfig.CreateClean(ConfFileName);
    end
    else
      XMLConfig := TRttiXMLConfig.Create(ConfFileName);
  except
    on E: Exception do
    begin
      DebugLn('WARNING: unable to read ', ConfFileName, ' ', E.Message);
      XMLConfig := Nil;
    end;
  end;

  // set defaults

  // General options
  fShowTabCloseButtons := True;
  FCopyWordAtCursorOnCopyNone := True;
  FShowGutterHints := True;
  fBlockIndent := 2;
  fBlockIndentType := sbitSpace;
  FTrimSpaceType := settEditLine;
  fUndoLimit := 32767;
  fTabWidth := 8;
  FBracketHighlightStyle := sbhsBoth;
  FGutterSeparatorIndex := 3;

  // Display options
  fEditorFont := SynDefaultFontName;
  fEditorFontHeight := SynDefaultFontHeight;
  fDisableAntialiasing := True;

  // Key Mappings
  fKeyMappingScheme := KeyMapSchemeNames[kmsLazarus];
  fKeyMap := TKeyCommandRelationList.Create;

  // Mouse Mappings
  fMouseMap := TSynEditMouseTextActions.Create(nil);
  fMouseMap.ResetDefaults;
  fMouseSelMap := TSynEditMouseSelActions.Create(nil);
  fMouseSelMap.ResetDefaults;
  FMouseGutterActions := TSynEditMouseActionsGutter.Create(nil);
  FMouseGutterActions.ResetDefaults;
  FMouseGutterActionsFold := TSynEditMouseActionsGutterFold.Create(nil);
  FMouseGutterActionsFold.ResetDefaults;
  FMouseGutterActionsFoldCol := TSynEditMouseActionsGutterFoldCollapsed.Create(nil);
  FMouseGutterActionsFoldCol.ResetDefaults;
  FMouseGutterActionsFoldExp := TSynEditMouseActionsGutterFoldExpanded.Create(nil);
  FMouseGutterActionsFoldExp.ResetDefaults;
  FMouseGutterActionsLines := TSynEditMouseActionsLineNum.Create(nil);
  FMouseGutterActionsLines.ResetDefaults;
  // Color options
  fHighlighterList := TEditOptLangList.Create;

  FMarkupCurWordTime := 1500;
  FMarkupCurWordFullLen := 3;
  FMarkupCurWordNoKeyword := True;
  FMarkupCurWordTrim := True;
  FMarkupCurWordNoTimer := False;

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

  // update translation
  EditorOptionsFoldInfoPas[ 0].Name := dlgFoldPasProcedure;
  EditorOptionsFoldInfoPas[ 1].Name := dlgFoldLocalPasVarType;
  EditorOptionsFoldInfoPas[ 2].Name := dlgFoldPasProcBeginEnd;
  EditorOptionsFoldInfoPas[ 3].Name := dlgFoldPasBeginEnd;
  EditorOptionsFoldInfoPas[ 4].Name := dlgFoldPasRepeat;
  EditorOptionsFoldInfoPas[ 5].Name := dlgFoldPasCase;
  EditorOptionsFoldInfoPas[ 6].Name := dlgFoldPasTry;
  EditorOptionsFoldInfoPas[ 7].Name := dlgFoldPasExcept;
  EditorOptionsFoldInfoPas[ 8].Name := dlgFoldPasAsm;
  EditorOptionsFoldInfoPas[ 9].Name := dlgFoldPasProgram;
  EditorOptionsFoldInfoPas[10].Name := dlgFoldPasUnit;
  EditorOptionsFoldInfoPas[11].Name := dlgFoldPasUnitSection;
  EditorOptionsFoldInfoPas[12].Name := dlgFoldPasUses;
  EditorOptionsFoldInfoPas[13].Name := dlgFoldPasVarType;
  EditorOptionsFoldInfoPas[14].Name := dlgFoldPasClass;
  EditorOptionsFoldInfoPas[15].Name := dlgFoldPasClassSection;
  EditorOptionsFoldInfoPas[16].Name := dlgFoldPasRecord;
  EditorOptionsFoldInfoPas[17].Name := dlgFoldPasNestedComment;
  EditorOptionsFoldInfoPas[18].Name := dlgFoldPasIfDef;
  EditorOptionsFoldInfoPas[19].Name := dlgFoldPasUserRegion;

  EditorOptionsDividerInfoPas[0].Name:=dlgDivPasUnitSectionName;
  EditorOptionsDividerInfoPas[1].Name:=dlgDivPasUsesName;
  EditorOptionsDividerInfoPas[2].Name:=dlgDivPasVarGlobalName;
  EditorOptionsDividerInfoPas[3].Name:=dlgDivPasVarLocalName;
  EditorOptionsDividerInfoPas[4].Name:=dlgDivPasStructGlobalName;
  EditorOptionsDividerInfoPas[5].Name:=dlgDivPasStructLocalName;
  EditorOptionsDividerInfoPas[6].Name:=dlgDivPasProcedureName;
  EditorOptionsDividerInfoPas[7].Name:=dlgDivPasBeginEndName;
  EditorOptionsDividerInfoPas[8].Name:=dlgDivPasTryName;

  AdditionalHighlightAttributes[ahaNone]                := '';
  AdditionalHighlightAttributes[ahaTextBlock]           := dlgAddHiAttrTextBlock;
  AdditionalHighlightAttributes[ahaExecutionPoint]      := dlgAddHiAttrExecutionPoint;
  AdditionalHighlightAttributes[ahaEnabledBreakpoint]   := dlgAddHiAttrEnabledBreakpoint;
  AdditionalHighlightAttributes[ahaDisabledBreakpoint]  := dlgAddHiAttrDisabledBreakpoint;
  AdditionalHighlightAttributes[ahaInvalidBreakpoint]   := dlgAddHiAttrInvalidBreakpoint;
  AdditionalHighlightAttributes[ahaUnknownBreakpoint]   := dlgAddHiAttrUnknownBreakpoint;
  AdditionalHighlightAttributes[ahaErrorLine]           := dlgAddHiAttrErrorLine;
  AdditionalHighlightAttributes[ahaIncrementalSearch]   := dlgAddHiAttrIncrementalSearch;
  AdditionalHighlightAttributes[ahaHighlightAll]        := dlgAddHiAttrHighlightAll;
  AdditionalHighlightAttributes[ahaBracketMatch]        := dlgAddHiAttrBracketMatch;
  AdditionalHighlightAttributes[ahaMouseLink]           := dlgAddHiAttrMouseLink;
  AdditionalHighlightAttributes[ahaLineNumber]          := dlgAddHiAttrLineNumber;
  AdditionalHighlightAttributes[ahaLineHighlight]       := dlgAddHiAttrLineHighlight;
  AdditionalHighlightAttributes[ahaModifiedLine]        := dlgAddHiAttrModifiedLine;
  AdditionalHighlightAttributes[ahaCodeFoldingTree]     := dlgAddHiAttrCodeFoldingTree;
  AdditionalHighlightAttributes[ahaHighlightWord]       := dlgAddHiAttrHighlightWord;
  AdditionalHighlightAttributes[ahaFoldedCode]          := dlgAddHiAttrFoldedCode;
  AdditionalHighlightAttributes[ahaWordGroup]           := dlgAddHiAttrWordGroup;
  AdditionalHighlightAttributes[ahaTemplateEditCur]     := dlgAddHiAttrTemplateEditCur;
  AdditionalHighlightAttributes[ahaTemplateEditSync]    := dlgAddHiAttrTemplateEditSync;
  AdditionalHighlightAttributes[ahaTemplateEditOther]   := dlgAddHiAttrTemplateEditOther;
  AdditionalHighlightAttributes[ahaSyncroEditCur]       := dlgAddHiAttrSyncroEditCur;
  AdditionalHighlightAttributes[ahaSyncroEditSync]      := dlgAddHiAttrSyncroEditSync;
  AdditionalHighlightAttributes[ahaSyncroEditOther]     := dlgAddHiAttrSyncroEditOther;
  AdditionalHighlightAttributes[ahaSyncroEditArea]      := dlgAddHiAttrSyncroEditArea;
  AdditionalHighlightAttributes[ahaGutterSeparator]     := dlgAddHiAttrGutterSeparator;
  AdditionalHighlightAttributes[ahaGutter]              := dlgGutter;
  AdditionalHighlightAttributes[ahaRightMargin]         := dlgRightMargin;

  AdditionalHighlightGroupNames[agnText]         := dlgAddHiAttrGroupText;
  AdditionalHighlightGroupNames[agnLine]         := dlgAddHiAttrGroupLine;
  AdditionalHighlightGroupNames[agnTemplateMode] := dlgAddHiAttrGroupTemplateEdit;
  AdditionalHighlightGroupNames[agnSyncronMode]  := dlgAddHiAttrGroupSyncroEdit;
  AdditionalHighlightGroupNames[agnGutter]       := dlgAddHiAttrGroupGutter;

end;

destructor TEditorOptions.Destroy;
begin
  fHighlighterList.Free;
  fMouseMap.Free;
  fMouseSelMap.Free;
  FMouseGutterActions.Free;
  FMouseGutterActionsFold.Free;
  FMouseGutterActionsFoldCol.Free;
  FMouseGutterActionsFoldExp.Free;
  FMouseGutterActionsLines.Free;
  fKeyMap.Free;
  XMLConfig.Free;
  FTempMouseSettings.Free;
  inherited Destroy;
end;

type
  TSynEditMouseSelActionsClass = class of TSynEditMouseSelActions;

procedure TEditorOptions.Load;
// load options from XML file
var
  SynEditOpt: TSynEditorOption;
  SynEditOptName: String;
  i: Integer;
  SynEditOpt2: TSynEditorOption2;
  FileVersion: LongInt;

  Procedure LoadMouseAct(Path: String; MActions: TSynEditMouseActions);
  var
    c, i: Integer;
    MAct: TSynEditMouseActionKeyCmdHelper;
    //ErrShown: Boolean;
  begin
    //ErrShown := False;
    MActions.Clear;
    MAct := TSynEditMouseActionKeyCmdHelper.Create(nil);

    c := XMLConfig.GetValue(Path + 'Count', 0);
    for i := 0 to c - 1 do begin
      try
        MActions.IncAssertLock;
        try
          // If the object would ever be extended, old configs will not have all properties.
          Mact.Clear;
          XMLConfig.ReadObject(Path + 'M' + IntToStr(i) + '/', MAct);
          MActions.Add.Assign(MAct);
        finally
          MActions.DecAssertLock;
        end;
        MActions.AssertNoConflict(MAct);
      except
        MActions.Delete(MActions.Count-1);
        //if not ErrShown then
        //  MessageDlg(dlgMouseOptErrorDup, dlgMouseOptErrorDupText, mtError, [mbOk], 0);
        //ErrShown := True;
      end;
    end;
    MAct.Free;
  end;

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
        eoCaretSkipTab:
          SynEditOptName := 'CaretSkipTab';
        eoAlwaysVisibleCaret:
          SynEditOptName := 'AlwaysVisibleCaret';
        eoEnhanceEndKey:
          SynEditOptName := 'EnhanceEndKey';
        eoFoldedCopyPaste:
          SynEditOptName := 'FoldedCopyPaste';
        eoPersistentBlock:
          SynEditOptName := 'PersistentBlock';
        eoOverwriteBlock:
          SynEditOptName := 'OverwriteBlock';
        eoAutoHideCursor:
          SynEditOptName := 'AutoHideCursor';
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
    fBlockIndentType := GetSynBeautifierIndentType
      (XMLConfig.GetValue('EditorOptions/General/Editor/BlockIndentType',
                          'SpaceIndent'));
    FTrimSpaceType := GetTrimSpaceType
      (XMLConfig.GetValue('EditorOptions/General/Editor/SpaceTrimType',
                          'EditLine'));
    fUndoLimit :=
      XMLConfig.GetValue('EditorOptions/General/Editor/UndoLimit', 32767);
    fTabWidth :=
      XMLConfig.GetValue('EditorOptions/General/Editor/TabWidth', 8);
    FBracketHighlightStyle :=
      TSynEditBracketHighlightStyle(XMLConfig.GetValue('EditorOptions/General/Editor/BracketHighlightStyle', 2));

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
    fGutterWidth :=
      XMLConfig.GetValue('EditorOptions/Display/GutterWidth', 30);
    FGutterSeparatorIndex :=
      XMLConfig.GetValue('EditorOptions/Display/GutterSeparatorIndex', 3);
    fRightMargin :=
      XMLConfig.GetValue('EditorOptions/Display/RightMargin', 80);
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

    FMarkupCurWordTime :=
      XMLConfig.GetValue(
      'EditorOptions/Display/MarkupCurrentWord/Time', 1500);
    FMarkupCurWordFullLen :=
      XMLConfig.GetValue(
      'EditorOptions/Display/MarkupCurrentWord/FullLen', 3);
    // check deprecated value
    if not XMLConfig.GetValue('EditorOptions/Display/MarkupCurrentWord/FullWord', True) then
      FMarkupCurWordFullLen := 0;
    XMLConfig.DeleteValue('EditorOptions/Display/MarkupCurrentWord/FullWord');
    FMarkupCurWordNoKeyword :=
      XMLConfig.GetValue(
      'EditorOptions/Display/MarkupCurrentWord/NoKeyword', True);
    FMarkupCurWordTrim :=
      XMLConfig.GetValue(
      'EditorOptions/Display/MarkupCurrentWord/Trim', True);
    FMarkupCurWordNoTimer :=
      XMLConfig.GetValue(
      'EditorOptions/Display/MarkupCurrentWord/NoTimer', False);

    // Code Tools options
    fAutoBlockCompletion :=
      XMLConfig.GetValue(
      'EditorOptions/CodeTools/AutoBlockCompletion', True);
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
    fAutoRemoveEmptyMethods :=
      XMLConfig.GetValue('EditorOptions/CodeTools/AutoRemoveEmptyMethods', False);

    // Code Folding
    FUseCodeFolding :=
      XMLConfig.GetValue(
      'EditorOptions/CodeFolding/UseCodeFolding', True);

    FTempMouseSettings.Reset;
    // Read deprecated value
    // It is on by default, so only if a user switched it off, actions is required
    if not XMLConfig.GetValue('EditorOptions/General/Editor/DragDropEditing', True) then
      FTempMouseSettings.TextDrag := False;
    XMLConfig.DeleteValue('EditorOptions/General/Editor/DragDropEditing');

    if XMLConfig.GetValue('EditorOptions/General/Editor/AltSetsColumnMode', False) then
      FTempMouseSettings.AltColumnMode := True;
    XMLConfig.DeleteValue('EditorOptions/General/Editor/AltSetsColumnMode');

    if not XMLConfig.GetValue('EditorOptions/General/Editor/CtrlMouseLinks', True) then
      FTempMouseSettings.TextCtrlLeftClick := moTCLNone;
    XMLConfig.DeleteValue('EditorOptions/General/Editor/CtrlMouseLinks');

    if XMLConfig.GetValue('EditorOptions/General/Editor/DoubleClickSelectsLine', False) then
      FTempMouseSettings.TextDoubleSelLine := True;
    XMLConfig.DeleteValue('EditorOptions/General/Editor/DoubleClickSelectsLine');

    FTempMouseSettings.CustomSavedActions := False;
    XMLConfig.ReadObject('EditorOptions/Mouse/Default/', FTempMouseSettings);
    if FTempMouseSettings.CustomSavedActions then begin
      // Load
      LoadMouseAct('EditorOptions/Mouse/Main/', MouseMap);
      LoadMouseAct('EditorOptions/Mouse/MainSelection/', MouseSelMap);
      LoadMouseAct('EditorOptions/Mouse/Gutter/', MouseGutterActions);
      LoadMouseAct('EditorOptions/Mouse/GutterFold/', MouseGutterActionsFold);
      LoadMouseAct('EditorOptions/Mouse/GutterFoldExp/', MouseGutterActionsFoldExp);
      LoadMouseAct('EditorOptions/Mouse/GutterFoldCol/', MouseGutterActionsFoldCol);
      LoadMouseAct('EditorOptions/Mouse/GutterLineNum/', MouseGutterActionsLines);
    end
    else begin
      FTempMouseSettings.ResetTextToDefault;
      FTempMouseSettings.ResetGutterToDefault;
      FTempMouseSettings.WriteBack;
    end;

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
  DefMouseSettings: TEditorMouseOptions;

  Procedure SaveMouseAct(Path: String; MActions: TSynEditMouseActions);
  var
    i, OldCnt: Integer;
    MAct: TSynEditMouseActionKeyCmdHelper;
  begin
    MAct := TSynEditMouseActionKeyCmdHelper.Create(nil);
    OldCnt := XMLConfig.GetValue(Path + 'Count', 0);
    for i := 0 to MActions.Count - 1 do begin
      if MActions[i].Command = emcSynEditCommand then begin
        MAct.Assign(MActions[i]);
        XMLConfig.WriteObject(Path + 'M' + IntToStr(i) + '/', MAct);
      end else
        XMLConfig.WriteObject(Path + 'M' + IntToStr(i) + '/', MActions[i]);
    end;
    XMLConfig.SetValue(Path + 'Count', MActions.Count);
    for i := MActions.Count to OldCnt do
      XMLConfig.DeletePath(Path + 'M' + IntToStr(i));
    MAct.Free;
  end;

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
        eoCaretSkipTab:
          SynEditOptName := 'CaretSkipTab';
        eoAlwaysVisibleCaret:
          SynEditOptName := 'AlwaysVisibleCaret';
        eoEnhanceEndKey:
          SynEditOptName := 'EnhanceEndKey';
        eoFoldedCopyPaste:
          SynEditOptName := 'FoldedCopyPaste';
        eoPersistentBlock:
          SynEditOptName := 'PersistentBlock';
        eoOverwriteBlock:
          SynEditOptName := 'OverwriteBlock';
        eoAutoHideCursor:
          SynEditOptName := 'AutoHideCursor';
        else
          SynEditOptName := '';
      end;
      if SynEditOptName <> '' then
        XMLConfig.SetDeleteValue('EditorOptions/General/Editor/' + SynEditOptName,
          SynEditOpt2 in fSynEditOptions2, SynEditOpt2 in SynEditDefaultOptions2);
    end;

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
    XMLConfig.SetDeleteValue('EditorOptions/General/Editor/BlockIndentType'
      , GetSynBeautifierIndentName(fBlockIndentType), 'SpaceIndent');
    XMLConfig.SetDeleteValue('EditorOptions/General/Editor/SpaceTrimType'
      , GetTrimSpaceName(FTrimSpaceType), 'EditLine');
    XMLConfig.SetDeleteValue('EditorOptions/General/Editor/UndoLimit'
      , fUndoLimit, 32767);
    XMLConfig.SetDeleteValue('EditorOptions/General/Editor/TabWidth'
      , fTabWidth, 8);
    XMLConfig.SetDeleteValue('EditorOptions/General/Editor/BracketHighlightStyle'
      , Ord(FBracketHighlightStyle), 2);

    // Display options
    XMLConfig.SetDeleteValue('EditorOptions/Display/VisibleRightMargin'
      , fVisibleRightMargin, True);
    XMLConfig.SetDeleteValue('EditorOptions/Display/VisibleGutter',
      fVisibleGutter, True);
    XMLConfig.SetDeleteValue('EditorOptions/Display/ShowLineNumbers',
      fShowLineNumbers, True);
    XMLConfig.SetDeleteValue('EditorOptions/Display/ShowOnlyLineNumbersMultiplesOf',
      fShowOnlyLineNumbersMultiplesOf, 5);
    XMLConfig.SetDeleteValue('EditorOptions/Display/GutterWidth',
      fGutterWidth, 30);
    XMLConfig.SetDeleteValue('EditorOptions/Display/GutterSeparatorIndex',
      fGutterSeparatorIndex, 3);
    XMLConfig.SetDeleteValue('EditorOptions/Display/RightMargin',
      fRightMargin, 80);
    XMLConfig.SetDeleteValue('EditorOptions/Display/EditorFont',
      fEditorFont, SynDefaultFontName);
    XMLConfig.SetDeleteValue('EditorOptions/Display/EditorFontHeight'
      ,fEditorFontHeight, SynDefaultFontHeight);
    XMLConfig.SetDeleteValue('EditorOptions/Display/ExtraCharSpacing'
      ,fExtraCharSpacing, 0);
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


    XMLConfig.SetDeleteValue('EditorOptions/Display/MarkupCurrentWord/Time',
      FMarkupCurWordTime, 1500);
    XMLConfig.SetDeleteValue('EditorOptions/Display/MarkupCurrentWord/FullLen',
      FMarkupCurWordFullLen, 3);
    XMLConfig.SetDeleteValue('EditorOptions/Display/MarkupCurrentWord/NoKeyword',
      FMarkupCurWordNoKeyword, True);
    XMLConfig.SetDeleteValue('EditorOptions/Display/MarkupCurrentWord/Trim',
      FMarkupCurWordTrim, True);
    XMLConfig.SetDeleteValue('EditorOptions/Display/MarkupCurrentWord/NoTimer',
      FMarkupCurWordNoTimer, False);

    // Code Tools options
    XMLConfig.SetDeleteValue('EditorOptions/CodeTools/AutoBlockCompletion'
      , fAutoBlockCompletion, True);
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
    XMLConfig.SetDeleteValue(
      'EditorOptions/CodeTools/AutoRemoveEmptyMethods'
      , fAutoRemoveEmptyMethods, False);

    // Code Folding
    XMLConfig.SetDeleteValue('EditorOptions/CodeFolding/UseCodeFolding',
        FUseCodeFolding, True);

    DefMouseSettings := TEditorMouseOptions.Create(self);
    FTempMouseSettings.CalcCustomSavedActions;
    XMLConfig.WriteObject('EditorOptions/Mouse/Default/', FTempMouseSettings, DefMouseSettings);
    DefMouseSettings.Free;
    if FTempMouseSettings.CustomSavedActions then begin
      // Save full settings / based on empty
      SaveMouseAct('EditorOptions/Mouse/Main/',          MouseMap);
      SaveMouseAct('EditorOptions/Mouse/MainSelection/', MouseSelMap);
      SaveMouseAct('EditorOptions/Mouse/Gutter/',        MouseGutterActions);
      SaveMouseAct('EditorOptions/Mouse/GutterFold/',    MouseGutterActionsFold);
      SaveMouseAct('EditorOptions/Mouse/GutterFoldExp/', MouseGutterActionsFoldExp);
      SaveMouseAct('EditorOptions/Mouse/GutterFoldCol/', MouseGutterActionsFoldCol);
      SaveMouseAct('EditorOptions/Mouse/GutterLineNum/', MouseGutterActionsLines);
    end else begin
      // clear unused entries
      XMLConfig.DeletePath('EditorOptions/Mouse/Main');
      XMLConfig.DeletePath('EditorOptions/Mouse/MainSelection');
      XMLConfig.DeletePath('EditorOptions/Mouse/Gutter');
      XMLConfig.DeletePath('EditorOptions/Mouse/GutterFold');
      XMLConfig.DeletePath('EditorOptions/Mouse/GutterFoldExp');
      XMLConfig.DeletePath('EditorOptions/Mouse/GutterFoldCol');
      XMLConfig.DeletePath('EditorOptions/Mouse/GutterLineNum');
    end;

    InvalidateFileStateCache;
    XMLConfig.Flush;
  except
    on E: Exception do
      DebugLn('[TEditorOptions.Save] ERROR: ', e.Message);
  end;
end;

function TEditorOptions.GetAdditionalAttributeName(aha:TAdditionalHilightAttribute): string;
begin
  result:=GetEnumName(TypeInfo(TAdditionalHilightAttribute), ord(aha));
end;

function TEditorOptions.OldAdditionalAttributeName(NewAha: String): string;
var
  AttriIdx: Integer;
begin
  AttriIdx := GetEnumValue(TypeInfo(TAdditionalHilightAttribute), NewAha);
  if AttriIdx < 0 then
    Result := NewAha
  else
    Result := ahaXmlNames[TAdditionalHilightAttribute(AttriIdx)];
end;

class function TEditorOptions.GetGroupCaption: string;
begin
  Result := dlgGroupEditor;
end;

function TEditorOptions.GetSynEditOptionName(SynOption: TSynEditorOption
  ): string;
begin
  case SynOption of
    eoAutoIndent:
      Result := 'AutoIndent';
    eoBracketHighlight:
      Result := 'BracketHighlight';
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

function TEditorOptions.GetSynBeautifierIndentName(IndentType: TSynBeautifierIndentType): string;
begin
  case IndentType of
    sbitSpace:
      Result := 'SpaceIndent';
    sbitCopySpaceTab:
      Result := 'CopySpaceTabIndent';
    sbitPositionCaret:
      Result := 'PositionIndent';
  end;
end;

function TEditorOptions.GetSynBeautifierIndentType(IndentName: String): TSynBeautifierIndentType;
begin
  Result := sbitSpace;
  if IndentName = 'CopySpaceTabIndent' then
    Result := sbitCopySpaceTab
  else if IndentName = 'PositionIndent' then
    Result := sbitPositionCaret;
end;

function TEditorOptions.GetTrimSpaceName(IndentType: TSynEditStringTrimmingType): string;
begin
  case IndentType of
    settLeaveLine:
      Result := 'LeaveLine';
    settEditLine:
      Result := 'EditLine';
    settMoveCaret:
      Result := 'MoveCaret';
    settIgnoreAll:
      Result := 'PosOnly';
  end;
end;

function TEditorOptions.GetTrimSpaceType(IndentName: String): TSynEditStringTrimmingType;
begin
  Result := settLeaveLine;
  if IndentName = 'EditLine' then
    Result := settEditLine
  else if IndentName = 'MoveCaret' then
    Result := settMoveCaret
  else if IndentName = 'PosOnly' then
    Result := settIgnoreAll;
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

function TEditorOptions.GetColorScheme(const SynColorScheme: String): TPascalColorScheme;
begin
  Result := ColorSchemeFactory.GetColorScheme(SynColorScheme);
end;

procedure TEditorOptions.GetDefaultsForPascalAttribute(
  Attr: TSynHighlightElement; const SynColorScheme: String);
var
  AttriName: String;
  Scheme: TPascalColorScheme;
  pha: TPascalHilightAttribute;
  aha: TAdditionalHilightAttribute;
begin
  AttriName := Attr.StoredName;
  if AttriName = '' then
    exit;

  Scheme := GetColorScheme(SynColorScheme);

  for pha := low(pha) to High(pha) do
  begin
    if AttriName <> PascalHilightAttributeNames[pha] then Continue;
    if Scheme.Attributes[pha].FG = clDefault
    then Attr.Foreground := Scheme.Default.FG
    else Attr.Foreground := Scheme.Attributes[pha].FG;
    if Scheme.Attributes[pha].BG = clDefault
    then Attr.Background := Scheme.Default.BG
    else Attr.Background := Scheme.Attributes[pha].BG;
    if Scheme.Attributes[pha].FC = clDefault
    then Attr.FrameColor := Scheme.Default.FC
    else Attr.FrameColor := Scheme.Attributes[pha].FC;
    //DebugLn(['TEditorOptions.GetDefaultsForPascalAttribute SynColorScheme=',SynColorScheme,' AttriName=',AttriName,' BG=',ColorToString(Scheme.Attributes[pha].BG),' Background=',ColorToString(Attr.Background),' SchemeBG=',ColorToString(Scheme.Default.BG)]);
    Attr.Style := Scheme.Attributes[pha].Styles;
    Attr.StyleMask := Scheme.Attributes[pha].StylesMask;
    Exit;
  end;

  for aha := low(aha) to High(aha) do
  begin
    if AttriName <> GetAdditionalAttributeName(aha) then Continue;
    if Scheme.Additional[aha].FG = clDefault
    then Attr.Foreground := Scheme.Default.FG
    else Attr.Foreground := Scheme.Additional[aha].FG;
    if Scheme.Additional[aha].BG = clDefault
    then Attr.Background := Scheme.Default.BG
    else Attr.Background := Scheme.Additional[aha].BG;
    if Scheme.Additional[aha].FC = clDefault
    then Attr.FrameColor := Scheme.Default.FC
    else Attr.FrameColor := Scheme.Additional[aha].FC;
    Attr.Style := Scheme.Additional[aha].Styles;
    Attr.StyleMask := Scheme.Additional[aha].StylesMask;
    Exit;
  end;

  Attr.Foreground := Scheme.Default.FG;
  Attr.Background := Scheme.Default.BG;
  Attr.FrameColor := Scheme.Default.FC;
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
        AttriName := StrToValidXMLName(Syn.Attribute[i].StoredName);
        if AttriName = '' then
          continue;
        // check, if there is a known mapping for this attribute
        if HilightInfo.MappedAttributes <> Nil then
          MappedAttriName := HilightInfo.MappedAttributes.Values[AttriName]
        else
          MappedAttriName := '';
        if MappedAttriName = '' then
          for aha := Low(TAdditionalHilightAttribute)
            to High(TAdditionalHilightAttribute) do
            if AnsiCompareText(GetAdditionalAttributeName(aha), AttriName) = 0 then begin
              MappedAttriName := AttriName;  // all special line color attributes can be mapped 1:1
              break;
            end;
        if MappedAttriName <> '' then
          DefaultSyn := DefaultPascalSyn
        else
          DefaultSyn := VirginSyn;
        // read defaults
        j := DefaultSyn.AttrCount - 1;
        while (j >= 0) do
        begin
          if AnsiCompareText(DefaultSyn.Attribute[j].StoredName, MappedAttriName) = 0 then
          begin
            CopyHiLightAttributeValues(DefaultSyn.Attribute[j], Syn.Attribute[i]);
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
  ReadDefaultsForHighlighterSettings(Syn, SynColorScheme, nil);
  // read settings, that are different from the defaults
  FormatVersion := XMLConfig.GetValue(
    'EditorOptions/Color/Lang' + StrToValidXMLName(Syn.LanguageName) +
    '/Version', 0);
  if FormatVersion > 1 then
    for i := 0 to Syn.AttrCount - 1 do
    begin
      Attri := Syn.Attribute[i];
      // Read version <= 4 if exist, or keep values
      AttriName := OldAdditionalAttributeName(Attri.StoredName);
      if AttriName <> '' then begin
        Path := 'EditorOptions/Color/Lang' + StrToValidXMLName(
          Syn.LanguageName) + '/Scheme' + StrToValidXMLName(
          SynColorScheme) + '/' + StrToValidXMLName(AttriName) + '/';
        Attri.BackGround := XMLConfig.GetValue(Path + 'BackgroundColor/Value',
          Attri.Background);
        Attri.ForeGround := XMLConfig.GetValue(Path + 'ForegroundColor/Value',
          Attri.Foreground);
        Attri.FrameColor := XMLConfig.GetValue(Path + 'FrameColor/Value',
          Attri.FrameColor);
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
      end;
      // Read old single colrs
      if Attri.StoredName = GetAdditionalAttributeName(ahaRightMargin) then
        Attri.Foreground := XMLConfig.GetValue('EditorOptions/Display/RightMarginColor', clBtnFace);
      if Attri.StoredName = GetAdditionalAttributeName(ahaGutter) then
        Attri.Background := XMLConfig.GetValue('EditorOptions/Display/GutterColor', clBtnFace);
      // Read the Version >= 5 if exist, or keep values
      if Attri.StoredName = '' then
        continue;
      Path := 'EditorOptions/Color/Lang' + StrToValidXMLName(
        Syn.LanguageName) + '/Scheme' + StrToValidXMLName(
        SynColorScheme) + '/' + StrToValidXMLName(Attri.StoredName) + '/';
      XMLConfig.ReadObject(Path, Attri, Attri);
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
      Attri.FrameColor := XMLConfig.GetValue(Path + 'FrameColorColor',
        Attri.FrameColor);
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
    ReadDefaultsForHighlighterSettings(OldSyn, SynColorScheme, nil);
    // write colorscheme
    XMLConfig.SetValue('EditorOptions/Color/Lang' +
      StrToValidXMLName(Syn.LanguageName) + '/Version',
      EditorOptsFormatVersion);
    // write all attributes
    for i := 0 to Syn.AttrCount - 1 do
    begin
      Attri := Syn.Attribute[i];
      OldAttri := OldSyn.Attribute[i];
      Path := 'EditorOptions/Color/Lang' + StrToValidXMLName(Syn.LanguageName) +
              '/Scheme' + StrToValidXMLName(SynColorScheme) + '/';
               ;
      // Delete Version <= 4
      AttriName := OldAdditionalAttributeName(Attri.StoredName);
      if AttriName <> '' then
        XMLConfig.DeletePath(Path + StrToValidXMLName(AttriName));
      // Delete old single colors
      if (Syn is TPreviewPasSyn) or (Syn is TSynPasSyn) then begin
        if Attri.StoredName = GetAdditionalAttributeName(ahaRightMargin) then
          XMLConfig.DeleteValue('EditorOptions/Display/RightMarginColor');
        if Attri.StoredName = GetAdditionalAttributeName(ahaGutter) then
          XMLConfig.DeleteValue('EditorOptions/Display/GutterColor');
      end;
    // Write Version >= 5
      if Attri.StoredName = '' then
        continue;
      XMLConfig.WriteObject(Path + StrToValidXMLName(Attri.StoredName) + '/',
                             Attri, OldAttri);
    end;
  finally
    OldSyn.Free;
  end;
end;

procedure TEditorOptions.ReadHighlighterFoldSettings(Syn: TSrcIDEHighlighter);
var
  ConfName: String;
  Path: String;
  i, h: Integer;
  TheFoldInfo: TEditorOptionsFoldRecord;
begin
  h := HighlighterList.FindByHighlighter(Syn);
  if h < 0 then
    h := HighlighterList.FindByName(Syn.LanguageName);
  if h < 0 then exit;

  ReadDefaultsForHighlighterFoldSettings(Syn);

  if (syn is TSynCustomFoldHighlighter) then begin
    TheFoldInfo := EditorOptionsFoldDefaults[HighlighterList[h].TheType];
    for i := 0 to TheFoldInfo.Count - 1 do begin
      ConfName := TheFoldInfo.Info^[i].Xml;
      Path := 'EditorOptions/FoldConfig/Lang' +
        StrToValidXMLName(Syn.LanguageName) + '/Type' + ConfName + '/' ;
    TSynCustomFoldHighlighter(Syn).FoldConfig[TheFoldInfo.Info^[i].Index] :=
      XMLConfig.GetValue(Path + 'Enabled/Value',
        TSynCustomFoldHighlighter(Syn).FoldConfig[TheFoldInfo.Info^[i].Index]);
    end;
  end;
end;

procedure TEditorOptions.ReadDefaultsForHighlighterFoldSettings(Syn: TSrcIDEHighlighter);
var
  i, h: Integer;
  TheFoldInfo: TEditorOptionsFoldRecord;
begin
  h := HighlighterList.FindByHighlighter(Syn);
  if h < 0 then
    h := HighlighterList.FindByName(Syn.LanguageName);
  if h < 0 then exit;
  if (syn is TSynCustomFoldHighlighter) then begin
    TheFoldInfo := EditorOptionsFoldDefaults[HighlighterList[h].TheType];
    for i := 0 to TheFoldInfo.Count - 1 do begin
      TSynCustomFoldHighlighter(Syn).FoldConfig[TheFoldInfo.Info^[i].Index]
        := TheFoldInfo.Info^[i].Enabled;
    end;
  end;
end;

procedure TEditorOptions.WriteHighlighterFoldSettings(Syn: TSrcIDEHighlighter);
var
  DefSyn: TSrcIDEHighlighter;
  i, h:   Integer;
  Path:   String;
  ConfName: String;
  TheFoldInfo: TEditorOptionsFoldRecord;
begin
  h := HighlighterList.FindByHighlighter(Syn);
  if h < 0 then
    h := HighlighterList.FindByName(Syn.LanguageName);
  if h < 0 then exit;

  DefSyn := TCustomSynClass(Syn.ClassType).Create(Nil);
  try
    ReadDefaultsForHighlighterFoldSettings(DefSyn);

    if (syn is TSynCustomFoldHighlighter) then begin
      TheFoldInfo := EditorOptionsFoldDefaults[HighlighterList[h].TheType];
      for i := 0 to TheFoldInfo.Count - 1 do begin
        ConfName := TheFoldInfo.Info^[i].Xml;
        Path := 'EditorOptions/FoldConfig/Lang' +
          StrToValidXMLName(Syn.LanguageName) + '/Type' + ConfName + '/' ;
        XMLConfig.SetDeleteValue(Path + 'Enabled/Value',
          TSynCustomFoldHighlighter(Syn).FoldConfig[TheFoldInfo.Info^[i].Index],
          TSynCustomFoldHighlighter(DefSyn).FoldConfig[TheFoldInfo.Info^[i].Index]);
      end;
    end;

  finally
    DefSyn.Free;
  end;
end;

procedure TEditorOptions.ReadHighlighterDivDrawSettings(Syn: TSrcIDEHighlighter);
var
  TheInfo: TEditorOptionsDividerRecord;
  Conf: TSynDividerDrawConfig;
  ConfName: String;
  Path: String;
  i, h: Integer;
begin
  h := HighlighterList.FindByHighlighter(Syn);
  if h < 0 then
    h := HighlighterList.FindByName(Syn.LanguageName);
  if h < 0 then exit;
  TheInfo := EditorOptionsDividerDefaults[HighlighterList[h].TheType];

  ReadDefaultsForHighlighterDivDrawSettings(Syn);

  // read settings, that are different from the defaults
  for i := 0 to TheInfo.Count - 1 do begin
    Conf := Syn.DividerDrawConfig[i];
    ConfName := TheInfo.Info^[i].Xml;
    Path := 'EditorOptions/DividerDraw/Lang' + StrToValidXMLName(Syn.LanguageName) +
      '/Type' + ConfName + '/' ;
    Conf.MaxDrawDepth := XMLConfig.GetValue(Path + 'MaxDepth/Value',
        Conf.MaxDrawDepth);
    Conf.TopColor := XMLConfig.GetValue(Path + 'TopColor/Value',
        Conf.TopColor);
    Conf.NestColor := XMLConfig.GetValue(Path + 'NestColor/Value',
        Conf.NestColor);
  end;
end;

procedure TEditorOptions.ReadDefaultsForHighlighterDivDrawSettings(Syn: TSrcIDEHighlighter);
var
  TheInfo: TEditorOptionsDividerRecord;
  i, h: Integer;
begin
  h := HighlighterList.FindByHighlighter(Syn);
  if h < 0 then
    h := HighlighterList.FindByName(Syn.LanguageName);
  if h < 0 then exit;
  TheInfo := EditorOptionsDividerDefaults[HighlighterList[h].TheType];
  for i := 0 to TheInfo.Count - 1 do begin
    Syn.DividerDrawConfig[i].MaxDrawDepth := TheInfo.Info^[i].MaxLeveL;
    Syn.DividerDrawConfig[i].TopColor := clDefault;
    Syn.DividerDrawConfig[i].NestColor := clDefault;
  end;
end;

procedure TEditorOptions.WriteHighlighterDivDrawSettings(Syn: TSrcIDEHighlighter);
var
  DefSyn: TSrcIDEHighlighter;
  i, h:   Integer;
  Path:   String;
  Conf, DefConf: TSynDividerDrawConfig;
  TheInfo: TEditorOptionsDividerRecord;
  ConfName: String;
begin
  h := HighlighterList.FindByHighlighter(Syn);
  if h < 0 then
    h := HighlighterList.FindByName(Syn.LanguageName);
  if h < 0 then exit;
  TheInfo := EditorOptionsDividerDefaults[HighlighterList[h].TheType];

  DefSyn := TCustomSynClass(Syn.ClassType).Create(Nil);
  try
    ReadDefaultsForHighlighterDivDrawSettings(DefSyn);
    for i := 0 to TheInfo.Count - 1 do begin
      Conf := Syn.DividerDrawConfig[i];
      DefConf := DefSyn.DividerDrawConfig[i]; // default value
      ConfName := TheInfo.Info^[i].Xml;
      Path := 'EditorOptions/DividerDraw/Lang' +
        StrToValidXMLName(Syn.LanguageName) + '/Type' + ConfName + '/' ;
      XMLConfig.SetDeleteValue(Path + 'MaxDepth/Value', Conf.MaxDrawDepth,
                               DefConf.MaxDrawDepth);
      XMLConfig.SetDeleteValue(Path + 'TopColor/Value', Conf.TopColor,
                               DefConf.TopColor);
      XMLConfig.SetDeleteValue(Path + 'NestColor/Value', Conf.NestColor,
                               DefConf.NestColor);
    end;

  finally
    DefSyn.Free;
  end;
end;

procedure TEditorOptions.GetHighlighterSettings(Syn: TSrcIDEHighlighter);
// read highlight settings from config file
begin
  ReadHighlighterSettings(Syn, '');
  ReadHighlighterFoldSettings(Syn);
  ReadHighlighterDivDrawSettings(Syn);
end;

procedure TEditorOptions.SetHighlighterSettings(Syn: TSrcIDEHighlighter);
// write highlight settings to config file
begin
  WriteHighlighterSettings(Syn, '');
  WriteHighlighterFoldSettings(Syn);
  WriteHighlighterDivDrawSettings(Syn);
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

procedure TEditorOptions.SetMarkupColors(Syn: TSrcIDEHighlighter; aSynEd: TSynEdit;
  SynColorScheme: String = '');
  (* - ASynEd.Highlighter has a copy of all the ahaAttributes
       SetMarkupColors copies them from the highlighter to the synedit
     - For this reason (if called from SourceNotebook)
       Syn and aSynEd.Highlighter should be equal
   *)
  procedure SetMarkupColorByClass(AddHilightAttr: TAdditionalHilightAttribute;
                                  aClass: TSynEditMarkupClass);
  begin
    if assigned(ASynEd.MarkupByClass[aClass]) then
      SetMarkupColor(aSynEd.Highlighter, AddHilightAttr,
                     ASynEd.MarkupByClass[aClass].MarkupInfo);
  end;
  procedure SetGutterColorByClass(AddHilightAttr: TAdditionalHilightAttribute;
                                  aClass: TSynGutterPartBaseClass);
  begin
    if assigned(ASynEd.Gutter.Parts.ByClass[aClass, 0]) then
      SetMarkupColor(aSynEd.Highlighter, AddHilightAttr,
                     ASynEd.Gutter.Parts.ByClass[aClass, 0].MarkupInfo);
  end;

var
  i: integer;
  Attri: TSynHighlighterAttributes;
  Scheme: TPascalColorScheme;
begin
  // Find current color scheme for default colors
  if (SynColorScheme = '') and (aSynEd.Highlighter <> nil) then
    SynColorScheme := ReadColorScheme(aSynEd.Highlighter.LanguageName);
  if (SynColorScheme <> '') then begin
    try
      Scheme := GetColorScheme(SynColorScheme);
      if (Scheme.Default.BG = clNone) or (Scheme.Default.BG = clDefault)
      then aSynEd.Color := clWhite
      else aSynEd.Color := Scheme.Default.BG;
      if (Scheme.Default.FG = clNone) or (Scheme.Default.FG = clDefault)
      then aSynEd.Font.Color := clBlack
      else aSynEd.Font.Color := Scheme.Default.FG;
    except
      aSynEd.Color := clWhite;
      aSynEd.Font.Color := clBlack;
    end;
  end
  else begin
    aSynEd.Color := clWhite;
    aSynEd.Font.Color := clBlack;
  end;

  Attri := GetSynAttributeByAha(aSynEd.Highlighter, ahaGutter);
  if Attri <> nil then
    aSynEd.Gutter.Color := Attri.Background;
  Attri := GetSynAttributeByAha(aSynEd.Highlighter, ahaRightMargin);
  if Attri <> nil then
    aSynEd.RightEdgeColor := Attri.Foreground;

  SetMarkupColor(aSynEd.Highlighter, ahaTextBlock, aSynEd.SelectedColor);
  SetMarkupColor(aSynEd.Highlighter, ahaIncrementalSearch, aSynEd.IncrementColor);
  SetMarkupColor(aSynEd.Highlighter, ahaHighlightAll, aSynEd.HighlightAllColor);
  SetMarkupColor(aSynEd.Highlighter, ahaBracketMatch, aSynEd.BracketMatchColor);
  SetMarkupColor(aSynEd.Highlighter, ahaMouseLink, aSynEd.MouseLinkColor);
  SetMarkupColor(aSynEd.Highlighter, ahaFoldedCode, aSynEd.FoldedCodeColor);
  SetMarkupColor(aSynEd.Highlighter, ahaLineHighlight, aSynEd.LineHighlightColor);
  SetMarkupColorByClass(ahaHighlightWord, TSynEditMarkupHighlightAllCaret);
  SetMarkupColorByClass(ahaWordGroup, TSynEditMarkupWordGroup);
  SetGutterColorByClass(ahaLineNumber, TSynGutterLineNumber);
  SetGutterColorByClass(ahaModifiedLine, TSynGutterChanges);
  SetGutterColorByClass(ahaCodeFoldingTree, TSynGutterCodeFolding);
  SetGutterColorByClass(ahaGutterSeparator, TSynGutterSeparator);

  i := aSynEd.PluginCount - 1;
  while (i >= 0) and not(aSynEd.Plugin[i] is TSynPluginTemplateEdit) do
    dec(i);
  if i >= 0 then begin
    SetMarkupColor(aSynEd.Highlighter, ahaTemplateEditOther,
                   TSynPluginTemplateEdit(aSynEd.Plugin[i]).MarkupInfo);
    SetMarkupColor(aSynEd.Highlighter, ahaTemplateEditCur,
                   TSynPluginTemplateEdit(aSynEd.Plugin[i]).MarkupInfoCurrent);
    SetMarkupColor(aSynEd.Highlighter, ahaTemplateEditSync,
                   TSynPluginTemplateEdit(aSynEd.Plugin[i]).MarkupInfoSync);
  end;
  i := aSynEd.PluginCount - 1;
  while (i >= 0) and not(aSynEd.Plugin[i] is TSynPluginSyncroEdit) do
    dec(i);
  if i >= 0 then begin
    SetMarkupColor(aSynEd.Highlighter, ahaSyncroEditOther,
                   TSynPluginSyncroEdit(aSynEd.Plugin[i]).MarkupInfo);
    SetMarkupColor(aSynEd.Highlighter, ahaSyncroEditCur,
                   TSynPluginSyncroEdit(aSynEd.Plugin[i]).MarkupInfoCurrent);
    SetMarkupColor(aSynEd.Highlighter, ahaSyncroEditSync,
                   TSynPluginSyncroEdit(aSynEd.Plugin[i]).MarkupInfoSync);
    SetMarkupColor(aSynEd.Highlighter, ahaSyncroEditArea,
                   TSynPluginSyncroEdit(aSynEd.Plugin[i]).MarkupInfoArea);
  end;
end;

function TEditorOptions.GetSynAttributeByAha(Syn : TSrcIDEHighlighter;
  Aha: TAdditionalHilightAttribute): TSynHighlighterAttributes;
var
  i: Integer;
begin
  if Syn <> nil
  then begin
    for i := 0 to Syn.AttrCount - 1 do
    begin
      Result := Syn.Attribute[i];
      if Result.StoredName = '' then Continue;
      if SysUtils.CompareText(Result.StoredName, GetAdditionalAttributeName(Aha))= 0
      then exit;
    end;
  end;
  Result := nil;
end;

procedure TEditorOptions.SetMarkupColor(Syn : TSrcIDEHighlighter;
  AddHilightAttr : TAdditionalHilightAttribute; aMarkup : TSynSelectedColor);
var
  Attrib: TSynHighlighterAttributes;
begin
  Attrib := GetSynAttributeByAha(Syn, AddHilightAttr);
  if Attrib <> nil then begin
    aMarkup.Foreground := Attrib.Foreground;
    aMarkup.Background := Attrib.Background;
    aMarkup.FrameColor := Attrib.FrameColor;
    aMarkup.Style      := Attrib.Style;
    aMarkup.StyleMask  := Attrib.StyleMask;
    Exit;
  end;

  // set default
  aMarkup.Foreground := DEFAULT_COLOR_SCHEME.Additional[AddHilightAttr].FG;;
  aMarkup.Background := DEFAULT_COLOR_SCHEME.Additional[AddHilightAttr].BG;
  aMarkup.FrameColor := DEFAULT_COLOR_SCHEME.Additional[AddHilightAttr].FC;
  aMarkup.Style := DEFAULT_COLOR_SCHEME.Additional[AddHilightAttr].Styles;
  aMarkup.StyleMask := DEFAULT_COLOR_SCHEME.Additional[AddHilightAttr].StylesMask;
end;

procedure TEditorOptions.ApplyFontSettingsTo(ASynEdit: TSynEdit);
begin
  ASynEdit.Font.Height := fEditorFontHeight;// set height before name for XLFD !
  ASynEdit.Font.Name := fEditorFont;
  if fDisableAntialiasing then
    ASynEdit.Font.Quality := fqNonAntialiased
  else
    ASynEdit.Font.Quality := fqDefault;
end;

procedure TEditorOptions.GetSynEditSettings(ASynEdit: TSynEdit);
// read synedit settings from config file
var
  MarkCaret: TSynEditMarkupHighlightAllCaret;
  i: Integer;
begin
  // general options
  ASynEdit.Options := fSynEditOptions;
  ASynEdit.Options2 := fSynEditOptions2;
  ASynEdit.BlockIndent := fBlockIndent;
  (ASynEdit.Beautifier as TSynBeautifier).IndentType := fBlockIndentType;
  ASynEdit.TrimSpaceType := FTrimSpaceType;
  ASynEdit.TabWidth := fTabWidth;
  ASynEdit.BracketHighlightStyle := FBracketHighlightStyle;

  // Display options
  ASynEdit.Gutter.Visible := fVisibleGutter;
  ASynEdit.Gutter.AutoSize := true;
  ASynEdit.Gutter.LineNumberPart.Visible := fShowLineNumbers;
  ASynEdit.Gutter.LineNumberPart(0).ShowOnlyLineNumbersMultiplesOf :=
    fShowOnlyLineNumbersMultiplesOf;

  //ASynEdit.Gutter.AutoSize:= fShowLineNumbers;
  ASynEdit.Gutter.CodeFoldPart.Visible := FUseCodeFolding;
  if not FUseCodeFolding then
    ASynEdit.UnfoldAll;

  ASynEdit.Gutter.Width := fGutterWidth;
  ASynEdit.Gutter.SeparatorPart.Visible := FGutterSeparatorIndex <> -1;
  if FGutterSeparatorIndex <> -1 then
  ASynEdit.Gutter.SeparatorPart(0).Index := FGutterSeparatorIndex;

  if fVisibleRightMargin then
    ASynEdit.RightEdge := fRightMargin
  else
    ASynEdit.RightEdge := 0;

  ApplyFontSettingsTo(ASynEdit);
  //debugln(['TEditorOptions.GetSynEditSettings ',ASynEdit.font.height]);

  ASynEdit.ExtraCharSpacing := fExtraCharSpacing;
  ASynEdit.ExtraLineSpacing := fExtraLineSpacing;
  ASynEdit.MaxUndo := fUndoLimit;
  // The Highlighter on the SynEdit will have been initialized with the configured
  // values already (including all the additional-attributes.
  // Just copy the colors from the SynEdit's highlighter to the SynEdit's Markup and co
  SetMarkupColors(ASynEdit.Highlighter, ASynEdit);

  MarkCaret := TSynEditMarkupHighlightAllCaret(ASynEdit.MarkupByClass[TSynEditMarkupHighlightAllCaret]);
  if assigned(MarkCaret) then begin
    if FMarkupCurWordNoTimer then
      MarkCaret.WaitTime := 0
    else
      MarkCaret.WaitTime := FMarkupCurWordTime;
    MarkCaret.FullWord := FMarkupCurWordFullLen > 0;
    MarkCaret.FullWordMaxLen := FMarkupCurWordFullLen;
    MarkCaret.IgnoreKeywords := FMarkupCurWordNoKeyword;
    MarkCaret.Trim := FMarkupCurWordTrim;
  end;

  KeyMap.AssignTo(ASynEdit.KeyStrokes, TSourceEditorWindowInterface);
  i := ASynEdit.PluginCount - 1;
  while (i >= 0) and not(ASynEdit.Plugin[i] is TSynPluginTemplateEdit) do
    dec(i);
  if i >= 0 then begin
    KeyMap.AssignTo(TSynPluginTemplateEdit(ASynEdit.Plugin[i]).Keystrokes, TLazSynPluginTemplateEditForm);
    KeyMap.AssignTo(TSynPluginTemplateEdit(ASynEdit.Plugin[i]).KeystrokesOffCell, TLazSynPluginTemplateEditFormOff);
  end;


  ASynEdit.MouseActions.Assign(MouseMap);
  ASynEdit.MouseSelActions.Assign(MouseSelMap);
  ASynEdit.Gutter.MouseActions.Assign(MouseGutterActions);
  if ASynEdit.Gutter.CodeFoldPart <> nil then begin
    ASynEdit.Gutter.CodeFoldPart.MouseActions.Assign(MouseGutterActionsFold);
    ASynEdit.Gutter.CodeFoldPart.MouseActionsCollapsed.Assign(MouseGutterActionsFoldCol);
    ASynEdit.Gutter.CodeFoldPart.MouseActionsExpanded.Assign(MouseGutterActionsFoldExp);
  end;
  if ASynEdit.Gutter.LineNumberPart <> nil then begin
    ASynEdit.Gutter.LineNumberPart.MouseActions.Assign(MouseGutterActionsLines);
  end;
end;

procedure TEditorOptions.SetSynEditSettings(ASynEdit: TSynEdit);
// copy settings from a synedit to the options
var
  MarkCaret: TSynEditMarkupHighlightAllCaret;
  Attri: TSynHighlighterAttributes;
begin
  // general options
  fSynEditOptions := ASynEdit.Options;
  fSynEditOptions2 := ASynEdit.Options2;
  fBlockIndent := ASynEdit.BlockIndent;
  fBlockIndentType := (ASynEdit.Beautifier as TSynBeautifier).IndentType;
  FTrimSpaceType := ASynEdit.TrimSpaceType;
  fTabWidth := ASynEdit.TabWidth;
  FBracketHighlightStyle := ASynEdit.BracketHighlightStyle;

  // Display options
  fVisibleGutter := ASynEdit.Gutter.Visible;
  fShowLineNumbers := ASynEdit.Gutter.LineNumberPart.Visible;
  fShowOnlyLineNumbersMultiplesOf := ASynEdit.Gutter.LineNumberPart(0).ShowOnlyLineNumbersMultiplesOf;
  FUseCodeFolding := ASynEdit.Gutter.CodeFoldPart.Visible;

  Attri := GetSynAttributeByAha(ASynEdit.Highlighter, ahaGutter);
  if Attri <> nil then
    Attri.Background := ASynEdit.Gutter.Color;
  fGutterWidth := ASynEdit.Gutter.Width;
  if ASynEdit.Gutter.SeparatorPart.Visible then
    FGutterSeparatorIndex := ASynEdit.Gutter.SeparatorPart(0).Index
  else
    FGutterSeparatorIndex := -1;
  fVisibleRightMargin := ASynEdit.RightEdge>0;
  if fVisibleRightMargin then
    fRightMargin:= ASynEdit.RightEdge;

  Attri := GetSynAttributeByAha(ASynEdit.Highlighter, ahaRightMargin);
  if Attri <> nil then
    Attri.Foreground := ASynEdit.RightEdgeColor;

  fEditorFont := ASynEdit.Font.Name;
  fEditorFontHeight := ASynEdit.Font.Height;
  fExtraCharSpacing := ASynEdit.ExtraCharSpacing;
  fExtraLineSpacing := ASynEdit.ExtraLineSpacing;
  fDisableAntialiasing := (ASynEdit.Font.Quality = fqNonAntialiased);
  fUndoLimit := ASynEdit.MaxUndo;

  MarkCaret := TSynEditMarkupHighlightAllCaret(ASynEdit.MarkupByClass[TSynEditMarkupHighlightAllCaret]);
  if assigned(MarkCaret) then begin
    FMarkupCurWordNoTimer := MarkCaret.WaitTime = 0;
    if FMarkupCurWordNoTimer then
      FMarkupCurWordTime := 1500
    else
      FMarkupCurWordTime := MarkCaret.WaitTime;
    FMarkupCurWordFullLen := MarkCaret.FullWordMaxLen;
    if not MarkCaret.FullWord then
      FMarkupCurWordFullLen := 0;
    FMarkupCurWordNoKeyword := MarkCaret.IgnoreKeywords;
    FMarkupCurWordTrim := MarkCaret.Trim;
  end;
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
      if StoredName = '' then
        continue;
      for a := Low(TAdditionalHilightAttribute)
        to High(TAdditionalHilightAttribute) do
        if GetAdditionalAttributeName(a) = StoredName then
          HasSpecialAttribute[a] := True;
    end;
  for a := Low(TAdditionalHilightAttribute) to High(TAdditionalHilightAttribute) do
    if not HasSpecialAttribute[a] then
      Syn.AddSpecialAttribute(AdditionalHighlightAttributes[a],
                              GetAdditionalAttributeName(a));
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


{ TColorSchemeMapping }

constructor TColorSchemeMapping.CreateEx(const AName: string;
  const AColorScheme: TPascalColorScheme);
begin
  Create;   // don't call inherited Create
  FName := AName;
  FColorScheme := AColorScheme;
end;

{ TColorSchemeFactory }

constructor TColorSchemeFactory.Create;
begin
  inherited Create;
  FMappings := TStringList.Create;
end;

destructor TColorSchemeFactory.Destroy;
var
  i: integer;
begin
  if Assigned(FMappings) then
  begin
    for i := 0 to FMappings.Count - 1 do
      TColorSchemeMapping(FMappings.Objects[i]).Free;
    FMappings.Free;
  end;
  inherited Destroy;
end;

procedure TColorSchemeFactory.RegisterScheme(const AName: string;
  const AColorScheme: TPascalColorScheme);
var
  i: integer;
  lMapping: TColorSchemeMapping;
begin
  i := FMappings.IndexOf(UpperCase(AName));
  if i <> -1 then
    raise Exception.Create('Registering a duplicate color scheme name <' + AName + '>')
  else
  begin
    lMapping := TColorSchemeMapping.CreateEx(AName, AColorScheme);
    FMappings.AddObject(UpperCase(AName), lMapping);
  end;
end;

function TColorSchemeFactory.GetColorScheme(const AName: string): TPascalColorScheme;
var
  Idx: integer;
begin
  Idx := FMappings.IndexOf(UpperCase(AName));
  if Idx = -1 then
    raise Exception.Create('No color scheme was registered by the name <' + AName + '>')
  else
    Result := TColorSchemeMapping(FMappings.Objects[Idx]).ColorScheme;
end;

procedure TColorSchemeFactory.GetRegisteredSchemes(AList: TStrings);
var
  i: integer;
begin
  AList.BeginUpdate;
  try
    AList.Clear;
    for i := 0 to FMappings.Count - 1 do
      AList.Add(TColorSchemeMapping(FMappings.Objects[i]).Name);
  finally
    AList.EndUpdate;
  end;
end;

initialization
  RegisterIDEOptionsGroup(GroupEditor, TEditorOptions);
  // register all built-in color schemes
  ColorSchemeFactory.RegisterScheme(DEFAULT_COLOR_SCHEME.Name, DEFAULT_COLOR_SCHEME);
  ColorSchemeFactory.RegisterScheme(TWILIGHT_COLOR_SCHEME.Name, TWILIGHT_COLOR_SCHEME);
  ColorSchemeFactory.RegisterScheme(CLASSIC_COLOR_SCHEME.Name, CLASSIC_COLOR_SCHEME);
  ColorSchemeFactory.RegisterScheme(OCEAN_COLOR_SCHEME.Name, OCEAN_COLOR_SCHEME);
  ColorSchemeFactory.RegisterScheme(DELPHI_COLOR_SCHEME.Name, DELPHI_COLOR_SCHEME);
  {$I lazarus_dci.lrs}

finalization
  ColorSchemeFactory.Free;

end.
