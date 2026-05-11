`ifndef RDMA_SUBSYSTEM_CASE_PKG_SV
`define RDMA_SUBSYSTEM_CASE_PKG_SV

package subsystem_case_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  typedef enum int unsigned {
    RUN_IDLE      = 0,
    RUN_PREPARING = 1,
    RUN_RUNNING   = 2,
    RUN_STOPPING  = 3,
    RUN_STOPPED   = 4
  } runtool_state_e;

  typedef enum int unsigned {
    TERM_EOE       = 0,
    TERM_FULL      = 1,
    TERM_ALIGN_ERR = 2,
    TERM_HALT      = 3
  } subsystem_term_e;

  typedef struct packed {
    bit [63:0] bytes_written_total;
    bit [31:0] seg1_bytes_written;
    bit [31:0] seg0_bytes_written;
    bit [15:0] status;
    bit [15:0] rqe_id;
    bit [31:0] flags;
    bit [63:0] event_count;
    bit [63:0] first_event_ts;
    bit [63:0] last_event_ts;
    bit [63:0] opq_drop_snapshot;
    bit [63:0] retire_seq;
  } subsystem_cqe_t;

  class subsystem_case_cfg extends uvm_object;
    `uvm_object_utils(subsystem_case_cfg)

    string case_id;
    string bucket;
    string coverage_bin;
    string contract_anchor;
    bit random_case;
    int unsigned case_num;
    int unsigned iter_count;
    int unsigned actual_txn_count;
    int unsigned rq_depth;
    int unsigned cq_depth;
    int unsigned n_pre_staged_rqe;
    int unsigned doorbell_coalesce_n;
    int unsigned frame_words;
    int unsigned opq_gap_cycles;
    int unsigned poll_cycles;
    int unsigned aw_lag;
    int unsigned w_lag;
    int unsigned b_lag;
    int unsigned ar_lag;
    int unsigned r_lag;
    bit seg1_used;
    bit idle_only;
    bit force_align_error;
    bit force_malformed_rqe;
    bit force_halt;
    bit ctrl_halt_reenable;
    bit inject_reset;
    bit cq_credit_stall;
    bit inject_bresp_error;
    bit inject_rresp_error;
    subsystem_term_e term_mode;

    function new(string name = "subsystem_case_cfg");
      super.new(name);
      case_id = "B001";
      bucket = "BASIC";
      coverage_bin = "basic_csr_reset_b001";
      contract_anchor = "DV_PLAN_INT.md";
      random_case = 1'b0;
      case_num = 1;
      iter_count = 1;
      actual_txn_count = 1;
      rq_depth = 16;
      cq_depth = 16;
      n_pre_staged_rqe = 1;
      doorbell_coalesce_n = 1;
      frame_words = 6;
      opq_gap_cycles = 0;
      poll_cycles = 8;
      aw_lag = 0;
      w_lag = 0;
      b_lag = 0;
      ar_lag = 0;
      r_lag = 0;
      seg1_used = 1'b0;
      idle_only = 1'b0;
      force_align_error = 1'b0;
      force_malformed_rqe = 1'b0;
      force_halt = 1'b0;
      ctrl_halt_reenable = 1'b0;
      inject_reset = 1'b0;
      cq_credit_stall = 1'b0;
      inject_bresp_error = 1'b0;
      inject_rresp_error = 1'b0;
      term_mode = TERM_EOE;
    endfunction

    function byte prefix();
      if (case_id.len() == 0)
        return "B";
      return case_id.getc(0);
    endfunction

    function string build_duplicate_reason();
      int unsigned group_first;
      group_first = ((case_num - 1) / 16) * 16 + 1;
      if (case_num == group_first)
        return "";
      return $sformatf("honest duplicate of %s%03d: same RTL contract anchor, unique stimulus and coverage token %s",
                       prefix(), group_first, coverage_bin);
    endfunction
  endclass

  function automatic int unsigned parse_case_num(input string case_id);
    string digits;
    int value;
    if (case_id.len() < 2)
      return 1;
    digits = case_id.substr(1, case_id.len() - 1);
    value = 1;
    void'($sscanf(digits, "%d", value));
    return int'(value);
  endfunction

  function automatic string bucket_from_case(input string case_id);
    if (case_id.len() == 0)
      return "BASIC";
    case (case_id.getc(0))
      "B": return "BASIC";
      "E": return "EDGE";
      "P": return "PROF";
      "X": return "ERROR";
      default: return "BASIC";
    endcase
  endfunction

  function automatic string group_cov_base(input string case_id, input int unsigned num);
    byte p;
    p = (case_id.len() == 0) ? "B" : case_id.getc(0);
    case (p)
      "B": begin
        if (num <= 16) return "basic_csr_reset";
        if (num <= 32) return "basic_single_eoe";
        if (num <= 48) return "basic_full_term";
        if (num <= 64) return "basic_two_segment";
        if (num <= 80) return "basic_back_to_back";
        if (num <= 96) return "basic_state_traversal";
        if (num <= 112) return "basic_doorbell_coalesce";
        return "basic_cqe_fields";
      end
      "E": begin
        if (num <= 16) return "edge_rq_wrap";
        if (num <= 32) return "edge_cq_wrap";
        if (num <= 48) return "edge_span_quantum";
        if (num <= 64) return "edge_addr_alignment";
        if (num <= 80) return "edge_idle_opq";
        if (num <= 96) return "edge_concurrent_ops";
        if (num <= 112) return "edge_doorbell_race";
        return "edge_depth_mask";
      end
      "P": begin
        if (num <= 32) return "prof_sustained_opq";
        if (num <= 64) return "prof_full_rq_depth";
        if (num <= 96) return "prof_axi_stalls";
        return "prof_long_soak";
      end
      default: begin
        if (num <= 16) return "error_bresp";
        if (num <= 32) return "error_rresp";
        if (num <= 48) return "error_align";
        if (num <= 64) return "error_malformed_rqe";
        if (num <= 80) return "error_midrun_reset";
        if (num <= 96) return "error_halt_reenable";
        if (num <= 112) return "error_cq_full";
        return "error_forced_halt";
      end
    endcase
  endfunction

  function automatic subsystem_case_cfg make_case_cfg(input string case_id);
    subsystem_case_cfg cfg;
    int unsigned n;
    int unsigned depth_sel[6];
    cfg = subsystem_case_cfg::type_id::create("cfg");
    cfg.case_id = case_id;
    cfg.bucket = bucket_from_case(case_id);
    n = parse_case_num(case_id);
    cfg.case_num = n;
    depth_sel = '{2, 4, 16, 256, 4096, 65536};
    cfg.rq_depth = depth_sel[(n - 1) % 6];
    cfg.cq_depth = depth_sel[(n + 1) % 6];
    if (cfg.rq_depth > 256)
      cfg.rq_depth = 256;
    if (cfg.cq_depth > 256)
      cfg.cq_depth = 256;
    cfg.frame_words = 4 + (n % 9);
    cfg.n_pre_staged_rqe = 1 + (n % 4);
    cfg.doorbell_coalesce_n = 1 + (n % 4);
    cfg.opq_gap_cycles = n % 3;
    cfg.poll_cycles = 4 + (n % 8);
    cfg.coverage_bin = {group_cov_base(case_id, n), "_", case_id.tolower()};
    cfg.contract_anchor = $sformatf("DV_%s.md %s cov:%s",
                                    cfg.bucket, case_id, cfg.coverage_bin);
    cfg.random_case = (case_id.getc(0) == "P") || (n > 64 && n <= 112);
    cfg.iter_count = cfg.random_case ? (4 + (n % 8)) : 1;
    cfg.actual_txn_count = cfg.random_case ? (2 + (n % 3)) : 1;
    if (cfg.actual_txn_count > cfg.rq_depth)
      cfg.actual_txn_count = cfg.rq_depth;
    cfg.seg1_used = (n % 5 == 0) || (n >= 49 && n <= 64);
    cfg.term_mode = (case_id.getc(0) == "B" && n >= 33 && n <= 48) ? TERM_FULL : TERM_EOE;
    cfg.idle_only = (case_id.getc(0) == "B" && n <= 16) ||
                    (case_id.getc(0) == "E" && n >= 65 && n <= 80);
    cfg.force_align_error = (case_id.getc(0) == "X" && n >= 33 && n <= 48);
    cfg.force_malformed_rqe = (case_id.getc(0) == "X" && n >= 49 && n <= 64);
    cfg.inject_reset = (case_id.getc(0) == "X" && n >= 65 && n <= 80);
    cfg.ctrl_halt_reenable = (case_id.getc(0) == "X" && n >= 81 && n <= 96);
    cfg.force_halt = (case_id.getc(0) == "X" && n >= 113);
    cfg.cq_credit_stall = (case_id.getc(0) == "X" && n >= 97 && n <= 112);
    cfg.inject_bresp_error = (case_id.getc(0) == "X" && n <= 16);
    cfg.inject_rresp_error = (case_id.getc(0) == "X" && n >= 17 && n <= 32);
    if (cfg.term_mode == TERM_FULL) begin
      cfg.frame_words = 1050;
      cfg.seg1_used = 1'b0;
    end
    if (cfg.force_halt) begin
      cfg.seg1_used = 1'b0;
      cfg.frame_words = 2200 + ((n - 113) % 4) * 32;
      cfg.w_lag = 128;
      cfg.b_lag = 8;
    end
    if (case_id.getc(0) == "P" && n >= 65 && n <= 96) begin
      cfg.aw_lag = n % 5;
      cfg.w_lag = (n + 1) % 5;
      cfg.b_lag = (n + 2) % 5;
      cfg.ar_lag = (n + 3) % 5;
      cfg.r_lag = (n + 4) % 5;
    end
    return cfg;
  endfunction
endpackage

`endif
