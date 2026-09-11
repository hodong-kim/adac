package Sample is
private
  type Choice is (A, B, C);
  type Holder (kind : Choice := A) is record
    common : Item;
    case kind is
      when A | B =>
        value : Item;
      when C =>
        null;
    end case;
  end record;
end Sample;
