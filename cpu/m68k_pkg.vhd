--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes,
--		 constants, and functions
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;
use UNISIM.VComponents.all;

package m68k_pkg is

    subtype m68k_register_t is unsigned(31 downto 0);

    subtype m68k_nibble_t is unsigned(3 downto 0);

    type m68k_nibble_with_carry_t is record
        val : m68k_nibble_t;
        c   : std_logic;
    end record;

    constant FL_Z : natural := 0;
    constant FL_C : natural := 0;
    constant FL_X : natural := 0;
    constant FL_V : natural := 0;
    constant FL_N : natural := 0;

    subtype m68k_flags_t is std_logic_vector(5 downto 0);

    type m68k_size_t is (
        M68K_BYTE, M68K_WORD, M68K_LONG, M68K_ANY
    );
    attribute enum_encoding : string;
    attribute enum_encoding of m68k_size_t : type is "00 01 10 11";

    type m68k_cond_t is (
        M68K_TRUE, M68K_FALSE, M68K_HI, M68K_LS, M68K_CC,
        M68K_CS, M68K_NE, M68K_EQ, M68K_VC, M68K_VS, M68K_PL,
        M68K_MI, M68K_GE, M68K_LT, M68K_GT, M68K_LE);

    type m68k_control_flow_t is (
        M68K_NEXT, M68K_CHECK_PRIV, M68K_LOCK_BUS, M68K_LEAVE_EXCEPTION,
        M68K_CHECK_TRAP_V, M68K_CHECK_CHK, M68K_MOVE_JUMP, M68K_IF_COND,
        M68K_CHECK_DIV, M68K_LOOP_MOVEM, M68K_LOOP_DC, M68K_WAIT,
        M68K_RESET, M68K_RAISE_EXCEPTION, M68K_CHECK_TRACE, M68K_ILLEGAL
    );

    type m68k_mem_src_t is (
        M68K_PC, M68K_ACC, M68K_OCC, M68K_TMP1, M68K_SR, M68K_SCC, M68K_TMP2,
        M68K_TMP1_31_DOWNTO_24, M68K_TMP1_23_DOWNTO_16,
        M68K_TMP1_15_DOWNTO_8, M68K_TMP1_7_DOWNTO_0,
        M68K_ISA, M68K_BCC, M68K_EADDR, M68K_EIR, M68K_ESW
    );

    type m68k_addr_type_t is (
        M68K_EA, M68K_PC, M68K_ACC, M68K_TMP1, M68K_TMP2, M68K_TRAP_VECTOR
    );

    type m68k_mem_cmd_t is record
        cmd_read     : boolean;
        imm_flag     : boolean;
        cmd_write    : boolean;
        address      : m68k_addr_type_t;
        source       : m68k_mem_src_t;
        size         : m68k_size_t;
    end record;

    type m68k_pc_src_t is (
        M68K_ZERO, M68K_PC_PLUS_2, M68K_PC_PLUS_4, M68K_MEM,
        M68K_TMP1, M68K_ACC, M68K_DBCC_ADDR, M68K_PC_PLUS_SIZE
    );

    type m68k_transfer_pc_cmd_t is record
        en          : boolean;
        source      : m68k_pc_src_t;
    end record;

    type m68k_tmp1_source_t is (
        M68K_ACC, M68K_RF, M68K_MEM, M68K_PC,
        M68K_MOVEQ, M68K_SIGN_EXT, M68K_COND_OP, M68K_ALUQ
    );

    type m68k_transfer_tmp1_cmd_t is record
        en          : boolean;
        source      : m68k_tmp1_source_t;
    end record;

    type m68k_tmp2_source_t is (
        M68K_SR, M68K_SIZE, M68K_TMP3, M68K_DISPL_8, M68K_DISPL_VAL, M68K_RF,
        M68K_SIGN_EXT, M68K_MEM, M68K_SET_2, M68K_SET_4, M68K_SET_1, M68K_SET_0
    );

    type m68k_transfer_tmp2_cmd_t is record
        en          : boolean;
        source      : m68k_tmp2_source_t;
    end record;

    type m68k_tmp3_source_t is (
        M68K_TMP1, M68K_MEM, M68K_READ_31_DOWNTO_24, M68K_READ_24_DOWNTO_16,
        M68K_READ_15_DOWNTO_8, M68K_READ_7_DOWNTO_0, M68K_ERROR_VECTOR
    );

    type m68k_transfer_tmp3_cmd_t is record
        en          : boolean;
        source      : m68k_tmp3_source_t;
    end record;

    type m68k_ea_source_t is (
        M68K_TMP1, M68K_TMP2, M68K_ACC, M68K_PC
    );

    type m68k_transfer_ea_cmd_t is record
        en          : boolean;
        source      : m68k_ea_source_t;
    end record;

    type m68k_transfer_instr_cmd_t is record
        en          : boolean;
    end record;

    type m68k_alu_func_t is (
        M68K_NOP, M68K_ADDL, M68K_SUBL, M68K_ALUD
    );

    type m68k_alu_op_t is (
        M68K_ADD, M68K_ADDX, M68K_SUB, M68K_CMP, M68K_CMPA,
        M68K_SUBX, M68K_AND, M68K_OR, M68K_EOR, M68K_ABCD,
        M68K_SBCD, M68K_MULU, M68K_MULS
    );

    type m68k_alu_cmd_t is record
        --en : boolean; ?
        func : m68k_alu_func_t;
    end record;

    type m68k_reg_no_t is (
        M68K_AN1, M68K_AND2, M68K_DN1, M68K_DN2,
        M68K_SP_NO, M68K_DISPL_RN, M68K_MOVEM_RN,
        M68K_SSP_NO, M68K_USP_NO, M68K_MOVEM_RN_REV
    );

    type m68k_rf_source_t is (
        M68K_ACC, M68K_TMP1, M68K_OCC, M68K_SCC,
        M68K_BCC, M68K_TMP2, M68K_DCC, M68K_TMP3
    );

    type m68k_rf_cmd_t is record
        cmd_read        : boolean;
        cmd_write       : boolean;
        rn              : m68k_reg_no_t;
        size            : m68k_size_t;
        source          : m68k_rf_source_t;
    end record;

    type m68k_sr_source_t is (
        M68K_ALU_FLAGS, M68K_ONE_FLAGS, M68K_SHF_FLAGS, M68K_BIT_FLAGS,
        M68K_DIV_FLAGS, M68K_CHK_FLAGS, M68K_MOV_FLAGS,
        M68K_SET_SR, M68K_SET_CCR, M68K_SET_TRC_OFF, M68K_SET_IPL,
        M68K_SET_SVR, M68K_SET_OVF
    );

    type m68k_transfer_sr_cmd_t is record
        en : boolean;
        source : m68k_sr_source_t;
    end record;

    type m68k_sign_ext_op_t is (
        M68K_EXT_B2W, M68K_EXT_W2L, M68K_EXT_W2LC, M68K_EXT_AN
    );

    type m68k_bit_number_source_t is (
        M68K_BIT_NUM_8, M68K_TMP2
    );

    type m68k_bn_cmd_t is record
        load            : boolean;
        source          : m68k_bit_number_source_t;
    end record;

    type m68k_dc_source_t is (
        M68K_X01, M68K_X1F, M68K_SHIFT_COUNT, M68K_TMP2
    );

    type m68k_dc_cmd_t is record
        load            : boolean;
        count_down      : boolean;
        source          : m68k_dc_source_t;
    end record;

    type m68k_trap_vector_cmd_t is (
        M68K_KEEP, M68K_X10, M68K_X14, M68K_X18, M68K_X1C,
        M68K_X20, M68K_X24, M68K_X28, M68K_X2C, M68K_TRAP, M68K_INTR
    );

    type m68k_move_flags_source_t is (
        M68K_MOVEQ, M68K_TMP1
    );

    type m68k_micro_command_t is record
        flow_cmd        : m68k_control_flow_t;
        decode          : boolean;
        mem_cmd         : m68k_mem_cmd_t;
        rf_cmd          : m68k_rf_cmd_t;
        transfer_pc     : m68k_transfer_pc_cmd_t;
        transfer_tmp1   : m68k_transfer_tmp1_cmd_t;
        transfer_tmp2   : m68k_transfer_tmp2_cmd_t;
        transfer_tmp3   : m68k_transfer_tmp3_cmd_t;
        transfer_ea     : m68k_transfer_ea_cmd_t;
        transfer_instr  : m68k_transfer_instr_cmd_t;
        transfer_sr     : m68k_transfer_sr_cmd_t;
        transfer_bn     : m68k_bn_cmd_t;
        transfer_dc     : m68k_dc_cmd_t;
        alu             : m68k_alu_cmd_t;
        displ_word      : boolean;
        movem_word      : boolean;
        sign_ext_op     : m68k_sign_ext_op_t;
        trap_vector_cmd : m68k_trap_vector_cmd_t;
    end record;


end m68k_pkg;

package body m68k_pkg is


end m68k_pkg;
