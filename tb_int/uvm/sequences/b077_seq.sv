`ifndef RDMA_SUBSYSTEM_SEQ_B077_SV
`define RDMA_SUBSYSTEM_SEQ_B077_SV

class seq_b077 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b077)

  function new(string name = "seq_b077");
    super.new(name);
    set_case_id("B077");
  endfunction
endclass

`endif
