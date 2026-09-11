procedure main is
  folded : constant Integer := (2 ** 100) / (2 ** 100);
  attribute_value : constant Integer := Integer'First - Integer'First + 2;
  result : Integer := folded + attribute_value;
begin
  null;
end main;
