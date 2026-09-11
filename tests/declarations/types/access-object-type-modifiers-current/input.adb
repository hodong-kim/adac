package Sample is
private
  type Plain_Ref is access Target;
  type All_Ref is access all Target;
  type Constant_Ref is access constant Target;
end Sample;
