package body Parent.Child is
  function Get return Node_ID is
  begin
    return self.nodes
      (Positive(handler.index)).exception_handler_choices_value(index);
  end Get;
end Parent.Child;
