`ifndef RDMA_SUBSYSTEM_SEQ_X070_SV
`define RDMA_SUBSYSTEM_SEQ_X070_SV

class seq_x070 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x070)

  function new(string name = "seq_x070");
    super.new(name);
    set_case_id("X070");
  endfunction
endclass

`endif
