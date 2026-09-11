package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    procedure Run is
      Success : Boolean;
    begin
      if Success then
        Helper.Call;
      end if;
      Helper.Call;
      Success := Ready;
    end Run;
  begin
    return value;
  end Wrap;
end Parent.Child;
