#Generated by Fabric Compiler ( version 2022.2-Lite <build 118454> ) at Mon Nov  6 21:16:26 2023

add_design C:/Users/pc/Desktop/paihui/pds project/ddr3_test/ddr3_test/ipcore/ddr3/ddr3.idf
remove_design -force C:/Users/pc/Desktop/paihui/pds project/ddr3_test/ddr3_test/ipcore/ddr3/ddr3.idf
add_design C:/Users/pc/Desktop/paihui/pds project/ddr3_test/ddr3_test/ipcore/ddr3_test/ddr3_test.idf
remove_design -force C:/Users/pc/Desktop/paihui/pds project/ddr3_test/ddr3_test/ipcore/ddr3_test/ddr3_test.idf
add_design C:/Users/pc/Desktop/paihui/pds project/ddr3_test/ddr3_test/ipcore/ddr3_test/ddr3_test.idf
add_design "C:/Users/pc/Desktop/paihui/pds project/ddr3_test/ddr3_test/source/ddr3_test/ddr3_test.v"
remove_design -force -verilog "C:/Users/pc/Desktop/paihui/pds project/ddr3_test/ddr3_test/source/ddr3_test/ddr3_test.v"
add_design "C:/Users/pc/Desktop/paihui/pds project/ddr3_test/ddr3_test/source/source/ddr3_test/ddr3_test1.v"
add_constraint "C:/Users/pc/Desktop/paihui/download/07_ddr3_test/constraint_backup/ddr3_test_2023_10_02_12_09_25.fdc"
set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module ddr3_test1
synthesize -ads -selected_syn_tool_opt 2 
synthesize -ads -selected_syn_tool_opt 2 
synthesize -ads -selected_syn_tool_opt 2 
set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module ddr3_test1
synthesize -ads -selected_syn_tool_opt 2 
synthesize -ads -selected_syn_tool_opt 2 
set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module ddr3_test1
synthesize -ads -selected_syn_tool_opt 2 
add_fic "C:/Users/pc/Desktop/paihui/pds project/ddr3_test/ddr3_test/synthesize/ddr3_test1_syn.fic"
dev_map 
dev_map 
remove_fic -force"C:/Users/pc/Desktop/paihui/pds project/ddr3_test/ddr3_test/synthesize/ddr3_test1_syn.fic"
dev_map 
pnr 
pnr 
set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module ddr3_test1
synthesize -ads -selected_syn_tool_opt 2 
dev_map 
pnr 
set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module ddr3_test1
synthesize -ads -selected_syn_tool_opt 2 
set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module ddr3_test1
synthesize -ads -selected_syn_tool_opt 2 
set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module ddr3_test1
synthesize -ads -selected_syn_tool_opt 2 
dev_map 
pnr 
report_timing 
gen_bit_stream 
add_fic "C:/Users/pc/Desktop/paihui/pds project/ddr3_test/ddr3_test/synthesize/ddr3_test1_syn.fic"
set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module ddr3_test1
synthesize -ads -selected_syn_tool_opt 2 
dev_map 
dev_map 
remove_fic -force"C:/Users/pc/Desktop/paihui/pds project/ddr3_test/ddr3_test/synthesize/ddr3_test1_syn.fic"
add_fic "C:/Users/pc/Desktop/paihui/pds project/ddr3_test/ddr3_test/synthesize/ddr3_test1_syn.fic"
dev_map 
dev_map 
dev_map 
set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module ddr3_test1
synthesize -ads -selected_syn_tool_opt 2 
dev_map 
dev_map 
pnr 
report_timing 
gen_bit_stream 
set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module ddr3_test1
synthesize -ads -selected_syn_tool_opt 2 
set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module ddr3_test1
synthesize -ads -selected_syn_tool_opt 2 
set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module ddr3_test1
synthesize -ads -selected_syn_tool_opt 2 
set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module ddr3_test1
synthesize -ads -selected_syn_tool_opt 2 
dev_map 
pnr 
report_timing 
gen_bit_stream 
set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module ddr3_test1
synthesize -ads -selected_syn_tool_opt 2 
dev_map 
pnr 
report_timing 
gen_bit_stream 
set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module ddr3_test1
synthesize -ads -selected_syn_tool_opt 2 
dev_map 
pnr 
report_timing 
gen_bit_stream 
set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module ddr3_test1
synthesize -ads -selected_syn_tool_opt 2 
dev_map 
pnr 
report_timing 
gen_bit_stream 
set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module ddr3_test1
synthesize -ads -selected_syn_tool_opt 2 
set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module ddr3_test1
synthesize -ads -selected_syn_tool_opt 2 
dev_map 
pnr 
report_timing 
gen_bit_stream 
set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module ddr3_test1
synthesize -ads -selected_syn_tool_opt 2 
dev_map 
pnr 
report_timing 
gen_bit_stream 
set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module ddr3_test1
synthesize -ads -selected_syn_tool_opt 2 
dev_map 
pnr 
report_timing 
gen_bit_stream 
add_constraint "C:/Users/smn90/repo/Multi-channel-video-splicing/project.old/ddr3_test/ddr3_test/source/ddr3_test_2023_10_02_12_09_25.fdc"
remove_constraint -force -logic -fdc "C:/Users/smn90/repo/Multi-channel-video-splicing/download/07_ddr3_test/constraint_backup/ddr3_test_2023_10_02_12_09_25.fdc"
set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module ddr3_test1
synthesize -ads -selected_syn_tool_opt 2 
dev_map 
pnr 
report_timing 
gen_bit_stream 
