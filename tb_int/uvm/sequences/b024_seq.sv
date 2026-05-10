`ifndef RDMA_SUBSYSTEM_SEQ_B024_SV
`define RDMA_SUBSYSTEM_SEQ_B024_SV

class seq_b024 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b024)

  function new(string name = "seq_b024");
    super.new(name);
    set_case_id("B024");
  endfunction
endclass

`endif
