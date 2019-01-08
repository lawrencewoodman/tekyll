set tekyllTcl "# File created using tekyll: https://github.com/lawrencewoodman/tekyll\n\n"
append tekyllTcl [
  ornament [regsub -line -all {^#>(.*)$} \
                   [read -directory [dir root] main.tcl] {\1}]
]

write [file join [dir build] tekyll.tcl] $tekyllTcl
