library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.ALL;
use work.m68k_pkg.all;

entity m68k_decoder is

    port (
        cpu_clk             : in std_logic;

        opcode              : in std_logic_vector(15 downto 0);
        addr                : out std_logic_vector(11 downto 0)

    );

end m68k_decoder;

architecture rtl of m68k_decoder is

    constant addr_dest_reg      : std_logic_vector(11 downto 0) := x"010";
    constant addr_dest_ea       : std_logic_vector(11 downto 0) := x"020";
    constant addr_one_op        : std_logic_vector(11 downto 0) := x"030";
    constant addr_imm           : std_logic_vector(11 downto 0) := x"040";
    constant addr_jmp           : std_logic_vector(11 downto 0) := x"050";
    constant addr_jsr           : std_logic_vector(11 downto 0) := x"060";
    constant addr_lea           : std_logic_vector(11 downto 0) := x"070";
    constant addr_movem2ea      : std_logic_vector(11 downto 0) := x"080";
    constant addr_movem2r       : std_logic_vector(11 downto 0) := x"090";
    constant addr_move_src      : std_logic_vector(11 downto 0) := x"0A0";
    constant addr_movea         : std_logic_vector(11 downto 0) := x"0B0";
    constant addr_move_sr       : std_logic_vector(11 downto 0) := x"0C0";
    constant addr_tas           : std_logic_vector(11 downto 0) := x"0D0";
    constant addr_pea           : std_logic_vector(11 downto 0) := x"0E0";
    constant addr_bit_static    : std_logic_vector(11 downto 0) := x"0F0";
    constant addr_bit_dynamic   : std_logic_vector(11 downto 0) := x"100";
    constant addr_imm_cmp       : std_logic_vector(11 downto 0) := x"110";
    constant addr_mem_shift     : std_logic_vector(11 downto 0) := x"120";
    constant addr_chk           : std_logic_vector(11 downto 0) := x"130";
    constant addr_alu_q         : std_logic_vector(11 downto 0) := x"140";
    constant addr_cmp_ea        : std_logic_vector(11 downto 0) := x"150";
    constant addr_move_dst      : std_logic_vector(11 downto 0) := x"160";
    constant addr_tst           : std_logic_vector(11 downto 0) := x"170";
    constant addr_move2sr       : std_logic_vector(11 downto 0) := x"180";
    constant addr_move2ccr      : std_logic_vector(11 downto 0) := x"190";
    constant addr_scc           : std_logic_vector(11 downto 0) := x"1A0";
    constant addr_div           : std_logic_vector(11 downto 0) := x"1B0";
    constant addr_cmpa          : std_logic_vector(11 downto 0) := x"1D0";
    constant addr_mul           : std_logic_vector(11 downto 0) := x"1E0";
    constant addr_an_dest       : std_logic_vector(11 downto 0) := x"1F0";
    constant addr_moveToUSP     : std_logic_vector(11 downto 0) := x"200";
    constant addr_moveFromUSP   : std_logic_vector(11 downto 0) := x"201";
    constant addr_imm2ccr       : std_logic_vector(11 downto 0) := x"202";
    constant addr_imm2sr        : std_logic_vector(11 downto 0) := x"203";
    constant addr_illegal       : std_logic_vector(11 downto 0) := x"204";
    constant addr_imm_shift     : std_logic_vector(11 downto 0) := x"206";
    constant addr_reg_shift     : std_logic_vector(11 downto 0) := x"20a";
    constant addr_movepR2M_L    : std_logic_vector(11 downto 0) := x"20b";
    constant addr_movepR2M_W    : std_logic_vector(11 downto 0) := x"20c";
    constant addr_movepM2R_L    : std_logic_vector(11 downto 0) := x"20d";
    constant addr_movepM2R_W    : std_logic_vector(11 downto 0) := x"20e";
    constant addr_nop           : std_logic_vector(11 downto 0) := x"207";
    constant addr_trace         : std_logic_vector(11 downto 0) := x"205";
    constant addr_trap          : std_logic_vector(11 downto 0) := x"208";
    constant addr_link          : std_logic_vector(11 downto 0) := x"209";
    constant addr_unlk          : std_logic_vector(11 downto 0) := x"210";
    constant addr_reset         : std_logic_vector(11 downto 0) := x"211";
    constant addr_stop          : std_logic_vector(11 downto 0) := x"212";
    constant addr_rts           : std_logic_vector(11 downto 0) := x"213";
    constant addr_rte           : std_logic_vector(11 downto 0) := x"214";
    constant addr_rtr           : std_logic_vector(11 downto 0) := x"215";
    constant addr_trapv         : std_logic_vector(11 downto 0) := x"216";
    constant addr_line1010      : std_logic_vector(11 downto 0) := x"218";
    constant addr_line1111      : std_logic_vector(11 downto 0) := x"219";
    constant addr_bra16         : std_logic_vector(11 downto 0) := x"220";
    constant addr_bra8          : std_logic_vector(11 downto 0) := x"221";
    constant addr_bsr8          : std_logic_vector(11 downto 0) := x"222";
    constant addr_bsr16         : std_logic_vector(11 downto 0) := x"223";
    constant addr_moveq         : std_logic_vector(11 downto 0) := x"226";
    constant addr_xR2R          : std_logic_vector(11 downto 0) := x"227";
    constant addr_xM2M          : std_logic_vector(11 downto 0) := x"230";
    constant addr_cmpm          : std_logic_vector(11 downto 0) := x"228";
    constant addr_exgD2D        : std_logic_vector(11 downto 0) := x"229";
    constant addr_exgD2A        : std_logic_vector(11 downto 0) := x"22a";
    constant addr_exgA2A        : std_logic_vector(11 downto 0) := x"22b";
    constant addr_bcc8          : std_logic_vector(11 downto 0) := x"240";
    constant addr_bcc16         : std_logic_vector(11 downto 0) := x"250";
    constant addr_dbcc          : std_logic_vector(11 downto 0) := x"260";
    constant addr_movem2ea_pd   : std_logic_vector(11 downto 0) := x"280";
    constant addr_movem2r_pi    : std_logic_vector(11 downto 0) := x"284";
    constant addr_movem2ea_dest : std_logic_vector(11 downto 0) := x"288";
    constant addr_movem2r_dest  : std_logic_vector(11 downto 0) := x"28c";
    constant addr_trap0         : std_logic_vector(11 downto 0) := x"290";
    constant addr_trap1and2     : std_logic_vector(11 downto 0) := x"300";
    constant addr_intHandler    : std_logic_vector(11 downto 0) := x"310";

    signal op_or_imm2ccr        : std_logic;
    signal op_or_imm2sr         : std_logic;
    signal op_or_imm            : std_logic;
    signal op_and_imm2ccr       : std_logic;
    signal op_and_imm2sr        : std_logic;
    signal op_and_imm           : std_logic;
    signal op_sub_imm           : std_logic;
    signal op_add_imm           : std_logic;
    signal op_btst              : std_logic;
    signal op_bchg              : std_logic;
    signal op_bclr              : std_logic;
    signal op_bset              : std_logic;
    signal op_eor_imm2ccr       : std_logic;
    signal op_eor_imm2sr        : std_logic;
    signal op_eor_imm           : std_logic;
    signal op_cmp_imm           : std_logic;
    signal op_invalid           : std_logic;
    signal op_movepR2M_L        : std_logic;
    signal op_movepR2M_W        : std_logic;
    signal op_movepM2R_L        : std_logic;
    signal op_movepM2R_W        : std_logic;
    signal op_btst_d            : std_logic;
    signal op_bchg_d            : std_logic;
    signal op_bclr_d            : std_logic;
    signal op_bset_d            : std_logic;
    signal op_movea_w           : std_logic;
    signal op_movea_l           : std_logic;
    signal op_move_b            : std_logic;
    signal op_move_w            : std_logic;
    signal op_move_l            : std_logic;
    signal op_move_sr           : std_logic;
    signal op_negx              : std_logic;
    signal op_move2sr           : std_logic;
    signal op_move2ccr          : std_logic;
    signal op_nbcd              : std_logic;
    signal op_swap              : std_logic;
    signal op_pea               : std_logic;
    signal op_ext               : std_logic;
    signal op_extB2W            : std_logic;
    signal op_extW2L            : std_logic;
    signal op_movem2ea          : std_logic;
    signal op_movem2ea_pd       : std_logic;
    signal op_movem2r           : std_logic;
    signal op_movem2r_pi        : std_logic;
    signal op_illegal           : std_logic;
    signal op_tas               : std_logic;
    signal op_trap              : std_logic;
    signal op_link              : std_logic;
    signal op_unlk              : std_logic;
    signal op_reset             : std_logic;
    signal op_nop               : std_logic;
    signal op_stop              : std_logic;
    signal op_rte               : std_logic;
    signal op_rts               : std_logic;
    signal op_trapv             : std_logic;
    signal op_rtr               : std_logic;
    signal op_jsr               : std_logic;
    signal op_jmp               : std_logic;
    signal op_chk               : std_logic;
    signal op_lea               : std_logic;
    signal op_tst               : std_logic;
    signal op_clr               : std_logic;
    signal op_neg               : std_logic;
    signal op_not               : std_logic;
    signal op_dbcc              : std_logic;
    signal op_scc               : std_logic;
    signal op_addq              : std_logic;
    signal op_addq_direct       : std_logic;
    signal op_subq              : std_logic;
    signal op_subq_direct       : std_logic;
    signal op_bra16             : std_logic;
    signal op_bra8              : std_logic;
    signal op_bsr16             : std_logic;
    signal op_bsr8              : std_logic;
    signal op_bcc16             : std_logic;
    signal op_bcc8              : std_logic;
    signal op_moveq             : std_logic;
    signal op_divu              : std_logic;
    signal op_divs              : std_logic;
    signal op_sbcd              : std_logic;
    signal op_sbcdR2R           : std_logic;
    signal op_sbcdM2M           : std_logic;
    signal op_orReg             : std_logic;
    signal op_orEA              : std_logic;
    signal op_subxR2R           : std_logic;
    signal op_subxM2M           : std_logic;
    signal op_suba              : std_logic;
    signal op_subReg            : std_logic;
    signal op_subEA             : std_logic;
    signal op_cmpm              : std_logic;
    signal op_eorEA             : std_logic;
    signal op_cmpa              : std_logic;
    signal op_cmp               : std_logic;
    signal op_mulu              : std_logic;
    signal op_muls              : std_logic;
    signal op_abcd              : std_logic;
    signal op_abcdR2R           : std_logic;
    signal op_abcdM2M           : std_logic;
    signal op_exg               : std_logic;
    signal op_exgD2D            : std_logic;
    signal op_exgA2A            : std_logic;
    signal op_exgD2A            : std_logic;
    signal op_andReg            : std_logic;
    signal op_andEA             : std_logic;
    signal op_addxR2R           : std_logic;
    signal op_addxM2M           : std_logic;
    signal op_adda              : std_logic;
    signal op_addReg            : std_logic;
    signal op_addEA             : std_logic;
    signal op_asr               : std_logic;
    signal op_asl               : std_logic;
    signal op_lsr               : std_logic;
    signal op_lsl               : std_logic;
    signal op_roxr              : std_logic;
    signal op_roxl              : std_logic;
    signal op_ror               : std_logic;
    signal op_rol               : std_logic;
    signal op_rasr              : std_logic;
    signal op_rasl              : std_logic;
    signal op_rlsr              : std_logic;
    signal op_rlsl              : std_logic;
    signal op_rroxr             : std_logic;
    signal op_rroxl             : std_logic;
    signal op_rror              : std_logic;
    signal op_rrol              : std_logic;
    signal op_iasr              : std_logic;
    signal op_iasl              : std_logic;
    signal op_ilsr              : std_logic;
    signal op_ilsl              : std_logic;
    signal op_iroxr             : std_logic;
    signal op_iroxl             : std_logic;
    signal op_iror              : std_logic;
    signal op_irol              : std_logic;
    signal op_moveToUSP         : std_logic;
    signal op_moveFromUSP       : std_logic;

    constant op_zero            : natural := 133;
    constant op_trueOrFalse     : natural := 134;
    constant op_shiftMem        : natural := 135;
    constant op_group0          : natural := 138;
    constant op_line1010        : natural := 139;
    constant op_line1111        : natural := 140;

    signal ea_data              : std_logic;
    signal ea_direct            : std_logic;
    signal ea_indirect          : std_logic;
    signal ea_post_inc          : std_logic;
    signal ea_pre_dec           : std_logic;
    signal ea_displ             : std_logic;
    signal ea_index             : std_logic;
    signal ea_abs_w             : std_logic;
    signal ea_abs_l             : std_logic;
    signal ea_pc_displ          : std_logic;
    signal ea_pc_index          : std_logic;
    signal ea_imm               : std_logic;

    -- signal decode_line_d        : decode_line_t;
    -- signal ea_line_d            : ea_line_t;
    signal op_movep             : std_logic;
    signal ea_addr_offset       :  std_logic_vector(3 downto 0);

    type pattern_t is array (15 downto 0) of character;

    impure function get_pattern(str : string) return pattern_t is
        variable res : pattern_t;
        variable idx : integer range 0 to 16;
    begin
        idx := 0;
        for i in str'range loop
            if (str(i) = '0' or str(i) = '1' or str(i) = '-') then
                res(idx) := str(i);
                idx := idx + 1;
            end if;
        end loop;
        return res;
    end get_pattern;


    impure function pattern_match (l : std_logic_vector; str : string) return std_ulogic is
        variable flag : boolean;
        variable r : pattern_t;
    begin
        r := get_pattern(str);
        flag := true;
        for i in l'range loop
            flag := flag and ((r(i)='-') or (r(i)='1' and l(i)='1') or (r(i)='0' and l(i)='0'));
        end loop;
        if flag then
            return '1';
        else
            return '0';
        end if;
    end pattern_match;

begin

    process (opcode) begin
        ea_addr_offset (2 downto 0) <= opcode(2 downto 0);
        if (opcode(5 downto 3) = "111") then
            ea_addr_offset(3) <= '1';
        else
            ea_addr_offset(3) <= '0';
        end if;
    end process;


    process (opcode) begin
        addr <= addr_illegal;
        case opcode(15 downto 14) is
            when "00" =>
                case opcode(13 downto 12) is
                    when "00" =>
                        if (opcode(8) = '1') then
                            if (opcode(5 downto 3) = "001") then
                                -- MOVEP
                                case opcode(7 downto 6) is
                                    when "00" =>
                                        addr <= addr_movepR2M_L;
                                    when "01" =>
                                        addr <= addr_movepR2M_W;
                                    when "10" =>
                                        addr <= addr_movepM2R_L;
                                    when others =>
                                        addr <= addr_movepM2R_W;
                                end case;
                            else
                                -- BTST, BCHG, BCLR, BSET
                                addr <= addr_bit_dynamic;
                            end if;
                        else
                            if (opcode(5 downto 3) = "111" and opcode(2 downto 0) = "100" and opcode(9) = '0') then
                                --to CCR, to SR
                                if (opcode(6) = '1') then
                                    addr <= addr_imm2sr;
                                else
                                    addr <= addr_imm2ccr;
                                end if;
                            else
                                case opcode(11 downto 9) is
                                    when "100" =>
                                        -- BTST, BCHG, BCLR, BSET
                                        addr <= addr_bit_static;
                                    when "110" =>
                                        --CMPI
                                        addr <= addr_imm_cmp(11 downto 4) & ea_addr_offset;
                                    when others =>
                                        -- ORI, ANDI, EORI
                                        addr <= addr_imm(11 downto 4) & ea_addr_offset;
                                end case;
                            end if;
                        end if;

                    when others =>
                        -- MOVEA, MOVE
                        case opcode(8 downto 6) is
                            when "001" =>
                                addr <= addr_movea;
                            when others =>
                                addr <= addr_move_src;
                        end case;

                end case;

            when "01" =>
                case opcode(13 downto 12) is
                    when "00" =>
                        case opcode(11 downto 8) is
                            when "1000" =>
                                --SWAP, PEA, EXT, NBCD, MOVEM*
                                case opcode(7 downto 6) is
                                    when "11" | "10" =>
                                        case opcode(5 downto 3) is
                                            when "000" =>
                                                --EXT
                                                addr <= addr_one_op(11 downto 4) & ea_addr_offset;
                                            when "100" =>
                                                --MOVEM pd
                                                addr <= addr_movem2ea_pd;
                                            when others =>
                                                --MOVEM
                                                addr <= addr_movem2ea(11 downto 4) & ea_addr_offset;
                                        end case;

                                    when "00" =>
                                        --NBCD
                                        addr <= addr_one_op(11 downto 4) & ea_addr_offset;

                                    when others =>
                                        if (opcode(5 downto 3) = "000") then
                                            --SWAP
                                            addr <= addr_one_op(11 downto 4) & ea_addr_offset;
                                        else
                                            --PEA
                                            addr <= addr_pea(11 downto 4) & ea_addr_offset;
                                        end if;

                                end case;


                            when "1010" =>
                                --ILLEGAL, TAS, TST
                                if (opcode (7 downto 6) = "11") then
                                    if (opcode(5 downto 0) = "1111000") then
                                        addr <= addr_illegal;
                                    else
                                        addr <= addr_tas(11 downto 4) & ea_addr_offset;
                                    end if;
                                else
                                    addr <= addr_tst(11 downto 4) & ea_addr_offset;
                                end if;

                            when "1110" =>
                                -- many
                                case opcode(7 downto 3) is
                                    when "01000" | "01001" =>
                                        -- trap
                                        addr <= addr_trap;
                                    when "01010" =>
                                        -- link
                                        addr <= addr_link;
                                    when "01011" =>
                                        -- unlink
                                        addr <= addr_unlk;
                                    when "01100" =>
                                        -- move to usp
                                        addr <= addr_moveToUSP;
                                    when "01101" =>
                                        -- move from usp
                                        addr <= addr_moveFromUSP;
                                    when "01110" =>
                                        -- reset, nop, stop, rte, rts, trapv, rtr
                                        case opcode(2 downto 0) is
                                            when "000" =>
                                                addr <= addr_reset;
                                            when "001" =>
                                                addr <= addr_nop;
                                            when "010" =>
                                                addr <= addr_stop;
                                            when "011" =>
                                                addr <= addr_rte;
                                            when "100" =>
                                                addr <= addr_illegal;
                                            when "101" =>
                                                addr <= addr_rts;
                                            when "110" =>
                                                addr <= addr_trapv;
                                            when "111" =>
                                                addr <= addr_reset;
                                            when others =>
                                                addr <= addr_rtr;
                                        end case;

                                    when others =>
                                        case opcode(7 downto 6) is
                                            when "10" =>
                                                --jsr
                                                addr <= addr_jsr(11 downto 4) & ea_addr_offset;
                                            when others =>
                                                --jmp
                                                addr <= addr_jmp(11 downto 4) & ea_addr_offset;
                                        end case;

                                end case;

                            when "1100" =>
                                if (opcode(5 downto 3) = "011") then
                                    --MOVEM pd
                                    addr <= addr_movem2r_pi;
                                else
                                    --MOVEM
                                    addr <= addr_movem2r(11 downto 4) & ea_addr_offset;
                                end if;

                            when others =>
                                if (opcode(8) = '0') then
                                    if (opcode (7 downto 6) = "11") then
                                        --MOVE to *
                                        case opcode(10 downto 8) is
                                            when "000" =>
                                                addr <= addr_move_sr;
                                            when "100" =>
                                                addr <= addr_move2ccr;
                                            when "110" =>
                                                addr <= addr_move2sr;
                                            when others =>
                                                null;
                                        end case;
                                    else
                                        --NEGX, CLR, NEG, NOT
                                        addr <= addr_one_op(11 downto 4) & ea_addr_offset;
                                    end if;
                                else
                                    --LEA, CHK
                                    if (opcode(6) = '1') then
                                        addr <= addr_lea(11 downto 4) & ea_addr_offset;
                                    else
                                        addr <= addr_chk(11 downto 4) & ea_addr_offset;
                                    end if;
                                end if;

                        end case;

                    when "01" =>
                        if (opcode(7 downto 6) = "11") then
                            --DBCC, SCC
                            if (opcode(5 downto 3) = "001") then
                                addr <= addr_dbcc;
                            else
                                addr <= addr_scc(11 downto 4) & ea_addr_offset;
                            end if;
                        else
                            --ADDQ, SUBQ
                            addr <= addr_alu_q(11 downto 4) & ea_addr_offset;
                        end if;

                    when "10" =>
                        case opcode(11 downto 8) is
                            -- BRA, BSR, Bcc
                            when "0000" =>
                                if opcode(7 downto 0) = "00000000" then
                                    addr <= addr_bra16;
                                else
                                    addr <= addr_bra8;
                                end if;
                            when "0001" =>
                                if opcode(7 downto 0) = "00000000" then
                                    addr <= addr_bsr16;
                                else
                                    addr <= addr_bsr8;
                                end if;
                            when others =>
                                if opcode(7 downto 0) = "00000000" then
                                    addr <= addr_bcc16;
                                else
                                    addr <= addr_bcc8;
                                end if;
                        end case;

                    when others =>
                        if (opcode(8) = '0') then
                            addr <= addr_moveq;
                        end if;

                end case;

            when "10" =>
                case opcode(8 downto 6) is
                    when "011" =>
                        --DIVU, MULU, SUBA*, CMPA
                    when "100" =>
                        --SBCD, ABCD
                    when "111" =>
                        --DIVS, MULS, SUBA*, CMPA
                    when others =>
                        if opcode(8) = '0' then
                            --OR REG
                        else
                            --OR EA
                        end if;
                end case;


            when others =>
                null;
        end case;

    end process;

    -- op_or_imm2ccr   <= pattern_match(opcode, "0000_000_000_111_100"); -- 0
    -- op_or_imm2sr    <= pattern_match(opcode, "0000_000_001_111_100");
    -- op_or_imm       <= pattern_match(opcode, "0000_000_0--_---_---");

    -- op_and_imm2ccr  <= pattern_match(opcode, "0000_001_000_111_100");
    -- op_and_imm2sr   <= pattern_match(opcode, "0000_001_001_111_100");
    -- op_and_imm      <= pattern_match(opcode, "0000_001_0--_---_---");
    -- op_sub_imm      <= pattern_match(opcode, "0000_010_0--_---_---");
    -- op_add_imm      <= pattern_match(opcode, "0000_011_0--_---_---");

    -- op_btst         <= pattern_match(opcode, "0000_100_000_---_---");
    -- op_bchg         <= pattern_match(opcode, "0000_100_001_---_---");
    -- op_bclr         <= pattern_match(opcode, "0000_100_010_---_---");
    -- op_bset         <= pattern_match(opcode, "0000_100_011_---_---");

    -- op_eor_imm2ccr  <= pattern_match(opcode, "0000_101_000_111_100");
    -- op_eor_imm2sr   <= pattern_match(opcode, "0000_101_001_111_100");
    -- op_eor_imm      <= pattern_match(opcode, "0000_101_0--_---_---");
    -- op_cmp_imm      <= pattern_match(opcode, "0000_110_0--_---_---");

    -- op_movep        <= pattern_match(opcode, "0000_---_1--_001_---");
    -- op_movepM2R_W   <= pattern_match(opcode, "0000_---_100_001_---");
    -- op_movepM2R_L   <= pattern_match(opcode, "0000_---_101_001_---");
    -- op_movepR2M_W   <= pattern_match(opcode, "0000_---_110_001_---");
    -- op_movepR2M_L   <= pattern_match(opcode, "0000_---_111_001_---");

    -- op_btst_d       <= pattern_match(opcode, "0000_---_100_---_---");
    -- op_bchg_d       <= pattern_match(opcode, "0000_---_101_---_---");
    -- op_bclr_d       <= pattern_match(opcode, "0000_---_110_---_---");
    -- op_bset_d       <= pattern_match(opcode, "0000_---_111_---_---");

    -- op_movea_w      <= pattern_match(opcode, "0011_---_001_---_---");
    -- op_movea_l      <= pattern_match(opcode, "0010_---_001_---_---");

    -- op_move_b       <= pattern_match(opcode, "0001_---_---_---_---");
    -- op_move_w       <= pattern_match(opcode, "0011_---_---_---_---");
    -- op_move_l       <= pattern_match(opcode, "0010_---_---_---_---");

    -- op_move_sr      <= pattern_match(opcode, "0100_000_011_---_---");
    -- op_negx         <= pattern_match(opcode, "0100_000_0--_---_---");
    -- op_clr          <= pattern_match(opcode, "0100_001_0--_---_---");
    -- op_move2ccr     <= pattern_match(opcode, "0100_010_011_---_---");
    -- op_neg          <= pattern_match(opcode, "0100_010_0--_---_---");
    -- op_move2sr      <= pattern_match(opcode, "0100_011_011_---_---");
    -- op_not          <= pattern_match(opcode, "0100_011_0--_---_---");
    -- op_nbcd         <= pattern_match(opcode, "0100_100_000_---_---");
    -- op_swap         <= pattern_match(opcode, "0100_100_001_000_---");
    -- op_pea          <= pattern_match(opcode, "0100_100_001_---_---");
    -- op_ext          <= pattern_match(opcode, "0100_100_01-_000_---");
    -- op_extB2W       <= pattern_match(opcode, "0100_100_010_000_---");
    -- op_extW2L       <= pattern_match(opcode, "0100_100_011_000_---");
    -- op_movem2ea_pd  <= pattern_match(opcode, "0100_100_01-_100_---");
    -- op_movem2ea     <= pattern_match(opcode, "0100_100_01-_---_---");
    -- op_illegal      <= pattern_match(opcode, "0100_101_011_111_100");
    -- op_tas          <= pattern_match(opcode, "0100_101_011_---_---");
    -- op_tst          <= pattern_match(opcode, "0100_101_0--_---_---");
    -- op_movem2r_pi   <= pattern_match(opcode, "0100_110_01-_011_---");
    -- op_movem2r      <= pattern_match(opcode, "0100_110_01-_---_---");
    -- op_trap         <= pattern_match(opcode, "0100_111_001_00-_---");
    -- op_link         <= pattern_match(opcode, "0100_111_001_010_---");
    -- op_unlk         <= pattern_match(opcode, "0100_111_001_011_---");
    -- op_moveToUSP    <= pattern_match(opcode, "0100_111_001_100_---");
    -- op_moveFromUSP  <= pattern_match(opcode, "0100_111_001_101_---");

    -- op_reset        <= pattern_match(opcode, "0100_111_001_110_000");
    -- op_nop          <= pattern_match(opcode, "0100_111_001_110_001");
    -- op_stop         <= pattern_match(opcode, "0100_111_001_110_010");
    -- op_rte          <= pattern_match(opcode, "0100_111_001_110_011");
    -- op_rts          <= pattern_match(opcode, "0100_111_001_110_101");
    -- op_trapv        <= pattern_match(opcode, "0100_111_001_110_110");
    -- op_rtr          <= pattern_match(opcode, "0100_111_001_110_111");

    -- op_jsr          <= pattern_match(opcode, "0100_111_010_---_---");
    -- op_jmp          <= pattern_match(opcode, "0100_111_011_---_---");
    -- op_chk          <= pattern_match(opcode, "0100_---_110_---_---");
    -- op_lea          <= pattern_match(opcode, "0100_---_111_---_---");

    -- op_dbcc         <= pattern_match(opcode, "0101_---_-11_001_---");
    -- op_scc          <= pattern_match(opcode, "0101_---_-11_---_---");
    -- op_addq_direct  <= pattern_match(opcode, "0101_---_0--_001_---");
    -- op_addq         <= pattern_match(opcode, "0101_---_0--_---_---");
    -- op_subq_direct  <= pattern_match(opcode, "0101_---_1--_001_---");
    -- op_subq         <= pattern_match(opcode, "0101_---_1--_---_---");

    -- op_asr          <= pattern_match(opcode, "1110_000_011_---_---");
    -- op_asl          <= pattern_match(opcode, "1110_000_111_---_---");
    -- op_lsr          <= pattern_match(opcode, "1110_001_011_---_---");
    -- op_lsl          <= pattern_match(opcode, "1110_001_111_---_---");
    -- op_roxr         <= pattern_match(opcode, "1110_010_011_---_---");
    -- op_roxl         <= pattern_match(opcode, "1110_010_111_---_---");
    -- op_ror          <= pattern_match(opcode, "1110_011_011_---_---");
    -- op_rol          <= pattern_match(opcode, "1110_011_111_---_---");

    -- op_iasr         <= pattern_match(opcode, "1110_---_0--_000_---");
    -- op_iasl         <= pattern_match(opcode, "1110_---_1--_000_---");
    -- op_ilsr         <= pattern_match(opcode, "1110_---_0--_001_---");
    -- op_ilsl         <= pattern_match(opcode, "1110_---_1--_001_---");
    -- op_iroxr        <= pattern_match(opcode, "1110_---_0--_010_---");
    -- op_iroxl        <= pattern_match(opcode, "1110_---_1--_010_---");
    -- op_iror         <= pattern_match(opcode, "1110_---_0--_011_---");
    -- op_irol         <= pattern_match(opcode, "1110_---_1--_011_---");

    -- op_rasr         <= pattern_match(opcode, "1110_---_0--_100_---");
    -- op_rasl         <= pattern_match(opcode, "1110_---_1--_100_---");
    -- op_rlsr         <= pattern_match(opcode, "1110_---_0--_101_---");
    -- op_rlsl         <= pattern_match(opcode, "1110_---_1--_101_---");
    -- op_rroxr        <= pattern_match(opcode, "1110_---_0--_110_---");
    -- op_rroxl        <= pattern_match(opcode, "1110_---_1--_110_---");
    -- op_rror         <= pattern_match(opcode, "1110_---_0--_111_---");
    -- op_rrol         <= pattern_match(opcode, "1110_---_1--_111_---");

    -- op_adda         <= pattern_match(opcode, "1101_---_-11_---_---");
    -- op_addReg       <= pattern_match(opcode, "1101_---_0--_---_---");
    -- op_addxR2R      <= pattern_match(opcode, "1101_---_1--_000_---");
    -- op_addxM2M      <= pattern_match(opcode, "1101_---_1--_001_---");
    -- op_addEA        <= pattern_match(opcode, "1101_---_1--_---_---");

    -- addr <=

    --     addr_mem_shift                                  when op_asr = '1' or
    --                                                          op_asl = '1' or
    --                                                          op_lsr = '1' or
    --                                                          op_lsl = '1' or
    --                                                          op_roxr = '1' or
    --                                                          op_roxl = '1' or
    --                                                          op_ror = '1' or
    --                                                          op_rol = '1' else
    --     addr_reg_shift                                  when op_rasr = '1' or
    --                                                          op_rasl = '1' or
    --                                                          op_rlsr = '1' or
    --                                                          op_rlsl = '1' or
    --                                                          op_rroxr = '1' or
    --                                                          op_rroxl = '1' or
    --                                                          op_rror = '1' or
    --                                                          op_rrol = '1' else
    --     addr_imm_shift                                  when op_iasr = '1' or
    --                                                          op_iasl = '1' or
    --                                                          op_ilsr = '1' or
    --                                                          op_ilsl = '1' or
    --                                                          op_iroxr = '1' or
    --                                                          op_iroxl = '1' or
    --                                                          op_iror = '1' or
    --                                                          op_irol = '1' else
    --     addr_bit_static(11 downto 4) & ea_addr_offset   when op_btst = '1' or
    --                                                          op_bchg = '1' or
    --                                                          op_bclr = '1' or
    --                                                          op_bset = '1' else

    --     addr_xR2R                                       when op_addxR2R = '1' else
    --     addr_xM2M                                       when op_addxM2M = '1' else

    --     addr_imm2ccr                                    when op_or_imm2ccr = '1' else
    --     addr_imm2sr                                     when op_or_imm2sr = '1' else
    --     addr_imm2ccr                                    when op_and_imm2ccr = '1' else
    --     addr_imm2sr                                     when op_and_imm2sr = '1' else
    --     addr_imm2ccr                                    when op_eor_imm2ccr = '1' else
    --     addr_imm2sr                                     when op_eor_imm2sr = '1' else
    --     addr_imm_cmp(11 downto 4) & ea_addr_offset      when op_cmp_imm = '1' else
    --     addr_movepR2M_L                                 when op_movepM2R_W = '1' else
    --     addr_movepR2M_W                                 when op_movepM2R_L = '1' else
    --     addr_movepM2R_L                                 when op_movepR2M_W = '1' else
    --     addr_movepM2R_W                                 when op_movepR2M_L = '1' else
    --     addr_bit_dynamic(11 downto 4) & ea_addr_offset  when op_btst_d = '1' or
    --                                                          op_bchg_d = '1' or
    --                                                          op_bclr_d = '1' or
    --                                                          op_bset_d = '1' else
    --     addr_movea(11 downto 4) & ea_addr_offset        when op_movea_w = '1' or
    --                                                          op_movea_l = '1' else
    --     addr_move_src(11 downto 4) & ea_addr_offset     when op_move_b = '1' or
    --                                                          op_move_w = '1' or
    --                                                          op_move_l = '1' else
    --     addr_move_sr                                    when op_move_sr = '1' else
    --     addr_move2ccr(11 downto 4) & ea_addr_offset     when op_move2ccr = '1' else
    --     addr_move2sr(11 downto 4) & ea_addr_offset      when op_move2sr = '1' else
    --     addr_pea(11 downto 4) & ea_addr_offset          when op_pea = '1' else
    --     addr_movem2ea_pd                                when op_movem2ea_pd = '1' else
    --     addr_movem2ea(11 downto 4) & ea_addr_offset     when op_movem2ea = '1' else
    --     addr_illegal                                    when op_illegal = '1' else
    --     addr_tas(11 downto 4) & ea_addr_offset          when op_tas = '1' else
    --     addr_tst(11 downto 4) & ea_addr_offset          when op_tst = '1' else
    --     addr_movem2r(11 downto 4) & ea_addr_offset      when op_movem2r = '1' else
    --     addr_movem2r_pi                                 when op_movem2r_pi = '1' else
    --     addr_trap                                       when op_trap = '1' else
    --     addr_link                                       when op_link = '1' else
    --     addr_unlk                                       when op_unlk = '1' else
    --     addr_reset                                      when op_reset = '1' else
    --     addr_nop                                        when op_nop = '1' else
    --     addr_stop                                       when op_stop = '1' else
    --     addr_rte                                        when op_rte = '1' else
    --     addr_rts                                        when op_rts = '1' else
    --     addr_trapv                                      when op_trapv = '1' else
    --     addr_rtr                                        when op_rtr = '1' else
    --     addr_one_op(11 downto 4) & ea_addr_offset       when op_negx = '1' or
    --                                                          op_nbcd = '1' or
    --                                                          op_swap = '1' or
    --                                                          op_extB2W = '1' or
    --                                                          op_extW2L = '1' or
    --                                                          op_clr = '1' or
    --                                                          op_neg = '1' or
    --                                                          op_not = '1' else
    --     addr_jsr(11 downto 4) & ea_addr_offset          when op_jsr = '1' else
    --     addr_jmp(11 downto 4) & ea_addr_offset          when op_jmp = '1' else
    --     addr_chk(11 downto 4) & ea_addr_offset          when op_chk = '1' else
    --     addr_lea(11 downto 4) & ea_addr_offset          when op_lea = '1' else
    --     addr_dbcc                                       when op_dbcc = '1' else
    --     addr_scc(11 downto 4) & ea_addr_offset          when op_scc = '1' else
    --     addr_imm(11 downto 4) & ea_addr_offset          when op_or_imm = '1'  or
    --                                                          op_and_imm = '1' or
    --                                                          op_sub_imm = '1' or
    --                                                          op_add_imm = '1' or
    --                                                          op_eor_imm = '1' else


    --     addr_illegal;


end architecture;