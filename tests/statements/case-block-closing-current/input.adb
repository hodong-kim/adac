procedure main is
  procedure nested is
    module : Module_Type;
  begin
    Call;
    declare
      analysis : constant Result := Analyze (context, root);
    begin
      case analysis.status is
        when Rejected =>
          Fail (context);
          return;
        when Succeeded =>
          Log ("ok");
          module := Build (context, analysis.entity);
      end case;
    end;
    Next;
  end nested;
begin
  null;
end main;
