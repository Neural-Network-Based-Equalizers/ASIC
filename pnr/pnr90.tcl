# --------------------------------------------- # 
# --------------- NDM Creation  --------------- # 
# --------------------------------------------- # 
set worst_case "saed90nm_max.db" ; 
set lib_name mips16_ndm 
set common_path "/home/ICer/Downloads/Lib"
set std_cell_path "/synopsys/models"
set tech_file_path "/process/astro/tech/astroTechFile.tf"
set LIBNAME "saed90nm_max"

# ======= Create Workspace  ======= #
# --- creates a library workspace, in automatically analyze the library source
create_workspace -flow exploration -technology ${common_path}/${tech_file_path} $LIBNAME
# ======= Read db files ======= # 
# Reads one or more logic library files (db) format into the library workspace.
read_db ${common_path}/${std_cell_path}/${worst_case}
#  =======  read abstarct_view ======= # 
# Loads the physical information 
read_lef ${common_path}/lef/saed90nmEditted.lef
# ======= Change_Options ======= #
# To save design and layout views in The NDM  
set_app_options -list {lib.workspace.keep_all_physical_cells {true}}
set_app_options -list {lib.workspace.save_design_views {true}}
set_app_options -list {lib.workspace.save_layout_views {true}}
set_app_options -list {design.enable_lib_cell_editing {mutable}}

# ======= Partitions libraries ======= # 
# ---  analyzes the logic and physical source libraries in the exploration mode 
group_libs

# ======= Check & commit workspace ======= # 
# saving the data to disk and removed from memory 
process_workspaces  -directory /home/ICer/Desktop/iti/mips/pnr/1_ndm -output $LIBNAME


# ======= quit ======= # 
quit

# ================================================ #
# ================== Search path ================= #
# ================================================ #
set_app_var search_path /home/ICer/Downloads/Lib

# ================================================ #
# ================== NDM_library ================= #
# ================================================ #
set reference_library /home/ICer/Desktop/iti/mips/pnr/1_ndm/saed90nm_max_1.ndm
# ================================================ #
# =================== Techfile =================== #
# ================================================ #
set TECH_FILE $search_path/process/astro/tech/astroTechFile.tf 

# ================================================ #
# ================ Design Library ================ #
# ================================================ #
create_lib -technology $TECH_FILE -ref_libs $reference_library mips_16.dlib

# ================================================ #
# ================== Load Design ================= #
# ================================================ #
read_verilog -top mips_16 ../../dft/output/mips_16.v
# ----------- Read_SDC ----------- #
read_sdc ../../dft/output/mips_16.sdc

# ================================================ #
# ===================== TLU+ ===================== #
# ================================================ #
set Tech $search_path/Technology_Kit/starrcxt

read_parasitic_tech -layermap $Tech/tech2itf.map -tlup $Tech/tluplus/saed90nm_1p9m_1t_Cmax.tluplus  -name maxTLU

read_parasitic_tech -layermap $Tech/tech2itf.map -tlup $Tech/tluplus/saed90nm_1p9m_1t_Cmin.tluplus  -name minTLU

set_parasitic_parameters -late_spec maxTLU -early_spec minTLU

# ================================================ #
# =================== End_Step =================== #
# ================================================ #
save_block -as mips_16_setup mips_16.dlib:mips_16.design






# ================================================ #
# ================== Start_Step ================== #
# ================================================ #
set design mips_16
sh rm ../../2_design_library/${design}.dlib/${design}_setup/design.ndm.lock

 
#set design_lib_path /home/ICer/Downloads/Mips16/pnr/2_design_library

set design_lib_path /home/ICer/Desktop/iti/mips/pnr/2_design_library
open_block $design_lib_path/${design}.dlib:${design}_setup.design
copy_block -from_block ${design}.dlib:${design}_setup.design -to_block ${design}_fp
current_block ${design}_fp.design
start_gui

# ================================================ #
# ================= First Step =================== #
# ================================================ # 

# -- Metal layers Directions 
set_attribute [get_layers {M1 M3 M5 M7 M9}] routing_direction vertical
set_attribute [get_layers {M2 M4 M6 M8}] routing_direction horizontal 


# # -- Metal Layers Offest 
set_attribute [get_layers {M1}] track_offset 0.03 
set_attribute [get_layers {M2}] track_offset 0.04

# -- Wire Track pattern (Method1)

# set_wire_track_pattern -site_def unit -layer M1 -mode uniform \
#-mask_constraint {mask_two mask_one} -coord 0.037 -space 0.074 -direction vertical

# -- For power Layers 
set_ignored_layers -max_routing_layer M8 
set_ignored_layers -max_routing_layer M9


# -- site def attribute 
set Name_unit [get_site_defs]
set_attribute [get_site_defs $Name_unit] is_default true
set_attribute [get_site_defs  $Name_unit] symmetry {Y}

# ================================================ #
# ================== Second Step ================= #
# ================================================ #
# -- Initialize_Floor_planning 
initialize_floorplan -core_utilization .5 -shape R -orientation N -core_offset {150}  \
					 -flip_first_row false -side_ratio {1 1}


# ================================================ #
# ================= Third Step =================== #
# ================================================ #
# -- Muliple Power Domains (if UPF File existing) 
#load_upf file.upf
#commit_upf 

# ================================================ #
# ================= Fourth Step ================== #
# ================================================ #
#set_block_pin_constraints  -allowed_layers {M3}  -sides {1 3} 
#place_pins -ports [get_ports -filter {direction == in }] 

#set_block_pin_constraints -self -allowed_layers {M2} -sides {2 4} -corner_keepout_num_tracks 1
#place_pins -ports [get_ports -filter {direction == out }] 

place_pins -ports [get_ports *]


# ================================================ #
# ================= Fifth Step =================== #
# ================================================ #
# --- Placement Blockage  
create_placement_blockage -boundary {{70 70} {150  150}} -name B1 -type hard
create_placement_blockage -boundary {{150  150} {200 200}} -name B2 -type partial -blocked_percentage 40 
create_placement_blockage -boundary {{200 200} {250 250}}  -name B3 -type soft
#remove_placement_blockages -all



# ================================================ #
# ================ Seventh Step ================== #
# ================================================ #
# -- in this library don't exist tapcells sothat insert Dcaps only for get it 
#get_lib_cell saed90nm_max/DC*
create_tap_cells -lib_cell saed90nm_max/DCAP  -pattern stagger -distance 15
get_cells tap*
remove_cell tap*

create_tap_cells -lib_cell saed90nm_max/DCAP  -pattern every_row -distance 10
get_cells tap*
remove_cell tap*

create_tap_cells -lib_cell saed90nm_max/DCAP  -pattern  every_other_row -distance 10
get_cells tap*
remove_cell tap*

# ================================================ #
# ================== Reports ===================== #
# ================================================ #
report_ports [all_inputs] > ../report/input_port.rpt
report_ports [all_outputs] > ../report/output_port.rpt
report_cell  > ../report/cells.rpt
report_nets  > ../report/nets.rpt
report_qor   > ../report/qor.rpt
report_utilization > ../report/utilization.rpt
get_placement_blockages > ../report/Blockage.rpt

# ================================================ #
# =================== End_Step =================== #
# ================================================ #
write_def ../output/cv32e40p_top.def
write_verilog -include {all} ../output/cv32e40p_top.v
write_sdc -output ../output/cv32e40p_top.sdc

# =================== End_Step =================== #
save_block 

# ================================================ #
# ================== Start_Step ================== #
# ================================================ #
set design mips_16
sh rm ../../2_design_library/${design}.dlib/${design}_fp/design.ndm.lock

#set design_lib_path /home/ICer/Downloads/Mips16/pnr/2_design_library

set design_lib_path /home/ICer/Desktop/iti/mips/pnr/2_design_library
open_block $design_lib_path/${design}.dlib:${design}_fp.design
copy_block -from_block ${design}.dlib:${design}_fp.design -to_block ${design}_pp
current_block ${design}_pp.design
start_gui

# ================================================ #
# ================= First Step =================== #
# ================================================ #
# --- disable ignored layers used to  used it through Power planning 
report_ignored_layers
remove_ignored_layers -all -max_routing_layer -min_routing_layer
report_ignored_layers
# ================================================ #
# ================= Second Step ================== #
# ================================================ #
# --- Creation VDD and VSS nets for Network {PDN} 
create_net -power VDD 
create_net -ground VSS

# --- Connect pins of cells and submodules  to rails   
# hierarchical [include top module + sub modules]
connect_pg_net -net VDD [get_pins -hierarchical */VDD]
connect_pg_net -net VSS [get_pins -hierarchical */VSS]

# --- Automati c connect for nets 
set_app_option -name plan.pgroute.auto_connect_pg_net -value true



# ================================================ #
# ================= Third Step =================== #
# ================================================ #
# -- Create region,patterns , Define strategie,Compile stra  
# --- Variables 
set ring_offset 2 ;  set ring_width 5 ; set ring_spacing 5 ; 

# ---- Create region to define region pg network 
create_pg_region power_ring_region -core -expand_by_edge  \
          "{{side: 1} {offset: $ring_offset}} \
		   {{side: 2} {offset: $ring_offset}} \ 
		   {{side: 3} {offset: $ring_offset}} \
		   {{side: 4} {offset: $ring_offset}} "
		   

# ---- Create Pattern Rings Structure {Layers , Width , Space }
# --- Variables 
set hm_top M8 ;  set vm_top M9 ; 
create_pg_ring_pattern ring_pattern \
                 -horizontal_layer $hm_top -vertical_layer $vm_top \
                 -horizontal_width $ring_width -vertical_width $ring_width \
                 -horizontal_spacing $ring_spacing -vertical_spacing $ring_spacing

# ---- Stratgie for design Rings
set_pg_strategy core_ring \
					-pg_regions { power_ring_region } \
					-pattern {{ name: ring_pattern} { nets: "VSS VDD" }}

# ---- Compile /Implement Ring   
compile_pg -strategies core_ring


# --- Verify routing of PG nets satisfies technology design rules
check_pg_drc
# --- Connectivity check for PG networks, standard cell PG pins, PG pads, and block terminals 
check_pg_connectivity 
# --- Check Missing Vias in the PG Network
check_pg_missing_vias 


# ================================================ #
# ================= Fourth Step ================== #
# ================================================ # 
# --- Offest : the center line of the first wire to the boundary
# --- pitch  : the pitch of the wires in this layer {centre to centre}.
# --- space  : the spacing between wires in this layer {edge to edge} . 
# --- trim   : the trim option for wires in this layer.
# --- Define structure pattern
set hm_top M8 ; set vm_top M9 ; 
# --- Create Mesh/Straps pattern {Layer, Width, Offest, Pitch }
create_pg_mesh_pattern straps_vddvss -layers {{{vertical_layer: M9} {width: 5} {pitch: 30} {spacing: interleaving} {offset:1} {trim:true}} \
				     {{horizontal_layer: M8} {width: 5} {pitch: 30} {spacing: interleaving} {offset:  6} {trim: true}}}
# --- Strategie for design mesh 
set_pg_strategy mesh_vddvss -core \
   			    -pattern {{pattern: straps_vddvss} {nets: VDD VSS}}  \
				-extension {{stop: outermost_ring}}
			    #-extension {{stop: design_boundary_and_generate_pin}}

# --- Compile /Implement Mesh  
compile_pg -strategies mesh_vddvss
# --- Create Mesh2
create_pg_mesh_pattern straps_vddvss2 -layers {{{vertical_layer: M7} {width: 3} {pitch: 30} {spacing: interleaving} {offset:1} {trim:true}} \
				     {{horizontal_layer: M6} {width: 3} {pitch: 30} {spacing: interleaving} {offset:  6} {trim: true}}}
# --- Strategie for design mesh 
set_pg_strategy mesh_vddvss2 -core \
   			    -pattern {{pattern: straps_vddvss2} {nets: VDD VSS}}  \
				-extension {{stop: outermost_ring}}
			    #-extension {{stop: design_boundary_and_generate_pin}}

# --- Compile /Implement Mesh  
compile_pg -strategies mesh_vddvss2

# --- Verify routing of PG nets satisfies technology design rules
check_pg_drc
# --- Connectivity check for PG networks, standard cell PG pins, PG pads, and block terminals 
check_pg_connectivity 
check_pg_connectivity  > ../report/Connectivity_Mesh_Steps.rpt

# --- Check Missing Vias in the PG Network
check_pg_missing_vias 
# ================================================ #
# ================= Fifth Step =================== #
# ================================================ #
# --- Prevent Create VIA on Rails  
#set_app_option plan.pgroute.disable_via_createion -value true
# ---- Create rails patterns {Layer , Width}
create_pg_std_cell_conn_pattern std_cell_rail -layers M1 -rail_width 0.16

# ---- Define Strategie 
set_pg_strategy rails_M1 -core -pattern {{name: std_cell_rail} {nets: "VDD VSS"} }

# ---- Compiling  
compile_pg -strategies rails_M1   

# --- Verify routing of PG nets satisfies technology design rules
check_pg_drc
# --- Connectivity check for PG networks, standard cell PG pins, PG pads, and block terminals 
check_pg_connectivity 
# --- Check Missing Vias in the PG Network
check_pg_missing_vias 

# ================================================ #
# ================ Seventh Step ================== #
# ================================================ #
# --- Verify routing of PG nets satisfies technology design rules
check_pg_drc
# --- Connectivity check for PG networks, standard cell PG pins, PG pads, and block terminals 
check_pg_connectivity 
# --- Check Missing Vias in the PG Network
check_pg_missing_vias 


# ================================================ #
# ================================================ #
# ================== Reports ===================== #
# ================================================ #

check_pg_drc  > ../report/pg_drc.rpt
check_pg_connectivity > ../report/pg_connectivity.rpt
analyze_power_plan -report_track_utilization_only > ../report/track_utilization.rpt
report_utilization > ../report/utilization.rpt
report_qor > ../report/qor.rpt  ; #optional
report_timing > ../report/timing.rpt ; #optional 

# ================================================ #
# =================== End_Step =================== #
# ================================================ #
write_def ../output/cv32e40p_top.def
write_verilog -include {all} ../output/cv32e40p_top.v
write_sdc -output ../output/cv32e40p_top.sdc 
save_block ;


# ================================================ #
# ================== Start_Step ================== #
# ================================================ #
set design mips_16
sh rm ../../2_design_library/${design}.dlib/${design}_pp/design.ndm.lock

#set design_lib_path /home/ICer/Downloads/Mips16/pnr/2_design_library 

set design_lib_path /home/ICer/Desktop/iti/mips/pnr/2_design_library

open_block $design_lib_path/${design}.dlib:${design}_pp.design
copy_block -from_block ${design}.dlib:${design}_pp.design -to_block ${design}_pl
current_block ${design}_pl.design
start_gui

# ================================================ #
# ================= def file read ================ #
# ================================================ # 
read_def ../../../dft/output/${design}.def
check_design -checks pre_placement_stage

# ================================================ #
# ============== Placement OPtion  =============== #
# ================================================ #
#set_app_option  -name place.coarse.congestion_driven_max_util -value 0.6
#set_app_options -name place.coarse.max_density -value 0.2
#set_app_options -name place.coarse.target_routing_density -value 0.6
set_app_options -name opt.common.user_instance_name_prefix -value "PLACE_"
set_app_options -name opt.common.max_fanout   -value 10  
set_app_options -name opt.tie_cell.max_fanout -value 10

# set_app_options -name place.coarse.enable_tie_cell_opt_after_plc true  ; # automatically insert tie cell 

report_app_options > ../report/Placement_option.rp
# ================================================ #
# ================= Spare cells  ================= #
# ================================================ #
# --- Get library cells to insert as spare cells 
get_lib_cell */NA*
get_lib_cell */IN*
get_lib_cell */IBU*
get_lib_cell */XO*


# --- add spare cells without legalized 
add_spare_cells -cell_name SpareCell \
				-lib_cell "*/NAND2X2 */INVX2  */XOR2X1" \
				-num_instances 25				
# --- Spread spare cells by randmization 
spread_spare_cells -cells [get_cells Spare*] -random_distribution

# --- legalized Sparecells 
place_eco_cells -cells [get_cells Spare*] -legalize_only

# ---  set variables 
set spare_cells [get_cells Spare*]
# ================================================ #
# ================== Tie cells  ================== #
# ================================================ #
# -- Tie-High  
set_attribute [get_lib_cells saed90nm_max/TIEH] dont_use false  
set_attribute [get_lib_cells saed90nm_max/TIEH] dont_touch false
set_lib_cell_purpose -include all {saed90nm_max/TIEH}

# set_attribute [get_lib_cells saed90nm_max/TIEH] dont_touch false
# -- Tie-Low 
set_attribute [get_lib_cells saed90nm_max/TIEL] dont_use false  
set_attribute [get_lib_cells saed90nm_max/TIEL] dont_touch false
set_lib_cell_purpose -include all {saed90nm_max/TIEL}
# -- Add cells 
add_tie_cells -objects $spare_cells \
			  -tie_low_lib_cells  saed90nm_max/TIEL \
			  -tie_high_lib_cells saed90nm_max/TIEH \
		          -legalize
	

# ---  Prevents ICC2 optimization from modifying, removing.
set_dont_touch $spare_cells
# --- Locks the placement location of those spare cells so ICC2 does not move them during placement optimizations.
set_fixed_objects $spare_cells

# ================================================ #
# ================ Connect_Cells  ================ #
# ================================================ #
connect_pg_net -net "VDD" [get_pins -hierarchical "*/VDD*"]
connect_pg_net -net "VSS" [get_pins -hierarchical "*/VSS"]
check_pg_drc  > ../report/drc_spare_cells_steps.rp

# ================================================ #
# ============== Detailed Placement ============== #
# ================================================ #

# --- Detailed Placement divided to { Coarse placment , legalized placement  } 

# -- Performs coarse {approximate locations for cells, Cells overlap,No logic optimization }
# --- buffering_aware_timing_driven :  model that estimates the effects of buffering long nets and high fanout nets later in the flow.
#create_placement -effort high  -congestion -congestion_effort  high   -incremental
create_placement  -effort high  \
				  -timing_driven -buffering_aware_timing_driven \
				  -congestion -congestion_effort  medium   -incremental

# --- Legalized placement each  illegal cell will be legal location 
legalize_placement  -incremental 
check_pg_drc  > ../report/drc_legalized.rpt


# ================================================ #
# ============ Placement Optimization ============ #
# ================================================ #
# --- initial_place, initial_drc, initial_opto, final_place, and final_opto.
#place_opt 
#check_pg_drc > ../report/drc_final_opto.rpt
# --- congestion is found to be a problem after placement and optimization It can improve 
#refine_opt
#check_pg_drc > ../report/drc_refine_opto.rpt


# ================================================ #
# ================ Connect_Cells  ================ #
# ================================================ #
connect_pg_net -net "VDD" [get_pins -hierarchical "*/VDD*"]
connect_pg_net -net "VSS" [get_pins -hierarchical "*/VSS"]
check_pg_drc


# ================================================ #
# =================== Reports ==================== #
# ================================================ #
check_legality -verbose  > ../report/legality.rpt
check_routability   > ../report/routeability.rpt
report_utilization > ../report/utilization.rpt
check_pg_drc  > ../report/drc_final.rpt
report_design > ../report/design.rpt
report_cell   > ../report/cells.rpt
report_qor    > ../report/qor.rpt
report_timing > ../report/timing.rpt

# ================================================ #
# =================== End_Step =================== #
# ================================================ #
write_def ../output/${design}.def
write_verilog -include {all} ../output/${design}.v
save_block ; 






#spare cells are placed where it may result in an error
#
# ================================================ #
# ================== Start_Step ================== #
# ================================================ #
set design mips_16
##sh rm ../../2_design_library/${design}.dlib/${design}_pl/design.ndm.lock

set design_lib_path /home/ICer/Downloads/Mips16/pnr/2_design_library
open_block $design_lib_path/${design}.dlib:${design}_pl.design
copy_block -from_block ${design}.dlib:${design}_pl.design -to_block ${design}_cts
current_block ${design}_cts.design
start_gui


# ================================================ #
# =================== Pre-CTS ==================== #
# ================================================ # 
# --- Check design placment ,congestion .. 
check_design -checks pre_clock_tree_stage
# --- Reset all option and configration for skew and latency 
set_ignored_layers -max_routing_layer M9 -min_routing_layer M1 -verbose
remove_clock_tree_options -all -target_skew -target_latency 
# --- Clock sources  
report_clocks 
report_clock_qor -type structure

# ================================================ #
# ================= Transitions ================== #
# ================================================ # 
# set_driving_cell -lib_cell */*_BUF_2 -pin Z [get_ports clk_i]
set_input_transition -rise 0.3 {fun_clk scan_clk}
set_input_transition -fall 0.2 {fun_clk scan_clk}
# ================================================ #
# ============== Clock_Exceptions ================ #
# ================================================ # 
set_lib_cell_purpose -exclude cts [get_lib_cells -of [get_cells *]]

# ================================================ #
# ================= CTS_Cells ==================== #
# ================================================ #
# ----- Prefred ( High drive strength and INV Cells )
# ----- INV Prefred to resisitance of wire interconnect and trainstions  
set_lib_cell_purpose -include cts */INVX2 ; # This prefred Cell high Drive strength  
set_lib_cell_purpose -include cts */INVX4
set_lib_cell_purpose -include cts */*INVX8 ;   
set_lib_cell_purpose -include cts */*INVX16 ;
# ================================================ #
# ================ Skew & Latency ================ #
# ================================================ # 
set_clock_tree_options -target_skew 0.01  
set_clock_tree_options -target_latency 0.5

# ================================================ #
# ====================== NDR ===================== #
# ================================================ #
# defines non-default routing rules in the design.
create_routing_rule clk_network_NDR -multiplier_spacing 2 -multiplier_width 2
# ----- root:from port to first buffer  
set_clock_routing_rules -net_type root -rules clk_network_NDR -max_routing_layer M9 -min_routing_layer M3
# ----- internal : from first buffer to last buffer before sink   
set_clock_routing_rules -net_type internal -rules clk_network_NDR -max_routing_layer M9 -min_routing_layer M3
# ----- Sink >> from last buffer to sink(leaf) without NDR     
set_clock_routing_rules -net_type sink -default_rule -max_routing_layer M9 -min_routing_layer M3

# over all Rules 		
report_routing_rules -verbose 
# Special Clock net all Rules 
report_clock_routing_rules


# ================================================ #
# ================== DRC/Options ================= #
# ================================================ #
set_max_transition -clock_path 0.100 [get_clocks ]
set_app_options -as_user_default -list {cts.common.max_fanout 25}
set_app_options -name cts.common.user_instance_name_prefix -value "CTS_"
# ================================================ #
# ====================== CRP ===================== #
# ================================================ # 
# --- To reduce On-Chip Variation (OCV) effects, clock trees try to share as many buffers as possible. 
set_app_options -name time.remove_clock_reconvergence_pessimism -value true
report_clock_settings

# ================================================ #
# ====================== Opt ===================== #
# ================================================ # 

clock_opt -from build_clock -to build_clock

clock_opt -from route_clock -to route_clock

clock_opt -from route_clock -to final_opto
# ================================================ #
# ================== Connect_PG ================== #
# ================================================ # 
sizeof_collection [get_cells "CTS_*"]
connect_pg_net -net "VDD" [get_pins -hierarchical "*/VDD*"]
connect_pg_net -net "VSS" [get_pins -hierarchical "*/VSS"]
check_pg_drc
check_routes -drc true
# ================================================ #
# =================== Reports ==================== #
# ================================================ #
report_clock_tree_options  >  ../report/clock_tree_options.rpt
report_routing_rules -verbose >  ../report/cts_routing_rules.rpt
report_clock_routing_rules >  ../report/cts_clock_routing_rules.rpt
report_ports -verbose [get_ports *clk*] >  ../report/cts_ports.rpt
report_clock_settings >  ../report/cts_clk_setting.rpt
report_utilization -verbose > ../report/utilization.rpt
check_pg_drc  > ../report/pg_drc_final.rpt
check_routes -drc true > ../report/DRC.rpt
report_design > ../report/design.rpt
report_cell   > ../report/cells.rpt
report_qor    > ../report/qor.rpt
report_timing -delay_type min -nosplit > ../report/timing_min.rpt
report_timing -delay_type max -nosplit > ../report/timing_max.rpt
# ================================================ #
# =================== End_Step =================== #
# ================================================ #
write_def ../output/${design}.def
write_verilog -include {all} ../output/${design}.v
save_block ;
# ================================================ #
# ================== Start_Step ================== #
# ================================================ #
set_host_options -max_cores 6 

set design counter
##sh rm ../../2_design_library/${design}.dlib/${design}_pl/design.ndm.lock

set design_lib_path /home/ICer/Downloads/counter/pnr/2_design_library
open_block $design_lib_path/${design}.dlib:${design}_cts.design
copy_block -from_block ${design}.dlib:${design}_cts.design -to_block ${design}_route
current_block ${design}_route.design
start_gui

# ================================================ #
# =================== Pre-Route ================== #
# ================================================ # 
#  check for any issues that might cause problems during routing
check_design -checks routability 
# --All layers below M1 and above M9 are set as ignored layers.
set_ignored_layer -max M9 -min M1
# ================================================ #
# ================== Global Route ================ #
# ================================================ # 

route_global
check_routes
# ================================================ #
# ================= Track Assign ================= #
# ================================================ # 
route_track
check_routes


# ================================================ #
# =============== Detailed Route ================= #
# ================================================ # 
route_detail
check_routes
route_detail -incremental true
check_routes

# ================================================ #
# =================== Filler ===================== #
# ================================================ #
get_lib_cell saed90nm_max/SHF*
set FillerCells " saed90nm_max/SHFILL1 saed90nm_max/SHFILL2 saed90nm_max/SHFILL3  "

create_stdcell_fillers -lib_cells $FillerCells
create_stdcell_fillers -lib_cells saed90nm_max/SHFILL3
create_stdcell_fillers -lib_cells saed90nm_max/SHFILL1
connect_pg_net -net "VDD" [get_pins -hierarchical "*/VDD*"]
connect_pg_net -net "VSS" [get_pins -hierarchical "*/VSS"]
check_routes
check_pg_drc

remove_stdcell_fillers_with_violation

check_legality


# ================================================ #
# =================== Connect ==================== #
# ================================================ # 

# ================================================ #
# =================== Reports ==================== #
# ================================================ # 
check_routes > ../report/drc_final.rpt
check_lvs -max_error 0 > ../report/lvs_final.rpt
check_clock_trees > ../report/clock_trees.rpt 
report_congestion -nosplit > ../report/congestion.rpt 
check_legality -verbose    > ../report/legality

# ================================================ #
# ================== End_Steps =================== #
# ================================================ # 
write_def ../output/${design}.def
write_verilog -include {all} ../output/${design}.v
write_parasitics -format spef  -output ../output/${design}
save_block -as cv32e40p_top.dlib:cv32e40p_top_route.design
report_area -include filler
report_area -physical_only


