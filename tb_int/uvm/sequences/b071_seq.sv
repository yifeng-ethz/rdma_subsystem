`ifndef RDMA_SUBSYSTEM_SEQ_B071_SV
`define RDMA_SUBSYSTEM_SEQ_B071_SV

class seq_b071 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b071)

  function new(string name = "seq_b071");
    super.new(name);
    set_case_id("B071");
  endfunction
endclass

`endif
