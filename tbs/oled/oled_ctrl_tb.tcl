#Maximize window
wm state . zoom

#Show all as hex
radix -hexadecimal

puts {
  AXI Stream Divider Test Bench
}

# Simply change the project settings in this section
# for each new project. There should be no need to
# modify the rest of the script.

set library_file_list {
    design_library {
        "./src/oled/oled_char_lib.vhd"
        "./src/oled/oled_data_ctrl.vhd"
        "./src/oled/oled_ctrl.vhd"
        "./src/oled/oled_delay.vhd"
        "./src/oled/oled_init_ctrl.vhd"
        "./src/oled/oled_spi_ctrl.vhd"
    }
    test_library   {
        "./tbs/oled/oled_ctrl_tb.vhd"
    }
}
set top_level test_library.oled_ctrl_tb
set wave_patterns {
    /*
    /uut/*
    /uut/oled_init_ctrl_inst/*
    /uut/oled_data_ctrl_inst/*
}
set wave_radices {
    unsigned {n d q r r2 i}
    unsigned {check_n check_d check_q check_r}
}

# After sourcing the script from ModelSim for the
# first time use these commands to recompile.
proc q  {} {
    quit -force
}

# Compile out of date files
set time_now [clock seconds]
if [catch {set last_compile_time}] {
  set last_compile_time 0
}

foreach {library file_list} $library_file_list {
  vlib $library
  vmap work $library
  foreach file $file_list {
    if { $last_compile_time < [file mtime $file] } {
      if [regexp {.vhd?$} $file] {
        vcom -93 $file
      } else {
        vlog $file
      }
      set last_compile_time 0
    }
  }
}

set last_compile_time $time_now

eval vsim -novopt $top_level -L design_library

if [llength $wave_patterns] {
  noview wave
  foreach pattern $wave_patterns {
    add wave -noupdate -divider
    add wave $pattern
  }
  configure wave -signalnamewidth 1
  foreach {radix signals} $wave_radices {
    foreach signal $signals {
      catch {property wave -radix $radix $signal}
    }
  }
}

# Run the simulation
run 7us

