`ifndef RDMA_SUBSYSTEM_SEQ_X043_SV
`define RDMA_SUBSYSTEM_SEQ_X043_SV

class seq_x043 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x043)

  function new(string name = "seq_x043");
    super.new(name);
    set_case_id("X043");
  endfunction
endclass

`endif
