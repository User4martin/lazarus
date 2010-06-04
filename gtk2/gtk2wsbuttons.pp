{ $Id$}
{
 *****************************************************************************
 *                             Gtk2WSButtons.pp                              * 
 *                             ----------------                              * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

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
unit Gtk2WSButtons;

{$mode objfpc}{$H+}

interface

uses
  glib2, gtk2, gdk2, gdk2pixbuf, Gtk2WSPrivate,
////////////////////////////////////////////////////
  LCLType, Controls, Buttons, Graphics, GraphType,
////////////////////////////////////////////////////
  WSButtons, WSLCLClasses, WSProc,
  Gtk2Def, GtkDebug;

type
  PBitBtnWidgetInfo = ^TBitBtnWidgetInfo;
  TBitBtnWidgetInfo = record
    LabelWidget: Pointer;
    ImageWidget: Pointer;
    SpaceWidget: Pointer; 
    AlignWidget: Pointer; 
    TableWidget: Pointer; 
  end;

  { TGtk2WSBitBtn }

  TGtk2WSBitBtn = class(TWSBitBtn)
  private
  protected
    class procedure UpdateGlyph(const ABitBtn: TCustomBitBtn; const AValue: TButtonGlyph; const AButtonState: TButtonState);
    class procedure UpdateLayout(const AInfo: PBitBtnWidgetInfo; const ALayout: TButtonLayout; const AMargin: Integer);
    class procedure UpdateMargin(const AInfo: PBitBtnWidgetInfo; const ALayout: TButtonLayout; const AMargin: Integer);
    class procedure SetCallbacks(const AGtkWidget: PGtkWidget; const AWidgetInfo: PWidgetInfo); virtual;
  published
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure SetGlyph(const ABitBtn: TCustomBitBtn; const AValue: TButtonGlyph); override;
    class procedure SetLayout(const ABitBtn: TCustomBitBtn; const AValue: TButtonLayout); override;
    class procedure SetMargin(const ABitBtn: TCustomBitBtn; const AValue: Integer); override;
    class procedure SetSpacing(const ABitBtn: TCustomBitBtn; const AValue: Integer); override;
    class procedure SetText(const AWinControl: TWinControl; const AText: String); override;
    class procedure SetColor(const AWinControl: TWinControl); override;
    class procedure SetFont(const AWinControl: TWinControl; const AFont: TFont); override;
  end;
  TGtk2WSBitBtnClass = class of TGtk2WSBitBtn;


  { TGtk2WSSpeedButton }

  TGtk2WSSpeedButton = class(TWSSpeedButton)
  private
  protected
  public
  end;


implementation

uses
  Gtk2Proc, Gtk2Int, Gtk2WSStdCtrls;

const
  GtkStateToButtonState: array[GTK_STATE_NORMAL..GTK_STATE_INSENSITIVE] of TButtonState =
  (
{GTK_STATE_NORMAL     } bsUp,
{GTK_STATE_ACTIVE     } bsDown,
{GTK_STATE_PRELIGHT   } bsHot,
{GTK_STATE_SELECTED   } bsDown,
{GTK_STATE_INSENSITIVE} bsDisabled
  );
  
type
  TCustomBitBtnAccess = class(TCustomBitBtn)
  end;

procedure GtkWSBitBtn_StateChanged(AWidget: PGtkWidget; AState: TGtkStateType; AInfo: PWidgetInfo); cdecl;
begin
  //WriteLn(Astate, ' :: ', GTK_WIDGET_STATE(AWidget));
  TGtk2WSBitBtnClass(TCustomBitBtn(AInfo^.LCLObject).WidgetSetClass).UpdateGlyph(
    TBitBtn(AInfo^.LCLObject),
    TCustomBitBtnAccess(AInfo^.LCLObject).FButtonGlyph,
    GtkStateToButtonState[GTK_WIDGET_STATE(AWidget)]);
end;

{ TGtk2WSBitBtn }

{
 The interiour of TBitBtn is created with a 4X4 table
 Depending in how the image and label are aligned, only a 
 columns or rows are used (like a 4x1 or 1x4 table). 
 This way the table doesn't have to be recreated on changes.
 So there are 4 positions 0, 1, 2, 3.
 Positions 1 and 2 are used for the label and image.
 Since this is always the case, spacing can be implemented
 by setting the spacing of row/col 1
 To get a margin, a gtkInvisible is needed for bottom and 
 right, so the invisible is always in position 3. 
}
class function TGtk2WSBitBtn.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
var
  BitBtn: TCustomBitBtn;
  WidgetInfo: PWidgetInfo;
  BitBtnInfo: PBitBtnWidgetInfo;
  Allocation: TGTKAllocation;
begin
  BitBtn := AWinControl as TCustomBitBtn;

  Result := TLCLIntfHandle(PtrUInt(gtk_button_new));
  if Result = 0 then Exit;
  {$IFDEF DebugLCLComponents}
  DebugGtkWidgets.MarkCreated(Pointer(Result),dbgsName(AWinControl));
  {$ENDIF}

  WidgetInfo := CreateWidgetInfo(Pointer(Result), BitBtn, AParams);

  New(BitBtnInfo);
  FillChar(BitBtnInfo^, SizeOf(BitBtnInfo^), 0);
  WidgetInfo^.UserData := BitBtnInfo;
  WidgetInfo^.DataOwner := True;

  BitBtnInfo^.AlignWidget := gtk_alignment_new(0.5, 0.5, 0, 0);
  gtk_container_add(Pointer(Result), BitBtnInfo^.AlignWidget);

  BitBtnInfo^.TableWidget := gtk_table_new(4, 4, False);
  gtk_container_add(BitBtnInfo^.AlignWidget, BitBtnInfo^.TableWidget);
  
  BitBtnInfo^.LabelWidget := gtk_label_new('bitbtn');
  gtk_table_attach(BitBtnInfo^.TableWidget, BitBtnInfo^.LabelWidget,
                   2, 3, 0, 4, GTK_SHRINK or GTK_FILL, GTK_SHRINK or GTK_FILL, 0, 0);

  BitBtnInfo^.SpaceWidget := nil;
  BitBtnInfo^.ImageWidget := nil;

  gtk_widget_show(BitBtnInfo^.AlignWidget);
  gtk_widget_show(BitBtnInfo^.TableWidget);
  gtk_widget_show(BitBtnInfo^.LabelWidget);

  Allocation.X := AParams.X;
  Allocation.Y := AParams.Y;
  Allocation.Width := AParams.Width;
  Allocation.Height := AParams.Height;
  gtk_widget_size_allocate(PGtkWidget(Result), @Allocation);

  Set_RC_Name(AWinControl, PGtkWidget(Result));
  SetCallbacks(PGtkWidget(Result), WidgetInfo);
end;

class procedure TGtk2WSBitBtn.SetGlyph(const ABitBtn: TCustomBitBtn;
  const AValue: TButtonGlyph);
begin
  if not WSCheckHandleAllocated(ABitBtn, 'SetGlyph')
  then Exit;
  
  UpdateGlyph(ABitBtn, AValue, GtkStateToButtonState[GTK_WIDGET_STATE(PGtkWidget(ABitBtn.Handle))]);
end;

class procedure TGtk2WSBitBtn.SetLayout(const ABitBtn: TCustomBitBtn;
  const AValue: TButtonLayout);
var
  WidgetInfo: PWidgetInfo;
  BitBtnInfo: PBitBtnWidgetInfo;
begin
  if not WSCheckHandleAllocated(ABitBtn, 'SetLayout')
  then Exit;

  WidgetInfo := GetWidgetInfo(Pointer(ABitBtn.Handle));
  BitBtnInfo := WidgetInfo^.UserData;                       
  UpdateLayout(BitBtnInfo, AValue, ABitBtn.Margin);
end;

class procedure TGtk2WSBitBtn.SetMargin(const ABitBtn: TCustomBitBtn;
  const AValue: Integer);
var
  WidgetInfo: PWidgetInfo;
  BitBtnInfo: PBitBtnWidgetInfo;
begin
  if not WSCheckHandleAllocated(ABitBtn, 'SetMargin')
  then Exit;

  WidgetInfo := GetWidgetInfo(Pointer(ABitBtn.Handle));
  BitBtnInfo := WidgetInfo^.UserData;                       
  UpdateMargin(BitBtnInfo, ABitBtn.Layout, AValue);
end;

class procedure TGtk2WSBitBtn.SetSpacing(const ABitBtn: TCustomBitBtn;
  const AValue: Integer);
var
  WidgetInfo: PWidgetInfo;
  BitBtnInfo: PBitBtnWidgetInfo;
begin
  if not WSCheckHandleAllocated(ABitBtn, 'SetSpacing')
  then Exit;
  
  WidgetInfo := GetWidgetInfo(Pointer(ABitBtn.Handle));
  BitBtnInfo := WidgetInfo^.UserData;                       
  gtk_table_set_col_spacing(BitBtnInfo^.TableWidget, 1, AValue);
  gtk_table_set_row_spacing(BitBtnInfo^.TableWidget, 1, AValue);
end;

class procedure TGtk2WSBitBtn.SetText(const AWinControl: TWinControl;
  const AText: String);
var
  WidgetInfo: PWidgetInfo;
  BitBtnInfo: PBitBtnWidgetInfo;
begin          
  if not WSCheckHandleAllocated(AWincontrol, 'SetText')
  then Exit;

  WidgetInfo := GetWidgetInfo(Pointer(AWinControl.Handle));
  BitBtnInfo := WidgetInfo^.UserData;                       

  if AText = '' then
  begin
    gtk_container_remove(BitBtnInfo^.TableWidget, BitBtnInfo^.LabelWidget);
    BitBtnInfo^.LabelWidget := nil;
  end
  else
  begin
    if BitBtnInfo^.LabelWidget = nil then
    begin
      BitBtnInfo^.LabelWidget := gtk_label_new(nil);
      gtk_widget_show(BitBtnInfo^.LabelWidget);
    end;

    Gtk2WidgetSet.SetLabelCaption(BitBtnInfo^.LabelWidget, AText
       {$IFDEF Gtk1},AWinControl,WidgetInfo^.CoreWidget, 'clicked'{$ENDIF});
  end;

  UpdateLayout(BitBtnInfo, TBitBtn(AWincontrol).Layout, TBitBtn(AWincontrol).Margin);
end;

class procedure TGtk2WSBitBtn.SetColor(const AWinControl: TWinControl);
var
  Widget: PGTKWidget;
begin
  if not AWinControl.HandleAllocated then exit;
  Widget:= PGtkWidget(AWinControl.Handle);
  Gtk2WidgetSet.SetWidgetColor(Widget, clNone, AWinControl.color,
     [GTK_STATE_NORMAL,GTK_STATE_ACTIVE,GTK_STATE_PRELIGHT,GTK_STATE_SELECTED]);
end;

class procedure TGtk2WSBitBtn.SetFont(const AWinControl: TWinControl;
  const AFont: TFont);
var
  WidgetInfo: PWidgetInfo;
  BitBtnInfo: PBitBtnWidgetInfo;
  Widget: PGTKWidget;
begin
  if not AWinControl.HandleAllocated then exit;
  
  Widget:= PGtkWidget(AWinControl.Handle);
  WidgetInfo := GetWidgetInfo(Widget);
  BitBtnInfo := WidgetInfo^.UserData;

  if (BitBtnInfo=nil) or (BitBtnInfo^.LabelWidget = nil) then Exit;
  Gtk2WidgetSet.SetWidgetColor(BitBtnInfo^.LabelWidget, AFont.Color,
    clNone,
    [GTK_STATE_NORMAL,GTK_STATE_ACTIVE,GTK_STATE_PRELIGHT,GTK_STATE_SELECTED]);
  Gtk2WidgetSet.SetWidgetFont(BitBtnInfo^.LabelWidget, AFont);
end;

class procedure TGtk2WSBitBtn.UpdateGlyph(const ABitBtn: TCustomBitBtn;
  const AValue: TButtonGlyph; const AButtonState: TButtonState);
var
  WidgetInfo: PWidgetInfo;
  BitBtnInfo: PBitBtnWidgetInfo;
  GDIObject: PGDIObject;
  Pixbuf: PGdkPixbuf;
  Mask: PGdkBitmap;
  AGlyph: TBitmap;
  AIndex: Integer;
  AEffect: TGraphicsDrawEffect;
begin
  WidgetInfo := GetWidgetInfo(Pointer(ABitBtn.Handle));
  BitBtnInfo := WidgetInfo^.UserData;

  if ABitBtn.CanShowGlyph then
  begin
    AGlyph := TBitmap.Create;
    AValue.GetImageIndexAndEffect(AButtonState, AIndex, AEffect);
    if (AIndex <> -1) and (AValue.Images <> nil) then
      AValue.Images.GetBitmap(AIndex, AGlyph, AEffect);
  end
  else
    AGlyph := nil;
  // check if an image is needed
  if (AGlyph = nil) or AGlyph.Empty
  then begin
    if BitBtnInfo^.ImageWidget <> nil
    then begin
      gtk_container_remove(BitBtnInfo^.TableWidget, BitBtnInfo^.ImageWidget);
      BitBtnInfo^.ImageWidget := nil;
    end;
    AGlyph.Free;
    Exit;
  end;

  GDIObject := PGDIObject(AGlyph.Handle);
  Mask := nil;
  Pixbuf := nil;
  if GDIObject^.GDIBitmapType = gbPixbuf then
    Pixbuf := GDIObject^.GDIPixbufObject
  else
    Mask := CreateGdkMaskBitmap(AGlyph.Handle, AGlyph.MaskHandle);
  // check for image
  if BitBtnInfo^.ImageWidget = nil
  then begin
    BitBtnInfo^.ImageWidget := gtk_image_new;
    gtk_widget_show(BitBtnInfo^.ImageWidget);
    UpdateLayout(BitBtnInfo, ABitBtn.Layout, ABitBtn.Margin);
  end;

  if Pixbuf <> nil then
  begin
    gtk_image_set_from_pixbuf(BitBtnInfo^.ImageWidget, Pixbuf);
    //DbgDumpPixbuf(Pixbuf);
  end
  else
  begin
    gtk_image_set_from_pixmap(BitBtnInfo^.ImageWidget, GDIObject^.GDIPixmapObject.Image, Mask);
    //DbgDumpPixmap(GDIObject^.GDIPixmapObject.Image);
    //DbgDumpBitmap(Mask);
  end;

  if Mask <> nil then
    gdk_pixmap_unref(Mask);
  AGlyph.Free;
end;

class procedure TGtk2WSBitBtn.UpdateLayout(const AInfo: PBitBtnWidgetInfo;
  const ALayout: TButtonLayout; const AMargin: Integer);
begin
  if (AInfo^.ImageWidget = nil) and (AMargin < 0) then Exit; // nothing to do
  
  // add references and remove it from the table
  if AInfo^.LabelWidget <> nil then
  begin
    gtk_object_ref(AInfo^.LabelWidget);
    if PGtkWidget(AInfo^.LabelWidget)^.Parent <> nil then
      gtk_container_remove(AInfo^.TableWidget, AInfo^.LabelWidget);
  end;
  if AInfo^.ImageWidget <> nil then
  begin
    gtk_object_ref(AInfo^.ImageWidget);                          
    if PGtkWidget(AInfo^.ImageWidget)^.Parent <> nil then
      gtk_container_remove(AInfo^.TableWidget, AInfo^.ImageWidget);
  end;
  if AInfo^.SpaceWidget <> nil then
  begin
    gtk_object_ref(AInfo^.SpaceWidget);
    if PGtkWidget(AInfo^.SpaceWidget)^.Parent <> nil then
      gtk_container_remove(AInfo^.TableWidget, AInfo^.SpaceWidget);
  end;

  if ((AInfo^.LabelWidget = nil) or (PGtkLabel(AInfo^.LabelWidget)^.{$ifdef gtk1}thelabel{$else}text{$endif} = '')) and
     (AInfo^.ImageWidget <> nil) then
  begin
    gtk_table_attach(AInfo^.TableWidget, AInfo^.ImageWidget,
                     0, 3, 0, 3, GTK_EXPAND or GTK_FILL, GTK_EXPAND or GTK_FILL, 0, 0);
  end
  else
  case ALayout of 
    blGlyphLeft:
    begin
      if AInfo^.ImageWidget <> nil then
        gtk_table_attach(AInfo^.TableWidget, AInfo^.ImageWidget,
                         1, 2, 1, 3, GTK_SHRINK or GTK_FILL, GTK_SHRINK or GTK_FILL, 0, 0);
      gtk_table_attach(AInfo^.TableWidget, AInfo^.LabelWidget,
                       2, 3, 1, 3, GTK_SHRINK or GTK_FILL, GTK_SHRINK or GTK_FILL, 0, 0);
    end;
    blGlyphRight:
    begin
      gtk_table_attach(AInfo^.TableWidget, AInfo^.LabelWidget,
                       1, 2, 1, 3, GTK_SHRINK or GTK_FILL, GTK_SHRINK or GTK_FILL, 0, 0);
      if AInfo^.ImageWidget <> nil then
        gtk_table_attach(AInfo^.TableWidget, AInfo^.ImageWidget,
                         2, 3, 1, 3, GTK_SHRINK or GTK_FILL, GTK_SHRINK or GTK_FILL, 0, 0);
      if AInfo^.SpaceWidget <> nil then
        gtk_table_attach(AInfo^.TableWidget, AInfo^.SpaceWidget,
                         3, 4, 1, 3, GTK_SHRINK or GTK_FILL, GTK_SHRINK or GTK_FILL, 0, 0);
    end;
    blGlyphTop:
    begin
      if AInfo^.ImageWidget <> nil then
        gtk_table_attach(AInfo^.TableWidget, AInfo^.ImageWidget,
                         1, 3, 1, 2, GTK_SHRINK or GTK_FILL, GTK_SHRINK or GTK_FILL, 0, 0);
      gtk_table_attach(AInfo^.TableWidget, AInfo^.LabelWidget,
                       1, 3, 2, 3, GTK_SHRINK or GTK_FILL, GTK_SHRINK or GTK_FILL, 0, 0);
    end; 
    blGlyphBottom:
    begin
      gtk_table_attach(AInfo^.TableWidget, AInfo^.LabelWidget,
                       1, 3, 1, 2, GTK_SHRINK or GTK_FILL, GTK_SHRINK or GTK_FILL, 0, 0);
      if AInfo^.ImageWidget <> nil then
        gtk_table_attach(AInfo^.TableWidget, AInfo^.ImageWidget,
                        1, 3, 2, 3, GTK_SHRINK or GTK_FILL, GTK_SHRINK or GTK_FILL, 0, 0);
      if AInfo^.SpaceWidget <> nil then
        gtk_table_attach(AInfo^.TableWidget, AInfo^.SpaceWidget,
                         1, 3, 3, 4, GTK_SHRINK or GTK_FILL, GTK_SHRINK or GTK_FILL, 0, 0);
    end;
  end;
  
  // remove temp reference
  if AInfo^.SpaceWidget <> nil then
    gtk_object_unref(AInfo^.SpaceWidget);
  if AInfo^.ImageWidget <> nil then
    gtk_object_unref(AInfo^.ImageWidget);
  if AInfo^.LabelWidget <> nil then
    gtk_object_unref(AInfo^.LabelWidget);
  
  if AMargin >= 0 then
    UpdateMargin(AInfo, ALayout, AMargin)
end;

class procedure TGtk2WSBitBtn.UpdateMargin(const AInfo: PBitBtnWidgetInfo;
  const ALayout: TButtonLayout; const AMargin: Integer);
begin
  if AMargin < 0 
  then begin
    if AInfo^.SpaceWidget <> nil
    then begin
      gtk_container_remove(AInfo^.TableWidget, AInfo^.SpaceWidget);
      AInfo^.SpaceWidget := nil;

      gtk_alignment_set(AInfo^.AlignWidget, 0.5, 0.5, 0, 0);
      
      case ALayout of 
        blGlyphLeft:   gtk_table_set_col_spacing(AInfo^.TableWidget, 0, 0);
        blGlyphRight:  gtk_table_set_col_spacing(AInfo^.TableWidget, 2, 0);
        blGlyphTop:    gtk_table_set_row_spacing(AInfo^.TableWidget, 0, 0);
        blGlyphBottom: gtk_table_set_row_spacing(AInfo^.TableWidget, 2, 0);
      end;
    end;
  end
  else begin
    if (AInfo^.SpaceWidget = nil)
    and (ALayout in [blGlyphRight, blGlyphBottom])
    then begin
      {$IFDEF gtk1}
      AInfo^.SpaceWidget := gtk_invisible_new;
      {$ELSE}
      // dont use gtk_invisible_new - it cannot have parent
      AInfo^.SpaceWidget := gtk_image_new;
      {$ENDIF}
      UpdateLayout(AInfo, ALayout, AMargin);
    end
    else begin
      case ALayout of 
        blGlyphLeft: begin
          gtk_alignment_set(AInfo^.AlignWidget, 0, 0.5, 0, 0);
          gtk_table_set_col_spacing(AInfo^.TableWidget, 0, AMargin);
          gtk_table_set_col_spacing(AInfo^.TableWidget, 2, 0);
          gtk_table_set_row_spacing(AInfo^.TableWidget, 0, 0);
          gtk_table_set_row_spacing(AInfo^.TableWidget, 2, 0);
        end;
        blGlyphRight: begin
          gtk_alignment_set(AInfo^.AlignWidget, 1, 0.5, 0, 0);
          gtk_table_set_col_spacing(AInfo^.TableWidget, 0, 0);
          gtk_table_set_col_spacing(AInfo^.TableWidget, 2, AMargin);
          gtk_table_set_row_spacing(AInfo^.TableWidget, 0, 0);
          gtk_table_set_row_spacing(AInfo^.TableWidget, 2, 0);
        end;
        blGlyphTop: begin
          gtk_alignment_set(AInfo^.AlignWidget, 0.5, 0, 0, 0);
          gtk_table_set_col_spacing(AInfo^.TableWidget, 0, 0);
          gtk_table_set_col_spacing(AInfo^.TableWidget, 2, 0);
          gtk_table_set_row_spacing(AInfo^.TableWidget, 0, AMargin);
          gtk_table_set_row_spacing(AInfo^.TableWidget, 2, 0);
        end;
        blGlyphBottom: begin
          gtk_alignment_set(AInfo^.AlignWidget, 0.5, 1, 0, 0);
          gtk_table_set_col_spacing(AInfo^.TableWidget, 0, 0);
          gtk_table_set_col_spacing(AInfo^.TableWidget, 2, 0);
          gtk_table_set_row_spacing(AInfo^.TableWidget, 0, 0);
          gtk_table_set_row_spacing(AInfo^.TableWidget, 2, AMargin);
        end;
      end;
    end;
  end;
end;

class procedure TGtk2WSBitBtn.SetCallbacks(const AGtkWidget: PGtkWidget;
  const AWidgetInfo: PWidgetInfo);
begin
  TGtk2WSButton.SetCallbacks(AGtkWidget, AWidgetInfo);

  SignalConnect(AGtkWidget, 'state-changed', @GtkWSBitBtn_StateChanged, AWidgetInfo);
end;

end.
