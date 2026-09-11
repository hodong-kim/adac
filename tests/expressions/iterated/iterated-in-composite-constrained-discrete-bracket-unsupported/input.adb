procedure main is
begin
  return [for Element :
            Matrix_Type(Row_Index range Rows'Range,
                        Column_Index range 1 .. Columns)
          in reverse Items when Ready => Value];
end main;
