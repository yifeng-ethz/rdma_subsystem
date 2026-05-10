`ifndef RDMA_SUBSYSTEM_SEQ_X059_SV
`define RDMA_SUBSYSTEM_SEQ_X059_SV

class seq_x059 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x059)

  function new(string name = "seq_x059");
    super.new(name);
    set_case_id("X059");
  endfunction
endclass

`endif
