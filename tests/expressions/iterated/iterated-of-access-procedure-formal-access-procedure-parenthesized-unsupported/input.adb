procedure main is
begin
  return (for Handler : access procedure
            (Callback : not null access protected procedure
               (Item : access Item_Type) := Default_Handler)
          of Handlers => Value);
end main;
