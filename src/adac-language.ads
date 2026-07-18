-- ============================================================================
-- adac-language.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package Adac.Language is

  type Options is record
    case_sensitive_identifiers : Boolean := False;
  end record;

end Adac.Language;
