`ifndef RDMA_SUBSYSTEM_SEQ_E050_SV
`define RDMA_SUBSYSTEM_SEQ_E050_SV

class seq_e050 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e050)

  function new(string name = "seq_e050");
    super.new(name);
    set_case_id("E050");
  endfunction
endclass

`endif
