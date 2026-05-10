`ifndef RDMA_SUBSYSTEM_SEQ_P024_SV
`define RDMA_SUBSYSTEM_SEQ_P024_SV

class seq_p024 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p024)

  function new(string name = "seq_p024");
    super.new(name);
    set_case_id("P024");
  endfunction
endclass

`endif
