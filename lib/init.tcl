# Copyright (C) 2018-2019 Lawrence Woodman <lwoodman@vlifesystems.com>
# Licensed under an MIT licence.  Please see LICENCE.md for details.

namespace eval init {
  namespace export {[a-z]*}
}

proc init::process {file vars} {
  set cmds [::cmds::new $vars]
  if {![checkPermissions $vars $file r]} {
    return -code error "permission denied for: $file"
  }
  puts "Processing: $file"
  set safeInterp [interp create -safe]
  try {
    set fp [open $file r]
    set script [read $fp]
    close $fp

    $safeInterp eval {unset {*}[info vars]}
    dict for {templateCmdName cmdInvokation} $cmds {
      $safeInterp alias $templateCmdName {*}$cmdInvokation $safeInterp
    }
    return [$safeInterp eval $script]
  } on error {result options} {
    return -code error "error processing $file, $result"
  } finally {
    interp delete $safeInterp
  }
}
