`ifndef RDMA_SUBSYSTEM_SEQ_P083_SV
`define RDMA_SUBSYSTEM_SEQ_P083_SV

class seq_p083 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p083)

  function new(string name = "seq_p083");
    super.new(name);
    set_case_id("P083");
  endfunction
endclass

`endif
