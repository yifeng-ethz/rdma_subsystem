`ifndef RDMA_SUBSYSTEM_SEQ_P003_SV
`define RDMA_SUBSYSTEM_SEQ_P003_SV

class seq_p003 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p003)

  function new(string name = "seq_p003");
    super.new(name);
    set_case_id("P003");
  endfunction
endclass

`endif
