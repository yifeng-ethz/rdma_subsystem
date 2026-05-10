`ifndef RDMA_SUBSYSTEM_SEQ_E040_SV
`define RDMA_SUBSYSTEM_SEQ_E040_SV

class seq_e040 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e040)

  function new(string name = "seq_e040");
    super.new(name);
    set_case_id("E040");
  endfunction
endclass

`endif
