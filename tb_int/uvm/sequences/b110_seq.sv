`ifndef RDMA_SUBSYSTEM_SEQ_B110_SV
`define RDMA_SUBSYSTEM_SEQ_B110_SV

class seq_b110 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b110)

  function new(string name = "seq_b110");
    super.new(name);
    set_case_id("B110");
  endfunction
endclass

`endif
