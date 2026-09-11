procedure main is
  Left : Boolean := True;
  Right : Boolean := False;
  Third : Boolean := True;
  Target : Boolean;
begin
  Target := (not Left) or (Right xor True);
  Left := False;
  Target := (Target and (not False)) = (not Right);
  Right := True;
  Target := ((Left < Right) xor (not Third)) or (False and then True);
end main;
