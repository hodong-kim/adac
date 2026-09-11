procedure main is
begin
  return (for Handler : access function return access Result_Type
          of Handlers => Value);
end main;
