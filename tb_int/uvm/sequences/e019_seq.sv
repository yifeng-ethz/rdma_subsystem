`ifndef RDMA_SUBSYSTEM_SEQ_E019_SV
`define RDMA_SUBSYSTEM_SEQ_E019_SV

class seq_e019 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e019)

  function new(string name = "seq_e019");
    super.new(name);
    set_case_id("E019");
  endfunction
endclass

`endif
