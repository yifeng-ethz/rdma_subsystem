`ifndef RDMA_SUBSYSTEM_SEQ_B122_SV
`define RDMA_SUBSYSTEM_SEQ_B122_SV

class seq_b122 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b122)

  function new(string name = "seq_b122");
    super.new(name);
    set_case_id("B122");
  endfunction
endclass

`endif
