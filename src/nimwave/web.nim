from illwave as iw import `[]`, `[]=`, `==`
from strutils import format
import tables, unicode
from terminal import nil
from ./web/emscripten import nil
from ./tui/termtools/runewidth import nil

type
  Options* = object
    padding*: float
    fontWidth*: float
    fontHeight*: float

const
  # dark colors
  blackColor* = (0, 0, 0, 1.0)
  redColor* = (255, 0, 0, 1.0)
  greenColor* = (0, 128, 0, 1.0)
  yellowColor* = (255, 255, 0, 1.0)
  blueColor* = (0, 0, 255, 1.0)
  magentaColor* = (255, 0, 255, 1.0)
  cyanColor* = (0, 255, 255, 1.0)
  whiteColor* = (255, 255, 255, 1.0)

  # bright colors
  brightRedColor* = (238, 119, 109, 1.0)
  brightGreenColor* = (141, 245, 123, 1.0)
  brightYellowColor* = (255, 250, 127, 1.0)
  brightBlueColor* = (103, 118, 246, 1.0)
  brightMagentaColor* = (238, 131, 248, 1.0)
  brightCyanColor* = (141, 250, 253, 1.0)

  nameToIllwaveKey* =
    {"Backspace": iw.Key.Backspace,
     "Delete": iw.Key.Delete,
     "Tab": iw.Key.Tab,
     "Enter": iw.Key.Enter,
     "Escape": iw.Key.Escape,
     "ArrowUp": iw.Key.Up,
     "ArrowDown": iw.Key.Down,
     "ArrowLeft": iw.Key.Left,
     "ArrowRight": iw.Key.Right,
     "Home": iw.Key.Home,
     "End": iw.Key.End,
     "PageUp": iw.Key.PageUp,
     "PageDown": iw.Key.PageDown,
     "Insert": iw.Key.Insert,
    }.toTable
  nameToIllwaveCtrlKey* =
    {"a": iw.Key.CtrlA,
     "b": iw.Key.CtrlB,
     "c": iw.Key.CtrlC,
     "d": iw.Key.CtrlD,
     "e": iw.Key.CtrlE,
     "f": iw.Key.CtrlF,
     "g": iw.Key.CtrlG,
     "h": iw.Key.CtrlH,
     "i": iw.Key.Tab,
     "j": iw.Key.CtrlJ,
     "k": iw.Key.CtrlK,
     "l": iw.Key.CtrlL,
     "m": iw.Key.Enter,
     "n": iw.Key.CtrlN,
     "o": iw.Key.CtrlO,
     "p": iw.Key.CtrlP,
     "q": iw.Key.CtrlQ,
     "r": iw.Key.CtrlR,
     "s": iw.Key.CtrlS,
     "t": iw.Key.CtrlT,
     "u": iw.Key.CtrlU,
     "v": iw.Key.CtrlV,
     "w": iw.Key.CtrlW,
     "x": iw.Key.CtrlX,
     "y": iw.Key.CtrlY,
     "z": iw.Key.CtrlZ,
     "\\": iw.Key.CtrlBackslash,
     "]": iw.Key.CtrlRightBracket,
     }.toTable

type
  Vec4 = tuple[r: int, g: int, b: int, a: float]

proc fgColorToString*(ch: iw.TerminalChar): string =
  var vec: Vec4
  vec =
    if ch.fgTrueColor.ord != 0:
      let (r, g, b) = iw.fromColor(ch.fgTrueColor)
      (r.int, g.int, b.int, 1.0)
    else:
      if terminal.styleBright in ch.style:
        case ch.fg:
        of iw.fgNone: return ""
        of iw.fgBlack: blackColor
        of iw.fgRed: brightRedColor
        of iw.fgGreen: brightGreenColor
        of iw.fgYellow: brightYellowColor
        of iw.fgBlue: brightBlueColor
        of iw.fgMagenta: brightMagentaColor
        of iw.fgCyan: brightCyanColor
        of iw.fgWhite: whiteColor
      else:
        case ch.fg:
        of iw.fgNone: return ""
        of iw.fgBlack: blackColor
        of iw.fgRed: redColor
        of iw.fgGreen: greenColor
        of iw.fgYellow: yellowColor
        of iw.fgBlue: blueColor
        of iw.fgMagenta: magentaColor
        of iw.fgCyan: cyanColor
        of iw.fgWhite: whiteColor
  if ch.cursor:
    vec.a = 0.7
  let (r, g, b, a) = vec
  "color: rgba($1, $2, $3, $4);".format(r, g, b, a)

proc bgColorToString*(ch: iw.TerminalChar): string =
  var vec: Vec4
  vec =
    if ch.bgTrueColor.ord != 0:
      let (r, g, b) = iw.fromColor(ch.bgTrueColor)
      (r.int, g.int, b.int, 1.0)
    else:
      if terminal.styleBright in ch.style:
        case ch.bg:
        of iw.bgNone: return ""
        of iw.bgBlack: blackColor
        of iw.bgRed: brightRedColor
        of iw.bgGreen: brightGreenColor
        of iw.bgYellow: brightYellowColor
        of iw.bgBlue: brightBlueColor
        of iw.bgMagenta: brightMagentaColor
        of iw.bgCyan: brightCyanColor
        of iw.bgWhite: whiteColor
      else:
        case ch.bg:
        of iw.bgNone: return ""
        of iw.bgBlack: blackColor
        of iw.bgRed: redColor
        of iw.bgGreen: greenColor
        of iw.bgYellow: yellowColor
        of iw.bgBlue: blueColor
        of iw.bgMagenta: magentaColor
        of iw.bgCyan: cyanColor
        of iw.bgWhite: whiteColor
  if ch.cursor:
    vec.a = 0.7
  let (r, g, b, a) = vec
  "background-color: rgba($1, $2, $3, $4);".format(r, g, b, a)

proc toHtml*(ch: iw.TerminalChar, position: tuple[x: int, y: int], opts: Options): string =
  if cast[uint32](ch.ch) == 0:
    return ""
  let
    fg = fgColorToString(ch)
    bg = bgColorToString(ch)
    additionalStyles =
      if runewidth.runeWidth(ch.ch) == 2:
        # add some padding because double width characters are a little bit narrower
        # than two normal characters due to font differences
        "display: inline-block; max-width: $1px; padding-left: $2px; padding-right: $2px;".format(opts.fontHeight, opts.padding)
      else:
        ""
    mouseEvents =
      if position != (-1, -1):
        "onmousedown='mouseDown($1, $2)' onmouseup='mouseUp($1, $2)' onmousemove='mouseMove($1, $2)'".format(position.x, position.y)
      else:
        ""
  return "<span class='col$1' style='$2 $3 $4' $5>$6</span>".format(position.x, fg, bg, additionalStyles, mouseEvents, $ch.ch)

proc toLine(innerHtml: string, y: int): string =
  "<div class='row$1'>$2</div>".format(y, innerHtml)

proc toHtml*(tb: iw.TerminalBuffer, opts: Options): string =
  let
    termWidth = iw.width(tb)
    termHeight = iw.height(tb)

  for y in 0 ..< termHeight:
    var line = ""
    for x in 0 ..< termWidth:
      line &= toHtml(tb[x, y], (x, y), opts)
    result &= toLine(line, y)

type
  ActionKind = enum
    Insert, Update, Remove,
  Action = object
    case kind: ActionKind
    of Insert, Update:
      ch: iw.TerminalChar
    of Remove:
      discard
    x: int
    y: int

proc getLineLen(tb: iw.TerminalBuffer, line: int): int =
  if line > tb.buf[].chars.len - 1:
    0
  else:
    tb.buf[].chars[line].len

proc diff(tb: iw.TerminalBuffer, prevTb: iw.TerminalBuffer): seq[Action] =
  for y in 0 ..< max(tb.buf[].chars.len, prevTb.buf[].chars.len):
    for x in 0 ..< max(tb.getLineLen(y), prevTb.getLineLen(y)):
      if y > prevTb.buf[].chars.len-1 or x > prevTb.buf[].chars[y].len-1:
        result.add(Action(kind: Insert, ch: tb[x, y], x: x, y: y))
      elif y > tb.buf[].chars.len-1 or x > tb.buf[].chars[y].len-1:
        result.add(Action(kind: Remove, x: x, y: y))
      elif tb[x, y] != prevTb[x, y]:
        result.add(Action(kind: Update, ch: tb[x, y], x: x, y: y))

proc display*(tb: iw.TerminalBuffer, prevTb: iw.TerminalBuffer, selector: string, opts: Options) =
  if prevTb.buf == nil:
    let html = toHtml(tb, opts)
    emscripten.setInnerHtml(selector, html)
  elif prevTb != tb:
    for action in diff(tb, prevTb):
      case action.kind:
      of Insert:
        if not emscripten.insertHtml(selector & " .row" & $action.y, "beforeend", toHtml(action.ch, (action.x, action.y), opts)):
          doAssert emscripten.insertHtml(selector, "beforeend", toLine("", action.y)), "Can't insert in " & selector
          doAssert emscripten.insertHtml(selector &  " .row" & $action.y, "beforeend", toHtml(action.ch, (action.x, action.y), opts)), "Can't insert before end of " & selector &  ".row" & $action.y
      of Update:
        doAssert emscripten.insertHtml(selector & " .row" & $action.y & " .col" & $action.x, "afterend", toHtml(action.ch, (action.x, action.y), opts)), "Can't insert after " & selector & " .row" & $action.y & " .col" & $action.x
        doAssert emscripten.removeHtml(selector & " .row" & $action.y & " .col" & $action.x), "Can't remove " & selector & " .row" & $action.y & " .col" & $action.x
      of Remove:
        doAssert emscripten.removeHtml(selector & " .row" & $action.y & " .col" & $action.x), "Can't remove " & selector & " .row" & $action.y & " .col" & $action.x

