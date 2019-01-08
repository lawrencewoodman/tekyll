# Copyright (C) 2018-2019 Lawrence Woodman <lwoodman@vlifesystems.com>
# Licensed under an MIT licence.  Please see LICENCE.md for details.

package require fileutil::traverse

# The lines beginning '#>' will have the '#>' removed if processed by
# tekyll to create a single file, so that those lines can instruct
# ornament what to do.
#>! if 0 {
set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir lib]
source [file join $LibDir init.tcl]
source [file join $LibDir misc.tcl]
source [file join $LibDir markdown.tcl]
source [file join $LibDir cmds.tcl]
#>! }
#>!* commandSubst true
#>[read -directory [dir lib] init.tcl]
#>[read -directory [dir lib] misc.tcl]
#>[read -directory [dir lib] cmds.tcl]
#>!* commandSubst false


proc loadVars {} {
  set fp [open tekyll.cfg r]
  set script [ornament compile [read $fp]]
  set cmds [cmds::new]
  set vars [ornament run $script $cmds]
  close $fp
  return $vars
}

proc getInitFiles {vars} {
  set contentWalker [::fileutil::traverse %AUTO% [getDir $vars init]]
  $contentWalker foreach file {
    if {[file isfile $file]} {
      lappend files $file
    }
  }
  return $files
}

proc processInitFiles {vars files} {
  set files [lsort $files]
  foreach file $files {
    init::process $file $vars
  }
}

set vars [loadVars]
set initFiles [getInitFiles $vars]
processInitFiles $vars $initFiles
