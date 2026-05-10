`ifndef RDMA_SUBSYSTEM_SEQ_E059_SV
`define RDMA_SUBSYSTEM_SEQ_E059_SV

class seq_e059 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e059)

  function new(string name = "seq_e059");
    super.new(name);
    set_case_id("E059");
  endfunction
endclass

`endif
