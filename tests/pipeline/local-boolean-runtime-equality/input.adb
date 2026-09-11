procedure main is
  Left : Boolean := True;
  Right : Boolean := True;
  Target : Boolean;
begin
  Target := Left = Right;
  Right := False;
  Target := Left = Right;
  Target := Left /= Right;
  Left := False;
  Target := Left /= Right;
end main;
