unit uTPLb_SVN_Keywords;
interface
const
  TPLB3Runtime_SVN_Keyword_Date    : UTF8String = '$Date: 2011-08-07 02:28:13 +1000 (Sun, 07 Aug 2011) $';
  TPLB3Runtime_SVN_Keyword_Revision: UTF8String = '$Revision: 204 $';
  TPLB3Runtime_SVN_Keyword_Author  : UTF8String = '$Author: durkin10 $';
  TPLB3Runtime_SVN_Keyword_HeadURL : UTF8String = '$HeadURL: https://tplockbox.svn.sourceforge.net/svnroot/tplockbox/trunc/run/utilities/uTPLb_SVN_Keywords.pas $';
  TPLB3Runtime_SVN_Keyword_Id      : UTF8String = '$Id: uTPLb_SVN_Keywords.pas 204 2011-08-06 16:28:13Z durkin10 $';


function TPLB3Runtime_SVN_Revision: integer;


implementation

{$WARNINGS OFF}
function TPLB3Runtime_SVN_Revision: integer;
var
  s, Pattern: string;
  P, Code: integer;
begin
s := TPLB3Runtime_SVN_Keyword_Revision;
Pattern := '$Revision: ';
P := Pos( Pattern, s);
if P > 0 then
  Delete( s, P, Length( Pattern));
Pattern := ' ';
P := Pos( Pattern, s);
if P > 0 then
  SetLength( s, P-1);
Val( s, result, Code);
if (s = '') or (Code <> 0) then
  result := -1 // Signifying unknown version
end;
{$WARNINGS ON}

{ Here is a scratch pad area for forcing changes to file in SVN.

}
end.
