`ifndef RDMA_SUBSYSTEM_SEQ_X006_SV
`define RDMA_SUBSYSTEM_SEQ_X006_SV

class seq_x006 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x006)

  function new(string name = "seq_x006");
    super.new(name);
    set_case_id("X006");
  endfunction
endclass

`endif
