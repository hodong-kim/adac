package body Parent.Child is
  function Wrap (self : Store) return Integer is
  begin
    if self.nodes.length >= Ada.Containers.Count_Type(Positive'Last) then
      raise Program_Error with "bad";
    end if;
    return 0;
  end Wrap;
end Parent.Child;
