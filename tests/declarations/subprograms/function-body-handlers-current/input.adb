package body Parent.Child is
  function Emit (output_path : String) return Result is
  begin
    Helper.Call;
    return (status => Succeeded);
  exception
    when error : Operational_Error =>
      return
        (status => Failed,
         diagnostic => Text.Make (Errors.Message (error)));
    when Name_Error | Use_Error | Device_Error =>
      return
        (status => Failed,
         diagnostic => Text.Make ("I/O failure: " & output_path));
  end Emit;
end Parent.Child;
