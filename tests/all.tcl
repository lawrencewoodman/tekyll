package require Tcl 8.6
package require tcltest
::tcltest::configure -testdir [file dirname [file normalize [info script]]]
::tcltest::configure {*}$argv
exit [tcltest::runAllTests]
