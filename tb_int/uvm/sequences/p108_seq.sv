`ifndef RDMA_SUBSYSTEM_SEQ_P108_SV
`define RDMA_SUBSYSTEM_SEQ_P108_SV

class seq_p108 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p108)

  function new(string name = "seq_p108");
    super.new(name);
    set_case_id("P108");
  endfunction
endclass

`endif
