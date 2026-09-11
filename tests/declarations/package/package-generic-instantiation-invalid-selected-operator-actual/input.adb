package Sample is
private
  package Items is new Generic_Package
    (Value => Ada.Strings.Unbounded."Value");
end Sample;
