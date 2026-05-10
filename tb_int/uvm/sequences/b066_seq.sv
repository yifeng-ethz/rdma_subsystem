`ifndef RDMA_SUBSYSTEM_SEQ_B066_SV
`define RDMA_SUBSYSTEM_SEQ_B066_SV

class seq_b066 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b066)

  function new(string name = "seq_b066");
    super.new(name);
    set_case_id("B066");
  endfunction
endclass

`endif
