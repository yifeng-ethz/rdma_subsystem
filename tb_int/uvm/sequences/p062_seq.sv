`ifndef RDMA_SUBSYSTEM_SEQ_P062_SV
`define RDMA_SUBSYSTEM_SEQ_P062_SV

class seq_p062 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p062)

  function new(string name = "seq_p062");
    super.new(name);
    set_case_id("P062");
  endfunction
endclass

`endif
