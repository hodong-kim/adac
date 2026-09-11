package body Parent.Child is
  function Make return Span is
  begin
    return (first => (file_id => INVALID_SOURCE_FILE_ID,
                      line    => 1,
                      column  => 1),
            last  => (file_id => INVALID_SOURCE_FILE_ID,
                      line    => 2,
                      column  => 3));
  end Make;
end Parent.Child;
