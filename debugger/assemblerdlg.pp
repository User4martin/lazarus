unit AssemblerDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  ComCtrls, StdCtrls, Grids, ExtCtrls, LclType, LCLIntf, DebuggerDlg, Debugger,
  EditorOptions, Maps, Math, LCLProc, Menus, Clipbrd, ActnList,
  IDECommands, IDEImagesIntf;

type

  { TAssemblerDlg }

  TAsmDlgLineMapState = (
    lmsUnknown,
    lmsInvalid,    // debugger couldn't disassemble this address
    lmsStatement,  // display line as assembler
    lmsSource,     // display line as source
    lmsFuncName    // Name of function
  );

  TAsmDlgLineEntry = record
    State: TAsmDlgLineMapState;
    Addr: TDbgPtr;
    Dump: String;
    Statement: String;
    FileName: String;
    SourceLine: Integer;
  end;
  TAsmDlgLineEntries = Array of TAsmDlgLineEntry;

  TAssemblerDlg = class(TDebuggerDlg)
    actCurrentInstr: TAction;
    actGotoAddr: TAction;
    actCopy: TAction;
    actStepOverInstr: TAction;
    actStepIntoInstr: TAction;
    ActionList1: TActionList;
    CopyToClipboard: TMenuItem;
    EditGotoAddr: TEdit;
    ImageList1: TImageList;
    pnlToolAddr: TPanel;
    pbAsm: TPaintBox;
    PopupMenu1: TPopupMenu;
    sbHorizontal: TScrollBar;
    sbVertical: TScrollBar;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButtonCopy: TToolButton;
    ToolButtonGoto: TToolButton;
    ToolButtonGotoCurrent: TToolButton;
    ToolButtonStepOverInstr: TToolButton;
    ToolButtonStepIntoInstr: TToolButton;
    ToolButton4: TToolButton;
    ToolButtonPower: TToolButton;
    ToolButton2: TToolButton;
    procedure actCurrentInstrExecute(Sender: TObject);
    procedure actGotoAddrExecute(Sender: TObject);
    procedure actStepIntoInstrExecute(Sender: TObject);
    procedure actStepOverInstrExecute(Sender: TObject);
    procedure CopyToClipboardClick(Sender: TObject);
    procedure EditGotoAddrChange(Sender: TObject);
    procedure EditGotoAddrKeyPress(Sender: TObject; var Key: char);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormResize(Sender: TObject);
    procedure pbAsmMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure pbAsmMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure pbAsmMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,
      Y: Integer);
    procedure pbAsmMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure pbAsmPaint(Sender: TObject);
    procedure sbHorizontalChange(Sender: TObject);
    procedure sbVerticalChange(Sender: TObject);
    procedure sbVerticalScroll(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);
    procedure ToolButtonPowerClick(Sender: TObject);
  private
    FDebugger: TDebugger;
    FDisassembler: TIDEDisassembler;
    FDisassemblerNotification: TIDEDisassemblerNotification;
    FCurrentLocation, FLocation: TDBGPtr;
    FMouseIsDown: Boolean;

    FTopLine: Integer;
    FLastTopLine: Integer;
    FLastTopLineIdx: Integer;
    FLastTopLineIsSrc: Boolean; // The Source In Fron of Idx
    FLastTopLineValid: Boolean;

    FSelectLine: Integer;
    FSelectionEndLine: Integer;
    FLineCount: Integer;
    FLineMap: TAsmDlgLineEntries;

    FLineHeight: Integer;
    FCharWidth: Integer;
    FGutterWidth: Integer;
    FUpdating: Boolean;
    FUpdateNeeded: Boolean;

    FPowerImgIdx, FPowerImgIdxGrey: Integer;
    FCurLineImgIdx: Integer;

    procedure DoDebuggerDestroyed(Sender: TObject);
    procedure ClearLineMap(AState: TAsmDlgLineMapState = lmsUnknown);
    procedure DisassemblerChanged(Sender: TObject);
    procedure SetDisassembler(const AValue: TIDEDisassembler);
    procedure SetDebugger(const AValue: TDebugger);
    function FormatLine(ALine: TAsmDlgLineEntry; W: Integer): String;
    procedure UpdateView;
    procedure UpdateActionEnabled;
    procedure UpdateLineData;
    procedure UpdateLineDataEx(ALineMap: TAsmDlgLineEntries;
                               AFirstLine, ALineCount: Integer;
                               var ACachedLine, ACachedIdx: Integer;
                               var ACachedIsSrc, ACachedValid: Boolean;
                               ACachedUpdate: Boolean;
                               ANoExtraHeader: Boolean = False
                              );
    procedure SetSelection(ALine: Integer; AMakeVisible: Boolean; AKeepSelEnd: Boolean = False);
    procedure SetLineCount(ALineCount: Integer);
    procedure SetTopLine(ALine: Integer);
    function  IndexOfAddr(const AAddr: TDBGPtr): Integer;
    procedure UpdateLocation(const AAddr: TDBGPtr);
  protected
    procedure InitializeWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure SetLocation(ADebugger: TDebugger; const AAddr: TDBGPtr);
    property Disassembler: TIDEDisassembler read FDisassembler write SetDisassembler;
  end;

implementation

{$R *.lfm}

uses
  LazarusIDEStrConsts;

{ TAssemblerDlg }

procedure TAssemblerDlg.ClearLineMap(AState: TAsmDlgLineMapState = lmsUnknown);
var
  n: Integer;
begin
  FLastTopLineValid := False;
  for n := Low(FLineMap) to High(FLineMap) do
  begin
    FLineMap[n].State := AState;
    FLineMap[n].Dump := '';
    FLineMap[n].Statement := '';
    if AState = lmsUnknown
    then FLineMap[n].Addr := 0;
  end;
end;

procedure TAssemblerDlg.SetDisassembler(const AValue: TIDEDisassembler);
begin
  if FDisassembler = AValue then exit;
  BeginUpdate;
  try
    if FDisassembler <> nil
    then begin
      FDisassembler.RemoveNotification(FDisassemblerNotification);
    end;

    FDisassembler := AValue;

    if FDisassembler <> nil
    then begin
      FDisassembler.AddNotification(FDisassemblerNotification);
    end;

    DisassemblerChanged(FDisassembler);
  finally
    EndUpdate;
  end;
  UpdateActionEnabled;
end;

procedure TAssemblerDlg.SetDebugger(const AValue: TDebugger);
begin
  if FDebugger = AValue
  then exit;

  if FDebugger <> nil
  then FDebugger.RemoveNotifyEvent(dnrDestroy, @DoDebuggerDestroyed);
  FDebugger := AValue;
  if FDebugger <> nil
  then FDebugger.AddNotifyEvent(dnrDestroy, @DoDebuggerDestroyed);
  UpdateActionEnabled;
end;

constructor TAssemblerDlg.Create(AOwner: TComponent);
begin
  FCurrentLocation := 0;
  FLocation := 0;
  FLineCount := 0;
  SetLength(FLineMap, FLineCount + 1);
  FGutterWidth := 32;
  FDisassemblerNotification := TIDEDisassemblerNotification.Create;
  FDisassemblerNotification.AddReference;
  FDisassemblerNotification.OnChange  := @DisassemblerChanged;

  inherited Create(AOwner);
//  DoubleBuffered := True;

  Caption := lisDisAssAssembler;

  pbAsm.Font.Height := EditorOpts.EditorFontHeight;
  pbAsm.Font.Name := EditorOpts.EditorFont;
  Caption := lisMenuViewAssembler;
  CopyToClipboard.Caption := lisDbgAsmCopyToClipboard;


  ToolBar1.Images := IDEImages.Images_16;
  PopupMenu1.Images := IDEImages.Images_16;

  actStepOverInstr.Caption := lisMenuStepOverInstr;
  actStepOverInstr.Hint := lisMenuStepOverInstrHint;
  actStepOverInstr.ImageIndex := IDEImages.LoadImage(16, 'menu_stepover_instr');

  actStepIntoInstr.Caption := lisMenuStepIntoInstr;
  actStepIntoInstr.Hint := lisMenuStepIntoInstrHint;
  actStepIntoInstr.ImageIndex := IDEImages.LoadImage(16, 'menu_stepinto_instr');

  actCurrentInstr.Caption := lisDisAssGotoCurrentAddress;
  actCurrentInstr.Hint := lisDisAssGotoCurrentAddressHint;
  actCurrentInstr.ImageIndex := IDEImages.LoadImage(16, 'debugger_current_line');

  actGotoAddr.Caption := lisDisAssGotoAddress;
  actGotoAddr.Hint := lisDisAssGotoAddressHint;
  actGotoAddr.ImageIndex := IDEImages.LoadImage(16, 'callstack_show');

  actCopy.Caption := lisMenuCopy;
  actCopy.Hint := lisMenuCopy;
  actCopy.ImageIndex := IDEImages.LoadImage(16, 'laz_copy');


  FPowerImgIdx := IDEImages.LoadImage(16, 'debugger_power');
  FPowerImgIdxGrey := IDEImages.LoadImage(16, 'debugger_power_grey');
  ToolButtonPower.ImageIndex := FPowerImgIdx;

  FCurLineImgIdx := IDEImages.LoadImage(16, 'debugger_current_line');
end;

destructor TAssemblerDlg.Destroy;
begin
  SetDisassembler(nil);
  SetDebugger(nil);
  FDisassemblerNotification.OnChange := nil;
  FDisassemblerNotification.ReleaseReference;
  inherited Destroy;
end;

procedure TAssemblerDlg.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  i: LongInt;
begin
  if (Shift - [ssShift] <> []) then begin
    inherited;
    Exit;
  end;
  case Key of
    VK_UP:   begin
      ToolButtonPower.Down := True;
      ToolButtonPowerClick(nil);
      SetSelection(FSelectLine - 1, True, ssShift in Shift);
      Key := 0;
    end;
    VK_DOWN: begin
      ToolButtonPower.Down := True;
      ToolButtonPowerClick(nil);
      SetSelection(FSelectLine + 1, True, ssShift in Shift);
      Key := 0;
    end;
    VK_PRIOR: begin
      ToolButtonPower.Down := True;
      ToolButtonPowerClick(nil);
      i := FTopLine;
      SetSelection(FSelectLine - FLineCount, False, ssShift in Shift);
      SetTopline(i - FLineCount);
      Key := 0;
    end;
    VK_NEXT: begin
      ToolButtonPower.Down := True;
      ToolButtonPowerClick(nil);
      i := FTopLine;
      SetSelection(FSelectLine + FLineCount, False, ssShift in Shift);
      SetTopline(i + FLineCount);
      Key := 0;
    end;
    VK_LEFT: begin
      if not EditGotoAddr.Focused then begin
        sbHorizontal.Position := sbHorizontal.Position - sbHorizontal.SmallChange;
        Key := 0;
      end;
    end;
    VK_RIGHT: begin
      if not EditGotoAddr.Focused then begin
        sbHorizontal.Position := sbHorizontal.Position + sbHorizontal.SmallChange;
        Key := 0;
      end;
    end;
    VK_HOME: begin
      if not EditGotoAddr.Focused then begin
        sbHorizontal.Position := 0;
        Key := 0;
      end;
    end;
    else
      inherited;
  end;
  pbAsm.Invalidate;
end;

procedure TAssemblerDlg.CopyToClipboardClick(Sender: TObject);
var
  ALineMap: TAsmDlgLineEntries;
  i, w: Integer;
  s: String;
begin
  SetLength(ALineMap, abs(FSelectionEndLine - FSelectLine)+1);
  UpdateLineDataEx(ALineMap, Min(FSelectionEndLine, FSelectLine),
    abs(FSelectionEndLine - FSelectLine)+1,
    FLastTopLine, FLastTopLineIdx, FLastTopLineIsSrc, FLastTopLineValid, False, True);
  if FDebugger = nil
  then W := 16
  else W := FDebugger.TargetWidth div 4;
  s := '';
  for i := 0 to length(ALineMap)-1 do
  begin
    s := s + FormatLine(ALineMap[i], W) + LineEnding;
  end;
  Clipboard.AsText := s;
end;

procedure TAssemblerDlg.EditGotoAddrChange(Sender: TObject);
var
  HasDisassembler: Boolean;
begin
  HasDisassembler := (FDebugger <> nil) and (FDisassembler <> nil);
  actGotoAddr.Enabled := HasDisassembler and (StrToQWordDef(EditGotoAddr.Text, 0) <> 0);
end;

procedure TAssemblerDlg.EditGotoAddrKeyPress(Sender: TObject; var Key: char);
begin
  if (key = #13) and (StrToQWordDef(EditGotoAddr.Text, 0) <> 0)
  then actGotoAddr.Execute;
end;

procedure TAssemblerDlg.actStepOverInstrExecute(Sender: TObject);
var
  Handled: Boolean;
begin
  if Assigned(OnProcessCommand)
  then OnProcessCommand(Self, ecStepOverInstr, Handled);
end;

procedure TAssemblerDlg.actStepIntoInstrExecute(Sender: TObject);
var
  Handled: Boolean;
begin
  if Assigned(OnProcessCommand)
  then OnProcessCommand(Self, ecStepIntoInstr, Handled);
end;

procedure TAssemblerDlg.actCurrentInstrExecute(Sender: TObject);
begin
  if FDisassembler.BaseAddr <> FLocation
  then begin
    ToolButtonPower.Down := True;
    ToolButtonPowerClick(nil);
  end;
  UpdateLocation(FLocation);
end;

procedure TAssemblerDlg.actGotoAddrExecute(Sender: TObject);
var
  Addr: TDBGPtr;
begin
  ToolButtonPower.Down := True;
  ToolButtonPowerClick(nil);
  Addr := StrToQWordDef(EditGotoAddr.Text, 0);
  if Addr <> 0
  then UpdateLocation(Addr);
end;

procedure TAssemblerDlg.DisassemblerChanged(Sender: TObject);
begin
  if (FDisassembler = nil) or (FCurrentLocation = 0) or (FLineCount = 0)
  then exit;
  if (FDebugger <> nil) and (FDebugger.State <> dsPause)
  then begin
    // only for F9, not for F8,F7 single stepping with assembler is no good, if it clears all the time
    //ClearLineMap;
    FCurrentLocation := 0;
    FLocation := 0;
  end
  else begin
    UpdateView;
  end;
  pbAsm.Invalidate;
end;

procedure TAssemblerDlg.FormResize(Sender: TObject);
begin
  sbHorizontal.PageSize    := pbAsm.Width;
  sbHorizontal.LargeChange := pbAsm.Width div 3;

  if FLineHeight <> 0
  then SetLineCount(pbAsm.Height div FLineHeight);
end;

procedure TAssemblerDlg.InitializeWnd;
var
  TM: TTextMetric;
begin
  inherited InitializeWnd;

  GetTextMetrics(pbAsm.Canvas.Handle, TM);
  FCharWidth := EditorOpts.ExtraCharSpacing + TM.tmMaxCharWidth;
  sbHorizontal.SmallChange := FCHarWidth;

  FLineHeight := EditorOpts.ExtraLineSpacing + TM.tmHeight;
  SetLineCount(pbAsm.Height div FLineHeight);
end;

procedure TAssemblerDlg.pbAsmMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then exit;

  SetSelection(FTopLine + Y div FLineHeight, False, ssShift in Shift);
  FMouseIsDown := True;
end;

procedure TAssemblerDlg.pbAsmMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  y := Y div FLineHeight;
  if FMouseIsDown and (y >= 0) and (y < FLineCount)
  then SetSelection(FTopLine + Y, False, True);
end;

procedure TAssemblerDlg.pbAsmMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FMouseIsDown := False;
end;

procedure TAssemblerDlg.pbAsmMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  i, j: LongInt;
begin
  if not ToolButtonPower.Down then exit;
  Handled := True;

  j := WheelDelta div 120;
  i := FTopLine ;
  if FSelectLine <> MaxInt
  then SetSelection(FSelectLine - j, False, ssShift in Shift);
  SetTopline(i - j);
end;

procedure TAssemblerDlg.pbAsmPaint(Sender: TObject);
var
  R: TRect;
  n, X, Y, Line, W: Integer;
  S: String;
begin

  R := pbAsm.ClientRect;
//  pbAsm.Canvas.Brush.Color := clWindow;
  pbAsm.Canvas.FillRect(R);
  Inc(R.Left, FGutterWidth);

  X := FGutterWidth - sbHorizontal.Position;
  Y := 0;
  Line := FTopLine;

  if FDebugger = nil
  then W := 16
  else W := FDebugger.TargetWidth div 4;

  for n := 0 to FLineCount do
  begin
    if Line = FSelectLine
    then begin
      pbAsm.Canvas.Brush.Color := clHighlight;
      pbAsm.Canvas.Font.Color := clHighlightText;
      pbAsm.Canvas.FillRect(R.Left, n * FLineHeight, R.Right, (n + 1) * FLineHeight);
      if (FSelectionEndLine <> FSelectLine)
      then begin
        pbAsm.Canvas.Brush.Color := clHotLight;
        pbAsm.Canvas.Brush.Style := bsClear;
        pbAsm.Canvas.Rectangle(R.Left, n * FLineHeight, R.Right, (n + 1) * FLineHeight);
        pbAsm.Canvas.Brush.Style := bsSolid;
        pbAsm.Canvas.Brush.Color := clHighlight;
      end;
    end
    else if (FSelectionEndLine <> FSelectLine)
    and (line >= Min(FSelectLine, FSelectionEndLine))
    and (line <= Max(FSelectLine, FSelectionEndLine))
    then begin
      pbAsm.Canvas.Brush.Color := clHighlight;
      pbAsm.Canvas.Font.Color := clHighlightText;
      pbAsm.Canvas.FillRect(R.Left, n * FLineHeight, R.Right, (n + 1) * FLineHeight);
    end
    else begin
      pbAsm.Canvas.Brush.Color := pbAsm.Color;
      pbAsm.Canvas.Font.Color := pbAsm.Font.Color;
    end;
    pbAsm.Canvas.Font.Bold := (FLineMap[n].State in [lmsSource, lmsFuncName]);

    if (FLineMap[n].State = lmsStatement) and (FLineMap[n].Addr = FLocation)
    then IDEImages.Images_16.Draw(pbAsm.Canvas, FGutterWidth - 16, Y, FCurLineImgIdx, True);

    S := FormatLine(FLineMap[n], W);
    pbAsm.Canvas.TextRect(R, X, Y, S);

    Inc(Y, FLineHeight);
    Inc(Line);
  end;
end;

function TAssemblerDlg.FormatLine(ALine: TAsmDlgLineEntry; W: Integer) : String;
begin
  Result := '';
  //Result :=  Format('[a:%8.8u l:%8.8d i:%3.3u] ', [Cardinal(ALine.Addr), Line, n]);
  Result := Result + HexStr(ALine.Addr, W) + ' ';

  case ALine.State of
    lmsUnknown: Result := Result + '??????';
    lmsInvalid: Result := Result + '......';
    lmsStatement: Result := Result + Copy(ALine.Dump + '                         ', 1, 24) + ' ' + ALine.Statement;
    lmsSource: begin
      if ALine.SourceLine = 0
      then Result := '---'
      else Result :=  Format('%s:%u %s', [ALine.FileName, ALine.SourceLine, ALine.Statement]);
    end;
    lmsFuncName: Result:= ALine.FileName + ' ' + ALine.Statement;
  end;
end;

procedure TAssemblerDlg.UpdateView;
begin
  if not ToolButtonPower.Down
  then exit;

  if (FDisassembler <> nil) and (FCurrentLocation <> 0)
  then begin
    FDisassembler.PrepareRange(FCurrentLocation, Max(0, -(FTopLine - 5)), Max(0, FTopLine + FLineCount + 1 + 5));
    UpdateLineData;
  end
  else ClearLineMap;
  pbAsm.Invalidate;
end;

procedure TAssemblerDlg.UpdateActionEnabled;
var
  HasDisassembler: Boolean;
begin
  HasDisassembler := (FDebugger <> nil) and (FDisassembler <> nil);
  actCurrentInstr.Enabled := HasDisassembler and (FLocation <> 0);
  actGotoAddr.Enabled := HasDisassembler and (StrToQWordDef(EditGotoAddr.Text, 0) <> 0);
  actCopy.Enabled := HasDisassembler;
  actStepOverInstr.Enabled := HasDisassembler;
  actStepIntoInstr.Enabled := HasDisassembler;
end;

procedure TAssemblerDlg.sbHorizontalChange(Sender: TObject);
begin
  pbAsm.Invalidate;
end;

procedure TAssemblerDlg.sbVerticalChange(Sender: TObject);
begin
  ToolButtonPower.Down := True;
  ToolButtonPowerClick(nil);
  sbVertical.Position := 475;
  pbAsm.Invalidate;
end;

procedure TAssemblerDlg.sbVerticalScroll(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
  case ScrollCode of
    scLineUp: begin
      SetTopline(FTopLine - 1);
    end;
    scLineDown: begin
      SetTopline(FTopLine + 1);
    end;
    scPageUp: begin
      SetTopline(FTopLine - FLineCount);
    end;
    scPageDown: begin
      SetTopline(FTopLine + FLineCount);
    end;
    scPosition: begin
      // doesn't work on gtk
    end;
    scTrack: begin
      // --- remove when scPosition works
      ScrollPos := 475;
      Exit;
      // ---

      if ScrollPos = 475 then Exit;
      if ScrollPos < 475
      then SetTopline(FTopLine - 1)
      else SetTopline(FTopLine + 1);
    end;
//    scTop,      // = SB_TOP
//    scBottom,   // = SB_BOTTOM
//    scEndScroll // = SB_ENDSCROLL
  end;
end;

procedure TAssemblerDlg.ToolButtonPowerClick(Sender: TObject);
begin
  if ToolButtonPower.Down
  then begin
    ToolButtonPower.ImageIndex := FPowerImgIdx;
    UpdateView;
  end
  else ToolButtonPower.ImageIndex := FPowerImgIdxGrey;
end;

procedure TAssemblerDlg.DoDebuggerDestroyed(Sender: TObject);
begin
  FDebugger := nil;
  FDisassembler := nil;
  UpdateView;
end;

function TAssemblerDlg.IndexOfAddr(const AAddr: TDBGPtr): Integer;
begin
  Result := length(FLineMap) - 1;
  while Result >= 0  do begin
    if (FLineMap[Result].State = lmsStatement) and (FLineMap[Result].Addr = FCurrentLocation)
    then exit;
    dec(Result);
  end;
end;

procedure TAssemblerDlg.UpdateLocation(const AAddr: TDBGPtr);
var
  i: Integer;
begin
  if FCurrentLocation <> AAddr
  then begin
    FCurrentLocation := AAddr;
    FLastTopLineValid := False;
  end;

  i := IndexOfAddr(FCurrentLocation);
  if (i >= 0) and (i < FLineCount - 1)
  then begin
    FSelectLine := FTopLine + i;
  end
  else begin
    FTopLine := -(FLineCount div 2);
    FSelectLine := 0;
  end;
  FSelectionEndLine := FSelectLine;
  UpdateActionEnabled;
  UpdateView;
end;

procedure TAssemblerDlg.SetLocation(ADebugger: TDebugger; const AAddr: TDBGPtr);
var
  i: Integer;
begin
  SetDebugger(ADebugger);

  FCurrentLocation := AAddr;
  FLocation := AAddr;
  FLastTopLineValid := False;

  if not ToolButtonPower.Down
  then begin
    i := IndexOfAddr(FCurrentLocation);
    if (i >= 0)
    then FSelectLine := FTopLine + i
    else FSelectLine := MaxInt;
    FSelectionEndLine := FSelectLine;

    pbAsm.Invalidate;
    exit;
  end;

  FTopLine := -(FLineCount div 2);
  FSelectLine := 0;
  FSelectionEndLine := 0;

  UpdateActionEnabled;
  if Visible then // otherwhise in resize
    UpdateView
  else
    ClearLineMap;
end;

procedure TAssemblerDlg.SetSelection(ALine: Integer; AMakeVisible: Boolean;
  AKeepSelEnd: Boolean = False);
var
  OldLine: Integer;
begin
  if Aline = FSelectLine then Exit;

  // UpdateLineData may cause eventhandling, so we enter here again
  // set variable first
  OldLine := FSelectLine;
  FSelectLine := Aline;

  if not AKeepSelEnd
  then FSelectionEndLine := FSelectLine;

  if AMakeVisible
  then begin
    if FSelectLine < OldLine
    then begin
      if FTopLine > FSelectLine
      then SetTopLine(FSelectLine);
    end
    else begin
      if FTopLine + FLineCount <= FSelectLine
      then SetTopLine(FSelectLine - FLineCount + 1);
    end;
  end;

  pbAsm.Invalidate;
end;

procedure TAssemblerDlg.SetLineCount(ALineCount: Integer);
begin
  if FLineCount = ALineCount
  then exit;
  FLineCount := ALineCount;
  SetLength(FLineMap, FLineCount + 1);
  UpdateView;
end;

procedure TAssemblerDlg.SetTopLine(ALine: Integer);
var
  PadFront, PadEnd: Integer;
begin
  if not ToolButtonPower.Down
  then exit;

  if FTopLine = ALine then Exit;
  // scrolled by user, get more padding lines
  PadFront := 5;
  PadEnd := 5;
  if ALine < FTopLine
  then PadFront := 20
  else PadEnd := 20;
  FTopLine := ALine;
  if (FDisassembler <> nil)
  and ( (FDisassembler.CountBefore < Max(0, -(FTopLine - 1)))
     or (FDisassembler.CountAfter < Max(0, FTopLine + FLineCount + 2)) )
  then FDisassembler.PrepareRange(FCurrentLocation, Max(0, -(FTopLine - PadFront)), Max(0, FTopLine + FLineCount + 1 + PadEnd));
  UpdateLineData;
end;

procedure TAssemblerDlg.UpdateLineData;
begin
  UpdateLineDataEx(FLineMap, FTopLine, FLineCount + 1,
    FLastTopLine, FLastTopLineIdx, FLastTopLineIsSrc, FLastTopLineValid, True);
end;

procedure TAssemblerDlg.UpdateLineDataEx(ALineMap: TAsmDlgLineEntries; AFirstLine,
  ALineCount: Integer; var ACachedLine, ACachedIdx: Integer;
  var ACachedIsSrc, ACachedValid: Boolean; ACachedUpdate: Boolean;
  ANoExtraHeader: Boolean = False);

  function GetItem(AIdx: Integer): PDisassemblerEntry;
  begin
    Result := nil;
    if (AIdx >= -FDisassembler.CountBefore) and (AIdx < FDisassembler.CountAfter)
    then Result := FDisassembler.EntriesPtr[AIdx];
  end;

  function IsSourceBeforeItem(AItm: PDisassemblerEntry;
    APrvItm: PDisassemblerEntry): Boolean;
  begin
    if AItm = nil
    then exit(False);

    if AItm^.SrcFileName <> '' then begin
      Result := AItm^.SrcStatementIndex = 0;
      if (not Result) and  (APrvItm <> nil)
      then Result := (AItm^.SrcFileName <> APrvItm^.SrcFileName)
                  or (AItm^.SrcFileLine <> APrvItm^.SrcFileLine);
    end
    else begin
      Result :=  (AItm^.FuncName <> '');
      if Result
      then Result := (AItm^.Offset = 0)
                  or ( (APrvItm <> nil) and (AItm^.FuncName <> APrvItm^.FuncName) );
    end;
  end;

var
  DoneLocation: TDBGPtr;
  DoneTopLine, DoneLineCount: Integer;
  DoneCountBefore, DoneCountAfter: Integer;
  Line, Idx: Integer;
  Itm, NextItm, PrevItm: PDisassemblerEntry;
  LineIsSrc, HasLineOutOfRange: Boolean;
begin
  if (FDebugger = nil) or (FDisassembler = nil) or (FDebugger.State <> dsPause)
  then begin
    ClearLineMap;  // set all to lmsUnknown;
    exit;
  end;
  if FDisassembler.BaseAddr <> FCurrentLocation
  then begin
    ClearLineMap(lmsInvalid);
    exit;
  end;

  if FUpdating
  then begin
    FUpdateNeeded := True;
    Exit;
  end;
  FUpdating := True;

  try
    FUpdateNeeded := False;
    DoneLocation    := FCurrentLocation;
    DoneTopLine     := AFirstLine;
    DoneLineCount   := ALineCount;
    DoneCountBefore := FDisassembler.CountBefore;
    DoneCountAfter  := FDisassembler.CountAfter;

    // Find Idx for topline
    Line := 0;
    Idx := 0;
    LineIsSrc := False;
    if ACachedValid
    and (abs(AFirstLine - ACachedLine) < AFirstLine)
    then begin
      Line := ACachedLine;
      Idx := ACachedIdx;
      LineIsSrc := ACachedIsSrc;
    end;

    Itm := GetItem(Idx);
    NextItm := GetItem(Idx + 1);

    while AFirstLine > Line
    do begin
      NextItm := GetItem(Idx+1);
      if LineIsSrc
      then begin
        LineIsSrc := False;
      end
      else if IsSourceBeforeItem(NextItm, Itm)
      then begin
        inc(Idx);
        Itm := NextItm;
        NextItm := GetItem(Idx + 1);
        LineIsSrc := True;
      end
      else begin
        inc(Idx);
        Itm := NextItm;
        NextItm := GetItem(Idx + 1);
      end;
      inc(Line);
    end;

    Itm := GetItem(Idx);
    PrevItm := GetItem(Idx - 1);
    while AFirstLine < line
    do begin
      if LineIsSrc
      then begin
        dec(Idx);
        Itm := PrevItm;
        PrevItm := GetItem(Idx - 1);
        LineIsSrc := False;
      end
      else if IsSourceBeforeItem(Itm, PrevItm)
      then begin
        LineIsSrc := True;
      end
      else begin
        dec(Idx);
        Itm := PrevItm;
        PrevItm := GetItem(Idx - 1);
      end;
      Dec(Line);
    end;

    if ACachedUpdate
    then begin
      ACachedLine := AFirstLine;
      ACachedIdx := Idx;
      ACachedIsSrc := LineIsSrc;
      ACachedValid := True;
    end;

    // Fill LineMap
    HasLineOutOfRange := False;
    Line := 0;
    PrevItm := GetItem(Idx - 1);
    NextItm := GetItem(Idx);
    while Line < ALineCount do begin
      PrevItm := Itm;
      Itm := NextItm;
      NextItm := GetItem(Idx+1);

      if Itm = nil
      then begin
        ALineMap[Line].State := lmsInvalid;
        HasLineOutOfRange := True;
        inc(Line);
        inc(idx);
        continue;
      end;

      if ( (Line = 0) and LineIsSrc )
      or ( (Line <> 0) and IsSourceBeforeItem(Itm, PrevItm) )
      then begin
        ALineMap[Line].Dump       := '';
        ALineMap[Line].Statement  := '';
        if Itm^.SrcFileName <> ''
        then begin
          ALineMap[Line].State := lmsSource;
          ALineMap[Line].SourceLine := Itm^.SrcFileLine;
          ALineMap[Line].FileName   := Itm^.SrcFileName;
        end
        else begin
          ALineMap[Line].State := lmsFuncName;
          ALineMap[Line].SourceLine := Itm^.Offset;
          ALineMap[Line].FileName   := Itm^.FuncName;
        end;
        inc(Line);
      end
      else
      if (Line = 0) and (not ANoExtraHeader)  // but it's not LineIsSrc
      and ( ( (Itm^.SrcFileName <> '') and (Itm^.SrcStatementIndex <> Itm^.SrcStatementCount-1) )
         or ( (Itm^.SrcFileName = '') and (Itm^.FuncName <> '') and (NextItm <> nil) and (Itm^.Offset < NextItm^.Offset) )
      )
      then begin
        ALineMap[Line].Dump       := '';
        ALineMap[Line].Statement  := '';
        if Itm^.SrcFileName <> ''
        then begin
          ALineMap[Line].State := lmsSource;
          ALineMap[Line].SourceLine := Itm^.SrcFileLine;
          ALineMap[Line].FileName   := Itm^.SrcFileName;
          if NextItm <> nil
          then ALineMap[Line].Statement  := Format('(%d of %d)', [NextItm^.SrcStatementIndex, NextItm^.SrcStatementCount])
          else ALineMap[Line].Statement  := Format('(??? of %d)', [Itm^.SrcStatementCount]);
        end
        else begin
          ALineMap[Line].State := lmsFuncName;
          ALineMap[Line].SourceLine := 0;
          if NextItm <> nil
          then ALineMap[Line].SourceLine := NextItm^.Offset;
          ALineMap[Line].FileName   := Itm^.FuncName;
          if NextItm <> nil
          then ALineMap[Line].Statement  := Format('(%d)', [NextItm^.Offset])
          else ALineMap[Line].Statement  := '(???)';
        end;
        inc(Line);
        inc(idx); // displayed source-info, instead of asm (topline substituted)
        LineIsSrc := False;
        continue;
      end;
      LineIsSrc := False; // only for topline

      if Line >= ALineCount
      then break;

      ALineMap[Line].Addr       := Itm^.Addr;
      ALineMap[Line].State      := lmsStatement;
      ALineMap[Line].Dump       := Itm^.Dump;
      ALineMap[Line].Statement  := Itm^.Statement;
      ALineMap[Line].SourceLine := Itm^.SrcFileLine;

      inc(Line);
      inc(idx);
    end;

  finally
    FUpdating := False;
    if FUpdateNeeded
    and ( (DoneLocation    <> FCurrentLocation)
       or (DoneTopLine     <> AFirstLine)
       or (DoneLineCount   <> ALineCount)
       or (HasLineOutOfRange
          and ( (DoneCountBefore <> FDisassembler.CountBefore)
             or (DoneCountAfter  <> FDisassembler.CountAfter) )  )
    )
    then UpdateLineData;
  end;
end;

end.

