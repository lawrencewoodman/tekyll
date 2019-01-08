# Copyright (C) 2018-2019 Lawrence Woodman <lwoodman@vlifesystems.com>
# Licensed under an MIT licence.  Please see LICENCE.md for details.

package require htmlparse
package require cmdline
package require ornament

namespace eval cmds {
  namespace export {[a-z]*}
  namespace ensemble create
  variable collections [dict create]
}

proc cmds::new {{vars {}}} {
  set cmds [dict create \
    collection [namespace which CmdCollection] \
    dir [list [namespace which CmdDir] $vars] \
    getvar [list [namespace which CmdGetVar] $vars] \
    getparam [list [namespace which CmdGetParam] $vars] \
    log [namespace which CmdLog] \
    markdown [list [namespace which CmdMarkdown] $vars] \
    ornament [list [namespace which CmdOrnament] $vars] \
    source [list [namespace which CmdSource] $vars]\
    read [list [namespace which CmdRead] $vars] \
    strip_html [namespace which CmdStripHTML] \
    file [list [namespace which CmdFile] $vars] \
    glob [namespace which CmdGlob] \
    write [list [namespace which CmdWrite] $vars] \
  ]
}

proc cmds::CmdCollection {int subCommand args} {
  set subCommands {
    get {numArgs 1 cmd CmdCollectionGet}
    add {numArgs 2 cmd CmdCollectionAdd}
  }
  if {![dict exists $subCommands $subCommand]} {
    return -code error "collection: invalid subcommand: $subCommand"
  }
  dict with subCommands $subCommand {
    if {[llength $args] != $numArgs} {
      return -code error "collection $subCommand: wrong # args"
    }
    return [$cmd {*}$args]
  }
}


proc cmds::CmdCollectionGet {name} {
  variable collections
  if {![dict exists $collections $name]} {
    return -code error "collection get: unknown name: $name"
  }
  return [dict get $collections $name]
}


proc cmds::CmdCollectionAdd {collection vars} {
  variable collections
  dict lappend collections $collection $vars
}


# Lookup the proper directory using its shortName and then file join
# the rest of the args to make its full name.  The dirs are stored
# in build > dirs.
proc cmds::CmdDir {vars int shortName args} {
  try {
    return [getDir $vars $shortName {*}$args]
  } on error {result} {
    return -code error "dir: $result"
  }
}


proc cmds::CmdFile {vars int subCommand args} {
  switch $subCommand {
    copy {
      return [SafeCopy $vars {*}$args]
    }
    join  {
      return [file join {*}$args]
    }
    tail {
      return [file tail {*}$args]
    }
  }
  return -code error \
         "file: unknown subcommand \"$subCommand\" for file: must be join"
}

# DOCUMENT: -force is set
proc cmds::SafeCopy {vars args} {
  try {
    set target [lindex $args end]
    if {![checkPermissions $vars $target w]} {
      return -code error "file copy: permission denied for: $target"
    }
    file mkdir $target
    set args [lrange $args 0 end-1]
    set numFiles 0
    foreach arg $args {
      set files [glob -- $arg]
      foreach file $files {
        if {![checkPermissions $vars $file r]} {
          return -code error "file copy: permission denied for: $file"
        }
      }
      incr numFiles [llength $files]
      file copy -force {*}$files $target
    }
    return $numFiles
  } on error {result} {
    return -code error "file copy: $result"
  }
}

proc cmds::CmdGlob {int args} {
  try {
    set files [glob {*}$args]
  } on error {result options} {
    return -code error "glob: $result"
  }
  foreach file $files {
    if {![checkPermissions $vars $file r]} {
      return -code error "glob: permission denied for: $file"
    }
  }
  return $files
}

proc cmds::CmdSource {vars int args} {
  set options {
    {directory.arg {} {Which directory the file is located in}}
  }
  set usage ": source \[options] filename\noptions:"
  set parsed [::cmdline::getoptions args $options $usage]

  if {[llength $args] != 1} {
    return -code error \
      "source: wrong number of arguments\n[::cmdline::usage $options $usage]"
  }

  set directory [dict get $parsed directory]
  set filename [file join $directory [lindex $args 0]]
  if {![checkPermissions $vars $filename r]} {
    return -code error "source: permission denied for: $filename"
  }
  try {
    set fp [open $filename r]
    set content [read $fp]
    close $fp
    return [$int eval $content]
  } on error {result} {
    return -code error "source: error in script: $filename, $result"
  }
}

proc cmds::CmdLog {int level msg} {
  set validLevels {info warning error}
  if {[lsearch $validLevels $level] == -1} {
    return -code error "log: unknown level: $level"
  }
  set channelID stdout
  set timeStamp [clock format [clock seconds] -format {%Y-%m-%d}]
  if {$level eq "error"} {
    set channelID stderr
  }
  puts $channelID [format "%s  %8s  %s" $timeStamp $level $msg]
}

proc cmds::collectText {varName args} {
  upvar 2 $varName var
  append var [lindex $args 3]
}

proc cmds::CmdStripHTML {int html} {
  htmlparse::parse -cmd [list [namespace which collectText] text] $html
  return $text
}

proc cmds::CmdMarkdown {vars int args} {
  set options {
    {directory.arg {} {Which directory the file is located in}}
    {file.arg {} {Which file to process}}
  }
  set usage "markdown \[options] ?text?\noptions:"
  set parsed [::cmdline::getoptions args $options $usage]

  set directory [dict get $parsed directory]
  set filename [dict get $parsed file]
  if {$filename ne ""} {
    if {[llength $args] > 0} {
      return -code error "markdown: wrong # args"
    }
  } elseif {$directory ne ""} {
      return -code error \
        "markdown: can't use -directory without -file"
  } elseif {[llength $args] != 1} {
      return -code error "markdown: wrong # args"
  }

  if {[llength $args] == 1} {
    try {
      return [markdown render [lindex $args 0]]
    } on error {result} {
      return -code error "markdown: $result"
    }
  } else {
    set filename [file join $directory $filename]
    if {![checkPermissions $vars $filename r]} {
      return -code error "markdown: permission denied for: $filename"
    }
    try {
      return [markdown renderFile $filename]
    } on error {result} {
      return -code error "markdown: $result"
    }
  }
}

proc cmds::CmdOrnament {vars int args} {
  set options {
    {params.arg {} {Parameters to pass to the template}}
    {directory.arg {} {Which directory the file is located in}}
    {file.arg {} {Which file to process}}
  }
  set usage ": ornament \[options] filename\noptions:"
  set parsed [::cmdline::getoptions args $options $usage]

  set directory [dict get $parsed directory]
  set filename [dict get $parsed file]
  if {$filename ne ""} {
    if {[llength $args] > 0} {
      return -code error "ornament: wrong # args"
    }
  } elseif {$directory ne ""} {
      return -code error \
        "ornament: can't use -directory without -file"
  } elseif {[llength $args] != 1} {
      return -code error "ornament: wrong # args"
  }

  if {$filename ne ""} {
    set filename [file join $directory $filename]
    if {![checkPermissions $vars $filename r]} {
      return -code error "ornament: permission denied for: $filename"
    }
    try {
      set fp [open $filename r]
    } on error {result} {
      return -code error "ornament: $result"
    }
    try {
      set template [read $fp]
      if {[string index $template end] == "\n"} {
        set template [string range $template 0 end-1]
      }
    } on error {result} {
      return -code error "ornament: error in $filename, $result"
    } finally {
      close $fp
    }
  } else {
    set template [lindex $args 0]
  }
  try {
    dict set vars params [dict get $parsed params]
    set cmds [new $vars]
    set script [ornament compile $template]
    return [ornament run $script $cmds]
  } on error {result} {
    if {$filename ne ""} {
      return -code error "ornament: error in $filename, $result"
    } else {
      return -code error "ornament: $result"
    }
  }
}

proc cmds::CmdGetVar {vars int args} {
  array set options {}
  while {[llength $args]} {
    switch -glob -- [lindex $args 0] {
      -default {set args [lassign $args - options(default)]}
      --      {set args [lrange $args 1 end] ; break}
      -*      {error "getvar: unknown option [lindex $args 0]"}
      default break
    }
  }
  if {[llength $args] == 0} {
    return -code error "getvar: invalid number of arguments"
  }

  if {[dict exists $vars {*}$args]} {
    return [dict get $vars {*}$args]
  }
  if {[info exists options(default)]} {
    return $options(default)
  }
  return -code error "getvar: unknown key: $args"
}

proc cmds::CmdGetParam {vars int args} {
  array set options {}
  while {[llength $args]} {
    switch -glob -- [lindex $args 0] {
      -default {set args [lassign $args - options(default)]}
      --      {set args [lrange $args 1 end] ; break}
      -*      {error "getparam: unknown option [lindex $args 0]"}
      default break
    }
  }
  if {[dict exists $vars params {*}$args]} {
    return [dict get $vars params {*}$args]
  }
  if {[info exists options(default)]} {
    return $options(default)
  }
  return -code error "getparam: unknown key: $args"
}

proc cmds::CmdRead {vars int args} {
  set options {
    {binary {Whether to use binary translation}}
    {directory.arg {} {Which directory the file is located in}}
  }
  set usage ": read \[options] filename\noptions:"
  set parsed [::cmdline::getoptions args $options $usage]

  if {[llength $args] != 1} {
    return -code error \
      "read: wrong number of arguments\n[::cmdline::usage $options $usage]"
  }

  set filename [file join [dict get $parsed directory] [lindex $args 0]]
  if {![checkPermissions $vars $filename r]} {
    return -code error "read: permission denied for: $filename"
  }
  set fp [open $filename r]
  if {[dict get $parsed binary]} {
    fconfigure $fp -translation binary
  }
  set content [read $fp]
  close $fp
  return $content
}

proc cmds::CmdWrite {vars int args} {
  set options {
    {binary {Whether to use binary translation}}
  }

  set usage ": write \[options] filename content\noptions:"
  set parsed [::cmdline::getoptions args $options $usage]

  if {[llength $args] != 2} {
    return -code error \
      "write: wrong number of arguments\n[::cmdline::usage $options $usage]"
  }

  set filename [lindex $args 0]
  if {![checkPermissions $vars $filename w]} {
    return -code error "write: permission denied for: $filename"
  }
  set content [lindex $args 1]

  file mkdir [file dirname $filename]
  set fp [open $filename w]
  if {[dict get $parsed binary]} {
    fconfigure $fp -translation binary
  }
  puts -nonewline $fp $content
  close $fp
}

namespace export cmds
