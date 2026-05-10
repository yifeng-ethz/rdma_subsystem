`ifndef RDMA_SUBSYSTEM_SEQ_P111_SV
`define RDMA_SUBSYSTEM_SEQ_P111_SV

class seq_p111 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p111)

  function new(string name = "seq_p111");
    super.new(name);
    set_case_id("P111");
  endfunction
endclass

`endif
