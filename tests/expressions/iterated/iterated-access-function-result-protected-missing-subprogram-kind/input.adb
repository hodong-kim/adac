procedure main is
begin
  return (for Handler : access function return access protected
          of Handlers => Value);
end main;
