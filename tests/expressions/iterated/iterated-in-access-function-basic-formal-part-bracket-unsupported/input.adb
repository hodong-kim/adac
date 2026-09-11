procedure main is
begin
  return [for Handler : not null access protected function
          (Item : Item_Type) return not null Result_Type
          in reverse Handlers when Ready => Value];
end main;
