`ifndef RDMA_SUBSYSTEM_SEQ_B111_SV
`define RDMA_SUBSYSTEM_SEQ_B111_SV

class seq_b111 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b111)

  function new(string name = "seq_b111");
    super.new(name);
    set_case_id("B111");
  endfunction
endclass

`endif
