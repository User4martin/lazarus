{ $Id$}
{
 *****************************************************************************
 *                               lclclasses.pp                               * 
 *                               -------------                               * 
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

  Defines the base class for all LCL TComponents including controls.
}
unit LCLClasses;

{$mode objfpc}{$H+}

interface

uses
  Classes, WSLCLClasses, WSReferences, LCLType, LCLProc;

type

  { TLCLComponent }

  TLCLComponent = class(TComponent)
  private
    FWidgetSetClass: TWSLCLComponentClass;
    FLCLRefCount: integer;
  protected
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeforeDestruction; override; // fixes missing call to Destroying in FPC
    class function NewInstance: TObject; override;
    procedure RemoveAllHandlersOfObject(AnObject: TObject); virtual;
    procedure IncLCLRefCount;
    procedure DecLCLRefCount;
    property LCLRefCount: integer read FLCLRefCount;
    property WidgetSetClass: TWSLCLComponentClass read FWidgetSetClass;
  end;
  
  { TLCLReferenceComponent }

  // A base class for all components having a handle

  TLCLReferenceComponent = class(TLCLComponent)
  private
    FReferencePtr: PWSReference;

    FCreating: Boolean; // Set if we are creating the handle
    function  GetHandle: THandle;
    function  GetReferenceAllocated: Boolean;
  protected
    procedure CreateParams(var AParams: TCreateParams); virtual;
    procedure DestroyReference;
    function  GetReferenceHandle: THandle; virtual; abstract;
    procedure ReferenceCreated; virtual;    // gets called after the Handle is created
    procedure ReferenceDestroying; virtual; // gets called before the Handle is destroyed
    procedure ReferenceNeeded;
    function  WSCreateReference(AParams: TCreateParams): PWSReference; virtual;
    procedure WSDestroyReference; virtual;
  protected
  public
    destructor Destroy; override;
    property Handle: TLCLIntfHandle read GetHandle; deprecated;
    property HandleAllocated: Boolean read GetReferenceAllocated;
    property ReferenceAllocated: Boolean read GetReferenceAllocated;
  end;

implementation                    

constructor TLCLComponent.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  {$IFDEF DebugLCLComponents}
  //DebugLn('TLCLComponent.Create ',DbgSName(Self));
  DebugLCLComponents.MarkCreated(Self,DbgSName(Self));
  {$ENDIF}
end;

destructor TLCLComponent.Destroy;
begin
  if FLCLRefCount>0 then
    DebugLn(['WARNING: TLCLComponent.Destroy with LCLRefCount>0. Hint: Maybe the component is processing an event?']);
  {$IFDEF DebugLCLComponents}
  //DebugLn('TLCLComponent.Destroy ',DbgSName(Self));
  DebugLCLComponents.MarkDestroyed(Self);
  {$ENDIF}
  inherited Destroy;
end;

procedure TLCLComponent.BeforeDestruction;
begin
  inherited;
  Destroying;
end;

class function TLCLComponent.NewInstance: TObject;
begin
  Result := inherited NewInstance; 
  TLCLComponent(Result).FWidgetSetClass := FindWSComponentClass(Self);
  if TLCLComponent(Result).FWidgetSetClass = nil then
  begin
    {$IFDEF VerboseLCL}
    DebugLn(['TLCLComponent.NewInstance WARNING: missing FWidgetSetClass ',ClassName]);
    {$ENDIF}
    TLCLComponent(Result).FWidgetSetClass := TWSLCLComponent;
  end;
end;

procedure TLCLComponent.RemoveAllHandlersOfObject(AnObject: TObject);
begin
end;

procedure TLCLComponent.IncLCLRefCount;
begin
  inc(FLCLRefCount);
end;

procedure TLCLComponent.DecLCLRefCount;
begin
  dec(FLCLRefCount);
end;

{ TLCLReferenceComponent }

procedure TLCLReferenceComponent.CreateParams(var AParams: TCreateParams);
begin
end;

destructor TLCLReferenceComponent.Destroy;
begin
  DestroyReference;
  inherited Destroy;
end;

procedure TLCLReferenceComponent.DestroyReference;
begin
  if ReferenceAllocated then
  begin
    ReferenceDestroying;
    WSDestroyReference;
    FReferencePtr^._Clear;
    FReferencePtr := nil;
  end;
end;

function TLCLReferenceComponent.GetHandle: THandle;
begin
  ReferenceNeeded;
  Result := GetReferenceHandle;
end;

function TLCLReferenceComponent.GetReferenceAllocated: Boolean;
begin
  Result := (FReferencePtr <> nil) and FReferencePtr^.Allocated;
end;

procedure TLCLReferenceComponent.ReferenceCreated;
begin
end;

procedure TLCLReferenceComponent.ReferenceDestroying;
begin
end;

procedure TLCLReferenceComponent.ReferenceNeeded;
var
  Params: TCreateParams;
begin
  if ReferenceAllocated then Exit;

  if FCreating
  then begin
    // raise some error ?
    DebugLn('TLCLReferenceComponent: Circulair reference creation');
    Exit;
  end;

  CreateParams(Params);
  FCreating := True;
  try
    FReferencePtr := WSCreateReference(Params);
    if not ReferenceAllocated
    then begin
      // raise some error ?
      DebugLn('TLCLHandleComponent: Reference creation failed');
      Exit;
    end;
  finally
    FCreating := False;
  end;
  ReferenceCreated;
end;

function TLCLReferenceComponent.WSCreateReference(AParams: TCreateParams): PWSReference;
begin
  // this function should be overriden in derrived class
  Result := nil;
end;

procedure TLCLReferenceComponent.WSDestroyReference;
begin
  TWSLCLReferenceComponentClass(WidgetSetClass).DestroyReference(Self);
end;

end.

