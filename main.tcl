# Copyright (C) 2018 Lawrence Woodman <lwoodman@vlifesystems.com>
# Licensed under an MIT licence.  Please see LICENCE.md for details.

package require fileutil::traverse

set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir lib]

source [file join $LibDir mapper.tcl]
source [file join $LibDir cmds.tcl]

# Load vars
set fp [open config.dict r]
set vars [read $fp]
close $fp

# baseurl could by someting like: /myuser
# so you could have: http://example.com/myuser/blog/...
# which would be [dict get $siteVars url][dict get $siteVars baseurl]/blog

set contentWalker [::fileutil::traverse %AUTO% [dict get $vars config scripts]]

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
