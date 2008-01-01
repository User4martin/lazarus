{ $Id$}
{
 *****************************************************************************
 *                             Win32WSImgList.pp                             * 
 *                             -----------------                             * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
unit Win32WSImgList;

{$mode objfpc}{$H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
  Windows, SysUtils, Classes, ImgList, GraphType, Graphics, LCLType,
  Win32Extra, Win32Int, Win32Proc, InterfaceBase,
////////////////////////////////////////////////////
  WSImgList, WSLCLClasses, WSProc;

type

  { TWin32WSCustomImageList }

  TWin32WSCustomImageList = class(TWSCustomImageList)
  private
  protected
    class procedure AddData(AListHandle: TLCLIntfHandle; ACount, AReplaceIndex, AWidth, AHeight: Integer; AData: PRGBAQuad);
  public
    class procedure Clear(AList: TCustomImageList); override;
    class function CreateHandle(AList: TCustomImageList; ACount, AGrow, AWidth,
      AHeight: Integer; AData: PRGBAQuad): TLCLIntfHandle; override;
    class procedure Delete(AList: TCustomImageList; AIndex: Integer); override;
    class procedure DestroyHandle(AComponent: TComponent); override;
    class procedure Draw(AList: TCustomImageList; AIndex: Integer; ACanvas: TCanvas;
      ABounds: TRect; ABkColor, ABlendColor: TColor; ADrawEffect: TGraphicsDrawEffect; AStyle: TDrawingStyle; AImageType: TImageType); override;
    class procedure DrawToDC(AList: TCustomImageList; AIndex: Integer; ADC: HDC;
      ABounds: TRect; ABkColor, ABlendColor: TColor; ADrawEffect: TGraphicsDrawEffect; AStyle: TDrawingStyle; AImageType: TImageType);
    class procedure Insert(AList: TCustomImageList; AIndex: Integer; AData: PRGBAQuad); override;
    class procedure Move(AList: TCustomImageList; ACurIndex, ANewIndex: Integer); override;
    class procedure Replace(AList: TCustomImageList; AIndex: Integer; AData: PRGBAQuad); override;
  end;


implementation

uses
  intfgraphics;

const
  DRAWINGSTYLEMAP: array[TDrawingStyle] of DWord = (
{ dsFocus       } ILD_FOCUS,
{ dsSelected    } ILD_SELECTED,
{ dsNormal      } ILD_NORMAL,
{ dsTransparent } ILD_TRANSPARENT
  );
  
  IMAGETPYEMAP: array[TImageType] of DWord = (
{ itImage } ILD_NORMAL,
{ itMask }  ILD_MASK
  );

function ColorToImagelistColor(AColor: TColor): DWord;
begin
  case AColor of
    clNone: Result := CLR_NONE;
    clDefault: Result := CLR_DEFAULT;
  else
    Result := ColorToRGB(AColor);
  end;
end;

class function GetColorDepth: Integer;
var
  DC: HDC;
begin
  DC := GetDC(0);
  Result := GetDeviceCaps(DC, BITSPIXEL) * GetDeviceCaps(DC, PLANES);
  ReleaseDC(0, DC);
end;

class procedure TWin32WSCustomImageList.AddData(AListHandle: TLCLIntfHandle; ACount, AReplaceIndex, AWidth, AHeight: Integer; AData: PRGBAQuad);
  procedure DoAddAlpha;
  var
    Info: Windows.TBitmapInfo;
    BitsPtr: Pointer;
    bmp: HBITMAP;
    DC: HDC;
    DataCount, DataSize: Integer;
  begin
    FillChar(Info, SizeOf(Info), 0);
    Info.bmiHeader.biSize := SizeOf(Info.bmiHeader);
    Info.bmiHeader.biWidth := AWidth;
    Info.bmiHeader.biHeight := -AHeight; // request top down
    Info.bmiHeader.biPlanes := 1;
    Info.bmiHeader.biBitCount := 32;
    Info.bmiHeader.biCompression := BI_RGB;

    BitsPtr := nil;
    DC := GetDC(0);
    bmp := Windows.CreateDIBSection(DC, Info, DIB_RGB_COLORS, BitsPtr, 0, 0);
    ReleaseDC(0, DC);

    if BitsPtr = nil
    then begin
      DeleteObject(bmp);
      Exit;
    end;

    DataCount := AWidth * AHeight;
    DataSize := DataCount * SizeOf(AData^);
    while ACount > 0 do
    begin
      System.Move(AData^, BitsPtr^, DataSize);
      if AReplaceIndex = -1
      then ImageList_Add(AListHandle, bmp, 0)
      else ImageList_Replace(AListHandle, AReplaceIndex, bmp, 0);
      Inc(AData, DataCount);
      Dec(ACount);
    end;

    DeleteObject(bmp);
  end;

  procedure DoAdd;
  var
    Info: Windows.TBitmapInfo;
    BitsPtr, MaskPtr: Pointer;
    P, LinePtr: PByte;
    bmp, msk: HBITMAP;
    DC: HDC;
    DataCount, DataSize, x, y, MaskStride: Integer;
  begin
    FillChar(Info, SizeOf(Info), 0);
    Info.bmiHeader.biSize := SizeOf(Info.bmiHeader);
    Info.bmiHeader.biWidth := AWidth;
    Info.bmiHeader.biHeight := -AHeight; // request top down
    Info.bmiHeader.biPlanes := 1;
    Info.bmiHeader.biBitCount := 32;
    Info.bmiHeader.biCompression := BI_RGB;

    BitsPtr := nil;
    MaskPtr := nil;
    msk := 0;
    bmp := 0;
    DC := GetDC(0);
    bmp := Windows.CreateDIBSection(DC, Info, DIB_RGB_COLORS, BitsPtr, 0, 0);
    ReleaseDC(0, DC);

    if (bmp = 0) or (BitsPtr = nil) then
    begin
      DeleteObject(bmp);
      Exit;
    end;

    DataCount := AWidth * AHeight;
    DataSize := DataCount * SizeOf(AData^);
    MaskStride := ((AWidth + 15) shr 4) shl 1; // align to Word
    MaskPtr := AllocMem(AHeight * MaskStride);
    while ACount > 0 do
    begin
      System.Move(AData^, BitsPtr^, DataSize);

      // create mask
      LinePtr := MaskPtr;
      for y := 1 to AHeight do
      begin
        p := LinePtr;
        for x := 1 to AWidth do
        begin
          P^ := (P^ and $FE) or ((not AData^.Alpha) shr 7);
          if x and $7 = 0
          then Inc(p)
          else P^ := P^ shl 1;
          Inc(AData);
        end;
        // finish mask shifting
        if (AWidth and $7) <> 0 then
          P^ := P^ shl (7 - (AWidth and 7));
        Inc(LinePtr, MaskStride);
      end;

      msk := CreateBitmap(AWidth, AHeight, 1, 1, MaskPtr);
      if AReplaceIndex = -1
      then ImageList_Add(AListHandle, bmp, msk)
      else ImageList_Replace(AListHandle, AReplaceIndex, bmp, msk);
      Dec(ACount);
      DeleteObject(msk);
    end;
    FreeMem(MaskPtr);

    DeleteObject(bmp);
  end;

begin
  if Win32WidgetSet.CommonControlsVersion >= ComCtlVersionIE6
  then DoAddAlpha
  else DoAdd;
end;

class procedure TWin32WSCustomImageList.Clear(AList: TCustomImageList);
begin
  if not WSCheckHandleAllocated(AList, 'Clear')
  then Exit;
  ImageList_SetImageCount(HImageList(AList.Handle), 0);
end;

class function TWin32WSCustomImageList.CreateHandle(AList: TCustomImageList;
  ACount, AGrow, AWidth, AHeight: Integer; AData: PRGBAQuad): TLCLIntfHandle;
var
  Flags: DWord;
begin
  if Win32WidgetSet.CommonControlsVersion >= ComCtlVersionIE6
  then begin
    Flags := ILC_COLOR32;
  end
  else begin
    case GetColorDepth of
      04: FLAGS := ILC_COLOR4 or ILC_MASK;
      08: FLAGS := ILC_COLOR8 or ILC_MASK;
      16: FLAGS := ILC_COLOR16 or ILC_MASK;
      24: FLAGS := ILC_COLOR24 or ILC_MASK;
      32: FLAGS := ILC_COLOR32 or ILC_MASK;
    else
      FLAGS := ILC_COLOR or ILC_MASK;
    end;
  end;
  Result := ImageList_Create(AWidth, AHeight, Flags, ACount, AGrow);
  if Result <> 0
  then AddData(Result, ACount, -1, AWidth, AHeight, AData);
end;

class procedure TWin32WSCustomImageList.Delete(AList: TCustomImageList;
  AIndex: Integer);
begin
  if not WSCheckHandleAllocated(AList, 'Delete')
  then Exit;
  ImageList_Remove(HImageList(AList.Handle), AIndex);
end;

class procedure TWin32WSCustomImageList.DestroyHandle(AComponent: TComponent);
begin
  if not WSCheckHandleAllocated(TCustomImageList(AComponent), 'DestroyHandle')
  then Exit;
  ImageList_Destroy(TCustomImageList(AComponent).Handle);
end;

class procedure TWin32WSCustomImageList.Draw(AList: TCustomImageList; AIndex: Integer;
  ACanvas: TCanvas; ABounds: TRect; ABkColor, ABlendColor: TColor; ADrawEffect: TGraphicsDrawEffect; AStyle: TDrawingStyle; AImageType: TImageType);
begin
  if not WSCheckHandleAllocated(AList, 'Draw')
  then Exit;
  DrawToDC(AList, AIndex, ACanvas.Handle, ABounds, ABkColor, ABlendColor, ADrawEffect, AStyle, AImageType);
end;

class procedure TWin32WSCustomImageList.DrawToDC(AList: TCustomImageList;
  AIndex: Integer; ADC: HDC; ABounds: TRect; ABkColor, ABlendColor: TColor;
  ADrawEffect: TGraphicsDrawEffect; AStyle: TDrawingStyle;
  AImageType: TImageType);
var
  DrawParams: TImageListDrawParams;
  RawImg: TRawImage;
  ListImg, DeviceImg: TLazIntfImage;
  OldBmp, ImgHandle, MskHandle: HBitmap;
  ImgDC: HDC;
begin
  if ADrawEffect = gdeNormal then
  begin
      ImageList_DrawEx(HImageList(AList.Handle), AIndex, ADC, ABounds.Left,
        ABounds.Top, ABounds.Right, ABounds.Bottom, ColorToImagelistColor(ABkColor),
        ColorToImagelistColor(ABlendColor), DRAWINGSTYLEMAP[AStyle] or IMAGETPYEMAP[AImageType]);
  end
  else
  if (ADrawEffect = gdeDisabled) and (Win32WidgetSet.CommonControlsVersion >= ComCtlVersionIE6) then
  begin
    // if it is manifested exe then use winXP algoriphm of gray painting
    FillChar(DrawParams, SizeOf(DrawParams), 0);
    DrawParams.cbSize := SizeOf(DrawParams);
    DrawParams.himlL := HImageList(AList.Handle);
    DrawParams.i := AIndex;
    DrawParams.hdcDst := ADC;
    DrawParams.x := ABounds.Left;
    DrawParams.y := ABounds.Top;
    DrawParams.cx := ABounds.Right;
    DrawParams.cy := ABounds.Bottom;
    DrawParams.rgbBk := ColorToImagelistColor(ABkColor);
    DrawParams.rgbFg := ColorToImagelistColor(ABlendColor);
    DrawParams.fStyle := DRAWINGSTYLEMAP[AStyle] or IMAGETPYEMAP[AImageType];
    DrawParams.fState := ILS_SATURATE; // draw greyed
    ImageList_DrawIndirect(@DrawParams);
  end
  else
  begin
    // use RawImage_PerformEffect to perform drawing effect
    AList.GetRawImage(AIndex, RawImg);
    RawImg.PerformEffect(ADrawEffect, True);

    if not Widgetset.RawImage_CreateBitmaps(RawImg, ImgHandle, MskHandle, True)
    then begin
      // bummer, the widgetset doesn't support our 32bit format, try device
      ListImg := TLazIntfImage.Create(RawImg, False);
      DeviceImg := TLazIntfImage.Create(0, 0);
      DeviceImg.DataDescription := GetDescriptionFromDevice(0, AList.Width, AList.Height);
      DeviceImg.CopyPixels(ListImg);
      DeviceImg.GetRawImage(RawImg);
      Widgetset.RawImage_CreateBitmaps(RawImg, ImgHandle, MskHandle);
      DeviceImg.Free;
      ListImg.Free;
    end;
    
    ImgDC := CreateCompatibleDC(ADC);
    OldBmp := SelectObject(ImgDC, ImgHandle);
    WidgetSet.StretchMaskBlt(ADC, ABounds.Left, ABounds.Top, ABounds.Right, ABounds.Bottom,
      ImgDC, 0, 0, ABounds.Right, ABounds.Bottom, MskHandle, 0, 0, SRCCOPY);
    RawImg.FreeData;
    SelectObject(ImgDC, OldBmp);
    if ImgHandle<>0 then DeleteObject(ImgHandle);
    if MskHandle<>0 then DeleteObject(MskHandle);
    DeleteDC(ImgDC);
  end;
end;

class procedure TWin32WSCustomImageList.Insert(AList: TCustomImageList;
  AIndex: Integer; AData: PRGBAQuad);
var
  ImageList: HImageList;
  Count: Integer;
begin
  if not WSCheckHandleAllocated(AList, 'Insert')
  then Exit;

  ImageList := HImageList(AList.Handle);
  Count := ImageList_GetImageCount(ImageList);
  
  if (AIndex <= Count) and (AIndex >= 0) then
  begin
    AddData(ImageList, 1, -1, AList.Width, AList.Height, AData);
    if AIndex <> Count
    then Move(AList, Count, AIndex);
  end;
end;

class procedure TWin32WSCustomImageList.Move(AList: TCustomImageList;
  ACurIndex, ANewIndex: Integer);
var
  n: integer;
  Handle: THandle;
begin
  if not WSCheckHandleAllocated(AList, 'Move')
  then Exit;
  
  if ACurIndex = ANewIndex
  then Exit;
        
  Handle := AList.Handle;
  if ACurIndex < ANewIndex
  then begin       
    for n := ACurIndex to ANewIndex - 1 do
      ImageList_Copy(Handle, n + 1, Handle, n, ILCF_SWAP);
  end
  else begin
    for n := ACurIndex downto ANewIndex - 1 do
      ImageList_Copy(Handle, n - 1, Handle, n, ILCF_SWAP);
  end;
end;

class procedure TWin32WSCustomImageList.Replace(AList: TCustomImageList;
  AIndex: Integer; AData: PRGBAQuad);
var
  ImageList: HImageList;
  Count: Integer;
begin
  if not WSCheckHandleAllocated(AList, 'Replace')
  then Exit;

  ImageList := HImageList(AList.Handle);
  Count := ImageList_GetImageCount(ImageList);

  if (AIndex < Count) and (AIndex >= 0)
  then AddData(ImageList, 1, AIndex, AList.Width, AList.Height, AData);
end;

initialization
////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
  RegisterWSComponent(TCustomImageList, TWin32WSCustomImageList);
////////////////////////////////////////////////////
end.
