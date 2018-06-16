# Copyright (C) 2018 Lawrence Woodman <lwoodman@vlifesystems.com>
# Licensed under an MIT licence.  Please see LICENCE.md for details.

package require htmlparse
package require cmdline

namespace eval ::site {

  namespace eval cmds {
    namespace export {[a-z]*}
    namespace ensemble create
  }

  proc cmds::new {mode {vars {}}} {
    set cmds [dict create \
      collection [namespace which CmdCollection] \
      getvar [list [namespace which CmdGetVar] $vars] \
      getparams [list [namespace which CmdGetParams] $vars] \
      log [namespace which CmdLog] \
      markdownify [list [namespace which CmdMarkdownify] $vars] \
      ornament [list [namespace which CmdOrnament] $vars] \
      source [list [namespace which CmdSource] $vars]\
      read [list [namespace which CmdRead] $vars] \
      strip_html [namespace which CmdStripHTML] \
    ]
    set additionalMapCmds [dict create \
      file [list [namespace which CmdFile] $vars] \
      glob [namespace which CmdGlob] \
      write [list [namespace which CmdWrite] $vars] \
    ]
    switch $mode {
      ornament {
        return $cmds
      }
      map {
        return [dict merge $cmds $additionalMapCmds]
      }
      default {
        error "unknown mode: $mode"
      }
    }
  }

  proc cmds::CmdCollection {int name} {
    return [::site::mapper::getCollection $name]
  }

  proc cmds::CmdFile {vars int subCommand args} {
    # TODO: Ensure this is located within safe locatons: site, content, etc
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

  # DOCUMENT: Takes wildcards and target based off destination/baseurl/
  # DOCUMENT: -force is set
  proc cmds::SafeCopy {vars args} {
    try {
      set target [lindex $args end]
      if {![CheckPermissions $vars $target w]} {
        return -code error "file copy: permission denied for: $target"
      }
      file mkdir $target
      set args [lrange $args 0 end-1]
      set numFiles 0
      foreach arg $args {
        set files [glob $arg]
        foreach file $files {
          if {![CheckPermissions $vars $file r]} {
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
      if {![CheckPermissions $vars $file r]} {
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
    if {![CheckPermissions $vars $filename r]} {
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
    # TODO: Work out whether should log to stderr or stdout
    set timeStamp [clock format [clock seconds] -format {%Y-%m-%d}]
    puts [format "%s  %8s  %s" $timeStamp $level $msg]
  }

  proc cmds::collectText {varName args} {
    upvar 2 $varName var
    append var [lindex $args 3]
  }

  proc cmds::CmdStripHTML {int html} {
    htmlparse::parse -cmd [list [namespace which collectText] text] $html
    return $text
  }

  proc cmds::CmdMarkdownify {vars int text} {
    set cmd [dict get $vars build markdown cmd]
    try {
      return [exec -- $cmd << $text]
    } on error {result} {
      return -code error \
          "markdownify: error from external command: $cmd, $result"
    }
  }

  proc cmds::CmdOrnament {vars int args} {
    set options {
      {params.arg {} {Parameters to pass to the template}}
      {directory.arg {} {Which directory the file is located in}}
    }
    set usage ": ornament \[options] filename\noptions:"
    set parsed [::cmdline::getoptions args $options $usage]

    if {[llength $args] != 1} {
      return -code error \
        "ornament: wrong number of arguments\n[::cmdline::usage $options $usage]"
    }

    set filename [file join [dict get $parsed directory] [lindex $args 0]]
    if {![CheckPermissions $vars $filename r]} {
      return -code error "ornament: permission denied for: $filename"
    }
    try {
      set fp [open $filename r]
      set template [read $fp]
      close $fp
      dict set vars params [dict get $parsed params]
      set script [ornament compile $template]
      set cmds [::site::cmds::new ornament $vars]
      return [ornament run $script $cmds]
    } on error {result} {
      return -code error "ornament: error in $filename, $result"
    }
  }

  proc cmds::CmdGetVar {vars int args} {
    set options {
      {noerror {Don't return error if key not found}}
      {default.arg {} {What to default to in case var doesn't exist}}
    }
    set usage ": getvar \[options] key ?key ..?\noptions:"
    set parsed [::cmdline::getoptions args $options $usage]

    # TODO: only allow file and site vars
    if {[dict exists $vars {*}$args]} {
      return [dict get $vars {*}$args]
    }
    if {![dict get $parsed noerror]} {
      return -code error "getvar: key doesn't exist: $args"
    }
    return [dict get $parsed default]
  }

  proc cmds::CmdGetParams {vars int args} {
    set options {
      {noerror {Don't return error if key not found}}
      {default.arg {} {What to default to in case var doesn't exist}}
    }
    set usage ": getparams \[options] key ?key ..?\noptions:"
    set parsed [::cmdline::getoptions args $options $usage]

    if {[dict exists $vars params {*}$args]} {
      return [dict get $vars params {*}$args]
    }
    if {![dict get $parsed noerror] && [dict get $parsed default] eq ""} {
      return -code error "getparams: key doesn't exist: $args"
    }
    return [dict get $parsed default]
  }

  # wantPermissions is a string
  # Returns true if wanted permissions all found, otherwise false
  proc cmds::CheckPermissions {vars path wantPermissions} {
    set path [file normalize $path]
    foreach d [dict get $vars build dirs] {
      lassign $d buildDir buildPermissions
      set buildDir [file normalize $buildDir]
      set lengthBuildDir [string length $buildDir]
      if {$buildDir eq [string range $path 0 $lengthBuildDir-1]} {
        foreach p [split $wantPermissions {}] {
          if {[string first $p $buildPermissions] == -1} {
            return false
          }
        }
        return true
      }
    }
    return false
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
    if {![CheckPermissions $vars $filename r]} {
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
    if {![CheckPermissions $vars $filename w]} {
      return -code error "write: permission denied for: $filename"
    }
    set content [lindex $args 1]

    # TODO: Only allow to write to destination directory
    file mkdir [file dirname $filename]
    set fp [open $filename w]
    if {[dict get $parsed binary]} {
      fconfigure $fp -translation binary
    }
    puts -nonewline $fp $content
    close $fp
  }

  namespace export cmds
}
