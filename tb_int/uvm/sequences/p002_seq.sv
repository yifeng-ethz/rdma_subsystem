`ifndef RDMA_SUBSYSTEM_SEQ_P002_SV
`define RDMA_SUBSYSTEM_SEQ_P002_SV

class seq_p002 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p002)

  function new(string name = "seq_p002");
    super.new(name);
    set_case_id("P002");
  endfunction
endclass

`endif
