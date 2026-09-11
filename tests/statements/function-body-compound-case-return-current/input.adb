package body Parent.Child is
  function Wrap (items : Item_List; ready : Boolean) return Boolean is
  begin
    if ready then
      for item of items loop
        case item is
          when Ready =>
            return True;
          when others =>
            return False;
        end case;
      end loop;
    end if;
    return ready;
  end Wrap;
end Parent.Child;
