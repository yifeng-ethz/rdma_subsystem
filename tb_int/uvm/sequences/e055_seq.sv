`ifndef RDMA_SUBSYSTEM_SEQ_E055_SV
`define RDMA_SUBSYSTEM_SEQ_E055_SV

class seq_e055 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e055)

  function new(string name = "seq_e055");
    super.new(name);
    set_case_id("E055");
  endfunction
endclass

`endif
