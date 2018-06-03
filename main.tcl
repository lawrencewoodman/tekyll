# Copyright (C) 2018 Lawrence Woodman <lwoodman@vlifesystems.com>
# Licensed under an MIT licence.  Please see LICENCE.md for details.

package require fileutil::traverse

set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir lib]

source [file join $LibDir mapper.tcl]
source [file join $LibDir cmds.tcl]
source [file join $LibDir parsers.tcl]

set vars [dict create \
  config [dict create \
    destination [file normalize site] \
    root [file normalize [pwd]] \
  ] \
  site [dict create \
    title "The site's title" \
    description "The site's description" \
    url "http://example.com" \
    baseurl "" \
  ]
]

# baseurl could by someting like: /myuser
# so you could have: http://example.com/myuser/blog/...
# which would be [dict get $siteVars url][dict get $siteVars baseurl]/blog

set contentWalker [::fileutil::traverse %AUTO% content]

$contentWalker foreach file {
  if {[file tail $file] eq "_map"} {
    set dir [file dirname $file]
    puts "Processing: $dir"
    ::site::mapper process $dir $vars
  }
}
