procedure main is
begin
  null;
exception
  when others =>
    cleanup;
    raise;
end main;
