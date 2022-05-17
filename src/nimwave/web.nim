from illwave as iw import `[]`, `[]=`, `==`
from strutils import format
import tables
from terminal import nil

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

