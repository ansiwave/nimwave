const EM_HTML5_SHORT_STRING_LEN_BYTES = 32

type
  EmscriptenKeyboardEvent* {.bycopy.} = object
    timestamp*: cdouble
    location*: culong
    ctrlKey*: cint
    shiftKey*: cint
    altKey*: cint
    metaKey*: cint
    repeat*: cint
    charCode*: culong
    keyCode*: culong
    which*: culong
    key*: array[EM_HTML5_SHORT_STRING_LEN_BYTES, uint8]
    code*: array[EM_HTML5_SHORT_STRING_LEN_BYTES, uint8]
    charValue*: array[EM_HTML5_SHORT_STRING_LEN_BYTES, uint8]
    locale*: array[EM_HTML5_SHORT_STRING_LEN_BYTES, uint8]
  em_key_callback_func* = proc (eventType: cint, keyEvent: ptr EmscriptenKeyboardEvent, userData: pointer) {.cdecl.}

proc emscripten_set_main_loop*(f: proc() {.cdecl.}, a: cint, b: bool) {.importc, header: "<emscripten/emscripten.h>".}
proc emscripten_set_keydown_callback*(target: cstring, userData: pointer, useCapture: bool, callback: em_key_callback_func): cint {.importc, header: "<emscripten/html5.h>".}

proc ansiweb_get_innerhtml(selector: cstring): cstring {.importc.}
proc ansiweb_set_innerhtml(selector: cstring, html: cstring) {.importc.}
proc ansiweb_set_location(selector: cstring, left: cint, top: cint) {.importc.}
proc ansiweb_set_size(selector: cstring, width: cint, height: cint) {.importc.}
proc ansiweb_get_client_width(): cint {.importc.}
proc ansiweb_get_client_height(): cint {.importc.}
proc ansiweb_set_display(selector: cstring, display: cstring) {.importc.}
proc ansiweb_focus(selector: cstring) {.importc.}
proc ansiweb_scroll_down(selector: cstring) {.importc.}
proc ansiweb_get_scroll_top(selector: cstring): cint {.importc.}
proc ansiweb_get_cursor_line(selector: cstring): cint {.importc.}
proc free(p: pointer) {.importc.}

{.compile: "ansiweb_emscripten.c".}

proc getInnerHtml*(selector: string): string =
  let html = ansiweb_get_innerhtml(selector)
  result = $html
  free(html)

proc setInnerHtml*(selector: string, html: string) =
  ansiweb_set_innerhtml(selector, html)

proc setLocation*(selector: string, left: int32, top: int32) =
  ansiweb_set_location(selector, left, top)

proc setSize*(selector: string, width: int32, height: int32) =
  ansiweb_set_size(selector, width, height)

proc getClientWidth*(): int32 =
  ansiweb_get_client_width()

proc getClientHeight*(): int32 =
  ansiweb_get_client_height()

proc setDisplay*(selector: string, display: string) =
  ansiweb_set_display(selector, display)

proc focus*(selector: string) =
  ansiweb_focus(selector)

proc scrollDown*(selector: string) =
  ansiweb_scroll_down(selector)

proc getScrollTop*(selector: string): int =
  ansiweb_get_scroll_top(selector)

proc getCursorLine*(selector: string): int =
  ansiweb_get_cursor_line(selector)


