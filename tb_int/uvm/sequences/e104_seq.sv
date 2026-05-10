`ifndef RDMA_SUBSYSTEM_SEQ_E104_SV
`define RDMA_SUBSYSTEM_SEQ_E104_SV

class seq_e104 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e104)

  function new(string name = "seq_e104");
    super.new(name);
    set_case_id("E104");
  endfunction
endclass

`endif
