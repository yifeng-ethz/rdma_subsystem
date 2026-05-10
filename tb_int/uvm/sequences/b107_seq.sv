`ifndef RDMA_SUBSYSTEM_SEQ_B107_SV
`define RDMA_SUBSYSTEM_SEQ_B107_SV

class seq_b107 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b107)

  function new(string name = "seq_b107");
    super.new(name);
    set_case_id("B107");
  endfunction
endclass

`endif
