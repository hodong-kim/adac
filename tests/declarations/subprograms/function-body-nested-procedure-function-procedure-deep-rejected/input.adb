package body Parent.Child is
  function Wrap return Integer is
    procedure Helper is
      function Choose return Integer is
        procedure Nested is
          procedure Too_Deep is
          begin
            null;
          end Too_Deep;
        begin
          null;
        end Nested;
      begin
        return 1;
      end Choose;
    begin
      Touch;
    end Helper;
  begin
    return 1;
  end Wrap;
end Parent.Child;
