`ifndef RDMA_SUBSYSTEM_SEQ_B002_SV
`define RDMA_SUBSYSTEM_SEQ_B002_SV

class seq_b002 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b002)

  function new(string name = "seq_b002");
    super.new(name);
    set_case_id("B002");
  endfunction
endclass

`endif
