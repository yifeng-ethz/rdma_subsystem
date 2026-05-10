`ifndef RDMA_SUBSYSTEM_SEQ_E116_SV
`define RDMA_SUBSYSTEM_SEQ_E116_SV

class seq_e116 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e116)

  function new(string name = "seq_e116");
    super.new(name);
    set_case_id("E116");
  endfunction
endclass

`endif
