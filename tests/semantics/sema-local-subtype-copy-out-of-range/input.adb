procedure main is
  subtype Small is Integer range 1 .. 10;
  source : Integer := 11;
  target : Small := 1;
begin
  target := source;
end main;
