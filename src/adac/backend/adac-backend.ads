-- ============================================================================
-- adac-backend.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.IR;

package Adac.Backend is

  Operational_Error : exception;

  function emit
    (module      : Adac.IR.Module;
     output_path : String)
  return Boolean;

end Adac.Backend;
