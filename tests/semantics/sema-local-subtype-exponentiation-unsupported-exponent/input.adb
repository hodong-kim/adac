procedure main is
  value : Integer := 2;
  subtype Bad is Integer range 0 .. 2 ** value;
begin
  null;
end main;
