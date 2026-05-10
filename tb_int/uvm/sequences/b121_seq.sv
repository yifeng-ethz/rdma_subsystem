`ifndef RDMA_SUBSYSTEM_SEQ_B121_SV
`define RDMA_SUBSYSTEM_SEQ_B121_SV

class seq_b121 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b121)

  function new(string name = "seq_b121");
    super.new(name);
    set_case_id("B121");
  endfunction
endclass

`endif
