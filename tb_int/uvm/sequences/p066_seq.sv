`ifndef RDMA_SUBSYSTEM_SEQ_P066_SV
`define RDMA_SUBSYSTEM_SEQ_P066_SV

class seq_p066 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p066)

  function new(string name = "seq_p066");
    super.new(name);
    set_case_id("P066");
  endfunction
endclass

`endif
