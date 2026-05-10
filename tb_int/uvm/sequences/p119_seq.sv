`ifndef RDMA_SUBSYSTEM_SEQ_P119_SV
`define RDMA_SUBSYSTEM_SEQ_P119_SV

class seq_p119 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p119)

  function new(string name = "seq_p119");
    super.new(name);
    set_case_id("P119");
  endfunction
endclass

`endif
