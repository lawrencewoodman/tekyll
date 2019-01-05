package require Tcl 8.6
package require tcltest
namespace import tcltest::*

set ThisScriptDir [file dirname [info script]]
set LibDir [file join $ThisScriptDir .. lib]
set DummyDir [file normalize [file join $ThisScriptDir dummy]]
set FixturesDir [file normalize [file join $ThisScriptDir fixtures]]

source [file join $LibDir "markdown.tcl"]
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

test collection-1 {Return error if subcommand} -setup {
  set vars {}
  set cmds [cmds::new $vars]
} -body {
  TestCmds $cmds {
    collection fred
  }
} -returnCodes {error} -result {collection: invalid subcommand: fred}


test collection-get-1 {Return correct collection with get} -setup {
  set vars {}
  set cmds [cmds::new $vars]
} -body {
  TestCmds $cmds {
    collection add people {name fred age 27}
    collection add people {name bob age 29}
    collection add places Caerdydd
    collection add places Abertawe
    list [collection get people] [collection get places]
  }
} -result {{{name fred age 27} {name bob age 29}} {Caerdydd Abertawe}}


test collection-get-2 {Return error if name doesn't exist with get} -setup {
  set vars {}
  set cmds [cmds::new $vars]
} -body {
  TestCmds $cmds {
    collection add people {name fred age 27}
    collection add people {name bob age 29}
    list [collection get people] [collection get time]
  }
} -returnCodes {error} -result {collection get: unknown name: time}


test collection-get-3 {Return error if wrong number of args with get} -setup {
  set vars {}
  set cmds [cmds::new $vars]
} -body {
  TestCmds $cmds {
    collection add people {name fred age 27}
    collection get people hello
  }
} -returnCodes {error} -result {collection get: wrong # args}


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
} -body {
  TestCmds $cmds {
    list [dir plugins] [dir destination] [dir include] [dir include this that]
  }
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
} -body {
  TestCmds $cmds {
    dir layout
  }
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
  set cmds [cmds::new]
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
      dirs [list [list fixturesDir $FixturesDir r]] \
    ]
  ]
  set cmds [cmds::new $vars]
} -body {
  TestCmds $cmds {
    markdown -file [file join [dir fixturesDir] simple.md]
  }
} -result {<h1>This is a title</h1>
<p>This is a new paragraph.</p>}


test markdown-3 {Process a file with -directory} -setup {
  set vars [dict create \
    build [dict create \
      dirs [list [list fixturesDir $FixturesDir r]] \
    ]
  ]
  set cmds [cmds::new $vars]
} -body {
  TestCmds $cmds {
    markdown -directory [dir fixturesDir] -file simple.md
  }
} -result {<h1>This is a title</h1>
<p>This is a new paragraph.</p>}


test markdown-4 {Wrong number of arguments with -file} -setup {
  set vars [dict create \
    build [dict create \
      dirs [list [list fixturesDir $FixturesDir r]] \
    ]
  ]
  set cmds [cmds::new $vars]
} -body {
  TestCmds $cmds {
    markdown -file simple.md "# This is a title"
  }
} -returnCodes {error} -result {markdown: wrong # args}


test markdown-5 {Can't use -directory without -file} -setup {
  set vars [dict create \
    build [dict create \
      dirs [list [list fixturesDir $FixturesDir r]] \
    ]
  ]
  set cmds [cmds::new $vars]
} -body {
  TestCmds $cmds {
    markdown -directory [dir fixturesDir]
  }
} -returnCodes {error} -result {markdown: can't use -directory without -file}


test markdown-6 {Detect errors from external markdown command} -setup {
  set vars [dict create \
    build [dict create \
      dirs [list [list fixturesDir $FixturesDir r]] \
    ]
  ]
  set cmds [cmds::new $vars]
  set OLD_MARKDOWN_CMD $markdown::MARKDOWN_CMD
  set markdown::MARKDOWN_CMD "cmark-gfm -nnnnnn"
} -body {
  TestCmds $cmds {
    try {
      markdown -directory [dir fixturesDir] -file simple.md
    } on error {result} {
      return -code error [lrange [lindex [split $result "\n"] 0] 0 8]
    }
  }
} -cleanup {
  set markdown::MARKDOWN_CMD $OLD_MARKDOWN_CMD
} -returnCodes {error} -result "markdown: error from external command: cmark-gfm -nnnnnn, Usage: cmark-gfm"


test markdown-7 {Detect permission errors} -setup {
  set vars [dict create \
    build [dict create \
      dirs [list [list testsDummy $DummyDir r]] \
    ] \
    fixturesDir $FixturesDir
  ]
  set cmds [cmds::new $vars]
} -body {
  TestCmds $cmds {
    markdown -directory [getvar fixturesDir] -file simple.md
  }
} -returnCodes {error} -result "markdown: permission denied for: [file join $FixturesDir simple.md]"


test ornament-1 {Detect errors when opening template file} -setup {
  set vars [dict create \
    build [dict create \
      dirs [list [list fixturesDir $FixturesDir r]] \
    ] \
  ]
  set cmds [cmds::new $vars]
} -body {
  TestCmds $cmds {
    ornament -directory [dir fixturesDir] -file notexist.tpl
  }
} -returnCodes {error} -result "ornament: couldn't open \"[file join $FixturesDir notexist.tpl]\": no such file or directory"


test ornament-2 {Process template properly} -setup {
  set vars [dict create \
    build [dict create \
      dirs [list [list fixturesDir $FixturesDir r]] \
    ] \
  ]
  set cmds [cmds::new $vars]
} -body {
  TestCmds $cmds {
    set params {
      posts {{a 7} {b 9} {c 10}} \
      maxPosts 4 \
    }
    ornament -params $params -directory [dir fixturesDir] -file ornament.txt
  }
} -result {<div class="row">
      hello this is ornament2.txt for post: 0, in here numPosts: 0
      hello this is ornament2.txt for post: 1, in here numPosts: 0
      hello this is ornament2.txt for post: 2, in here numPosts: 0
</div>
numPosts: 3}

cleanupTests
