-- ============================================================================
-- adac-backend.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Strings.Unbounded;

with Adac.IR;

package Adac.Backend is

  type Emission_Status is
    (Emission_Operational_Failure,
     Emission_Succeeded);

  type Emission_Result
    (status : Emission_Status := Emission_Operational_Failure)
  is private;

  --! summary
  --!   Emits and publishes the requested backend output.
  --! contract
  --!   `Emission_Operational_Failure` reports an external system failure that
  --!   prevented publication. Internal contract violations propagate as
  --!   exceptions.
  --! ownership
  --!   The operation borrows `module` and does not retain `output_path`.
  function emit
    (module      : Adac.IR.Module;
     output_path : String)
  return Emission_Result;

  --! contract
  --!   `result.status` must be `Emission_Operational_Failure`.
  function failure_message (result : Emission_Result) return String
    with pre => result.status = Emission_Operational_Failure;

private

  Operational_Error : exception;

  type Emission_Result
    (status : Emission_Status := Emission_Operational_Failure)
  is record
    case status is
      when Emission_Operational_Failure =>
        diagnostic : Ada.Strings.Unbounded.Unbounded_String;

      when Emission_Succeeded =>
        null;
    end case;
  end record;

end Adac.Backend;
