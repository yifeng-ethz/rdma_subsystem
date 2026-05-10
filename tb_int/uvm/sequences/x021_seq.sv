`ifndef RDMA_SUBSYSTEM_SEQ_X021_SV
`define RDMA_SUBSYSTEM_SEQ_X021_SV

class seq_x021 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x021)

  function new(string name = "seq_x021");
    super.new(name);
    set_case_id("X021");
  endfunction
endclass

`endif
