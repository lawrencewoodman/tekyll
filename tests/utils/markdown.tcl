package require Markdown
package require cmdline

if {[llength $argv] == 1} {
  set filename [lindex $argv 0]
  set fp [open $filename r]
  set text [read $fp]
  close $fp
} elseif {[llength $argv] > 1} {
  puts stderr "wrong # args"
  exit
} else {
  set text [read stdin]
}

puts -nonewline [::Markdown::convert $text]
