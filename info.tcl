puts "auto_path: $auto_path"

foreach dir $auto_path {
  puts "$dir\n======================\n"
  foreach subDir [glob -directory $dir *] {
    if {[string first tcllib $subDir] >= 0} {
      puts "****$subDir"
      foreach f [glob -directory [file join $dir $subDir] *] {
        if {[string first markdown $f] >= 0} {
          puts "********$f"
        } else {
          puts "        $f"
        }
      }
    } else {
      puts "    $subDir"
    }
  }
}

set v [package require Markdown]
puts "Markdown version: $v"
puts "Markdown location: [package ifneeded Markdown $v]"
