# Copyright (C) 2018 Lawrence Woodman <lwoodman@vlifesystems.com>
# Licensed under an MIT licence.  Please see LICENCE.md for details.

package require Markdown

namespace eval ::site {

  namespace eval parsers {
    namespace export {[a-z]*}
    namespace ensemble create
  }

  proc parsers::parse {vars parser content} {
    switch $parser {
      layout {
        # TODO: pass content to layout rather than in vars to make
        # TODO: more consistent
        return [::site::layout generate $vars]
      }
      markdown {
        return [::Markdown::convert $content]
      }
      ornament {
        set script [ornament compile $content]
        set cmds [::site::cmds::new ornament $vars]
        return [ornament run $script $cmds]
      }
    }
    return -code error "unknown parser: $parser"
  }

  namespace export parsers
}
