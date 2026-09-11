package body Parent.Child is
  function Option return String is
  begin
    return String'("-o");
  end Option;
end Parent.Child;
