package body Parent.Child is
  function Get (name : Node_ID) return Node_ID is
  begin
    case Kind is
      when Selected =>
        return self.nodes(Positive(name.index)).selected_prefix;
      when others =>
        return fallback;
    end case;
  end Get;
end Parent.Child;
