{%MainUnit ../forms.pp}

{
 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}

const
  IntfBarKind: array[TScrollBarKind] of Integer =
  (
    SB_HORZ,
    SB_VERT
  );

  TrackToPolicyMap: array[Boolean] of integer =
  (
   SB_POLICY_DISCONTINUOUS,
   SB_POLICY_CONTINUOUS
  );

procedure TControlScrollBar.SetPosition(const Value: Integer);
var
  MaxPos, PrevPosition: Integer;
  ScrollInfo: TScrollInfo;
begin
  if csLoading in FControl.ComponentState then
  begin
    FPosition := Value;
    Exit;
  end;

  if Value < 0 then
  begin
    SetPosition(0);
    exit;
  end;

  if GetAutoScroll then
  begin
    if Value > FAutoRange then
    begin
      {$IFDEF VerboseScrollingWinControl}
      if DebugCondition then
        DebugLn(['TControlScrollBar.SetPosition FAutoRange Value=',Value,' > AutoRange=',FAutoRange]);
      {$ENDIF}
      SetPosition(FAutoRange);
      exit;
    end;
  end;

  MaxPos := Range - Page;
  if (MaxPos >= 0) and (Value > MaxPos) then
  begin
    {$IFDEF VerboseScrollingWinControl}
    if DebugCondition then
      DebugLn(['TControlScrollBar.SetPosition Range Value=',Value,' > Range=',Range]);
    {$ENDIF}
    SetPosition(MaxPos);
    exit;
  end;

  {$IFDEF VerboseScrollingWinControl}
  if DebugCondition then
    DebugLn(['TControlScrollBar.SetPosition Value=',Value,' FPosition=',FPosition]);
  {$ENDIF}
  if Value = FPosition then
    exit;

  PrevPosition := FPosition;
  // position has to be set before FControl.ScrollBy !!!
  FPosition := Value;

  // scroll logical client area of FControl
  if Kind = sbVertical then
    FControl.ScrollBy(0, PrevPosition - FPosition)
  else
    FControl.ScrollBy(PrevPosition - FPosition, 0);

  // check that the new position is also set on the scrollbar
  if HandleAllocated and (GetScrollPos(ControlHandle, IntfBarKind[Kind]) <> FPosition) then
  begin
    InvalidateScrollInfo;
    {$IFDEF VerboseScrollingWinControl}
    if DebugCondition then
      DebugLn(['TControlScrollBar.SetPosition FPosition=',FPosition]);
    {$ENDIF}
    // send position to interface and store it back to FPosition (this way LCL will have actual position value)
    FillChar(ScrollInfo,SizeOf(ScrollInfo), 0);
    ScrollInfo.cbSize := SizeOf(ScrollInfo);
    ScrollInfo.fMask := SIF_POS;
    ScrollInfo.nPos := FPosition;

    FPosition := SetScrollInfo(ControlHandle, IntfBarKind[Kind], ScrollInfo, ScrollBarShouldBeVisible);
  end;
end;

function TControlScrollBar.GetIncrement: TScrollBarInc;
begin
  Result := FIncrement;
end;

function TControlScrollBar.GetPage: TScrollBarInc;
var
  ScrollInfo: TScrollInfo;
begin
  if HandleAllocated and (not (FControl is TScrollingWinControl)) then
  begin
    ScrollInfo.fMask := SIF_PAGE;
    GetScrollInfo(ControlHandle, IntfBarKind[Kind], ScrollInfo);
    if FPage<>ScrollInfo.nPage then
    begin
      FPage := ScrollInfo.nPage;
      InvalidateScrollInfo;
    end;
  end;
  Result := FPage;
end;

function TControlScrollBar.GetPosition: Integer;
var
  ScrollInfo: TScrollInfo;
begin
  if HandleAllocated and (not (FControl is TScrollingWinControl)) then
  begin
    ScrollInfo.fMask := SIF_POS;
    GetScrollInfo(ControlHandle, IntfBarKind[Kind], ScrollInfo);
    if FPosition <> ScrollInfo.nPos then
    begin
      FPosition := ScrollInfo.nPos;
      InvalidateScrollInfo;
    end;
  end;
  Result := FPosition;
end;

function TControlScrollBar.GetRange: Integer;
var
  ScrollInfo: TScrollInfo;
  NewRange: Integer;
begin
  if HandleAllocated and (not (FControl is TScrollingWinControl)) then
  begin
    ScrollInfo.fMask := SIF_Range + SIF_Page;
    GetScrollInfo(ControlHandle, IntfBarKind[Kind], ScrollInfo);
    NewRange := ScrollInfo.nMax - ScrollInfo.nMin;
    if NewRange <> FRange then
    begin
      FRange := NewRange;
      InvalidateScrollInfo;
    end;
  end;
  Result := FRange;
end;

function TControlScrollBar.GetSmooth: Boolean;
begin
  Result := FSmooth;
end;

procedure TControlScrollBar.SetIncrement(const AValue: TScrollBarInc);
begin
  // This value is only used by the ScrollHandler procedure
  FIncrement := AValue;
end;

procedure TControlScrollBar.SetPage(const AValue: TScrollBarInc);
begin
  if FPage = AValue then exit;
  FPage := AValue;
  ControlUpdateScrollBars;
end;

function TControlScrollBar.GetSize: integer;
var
  KindID: integer;
begin
  if Kind = sbHorizontal then
    KindID := SM_CYHSCROLL
  else
    KindID := SM_CXVSCROLL;
  if HandleAllocated then
    Result := LCLIntf.GetScrollBarSize(ControlHandle,KindID)
  else
    Result := GetSystemMetrics(KindID);
end;

procedure TControlScrollBar.SetRange(const AValue: Integer);
begin
  if not (csLoading in FControl.ComponentState) then
    if FControl is TScrollingWinControl then
      TScrollingWinControl(FControl).FAutoScroll := False;

  InternalSetRange(AValue);
end;

procedure TControlScrollBar.SetVisible(const AValue: Boolean);
begin
  if FVisible = AValue then
    Exit;
  FVisible := AValue;
  ControlUpdateScrollBars;
end;

procedure TControlScrollBar.SetSmooth(const AValue: Boolean);
begin
  // only used by the ScrollHandler procedure
  FSmooth := AValue;
end;

procedure TControlScrollBar.UpdateScrollBar;
var
  ScrollInfo: TScrollInfo;
  NewVisible: Boolean;
begin
  if HandleAllocated and (FControl is TScrollingWinControl) then
  begin
    FillChar(ScrollInfo, SizeOf(ScrollInfo), 0);
    ScrollInfo.cbSize := SizeOf(ScrollInfo);
    ScrollInfo.fMask := SIF_ALL;
    ScrollInfo.nMin := 0;
    ScrollInfo.nMax := FRange;
    ScrollInfo.nPos := FPosition;
    ScrollInfo.nPage := FPage;
    ScrollInfo.nTrackPos := FPosition;
    NewVisible := ScrollBarShouldBeVisible;
    if (not FOldScrollInfoValid) or (not CompareMem(@ScrollInfo, @FOldScrollInfo, SizeOf(TScrollInfo))) then
    begin
      FOldScrollInfo := ScrollInfo;
      SetScrollInfo(ControlHandle, IntfBarKind[Kind], ScrollInfo, NewVisible);
      // update policy too
      ScrollInfo.fMask := SIF_UPDATEPOLICY;
      ScrollInfo.nTrackPos := TrackToPolicyMap[FTracking];
      SetScrollInfo(ControlHandle, IntfBarKind[Kind], ScrollInfo, NewVisible);
      ShowScrollBar(ControlHandle, IntfBarKind[Kind], NewVisible);
    end
    else
    if (not FOldScrollInfoValid) or (FOldVisible <> NewVisible) then
      ShowScrollBar(ControlHandle, IntfBarKind[Kind], NewVisible);
    FOldVisible := NewVisible;
    FOldScrollInfoValid := True;
    {$IFDEF VerboseScrollingWinControl}
    //if DebugCondition then
      DebugLn(['TControlScrollBar.UpdateScrollBar ',DbgSName(FControl),' ',DbgSName(Self),' ',dbgs(Kind),' FVisible=',FVisible,' Range=',FRange,' FPosition=',FPosition,' FPage=',FPage,' FAutoRange=',FAutoRange,' ShouldVisible=',NewVisible,' IsVisible=',IsScrollBarVisible]);
    {$ENDIF}
  end;

  SetPosition(FPosition);

  if FControl is TScrollingWinControl then
  begin
    // I am not positive that this is right, but it appeared to be when I
    // compared results to Delphi 4
    if FSmooth then
      FIncrement := Max(low(FIncrement),FPage div 10);
  end;
end;

procedure TControlScrollBar.InvalidateScrollInfo;
begin
  FOldScrollInfoValid := False;
end;

{$ifdef VerboseScrollingWinControl}
function TControlScrollBar.DebugCondition: Boolean;
begin
  Result := (Kind = sbHorizontal);
end;
{$endif}

function TControlScrollBar.GetAutoScroll: boolean;
begin
  if FControl is TScrollingWinControl then
    Result := TScrollingWinControl(FControl).AutoScroll
  else
    Result := False;
end;

procedure TControlScrollBar.ScrollHandler(var Message: TLMScroll);
var
  NewPos: Longint;
begin
  if (csDesigning in FControl.ComponentState) then
    exit; //prevent wierdness in IDE.

  NewPos := FPosition;
  case Message.ScrollCode of
    SB_LINEUP:
      Dec(NewPos, FIncrement);
    SB_LINEDOWN:
      Inc(NewPos, FIncrement);
    SB_PAGEUP:
      Dec(NewPos, FPage);
    SB_PAGEDOWN:
      Inc(NewPos, FPage);
    SB_THUMBPOSITION:
      NewPos := Message.Pos;
    SB_THUMBTRACK:
      if Tracking then
        NewPos := Message.Pos;
    SB_TOP:
      NewPos := 0;
    SB_BOTTOM:
      NewPos := Range;
  else
    Exit;
  end;
  {$IFDEF VerboseScrollingWinControl}
  if DebugCondition then
    DebugLn(['TControlScrollBar.ScrollHandler Message.ScrollCode=',Message.ScrollCode,' FPosition=',FPosition,' NewPos=',NewPos,' Range=',Range]);
  {$ENDIF}
  if NewPos < 0 then
    NewPos := 0;
  if NewPos > FRange then
    NewPos := FRange;
  if NewPos<>FPosition then
  begin
    InvalidateScrollInfo;
    SetPosition(NewPos);
    Message.Result := 1;
  end;
end;

procedure TControlScrollBar.ControlUpdateScrollBars;
begin
  if ([csLoading, csDestroying] * FControl.ComponentState <> []) then
    Exit;
  if not HandleAllocated then
    Exit;
  if FControl is TScrollingWinControl then
    TScrollingWinControl(FControl).UpdateScrollBars;
end;

procedure TControlScrollBar.InternalSetRange(const AValue: Integer);
var
  NewRange: Integer;
begin
  NewRange := AValue;
  if NewRange < 0 then
    NewRange := 0;
  if FRange = NewRange then
    Exit;
  FRange := NewRange;
  {$IFDEF VerboseScrollingWinControl}
  //if DebugCondition then
    DebugLn(['TControlScrollBar.InternalSetRange ',dbgs(Kind),' ',Self,' FRange=',FRange]);
  {$ENDIF}
  ControlUpdateScrollBars;
end;

function TControlScrollBar.HandleAllocated: boolean;
begin
  Result := (FControl <> nil) and FControl.HandleAllocated;
end;

function TControlScrollBar.IsRangeStored: boolean;
begin
  Result := not GetAutoScroll;
end;

procedure TControlScrollBar.SetTracking(const AValue: Boolean);
var
  ScrollInfo: TScrollInfo;
begin
  if FTracking = AValue then Exit;
  FTracking := AValue;
  if not HandleAllocated then
    Exit;
  FillChar(ScrollInfo,SizeOf(ScrollInfo), 0);
  ScrollInfo.cbSize := SizeOf(ScrollInfo);
  ScrollInfo.fMask := SIF_UPDATEPOLICY;
  ScrollInfo.nTrackPos := TrackToPolicyMap[FTracking];
  SetScrollInfo(ControlHandle, IntfBarKind[Kind], ScrollInfo, ScrollBarShouldBeVisible);
end;

function TControlScrollBar.ControlHandle: HWnd;
begin
  Result := FControl.Handle;
end;

function TControlScrollBar.ControlSize: integer;
begin
  if Kind = sbVertical then
    Result := FControl.Width
  else
    Result := FControl.Height;
end;

constructor TControlScrollBar.Create(AControl: TWinControl;
  AKind: TScrollBarKind);
begin
  inherited Create;
  FControl := AControl;
  FKind := AKind;
  FPage := 80;
  FIncrement := 8;
  FPosition := 0;
  FRange := 0;
  FSmooth := False;
  FTracking := False;
  FVisible := True;
end;

procedure TControlScrollBar.Assign(Source: TPersistent);
begin
  if Source is TControlScrollBar then
  begin
    with Source as TControlScrollBar do
    begin
      Self.Increment := Increment;
      Self.Position := Position;
      Self.Range := Range;
      Self.Visible := Visible;
      Self.Smooth := Smooth;
      // page and size depend on FControl, so no need to copy them
    end;
  end
  else
    inherited Assign(Source);
end;

function TControlScrollBar.IsScrollBarVisible: Boolean;
begin
  Result := FVisible;
  if HandleAllocated then
    Result := GetScrollbarVisible(ControlHandle, IntfBarKind[Kind]);
end;

function TControlScrollBar.ScrollPos: Integer;
begin
  if Visible then
    Result := Position
  else
    Result := 0;
end;

function TControlScrollBar.GetOtherScrollBar: TControlScrollBar;
begin
  if Kind = sbVertical then
    Result := GetHorzScrollBar
  else
    Result := GetVertSCrollbar;
end;

function TControlScrollBar.ClientSize: integer;
begin
  if Kind = sbVertical then
    Result := FControl.ClientWidth
  else
    Result := FControl.ClientHeight;
end;

function TControlScrollBar.ClientSizeWithBar: integer;
begin
  Result := ClientSize;
  if not IsScrollBarVisible then
    Result := Max(0,Result-GetSize-GetSystemMetrics(SM_SWSCROLLBARSPACING));
end;

function TControlScrollBar.ClientSizeWithoutBar: integer;
begin
  Result:=ClientSize;
  if IsScrollBarVisible then
    Result := Min(ControlSize, Result+GetSize+GetSystemMetrics(SM_SWSCROLLBARSPACING));
end;

function TControlScrollBar.GetHorzScrollBar: TControlScrollBar;
begin
  if FControl is TScrollingWinControl then
    Result := TScrollingWinControl(FControl).HorzScrollBar
  else
    Result := nil;
end;

function TControlScrollBar.GetVertScrollBar: TControlScrollBar;
begin
  if FControl is TScrollingWinControl then
    Result := TScrollingWinControl(FControl).VertScrollBar
  else
    Result := nil;
end;

function TControlScrollBar.ScrollBarShouldBeVisible: Boolean;
begin
  Result := FVisible and (FRange > FPage);
end;

// included by forms.pp
