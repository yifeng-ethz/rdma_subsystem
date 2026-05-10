`ifndef RDMA_SUBSYSTEM_SEQ_E070_SV
`define RDMA_SUBSYSTEM_SEQ_E070_SV

class seq_e070 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e070)

  function new(string name = "seq_e070");
    super.new(name);
    set_case_id("E070");
  endfunction
endclass

`endif
