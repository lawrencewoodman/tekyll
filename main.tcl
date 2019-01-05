# Copyright (C) 2018 Lawrence Woodman <lwoodman@vlifesystems.com>
# Licensed under an MIT licence.  Please see LICENCE.md for details.

package require fileutil::traverse

#>! if 0 {
set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir lib]
source [file join $LibDir mapper.tcl]
source [file join $LibDir misc.tcl]
source [file join $LibDir markdown.tcl]
source [file join $LibDir cmds.tcl]
#>! }
#>!* commandSubst true
#>[read -directory [dir lib] mapper.tcl]
#>[read -directory [dir lib] misc.tcl]
#>[read -directory [dir lib] cmds.tcl]
#>!* commandSubst false

# Load vars
set fp [open tekyll.cfg r]
set script [ornament compile [read $fp]]
set cmds [cmds::new]
set vars [ornament run $script $cmds]
close $fp

set contentWalker [::fileutil::traverse %AUTO% [getDir $vars init]]

$contentWalker foreach file {
  if {[file isfile $file]} {
    lappend files $file
  }
}

set files [lsort $files]
foreach file $files {
  mapper process $file $vars
}
