package require Tcl 8.6
package require tcltest
namespace import tcltest::*

set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir .. lib]
set UtilsDir [file normalize [file join $ThisScriptDir utils]]
set FixturesDir [file normalize [file join $ThisScriptDir fixtures]]

source [file join $LibDir "misc.tcl"]
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


test collection-1 {Return correct collection} -setup {
  set vars {}
  set cmds [cmds::new $vars]
} -body {
  TestCmds $cmds {
    collect people {name fred age 27}
    collect people {name bob age 29}
    collect places Caerdydd
    collect places Abertawe
    list [collection people] [collection places]
  }
} -result {{{name fred age 27} {name bob age 29}} {Caerdydd Abertawe}}


test collection-2 {Return error if name doesn't exist} -setup {
  set vars {}
  set cmds [cmds::new $vars]
  set body {
    list [dir plugins] [dir destination] [dir include] [dir include this that]
  }
} -body {
  TestCmds $cmds {
    collect people {name fred age 27}
    collect people {name bob age 29}
    list [collection people] [collection time]
  }
} -returnCodes {error} -result {collection: unknown name: time}


test dir-1 {Find correct directory for shortName} -setup {
  set vars {
    build {
      dirs {
        {destination tmp/site w}
        {include include r}
        {plugins plugins r}
      }
    }
  }
  set cmds [cmds::new $vars]
  set body {
    list [dir plugins] [dir destination] [dir include] [dir include this that]
  }
} -body {
  TestCmds $cmds $body
} -result [list plugins tmp/site include [file join include this that]]


test dir-2 {Return error if can't find shortName} -setup {
  set vars {
    build {
      dirs {
        {destination tmp/site w}
        {include include r}
        {plugins plugins r}
      }
    }
  }
  set cmds [cmds::new $vars]
  set body {
    dir layout
  }
} -body {
  TestCmds $cmds $body
} -returnCodes {error} -result "dir: unknown name: layout"


test getparam-1 {Return the correct value for key from params} -setup {
  set vars {
    params {
      name fred
      age 27
      status {
        first ready
        second go
      }
    }
  }
  set cmds [cmds::new $vars]
} -body {
  TestCmds $cmds {
    list [getparam name] is [getparam age] [getparam status second]
  }
} -result {fred is 27 go}


test getparam-2 {Return default if -default set and can't find key} -setup {
  set vars {
    params {
      name fred
      age 27
    }
  }
  set cmds [cmds::new $vars]
} -body {
  TestCmds $cmds {
    list [getparam name] is [getparam -default {} name] and \
         [getparam -default bob name] is known as \
         [getparam -default harry nickname]
  }
} -result [list fred is fred and fred is known as harry]


test getparam-3 {Return all params if no key passed} -setup {
  set vars [dict create \
    params [dict create \
      name fred \
      age 27 \
    ]
  ]
  set cmds [cmds::new $vars]
} -body {
  TestCmds $cmds {
    getparam
  }
} -result [dict create name fred age 27]


test getparam-4 {Return error if key doesn't exist} -setup {
  set vars [dict create \
    params [dict create \
      name fred \
      age 27 \
    ]
  ]
  set cmds [cmds::new $vars]
} -body {
  TestCmds $cmds {
    getparam status
  }
} -returnCodes {error} -result {getparam: unknown key: status}


test getparam-5 {Return error if key doesn't exist and -default set to {}} -setup {
  set vars [dict create \
    params [dict create \
      name fred \
      age 27 \
    ]
  ]
  set cmds [cmds::new $vars]
} -body {
  TestCmds $cmds {
    getparam -default {} status
  }
} -returnCodes {error} -result {getparam: unknown key: status}


test getparam-6 {Don't return an error if -noerror set} -setup {
  set vars [dict create \
    params [dict create \
      name fred \
      age 27 \
    ]
  ]
  set cmds [cmds::new $vars]
} -body {
  TestCmds $cmds {
    list "status: [getparam -noerror -default {} status]" \
         "status: [getparam -noerror status]" \
         "status: [getparam -noerror -default ready status]"
  }
} -result {{status: } {status: } {status: ready}}


test markdown-1 {Process text passed to it} -setup {
  set vars [dict create \
    build [dict create \
      markdown [dict create \
        cmd $MarkdownCmd
      ]
    ]
  ]
  set cmds [cmds::new $vars]
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
  set cmds [cmds::new $vars]
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
  set cmds [cmds::new $vars]
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
  set cmds [cmds::new $vars]
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
  set cmds [cmds::new $vars]
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
  set cmds [cmds::new $vars]
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
  set cmds [cmds::new $vars]
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
  set cmds [cmds::new $vars]
  set body {
    markdown -directory [getvar fixturesDir] -file simple.md
  }
} -body {
  TestCmds $cmds $body
} -returnCodes {error} -result "markdown: error from external command: $MarkdownCmd hello, wrong # args"
