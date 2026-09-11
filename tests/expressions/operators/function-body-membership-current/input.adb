package body Parent.Child is
  function Keep
    (form : Loop_Statement_Form)
  return Loop_Statement_Form is
  begin
    if form not in
      Discrete_Range_Loop_Form | Generalized_Iterator_Loop_Form
    then
      Helper.Call;
    end if;
    return form;
  end Keep;
end Parent.Child;
