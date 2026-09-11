procedure main is
  limit : constant Integer := 7;
  subtype Small is Integer range 1 .. 9;
  from_constant : constant := limit * 2;
  from_attribute : constant := Small'Last + 1;
  combined : constant := from_constant + from_attribute;
  value : Integer := combined;
begin
  null;
end main;
