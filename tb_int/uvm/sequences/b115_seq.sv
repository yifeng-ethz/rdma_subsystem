`ifndef RDMA_SUBSYSTEM_SEQ_B115_SV
`define RDMA_SUBSYSTEM_SEQ_B115_SV

class seq_b115 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b115)

  function new(string name = "seq_b115");
    super.new(name);
    set_case_id("B115");
  endfunction
endclass

`endif
