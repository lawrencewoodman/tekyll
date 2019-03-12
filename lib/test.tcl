# Copyright (C) 2019 Lawrence Woodman <lwoodman@vlifesystems.com>
# Licensed under an MIT licence.  Please see LICENCE.md for details.

namespace eval test {
  namespace export {[a-z]*}
}

proc test::runTests {file vars} {
  set cmds [::cmds::new $vars]
  if {![checkPermissions $vars $file r]} {
    return -code error "permission denied for: $file"
  }
  set safeInterp [interp create -safe]
  try {
    try {
      set fp [open $file r]
      set script [read $fp]
      close $fp

      puts "Testing: $file"
      $safeInterp eval {unset {*}[info vars]}
      dict for {templateCmdName cmdInvokation} $cmds {
        $safeInterp alias $templateCmdName {*}$cmdInvokation $safeInterp
      }
      $safeInterp alias test [namespace which SafeTest] $safeInterp
      $safeInterp alias testFail ::xproc::fail
      $safeInterp alias testCases ::xproc::testCases -interp $safeInterp --
      $safeInterp eval $script
    } on error {result options} {
      return -code error "$result for: $file"
    }
    set ch [channelMonitor new]
    try {
      set summary [
        xproc::runTests -verbose 1 -channel $ch -interp $safeInterp
      ]
    } finally {
      set testOutput [channelMonitor getWriteData $ch]
      close $ch
    }
    if {[dict get $summary failed] > 0} {
      puts -nonewline $testOutput
      return false
    }
  } finally {
    xproc::remove all -interp $safeInterp
    interp delete $safeInterp
  }
  return true
}

proc test::SafeTest {interp args} {
  array set options {id 1}
  while {[llength $args]} {
    switch -glob -- [lindex $args 0] {
      -id     {set args [lassign $args - options(id)]}
      --      {set args [lrange $args 1 end] ; break}
      -*      {return -code error "unknown option: [lindex $args 0]"}
      default break
    }
  }
  if {[llength $args] != 2} {
    return -code error "invalid number of arguments"
  }
  xproc::test -interp $interp -id $options(id) -- {*}$args
}
