procedure main is
begin
  return (for Handler : access procedure
            (Item : Item_Type with Impl_Aspect =>)
          of Handlers => Value);
end main;
