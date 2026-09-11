package Sample is
private
  type Choice is (A, B);
  type Holder (kind : Choice := A) is record
    case kind is
      when A =>
        value : Item;
      when B =>
        null;
    end case;
  end record;
end Sample;
