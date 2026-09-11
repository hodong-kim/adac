procedure main is
begin
  return (for Handler : access procedure
            (Mapper : not null access protected function
               (Item : Item_Type) return
                 access function return Result_Type := Default_Mapper)
          of Handlers => Value);
end main;
