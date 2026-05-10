`ifndef RDMA_SUBSYSTEM_SEQ_B103_SV
`define RDMA_SUBSYSTEM_SEQ_B103_SV

class seq_b103 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b103)

  function new(string name = "seq_b103");
    super.new(name);
    set_case_id("B103");
  endfunction
endclass

`endif
