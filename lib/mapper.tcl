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

  proc mapper::process {dir vars} {
    variable collections
    try {
      set cmds [::site::cmds::new map $vars]
      dict set cmds collect [namespace which CmdCollect]
      load $dir $cmds $vars
      #ProcessFile $map $dir $vars
    } on error {result options} {
      return -code error "error processing: $dir, $result"
    }
  }

  proc mapper::CmdCollect {int collection vars} {
    variable collections
    dict lappend collections $collection $vars
  }

  proc mapper::load {dir cmds vars} {
    set startDir [pwd]
    set safeInterp [interp create -safe]
    try {
      cd $dir
      set fp [open "_map" r]
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
      return -code error "error loading _map in: $dir, $result"
    } finally {
      interp delete $safeInterp
      cd $startDir
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
