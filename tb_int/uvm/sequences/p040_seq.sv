`ifndef RDMA_SUBSYSTEM_SEQ_P040_SV
`define RDMA_SUBSYSTEM_SEQ_P040_SV

class seq_p040 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p040)

  function new(string name = "seq_p040");
    super.new(name);
    set_case_id("P040");
  endfunction
endclass

`endif
