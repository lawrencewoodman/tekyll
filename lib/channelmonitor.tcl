# Copyright (C) 2019 Lawrence Woodman <lwoodman@vlifesystems.com>
# Licensed under an MIT licence.  Please see LICENCE.md for details.

# This is used to capture the output of a channel
namespace eval channelMonitor {
  namespace export {[a-z]*}
  namespace ensemble create
  variable channels
}

proc channelMonitor::new {} {
  variable channels
  return [chan create {write} [namespace which -command channelMonitor]]
}

proc channelMonitor::initialize {channelID mode} {
  variable channels
  if {"read" in $mode} {
    return -code error "unsupported mode: read"
  }
  dict set channels $channelID [
    dict create writeData {} finalized false
  ]
  return {initialize finalize watch write}
}

proc channelMonitor::finalize {channelID} {
  variable channels
  dict unset channels $channelID
}

proc channelMonitor::watch {channelID eventSpec} {
}

proc channelMonitor::write {channelID data} {
  variable channels
  set channelWriteData [dict get $channels $channelID writeData]
  append channelWriteData $data
  dict set channels $channelID writeData $channelWriteData
  return [string bytelength $data]
}

proc channelMonitor::getWriteData {channelID} {
  variable channels
  flush $channelID
  return [dict get $channels $channelID writeData]
}

