procedure main is
begin
  return [for Index in reverse 1 .. Limit when Ready and Enabled => Value];
end main;
