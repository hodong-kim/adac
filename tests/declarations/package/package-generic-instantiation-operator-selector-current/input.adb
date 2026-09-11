package Sample is
private
  package Items is new Ada.Containers.Vectors
    (Index_Type => Positive,
     Element_Type => Item,
     "=" => Ada.Strings.Unbounded."=");
end Sample;
