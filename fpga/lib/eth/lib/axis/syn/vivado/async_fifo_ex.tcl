# Timing constraints for async_fifo

# Assume that fifo_inst is the instance of the async_fifo module.
foreach fifo_inst [get_cells -hier -filter {(ORIG_REF_NAME == async_fifo || REF_NAME == async_fifo)}] {
    puts "Inserting timing constraints for async_fifo instance $fifo_inst"

    # Get clock periods
    set write_clk [get_clocks -of_objects [get_cells -quiet "$fifo_inst/wr_ptr_reg[*]"]]
    set read_clk [get_clocks -of_objects [get_cells -quiet "$fifo_inst/rd_ptr_reg[*]"]]

    set write_clk_period [if {[llength $write_clk]} {get_property -min PERIOD $write_clk} {expr 1.0}]
    set read_clk_period [if {[llength $read_clk]} {get_property -min PERIOD $read_clk} {expr 1.0}]

    set min_clk_period [expr min($write_clk_period, $read_clk_period)]

    # Reset synchronization (wr_sync_rst, rd_sync_rst)
    set reset_ffs_wr [get_cells -quiet -hier -regexp ".*/wr_sync_rst.*" -filter "PARENT == $fifo_inst"]
    set reset_ffs_rd [get_cells -quiet -hier -regexp ".*/rd_sync_rst.*" -filter "PARENT == $fifo_inst"]

    if {[llength $reset_ffs_wr]} {
        set_property ASYNC_REG TRUE $reset_ffs_wr
    }

    if {[llength $reset_ffs_rd]} {
        set_property ASYNC_REG TRUE $reset_ffs_rd
    }

    # Pointer synchronization
    set sync_ffs_wr [get_cells -quiet -hier -regexp ".*/m_wr_rd_sync_ptr_reg.*" -filter "PARENT == $fifo_inst"]
    set sync_ffs_rd [get_cells -quiet -hier -regexp ".*/m_rd_wr_sync_ptr_reg.*" -filter "PARENT == $fifo_inst"]

    if {[llength $sync_ffs_wr]} {
        set_property ASYNC_REG TRUE $sync_ffs_wr
        set_max_delay -from [get_cells "$fifo_inst/wr_ptr_reg[*]"] -to [get_cells "$fifo_inst/m_wr_rd_sync_ptr_reg[*]"] -datapath_only $write_clk_period
    }

    if {[llength $sync_ffs_rd]} {
        set_property ASYNC_REG TRUE $sync_ffs_rd
        set_max_delay -from [get_cells "$fifo_inst/rd_ptr_reg[*]"] -to [get_cells "$fifo_inst/m_rd_wr_sync_ptr_reg[*]"] -datapath_only $read_clk_period
    }

    # Commit pointer synchronization
    set commit_sync_wr [get_cells -quiet -hier -regexp ".*/wr_sync_commit_ptr.*" -filter "PARENT == $fifo_inst"]
    set commit_sync_rd [get_cells -quiet -hier -regexp ".*/rd_sync_commit_ptr.*" -filter "PARENT == $fifo_inst"]

    if {[llength $commit_sync_wr]} {
        set_property ASYNC_REG TRUE $commit_sync_wr
        set_max_delay -from [get_cells "$fifo_inst/m_wr_rd_sync_ptr_reg[*]"] -to [get_cells "$fifo_inst/wr_sync_commit_ptr_reg[*]"] -datapath_only $write_clk_period
    }

    if {[llength $commit_sync_rd]} {
        set_property ASYNC_REG TRUE $commit_sync_rd
        set_max_delay -from [get_cells "$fifo_inst/m_rd_wr_sync_ptr_reg[*]"] -to [get_cells "$fifo_inst/rd_sync_commit_ptr_reg[*]"] -datapath_only $read_clk_period
    }

    # Output register (needed for handling data_out timing)
    set output_reg_ffs [get_cells -quiet "$fifo_inst/data_out"]

    if {[llength $output_reg_ffs]} {
        if {[llength $write_clk]} {
            set_false_path -from $write_clk -to $output_reg_ffs
        }
    }
}
