#Maximize window
wm state . zoom

radix -hexadecimal

puts {
  AXI Stream Divider Test Bench
}

# Simply change the project settings in this section
# for each new project. There should be no need to
# modify the rest of the script.

set library_file_list {
    design_library {"./src/utils/axis_reg.vhd"}
    test_library   {"./tbs/utils/axis_reg_tb.vhd"}
}
set top_level test_library.axis_reg_tb
set wave_patterns {
    /*
    /uut/*
}
set wave_radices {
    unsigned {
        *in_s_tdata*
        *out_m_tdata*
    }
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

eval vsim $top_level -L design_library

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
run 10us

wave zoom full
