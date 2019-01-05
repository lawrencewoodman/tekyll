# Copyright (C) 2019 Lawrence Woodman <lwoodman@vlifesystems.com>
# Licensed under an MIT licence.  Please see LICENCE.md for details.

namespace eval markdown {
  namespace export {[a-z]*}
  namespace ensemble create

  variable MARKDOWN_CMD "cmark-gfm"
}

proc markdown::render {text} {
  variable MARKDOWN_CMD
  # Check MARKDOWN_CMD isn't blank.  This is also a security check to stop
  # the file being executed instead of the markdown command.
  if {[string trim $MARKDOWN_CMD " \t"] eq ""} {
    return -code error "markdown: MARKDOWN_CMD isn't valid"
  }
  try {
    return [exec -- {*}$MARKDOWN_CMD << $text]
  } on error {result} {
    return -code error "error from external command: $MARKDOWN_CMD, $result"
  }
}

proc markdown::renderFile {filename} {
  variable MARKDOWN_CMD
  # Check MARKDOWN_CMD isn't blank.  This is a security check to stop the
  # file being executed instead of the markdown command.
  if {[string trim $MARKDOWN_CMD " \t"] eq ""} {
    return -code error "markdown: MARKDOWN_CMD isn't valid"
  }
  try {
    return [exec -- {*}$MARKDOWN_CMD $filename]
  } on error {result} {
    return -code error "error from external command: $MARKDOWN_CMD, $result"
  }
}
