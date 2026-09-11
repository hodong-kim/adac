package Parent.Child is
  type Result is private;
  function Failure_Message (result : Result) return String
    with Pre => result.status = Failure;
end Parent.Child;
