# Copyright (C) 2018 Lawrence Woodman <lwoodman@vlifesystems.com>
# Licensed under an MIT licence.  Please see LICENCE.md for details.

namespace eval mapper {
  namespace export {[a-z]*}
  namespace ensemble create
}

proc mapper::process {file vars} {
  set cmds [::cmds::new $vars]
  if {![checkPermissions $vars $file r]} {
    return -code error "error processing: $file, permission denied"
  }
  puts "Processing: $file"
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
    return -code error "error processing $file, $result"
  } finally {
    interp delete $safeInterp
  }
}
