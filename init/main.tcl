write [file join [dir build] tekyll.tcl] [
  ornament [regsub -line -all {^#>(.*)$} \
                   [read -directory [dir root] main.tcl] {\1}]
]
