`ifndef RDMA_SUBSYSTEM_SEQ_X050_SV
`define RDMA_SUBSYSTEM_SEQ_X050_SV

class seq_x050 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x050)

  function new(string name = "seq_x050");
    super.new(name);
    set_case_id("X050");
  endfunction
endclass

`endif
