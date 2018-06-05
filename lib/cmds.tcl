# Copyright (C) 2018 Lawrence Woodman <lwoodman@vlifesystems.com>
# Licensed under an MIT licence.  Please see LICENCE.md for details.

package require htmlparse
package require cmdline

namespace eval ::site {

  namespace eval cmds {
    namespace export {[a-z]*}
    namespace ensemble create
  }

  proc cmds::new {mode vars} {
    set cmds [dict create \
      collection [namespace which CmdCollection] \
      getvar [list [namespace which CmdGetVar] $vars] \
      getparams [list [namespace which CmdGetParams] $vars] \
      include [list [namespace which CmdInclude] $vars] \
      log [namespace which CmdLog] \
      markdownify [namespace which CmdMarkdownify] \
      ornament [list [namespace which CmdOrnament] $vars] \
      plugin [list [namespace which CmdPlugin] $vars]\
      strip_html [namespace which CmdStripHTML] \
    ]
    set additionalMapCmds [dict create \
      file [list [namespace which CmdFile] $vars] \
      glob [namespace which CmdGlob] \
      read [namespace which CmdRead] \
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
      set target [makeFinalPath \
        [dict get $vars config destination] \
        [dict get $vars site baseurl] \
        [lindex $args end] \
      ]
      file mkdir $target
      set args [lrange $args 0 end-1]
      set numFiles 0
      foreach arg $args {
        set files [glob $arg]
        incr numFiles [llength $files]
        file copy -force {*}$files $target
      }
      return $numFiles
    } on error {result} {
      return -code error "file copy: $result"
    }
  }

  proc cmds::CmdGlob {int args} {
    # TODO: Restrict to content directory
    try {
      return [glob {*}$args]
    } on error {result options} {
      return -code error "glob: $result"
    }
  }

  proc cmds::CmdPlugin {vars int filename} {
    try {
      set pluginsDir [file join [dict get $vars config root] plugins]
      set fp [open [file join $pluginsDir $filename] r]
      set content [read $fp]
      close $fp
    } on error {result options} {
      return -code error "plugin: error in script: $filename, $result"
    }
    return [$int eval $content]
  }

  # TODO: For security, force all includes to be relative to the include dir
  # Default parsers {ornament}
  proc cmds::CmdInclude {vars int args} {
    set options {
      {parsers.arg {ornament}
         {which parsers to process file (ornament, markdown)}}
      {parameters.arg  ""
         {a dictionary of parameters that will be included in the vars}}
    }

    set usage ": include \[options] filename\noptions:"
    set parsed [::cmdline::getoptions args $options $usage]

    if {[llength $args] != 1} {
      return -code error \
        "include: wrong number of arguments\n[::cmdline::usage $options $usage]"
    }

    dict for {optionName optionValue} $parsed {
      switch $optionName {
        "parameters" {
          if {[llength $optionValue] > 0} {
            dict set vars parameters $optionValue
          }
        }
      }
    }
    set filename [lindex $args 0]

    set includesDir [file join [dict get $vars config root] includes]
    set fp [open [file join $includesDir $filename] r]
    set content [read $fp]
    close $fp
    dict set vars content $content

    foreach parser [dict get $parsed "parsers"] {
      set content [::site::parsers::parse $vars $parser $content]
      dict set vars content $content
    }
    return $content
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

  proc cmds::CmdMarkdownify {int text} {
    return [::Markdown::convert $text]
  }

  proc cmds::CmdOrnament {vars int template {parameterVars {}}} {
    dict set vars params $parameterVars
    set script [ornament compile $template]
    set cmds [::site::cmds::new ornament $vars]
    return [ornament run $script $cmds]
  }

  proc cmds::CmdGetVar {vars int args} {
    # TODO: only allow file and site vars
    if {[dict exists $vars {*}$args]} {
      return [dict get $vars {*}$args]
    }
    # TODO: Is this default a good idea
    return ""
  }

  proc cmds::CmdGetParams {vars int args} {
    # TODO: only allow file and site vars
    if {[dict exists $vars params {*}$args]} {
      return [dict get $vars params {*}$args]
    }
    # TODO: Is this default a good idea
    return ""
  }

  proc cmds::CmdRead {int args} {
    # TODO: Only allow to read from content directory or base off config>root
    set options {
      {binary {Whether to use binary translation}}
    }
    set usage ": read \[options] filename content\noptions:"
    set parsed [::cmdline::getoptions args $options $usage]

    if {[llength $args] != 1} {
      return -code error \
        "write: wrong number of arguments\n[::cmdline::usage $options $usage]"
    }

    dict for {optionName optionValue} $parsed {
      switch $optionName {
        "binary" {
          set binary true
        }
      }
    }

    set filename [lindex $args 0]
    set fp [open $filename r]
    if {$binary} {
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

    dict for {optionName optionValue} $parsed {
      switch $optionName {
        "binary" {
          set binary true
        }
      }
    }

    set filename [makeFinalPath \
      [dict get $vars config destination] \
      [dict get $vars site baseurl] \
      [lindex $args 0] \
    ]
    puts "write: filename: $filename"
    set content [lindex $args 1]

    # TODO: Only allow to write to destination directory
    file mkdir [file dirname $filename]
    set fp [open $filename w]
    if {$binary} {
      fconfigure $fp -translation binary
    }
    puts -nonewline $fp $content
    close $fp
  }

  proc cmds::makeFinalPath {destination baseurl path} {
    set splitPath [file split $path]
    if {[lindex $splitPath 0] eq "/"} {
      set splitPath [lrange $splitPath 1 end]
    }
    return [file join $destination $baseurl {*}$splitPath]
  }

  namespace export cmds
}
