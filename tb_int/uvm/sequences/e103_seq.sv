`ifndef RDMA_SUBSYSTEM_SEQ_E103_SV
`define RDMA_SUBSYSTEM_SEQ_E103_SV

class seq_e103 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e103)

  function new(string name = "seq_e103");
    super.new(name);
    set_case_id("E103");
  endfunction
endclass

`endif
