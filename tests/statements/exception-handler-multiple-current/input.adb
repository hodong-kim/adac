procedure main is
begin
  null;
exception
  when first_occurrence : First_Error =>
    null;
  when second_occurrence : Second_Error =>
    null;
  when final_occurrence : others =>
    null;
end main;
