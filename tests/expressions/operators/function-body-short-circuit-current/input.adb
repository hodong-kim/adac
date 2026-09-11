package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    if self.nodes (Positive (association.expression.index)).kind =
         Record_Aggregate_Node or else
       self.nodes (Positive (association.expression.index)).kind =
         Qualified_Expression_Node or else
       not is_current_direct_expression_kind
         (self.nodes (Positive (association.expression.index)).kind)
    then
      raise Program_Error with "bad";
    end if;
    return value;
  end Wrap;
end Parent.Child;
