`ifndef RDMA_SUBSYSTEM_SEQ_B059_SV
`define RDMA_SUBSYSTEM_SEQ_B059_SV

class seq_b059 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b059)

  function new(string name = "seq_b059");
    super.new(name);
    set_case_id("B059");
  endfunction
endclass

`endif
