package body Parent.Child is
  function Wrap return Integer is
    procedure Helper is
      type State is (Idle, Busy, Done);
    begin
      Touch;
    end Helper;
  begin
    return 1;
  end Wrap;
end Parent.Child;
