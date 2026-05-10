`ifndef RDMA_SUBSYSTEM_SEQ_B055_SV
`define RDMA_SUBSYSTEM_SEQ_B055_SV

class seq_b055 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b055)

  function new(string name = "seq_b055");
    super.new(name);
    set_case_id("B055");
  endfunction
endclass

`endif
