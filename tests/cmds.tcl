package require Tcl 8.6
package require tcltest
namespace import tcltest::*

set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir .. lib]
set UtilsDir [file normalize [file join $ThisScriptDir utils]]
set FixturesDir [file normalize [file join $ThisScriptDir fixtures]]

source [file join $LibDir "cmds.tcl"]

proc TestCmds {cmds body} {
  set safeInterp [interp create -safe]
  try {
    $safeInterp eval {unset {*}[info vars]}
    dict for {templateCmdName cmdInvokation} $cmds {
      $safeInterp alias $templateCmdName {*}$cmdInvokation $safeInterp
    }
    return [$safeInterp eval $body]
  } finally {
    interp delete $safeInterp
  }
}

set MarkdownCmd [list tclsh [file join $UtilsDir markdown.tcl]]

test markdown-1 {Process text passed to it} -setup {
  set vars [dict create \
    build [dict create \
      markdown [dict create \
        cmd $MarkdownCmd
      ]
    ]
  ]
  set cmds [::site::cmds::new map $vars]
  set body {
    set text {
# This is a title

This is a new paragraph.
}
    markdown $text
  }
} -body {
  TestCmds $cmds $body
} -result {<h1>This is a title</h1>

<p>This is a new paragraph.</p>}


test markdown-2 {Process a file without -directory} -setup {
  set vars [dict create \
    build [dict create \
      markdown [dict create \
        cmd $MarkdownCmd
      ]
    ] \
    fixturesDir $FixturesDir
  ]
  set cmds [::site::cmds::new map $vars]
  set body {
    markdown -file [file join [getvar fixturesDir] simple.md]
  }
} -body {
  TestCmds $cmds $body
} -result {<h1>This is a title</h1>

<p>This is a new paragraph.</p>}


test markdown-3 {Process a file with -directory} -setup {
  set vars [dict create \
    build [dict create \
      markdown [dict create \
        cmd $MarkdownCmd
      ]
    ] \
    fixturesDir $FixturesDir
  ]
  set cmds [::site::cmds::new map $vars]
  set body {
    markdown -directory [getvar fixturesDir] -file simple.md
  }
} -body {
  TestCmds $cmds $body
} -result {<h1>This is a title</h1>

<p>This is a new paragraph.</p>}


test markdown-4 {Wrong number of arguments with -file} -setup {
  set vars [dict create \
    build [dict create \
      markdown [dict create \
        cmd $MarkdownCmd
      ]
    ] \
    fixturesDir $FixturesDir
  ]
  set cmds [::site::cmds::new map $vars]
  set body {
    markdown -file simple.md "# This is a title"
  }
} -body {
  TestCmds $cmds $body
} -returnCodes {error} -result {markdown: wrong # args}


test markdown-5 {Can't use -directory without -file} -setup {
  set vars [dict create \
    build [dict create \
      markdown [dict create \
        cmd $MarkdownCmd
      ]
    ] \
    fixturesDir $FixturesDir
  ]
  set cmds [::site::cmds::new map $vars]
  set body {
    markdown -directory [getvar fixturesDir]
  }
} -body {
  TestCmds $cmds $body
} -returnCodes {error} -result {markdown: can't use -directory without -file}


test markdown-6 {Detect missing command if set to "\t"} -setup {
  set vars [dict create \
    build [dict create \
      markdown [dict create \
        cmd "\t"
      ]
    ] \
    fixturesDir $FixturesDir
  ]
  set cmds [::site::cmds::new map $vars]
  set body {
    markdown -directory [getvar fixturesDir] -file simple.md
  }
} -body {
  TestCmds $cmds $body
} -returnCodes {error} -result {markdown: no cmd set in build > markdown > cmd}


test markdown-7 {Detect missing command if set to " "} -setup {
  set vars [dict create \
    build [dict create \
      markdown [dict create \
        cmd " "
      ]
    ] \
    fixturesDir $FixturesDir
  ]
  set cmds [::site::cmds::new map $vars]
  set body {
    markdown -directory [getvar fixturesDir] -file simple.md
  }
} -body {
  TestCmds $cmds $body
} -returnCodes {error} -result {markdown: no cmd set in build > markdown > cmd}


test markdown-8 {Detect errors from external markdown command} -setup {
  set vars [dict create \
    build [dict create \
      markdown [dict create \
        cmd "$MarkdownCmd hello"
      ]
    ] \
    fixturesDir $FixturesDir
  ]
  set cmds [::site::cmds::new map $vars]
  set body {
    markdown -directory [getvar fixturesDir] -file simple.md
  }
} -body {
  TestCmds $cmds $body
} -returnCodes {error} -result "markdown: error from external command: $MarkdownCmd hello, wrong # args"
