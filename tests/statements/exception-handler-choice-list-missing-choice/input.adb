procedure main is
begin
  null;
exception
  when occurrence : Constraint_Error | =>
    null;
end main;
