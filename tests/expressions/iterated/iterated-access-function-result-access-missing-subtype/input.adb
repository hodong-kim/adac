procedure main is
begin
  return (for Handler : access function return access constant
          of Handlers => Value);
end main;
