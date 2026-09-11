package Sample is
private
  type Holder is record
    owner : Ref := null;
    index : Natural := 0;
  end record;
end Sample;
