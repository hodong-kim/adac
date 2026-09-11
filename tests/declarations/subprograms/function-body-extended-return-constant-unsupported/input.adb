package body Parent.Child is
  function Create return Store is
  begin
    return result : constant Store do
      result.initialized := True;
    end return;
  end Create;
end Parent.Child;
