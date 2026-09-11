package body Parent.Child is
  function Wrap (items : Item_List; ready : Boolean) return Integer is
  begin
    if ready then
      for item of items loop
        case item is
          when Ready =>
            if ready then
              for nested of items loop
                Helper.Call;
              end loop;
            end if;
            declare
              local : Integer;
            begin
              local := 1;
            end;
          when others =>
            Helper.Call;
        end case;
      end loop;
    else
      for item of items loop
        Helper.Call;
      end loop;
    end if;
    return 0;
  end Wrap;
end Parent.Child;
