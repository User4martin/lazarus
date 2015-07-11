{
   File generated automatically by Lazarus Package Manager

   fpmake.pp for LCLBase 1.3

   This file was generated on 02-01-2015
}

{$ifndef ALLPACKAGES} 
{$mode objfpc}{$H+}
program fpmake;

uses fpmkunit;
{$endif ALLPACKAGES}

procedure add_LCLBase(const ADirectory: string);

var
  P : TPackage;
  T : TTarget;

begin
  with Installer do
    begin
    P:=AddPAckage('lclbase');
    P.Version:='1.3';

    P.Directory:=ADirectory;

    P.Flags.Add('LazarusDsgnPkg');

    P.Dependencies.Add('lazutils');
    P.Options.Add('-MObjFPC');
    P.Options.Add('-Scghi');
    P.Options.Add('-O1');
    P.Options.Add('-g');
    P.Options.Add('-gl');
    P.Options.Add('-l');
    P.Options.Add('-vn-');
    P.Options.Add('-vh-');
    P.Options.Add('-vi-');
    P.Options.Add('-vewbq');
    P.IncludePath.Add('include');
    P.UnitPath.Add('forms');
    P.UnitPath.Add('widgetset');
    P.UnitPath.Add('nonwin32');
    P.UnitPath.Add('.');
    T:=P.Targets.AddUnit('alllclunits.pp');
    t.Dependencies.AddUnit('checklst');
    t.Dependencies.AddUnit('clipbrd');
    t.Dependencies.AddUnit('colorbox');
    t.Dependencies.AddUnit('comctrls');
    t.Dependencies.AddUnit('controls');
    t.Dependencies.AddUnit('customtimer');
    t.Dependencies.AddUnit('dbactns');
    t.Dependencies.AddUnit('dbctrls');
    t.Dependencies.AddUnit('dbgrids');
    t.Dependencies.AddUnit('defaulttranslator');
    t.Dependencies.AddUnit('dialogs');
    t.Dependencies.AddUnit('dynamicarray');
    t.Dependencies.AddUnit('dynhasharray');
    t.Dependencies.AddUnit('dynqueue');
    t.Dependencies.AddUnit('extctrls');
    t.Dependencies.AddUnit('extdlgs');
    t.Dependencies.AddUnit('extendedstrings');
    t.Dependencies.AddUnit('extgraphics');
    t.Dependencies.AddUnit('filectrl');
    t.Dependencies.AddUnit('forms');
    t.Dependencies.AddUnit('graphics');
    t.Dependencies.AddUnit('graphmath');
    t.Dependencies.AddUnit('graphtype');
    t.Dependencies.AddUnit('graphutil');
    t.Dependencies.AddUnit('grids');
    t.Dependencies.AddUnit('helpintfs');
    t.Dependencies.AddUnit('icnstypes');
    t.Dependencies.AddUnit('imagelistcache');
    t.Dependencies.AddUnit('imglist');
    t.Dependencies.AddUnit('inipropstorage');
    t.Dependencies.AddUnit('interfacebase');
    t.Dependencies.AddUnit('intfgraphics');
    t.Dependencies.AddUnit('lazhelphtml');
    t.Dependencies.AddUnit('lazhelpintf');
    t.Dependencies.AddUnit('lazlinkedlist');
    t.Dependencies.AddUnit('lclclasses');
    t.Dependencies.AddUnit('lclintf');
    t.Dependencies.AddUnit('lclmemmanager');
    t.Dependencies.AddUnit('lclmessageglue');
    t.Dependencies.AddUnit('lclproc');
    t.Dependencies.AddUnit('lclrescache');
    t.Dependencies.AddUnit('lclstrconsts');
    t.Dependencies.AddUnit('lcltype');
    t.Dependencies.AddUnit('menus');
    t.Dependencies.AddUnit('lclunicodedata');
    t.Dependencies.AddUnit('lclversion');
    t.Dependencies.AddUnit('lmessages');
    t.Dependencies.AddUnit('lresources');
    t.Dependencies.AddUnit('maps');
    t.Dependencies.AddUnit('maskedit');
    t.Dependencies.AddUnit('pairsplitter');
    t.Dependencies.AddUnit('popupnotifier');
    t.Dependencies.AddUnit('postscriptcanvas');
    t.Dependencies.AddUnit('postscriptprinter');
    t.Dependencies.AddUnit('postscriptunicode');
    t.Dependencies.AddUnit('printers');
    t.Dependencies.AddUnit('propertystorage');
    t.Dependencies.AddUnit('rubberband');
    t.Dependencies.AddUnit('shellctrls');
    t.Dependencies.AddUnit('spin');
    t.Dependencies.AddUnit('stdactns');
    t.Dependencies.AddUnit('stdctrls');
    t.Dependencies.AddUnit('stringhashlist');
    t.Dependencies.AddUnit('textstrings');
    t.Dependencies.AddUnit('themes');
    t.Dependencies.AddUnit('tmschema');
    t.Dependencies.AddUnit('toolwin');
    t.Dependencies.AddUnit('translations');
    t.Dependencies.AddUnit('utrace');
    t.Dependencies.AddUnit('xmlpropstorage');
    t.Dependencies.AddUnit('messages');
    t.Dependencies.AddUnit('wsbuttons');
    t.Dependencies.AddUnit('wscalendar');
    t.Dependencies.AddUnit('wschecklst');
    t.Dependencies.AddUnit('wscomctrls');
    t.Dependencies.AddUnit('wscontrols');
    t.Dependencies.AddUnit('wsdesigner');
    t.Dependencies.AddUnit('wsdialogs');
    t.Dependencies.AddUnit('wsextctrls');
    t.Dependencies.AddUnit('wsextdlgs');
    t.Dependencies.AddUnit('wsfactory');
    t.Dependencies.AddUnit('wsforms');
    t.Dependencies.AddUnit('wsgrids');
    t.Dependencies.AddUnit('wsimglist');
    t.Dependencies.AddUnit('wslclclasses');
    t.Dependencies.AddUnit('wsmenus');
    t.Dependencies.AddUnit('wspairsplitter');
    t.Dependencies.AddUnit('wsproc');
    t.Dependencies.AddUnit('wsreferences');
    t.Dependencies.AddUnit('wsspin');
    t.Dependencies.AddUnit('wsstdctrls');
    t.Dependencies.AddUnit('wstoolwin');
    t.Dependencies.AddUnit('actnlist');
    t.Dependencies.AddUnit('asyncprocess');
    t.Dependencies.AddUnit('buttonpanel');
    t.Dependencies.AddUnit('buttons');
    t.Dependencies.AddUnit('calendar');
    t.Dependencies.AddUnit('registerlcl');
    t.Dependencies.AddUnit('valedit');
    t.Dependencies.AddUnit('lazcanvas');
    t.Dependencies.AddUnit('lazdialogs');
    t.Dependencies.AddUnit('lazregions');
    t.Dependencies.AddUnit('customdrawn_common');
    t.Dependencies.AddUnit('customdrawncontrols');
    t.Dependencies.AddUnit('customdrawndrawers');
    t.Dependencies.AddUnit('lazdeviceapis');
    t.Dependencies.AddUnit('ldocktree');
    t.Dependencies.AddUnit('lazfreetypeintfdrawer');
    t.Dependencies.AddUnit('customdrawn_winxp');
    t.Dependencies.AddUnit('customdrawn_android');
    t.Dependencies.AddUnit('arrow');
    t.Dependencies.AddUnit('editbtn');
    t.Dependencies.AddUnit('comboex');
    t.Dependencies.AddUnit('dbextctrls');

    T:=P.Targets.AddUnit('checklst.pas');
    T:=P.Targets.AddUnit('clipbrd.pp');
    T:=P.Targets.AddUnit('colorbox.pas');
    T:=P.Targets.AddUnit('comctrls.pp');
    T:=P.Targets.AddUnit('controls.pp');
    T:=P.Targets.AddUnit('customtimer.pas');
    T:=P.Targets.AddUnit('dbactns.pp');
    T:=P.Targets.AddUnit('dbctrls.pp');
    T:=P.Targets.AddUnit('dbgrids.pas');
    T:=P.Targets.AddUnit('defaulttranslator.pas');
    T:=P.Targets.AddUnit('dialogs.pp');
    T:=P.Targets.AddUnit('dynamicarray.pas');
    T:=P.Targets.AddUnit('dynhasharray.pp');
    T:=P.Targets.AddUnit('dynqueue.pas');
    T:=P.Targets.AddUnit('extctrls.pp');
    T:=P.Targets.AddUnit('extdlgs.pas');
    T:=P.Targets.AddUnit('extendedstrings.pas');
    T:=P.Targets.AddUnit('extgraphics.pas');
    T:=P.Targets.AddUnit('filectrl.pp');
    T:=P.Targets.AddUnit('forms.pp');
    T:=P.Targets.AddUnit('graphics.pp');
    T:=P.Targets.AddUnit('graphmath.pp');
    T:=P.Targets.AddUnit('graphtype.pp');
    T:=P.Targets.AddUnit('graphutil.pp');
    T:=P.Targets.AddUnit('grids.pas');
    T:=P.Targets.AddUnit('helpintfs.pas');
    T:=P.Targets.AddUnit('icnstypes.pas');
    T:=P.Targets.AddUnit('imagelistcache.pas');
    T:=P.Targets.AddUnit('imglist.pp');
    T:=P.Targets.AddUnit('inipropstorage.pas');
    T:=P.Targets.AddUnit('interfacebase.pp');
    T:=P.Targets.AddUnit('intfgraphics.pas');
    T:=P.Targets.AddUnit('lazhelphtml.pas');
    T:=P.Targets.AddUnit('lazhelpintf.pas');
    T:=P.Targets.AddUnit('lazlinkedlist.pas');
    T:=P.Targets.AddUnit('lclclasses.pp');
    T:=P.Targets.AddUnit('lclintf.pas');
    T:=P.Targets.AddUnit('lclmemmanager.pas');
    T:=P.Targets.AddUnit('lclmessageglue.pas');
    T:=P.Targets.AddUnit('lclproc.pas');
    T:=P.Targets.AddUnit('lclrescache.pas');
    T:=P.Targets.AddUnit('lclstrconsts.pas');
    T:=P.Targets.AddUnit('lcltype.pp');
    T:=P.Targets.AddUnit('menus.pp');
    T:=P.Targets.AddUnit('lclunicodedata.pas');
    T:=P.Targets.AddUnit('lclversion.pas');
    T:=P.Targets.AddUnit('lmessages.pp');
    T:=P.Targets.AddUnit('lresources.pp');
    T:=P.Targets.AddUnit('maps.pp');
    T:=P.Targets.AddUnit('maskedit.pp');
    T:=P.Targets.AddUnit('pairsplitter.pas');
    T:=P.Targets.AddUnit('popupnotifier.pas');
    T:=P.Targets.AddUnit('postscriptcanvas.pas');
    T:=P.Targets.AddUnit('postscriptprinter.pas');
    T:=P.Targets.AddUnit('postscriptunicode.pas');
    T:=P.Targets.AddUnit('printers.pas');
    T:=P.Targets.AddUnit('propertystorage.pas');
    T:=P.Targets.AddUnit('rubberband.pas');
    T:=P.Targets.AddUnit('shellctrls.pas');
    T:=P.Targets.AddUnit('spin.pp');
    T:=P.Targets.AddUnit('stdactns.pas');
    T:=P.Targets.AddUnit('stdctrls.pp');
    T:=P.Targets.AddUnit('stringhashlist.pas');
    T:=P.Targets.AddUnit('textstrings.pas');
    T:=P.Targets.AddUnit('themes.pas');
    T:=P.Targets.AddUnit('tmschema.pas');
    T:=P.Targets.AddUnit('toolwin.pp');
    T:=P.Targets.AddUnit('translations.pas');
    T:=P.Targets.AddUnit('utrace.pp');
    T:=P.Targets.AddUnit('xmlpropstorage.pas');
    P.Sources.AddSrc('forms/calendarpopup.pas');
    T:=P.Targets.AddUnit('nonwin32/messages.pp');
    T:=P.Targets.AddUnit('widgetset/wsbuttons.pp');
    T:=P.Targets.AddUnit('widgetset/wscalendar.pp');
    T:=P.Targets.AddUnit('widgetset/wschecklst.pp');
    T:=P.Targets.AddUnit('widgetset/wscomctrls.pp');
    T:=P.Targets.AddUnit('widgetset/wscontrols.pp');
    T:=P.Targets.AddUnit('widgetset/wsdesigner.pp');
    T:=P.Targets.AddUnit('widgetset/wsdialogs.pp');
    T:=P.Targets.AddUnit('widgetset/wsextctrls.pp');
    T:=P.Targets.AddUnit('widgetset/wsextdlgs.pp');
    T:=P.Targets.AddUnit('widgetset/wsfactory.pas');
    T:=P.Targets.AddUnit('widgetset/wsforms.pp');
    T:=P.Targets.AddUnit('widgetset/wsgrids.pp');
    T:=P.Targets.AddUnit('widgetset/wsimglist.pp');
    T:=P.Targets.AddUnit('widgetset/wslclclasses.pp');
    T:=P.Targets.AddUnit('widgetset/wsmenus.pp');
    T:=P.Targets.AddUnit('widgetset/wspairsplitter.pp');
    T:=P.Targets.AddUnit('widgetset/wsproc.pp');
    T:=P.Targets.AddUnit('widgetset/wsreferences.pp');
    T:=P.Targets.AddUnit('widgetset/wsspin.pp');
    T:=P.Targets.AddUnit('widgetset/wsstdctrls.pp');
    T:=P.Targets.AddUnit('widgetset/wstoolwin.pp');
    T:=P.Targets.AddUnit('actnlist.pas');
    T:=P.Targets.AddUnit('asyncprocess.pp');
    T:=P.Targets.AddUnit('buttonpanel.pas');
    T:=P.Targets.AddUnit('buttons.pp');
    T:=P.Targets.AddUnit('calendar.pp');
    T:=P.Targets.AddUnit('registerlcl.pas');
    T:=P.Targets.AddUnit('valedit.pas');
    T:=P.Targets.AddUnit('lazcanvas.pas');
    T:=P.Targets.AddUnit('lazdialogs.pas');
    T:=P.Targets.AddUnit('lazregions.pas');
    T:=P.Targets.AddUnit('customdrawn_common.pas');
    T:=P.Targets.AddUnit('customdrawncontrols.pas');
    T:=P.Targets.AddUnit('customdrawndrawers.pas');
    T:=P.Targets.AddUnit('lazdeviceapis.pas');
    T:=P.Targets.AddUnit('ldocktree.pas');
    T:=P.Targets.AddUnit('lazfreetypeintfdrawer.pas');
    T:=P.Targets.AddUnit('customdrawn_winxp.pas');
    T:=P.Targets.AddUnit('customdrawn_android.pas');
    T:=P.Targets.AddUnit('arrow.pp');
    T:=P.Targets.AddUnit('editbtn.pas');
    T:=P.Targets.AddUnit('comboex.pas');
    T:=P.Targets.AddUnit('dbextctrls.pp');

    // copy the compiled file, so the IDE knows how the package was compiled
    P.InstallFiles.Add('LCLBase.compiled',AllOSes,'$(unitinstalldir)');

    end;
end;

{$ifndef ALLPACKAGES}
begin
  add_LCLBase('');
  Installer.Run;
end.
{$endif ALLPACKAGES}
