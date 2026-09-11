package body Parent.Child is
  function Fit
    (local_count         : Natural;
     max_frame_bytes     : Natural;
     local_storage_bytes : Natural) return Natural
  is
  begin
    if local_count > max_frame_bytes / local_storage_bytes then
      return local_count;
    end if;
    return local_count;
  end Fit;
end Parent.Child;
