# Copyright (C) 2018 Lawrence Woodman <lwoodman@vlifesystems.com>
# Licensed under an MIT licence.  Please see LICENCE.md for details.

package require ornament

namespace eval mapper {
  namespace export {[a-z]*}
  namespace ensemble create
}

proc mapper::process {file vars} {
  try {
    set cmds [::cmds::new map $vars]
    load $file $cmds $vars
  } on error {result options} {
    return -code error "error processing: $file, $result"
  }
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
