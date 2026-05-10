`ifndef RDMA_SUBSYSTEM_SEQ_B084_SV
`define RDMA_SUBSYSTEM_SEQ_B084_SV

class seq_b084 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b084)

  function new(string name = "seq_b084");
    super.new(name);
    set_case_id("B084");
  endfunction
endclass

`endif
