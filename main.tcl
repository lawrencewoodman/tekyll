# Copyright (C) 2018-2019 Lawrence Woodman <lwoodman@vlifesystems.com>
# Licensed under an MIT licence.  Please see LICENCE.md for details.

package require fileutil::traverse
package require cmdline

# The lines beginning '#>' will have the '#>' removed if processed by
# tekyll to create a single file, so that those lines can instruct
# ornament what to do.
#>! if 0 {
set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir lib]
set VendorDir [file join $ThisScriptDir vendor]
source [file join $VendorDir xproc-0.1.tm]
source [file join $LibDir init.tcl]
source [file join $LibDir misc.tcl]
source [file join $LibDir markdown.tcl]
source [file join $LibDir cmds.tcl]
source [file join $LibDir channelmonitor.tcl]
source [file join $LibDir test.tcl]
#>! }
#>!* commandSubst true
#>[read -directory [dir lib] init.tcl]
#>[read -directory [dir lib] misc.tcl]
#>[read -directory [dir lib] markdown.tcl]
#>[read -directory [dir lib] cmds.tcl]
#>[read -directory [dir lib] channelmonitor.tcl]
#>[read -directory [dir lib] test.tcl]
#>[read -directory [dir vendor] xproc-0.1.tm]
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

proc getPluginFiles {vars} {
  set files {}
  try {
    getDir $vars plugins
  } on error {} {
    return {}
  }
  set contentWalker [::fileutil::traverse %AUTO% [getDir $vars plugins]]
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

proc testFiles {vars files} {
  set files [lsort $files]
  set allPass true
  foreach file $files {
    try {
      if {![test::runTests $file $vars]} {
        set allPass false
      }
    } on error {result} {
      puts "Error: $result"
      set allPass false
    }
  }
  if {!$allPass} {
    exit 1
  }
}

proc main {args} {
  set options {
    {test     "Run tests"}
  }
  set usage ": tekyll \[options]\noptions:"
  try {
    array set params [::cmdline::getoptions args $options $usage]
  } trap {CMDLINE USAGE} {msg o} {
    puts $msg
    exit 1
  }

  set vars [loadVars]
  set initFiles [getInitFiles $vars]

  if {$params(test)} {
    set pluginFiles [getPluginFiles $vars]
    testFiles $vars $pluginFiles
  }

  processInitFiles $vars $initFiles
}

main {*}$argv
