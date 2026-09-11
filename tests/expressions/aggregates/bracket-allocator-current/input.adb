package body Parent.Child is
  function Make return Integer is
    Arguments : OS.Argument_List (1 .. 3) :=
      [new String'("-o"),
       new String'("output"),
       new String'("input")];
  begin
    return 0;
  end Make;
end Parent.Child;
