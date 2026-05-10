# SignalTap helper recipes for rdma_subsystem checkpoint debugging.
#
# Source this file from quartus_stp or tclsh, then call:
#   rdma_print_recipe CP-C7
#   rdma_write_recipe CP-O2 test_plan/stp_captures/CP-O2_nodes.txt

namespace eval rdma_stp {
    variable recipes
    array set recipes {
        CP-BU {
            {00_reset_status {reset_n csr_status run_state_idle}}
            {01_bar1_uid {avmm_csr_read avmm_csr_readdata csr_uid}}
            {02_link2_lock {feb_link2_locked link2_rx_valid link2_rx_error}}
            {03_idle_leakage {s_axis_opq_tvalid s_axis_opq_tdata m_axi_awvalid m_axi_wvalid cnt_halt}}
        }
        CP-C1 {
            {01_rate_emulator {rate_emulator_valid rate_emulator_channel rate_emulator_count}}
        }
        CP-C2 {
            {02_frame_assembler {frame_assembler_valid frame_assembler_eoe frame_assembler_count}}
        }
        CP-C3 {
            {03_rbcam_ingress {rbcam_in_valid rbcam_in_ready rbcam_in_channel rbcam_in_count}}
        }
        CP-C4 {
            {04_rbcam_egress {rbcam_out_valid rbcam_out_ready rbcam_out_channel rbcam_out_count}}
        }
        CP-C5 {
            {05_hist_ip {hist_wr_en hist_wr_addr hist_wr_data hist_bin_total}}
        }
        CP-C6 {
            {06_feb_tx {feb_tx_valid feb_tx_ready feb_tx_data feb_tx_frame_count}}
        }
        CP-C7 {
            {07_swb_opq_ingress {s_axis_opq_tvalid s_axis_opq_tready s_axis_opq_tdata s_axis_opq_tlast cnt_opq_input_w}}
        }
        CP-C8 {
            {08_dma_writer {m_axi_awvalid m_axi_awready m_axi_wvalid m_axi_wready m_axi_wdata cnt_bytes_written cnt_sqe_consumed}}
        }
        CP-C9 {
            {09_cq_pusher {s_axis_cqe_tvalid s_axis_cqe_tready s_axis_cqe_tdata cnt_cqe_posted cq_tail}}
        }
        CP-R1 {
            {01_rate_stream {rate_emulator_valid rate_emulator_channel rate_emulator_tick}}
        }
        CP-R2 {
            {02_rbcam_in_rate {rbcam_in_valid rbcam_in_ready rbcam_in_channel}}
        }
        CP-R3 {
            {03_rbcam_out_rate {rbcam_out_valid rbcam_out_ready rbcam_out_channel}}
        }
        CP-R4 {
            {04_feb_tx_rate {feb_tx_valid feb_tx_ready feb_tx_data}}
        }
        CP-R5 {
            {05_opq_rate {s_axis_opq_tvalid s_axis_opq_tready s_axis_opq_tdata}}
        }
        CP-R6 {
            {06_axi_rate {m_axi_awvalid m_axi_awready m_axi_wvalid m_axi_wready}}
        }
        CP-L1 {
            {01_pre_rbcam_lifetime {hist_pre_wr_en hist_pre_bin hist_pre_count rbcam_in_valid}}
        }
        CP-L2 {
            {02_post_rbcam_lifetime {hist_post_wr_en hist_post_bin hist_post_count rbcam_out_valid}}
        }
        CP-L3 {
            {03_feb_egress_sim {feb_tx_valid feb_tx_data feb_gts hit_ts}}
        }
        CP-L4 {
            {04_opq_ingress_sim {s_axis_opq_tvalid s_axis_opq_tdata opq_gts hit_ts}}
        }
        CP-L5 {
            {05_opq_egress_sim {m_axi_wvalid m_axi_wdata opq_egress_gts hit_ts}}
        }
        CP-O1 {
            {01_before_dma {s_axis_opq_tvalid s_axis_opq_tready s_axis_opq_tdata s_axis_opq_tlast}}
        }
        CP-O2 {
            {02_dma_payload {m_axi_awvalid m_axi_wvalid m_axi_wdata m_axi_wstrb m_axi_wlast}}
        }
        CP-O3 {
            {03_host_sample {m_axi_bvalid m_axi_bready host_sample_addr host_sample_data}}
        }
        CP-O4 {
            {04_dma_file {cnt_bytes_written cnt_eoe_observed cq_tail cnt_halt}}
        }
        CP-A1 {
            {01_active_rate {cnt_opq_input_w cnt_bytes_written decoded_active_count}}
        }
        CP-A2 {
            {02_truth_count {rate_emulator_count decoded_hit_count cnt_halt}}
        }
        CP-A3 {
            {03_inter_event {decoded_prev_ts decoded_ts decoded_delta decoded_channel}}
        }
    }
}

proc rdma_normalize_stage {stage} {
    set text [string toupper [string map {_ -} $stage]]
    if {![string match "CP-*" $text]} {
        set text "CP-$text"
    }
    return $text
}

proc rdma_recipe {stage} {
    set key [rdma_normalize_stage $stage]
    variable ::rdma_stp::recipes
    if {![info exists recipes($key)]} {
        error "unknown rdma_subsystem STP recipe: $stage"
    }
    return $recipes($key)
}

proc rdma_print_recipe {stage} {
    set key [rdma_normalize_stage $stage]
    puts "rdma_subsystem STP recipe $key"
    foreach group [rdma_recipe $key] {
        set name [lindex $group 0]
        set signals [lindex $group 1]
        puts "\[$name\]"
        foreach signal $signals {
            puts "  $signal"
        }
    }
}

proc rdma_write_recipe {stage out_path} {
    set handle [open $out_path w]
    set key [rdma_normalize_stage $stage]
    puts $handle "# rdma_subsystem STP recipe $key"
    foreach group [rdma_recipe $key] {
        set name [lindex $group 0]
        set signals [lindex $group 1]
        puts $handle "\[$name\]"
        foreach signal $signals {
            puts $handle $signal
        }
    }
    close $handle
}

if {[info exists argv0] && [file tail $argv0] eq [file tail [info script]]} {
    if {[llength $argv] == 0} {
        puts stderr "usage: tclsh stp_arm.tcl <CP-stage> ?out_path?"
        exit 2
    }
    set stage [lindex $argv 0]
    if {[llength $argv] > 1} {
        rdma_write_recipe $stage [lindex $argv 1]
    } else {
        rdma_print_recipe $stage
    }
}
