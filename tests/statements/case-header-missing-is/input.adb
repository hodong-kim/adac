procedure main is
  procedure nested is
    item : constant String := Value;
  begin
    Call;
    declare
      local : constant String := Value;
    begin
      case local.status
        when Choice =>
          null;
      end case;
    end;
  end nested;
begin
  null;
end main;
