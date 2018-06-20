write [file join [dir build] tekyll.tcl] [
  ornament [regsub -line -all {^#>(.*)$} [read main.tcl] {\1}]
]
