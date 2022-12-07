unit IdeConfigStrConsts;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

resourcestring

  lisMMInvalidCharacterAt = 'invalid character "%s" at %s';
  lisMMMissingMacroName = 'missing macro name';
  lisMMExpectedMacroNameButFound = 'expected macro name but found "%s"';
  lisMMInvalidCharacterInMacroValue = 'invalid character in macro value "%s"';
  lisMMExpectedAfterMacroNameButFound = 'expected ":=" after macro name but found "%s"';

implementation

end.

