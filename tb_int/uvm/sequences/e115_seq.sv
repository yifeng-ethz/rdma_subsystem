`ifndef RDMA_SUBSYSTEM_SEQ_E115_SV
`define RDMA_SUBSYSTEM_SEQ_E115_SV

class seq_e115 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e115)

  function new(string name = "seq_e115");
    super.new(name);
    set_case_id("E115");
  endfunction
endclass

`endif
