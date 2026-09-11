package body Parent.Child is
  function Make return Integer is
  begin
    return_code := OS.Spawn (compiler_path.all, arguments);
    return 0;
  end Make;
end Parent.Child;
