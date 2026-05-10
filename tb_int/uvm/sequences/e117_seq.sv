`ifndef RDMA_SUBSYSTEM_SEQ_E117_SV
`define RDMA_SUBSYSTEM_SEQ_E117_SV

class seq_e117 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e117)

  function new(string name = "seq_e117");
    super.new(name);
    set_case_id("E117");
  endfunction
endclass

`endif
