procedure main is
  subtype Tiny is Integer range 1 .. 3;
  bad : constant Tiny := (2 ** 100) - (2 ** 100) + 4;
begin
  null;
end main;
