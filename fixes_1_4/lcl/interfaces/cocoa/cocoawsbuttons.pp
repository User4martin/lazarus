{
 *****************************************************************************
 *                              CocoaWSButtons.pp                            *
 *                              --------------                               *
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit cocoawsbuttons;

{$mode objfpc}{$H+}
{$modeswitch objectivec1}

interface

uses
  // libs
  MacOSAll, CocoaAll, SysUtils,
  // LCL
  Classes, Controls, Buttons, LCLType, LCLProc, Graphics, GraphType,
  // widgetset
  WSButtons, WSLCLClasses, WSProc,
  // LCL Carbon
  CocoaWSCommon, CocoaWSStdCtrls, CocoaGDIObjects, CocoaPrivate, CocoaUtils;

type

  { TCocoaWSBitBtn }

  TCocoaWSBitBtn = class(TWSBitBtn)
  private
    class function  LCLGlyphPosToCocoa(ALayout: TButtonLayout): NSCellImagePosition;
  published
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure SetGlyph(const ABitBtn: TCustomBitBtn; const AValue: TButtonGlyph); override;
    class procedure SetLayout(const ABitBtn: TCustomBitBtn; const AValue: TButtonLayout); override;
  end;

  { TCocoaWSSpeedButton }

  TCocoaWSSpeedButton = class(TWSSpeedButton)
  published
  end;


implementation

{ TCocoaWSBitBtn }

class function TCocoaWSBitBtn.LCLGlyphPosToCocoa(ALayout: TButtonLayout
  ): NSCellImagePosition;
begin
  case ALayout of
  blGlyphLeft:   Result := NSImageLeft;
  blGlyphRight:  Result := NSImageRight;
  blGlyphTop:    Result := NSImageAbove;
  blGlyphBottom: Result := NSImageBelow;
  else
    Result := NSNoImage;
  end;
end;

{------------------------------------------------------------------------------
  Method:  TCocoaWSBitBtn.CreateHandle
  Params:  AWinControl - LCL control
           AParams     - Creation parameters
  Returns: Handle to the control in Carbon interface

  Creates new bevel button with bitmap in Cocoa interface with the
  specified parameters
 ------------------------------------------------------------------------------}
class function TCocoaWSBitBtn.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
var
  btn: NSButton;
begin
  btn := AllocButton(AWinControl, TLCLButtonCallBack, AParams, NSRoundedBezelStyle, NSMomentaryPushInButton);
  Result := TLCLIntfHandle(btn);
end;

{------------------------------------------------------------------------------
  Method:  TCocoaWSBitBtn.SetGlyph
  Params:  ABitBtn - LCL custom bitmap button
           AValue  - Bitmap

  Sets the bitmap of bevel button in Cocoa interface
 ------------------------------------------------------------------------------}
class procedure TCocoaWSBitBtn.SetGlyph(const ABitBtn: TCustomBitBtn; const AValue: TButtonGlyph);
var
  Img: NSImage;
  AGlyph: TBitmap;
  lButtonHandle: TCocoaButton;
  AIndex: Integer;
  AEffect: TGraphicsDrawEffect;
begin
  //WriteLn('[TCocoaWSBitBtn.SetGlyph]');
  Img := nil;
  if ABitBtn.CanShowGlyph then
  begin
    AGlyph := TBitmap.Create;
    AValue.GetImageIndexAndEffect(bsUp, AIndex, AEffect);
    AValue.Images.GetBitmap(AIndex, AGlyph, AEffect);
    Img := TCocoaBitmap(AGlyph.Handle).image;
    lButtonHandle := TCocoaButton(ABitBtn.Handle);
    lButtonHandle.setImage(Img);
    lButtonHandle.setImagePosition(LCLGlyphPosToCocoa(ABitBtn.Layout));
    if Assigned(lButtonHandle.Glyph) then
      FreeAndNil(lButtonHandle.Glyph);
    lButtonHandle.Glyph := AGlyph;
  end;
end;

{------------------------------------------------------------------------------
  Method:  TCocoaWSBitBtn.SetLayout
  Params:  ABitBtn - LCL custom bitmap button
           AValue  - Bitmap and caption layout

  Sets the bitmap and caption layout of bevel button in Cocoa interface
 ------------------------------------------------------------------------------}
class procedure TCocoaWSBitBtn.SetLayout(const ABitBtn: TCustomBitBtn;
  const AValue: TButtonLayout);
var
  ImagePos: NSCellImagePosition;
begin

  if (ABitBtn.CanShowGlyph) then
    ImagePos := LCLGlyphPosToCocoa(AValue)
  else
    ImagePos := NSNoImage;
  NSButton(ABitBtn.Handle).SetImagePosition(ImagePos);
end;

end.
