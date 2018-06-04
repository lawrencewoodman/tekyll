# Copyright (C) 2018 Lawrence Woodman <lwoodman@vlifesystems.com>
# Licensed under an MIT licence.  Please see LICENCE.md for details.

package require Markdown
package require ornament

namespace eval ::site {

  # TODO: Rename siteDir throughout this file
  namespace eval mapper {
    namespace export {[a-z]*}
    namespace ensemble create
    variable collections [dict create]
  }

  proc mapper::process {file vars} {
    variable collections
    try {
      set cmds [::site::cmds::new map $vars]
      dict set cmds collect [namespace which CmdCollect]
      load $file $cmds $vars
      #ProcessFile $map $dir $vars
    } on error {result options} {
      return -code error "error processing: $file, $result"
    }
  }

  proc mapper::CmdCollect {int collection vars} {
    variable collections
    dict lappend collections $collection $vars
  }

  proc mapper::load {file cmds vars} {
    set safeInterp [interp create -safe]
    try {
      set fp [open $file r]
      set map [read $fp]
      close $fp

      $safeInterp eval {unset {*}[info vars]}
      dict for {templateCmdName cmdInvokation} $cmds {
        $safeInterp alias $templateCmdName {*}$cmdInvokation $safeInterp
      }
      # TODO: Should vars be set?
      #dict for {varName value} $vars {
      #  $safeInterp eval "set $varName $value"
      #}
      return [$safeInterp eval $map]
    } on error {result options} {
      return -code error $result
    } finally {
      interp delete $safeInterp
    }
  }

  proc mapper::getCollection {name} {
    variable collections
    if {![dict exists $collections $name]} {
      puts "collections: $collections"
    }
    return [dict get $collections $name]
  }


  namespace export posts
}
