`ifndef RDMA_SUBSYSTEM_SEQ_B046_SV
`define RDMA_SUBSYSTEM_SEQ_B046_SV

class seq_b046 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b046)

  function new(string name = "seq_b046");
    super.new(name);
    set_case_id("B046");
  endfunction
endclass

`endif
