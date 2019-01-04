# Copyright (C) 2018 Lawrence Woodman <lwoodman@vlifesystems.com>
# Licensed under an MIT licence.  Please see LICENCE.md for details.

# wantPermissions is a string
# Returns true if wanted permissions all found, otherwise false
proc checkPermissions {vars path wantPermissions} {
  set path [file normalize $path]
  foreach d [dict get $vars build dirs] {
    lassign $d shortName buildDir buildPermissions
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

# Lookup the proper directory using its shortName and then file join
# the rest of the args to make its full name.  The dirs are stored
# in build > dirs.
proc getDir {vars shortName args} {
  foreach d [dict get $vars build dirs] {
    lassign $d buildShortName buildDir
    if {$shortName eq $buildShortName} {
      return [file join $buildDir {*}$args]
    }
  }
  return -code error "unknown name: $shortName"
}
