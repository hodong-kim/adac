procedure main is
begin
  return (for Handler : access function return access procedure
          of Handlers => Value);
end main;
