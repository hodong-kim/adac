package Parent.Child is
  type Item is private;
  Null_Item : constant Item;
  type Choice is (One, Two, Three);
  type Mode is (Read, Write, Append);
  type Kind is (Primary, Secondary);
  type Form is (Variable_Form, Constant_Form);
  type List is private;
  type Name is private;
  type Literal_List is private;
  procedure Update (self : in out List; node : Item);
  function Count (self : List) return Natural;
  function Element (self : List; index : Positive) return Item;
  procedure Append_Name
    (self   : in out Name;
     symbol : Types.Symbol_ID;
     span   : Types.Span);
  function Component_Count (self : Name) return Natural;
  function Component_Symbol
    (self  : Name;
     index : Positive)
  return Types.Symbol_ID;
  function Component_Span
    (self  : Name;
     index : Positive)
  return Types.Span;
  procedure Append_Literal
    (self   : in out Literal_List;
     symbol : Types.Symbol_ID;
     span   : Types.Span);
  function Stop return Natural;
end Parent.Child;
