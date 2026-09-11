procedure main is
begin
  return (for Handler : access function return access
          function return Result_Type of Handlers => Value);
end main;
