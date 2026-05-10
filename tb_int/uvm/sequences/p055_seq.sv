`ifndef RDMA_SUBSYSTEM_SEQ_P055_SV
`define RDMA_SUBSYSTEM_SEQ_P055_SV

class seq_p055 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p055)

  function new(string name = "seq_p055");
    super.new(name);
    set_case_id("P055");
  endfunction
endclass

`endif
