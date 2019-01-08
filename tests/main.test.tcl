package require Tcl 8.6
package require tcltest
package require fileutil
package require sha256
namespace import tcltest::*

set ThisScriptDir [file dirname [info script]]
set RootDir [file normalize [file join $ThisScriptDir ..]]
set LibDir [file join $RootDir lib]
set InitDir [file join $RootDir init]
set DummyDir [file normalize [file join $ThisScriptDir dummy]]
set FixturesDir [file normalize [file join $ThisScriptDir fixtures]]


proc makeTekyllCfg {tempDir} {
  global LibDir InitDir RootDir
  set tekyllCfg [dict create build \
    [dict create dirs \
      [list \
        [list build build w] \
        [list lib $LibDir r] \
        [list init $InitDir r] \
        [list root $RootDir r] \
      ]
    ]
  ]
  set fd [open [file join $tempDir tekyll.cfg] w]
  puts -nonewline $fd $tekyllCfg
  close $fd
}


test main-1 {Return error if subcommand} -setup {
  set startDir [pwd]
  set tempDirA [::fileutil::maketempdir]
  set tempDirB [::fileutil::maketempdir]
  file mkdir [file join $tempDirA build]
  file mkdir [file join $tempDirB build]
  makeTekyllCfg $tempDirA
  makeTekyllCfg $tempDirB
  set interpA [interp create]
  set interpB [interp create]
} -body {
  cd $tempDirA
  $interpA eval [list source [file join $RootDir main.tcl]]
  cd $tempDirB
  $interpB eval [list source [file join $tempDirA build tekyll.tcl]]
  expr {[::sha2::sha256 -file [file join $tempDirA build tekyll.tcl]] ==
        [::sha2::sha256 -file [file join $tempDirB build tekyll.tcl]]}
} -cleanup {
  cd $startDir
  file delete -force $tempDirA
  file delete -force $tempDirB
} -result {1}
