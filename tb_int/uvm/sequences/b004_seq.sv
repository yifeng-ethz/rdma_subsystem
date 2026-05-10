`ifndef RDMA_SUBSYSTEM_SEQ_B004_SV
`define RDMA_SUBSYSTEM_SEQ_B004_SV

class seq_b004 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b004)

  function new(string name = "seq_b004");
    super.new(name);
    set_case_id("B004");
  endfunction
endclass

`endif
