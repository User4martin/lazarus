{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit LazUtils;

interface

uses
  laz2_DOM, Laz2_XMLCfg, laz2_XMLRead, laz2_xmlutils, laz2_XMLWrite, Laz_DOM, 
  Laz_XMLCfg, Laz_XMLRead, Laz_XMLStreaming, Laz_XMLWrite, LazFileUtils, 
  LazFileCache, LUResStrings, LazUTF8, LazDbgLog, paswstring, FileUtil, 
  lazutf8classes, Masks, LazUtilsStrConsts, LConvEncoding, lazutf16, 
  lazutf8sysutils, LazMethodList, AvgLvlTree, LazLogger, LazFreeType, TTCache, 
  TTCalc, TTCMap, TTDebug, TTError, TTFile, TTGLoad, TTInterp, TTLoad, 
  TTMemory, TTObjs, TTProfile, TTRASTER, TTTables, TTTypes, EasyLazFreeType, 
  LazLoggerBase, LazLoggerDummy, LazClasses, LazFreeTypeFontCollection, 
  LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('LazUtils', @Register);
end.
