-- ============================================================================
-- adac-support.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package body Adac.Support is

  function image (value : Natural) return String is
    raw : constant String := Natural'image (value);
  begin
    return raw(raw'first + 1 .. raw'last);
  end image;

end Adac.Support;
