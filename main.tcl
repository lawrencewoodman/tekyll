# Copyright (C) 2018 Lawrence Woodman <lwoodman@vlifesystems.com>
# Licensed under an MIT licence.  Please see LICENCE.md for details.

package require fileutil::traverse

set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir lib]

source [file join $LibDir mapper.tcl]
source [file join $LibDir cmds.tcl]

# Load vars
set fp [open tekyll.cfg r]
set script [ornament compile [read $fp]]
set cmds [::site::cmds::new map]
set vars [ornament run $script $cmds]
close $fp

set contentWalker [::fileutil::traverse %AUTO% scripts]

$contentWalker foreach file {
  if {[file isfile $file]} {
    lappend files $file
  }
}

set files [lsort $files]
foreach file $files {
  puts "Processing: $file"
  ::site::mapper process $file $vars
}
