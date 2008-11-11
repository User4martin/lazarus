{
 /***************************************************************************
                               TAGraph.pp
                               ----------
                    Component Library Standard Graph


 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

Authors: Lu�s Rodrigues and Philippe Martinole

}
unit TAGraph;

{$IFDEF fpc}
{$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  {$IFDEF fpc}
  LCLIntF, LCLType, LResources,
  {$ELSE}
  Windows,
  {$ENDIF}
  SysUtils, Classes, Controls, Graphics, Dialogs, StdCtrls, TAEngine, Clipbrd;

const
  MinDouble=-1.7e308;
  MaxDouble=1.7e308;
  MaxArray=2;
  MaxColor=15;
  Colors:array[1..MaxColor] of TColor=
     ( clRed,   
       clGreen,
       clyellow,
       clBlue,
       clWhite,
       clGray,
       clFuchsia,
       clTeal,
       clNavy,
       clMaroon,
       clLime,
       clOlive,
       clPurple,
       clSilver,
       clAqua
       );

type

  TDrawVertReticule=procedure(Sender:TComponent;IndexSerie,Index,Xi,Yi:Integer;
                                                        Xg,Yg:Double) of object;
  TDrawReticule=procedure(Sender:TComponent;IndexSerie,Index,Xi,Yi:Integer;
                                                        Xg,Yg:Double) of object;


  TCustomChart = class(TGraphicControl);

  TChartPen = class(TPen)
  private
      FVisible: boolean;
      procedure SetVisible(value: boolean);
  protected
    procedure Assign(Source:TPersistent); override;
  published
    property Visible: boolean read FVisible write SetVisible;
  end;

  TLegendAlignment=(laLeft,laRight,laTop,laBottom);
  TChartLegend = class(TPersistent)
  private
    FVisible: boolean;
    FAlignment: TLegendAlignment;
    FOwner: TCustomChart;
    FFont: TFont;
    FFrame: TChartPen;

    procedure SetVisible(value: boolean);
    procedure SetAlignment(value: TLegendAlignment);
    procedure SetFont(value: TFont);
    procedure SetFrame(value: TChartPen);
    procedure StyleChanged(Sender: TObject);
  protected
    procedure Assign(Source:TPersistent); override;
  public
    Constructor Create(AOwner: TCustomChart);
    Destructor Destroy; override;
  published
    property Visible: boolean read FVisible write SetVisible;
    property Alignment: TLegendAlignment read FAlignment write SetAlignment;
    property Font: TFont read FFont write SetFont;
    property Frame: TChartPen read FFrame write SetFrame;
  end;

  TChartTitle = class(TPersistent)
  private
    FVisible: boolean;
    FOwner: TCustomChart;
    FFont: TFont;
    FFrame: TChartPen;
    FBrush: TBrush;
    FText: TStrings;
    FAlignment: TAlignment;

    procedure SetVisible(value: boolean);
    procedure SetFont(value: TFont);
    procedure SetFrame(value: TChartPen);
    procedure SetBrush(value: TBrush);
    procedure SetText(value: TStrings);
    procedure SetAlignment(value: TAlignment);
    procedure StyleChanged(Sender: TObject);
  protected
    procedure Assign(Source:TPersistent); override;
  public
    Constructor Create(AOwner: TCustomChart);
    Destructor Destroy; override;
  published
    property Visible: boolean read FVisible write SetVisible;
    property Brush: TBrush read FBrush write SetBrush;
    property Font: TFont read FFont write SetFont;
    property Frame: TChartPen read FFrame write SetFrame;
    property Alignment: TAlignment read FAlignment write SetAlignment;
    property Text: TStrings read FText write SetText;
  end;

  TChartAxisTitle = class(TPersistent)
  private
    FVisible: boolean;
    FOwner: TCustomChart;
    FAngle: Integer;
    FCaption: String;
    FFont: TFont;

    procedure SetCaption(value: String);
    procedure SetAngle(value: Integer);
    procedure SetFont(value: TFont);
    procedure StyleChanged(Sender: TObject);
  protected
    procedure Assign(Source:TPersistent); override;
  public
    Constructor Create(AOwner: TCustomChart);
    Destructor Destroy; override;
  published
    property Caption: String read FCaption write SetCaption;
    property Angle: Integer read FAngle write SetAngle;
    property Font: TFont read FFont write SetFont;
  end;

  TAxisScale=(asIncreasing,asDecreasing,asLogIncreasing,asLogDecreasing);
  TChartAxis = class(TPersistent)
  private                        
    FVisible: boolean;
    FOwner: TCustomChart;
    FTitle: TChartAxisTitle;
    FGrid: TChartPen;
    FInverted: boolean;

    procedure SetVisible(value: boolean);
    procedure SetTitle(value: TChartAxisTitle);
    procedure SetGrid(value: TChartPen);
    procedure SetInverted(value: boolean);
    procedure StyleChanged(Sender: TObject);
  protected
    procedure Assign(Source:TPersistent); override;
  public
    Constructor Create(AOwner: TCustomChart);
    Destructor Destroy; override;
  published
    property Visible: boolean read FVisible write SetVisible;
    property Inverted: boolean read FInverted write SetInverted;
    property Title: TChartAxisTitle read FTitle write SetTitle;
    property Grid: TChartPen read FGrid write SetGrid;

  end;

  TChart = class(TCustomChart)
  private
    { D�clarations priv�es }
    TmpBrush: TBrush;
    TmpPen: TPen;
    TmpFont: TFont;
    FSeries:TSeriesList;                           // List of series
    FMirrorX:Boolean;                           // From right to left ?
    YMarkWidth:Integer;                         // Depend on Y marks
    FXGraphMin,FYGraphMin:Double;               // Graph coordinates of limits
    FXGraphMax,FYGraphMax:Double;
    FAutoUpdateXMin:Boolean;                    // Automatic calculation of XMin limit of graph ?
    FAutoUpdateXMax:Boolean;                    // Automatic calculation of XMax limit of graph ?
    FAutoUpdateYMin:Boolean;                    // Automatic calculation of YMin limit of graph ?
    FAutoUpdateYMax:Boolean;                    // Automatic calculation of YMax limit of graph ?

    FLegend: TChartLegend;                      //legend configuration
    FTitle: TChartTitle;                      //legend configuration
    FFoot: TChartTitle;                      //legend configuration
    FLeftAxis: TChartAxis;
    FBottomAxis: TChartAxis;

    FAllowZoom: Boolean;

    FGraphBrush:TBrush;
    AxisColor:TColor;                           // Axis color
    ax,bx,ay,by:Double;                         // Image<->Graphe conversion coefs

    Down:Boolean;
    Zoom:Boolean;
    Fixed:Boolean;
    XDown,YDown,XOld,YOld:Integer;
    XVMarkOld, XMarkOld,YMarkOld:Integer;
    ZoomRect:TRect;

    FShowReticule:Boolean;
    FShowVerticalReticule:Boolean;

    FDrawVertReticule:TDrawVertReticule;
    FDrawReticule:TDrawReticule;

    XReticule,YReticule:Integer;

    FFrame: TChartPen;

    FBackColor: TColor;

    FAxisVisible: boolean;
    
    FNumBarSeries: integer;

    procedure SetAutoUpdateXMin(Value:Boolean);
    procedure SetAutoUpdateXMax(Value:Boolean);
    procedure SetAutoUpdateYMin(Value:Boolean);
    procedure SetAutoUpdateYMax(Value:Boolean);
    procedure SetXGraphMin(Value:Double);
    procedure SetYGraphMin(Value:Double);
    procedure SetXGraphMax(Value:Double);
    procedure SetYGraphMax(Value:Double);
    procedure SetMirrorX(Value:Boolean);
    procedure SetGraphBrush(Value:TBrush);
    procedure SetTitle(Value:TChartTitle);
    procedure SetFoot(Value:TChartTitle);
    function  GetLegendWidth(ACanvas : TCanvas):Integer;
    procedure GetPointNextTo(X,Y:Integer;var SerieNumberOut,PointNumberOut,XOut,YOut:Integer);
    procedure GetXPointNextTo(X,Y:Integer;var SerieNumberOut,PointNumberOut,XOut,YOut:Integer);
    procedure GetYPointNextTo(X,Y:Integer;var SerieNumberOut,PointNumberOut,XOut,YOut:Integer);
    procedure DrawReticule(ACanvas : TCanvas; X,Y:Integer);
    procedure DrawVerticalReticule(ACanvas : TCanvas; X:Integer);
    procedure SetShowVerticalReticule(Value:Boolean);
    procedure SetShowReticule(Value:Boolean);

    procedure SetLegend(Value:TChartLegend);
    procedure SetLeftAxis(Value:TChartAxis);
    procedure SetBottomAxis(Value:TChartAxis);

    procedure SetFrame(Value: TChartPen);

    procedure SetBackColor(Value: TColor);
    procedure SetAxisVisible(Value: boolean);

    function GetChartHeight: integer;
    function GetChartWidth: integer;

    function GetSeriesCount: Integer;

    function only_pie: boolean;
    function get_pie: pointer;
    function SeriesInLegendCount: integer;
  protected
    { D�clarations prot�g�es }
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DoDrawVertReticule(IndexSerie,Index,Xi,Yi:Integer;Xg,Yg:Double); virtual;
    procedure DoDrawReticule(IndexSerie,Index,Xi,Yi:Integer;Xg,Yg:Double); virtual;
  public
    XImageMin,YImageMin:Integer;                // Image coordinates of limits
    XImageMax,YImageMax:Integer;

    { D�clarations publiques }
    constructor Create(AOwner:TComponent); override;
    destructor  Destroy; override;
    procedure Paint; override;
    procedure PaintOnCanvas(ACanvas : TCanvas; ARect : TRect);
    procedure Refresh(ACanvas : TCanvas; ARect : TRect);
    procedure Clean(ACanvas : TCanvas; ARect : TRect);
    procedure DrawTitleFoot(ACanvas : TCanvas; ARect : TRect);
    procedure DrawAxis(ACanvas : TCanvas; ARect : TRect);
    procedure DrawLegend(ACanvas : TCanvas; ARect : TRect);

    procedure AddSerie(Serie:TComponent);
    procedure DeleteSerie(Serie:TComponent);
    function  GetSerie(i:Integer):TComponent;
    procedure SetAutoXMin(Auto:Boolean);
    procedure SetAutoXMax(Auto:Boolean);
    procedure SetAutoYMin(Auto:Boolean);
    procedure SetAutoYMax(Auto:Boolean);

    procedure XGraphToImage(Xin:Double;var XOut:Integer);
    procedure YGraphToImage(Yin:Double;var YOut:Integer);
    procedure GraphToImage(Xin,Yin:Double;var XOut,YOut:Integer);
    procedure XImageToGraph(XIn:Integer;var XOut:Double);
    procedure YImageToGraph(YIn:Integer;var YOut:Double);
    procedure ImageToGraph(XIn,YIn:Integer;var XOut,YOut:Double);
    procedure DisplaySeries(ACanvas : TCanvas);
    procedure ZoomFull;

    procedure SaveToBitmapFile(Const FileName:String);
    procedure CopyToClipboardBitmap;
    procedure DrawOnCanvas(Rect : TRect; ACanvas : TCanvas);

    property SeriesCount:Integer read GetSeriesCount;
    
    property NumBarSeries: integer read FNumBarSeries;

    function GetNewColor:TColor;
    
    function GetRectangle:TRect;

    property Canvas;

    property ChartHeight: Integer read GetChartHeight;
    property ChartWidth: Integer read GetChartWidth;

    property Series: TSeriesList read FSeries write FSeries;
  published
    { D�clarations publi�es }
    procedure StyleChanged(Sender: TObject);
    property AutoUpdateXMin:Boolean read FAutoUpdateXMin write SetAutoUpdateXMin default True;
    property AutoUpdateXMax:Boolean read FAutoUpdateXMax write SetAutoUpdateXMax default True;
    property AutoUpdateYMin:Boolean read FAutoUpdateYMin write SetAutoUpdateYMin default True;
    property AutoUpdateYMax:Boolean read FAutoUpdateYMax write SetAutoUpdateYMax default True;
    property XGraphMin:Double read FXGraphMin write SetXGraphMin;
    property YGraphMin:Double read FYGraphMin write SetYGraphMin;
    property XGraphMax:Double read FXGraphMax write SetXGraphMax;
    property YGraphMax:Double read FYGraphMax write SetYGraphMax;
    property MirrorX:Boolean read FMirrorX write SetMirrorX;
    property GraphBrush:TBrush read FGraphBrush write SetGraphBrush;
    property ShowVerticalReticule:Boolean read FShowVerticalReticule write SetShowVerticalReticule;
    property ShowReticule:Boolean read FShowReticule write SetShowReticule;

    property OnDrawVertReticule:TDrawVertReticule read FDrawVertReticule write FDrawVertReticule;
    property OnDrawReticule:TDrawReticule read FDrawReticule write FDrawReticule;

    property Legend: TChartLegend read FLegend write SetLegend;
    property Title: TChartTitle read FTitle write SetTitle;
    property Foot: TChartTitle read FFoot write SetFoot;

    property AllowZoom: Boolean read FAllowZoom write FAllowZoom default True;

    property LeftAxis: TChartAxis read FLeftAxis write SetLeftAxis;
    property BottomAxis: TChartAxis read FBottomAxis write SetBottomAxis;
    property Frame: TChartPen read FFrame write setFrame;

    property BackColor: TColor read FBackColor write SetBackColor;

    property AxisVisible: boolean read FAxisVisible write SetAxisVisible default True;

    property Align;
    property Anchors;
    property Color;
    property DragCursor;
    property DragMode;
    property Enabled;
    property ParentColor;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;

    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnStartDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;



procedure Register;

implementation

uses taseries;

procedure RotateLabel(Canvas: TCanvas; x,y:Integer; Const St:String; RotDegree:Integer);
var OldFont,
    NewFont: HFONT;
    LogRec: TLOGFONT;
    DC : HDC;
begin
  with Canvas do begin
    Brush.Style := bsClear;
    GetObject(Font.Handle, SizeOf(LogRec), @LogRec);
    LogRec.lfEscapement   := RotDegree*10;
    LogRec.lfOrientation  := 0;
    LogRec.lfOutPrecision := OUT_TT_ONLY_PRECIS;
    NewFont := CreateFontIndirect(LogRec);
    DC:=Handle;
  end;
  OldFont := SelectObject(DC,NewFont);
  TextOut(DC,X, Y, @St[1],Length(St));
  DeleteObject(SelectObject(DC,OldFont));
end;

procedure TChartPen.SetVisible(Value: Boolean);
begin
     FVisible := Value;
     if assigned( OnChange ) then OnChange(Self);
end;

procedure TChartPen.Assign(Source: TPersistent);
begin
     if Source is TChartPen then
        with TChartPen( Source ) do begin
             FVisible := Visible;
        end;
     inherited Assign( Source );
end;


///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

Constructor TChartAxis.Create(AOwner: TCustomChart);
begin
     inherited Create;
     FOwner := AOwner;
     FTitle := TChartAxisTitle.Create(AOwner);
     FGrid := TChartPen.Create;
     FGrid.OnChange := StyleChanged;
end;

Destructor TChartAxis.Destroy;
begin
     FTitle.Free;
     FGrid.Free;
     inherited;
end;

procedure TChartAxis.SetVisible(value: boolean);
begin
     FVisible := value;
     StyleChanged(Self);
end;

procedure TChartAxis.SetTitle(value: TChartAxisTitle);
begin
     FTitle.Assign(Value);
     StyleChanged(Self);
end;

procedure TChartAxis.SetGrid(value: TChartPen);
begin
     FGrid.Assign(Value);
     StyleChanged(Self);
end;

procedure TChartAxis.SetInverted(value: boolean);
//Inverts the axis scale from increasing to decreasing
begin
     FInverted := value;
     StyleChanged(Self);
end;

procedure TChartAxis.Assign(Source:TPersistent);
begin
     if Source is TChartAxis then
        with TChartAxis(Source) do begin
             FTitle.Assign( Title );
             FVisible := Visible;
        end;
    inherited Assign(Source);
end;

procedure TChartAxis.StyleChanged(Sender: TObject);
begin
     FOwner.invalidate;
end;

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

Constructor TChartAxisTitle.Create(AOwner: TCustomChart);
begin
     inherited Create;
     FOwner := AOwner;
     FFont := TFont.Create;
     FFont.OnChange := StyleChanged;
end;

Destructor TChartAxisTitle.Destroy;
begin
     FFont.Destroy;
     inherited;
end;

procedure TChartAxisTitle.SetCaption(value: String);
begin
     FCaption := Value;
     StyleChanged(Self);
end;

procedure TChartAxisTitle.SetAngle(value: Integer);
begin
     FAngle := Value;
     StyleChanged(Self);
end;

procedure TChartAxisTitle.SetFont(value: TFont);
begin
     FFont.Assign( Value );
     StyleChanged(Self);
end;

procedure TChartAxisTitle.StyleChanged(Sender: TObject);
begin
     FOwner.Invalidate;
end;

procedure TChartAxisTitle.Assign(Source:TPersistent);
begin
     if Source is TChartAxisTitle then
        with TChartAxisTitle(Source) do begin
             FCaption := Caption;
             FAngle := Angle;
             FFont.Assign(Font);
        end;
    inherited Assign(Source);
end;

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

Constructor TChartLegend.Create(AOwner: TCustomChart);
begin
     inherited create;
     FOwner := AOwner;
     FVisible := false;
     FAlignment := laRight;

     FFont := TFont.Create;
     FFont.OnChange := StyleChanged;
     FFrame := TChartPen.Create;
     FFrame.OnChange := StyleChanged;
end;

Destructor TChartLegend.Destroy;
begin
     FFont.Destroy;
     FFrame.Destroy;

     inherited Destroy;
end;

Procedure TChartLegend.Assign(Source:TPersistent);
begin
  if Source is TChartLegend then
  With TChartLegend(Source) do
  Begin
    Self.FVisible   := FVisible;
    Self.FAlignment := FAlignment;
  end;

  inherited Assign(Source);
end;

procedure TChartLegend.SetVisible(value: boolean);
begin
     FVisible := value;
     StyleChanged(Self);
end;

procedure TChartLegend.SetAlignment(value: TLegendAlignment);
begin
     FAlignment := value;
     StyleChanged(Self);
end;

procedure TChartLegend.SetFont(value: TFont);
begin
     FFont.Assign( value );
     StyleChanged(Self);
end;

procedure TChartLegend.SetFrame(value: TChartPen);
begin
     FFrame.Assign( value );
     StyleChanged(Self);
end;

procedure TChartLegend.StyleChanged(Sender: TObject);
begin
     FOwner.Invalidate;
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Constructor TChartTitle.Create(AOwner: TCustomChart);
begin
     inherited create;
     FOwner := AOwner;

     FFont := TFont.Create;
     FFont.Color := clBlue;
     FFont.OnChange := StyleChanged;
     FFrame := TChartPen.Create;
     FFrame.OnChange := StyleChanged;
     FBrush := TBrush.Create;
     FBrush.Color := FOwner.Color;
     FBrush.OnChange := StyleChanged;
     FText := TStringList.Create;
end;

Destructor TChartTitle.Destroy;
begin
     FFont.Destroy;
     FFrame.Destroy;
     FBrush.Destroy;
     FText.Destroy;

     inherited Destroy;
end;

Procedure TChartTitle.Assign(Source:TPersistent);
begin
  if Source is TChartTitle then
    With TChartLegend(Source) do Begin
     Self.FVisible   := FVisible;
     Self.FFont.Assign( Font );
     Self.FBrush.Assign( Brush );
     Self.FFrame.Assign( Frame );
     Self.FText.Assign( Text );
   end;

  inherited Assign(Source);
end;

procedure TChartTitle.SetVisible(value: boolean);
begin
     FVisible := value;
     StyleChanged( Self );
end;

procedure TChartTitle.SetFont(value: TFont);
begin
     FFont.Assign( value );
     StyleChanged( Self );
end;

procedure TChartTitle.SetFrame(value: TChartPen);
begin
     FFrame.Assign( value );
     StyleChanged( Self );
end;


procedure TChartTitle.SetBrush(value: TBrush);
begin
     FBrush.Assign( value );
     StyleChanged( Self );
end;

procedure TChartTitle.SetText(value: TStrings);
begin
     FText.Assign( value );
     StyleChanged( Self );
end;

procedure TChartTitle.SetAlignment(value: TAlignment);
begin
   FAlignment := Value;
   StyleChanged( Self );
end;


procedure TChartTitle.StyleChanged(Sender: TObject);
begin
     FOwner.Invalidate;
end;


procedure CalculateIntervals(Mini,Maxi:Double; AxisScale: TAxisScale;
                                                          var Debut,Pas:Double);
var
   Etendue,EtendueTmp:Double;
   NbPas,Mult:array[1..3] of Double;

   Index:array[1..3] of Byte;
   Trouve:Boolean;
   DTmp:Double;
   BTmp:Byte;
   i,j:Integer;
begin
   if Maxi>59 then Sleep(1);
   Etendue:=Maxi-Mini;
   if Etendue<=0 then begin Debut:=Mini; Pas:=1; Exit; end;
   Mult[1]:=1;
   EtendueTmp:=Etendue;
   NbPas[1]:=EtendueTmp;
   if NbPas[1]>=10 then
      begin
           while NbPas[1]>10 do
                 begin
                      EtendueTmp:=EtendueTmp/10;
                      Mult[1]:=Mult[1]/10;
                      NbPas[1]:=EtendueTmp;
                 end;
      end
      else
      begin
           while EtendueTmp*10<=10 do
                 begin
                      EtendueTmp:=EtendueTmp*10;
                      Mult[1]:=Mult[1]*10;
                      NbPas[1]:=EtendueTmp;
                 end;
      end;
   Mult[2]:=1;
   EtendueTmp:=Etendue;
   NbPas[2]:=EtendueTmp/0.5;
   if NbPas[2]>=10 then
      begin
           while NbPas[2]>10 do
                 begin
                      EtendueTmp:=EtendueTmp/10;
                      Mult[2]:=Mult[2]/10;
                      NbPas[2]:=EtendueTmp/0.5;
                 end;
      end
      else
      begin
           while EtendueTmp*10/0.5<=10 do
                 begin
                      EtendueTmp:=EtendueTmp*10;
                      Mult[2]:=Mult[2]*10;
                      NbPas[2]:=EtendueTmp/0.5;
                 end;
      end;
   Mult[3]:=1;
   EtendueTmp:=Etendue;
   NbPas[3]:=EtendueTmp/0.2;
   if NbPas[3]>=10 then
      begin
           while NbPas[3]>10 do
                 begin
                      EtendueTmp:=EtendueTmp/10;
                      Mult[3]:=Mult[3]/10;
                      NbPas[3]:=EtendueTmp/0.2;
                 end;
      end
      else
      begin
           while EtendueTmp*10/0.2<=10 do
                 begin
                      EtendueTmp:=EtendueTmp*10;
                      Mult[3]:=Mult[3]*10;
                      NbPas[3]:=EtendueTmp/0.2;
                 end;
      end;
   for i:=1 to 3 do Index[i]:=i;
   Trouve:=True;
   while Trouve do
         begin
              Trouve:=False;
              for i:=1 to 2 do
                  if NbPas[i]>NbPas[i+1] then
                     begin
                          Trouve:=True;
                          DTmp:=NbPas[i];
                          NbPas[i]:=NbPas[i+1];
                          NbPas[i+1]:=DTmp;
                          BTmp:=Index[i];
                          Index[i]:=Index[i+1];
                          Index[i+1]:=BTmp;
                     end;
         end;
   if NbPas[3]<=10 then j:=3
      else if NbPas[2]<=10 then j:=2
      else if NbPas[1]<=10 then j:=1
      else
      begin
      //   ShowMessage(lang('Erreur'));
           Exit;
      end;
   if Index[j]=1 then Pas:=1;
   if Index[j]=2 then Pas:=0.5;
   if Index[j]=3 then Pas:=0.2;
   Pas:=Pas/Mult[Index[j]];
   case AxisScale of
        asIncreasing:
           begin
           // Sets 0 as a mark, in case it is in the interval
           if (Mini<0) and (Maxi>0) then
              begin
                   Debut:=0;
                   while (Debut > Mini) do Debut := Debut-Pas;
              end
              else
              begin
                // Don''t work if mini is negative and > 1
              //   if Abs(Mini)<1 then
                   Debut:=Round((Mini-Pas)*Mult[Index[j]])/Mult[Index[j]]
              //   else
              //      Debut:=System.Int(Mini)-Pas; //null
              end;
           end;
        asDecreasing:
           begin
           // Sets 0 as a mark, in case it is in the interval
           if (Mini<0) and (Maxi>0) then
              begin
                   Debut:=0;
                   while (Debut < Maxi) do Debut := Debut+Pas;
              end
              else
              begin
                // Don''t work if mini is negative and > 1
              //   if Abs(Mini)<1 then
                   Debut:=Round((Maxi+Pas)*Mult[Index[j]])/Mult[Index[j]]
              //   else
              //      Debut:=System.Int(Mini)-Pas; //null
              end;
           end;
        asLogIncreasing:
           begin
           // FIXME: asLogIncreasing is still not implemented. The following is the
           // same code for asIncreasing;
           // Sets 0 as a mark, in case it is in the interval
           if (Mini<0) and (Maxi>0) then
              begin
                   Debut:=0;
                   while (Debut > Mini) do Debut := Debut-Pas;
              end
              else
              begin
                // Don''t work if mini is negative and > 1
              //   if Abs(Mini)<1 then
                   Debut:=Round((Mini-Pas)*Mult[Index[j]])/Mult[Index[j]]
              //   else
              //      Debut:=System.Int(Mini)-Pas; //null
              end;
           end;
        asLogDecreasing:
           begin
           // FIXME: asLogDecreasing is still not implemented. The following is the
           // same code for asIncreasing;
           // Sets 0 as a mark, in case it is in the interval
           if (Mini<0) and (Maxi>0) then
              begin
                   Debut:=0;
                   while (Debut > Mini) do Debut := Debut-Pas;
              end
              else
              begin
                // Don''t work if mini is negative and > 1
              //   if Abs(Mini)<1 then
                   Debut:=Round((Mini-Pas)*Mult[Index[j]])/Mult[Index[j]]
              //   else
              //      Debut:=System.Int(Mini)-Pas; //null
              end;
           end;
   end; {case AxisScale}
end;

constructor TChart.Create(AOwner:TComponent);
begin
    inherited Create(AOwner);
    TmpBrush := TBrush.Create;
    TmpPen := TPen.Create;
    TmpFont := TFont.Create;

    FAllowZoom := True;
    FAxisVisible := true; 

    Width := 400;
    Height := 300;

    XVMarkOld:=-1;
    XMarkOld:=-1;
    YMarkOld:=-1;

    Series:=TSeriesList.Create;

    YMarkWidth:=10;

    FAutoUpdateXMin:=True;
    FAutoUpdateXMax:=True;
    FAutoUpdateYMin:=True;
    FAutoUpdateYMax:=True;

    Color:=clBtnFace;
    AxisColor:=clBlack;

    FXGraphMax:=0;
    FXGraphMin:=0;
    FYGraphMax:=0;
    FYGraphMin:=0;

    MirrorX:=False;
    Fixed:=False;
    Zoom:=False;
    FShowReticule:=False;
    FShowVerticalReticule:=False;
    FBackColor := Color;

    FGraphBrush:=TBrush.Create;
    FGraphBrush.OnChange:=StyleChanged;

    FLegend := TChartLegend.Create(Self);
    FTitle := TChartTitle.Create(Self);
    FTitle.Alignment := taCenter;
    FTitle.Text.Add('TAChart');
    FFoot := TChartTitle.Create(Self);

    FLeftAxis := TChartAxis.Create(Self);
    FLeftAxis.Title.Angle := 90;
    FLeftAxis.Inverted := false;
    FLeftAxis.Grid.Visible := True;
    FLeftAxis.Grid.Style := psDot;
    FBottomAxis := TChartAxis.Create(Self);
    FBottomAxis.Title.Angle := 0;
    FBottomAxis.Inverted := false;
    FBottomAxis.Grid.Visible := True;
    FBottomAxis.Grid.Style := psDot;

    FFrame :=  TChartPen.Create;
    FFrame.Visible := true;
    FFrame.OnChange := StyleChanged;
    
    FNumBarSeries := 0;
end;

destructor TChart.Destroy;
var
   MySerie:TChartSeries;
   i,c: integer;
begin
     if FSeries.Count > 0 then begin
       c := FSeries.Count - 1;
       for i := 0 to c do  begin
           TChartSeries(FSeries.Items[0]).Free;
           FSeries.Delete( 0 );
       end;
     end;

     FSeries.Free;
     FGraphBrush.Free;

     TmpBrush.Destroy;
     TmpPen.Destroy;
     TmpFont.Destroy;

     FLegend.Destroy;
     FTitle.Destroy;
     FFoot.Destroy;
     LeftAxis.Destroy;
     BottomAxis.Destroy;
     FFrame.Destroy;

     inherited Destroy;
end;

procedure TChart.StyleChanged(Sender: TObject);
begin
     Invalidate;
end;

procedure TChart.Paint;
Begin
PaintOnCanvas(Canvas,Rect(0,0,Width,Height));
End;

procedure TChart.PaintOnCanvas(ACanvas : TCanvas; ARect : TRect);
var i: integer;
begin
     YImageMin:=ARect.Bottom-5;
     YImageMax:=ARect.Top+5;

     if FTitle.Visible then begin
       TmpFont.Assign( ACanvas.Font );
       ACanvas.Font.Assign( FTitle.Font );
        for i := 0 to FTitle.Text.Count -1 do begin
           YImageMax:=YImageMax+5+ACanvas.TextHeight(FTitle.Text[i]);
        end;
        ACanvas.Font.Assign(TmpFont);
     end;

     if FFoot.Visible then begin
        TmpFont.Assign( ACanvas.Font );
        ACanvas.Font.Assign( FFoot.Font );
        for i := 0 to FFoot.Text.Count -1 do begin
           YImageMin:=YImageMin-5-ACanvas.TextHeight(FFoot.Text[i]);
        end;
        ACanvas.Font.Assign(TmpFont);
     end;

     if FBottomAxis.Visible and FAxisVisible then begin
        //FIXME: fix to rotate other than 0/90/180 degres
        YImageMin:=YImageMin-ACanvas.TextHeight(FBottomAxis.Title.Caption)
                  -ACanvas.TextHeight('1');
     end;
     if FMirrorX then begin
        XImageMin:=ARect.Right-YMarkWidth-GetLegendWidth(ACanvas);
        XImageMax:=ARect.Left;
     end else begin
         if FLeftAxis.Visible and FAxisVisible  then
            XImageMin:=YMarkWidth+ACanvas.TextHeight(FLeftAxis.Title.Caption)+ARect.Left
         else
            XImageMin:=YMarkWidth+ARect.Left;
         XImageMax:=ARect.Right-10-GetLegendWidth(ACanvas);
     end;
     Refresh(ACanvas, ARect);
end;

procedure TChart.Clean;
begin
     ACanvas.Pen.Mode:=pmCopy;
     ACanvas.Pen.Style:=psSolid;
     ACanvas.Pen.Color:=Color;
     ACanvas.Brush.Color:=Color;
     ACanvas.Brush.Style:=bsSolid;
     ACanvas.Rectangle(ARect.Left,ARect.Top,ARect.Right,ARect.Bottom);
end;

procedure TChart.DrawTitleFoot(ACanvas : TCanvas; ARect : TRect);
var i: Integer;
    t, xpos: Integer;
begin
   if FTitle.Visible and (FTitle.Text.Count > 0) then begin
      TmpBrush.Assign( ACanvas.Brush );
      TmpFont.Assign( ACanvas.Font );

      ACanvas.Brush.Assign( FTitle.Brush );
      ACanvas.Font.Assign( FTitle.Font );
      t := 5+ARect.Top;
      for i := 0 to FTitle.Text.Count -1 do begin
          case FTitle.Alignment of
               taLeftJustify:  xpos := XImageMin;
               taCenter:       xpos := (ARect.Left+ARect.Right-ACanvas.TextWidth(FTitle.Text[i])) div 2;
               taRightJustify: xpos := XImageMax - ACanvas.TextWidth(FTitle.Text[i]);
          end;
         ACanvas.TextOut( xpos ,t,FTitle.Text[i]);
         t := t + ACanvas.TextHeight(FTitle.Text[i]);
      end;
      ACanvas.Brush.Assign( TmpBrush );
      ACanvas.Font.Assign( TmpFont );
   end;
   if FFoot.Visible and (FFoot.Text.Count > 0) then begin
      TmpBrush.Assign( ACanvas.Brush );
      TmpFont.Assign( ACanvas.Font );
      ACanvas.Brush.Assign( FFoot.Brush );
      ACanvas.Font.Assign( FFoot.Font );
      t := ARect.Bottom-5-ACanvas.TextHeight(FFoot.Text[0]);
      for i := FFoot.Text.Count - 1 downto 0 do begin
          case FFoot.Alignment of
               taLeftJustify:  xpos := XImageMin;
               taCenter:       xpos := (ARect.Left+ARect.Right-ACanvas.TextWidth(FFoot.Text[i])) div 2;
               taRightJustify: xpos := XImageMax - ACanvas.TextWidth(FFoot.Text[i]);
          end;
         ACanvas.TextOut( xpos ,t,FFoot.Text[i]);
         t := t - ACanvas.TextHeight(FFoot.Text[i]);
      end;
      ACanvas.Brush.Assign( TmpBrush );
      ACanvas.Font.Assign( TmpFont );
   end;
end;

procedure TChart.DrawAxis(ACanvas : TCanvas; ARect : TRect);
var
  LargTexte,MaxLargTexte,HautTexte:Integer;
  XTemp,YTemp,XPos:Integer;
  MyText:string;
  Marque,Debut,Pas:Double;
  T: Integer;
  LeftAxisWidth: Integer;
  LeftAxisScale, BottomAxisScale : TAxisScale;
begin
   // Check AxisScale for both axes
   Case LeftAxis.Inverted of
        true : LeftAxisScale := asDecreasing;
        false: LeftAxisScale := asIncreasing;
   end;
   Case BottomAxis.Inverted of
        true : BottomAxisScale := asDecreasing;
        false: BottomAxisScale := asIncreasing;
   end;
   // Find max mark width
   MaxLargTexte:=0;
   Debut:=FYGraphMax;
   Pas:=1;
   CalculateIntervals(FYGraphMin,FYGraphMax,LeftAxisScale,Debut,Pas);
   if FYGraphMin<>FYGraphMax then begin
      Marque:=Debut;
      case LeftAxisScale of
          asIncreasing:
             begin
                  while Marque<=FYGraphMax+Pas*10e-10 do begin
                        if (Marque>=FYGraphMin) then begin
                           YGraphToImage(Marque,YTemp);
                           If (Marque<1e-16) and (Marque>-1e-16) then Marque:=0; 
                           MyText:=Trim(FloatToStr(Marque));
                           LargTexte:=ACanvas.TextWidth(MyText);
                           if LargTexte>MaxLargTexte then MaxLargTexte:=LargTexte;
                        end;
                  Marque:=Marque+Pas;
                  end;
             end;
          asDecreasing:
             begin
                  while Marque>=FYGraphMin-Pas*10e-10 do begin
                        if (Marque<=FYGraphMax) then begin
                           YGraphToImage(Marque,YTemp);
                           If (Marque<1e-16) and (Marque>-1e-16) then Marque:=0; 
                           MyText:=Trim(FloatToStr(Marque));
                           LargTexte:=ACanvas.TextWidth(MyText);
                           if LargTexte>MaxLargTexte then MaxLargTexte:=LargTexte;
                        end;
                  Marque:=Marque-Pas;
                  end;
             end;
      end;  {case LeftAxisScale}
   end;

   YMarkWidth:=10;
   //only consider this width if visible
   if FLeftAxis.Visible and FAxisVisible then
      LeftAxisWidth := ACanvas.TextHeight(FLeftAxis.Title.Caption) + 16
   else LeftAxisWidth := 0;

   if MaxLargTexte+LeftAxisWidth>YMarkWidth then begin
      YMarkWidth:=MaxLargTexte+LeftAxisWidth;
      if FMirrorX then begin
         XImageMin:=ARect.Right-YMarkWidth-GetLegendWidth(ACanvas);
         XImageMax:=ARect.Left+10;
      end
      else begin
         XImageMin:=ARect.Left+YMarkWidth;
         XImageMax:=ARect.Right-10-GetLegendWidth(ACanvas);
      end;

      // Update coefs
      if (FXGraphMax-FXGraphMin <>0) and (FYGraphMax-FYGraphMin <> 0) then begin
         case BottomAxisScale of
             asIncreasing:
                 begin
                     ax:=(XImageMax-XImageMin)/(FXGraphMax-FXGraphMin);
                     bx:=XImageMax-ax*FXGraphMax;
                 end;
             asDecreasing:
                 begin
                     ax:=(XImageMax-XImageMin)/(FXGraphMin-FXGraphMax);
                     bx:=XImageMin-ax*FXGraphMax;
                 end;
         end;
         case LeftAxisScale of
             asIncreasing:
                 begin
                     ay:=(YImageMax-YImageMin)/(FYGraphMax-FYGraphMin);
                     by:=YImageMax-ay*FYGraphMax;
                 end;
             asDecreasing:
                 begin
                     ay:=(YImageMax-YImageMin)/(FYGraphMin-FYGraphMax);
                     by:=YImageMin-ay*FYGraphMax;
                 end;
         end;
      end;
   end;

   // Back
   ACanvas.Pen.Style:=psClear;
   ACanvas.Brush.Color := FBackColor;
   ACanvas.Rectangle(XImageMin,YImageMin,XImageMax,YImageMax);

   // Axes
   if FFrame.Visible then begin
      ACanvas.Pen.Assign( FFrame );
      ACanvas.MoveTo(XImageMin,YImageMin);
      ACanvas.LineTo(XImageMin,YImageMax);
      ACanvas.MoveTo(XImageMin,YImageMin);
      ACanvas.LineTo(XImageMax,YImageMin);
      ACanvas.MoveTo(XImageMin,YImageMax);
      ACanvas.LineTo(XImageMax,YImageMax);
      ACanvas.MoveTo(XImageMax,YImageMin);
      ACanvas.LineTo(XImageMax,YImageMax);
   end;


   // Axis Labels
   if FLeftAxis.Visible and FAxisVisible then begin
{      Canvas.Brush.Color:=Color;
      Canvas.Font.Color:=clBlack;
      }
      if FMirrorX then T := ARect.Right-ACanvas.TextWidth(FLeftAxis.Title.Caption)+5
      else T := 5;
      if FTitle.Visible then
         RotateLabel(ACanvas, T, YImageMin+((YImageMax-YImageMin) div 2)
                     +(ACanvas.TextWidth(FLeftAxis.Title.Caption) div 2),
                       FLeftAxis.Title.Caption, FLeftAxis.Title.Angle)
      else
         RotateLabel(ACanvas, T, YImageMin+((YImageMax-YImageMin) div 2)
                     +(ACanvas.TextWidth(FLeftAxis.Title.Caption) div 2),
                       FLeftAxis.Title.Caption, FLeftAxis.Title.Angle);
   end;

   if FBottomAxis.Visible and FAxisVisible then begin
      RotateLabel(ACanvas, XImageMin+((XImageMax-XImageMin) div 2)
                  -(ACanvas.TextWidth(FBottomAxis.Title.Caption) div 2),
                    YImageMin+5+ACanvas.TextHeight(FBottomAxis.Title.Caption),
                    FBottomAxis.Title.Caption, FBottomAxis.Title.Angle);
   end;

   // X graduations
   if FBottomAxis.Visible and FAxisVisible then begin
      Debut:=FXGraphMax;
      Pas:=1;
      CalculateIntervals(FXGraphMin,FXGraphMax,BottomAxisScale,Debut,Pas);
      if FXGraphMin<>FXGraphMax then begin
         Marque:=Debut;
         case BottomAxisScale of
            asIncreasing:
               begin
                  while Marque<=FXGraphMax+Pas*10e-10 do begin
                     if (Marque>=FXGraphMin) then begin
                        XGraphToImage(Marque,XTemp);
                        ACanvas.Brush.Assign(FGraphBrush);
                        if FBottomAxis.Grid.Visible then begin
                           ACanvas.Pen.Assign(FBottomAxis.Grid);
                           if (XTemp<>XImageMax) and (XTemp<>XImageMin) then
                           begin
                              ACanvas.MoveTo(XTemp,YImageMin);
                              ACanvas.LineTo(XTemp,YImageMax);
                           end;
                        end;
                        ACanvas.Pen.Color:=AxisColor;
                        ACanvas.Pen.Style:=psSolid;
                        ACanvas.Pen.Mode:=pmCopy;
                        ACanvas.MoveTo(XTemp,YImageMin-4);
                        ACanvas.LineTo(XTemp,YImageMin+4);
                        ACanvas.Brush.Color:=Color;
                        If (Marque<1e-16) and (Marque>-1e-16) then Marque:=0;
                        MyText:=Trim(FloatToStr(Marque));
                        LargTexte:=ACanvas.TextWidth(MyText) div 2;
                        XPos:=XTemp-LargTexte;
                        if XPos<1 then Xpos:=1;
                        if XPos+LargTexte*2>ARect.Right then Xpos:=ARect.Right-LargTexte*2-1;
                        ACanvas.TextOut(Xpos,YImageMin+4,MyText);
                     end;
                     Marque:=Marque+Pas;
                  end;
               end;
            asDecreasing:
               begin
                  while Marque>=FXGraphMin-Pas*10e-10 do begin
                     if (Marque<=FXGraphMax) then begin
                        XGraphToImage(Marque,XTemp);
                        ACanvas.Brush.Assign(FGraphBrush);
                        if FBottomAxis.Grid.Visible then begin
                           ACanvas.Pen.Assign(FBottomAxis.Grid);
                           if (XTemp<>XImageMax) and (XTemp<>XImageMin) then
                           begin
                              ACanvas.MoveTo(XTemp,YImageMin);
                              ACanvas.LineTo(XTemp,YImageMax);
                           end;
                        end;
                        ACanvas.Pen.Color:=AxisColor;
                        ACanvas.Pen.Style:=psSolid;
                        ACanvas.Pen.Mode:=pmCopy;
                        ACanvas.MoveTo(XTemp,YImageMin-4);
                        ACanvas.LineTo(XTemp,YImageMin+4);
                        ACanvas.Brush.Color:=Color;
                        If (Marque<1e-16) and (Marque>-1e-16) then Marque:=0;
                        MyText:=Trim(FloatToStr(Marque));
                        LargTexte:=ACanvas.TextWidth(MyText) div 2;
                        XPos:=XTemp-LargTexte;
                        if XPos<1 then Xpos:=1;
                        if XPos+LargTexte*2>ARect.Right then Xpos:=ARect.Right-LargTexte*2-1;
                        ACanvas.TextOut(Xpos,YImageMin+4,MyText);
                     end;
                     Marque:=Marque-Pas;
                  end;
               end;
         end;   {case BottomAxisScale}
      end;
   end;

   // Y graduations
   if FLeftAxis.Visible and AxisVisible then begin
      MaxLargTexte:=0;
      Debut:=FYGraphMax;
      Pas:=1;
      CalculateIntervals(FYGraphMin,FYGraphMax,LeftAxisScale,Debut,Pas);
      if FYGraphMin<>FYGraphMax then begin
         Marque:=Debut;
         case LeftAxisScale of
            asIncreasing:
               begin
                  while Marque<=FYGraphMax+Pas*10e-10 do begin
                     if (Marque>=FYGraphMin) then begin
                        YGraphToImage(Marque,YTemp);
                        ACanvas.Brush.Assign(FGraphBrush);
                        //draw grid
                        if FLeftAxis.Grid.Visible then begin
                           ACanvas.Pen.Assign(FLeftAxis.Grid);
                           if (YTemp<>YImageMax) and (YTemp<>YImageMin) then
                           begin
                                ACanvas.MoveTo(XImageMin,YTemp);
                                ACanvas.LineTo(XImageMax,YTemp);
                           end;
                        end;
                        ACanvas.Pen.Color:=AxisColor;
                        ACanvas.Pen.Style:=psSolid;
                        ACanvas.Pen.Mode:=pmCopy;
                        ACanvas.MoveTo(XImageMin-4,YTemp);
                        ACanvas.LineTo(XImageMin+4,YTemp);
                        ACanvas.Brush.Color:=Color;
                        If (Marque<1e-16) and (Marque>-1e-16) then Marque:=0;
                        MyText:=Trim(FloatToStr(Marque));
                        LargTexte:=ACanvas.TextWidth(MyText);
                        if LargTexte>MaxLargTexte then MaxLargTexte:=LargTexte;
                        HautTexte:=ACanvas.TextHeight(MyText) div 2;
                        if FMirrorX then
                           ACanvas.TextOut(XImageMin+6,YTemp-HautTexte,MyText)
                        else
                            ACanvas.TextOut(XImageMin-7-LargTexte,YTemp-HautTexte,MyText);
                     end;
                     Marque:=Marque+Pas;
                  end;
               end;
            asDecreasing:
               begin
                  while Marque>=FYGraphMin-Pas*10e-10 do begin
                     if (Marque<=FYGraphMax) then begin
                        YGraphToImage(Marque,YTemp);
                        ACanvas.Brush.Assign(FGraphBrush);
                        //draw grid
                        if FLeftAxis.Grid.Visible then begin
                           ACanvas.Pen.Assign(FLeftAxis.Grid);
                           if (YTemp<>YImageMax) and (YTemp<>YImageMin) then
                           begin
                                ACanvas.MoveTo(XImageMin,YTemp);
                                ACanvas.LineTo(XImageMax,YTemp);
                           end;
                        end;
                        ACanvas.Pen.Color:=AxisColor;
                        ACanvas.Pen.Style:=psSolid;
                        ACanvas.Pen.Mode:=pmCopy;
                        ACanvas.MoveTo(XImageMin-4,YTemp);
                        ACanvas.LineTo(XImageMin+4,YTemp);
                        ACanvas.Brush.Color:=Color;
                        If (Marque<1e-16) and (Marque>-1e-16) then Marque:=0;
                        MyText:=Trim(FloatToStr(Marque));
                        LargTexte:=ACanvas.TextWidth(MyText);
                        if LargTexte>MaxLargTexte then MaxLargTexte:=LargTexte;
                        HautTexte:=ACanvas.TextHeight(MyText) div 2;
                        if FMirrorX then
                           ACanvas.TextOut(XImageMin+6,YTemp-HautTexte,MyText)
                        else
                            ACanvas.TextOut(XImageMin-7-LargTexte,YTemp-HautTexte,MyText);
                     end;
                     Marque:=Marque-Pas;
                  end;
               end;
         end;   {case LeftAxisScale}
      end;
   end;
end;

procedure TChart.DrawLegend(ACanvas : TCanvas; ARect : TRect);
var
   w,h,x1,y1,x2,y2,i,j,TH:Integer;
   MySerie:TChartSeries;
begin
   TmpBrush.Assign(ACanvas.Brush);
   TmpPen.Assign(ACanvas.Pen);
   TmpFont.Assign(ACanvas.Font);

   w:=GetLegendWidth(ACanvas);
   TH:=ACanvas.TextHeight('I');

   if only_pie then begin//if only one pie show diferent legend
      MySerie := get_pie;
      h:=5+MySerie.Count*(TH+5);
   end else begin
      h:=5+SeriesInLegendCount*(TH+5);
   end;
   x1 := ARect.Right-w-5;
   y1 := YImageMax;
   x2 := x1+w;
   y2 := y1+h;

   // Border
   ACanvas.Brush.Assign(FGraphBrush);
   ACanvas.Pen.Assign( FLegend.Frame );
   ACanvas.Font.Assign( FLegend.Font );
   ACanvas.Rectangle(x1,y1,x2,y2);

   // Lines and Series titles
   if only_pie then begin//if only one pie show diferent legend
      MySerie := get_pie;
      for i := 0 to MySerie.Count - 1 do begin //clean this coord shoould not be published
         ACanvas.Pen.Color := FLegend.Frame.Color;
         ACanvas.Brush.Color := FGraphBrush.Color;
         ACanvas.TextOut(x1+25,y1+5+i*(TH+5), format('%1.2g',[PChartCoord(MySerie.Coord.items[i])^.y])+' '+PChartCoord(MySerie.Coord.items[i])^.Text);
         ACanvas.Pen.Color := clBlack;
         ACanvas.Brush.Color := PChartCoord(MySerie.Coord.items[i])^.Color;
         ACanvas.Rectangle(x1+5,y1+i*(TH+5)+TH div 2, x1+22,y1+10+i*(TH+5)+TH div 2);
      end;
   end else begin
      j := 0;
      for i:=0 to SeriesCount-1 do begin
         MySerie:=Series[i];
         if MySerie.Active and MySerie.ShowInLegend then begin
            ACanvas.Brush.Assign(FGraphBrush);
            ACanvas.TextOut(x1+25,y1+5+j*(TH+5),MySerie.Title);
            ACanvas.Pen.Color := MySerie.SeriesColor;
            if MySerie is TBarSeries then begin
              ACanvas.Pen.Color := clBlack;
              ACanvas.Brush.Assign( (MySerie as TBarSeries).BarBrush);
              ACanvas.Rectangle(x1+5,y1+j*(TH+5)+TH div 2, x1+22,y1+10+j*(TH+5)+TH div 2);
            end else if MySerie is TAreaSeries then begin
              ACanvas.Pen.Color := clBlack;
              ACanvas.Brush.Color := MySerie.SeriesColor;;
              ACanvas.Rectangle(x1+5,y1+j*(TH+5)+TH div 2, x1+22,y1+10+j*(TH+5)+TH div 2);
            end else if (MySerie is TLine) or (MySerie is TSerie)  then begin
              ACanvas.MoveTo(x1+5,y1+5+j*(TH+5)+TH div 2);
              ACanvas.LineTo(x1+22,y1+5+j*(TH+5)+TH div 2);
	    end else  if MySerie is TPieSeries then begin end; //don't draw
	    j += 1;
         end;
      end;
   end;
   ACanvas.Brush.Assign(TmpBrush);
   ACanvas.Pen.Assign(TmpPen);
   ACanvas.Font.Assign(TmpFont);
end;

procedure TChart.SetAutoUpdateXMin(Value:Boolean);
begin
FAutoUpdateXMin:=Value;
end;

procedure TChart.SetAutoUpdateXMax(Value:Boolean);
begin
FAutoUpdateXMax:=Value;
end;

procedure TChart.SetAutoUpdateYMin(Value:Boolean);
begin
FAutoUpdateYMin:=Value;
end;

procedure TChart.SetAutoUpdateYMax(Value:Boolean);
begin
FAutoUpdateYMax:=Value;
end;

procedure TChart.SetXGraphMin(Value:Double);
begin
FXGraphMin:=Value;
Invalidate;
end;

procedure TChart.SetYGraphMin(Value:Double);
begin
FYGraphMin:=Value;
Invalidate;
end;

procedure TChart.SetXGraphMax(Value:Double);
begin
FXGraphMax:=Value;
Invalidate;
end;

procedure TChart.SetYGraphMax(Value:Double);
begin
FYGraphMax:=Value;
Invalidate;
end;

procedure TChart.SetMirrorX(Value:Boolean);
begin
if Value<>FMirrorX then
   begin
   if FMirrorX then
      begin
      XImageMin:=YMarkWidth;
      XImageMax:=Width-10-GetLegendWidth(Canvas);
      FMirrorX:=False;
      end
   else
      begin
      XImageMin:=Width-YMarkWidth-GetLegendWidth(Canvas);
      XImageMax:=10;
      FMirrorX:=True;
      end;
   Invalidate;
   end;
end;

procedure TChart.SetTitle(Value:TChartTitle);
begin
     FTitle.Assign( Value );
     Invalidate;
end;

procedure TChart.SetFoot(value: TChartTitle);
begin
     FFoot.Assign(Value);
     Invalidate;
end;


function TChart.GetLegendWidth(ACanvas : TCanvas):Integer;
var
   i,j,k:Integer;
   MySerie:TSerie;
begin
   if (not FLegend.Visible) or (SeriesInLegendCount = 0) then begin Result:=0; Exit; end;

   if only_pie then begin//if only one pie show diferent legend
      MySerie := get_pie;
      j := 0;
      for i := 0 to MySerie.Count - 1 do begin //clean this coord should not be published
         k := ACanvas.TextWidth( format('%1.2g',[PChartCoord(MySerie.Coord.items[i])^.y])
                          +' '+PChartCoord(MySerie.Coord.items[i])^.Text) ;
         if k>j then j:=k;
      end;
      Result:=j+20+10;
   end else begin
      j:=0;
      for i:=0 to SeriesCount-1 do begin
         MySerie:=Series[i];
         if MySerie.Active and MySerie.ShowInLegend then begin
            k:=ACanvas.TextWidth(MySerie.Title);
            if k>j then j:=k;
         end;
      end;
      Result:=j+20+10;
   end;
end;

procedure TChart.SetGraphBrush(Value:TBrush);
begin
    FGraphBrush.Assign(Value);
end;

procedure TChart.AddSerie(Serie:TComponent);
begin
     if FShowVerticalReticule then DrawVerticalReticule(Canvas,XVMarkOld);
     if FShowReticule then DrawReticule(Canvas,XMarkOld,YMarkOld);
     //disable axis when we have TPie series
     if Serie is TPieSeries then begin
        LeftAxis.Visible := False;
        BottomAxis.Visible := False;
     end;
     Series.Add(Serie);
     TChartSeries(Serie).ParentChart := Self;
     
     if Serie is TBarSeries then begin
       (Serie as TBarSeries).SeriesNumber := FNumBarSeries;
       inc(FNumBarSeries); //FIXME: this is never decremented when series is deleted
     end;
end;

procedure TChart.DeleteSerie(Serie:TComponent);
var
   i:Integer;
   MySerie:TComponent;
begin
i:=0;
while i< SeriesCount do
   begin
   MySerie:=Series[i];
   if Serie=MySerie then
      begin
      Series.Delete(i);
      Invalidate;
      end
   else Inc(i);
   end;
end;

function TChart.GetSerie(i:Integer):TComponent;
begin
     Result:=Series[i];
end;

procedure TChart.SetAutoXMin(Auto:Boolean);
begin
     FAutoUpdateXMin:=Auto;
     Refresh(Canvas,Rect(0,0,Width, Height));
end;

procedure TChart.SetAutoXMax(Auto:Boolean);
begin
     FAutoUpdateXMax:=Auto;
     Refresh(Canvas,Rect(0,0,Width, Height));
end;

procedure TChart.SetAutoYMin(Auto:Boolean);
begin
     FAutoUpdateYMin:=Auto;
     Refresh(Canvas,Rect(0,0,Width, Height));
end;

procedure TChart.SetAutoYMax(Auto:Boolean);
begin
     FAutoUpdateYMax:=Auto;
     Refresh(Canvas,Rect(0,0,Width, Height));
end;

procedure TChart.Refresh(ACanvas : TCanvas; ARect : TRect);
var
   Tolerance,Valeur:Double;
   i:Integer;
   NBPointsMax:Integer;
   Serie:TChartSeries;
   XMinSeries,XMaxSeries,YMinSeries,YMaxSeries:Double;
   LeftAxisScale, BottomAxisScale : TAxisScale;
begin
   if FShowVerticalReticule then DrawVerticalReticule(ACanvas,XVMarkOld);
   if FShowReticule then DrawReticule(ACanvas,XMarkOld,YMarkOld);
   // Check AxisScale for both axes
   Case LeftAxis.Inverted of
        true : LeftAxisScale := asDecreasing;
        false: LeftAxisScale := asIncreasing;
   end;
   Case BottomAxis.Inverted of
        true : BottomAxisScale := asDecreasing;
        false: BottomAxisScale := asIncreasing;
   end;
   // Search # of points, min and max of all series
   if Zoom then begin
      Zoom:=False;
      Fixed:=True;
      XImageToGraph(ZoomRect.Left,FXGraphMin);
      XImageToGraph(ZoomRect.Right,FXGraphMax);
      YImageToGraph(ZoomRect.Bottom,FYGraphMin);
      YImageToGraph(ZoomRect.Top,FYGraphMax);
   end
   else if not Fixed then begin
      XMinSeries:=MaxDouble;
      XMaxSeries:=MinDouble;
      YMinSeries:=MaxDouble;
      YMaxSeries:=MinDouble;
      NBPointsMax:=0;
      for i:=0 to Series.Count-1 do begin
         Serie := Series[i];
         if Serie.Active and (TChartSeries(Serie).Count>0) then begin
            NBPointsMax:=NBPointsMax+TChartSeries(Serie).Count;
            if TChartSeries(Serie).XGraphMin<XMinSeries then XMinSeries:=TChartSeries(Serie).XGraphMin;
            if TChartSeries(Serie).YGraphMin<YMinSeries then YMinSeries:=TChartSeries(Serie).YGraphMin;
            if TChartSeries(Serie).XGraphMax>XMaxSeries then XMaxSeries:=TChartSeries(Serie).XGraphMax;
            if TChartSeries(Serie).YGraphMax>YMaxSeries then YMaxSeries:=TChartSeries(Serie).YGraphMax;
         end;
      end;
      if XMinSeries>MaxDouble/10 then XMinSeries:=0;
      if YMinSeries>MaxDouble/10 then YMinSeries:=0;
      if XMaxSeries<MinDouble/10 then XMaxSeries:=0;
      if YMaxSeries<MinDouble/10 then YMaxSeries:=0;

      if YMaxSeries = YMinSeries then begin
         YMaxSeries := YMaxSeries + 1;
         YMinSeries := YMinSeries - 1;
      end;
      if XMaxSeries = XMinSeries then begin
         XMaxSeries := XMaxSeries + 1;
         XMinSeries := XMinSeries - 1;
      end;


      // Image coordinates calculation
      // Update max in graph
      // If one point : +/-10% of the point coordinates
      Tolerance:=0.001; //this should be cleaned eventually
//      Tolerance:=0.1;

   if NBPointsMax > 0 then
   // If several points : automatic +/-10% of interval
      begin
      Valeur:=Tolerance*(XMaxSeries-XMinSeries);
      if Valeur<>0 then
         begin
         if FAutoUpdateXMin then FXGraphMin:=XMinSeries-Valeur;
         if FAutoUpdateXMax then FXGraphMax:=XMaxSeries+Valeur;
         end
      else
         begin
         if FAutoUpdateXMin then FXGraphMin:=XMinSeries-1;
         if FAutoUpdateXMax then FXGraphMax:=XMaxSeries+1;
         end;
      Valeur:=Tolerance*(YMaxSeries-YMinSeries);
      if Valeur<>0 then
         begin
         if FAutoUpdateYMin then FYGraphMin:=YMinSeries-Valeur;
         if FAutoUpdateYMax then FYGraphMax:=YMaxSeries+Valeur;
         end
      else
         begin
         if FAutoUpdateYMin then FYGraphMin:=YMinSeries-1;
         if FAutoUpdateYMax then FYGraphMax:=YMinSeries+1;
         end;
      end
   else
   // 0 Points
      begin
        if FAutoUpdateXMin then FXGraphMin:=0;
        if FAutoUpdateXMax then FXGraphMax:=0;
        if FAutoUpdateYMin then FYGraphMin:=0;
        if FAutoUpdateYMax then FYGraphMax:=0; 
      end;
   end;
   // Image <-> Graph coeff calculation
   if FXGraphMax<>FXGraphMin then
   begin
         case BottomAxisScale of
             asIncreasing:
                 begin
                     ax:=(XImageMax-XImageMin)/(FXGraphMax-FXGraphMin);
                     bx:=XImageMax-ax*FXGraphMax;
                 end;
             asDecreasing:
                 begin
                     ax:=(XImageMax-XImageMin)/(FXGraphMin-FXGraphMax);
                     bx:=XImageMin-ax*FXGraphMax;
                 end;
         end;
   end
   else
   begin
       ax:=1;
       bx:=0;
   end;
   if FYGraphMax<>FYGraphMin then
   begin
         case LeftAxisScale of
             asIncreasing:
                 begin
                     ay:=(YImageMax-YImageMin)/(FYGraphMax-FYGraphMin);
                     by:=YImageMax-ay*FYGraphMax;
                 end;
             asDecreasing:
                 begin
                     ay:=(YImageMax-YImageMin)/(FYGraphMin-FYGraphMax);
                     by:=YImageMin-ay*FYGraphMax;
                 end;
         end;
   end
   else
   begin
       ay:=1;
       by:=0;
   end;
   Clean(ACanvas,ARect);
   DrawAxis(ACanvas,ARect);
   DisplaySeries(ACanvas);
   DrawTitleFoot(ACanvas, ARect);
   if FLegend.Visible then DrawLegend(ACanvas, ARect);
   if FShowVerticalReticule then DrawVerticalReticule(ACanvas,XVMarkOld);
   if FShowReticule then DrawReticule(ACanvas,XMarkOld,YMarkOld);
end;

procedure TChart.XGraphToImage(Xin:Double;var XOut:Integer);
begin
     XOut:=Round(ax*XIn+bx);
end;

procedure TChart.YGraphToImage(Yin:Double;var YOut:Integer);
begin
     YOut:=Round(ay*YIn+by);
end;

procedure TChart.GraphToImage(Xin,Yin:Double;var XOut,YOut:Integer);
begin
     XGraphToImage(Xin,XOut);
     YGraphToImage(Yin,YOut);
end;

procedure TChart.XImageToGraph(XIn:Integer;var XOut:Double);
begin
     XOut:=(XIn-bx)/ax;
end;

procedure TChart.YImageToGraph(YIn:Integer;var YOut:Double);
begin
     YOut:=(YIn-by)/ay;
end;

procedure TChart.ImageToGraph(XIn,YIn:Integer;var XOut,YOut:Double);
begin
   XImageToGraph(XIn,XOut);
   YImageToGraph(YIn,YOut);
end;

procedure TChart.SaveToBitmapFile(Const FileName:String);
var tmpR:TRect;
    tmpBitmap: TBitmap;
begin
  try
    tmpBitmap := TBitmap.Create;
    tmpR:=GetRectangle;
    tmpBitmap.Width := tmpR.Right-tmpR.Left;
    tmpBitmap.Height:= tmpR.Bottom-tmpR.Top;
    tmpBitmap.Canvas.CopyRect(tmpR, Canvas, tmpR);
    tmpBitmap.SaveToFile(FileName);
  finally
    tmpBitmap.Free;
  end;
end;

procedure TChart.CopyToClipboardBitmap;
var tmpBitmap:TBitmap;
    tmpR:TRect;
begin
  try
    tmpBitmap:=TBitmap.Create;
    tmpR:=GetRectangle;
    tmpBitmap.Width := tmpR.Right-tmpR.Left;
    tmpBitmap.Height:= tmpR.Bottom-tmpR.Top;
    tmpBitmap.Canvas.CopyRect(tmpR, Canvas, tmpR);
    ClipBoard.Assign(tmpBitmap);
  finally
    tmpBitmap.Free;
  end;
end;

procedure TChart.DrawOnCanvas(Rect : TRect; ACanvas : TCanvas);
var tmpCanvas : TCanvas;
Begin
   PaintOnCanvas(ACanvas,Rect);
End;



procedure TChart.DisplaySeries(ACanvas : TCanvas);
var
   i:Integer;
   Serie:TChartSeries;
   Rgn : HRGN;
   p: array[0..1] of TPoint;
begin
     if FSeries.Count = 0 then Exit;

     //set cliping region so we don't draw outsite
     IntersectClipRect(ACanvas.Handle, XImageMin, YImageMax, XImageMax, YImageMin);

     // Update all series
     for i:=0 to FSeries.Count-1 do begin
         Serie:= TChartSeries( Series[i] );
         if Serie.Active then
            Begin
            Serie.Draw(ACanvas);
            End;
     end;

     //now disable clipping
     SelectClipRgn(ACanvas.Handle, 0);
end;

procedure TChart.SetShowVerticalReticule(Value:Boolean);
begin
   if FShowVerticalReticule then begin
      DrawVerticalReticule(Canvas,XVMarkOld);
      FShowVerticalReticule:=False;
   end;
   FShowVerticalReticule:=Value;
   Invalidate;
end;

procedure TChart.SetShowReticule(Value:Boolean);
begin
   if Value=False then
      DrawReticule(Canvas,XVMarkOld,YMarkOld);
FShowReticule:=Value;
Invalidate;
end;

procedure TChart.GetPointNextTo(X,Y:Integer;var SerieNumberOut,PointNumberOut,XOut,YOut:Integer);
var
   j,k,XPoint,YPoint,SerieNumber,PointNumber:Integer;
   Mini,Dist,Xg,Yg,XgOut,YgOut:Double;
   Serie:TComponent;
   TASerie:TSerie;
   T1,T2:Double;
begin
Mini:=MaxDouble;
for SerieNumber:=0 to Series.Count-1 do
   begin
   Serie:=Series[SerieNumber];
   if Serie is TSerie then
      begin
      TASerie:=TSerie(Serie);
      for PointNumber:=0 to TASerie.Count-1 do
         begin
         XPoint:=TASerie.GetXImgValue(PointNumber);
         YPoint:=TASerie.GetYImgValue(PointNumber);
         T1:=X-XPoint;
         T2:=Y-YPoint;
         Dist:=Sqrt(Sqr(T1)+Sqr(T2));
         if Dist<=Mini then
            begin
            Mini:=Dist;
            SerieNumberOut:=SerieNumber;
            PointNumberOut:=PointNumber;
            XOut:=XPoint;
            YOut:=YPoint;
            XgOut:=TASerie.GetXValue(PointNumber);
            YgOut:=TASerie.GetYValue(PointNumber);
            end;
         end;
      if SerieNumberOut=SerieNumber then DoDrawReticule(SerieNumberOut,PointNumberOut,XOut,YOut,XgOut,YgOut);
      end;
   end;
end;

procedure TChart.GetXPointNextTo(X,Y:Integer;var SerieNumberOut,PointNumberOut,XOut,YOut:Integer);
var
   j,k,XPoint,YPoint,SerieNumber,PointNumber:Integer;
   Mini,Dist,Xg,Yg:Double;
   Serie:TComponent;
   TASerie:TSerie;
begin
Mini:=MaxDouble;
SerieNumberOut:=-1;
for SerieNumber:=0 to Series.Count-1 do
   begin
   Serie:=Series[SerieNumber];
   if Serie is TSerie then
      begin
      TASerie:=TSerie(Serie);
      for PointNumber:=0 to TASerie.Count-1 do
         begin
         XPoint:=TASerie.GetXImgValue(PointNumber);
         Dist:=Abs(X-XPoint);
         if Dist<=Mini then
            begin
            Mini:=Dist;
            SerieNumberOut:=SerieNumber;
            PointNumberOut:=PointNumber;
            XOut:=XPoint;
            YOut:=TASerie.GetYImgValue(PointNumber);
            Xg:=TASerie.GetXValue(PointNumber);
            Yg:=TASerie.GetYValue(PointNumber);
            end;
         end;
      if SerieNumberOut=SerieNumber then DoDrawVertReticule(SerieNumberOut,PointNumberOut,XOut,YOut,Xg,Yg);
      end;
   end;
end;

procedure TChart.GetYPointNextTo(X,Y:Integer;var SerieNumberOut,PointNumberOut,XOut,YOut:Integer);
var
   j,k,XPoint,YPoint,SerieNumber,PointNumber:Integer;
   Mini,Dist,Xg,Yg:Double;
   Serie:TComponent;
   TASerie:TSerie;
begin
Mini:=MaxDouble;
for SerieNumber:=0 to Series.Count-1 do
   begin
   Serie:=Series[SerieNumber];
   if Serie is TSerie then
      begin
      TASerie:=TSerie(Serie);
      for PointNumber:=0 to TASerie.Count-1 do
         begin
         YPoint:=TASerie.GetYImgValue(PointNumber);
         Dist:=Abs(Y-YPoint);
         if Dist<=Mini then
            begin
            Mini:=Dist;
            SerieNumberOut:=SerieNumber;
            PointNumberOut:=PointNumber;
            XOut:=XPoint;
            YOut:=YPoint;
            end;
         end;
      end;
   end;
end;

procedure TChart.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
     if (X < XImageMax) and (X > XImageMin) and (Y < YImageMin) and (Y > YImageMax)
        and FAllowZoom  then begin
        Down:=True;
        XDown:=X;
        YDown:=Y;
        XOld:=X;
        YOld:=Y;
     end;
end;

procedure TChart.DrawReticule(ACanvas : TCanvas; X,Y:Integer);
begin
ACanvas.Pen.Style:=psSolid;
ACanvas.Pen.Mode:=pmXor;
ACanvas.Pen.Color:=ClWhite;
ACanvas.Pen.Style:=psSolid;
ACanvas.Pen.Width:=1;

ACanvas.MoveTo(X,YImageMin);
ACanvas.LineTo(X,YImageMax);
ACanvas.MoveTo(XImageMin,Y);
ACanvas.LineTo(XImageMax,Y);
end;

procedure TChart.DrawVerticalReticule(ACanvas : TCanvas; X:Integer);
begin
Canvas.Pen.Style:=psSolid;
Canvas.Pen.Mode:=pmXor;
Canvas.Pen.Color:=ClWhite;
Canvas.Pen.Style:=psSolid;
Canvas.Pen.Width:=1;

Canvas.MoveTo(X,YImageMin);
Canvas.LineTo(X,YImageMax);
end;

procedure TChart.MouseMove(Shift: TShiftState; X, Y: Integer);
var
   i,SerieNumber,PointNumber,XMin,Xmax,YMin,YMax,Temp:Integer;
   MySerie:TSerie;
begin
if Down then
   begin
   Canvas.Brush.Style:=bsClear;
   Canvas.Pen.Style:=psSolid;
   Canvas.Pen.Mode:=pmXor;
   Canvas.Pen.Color:=ClWhite;
   Canvas.Pen.Style:=psSolid;
   Canvas.Pen.Width:=1;

   Canvas.Rectangle(XDown,YDown,XOld,YOld);
   Canvas.Rectangle(XDown,YDown,X,Y);

   XOld:=X;
   YOld:=Y;
   end
else
   begin
   XMin:=XImageMin;
   XMax:=XImageMax;
   YMin:=YImageMin;
   YMax:=YImageMax;
   if XMin>XMax then
      begin
      Temp:=XMin;
      XMin:=XMax;
      XMax:=Temp;
      end;
   if YMin>YMax then
      begin
      Temp:=YMin;
      YMin:=YMax;
      YMax:=Temp;
      end;

   for i:=0 to SeriesCount-1 do
      begin
      MySerie:=Series[i];
      if FShowVerticalReticule then
         begin
         GetXPointNextTo(X,Y,SerieNumber,PointNumber,XReticule,YReticule);
         if (XReticule<>XVMarkOld) and (XReticule>XMin) and (XReticule<XMax) then
            begin
            DrawVerticalReticule(Canvas,XVMarkOld);
            DrawVerticalReticule(Canvas,XReticule);
            FShowVerticalReticule:=True;
            XVMarkOld:=XReticule;
            end;
         end;
      if FShowReticule then
         begin
         GetPointNextTo(X,Y,SerieNumber,PointNumber,XReticule,YReticule);
         if (XReticule<>XMarkOld) or (YReticule<>YMarkOld) then
            if (XReticule>=XMin) and (XReticule<=XMax) and (YReticule>=YMin) and (YReticule<=YMax) then
               begin
               DrawReticule(Canvas,XMarkOld,YMarkOld);
               DrawReticule(Canvas,XReticule,YReticule);
               FShowReticule:=True;
               XMarkOld:=XReticule;
               YMarkOld:=YReticule;
               end;
         end;
      end;
   end;
end;

procedure TChart.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
if Down then
   begin
   XMarkOld:=X;
   YMarkOld:=Y;

   Canvas.Brush.Style:=bsClear;
   Canvas.Pen.Style:=psSolid;
   Canvas.Pen.Mode:=pmXor;
   Canvas.Pen.Color:=ClWhite;
   Canvas.Pen.Style:=psSolid;
   Canvas.Pen.Width:=1;

   Canvas.Rectangle(XDown,YDown,XOld,YOld);

   Down:=False;
   if (XDown<XOld) and (YDown<YOld) then
      begin
      Zoom:=True;
      end
   else
      begin
      Zoom:=False;
      Fixed:=False;
      end;
   if XDown<XOld then
      begin
      ZoomRect.Left:=XDown;
      ZoomRect.Right:=XOld;
      end
   else
      begin
      ZoomRect.Left:=XOld;
      ZoomRect.Right:=XDown;
      end;
   if YDown<YOld then
      begin
      ZoomRect.Bottom:=YOld;
      ZoomRect.Top:=YDown;
      end
   else
      begin
      ZoomRect.Bottom:=YDown;
      ZoomRect.Top:=YOld;
      end;

   Invalidate;
   end;
end;

procedure TChart.DoDrawVertReticule(IndexSerie,Index,Xi,Yi:Integer;Xg,Yg:Double);
begin
if Assigned(FDrawVertReticule) then FDrawVertReticule(Self,IndexSerie,Index,Xi,Yi,Xg,Yg);
end;

procedure TChart.DoDrawReticule(IndexSerie,Index,Xi,Yi:Integer;Xg,Yg:Double);
begin
if Assigned(FDrawReticule) then FDrawReticule(Self,IndexSerie,Index,Xi,Yi,Xg,Yg);
end;

function TChart.GetNewColor:TColor;
var
   i,j:Integer;
   MySerie:TSerie;
   ColorFound:Boolean;
begin
for i:=1 to MaxColor do
   begin
   ColorFound:=False;
   for j:=0 to SeriesCount-1 do
      begin
      MySerie:=Series[j];
      if MySerie.GetColor(0)=Colors[i] then
         ColorFound:=True;
      end;
   if not ColorFound then
      begin
      Result:=Colors[i];
      Exit;
      end;
   end;
Randomize;
Result:=RGB(Random(255),Random(255),Random(255));
end;

function TChart.GetRectangle:TRect;
begin
     Result.Left := 0;
     Result.Top := 0;
     Result.Right := Width;
     Result.Bottom := Height;
end;

procedure TChart.SetLegend(Value:TChartLegend);
begin
  FLegend.Assign(Value);
  Invalidate;
end;

procedure TChart.SetLeftAxis(Value:TChartAxis);
begin
  FLeftAxis.Assign(Value);
  Invalidate;
end;

procedure TChart.SetBottomAxis(Value:TChartAxis);
begin
  FBottomAxis.Assign(Value);
  Invalidate;
end;

procedure TChart.SetFrame(Value: TChartPen);
begin
   FFrame.Assign(Value);
   Invalidate;
end;

procedure TChart.SetBackColor(Value: TColor);
begin
     FBackColor := Value;
     Invalidate;
end; 

procedure TChart.SetAxisVisible(Value: boolean);
begin
    FAxisVisible := Value;
    Invalidate;
end; 

function TChart.GetChartHeight: integer;
begin
   result := YImageMax - YImageMin;
end;

function TChart.GetChartWidth: integer;
begin
   result := XImageMax - XImageMin;
end; 

function TChart.GetSeriesCount: integer;
var i: integer;
begin
   {result := 0;
   for i := 0 to FSeries.count -1 do
      if TChartSeries(FSeries.Items[i]).Active then
         inc(Result);     }
   result := FSeries.count;
end;


//UTIL: should clean a bit eventually
//checks if only a pie chart is enabled
function TChart.only_pie: boolean;
var i, cpie, cother: integer;
begin
     cpie := 0; cother := 0;
     for i := 0 to FSeries.count -1  do begin
         if ( (TChartSeries(Series.Items[i])  is TPieSeries)) and
            TChartSeries(FSeries.Items[i]).Active then begin
            Inc( cpie );
         end;
         if ( not (TChartSeries(Series.Items[i])  is TPieSeries)) and
            TChartSeries(FSeries.Items[i]).Active then begin
            Inc( cother );
         end;
         //more than one so not only a pie, can exit loop
         if (cpie > 1) or (cother >= 1) then break;
     end;
     if (cpie = 1) and (cother = 0) then Result := True
     else Result := False;
end;

//get enabled pie chart
function TChart.get_pie: pointer;
var i: integer;
begin
     result := nil;
     for i := 0 to FSeries.count -1  do begin
         if ( (TChartSeries(Series.Items[i])  is TPieSeries)) and
            TChartSeries(FSeries.Items[i]).Active then begin
               result := TChartSeries(Series.Items[i]) ;
               break;
         end;
     end;
end; 

function TChart.SeriesInLegendCount: integer;
var i: integer;
begin
   Result := 0;
   for i:=0 to SeriesCount-1 do
      if TChartSeries(Series[i]).Active and
         TChartSeries(Series[i]).ShowInLegend then
	 Inc(Result);
end;

procedure TChart.ZoomFull;
Begin
  Zoom:=False;
  Fixed:=False;
  Invalidate;
End;


procedure Register;
begin
  RegisterComponents('Additional', [TChart]);
end;

{$IFDEF fpc}
initialization
  {$I tagraph.lrs}
{$ENDIF}


end.
