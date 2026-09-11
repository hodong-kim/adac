package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    declare
      alias : Node renames self.nodes (Positive (value));
    begin
      Helper.Call;
    end;
    return value;
  end Wrap;
end Parent.Child;
