procedure main is
begin
  null;
exception
  when occurrence_only : Constraint_Error =>
    null;
end main;
