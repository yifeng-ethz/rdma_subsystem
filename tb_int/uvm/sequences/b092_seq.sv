`ifndef RDMA_SUBSYSTEM_SEQ_B092_SV
`define RDMA_SUBSYSTEM_SEQ_B092_SV

class seq_b092 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b092)

  function new(string name = "seq_b092");
    super.new(name);
    set_case_id("B092");
  endfunction
endclass

`endif
