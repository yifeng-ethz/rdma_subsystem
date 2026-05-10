`ifndef RDMA_SUBSYSTEM_SEQ_P070_SV
`define RDMA_SUBSYSTEM_SEQ_P070_SV

class seq_p070 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p070)

  function new(string name = "seq_p070");
    super.new(name);
    set_case_id("P070");
  endfunction
endclass

`endif
