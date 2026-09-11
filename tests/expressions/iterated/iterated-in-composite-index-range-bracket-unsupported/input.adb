procedure main is
begin
  return [for Element : Item_Type(Low .. High)
          in reverse Items when Ready => Value];
end main;
