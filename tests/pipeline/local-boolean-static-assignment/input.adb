procedure main is
  Ready : constant Boolean := True;
  Flag : Standard.Boolean;
begin
  Flag := Ready and not False;
  Flag := False;
end main;
