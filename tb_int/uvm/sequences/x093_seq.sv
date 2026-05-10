`ifndef RDMA_SUBSYSTEM_SEQ_X093_SV
`define RDMA_SUBSYSTEM_SEQ_X093_SV

class seq_x093 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x093)

  function new(string name = "seq_x093");
    super.new(name);
    set_case_id("X093");
  endfunction
endclass

`endif
