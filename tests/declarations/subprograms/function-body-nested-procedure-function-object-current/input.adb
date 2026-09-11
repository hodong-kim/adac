package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    procedure Helper is
      function Choose (item : Integer) return Integer is
        kind : Integer;
      begin
        kind := item;
        return kind;
      end Choose;
    begin
      Touch;
    end Helper;
  begin
    return value;
  end Wrap;
end Parent.Child;
