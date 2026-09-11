package body Parent.Child is
  function Image_Of (value : Long_Long_Integer) return String is
  begin
    return Long_Long_Integer'image(value);
  end Image_Of;
end Parent.Child;
