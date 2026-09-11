procedure main is
  Source : Boolean := True;
  Target : Boolean;
begin
  Target := not Source;
  Source := False;
  Target := not Source;
  Target := not Target;
end main;
