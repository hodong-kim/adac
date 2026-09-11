package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    procedure Touch is
      alias : Integer renames value;
      procedure P1 is
        alias : Integer renames value;
        procedure P2 is
          alias : Integer renames value;
          procedure P3 is
            alias : Integer renames value;
            procedure P4 is
              alias : Integer renames value;
              procedure P5 is
                alias : Integer renames value;
                procedure P6 is
                  alias : Integer renames value;
                  procedure P7 is
                    alias : Integer renames value;
                    procedure P8 is
                      alias : Integer renames value;
                      procedure P9 is
                        alias : Integer renames value;
                        procedure P10 is
                          alias : Integer renames value;
                          procedure P11 is
                            alias : Integer renames value;
                            procedure P12 is
                              alias : Integer renames value;
                              procedure P13 is
                                alias : Integer renames value;
                                procedure P14 is
                                  alias : Integer renames value;
                                  procedure P15 is
                                    alias : Integer renames value;
                                    procedure P16 is
                                      alias : Integer renames value;
                                      procedure P17 is
                                        alias : Integer renames value;
                                        procedure P18 is
                                          alias : Integer renames value;
                                          procedure P19 is
                                            alias : Integer renames value;
                                            procedure P20 is
                                              alias : Integer renames value;
                                              procedure P21 is
                                                alias : Integer renames value;
                                                procedure P22 is
                                                  alias : Integer renames value;
                                                  procedure P23 is
                                                    alias : Integer renames value;
                                                    procedure P24 is
                                                      alias : Integer renames value;
                                                      procedure P25 is
                                                        alias : Integer renames value;
                                                        procedure P26 is
                                                          alias : Integer renames value;
                                                          procedure P27 is
                                                            alias : Integer renames value;
                                                            procedure P28 is
                                                              alias : Integer renames value;
                                                              procedure P29 is
                                                                alias : Integer renames value;
                                                                procedure P30 is
                                                                  alias : Integer renames value;
                                                                  procedure P31 is
                                                                    alias : Integer renames value;
                                                                    procedure P32 is
                                                                      alias : Integer renames value;
                                                                      begin
                                                                        null;
                                                                    end P32;
                                                                    begin
                                                                      null;
                                                                  end P31;
                                                                  begin
                                                                    null;
                                                                end P30;
                                                                begin
                                                                  null;
                                                              end P29;
                                                              begin
                                                                null;
                                                            end P28;
                                                            begin
                                                              null;
                                                          end P27;
                                                          begin
                                                            null;
                                                        end P26;
                                                        begin
                                                          null;
                                                      end P25;
                                                      begin
                                                        null;
                                                    end P24;
                                                    begin
                                                      null;
                                                  end P23;
                                                  begin
                                                    null;
                                                end P22;
                                                begin
                                                  null;
                                              end P21;
                                              begin
                                                null;
                                            end P20;
                                            begin
                                              null;
                                          end P19;
                                          begin
                                            null;
                                        end P18;
                                        begin
                                          null;
                                      end P17;
                                      begin
                                        null;
                                    end P16;
                                    begin
                                      null;
                                  end P15;
                                  begin
                                    null;
                                end P14;
                                begin
                                  null;
                              end P13;
                              begin
                                null;
                            end P12;
                            begin
                              null;
                          end P11;
                          begin
                            null;
                        end P10;
                        begin
                          null;
                      end P9;
                      begin
                        null;
                    end P8;
                    begin
                      null;
                  end P7;
                  begin
                    null;
                end P6;
                begin
                  null;
              end P5;
              begin
                null;
            end P4;
            begin
              null;
          end P3;
          begin
            null;
        end P2;
        begin
          null;
      end P1;
    begin
      Helper.Call;
    end Touch;
  begin
    return value;
  end Wrap;
end Parent.Child;
