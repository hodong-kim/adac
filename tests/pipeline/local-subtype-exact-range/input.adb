procedure main is
  scale : constant Integer := 2;
  wide : constant := 2 ** 100;
  subtype Exact is Integer range wide - wide + 1 .. Integer'Last - Integer'Last + scale + 1;
  value : Exact := 2;
begin
  null;
end main;
