
{*****************************************}
{                                         }
{             FastReport v2.3             }
{             Report dataset              }
{                                         }
{  Copyright (c) 1998-99 by Tzyganenko A. }
{                                         }
{*****************************************}

unit LR_DSet;

interface

{$I LR_Vers.inc}

uses
  SysUtils, Classes;

type
  TRangeBegin = (rbFirst, rbCurrent);
  TRangeEnd = (reLast, reCurrent, reCount);
  TCheckEOFEvent = procedure(Sender: TObject; var Eof: Boolean) of object;

  { TfrDataset }

  TfrDataset = class(TComponent)
  protected
    FRangeBegin: TRangeBegin;
    FRangeEnd: TRangeEnd;
    FRangeEndCount: Integer;
    FOnFirst, FOnNext, FOnLast: TNotifyEvent;
    FOnCheckEOF: TCheckEOFEvent;
    FRecNo: Integer;
    procedure DoCheckEOF(var Eof: Boolean); virtual;
    procedure DoFirst; virtual;
    procedure DoNext; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Init; virtual;
    procedure Exit; virtual;
    procedure First; virtual;
    procedure Next; virtual;
    procedure Refresh; virtual;

    function GetBookMark : Pointer; virtual;
    procedure GotoBookMark({%H-}BM : Pointer); virtual;
    procedure FreeBookMark({%H-}BM : Pointer); virtual;
    procedure DisableControls; virtual;
    procedure EnableControls; virtual;
    
    function Eof: Boolean; virtual;
    property RangeBegin: TRangeBegin read FRangeBegin write FRangeBegin default rbFirst;
    property RangeEnd: TRangeEnd read FRangeEnd write FRangeEnd default reLast;
    property RangeEndCount: Integer read FRangeEndCount write FRangeEndCount default 0;
    property RecNo: Integer read FRecNo;
    property OnCheckEOF: TCheckEOFEvent read FOnCheckEOF write FOnCheckEOF;
    property OnFirst: TNotifyEvent read FOnFirst write FOnFirst;
    property OnNext: TNotifyEvent read FOnNext write FOnNext;
  end;

  TfrUserDataset = class(TfrDataset)
  published
    property RangeBegin;
    property RangeEnd;
    property RangeEndCount;
    property OnCheckEOF;
    property OnFirst;
    property OnNext;
  end;

implementation

procedure TfrDataset.DoCheckEOF(var Eof: Boolean);
begin
  if Assigned(FOnCheckEOF) then
     FOnCheckEOF(Self, Eof);
end;

procedure TfrDataset.DoFirst;
begin
  if Assigned(FOnFirst) then
    FOnFirst(Self);
end;

procedure TfrDataset.DoNext;
begin
  if Assigned(FOnNext) then
    FOnNext(Self);
end;

constructor TfrDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  RangeBegin := rbFirst;
  RangeEnd := reLast;
end;

procedure TfrDataSet.Init;
begin
end;

procedure TfrDataSet.Exit;
begin
end;

procedure TfrDataSet.First;
begin
  FRecNo := 0;
  DoFirst;
end;

procedure TfrDataSet.Next;
begin
  Inc(FRecNo);
  DoNext;
end;

procedure TfrDataset.Refresh;
begin
end;

function TfrDataset.GetBookMark: Pointer;
begin
  Result:=nil;
end;

procedure TfrDataset.GotoBookMark(BM: Pointer);
begin

end;

procedure TfrDataset.FreeBookMark(BM: Pointer);
begin

end;

procedure TfrDataset.DisableControls;
begin

end;

procedure TfrDataset.EnableControls;
begin

end;

function TfrDataSet.Eof: Boolean;
begin
  Result := False;
  if (FRangeEnd = reCount) and (FRecNo >= FRangeEndCount) then
    Result := True;
  DoCheckEOF(Result);
end;


end.
