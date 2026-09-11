procedure main is
  value : Integer := (2 ** 100) / (2 ** 100);
  attribute_value : Integer := Integer'First - Integer'First + 2;
begin
  value := (2 ** 100) - (2 ** 100) + 3;
  attribute_value := Integer'Last - Integer'Last + 4;
end main;
