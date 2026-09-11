procedure main is
  Left : Boolean := True;
  Right : Boolean := False;
  Target : Boolean;
begin
  Target := Left and Right;
  Right := True;
  Target := Left or Right;
  Left := False;
  Target := Left xor Right;
end main;
