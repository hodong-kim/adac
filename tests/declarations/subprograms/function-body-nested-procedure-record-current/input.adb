package body Parent.Child is
  function Wrap return Integer is
    procedure Helper is
      type Frame is record
        Prefix : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
        Ready : Boolean := False;
      end record;
    begin
      Touch;
    end Helper;
  begin
    return 1;
  end Wrap;
end Parent.Child;
