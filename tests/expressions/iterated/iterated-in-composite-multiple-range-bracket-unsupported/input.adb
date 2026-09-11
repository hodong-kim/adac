procedure main is
begin
  return [for Element : Matrix_Type(1 .. Rows, 1 .. Columns)
          in reverse Items when Ready => Value];
end main;
