procedure main is
  Left : Boolean := False;
  Right : Boolean := True;
  Target : Boolean;
begin
  Target := Left < Right;
  Target := Left <= Right;
  Target := Left > Right;
  Target := Left >= Right;
  Left := True;
  Target := Left < Right;
  Target := Left <= Right;
  Target := Left > Right;
  Target := Left >= Right;
end main;
