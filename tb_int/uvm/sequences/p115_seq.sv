`ifndef RDMA_SUBSYSTEM_SEQ_P115_SV
`define RDMA_SUBSYSTEM_SEQ_P115_SV

class seq_p115 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p115)

  function new(string name = "seq_p115");
    super.new(name);
    set_case_id("P115");
  endfunction
endclass

`endif
