unit laz.FakeMMSystem;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, LCLIntf;
  
function timeBeginPeriod(x1: DWord): DWord;

function timeEndPeriod(x1: DWord): DWord;

function timeGetTime: DWORD;

implementation

function timeBeginPeriod(x1: DWord): DWord;
begin
  //
  Result:= 0; //Warning: (5033) Function result does not seem to be set
end;

function timeEndPeriod(x1: DWord): DWord;
begin
  //
  Result:= 0; //Warning: (5033) Function result does not seem to be set
end;

function timeGetTime: DWORD;
begin
  Result := GetTickCount;
end;

end.

