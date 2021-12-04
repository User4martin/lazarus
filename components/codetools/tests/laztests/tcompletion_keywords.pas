unit tcompletion_keywords;
{%identcomplincludekeywords:on}

{$mode objfpc}{$H+}

interface

implementation
var
  bVal: Boolean;
  iVal: integer;

begin
  if  {completion:+3=!and,not,inherited} // +3 test in space after if
    iVal  {completion:!and,!in,not,inherited;+1=!and,!in,!not,inherited;+5=and,in,!not,!inherited} // + 5 in spaces after iVal
end.

