procedure main is
begin
  return (for Handler : access procedure
            (Left : Item_Type := Default_Value;
             Right : out Other_Type := Other_Default)
          of Handlers => Value);
end main;
