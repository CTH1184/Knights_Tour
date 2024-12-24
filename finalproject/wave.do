onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group {tour cmd} /KnightsTour_full_tour_tb/iDUT/iTC/clk
add wave -noupdate -expand -group {tour cmd} /KnightsTour_full_tour_tb/iDUT/iTC/rst_n
add wave -noupdate -expand -group {tour cmd} /KnightsTour_full_tour_tb/iDUT/iTC/start_tour
add wave -noupdate -expand -group {tour cmd} /KnightsTour_full_tour_tb/iDUT/iTC/move
add wave -noupdate -expand -group {tour cmd} /KnightsTour_full_tour_tb/iDUT/iTC/mv_indx
add wave -noupdate -expand -group {tour cmd} /KnightsTour_full_tour_tb/iDUT/iTC/cmd_UART
add wave -noupdate -expand -group {tour cmd} /KnightsTour_full_tour_tb/iDUT/iTC/cmd_rdy_UART
add wave -noupdate -expand -group {tour cmd} /KnightsTour_full_tour_tb/iDUT/iTC/cmd
add wave -noupdate -expand -group {tour cmd} /KnightsTour_full_tour_tb/iDUT/iTC/cmd_rdy
add wave -noupdate -expand -group {tour cmd} /KnightsTour_full_tour_tb/iDUT/iTC/clr_cmd_rdy
add wave -noupdate -expand -group {tour cmd} /KnightsTour_full_tour_tb/iDUT/iTC/send_resp
add wave -noupdate -expand -group {tour cmd} /KnightsTour_full_tour_tb/iDUT/iTC/resp
add wave -noupdate -expand -group {tour cmd} /KnightsTour_full_tour_tb/iDUT/iTC/incr_indx
add wave -noupdate -expand -group {tour cmd} /KnightsTour_full_tour_tb/iDUT/iTC/cmd_proc_sel
add wave -noupdate -expand -group {tour cmd} /KnightsTour_full_tour_tb/iDUT/iTC/cmd_rdy_proc
add wave -noupdate -expand -group {tour cmd} /KnightsTour_full_tour_tb/iDUT/iTC/cmd_y
add wave -noupdate -expand -group {tour cmd} /KnightsTour_full_tour_tb/iDUT/iTC/cmd_x
add wave -noupdate -expand -group {tour cmd} /KnightsTour_full_tour_tb/iDUT/iTC/cmd_decomposed
add wave -noupdate -expand -group {tour cmd} /KnightsTour_full_tour_tb/iDUT/iTC/state
add wave -noupdate -expand -group {tour cmd} /KnightsTour_full_tour_tb/iDUT/iTC/nxt_state
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/clk
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/rst_n
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/x_start
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/y_start
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/go
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/indx
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/done
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/move
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/move_try
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/move_num
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/xx
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/yy
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/next_xx
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/next_yy
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/next_poss_moves
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/zero
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/found_next_move
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/current_state
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/next_state
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/init
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/update_position
add wave -noupdate -group {tour logic} /KnightsTour_full_tour_tb/iDUT/iTL/backup
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/clk
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/rst_n
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/cmd
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/cmd_rdy
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/clr_cmd_rdy
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/send_resp
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/strt_cal
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/cal_done
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/heading
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/heading_rdy
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/lftIR
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/cntrIR
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/rghtIR
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/error
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/frwrd
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/moving
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/tour_go
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/fanfare_go
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/current_state
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/next_state
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/clr_frwrd
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/dec_frwrd
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/inc_frwrd
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/move_cmd
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/en_frwrd
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/max_spd
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/frwrd_zero
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/inc_frwrd_amt
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/cntrIR_rise
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/cntrIR_q
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/square_count
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/move_done
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/desired_heading
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/err_nudge
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/error_meets_threshold
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/cmd_q
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/err_left
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/err_right
add wave -noupdate -expand -group {cmd proc} /KnightsTour_full_tour_tb/iDUT/iCMD/move_with_fanfare
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/clk
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/RST_n
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/SS_n
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/SCLK
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/MOSI
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/IR_en
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/lftPWM1
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/lftPWM2
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/rghtPWM1
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/rghtPWM2
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/MISO
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/INT
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/lftIR_n
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/cntrIR_n
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/rghtIR_n
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/alpha_lft
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/alpha_rght
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/omega_lft
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/omega_rght
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/omega_sum
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/heading_v
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/heading_robot
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/rand_err
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/gyro_err
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/xx
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/yy
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/mtrL1
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/mtrL2
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/mtrR1
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/mtrR2
add wave -noupdate -expand -group phys /KnightsTour_full_tour_tb/iPHYS/calc_physics
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {1 us}
