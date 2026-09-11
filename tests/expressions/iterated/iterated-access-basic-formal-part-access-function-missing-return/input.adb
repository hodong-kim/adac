procedure main is
begin
  return (for Handler : access procedure
            (Mapper : access function)
          of Handlers => Value);
end main;
