unit CocoaUtils;

{$mode objfpc}{$H+}
{$modeswitch objectivec1}

interface

uses
  MacOSAll, CocoaAll,
  Types, LCLType;

type
  { NSLCLDebugExtension }

  NSLCLDebugExtension = objccategory(NSObject)
    function lclClassName: shortstring; message 'lclClassName';
  end;

const
  NSNullRect : NSRect = (origin:(x:0; y:0); size:(width:0; height:0));

function GetNSPoint(x,y: single): NSPoint; inline;

function GetCGRect(x1, y1, x2, y2: Integer): CGRect;
function CGRectToRect(const c: CGRect): TRect;

function GetNSRect(x, y, width, height: Integer): NSRect; inline;
function RectToNSRect(const r: TRect): NSRect;

procedure NSToLCLRect(const ns: NSRect; var lcl: TRect); overload;
procedure NSToLCLRect(const ns: NSRect; ParentHeight: Single; var lcl: TRect); overload;

procedure LCLToNSRect(const lcl: TRect; var ns: NSRect); overload;
procedure LCLToNSRect(const lcl: TRect; ParentHeight: Single; var ns: NSRect); overload;

function CreateParamsToNSRect(const params: TCreateParams): NSRect;

function NSStringUtf8(s: PChar): NSString;
function NSStringUtf8(const s: String): NSString;
function NSStringToString(ns: NSString): String;

function GetNSObjectView(obj: NSObject): NSView;
procedure AddViewToNSObject(ctrl: NSView; obj: NSObject);
procedure AddViewToNSObject(ctrl: NSView; obj: NSObject; X,Y: integer);

procedure SetNSText(text: NSText; const s: String); inline;
function GetNSText(text: NSText): string; inline;

procedure SetNSControlValue(c: NSControl; const S: String); inline;
function GetNSControlValue(c: NSControl): String; inline;

implementation

const
  DEFAULT_CFSTRING_ENCODING = kCFStringEncodingUTF8;

function CFStringToStr(AString: CFStringRef; Encoding: CFStringEncoding = DEFAULT_CFSTRING_ENCODING): String;
var
  Str: Pointer;
  StrSize: CFIndex;
  StrRange: CFRange;
begin
  if AString = nil then
  begin
    Result := '';
    Exit;
  end;

  // Try the quick way first
  Str := CFStringGetCStringPtr(AString, Encoding);
  if Str <> nil then
    Result := PChar(Str)
  else
  begin
    // if that doesn't work this will
    StrRange.location := 0;
    StrRange.length := CFStringGetLength(AString);

    CFStringGetBytes(AString, StrRange, Encoding,
      Ord('?'), False, nil, 0, StrSize);
    SetLength(Result, StrSize);

    if StrSize > 0 then
      CFStringGetBytes(AString, StrRange, Encoding,
        Ord('?'), False, @Result[1], StrSize, StrSize);
  end;
end;

function GetNSObjectView(obj: NSObject): NSView;
begin
  Result:=nil;
  if not Assigned(obj) then Exit;
  if obj.isKindOfClass_(NSView) then Result:=NSView(obj)
  else if obj.isKindOfClass_(NSWindow) then Result:=NSWindow(obj).contentView;
end;

procedure AddViewToNSObject(ctrl: NSView; obj: NSObject);
var
  view : NSView;
begin
  view:=GetNSObjectView(obj);
  if not Assigned(view) then Exit;
  view.addSubView(ctrl);
end;

procedure AddViewToNSObject(ctrl: NSView; obj: NSObject; X,Y: integer);
begin
  AddViewToNSObject(ctrl, obj);
  //SetViewFramePos(ctrl, x,y);
end;

function GetNSPoint(x, y: single): NSPoint;
begin
  Result.x:=x;
  Result.y:=y;
end;

function GetNSRect(x, y, width, height: Integer): NSRect;
begin
  Result.origin.x:=x;
  Result.origin.y:=y;
  Result.size.width:=width;
  Result.size.height:=height;
end;

function GetCGRect(x1, y1, x2, y2: Integer): CGRect;
begin
  Result.origin.x:=x1;
  Result.origin.y:=y1;
  Result.size.width:=x2-x1;
  Result.size.height:=y2-y1;
end;

function CGRectToRect(const c:CGRect):TRect;
begin
  Result.Left:=round(c.origin.x);
  Result.Top:=round(c.origin.y);
  Result.Right:=round(c.origin.x+c.size.width);
  Result.Bottom:=round(c.origin.y+c.size.height);
end;

function RectToNSRect(const r: TRect): NSRect;
begin
  Result:=GetNSRect(r.Left,r.Top,r.Right-r.Left,r.Bottom-r.Top);
end;

procedure NSToLCLRect(const ns: NSRect; var lcl: TRect);
begin
  lcl.Left:=round(ns.origin.x);
  lcl.Top:=round(ns.origin.y);
  lcl.Right:=round(ns.origin.x+ns.size.width);
  lcl.Bottom:=round(ns.origin.y+ns.size.height);
end;

procedure NSToLCLRect(const ns: NSRect; ParentHeight: Single; var lcl: TRect);
begin
  lcl.Left:=Round(ns.origin.x);
  lcl.Top:=Round(ParentHeight-ns.size.height-ns.origin.y);
  lcl.Right:=Round(ns.origin.x+ns.size.width);
  lcl.Bottom:=Round(lcl.Top+ns.size.height);
end;

procedure LCLToNSRect(const lcl: TRect; var ns: NSRect); overload;
begin
  ns.origin.x:=lcl.Left;
  ns.origin.y:=lcl.Top;
  ns.size.width:=lcl.Right-lcl.Left;
  ns.size.height:=lcl.Bottom-lcl.Top;
end;

procedure LCLToNSRect(const lcl: TRect; ParentHeight: Single; var ns: NSRect); overload;
begin
  ns.origin.x:=lcl.left;
  ns.origin.y:=ParentHeight-(lcl.bottom-lcl.Top)-lcl.Top;
  ns.size.width:=lcl.Right-lcl.Left;
  ns.size.height:=lcl.Bottom-lcl.Top;
end;


function CreateParamsToNSRect(const params: TCreateParams): NSRect;
begin
  with params do Result:=GetNSRect(X,Y,Width,Height);
end;

function NSStringUtf8(s: PChar): NSString;
var
  cf : CFStringRef;
begin
  {NSString and CFStringRef are interchangable}
  cf:=CFStringCreateWithCString(nil, S, kCFStringEncodingUTF8);
  Result:=NSString(cf);
end;

function NSStringUtf8(const s: String): NSString;
var
  cf : CFStringRef;
begin
  {NSString and CFStringRef are interchangable}
  cf:=CFStringCreateWithCString(nil, Pointer(PChar(S)), kCFStringEncodingUTF8);
  Result:=NSString(cf);
end;

function NSStringToString(ns: NSString): String;
begin
  Result:=CFStringToStr(CFStringRef(ns));
end;

procedure SetNSText(text: NSText; const s: String); inline;
var
  ns : NSString;
begin
  if Assigned(text) then
  begin
    ns:=NSStringUTF8(s);
    text.setString(ns);
    ns.release;
  end;
end;

function GetNSText(text: NSText): string; inline;
begin
  if Assigned(text) then
    Result := NSStringToString(text.string_)
  else
    Result:='';
end;

procedure SetNSControlValue(c: NSControl; const S: String); inline;
var
  ns : NSString;
begin
  if Assigned(c) then
  begin
    ns:=NSStringUtf8(S);
    c.setStringValue(ns);
    ns.release;
  end;
end;

function GetNSControlValue(c: NSControl): String; inline;
begin
  if Assigned(c) then
    Result:=NSStringToString(c.stringValue)
  else
    Result:='';
end;


{ NSLCLDebugExtension }

function NSLCLDebugExtension.lclClassName: shortstring;
begin
  Result:=NSStringToString(self.className);
end;

initialization

end.

