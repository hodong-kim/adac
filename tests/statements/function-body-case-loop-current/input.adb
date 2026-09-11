package body Parent.Child is
  function Value return Integer is
  begin
    case State is
      when Ready =>
        Touch;
        for Index in 1 .. Count (Items) loop
          Touch;
        end loop;
        return 1;
      when others =>
        return 0;
    end case;
  end Value;
end Parent.Child;
