`ifndef RDMA_SUBSYSTEM_SEQ_B032_SV
`define RDMA_SUBSYSTEM_SEQ_B032_SV

class seq_b032 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b032)

  function new(string name = "seq_b032");
    super.new(name);
    set_case_id("B032");
  endfunction
endclass

`endif
