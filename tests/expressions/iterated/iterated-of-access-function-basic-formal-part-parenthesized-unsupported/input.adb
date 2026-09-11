procedure main is
begin
  return (for Handler : access function (Item : Item_Type)
          return Result_Type of Handlers => Value);
end main;
