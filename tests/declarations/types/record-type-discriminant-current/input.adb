package Sample is
private
  type Holder (kind : Choice := Default_Kind) is record
    value : Item;
  end record;
end Sample;
