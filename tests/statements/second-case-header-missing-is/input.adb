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
    declare
      result : constant Emission_Result := Emit (module, output_path);
    begin
      case result.status
        when Failed =>
          null;
      end case;
    end;
  end nested;
begin
  null;
end main;
