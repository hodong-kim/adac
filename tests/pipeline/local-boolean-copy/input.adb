procedure main is
  Source : Boolean := True;
  Middle : Boolean;
  Target : Standard.Boolean;
begin
  Middle := Source;
  Source := False;
  Target := Source;
  Target := Middle;
end main;
