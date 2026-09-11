procedure main is
  Left : Boolean := False;
  Right : Boolean := True;
  Target : Boolean;
begin
  Target := Left and then Right;
  Left := True;
  Target := Left and then Right;
  Target := Target or else Left;
  Right := False;
  Target := Right or else Left;
end main;
