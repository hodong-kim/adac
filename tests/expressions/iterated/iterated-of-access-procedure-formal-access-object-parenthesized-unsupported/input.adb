procedure main is
begin
  return (for Handler : access procedure
            (Left : not null access constant Item_Type := Default_Access;
             Right : access Other_Type := Other_Access)
          of Handlers => Value);
end main;
