package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    procedure Helper is
      failed : Integer := 0;

      function Local
        (position : Integer;
         spelling : Integer)
      return Integer
      is
      begin
        return spelling;
      exception
        when Constraint_Error =>
          failed := 1;
          Touch;
          return position;
      end Local;
    begin
      Touch;
    end Helper;
  begin
    return value;
  end Wrap;
end Parent.Child;
