procedure main is
begin
  return (for Element :
            Matrix_Type(Index_Type, Column_Type range 1 .. Limit)
          of Items => Value);
end main;
