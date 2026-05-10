`ifndef RDMA_SUBSYSTEM_SEQ_B040_SV
`define RDMA_SUBSYSTEM_SEQ_B040_SV

class seq_b040 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b040)

  function new(string name = "seq_b040");
    super.new(name);
    set_case_id("B040");
  endfunction
endclass

`endif
