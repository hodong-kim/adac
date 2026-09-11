package body Parent.Child is
  function Wrap return Item is
  begin
    return Build
      (store,
       symbol,
       span,
       discriminants,
       full_span,
       limited_form => limited_form,
       maximum_nodes => limits.maximum_nodes);
  end Wrap;
end Parent.Child;
