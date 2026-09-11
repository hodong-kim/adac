package body Parent.Child is
  function Wrap (items : Item_List) return Integer is
  begin
    for index in 1 .. List_Count (items) loop
      Helper.Call;
    end loop;
    for index in reverse 1 .. 3 loop
      Helper.Call;
    end loop;
    return 0;
  end Wrap;
end Parent.Child;
