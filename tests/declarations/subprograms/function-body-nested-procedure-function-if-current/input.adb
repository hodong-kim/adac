package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    procedure Helper is
      function Choose (item : Integer) return Integer is
      begin
        if item = 0 then
          return 1;
        end if;
        return 2;
      end Choose;
    begin
      Touch;
    end Helper;
  begin
    return value;
  end Wrap;
end Parent.Child;
