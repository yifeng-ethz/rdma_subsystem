`ifndef RDMA_SUBSYSTEM_SEQ_E031_SV
`define RDMA_SUBSYSTEM_SEQ_E031_SV

class seq_e031 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e031)

  function new(string name = "seq_e031");
    super.new(name);
    set_case_id("E031");
  endfunction
endclass

`endif
