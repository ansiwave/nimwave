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

proc nimwave_get_innerhtml(selector: cstring): cstring {.importc.}
proc nimwave_set_innerhtml(selector: cstring, html: cstring) {.importc.}
proc nimwave_set_position(selector: cstring, left: cint, top: cint) {.importc.}
proc nimwave_set_size(selector: cstring, width: cint, height: cint) {.importc.}
proc nimwave_get_client_width(): cint {.importc.}
proc nimwave_get_client_height(): cint {.importc.}
proc nimwave_set_display(selector: cstring, display: cstring) {.importc.}
proc nimwave_focus(selector: cstring) {.importc.}
proc nimwave_scroll_down(selector: cstring) {.importc.}
proc nimwave_get_scroll_top(selector: cstring): cint {.importc.}
proc nimwave_open_new_tab(url: cstring) {.importc.}
proc nimwave_get_hash(): cstring {.importc.}
proc nimwave_set_hash(hash: cstring) {.importc.}
proc free(p: pointer) {.importc.}

{.compile: "nimwave_emscripten.c".}

proc getInnerHtml*(selector: string): string =
  let html = nimwave_get_innerhtml(selector)
  result = $html
  free(html)

proc setInnerHtml*(selector: string, html: string) =
  nimwave_set_innerhtml(selector, html)

proc setPosition*(selector: string, left: int32, top: int32) =
  nimwave_set_position(selector, left, top)

proc setSize*(selector: string, width: int32, height: int32) =
  nimwave_set_size(selector, width, height)

proc getClientWidth*(): int32 =
  nimwave_get_client_width()

proc getClientHeight*(): int32 =
  nimwave_get_client_height()

proc setDisplay*(selector: string, display: string) =
  nimwave_set_display(selector, display)

proc focus*(selector: string) =
  nimwave_focus(selector)

proc scrollDown*(selector: string) =
  nimwave_scroll_down(selector)

proc getScrollTop*(selector: string): int =
  nimwave_get_scroll_top(selector)

proc openNewTab*(url: string) =
  nimwave_open_new_tab(url)

proc getHash*(): string =
  let hash = nimwave_get_hash()
  result = $hash
  free(hash)

proc setHash*(hash: string) =
  nimwave_set_hash(hash)
