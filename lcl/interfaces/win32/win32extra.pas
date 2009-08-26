{
  Extra Win32 code that's not in the RTL.
  Copyright (C) 2001, 2002 Keith Bowes. 
  Modified by Marc Weustink

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
}

unit Win32Extra;

{$mode objfpc}{$H+}
{$I win32defines.inc}

{$IFDEF TRACE}
  {$ASSERTIONS ON}
{$ENDIF}

{$PACKRECORDS C}
{$SMARTLINK ON}

interface

uses 
  InterfaceBase, Classes, LCLType, Windows, GraphType, SysUtils;

{ Win32 API constants not included in windows.pp }
const
  // progress bar
  PBM_SETMARQUEE = WM_USER + 10;
  PBS_MARQUEE    = $08;

  // missed messages
  WM_NCMOUSELEAVE = $2A2; // declared in fpc 2.3.1

type
  tagMENUBARINFO = record
    cbSize: DWORD;
    rcBar: TRect;
    hMenu: HMENU;
    hwndMenu: HWND;
    Flags: DWORD;
  end;
  MENUBARINFO = tagMENUBARINFO;
  PMENUBARINFO = ^tagMENUBARINFO;

  // Window information snapshot
  tagWINDOWINFO = record
    cbSize: DWORD;
    rcWindow: TRect;
    rcClient: TRect;
    dwStyle: DWORD;
    dwExStyle: DWORD;
    dwWindowStatus: DWORD;
    cxWindowBorders: UINT;
    cyWindowBorders: UINT;
    atomWindowType: ATOM;
    wCreatorVersion: WORD;
  end;
  WINDOWINFO = tagWINDOWINFO;
  PWINDOWINFO = ^tagWINDOWINFO;

// AlphaBlend is only defined for win98&2k and up
// load dynamic and use ownfunction if not defined
var
  AlphaBlend: function(hdcDest: HDC; nXOriginDest, nYOriginDest, nWidthDest, nHeightDest: Integer; hdcSrc: HDC; nXOriginSrc, nYOriginSrc, nWidthSrc, nHeightSrc: Integer; blendFunction: TBlendFunction): BOOL; stdcall;
  GradientFill: function(DC: HDC; p2: PTriVertex; p3: ULONG; p4: Pointer; p5, p6: ULONG): BOOL; stdcall;
  GetComboBoxInfo: function(hwndCombo: HWND; pcbi: PComboboxInfo): BOOL; stdcall;
  GetMenuBarInfo: function(hwnd: HWND; idObject: LONG; idItem: LONG; pmbi: PMENUBARINFO): BOOL; stdcall;
  GetWindowInfo: function(hwnd: HWND; pwi: PWINDOWINFO): BOOL; stdcall;
  EnumDisplayMonitors: function(hdc: HDC; lprcClip: PRect; lpfnEnum: MonitorEnumProc; dwData: LPARAM): LongBool; stdcall;
  GetMonitorInfo: function(hMonitor: HMONITOR; lpmi: PMonitorInfo): Boolean; stdcall;
  MonitorFromWindow: function(hWnd: HWND; dwFlags: DWORD): HMONITOR; stdcall;
  MonitorFromRect: function(lprcScreenCoords: PRect; dwFlags: DWord): HMONITOR; stdcall;
  MonitorFromPoint: function(ptScreenCoords: TPoint; dwFlags: DWord): HMONITOR; stdcall;

const
  // ComCtlVersions
  ComCtlVersionIE3   = $00040046;
  ComCtlVersionIE4   = $00040047;
  ComCtlVersionIE401 = $00040048;
  ComCtlVersionIE5   = $00050050;
  ComCtlVersionIE501 = $00050051;
  ComCtlVersionIE6   = $00060000;

type
  SHSTOCKICONINFO = record
    cbSize: DWORD;
    hIcon: HICON;
    iSysImageIndex: integer;
    iIcon: integer;
    szPath: array[0..MAX_PATH - 1] of WCHAR;
  end;
  TSHSTOCKICONINFO = SHSTOCKICONINFO;
  PSHSTOCKICONINFO = ^SHSTOCKICONINFO;

var
  SHGetStockIconInfo: function(siid: integer; uFlags: UINT; psii: PSHSTOCKICONINFO): HResult; stdcall;

const
  SIID_SHIELD = 77;
  SHGFI_SMALLICON = $000000001;
  SHGFI_LARGEICON = $000000000;
  SHGFI_ICON      = $000000100;

implementation

uses
  Win32Proc;

const
  xPRIMARY_MONITOR = $12340042;

{$PACKRECORDS NORMAL}

function _AlphaBlend(hdcDest: HDC; nXOriginDest, nYOriginDest, nWidthDest, nHeightDest: Integer; hdcSrc: HDC; nXOriginSrc, nYOriginSrc, nWidthSrc, nHeightSrc: Integer; blendFunction: TBlendFunction): BOOL; stdcall;
var
  SCA: Byte absolute blendFunction.SourceConstantAlpha;

  R: TRect;
  DC, TmpDC: HDC;
  OldBmp, OldTmpBmp, SrcBmp, DstBmp, TmpBmp, AlphaBmp: HBITMAP;
  StretchSrc: Boolean;
  SrcSection, DstSection: TDIBSection;
  Info: record
    Header: TBitmapInfoHeader;
    Colors: array[0..3] of Cardinal; // reserve extra color for colormasks
  end;

  SrcBytesPtr, DstBytesPtr, TmpBytesPtr, AlphaBytesPtr: Pointer;
  SrcLinePtr, DstLinePtr: PByte;
  CleanupSrc, CleanupSrcPtr, CleanupDst, CleanupAlpha: Boolean;
  SrcSize: PtrUInt;
  SrcPixelBytes, DstPixelBytes: Byte;
  SrcRowStride, DstRowStride: Integer;
  SrcLineOrder: TRawImageLineOrder;

  X, Y: Integer;
  SrcRGBA, TmpRGBA, DstRGBA: PRGBAQuad;
  SrcAlpha: PByte;
  NotAlpha: Byte;
begin
  if nXOriginSrc < 0 then Exit(False);
  if nYOriginSrc < 0 then Exit(False);
  if nWidthSrc < 0 then Exit(False);
  if nHeightSrc < 0 then Exit(False);
  if nWidthDest < 0 then Exit(False);
  if nHeightDest < 0 then Exit(False);

  if blendFunction.SourceConstantAlpha = 0
  then Exit(True); // nothing to do

  if (blendFunction.AlphaFormat = 0)
  and (blendFunction.SourceConstantAlpha = 255)
  then begin
    // simple strechblt
    Result := StretchBlt(hdcDest, nXOriginDest, nYOriginDest, nWidthDest, nHeightDest, hdcSrc, nXOriginSrc, nYOriginSrc, nWidthSrc, nHeightSrc, SRCCOPY);
    Exit;
  end;

  // get source info, atleast bitmap, if possible also section
  if GetObjectType(hdcSrc) <> OBJ_MEMDC then Exit(False);
  SrcBmp := GetCurrentObject(hdcSrc, OBJ_BITMAP);
  if GetObject(SrcBmp, SizeOf(SrcSection), @SrcSection) = 0 then Exit(False);
  if nXOriginSrc + nWidthSrc > SrcSection.dsBm.bmWidth then Exit(False);
  if nYOriginSrc + nHeightSrc > SrcSection.dsBm.bmHeight then Exit(False);

  if (blendFunction.AlphaFormat = AC_SRC_ALPHA) and (SrcSection.dsBm.bmBitsPixel <> 32) then Exit(False); // invalid

  // get destination info, atleast bitmap, if possible also section
  if WindowsVersion in [wv95, wv98]
  then begin
    // under windows 98 GetObjectType() sometimes produce AV inside and
    // as result our debugger stopes and show exception
    // lazarus is not alone application with such problem under windows 98
    // here is workaround for windows 9x
    DstBmp := GetCurrentObject(hdcDest, OBJ_BITMAP);
    DstSection.dsBm.bmBits := nil;
    if (DstBmp <> 0)
    and ((GetObject(DstBmp, SizeOf(DstSection), @DstSection) < SizeOf(TDIBSection)) or (DstSection.dsBm.bmBits = nil))
    then DstBmp := 0;
  end
  else begin
    if GetObjectType(hdcDest) = OBJ_MEMDC
    then DstBmp := GetCurrentObject(hdcDest, OBJ_BITMAP)
    else DstBmp := 0;
    if (DstBmp <> 0) and (GetObject(DstBmp, SizeOf(DstSection), @DstSection) = 0)
    then DstBmp := 0;
  end;

  if (DstBmp = 0)
  then begin
    // GetCurrentObject can only be used on memory devices,
    // so fill in some values manually
    DstSection.dsBm.bmWidth := GetDeviceCaps(hdcDest, HORZRES);
    DstSection.dsBm.bmHeight := GetDeviceCaps(hdcDest, VERTRES);
    DstSection.dsBm.bmBitsPixel := GetDeviceCaps(hdcDest, BITSPIXEL);
    DstSection.dsBm.bmBits := nil;
  end;

  // docs doesn't require dest retangle inside dest.
  // however if dest rect is outside the destination, we're done here
  if nXOriginDest + nWidthDest < 0 then Exit(True);
  if nYOriginDest + nHeightDest < 0 then Exit(True);
  if nXOriginDest >= DstSection.dsBm.bmWidth then Exit(True);
  if nYOriginDest >= DstSection.dsBm.bmHeight then Exit(True);
  
  // get lineorder of source so we use the right direction
  SrcLineOrder := GetBitmapOrder(SrcSection.dsBm, SrcBmp);

  // setup info shared by alpha, source and destination bytes
  FillChar(Info, sizeof(Info), 0);
  Info.Header.biSize := sizeof(Windows.TBitmapInfoHeader);
  Info.Header.biWidth := nWidthDest;
  if SrcLineOrder = riloBottomToTop
  then Info.Header.biHeight := nHeightDest
  else Info.Header.biHeight := -nHeightDest;
  Info.Header.biPlanes := 1;
  Info.Header.biBitCount := 32;
  Info.Header.biSizeImage := nWidthDest * nHeightDest * 4;
  Info.Header.biCompression := BI_BITFIELDS;
  // when 24bpp, CE only supports B8G8R8 encoding
  Info.Colors[0] := $FF0000; {le-red}
  Info.Colors[1] := $00FF00; {le-green}
  Info.Colors[2] := $0000FF; {le-blue}

  StretchSrc := (nWidthDest <> nWidthSrc) or (nHeightDest <> nHeightSrc);
  if StretchSrc
  then begin
    // we need to strech the source

    // create alphabmp
    if blendFunction.AlphaFormat = AC_SRC_ALPHA
    then begin
      // create alpha source data
      R := Classes.Rect(nXOriginSrc, nYOriginSrc, nXOriginSrc + nWidthSrc, nYOriginSrc + nHeightSrc);
      if not GetBitmapBytes(SrcSection.dsBm, SrcBmp, R, rileDWordBoundary, SrcLineOrder, SrcBytesPtr, SrcSize) then Exit(False);

      // set info to source size
      Info.Header.biWidth := nWidthSrc;
      if SrcLineOrder = riloBottomToTop
      then Info.Header.biHeight := nHeightSrc
      else Info.Header.biHeight := -nHeightSrc;
      Info.Header.biSizeImage := nWidthSrc * nHeightSrc * 4;

      // create temp bitmap to store orginal grayscale alpha
      TmpBmp := CreateDIBSection(hdcSrc, PBitmapInfo(@Info)^, DIB_RGB_COLORS, TmpBytesPtr, 0, 0);
      if TmpBmp = 0 then Exit(False);
      if TmpBytesPtr = nil
      then begin
        FreeMem(SrcBytesPtr);
        DeleteObject(TmpBmp);
        Exit(False);
      end;

      // create grayscale image from alpha
      TmpRGBA := TmpBytesPtr;
      SrcRGBA := SrcBytesPtr;
      while SrcSize > 0 do
      begin
        TmpRGBA^.Blue := SrcRGBA^.Alpha;
        TmpRGBA^.Green := SrcRGBA^.Alpha;
        TmpRGBA^.Red := SrcRGBA^.Alpha;
        TmpRGBA^.Alpha := 255;
        Inc(SrcRGBA);
        Inc(TmpRGBA);
        Dec(SrcSize, 4);
      end;

      // restore to destination size
      Info.Header.biWidth := nWidthDest;
      if SrcLineOrder = riloBottomToTop
      then Info.Header.biHeight := nHeightDest
      else Info.Header.biHeight := -nHeightDest;
      Info.Header.biSizeImage := nWidthDest * nHeightDest * 4;

      // create bitmap to store stretched grayscale alpha
      AlphaBmp := CreateDIBSection(hdcSrc, PBitmapInfo(@Info)^, DIB_RGB_COLORS, AlphaBytesPtr, 0, 0);
      if (AlphaBmp = 0) or (AlphaBytesPtr = nil)
      then begin
        FreeMem(SrcBytesPtr);
        DeleteObject(TmpBmp);
        DeleteObject(AlphaBmp);
        Exit(False);
      end;

      // stretch grayscale alpha bitmap
      DC := CreateCompatibleDC(hdcSrc);
      OldBmp := SelectObject(DC, AlphaBmp);
      TmpDC := CreateCompatibleDC(hdcSrc);
      OldTmpBmp := SelectObject(TmpDC, TmpBmp);
      StretchBlt(DC, 0, 0, nWidthDest, nHeightDest, TmpDC, 0, 0, nWidthSrc, nHeightSrc, SRCCOPY);
      SelectObject(DC, OldBmp);
      DeleteDC(DC);
      SelectObject(TmpDC, OldTmpBmp);
      DeleteDC(TmpDC);
      DeleteObject(TmpBmp);
      FreeMem(SrcBytesPtr);

      // as long as AlphaBmp exists, AlphaBytesPtr is valid.
      CleanupAlpha := True;
    end
    else begin
      CleanupAlpha := False;
    end;

    // create new srcbmp
    SrcBmp := CreateDIBSection(hdcSrc, PBitmapInfo(@Info)^, DIB_RGB_COLORS, SrcBytesPtr, 0, 0);
    if (SrcBmp = 0) or (SrcBytesPtr = nil)
    then begin
      DeleteObject(AlphaBmp);
      DeleteObject(SrcBmp);
      Exit(False);
    end;
    SrcSize := Info.Header.biSizeImage;
    CleanupSrc := True;
    CleanupSrcPtr := False;
    SrcPixelBytes := 4;
    SrcRowStride := nWidthDest * SrcPixelBytes;

    DC := CreateCompatibleDC(hdcSrc);
    OldBmp := SelectObject(DC, SrcBmp);
    StretchBlt(DC, 0, 0, nWidthDest, nHeightDest, hdcSrc, nXOriginSrc, nYOriginSrc, nWidthSrc, nHeightSrc, SRCCOPY);
    SelectObject(DC, OldBmp);
    DeleteDC(DC);

    // adjust source size
    nWidthSrc := nWidthDest;
    nHeightSrc := nHeightDest;
    nXOriginSrc := 0;
    nYOriginSrc := 0;
  end
  else begin
    // only get source data
    SrcPixelBytes := SrcSection.dsBm.bmBitsPixel shr 3;
    if SrcSection.dsBm.bmBits <> nil
    then begin
      // source is a dibsection :)
      SrcBytesPtr := SrcSection.dsBm.bmBits;
      SrcRowStride := SrcSection.dsBm.bmWidthBytes;
      CleanupSrc := False;
      CleanupSrcPtr := False;
    end
    else begin
      R := Classes.Rect(nXOriginSrc, nYOriginSrc, nXOriginSrc + nWidthSrc, nYOriginSrc + nHeightSrc);
      if not GetBitmapBytes(SrcSection.dsBm, SrcBmp, R, rileDWordBoundary, SrcLineOrder, SrcBytesPtr, SrcSize) then Exit;
      SrcRowStride := nWidthSrc * SrcPixelBytes;
      CleanupSrc := False;
      CleanupSrcPtr := True;
      nXOriginSrc := 0;
      nYOriginSrc := 0;
    end;
    AlphaBytesPtr := nil;
    CleanupAlpha := False;
  end;

  // if a palette destination or destination isn't a section, create a temp DIB
  if (DstSection.dsBm.bmBitsPixel < 24)
  or (DstSection.dsBm.bmBits = nil)
  or (DstSection.dsBmih.biCompression <> BI_RGB)
  then begin
    // create temp dib
    DstBmp := CreateDIBSection(hdcSrc, PBitmapInfo(@Info)^, DIB_RGB_COLORS, DstBytesPtr, 0, 0);
    // copy destination
    DC := CreateCompatibleDC(hdcDest);
    OldBmp := SelectObject(DC, DstBmp);
    BitBlt(DC, 0, 0, nWidthDest, nHeightDest, hdcDest, nXOriginDest, nYOriginDest, SRCCOPY);
    SelectObject(DC, OldBmp);
    DeleteDC(DC);
    DstPixelBytes := 4;
    DstRowStride := nWidthDest * DstPixelBytes;
    CleanupDst := True;
  end
  else begin
    DstBytesPtr := DstSection.dsBm.bmBits;
    DstPixelBytes := DstSection.dsBm.bmBitsPixel shr 3;
    DstRowStride := DstSection.dsBm.bmWidthBytes;
    Inc(PByte(DstBytesPtr), nXOriginDest + nYOriginDest * DstRowStride);
    CleanupDst := False;
  end;

  // blend image
  SrcLinePtr := SrcBytesPtr;
  Inc(SrcLinePtr, nXOriginSrc * SrcPixelBytes + nYOriginSrc * SrcRowStride);
  DstLinePtr := DstBytesPtr;

  if blendFunction.AlphaFormat = AC_SRC_ALPHA
  then begin
    if AlphaBytesPtr <> nil
    then SrcAlpha := AlphaBytesPtr;

    if SCA {blendFunction.SourceConstantAlpha} = 255
    then begin
      for y := 1 to nHeightDest do
      begin
        SrcRGBA := Pointer(SrcLinePtr);
        if AlphaBytesPtr = nil
        then SrcAlpha := @SrcRGBA^.Alpha;
        DstRGBA := Pointer(DstLinePtr);
        for x := 1 to nWidthDest do
        begin
          if SrcAlpha^ <> 0
          then begin
            NotAlpha := not SrcAlpha^;
            DstRGBA^.Red   := SrcRgba^.Red   + (DstRGBA^.Red   * NotAlpha) div 255;
            DstRGBA^.Green := SrcRgba^.Green + (DstRGBA^.Green * NotAlpha) div 255;
            DstRGBA^.Blue  := SrcRgba^.Blue  + (DstRGBA^.Blue  * NotAlpha) div 255;
            if DstPixelBytes = 4
            then DstRGBA^.Alpha := SrcAlpha^ + (DstRGBA^.Alpha * NotAlpha) div 255;
          end;
          Inc(SrcRGBA);
          Inc(SrcAlpha, 4);
          Inc(PByte(DstRGBA), DstPixelBytes);
        end;
        Inc(SrcLinePtr, SrcRowStride);
        Inc(DstLinePtr, DstRowStride);
      end;
    end
    else begin
      for y := 1 to nHeightDest do
      begin
        SrcRGBA := Pointer(SrcLinePtr);
        if AlphaBytesPtr = nil
        then SrcAlpha := @SrcRGBA^.Alpha;
        DstRGBA := Pointer(DstLinePtr);
        for x := 1 to nWidthDest do
        begin
          if SrcAlpha^ <> 0
          then begin
            NotAlpha := not SrcAlpha^;
            DstRGBA^.Red   := (SrcRgba^.Red   * SCA + DstRGBA^.Red   * NotAlpha) div 255;
            DstRGBA^.Green := (SrcRgba^.Green * SCA + DstRGBA^.Green * NotAlpha) div 255;
            DstRGBA^.Blue  := (SrcRgba^.Blue  * SCA + DstRGBA^.Blue  * NotAlpha) div 255;
            if DstPixelBytes = 4
            then DstRGBA^.Alpha := (SrcAlpha^ * SCA + DstRGBA^.Alpha * NotAlpha) div 255;
          end;
          Inc(SrcRGBA);
          Inc(SrcAlpha, 4);
          Inc(PByte(DstRGBA), DstPixelBytes);
        end;
        Inc(SrcLinePtr, SrcRowStride);
        Inc(DstLinePtr, DstRowStride);
      end;
    end;
  end
  else begin
    // no source alpha
    NotAlpha := not SCA;
    for y := 1 to nHeightDest do
    begin
      SrcRGBA := Pointer(SrcLinePtr);
      if AlphaBytesPtr = nil
      then SrcAlpha := @SrcRGBA^.Alpha;
      DstRGBA := Pointer(DstLinePtr);
      for x := 1 to nWidthDest do
      begin
        DstRGBA^.Red :=   (SrcRGBA^.Red   * SCA + DstRGBA^.Red   * NotAlpha) div 255;
        DstRGBA^.Green := (SrcRGBA^.Green * SCA + DstRGBA^.Green * NotAlpha) div 255;
        DstRGBA^.Blue :=  (SrcRGBA^.Blue  * SCA + DstRGBA^.Blue  * NotAlpha) div 255;
        if (DstPixelBytes = 4) and (SrcPixelBytes = 4)
        then DstRGBA^.Alpha := (SrcAlpha^ * SCA + DstRGBA^.Alpha * NotAlpha) div 255;
        Inc(PByte(SrcRGBA), SrcPixelBytes);
        Inc(PByte(DstRGBA), DstPixelBytes);
        Inc(SrcAlpha, 4);
      end;
      Inc(SrcLinePtr, SrcRowStride);
      Inc(DstLinePtr, DstRowStride);
    end;
  end;

  // Replace destination if needed and do cleanup
  if CleanupDst
  then begin
    DC := CreateCompatibleDC(hdcDest);
    OldBmp := SelectObject(DC, DstBmp);
    BitBlt(hdcDest, nXOriginDest, nYOriginDest, nWidthDest, nHeightDest, DC, 0, 0, SRCCOPY);
    SelectObject(DC, OldBmp);
    DeleteDC(DC);
    DeleteObject(DstBmp);
  end;
  if CleanupSrc
  then DeleteObject(SrcBmp);
  if CleanupSrcPtr
  then FreeMem(SrcBytesPtr);
  if CleanupAlpha
  then DeleteObject(AlphaBmp);
end;

// win98 only supports dibsections, so if not a dib section,
// we draw ourselves
{var
  AlphaBlend98: function(hdcDest: HDC; nXOriginDest, nYOriginDest, nWidthDest, nHeightDest: Integer; hdcSrc: HDC; nXOriginSrc, nYOriginSrc, nWidthSrc, nHeightSrc: Integer; blendFunction: TBlendFunction): BOOL; stdcall;
}

function _AlphaBlend98(hdcDest: HDC; nXOriginDest, nYOriginDest, nWidthDest, nHeightDest: Integer; hdcSrc: HDC; nXOriginSrc, nYOriginSrc, nWidthSrc, nHeightSrc: Integer; blendFunction: TBlendFunction): BOOL; stdcall;
begin
  // we can check the bitmaptypes here and call AlphaBlend98, but for now, just call own implementation
  Result := _AlphaBlend(hdcDest, nXOriginDest, nYOriginDest, nWidthDest, nHeightDest, hdcSrc, nXOriginSrc, nYOriginSrc, nWidthSrc, nHeightSrc, blendFunction);
end;

function _GradientFill(DC: HDC; p2: PTriVertex; p3: ULONG; p4: Pointer; p5, p6: ULONG): BOOL;
begin
  Result := False;
end;

function _GetComboboxInfo(hwndCombo: HWND; pcbi: PComboboxInfo): BOOL; stdcall;
begin
  Result := (pcbi <> nil) and (pcbi^.cbSize = SizeOf(TComboboxInfo));
  if Result then
  begin
    pcbi^.hwndCombo := hwndCombo;
    if (GetWindowLong(hwndCombo, GWL_STYLE) and CBS_SIMPLE) <> 0 then
    begin
      pcbi^.hwndList := GetTopWindow(hwndCombo);
      pcbi^.hwndItem := GetWindow(pcbi^.hwndList, GW_HWNDNEXT);
    end
    else
    begin
      pcbi^.hwndItem := GetTopWindow(hwndCombo);
      pcbi^.hwndList := 0;
    end;
  end;
end;

function _GetMenuBarInfo(hwnd: HWND; idObject: LONG; idItem: LONG; pmbi: PMENUBARINFO): BOOL; stdcall;
begin
  Result := False;
end;

function _GetWindowInfo(hwnd: HWND; pwi: PWINDOWINFO): BOOL; stdcall;
begin
  Result := False;
end;

function _EnumDisplayMonitors(hdcOptionalForPainting: HDC;
  lprcEnumMonitorsThatIntersect: PRect;
  lpfnEnumProc: MonitorEnumProc;
  dwData: LPARAM): LongBool; stdcall;
var
  rcLimit, rcClip: TRect;
  ptOrg: TPoint;
  Cb: Integer;
begin
  // from MultiMon.h
  rcLimit.left   := 0;
  rcLimit.top    := 0;
  rcLimit.right  := GetSystemMetrics(SM_CXSCREEN);
  rcLimit.bottom := GetSystemMetrics(SM_CYSCREEN);

  if (hdcOptionalForPainting <> 0) then
  begin
    Cb := GetClipBox(hdcOptionalForPainting, @rcClip);
    if not GetDCOrgEx(hdcOptionalForPainting, @ptOrg) then
      Exit(False);

    OffsetRect(rcLimit, -ptOrg.x, -ptOrg.y);
    if (IntersectRect(rcLimit, rcLimit, rcClip) and
       ((lprcEnumMonitorsThatIntersect = nil) or
         IntersectRect(rcLimit, rcLimit, lprcEnumMonitorsThatIntersect^))) then
    begin
      if Cb =  NULLREGION then
        Exit(True)
      else
      if Cb = ERROR then
        Exit(False);
    end
  end
  else
  if ((lprcEnumMonitorsThatIntersect <> nil) and
      not IntersectRect(rcLimit, rcLimit, lprcEnumMonitorsThatIntersect^)) then
    Exit(True);

  Result := lpfnEnumProc(
              xPRIMARY_MONITOR,
              hdcOptionalForPainting,
              @rcLimit,
              dwData);
end;

function _GetMonitorInfo(hMonitor: HMONITOR; lpMonitorInfo: PMonitorInfo): Boolean; stdcall;
var
  rcWork: TRect;
begin
  // from MultiMon.h
  if ((hMonitor = xPRIMARY_MONITOR) and
      (lpMonitorInfo <> nil) and
      (lpMonitorInfo^.cbSize >= sizeof(TMonitorInfo)) and
      SystemParametersInfo(SPI_GETWORKAREA, 0, @rcWork, 0)) then
  begin
    lpMonitorInfo^.rcMonitor.left := 0;
    lpMonitorInfo^.rcMonitor.top  := 0;
    lpMonitorInfo^.rcMonitor.right  := GetSystemMetrics(SM_CXSCREEN);
    lpMonitorInfo^.rcMonitor.bottom := GetSystemMetrics(SM_CYSCREEN);
    lpMonitorInfo^.rcWork := rcWork;
    lpMonitorInfo^.dwFlags := MONITORINFOF_PRIMARY;

    {$IFDEF WindowsUnicodeSupport}
    if UnicodeEnabledOS then
    begin
      if (lpMonitorInfo^.cbSize >= sizeof(TMonitorInfoExW)) then
        PMonitorInfoExW(lpMonitorInfo)^.szDevice := 'DISPLAY'
    end
    else
    {$ENDIF}
    if (lpMonitorInfo^.cbSize >= sizeof(TMonitorInfoEx)) then
      PMonitorInfoEx(lpMonitorInfo)^.szDevice := 'DISPLAY';

    Result := True;
  end
  else
    Result := False;
end;

function _MonitorFromPoint(ptScreenCoords: TPoint; dwFlags: DWord): HMONITOR;
begin
  if ((dwFlags and (MONITOR_DEFAULTTOPRIMARY or MONITOR_DEFAULTTONEAREST) <> 0 ) or
      ((ptScreenCoords.x >= 0) and
      (ptScreenCoords.x < GetSystemMetrics(SM_CXSCREEN)) and
      (ptScreenCoords.y >= 0) and
      (ptScreenCoords.y < GetSystemMetrics(SM_CYSCREEN)))) then
    Result := xPRIMARY_MONITOR
  else
    Result := 0;
end;

function _MonitorFromRect(lprcScreenCoords: PRect; dwFlags: DWord): HMONITOR;
begin
  if ((dwFlags and (MONITOR_DEFAULTTOPRIMARY or MONITOR_DEFAULTTONEAREST) <> 0) or
      ((lprcScreenCoords^.right > 0) and
      (lprcScreenCoords^.bottom > 0) and
      (lprcScreenCoords^.left < GetSystemMetrics(SM_CXSCREEN)) and
      (lprcScreenCoords^.top < GetSystemMetrics(SM_CYSCREEN)))) then
    Result := xPRIMARY_MONITOR
  else
    Result := 0;
end;

function _MonitorFromWindow(hWnd: HWND; dwFlags: DWord): HMONITOR;
var
  wp: TWindowPlacement;
  B: Boolean;
begin
  if (dwFlags and (MONITOR_DEFAULTTOPRIMARY or MONITOR_DEFAULTTONEAREST) <> 0) then
    Exit(xPRIMARY_MONITOR);

  if IsIconic(hWnd) then
    B := GetWindowPlacement(hWnd, @wp)
  else
    B := GetWindowRect(hWnd, @wp.rcNormalPosition);

  if B then
    Result := _MonitorFromRect(@wp.rcNormalPosition, dwFlags)
  else
    Result := 0;
end;

function _SHGetStockIconInfo(siid: integer; uFlags: UINT; psii: PSHSTOCKICONINFO): HResult;
begin
  Result := E_NOTIMPL;
end;

const
  msimg32lib = 'msimg32.dll';
  user32lib = 'user32.dll';
  shell32lib = 'shell32.dll';

var
  msimg32handle: THandle = 0;
  user32handle: THandle = 0;
  shell32handle: THandle = 0;

procedure Initialize;
var
  p: Pointer;
begin
  if WindowsVersion = wvUnknown then
    UpdateWindowsVersion;

  GetComboBoxInfo := nil;
  GetMenuBarInfo := nil;
  GetWindowInfo := nil;

  msimg32handle := LoadLibrary(msimg32lib);
  if msimg32handle <> 0
  then begin 
    p := GetProcAddress(msimg32handle, 'AlphaBlend');
    if p <> nil
    then begin
      // Detect win98 since aplhablend doesn't support all bitmap types
      if WindowsVersion = wv98
      then begin
        // windows 98
        // Pointer(AlphaBlend98) := p;
        Pointer(AlphaBlend) := @_AlphaBlend98;
      end
      else begin
        // other
        Pointer(AlphaBlend) := p;
      end;
    end
    else
      Pointer(AlphaBlend) := @_AlphaBlend;

    p := GetProcAddress(msimg32handle, 'GradientFill');
    if p <> nil then
      Pointer(GradientFill) := p
    else
      Pointer(GradientFill) := @_GradientFill;
  end;
  
  user32handle := LoadLibrary(user32lib);
  if user32handle <> 0 then
  begin
    p := GetProcAddress(user32handle, 'GetComboBoxInfo');
    if p <> nil then
      Pointer(GetComboboxInfo) := p
    else
      Pointer(GetComboboxInfo) := @_GetComboboxInfo;
    p := GetProcAddress(user32handle, 'GetMenuBarInfo');
    if p <> nil then
      Pointer(GetMenuBarInfo) := p
    else
      Pointer(GetMenuBarInfo) := @_GetMenuBarInfo;
    p := GetProcAddress(user32handle, 'GetWindowInfo');
    if p <> nil then
      Pointer(GetWindowInfo) := p
    else
      Pointer(GetWindowInfo) := @_GetWindowInfo;
    p := GetProcAddress(user32handle, 'EnumDisplayMonitors');
    if p <> nil then
      Pointer(EnumDisplayMonitors) := p
    else
      Pointer(EnumDisplayMonitors) := @_EnumDisplayMonitors;
  {$IFDEF WindowsUnicodeSupport}
    if UnicodeEnabledOS then
      p := GetProcAddress(user32handle, 'GetMonitorInfoW')
    else
      p := GetProcAddress(user32handle, 'GetMonitorInfoA');
  {$ELSE}
    p := GetProcAddress(user32handle, 'GetMonitorInfoA');
  {$ENDIF}
    if p <> nil then
      Pointer(GetMonitorInfo) := p
    else
      Pointer(GetMonitorInfo) := @_GetMonitorInfo;
    p := GetProcAddress(user32handle, 'MonitorFromWindow');
    if p <> nil then
      Pointer(MonitorFromWindow) := p
    else
      Pointer(MonitorFromWindow) := @_MonitorFromWindow;
    p := GetProcAddress(user32handle, 'MonitorFromRect');
    if p <> nil then
      Pointer(MonitorFromRect) := p
    else
      Pointer(MonitorFromRect) := @_MonitorFromRect;
    p := GetProcAddress(user32handle, 'MonitorFromPoint');
    if p <> nil then
      Pointer(MonitorFromPoint) := p
    else
      Pointer(MonitorFromPoint) := @_MonitorFromPoint;
  end;

  shell32handle := LoadLibrary(shell32lib);
  if shell32handle <> 0 then
  begin
    p := GetProcAddress(shell32handle, 'SHGetStockIconInfo');
    if p <> nil then
      Pointer(SHGetStockIconInfo) := p
    else
      Pointer(SHGetStockIconInfo) := @_SHGetStockIconInfo;
  end;
end;

procedure Finalize;
begin
  AlphaBlend := @_AlphaBlend;
  GetComboboxInfo := nil;
  GetMenuBarInfo := nil;

  if msimg32handle <> 0
  then FreeLibrary(msimg32handle);
  msimg32handle := 0;
  
  if user32handle <> 0 then
    FreeLibrary(user32handle);
  user32handle := 0;

  if shell32handle <> 0 then
    FreeLibrary(shell32handle);
  shell32handle := 0;
end;

initialization
  Initialize;

finalization
  Finalize;

end.
