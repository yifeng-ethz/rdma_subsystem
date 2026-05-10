`ifndef RDMA_SUBSYSTEM_COVERAGE_SV
`define RDMA_SUBSYSTEM_COVERAGE_SV

class subsystem_coverage extends uvm_component;
  `uvm_component_utils(subsystem_coverage)

  int unsigned case_num_cp;
  int unsigned bucket_cp;
  int unsigned sq_depth_cp;
  int unsigned cq_depth_cp;
  int unsigned seg_mode_cp;
  int unsigned term_mode_cp;
  int unsigned axi_profile_cp;
  int unsigned debug_level_cp;
  int unsigned state_cp;

  covergroup cg_case;
    option.per_instance = 1;
    cp_bucket: coverpoint bucket_cp {
      bins basic = {0};
      bins edge_bucket = {1};
      bins prof = {2};
      bins error = {3};
    }
    cp_case_group: coverpoint case_num_cp {
      bins g0 = {[1:16]};
      bins g1 = {[17:32]};
      bins g2 = {[33:48]};
      bins g3 = {[49:64]};
      bins g4 = {[65:80]};
      bins g5 = {[81:96]};
      bins g6 = {[97:112]};
      bins g7 = {[113:128]};
    }
    cp_sq_depth: coverpoint sq_depth_cp {
      bins d2 = {2};
      bins d4 = {4};
      bins d16 = {16};
      bins d256 = {256};
    }
    cp_cq_depth: coverpoint cq_depth_cp {
      bins d2 = {2};
      bins d4 = {4};
      bins d16 = {16};
      bins d256 = {256};
    }
    cp_seg: coverpoint seg_mode_cp {
      bins single_seg = {0};
      bins two_seg = {1};
    }
    cp_term: coverpoint term_mode_cp {
      bins eoe = {0};
      bins full = {1};
      bins align_err = {2};
      bins halt = {3};
    }
    cp_axi: coverpoint axi_profile_cp {
      bins none = {0};
      bins read = {1};
      bins write = {2};
      bins mixed = {3};
      bins error_resp = {4};
    }
    cp_debug: coverpoint debug_level_cp {
      bins dbg1 = {1};
      bins dbg2 = {2};
    }
    cross_bucket_term: cross cp_bucket, cp_term;
    cross_seg_term: cross cp_seg, cp_term;
    cross_depths: cross cp_sq_depth, cp_cq_depth;
    cross_debug_bucket: cross cp_debug, cp_bucket;
  endgroup

  covergroup cg_state;
    option.per_instance = 1;
    cp_state: coverpoint state_cp {
      bins idle = {0};
      bins preparing = {1};
      bins running = {2};
      bins stopping = {3};
      bins stopped = {4};
    }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_case = new();
    cg_state = new();
  endfunction

  function void sample_case(subsystem_case_cfg cfg, int unsigned debug_level);
    case_num_cp = cfg.case_num;
    case (cfg.bucket)
      "BASIC": bucket_cp = 0;
      "EDGE": bucket_cp = 1;
      "PROF": bucket_cp = 2;
      default: bucket_cp = 3;
    endcase
    sq_depth_cp = cfg.sq_depth;
    cq_depth_cp = cfg.cq_depth;
    seg_mode_cp = cfg.seg1_used ? 1 : 0;
    term_mode_cp = cfg.term_mode;
    if (cfg.inject_bresp_error || cfg.inject_rresp_error)
      axi_profile_cp = 4;
    else if ((cfg.aw_lag | cfg.w_lag | cfg.b_lag) != 0 && (cfg.ar_lag | cfg.r_lag) != 0)
      axi_profile_cp = 3;
    else if ((cfg.aw_lag | cfg.w_lag | cfg.b_lag) != 0)
      axi_profile_cp = 2;
    else if ((cfg.ar_lag | cfg.r_lag) != 0)
      axi_profile_cp = 1;
    else
      axi_profile_cp = 0;
    debug_level_cp = debug_level;
    cg_case.sample();
  endfunction

  function void sample_state(runtool_state_e state);
    state_cp = state;
    cg_state.sample();
  endfunction
endclass

`endif
