`ifndef RDMA_SUBSYSTEM_SEQ_E066_SV
`define RDMA_SUBSYSTEM_SEQ_E066_SV

class seq_e066 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e066)

  function new(string name = "seq_e066");
    super.new(name);
    set_case_id("E066");
  endfunction
endclass

`endif
