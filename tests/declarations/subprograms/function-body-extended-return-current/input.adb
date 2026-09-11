package body Parent.Child is
  function Create return Store is
  begin
    return result : Store do
      result.initialized := True;
      result.finish;
      null;
    end return;
  end Create;
end Parent.Child;
