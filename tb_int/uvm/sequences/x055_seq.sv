`ifndef RDMA_SUBSYSTEM_SEQ_X055_SV
`define RDMA_SUBSYSTEM_SEQ_X055_SV

class seq_x055 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x055)

  function new(string name = "seq_x055");
    super.new(name);
    set_case_id("X055");
  endfunction
endclass

`endif
