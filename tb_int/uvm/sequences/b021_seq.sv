`ifndef RDMA_SUBSYSTEM_SEQ_B021_SV
`define RDMA_SUBSYSTEM_SEQ_B021_SV

class seq_b021 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b021)

  function new(string name = "seq_b021");
    super.new(name);
    set_case_id("B021");
  endfunction
endclass

`endif
