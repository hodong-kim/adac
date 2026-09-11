package body Parent.Child is
  function Next (self : Store) return Node_ID is
  begin
    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length) + 1);
  end Next;
end Parent.Child;
