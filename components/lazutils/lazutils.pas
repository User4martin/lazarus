{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit LazUtils;

{$warn 5023 off : no warning about unused units}
interface

uses
  AvgLvlTree, DynamicArray, DynHashArray, DynQueue, EasyLazFreeType, 
  ExtendedStrings, FileUtil, FPCAdds, Laz2_DOM, Laz2_XMLCfg, laz2_XMLRead, 
  laz2_xmlutils, laz2_XMLWrite, laz2_xpath, Laz_DOM, Laz_XMLCfg, Laz_XMLRead, 
  Laz_XMLStreaming, Laz_XMLWrite, LazClasses, lazCollections, 
  LazConfigStorage, LazDbgLog, lazfglhash, LazFileCache, LazFileUtils, 
  LazFreeType, LazFreeTypeFontCollection, LazFreeTypeFPImageDrawer, 
  LazLinkedList, LazLogger, LazLoggerBase, LazLoggerDummy, LazLoggerProfiling, 
  LazMethodList, LazUnicode, LazUTF16, LazUTF8, LazUTF8Classes, 
  LazUTF8SysUtils, LazUtilities, LazUtilsStrConsts, LConvEncoding, lcsvutils, 
  LookupStringList, Maps, Masks, PasWString, StringHashList, TextStrings, 
  Translations, TTCache, TTCalc, TTCMap, TTDebug, TTError, TTFile, TTGLoad, 
  TTInterp, TTLoad, TTMemory, TTObjs, TTProfile, TTRASTER, TTTables, TTTypes, 
  UTF8Process, Laz_AVL_Tree, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('LazUtils', @Register);
end.
