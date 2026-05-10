`ifndef RDMA_SUBSYSTEM_SEQ_P080_SV
`define RDMA_SUBSYSTEM_SEQ_P080_SV

class seq_p080 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p080)

  function new(string name = "seq_p080");
    super.new(name);
    set_case_id("P080");
  endfunction
endclass

`endif
