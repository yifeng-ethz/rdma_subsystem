`ifndef RDMA_SUBSYSTEM_SEQ_X072_SV
`define RDMA_SUBSYSTEM_SEQ_X072_SV

class seq_x072 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x072)

  function new(string name = "seq_x072");
    super.new(name);
    set_case_id("X072");
  endfunction
endclass

`endif
