procedure main is
begin
  return (for Handler : access procedure
            (Item : Item_Type := Default_Item
               with Impl_Aspect'ClAsS => Aspect_Value, Flag_Aspect;
             Other : access Other_Type
               with Access_Aspect => Access_Value)
          of Handlers => Value);
end main;
