`ifndef RDMA_SUBSYSTEM_SEQ_P011_SV
`define RDMA_SUBSYSTEM_SEQ_P011_SV

class seq_p011 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p011)

  function new(string name = "seq_p011");
    super.new(name);
    set_case_id("P011");
  endfunction
endclass

`endif
