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

type
  Vec4 = tuple[r: int, g: int, b: int, a: float]

proc fgColorToString*(ch: iw.TerminalChar): string =
  var vec: Vec4
  vec =
    case ch.fg.kind:
    of iw.SimpleColor:
      if terminal.styleBright in ch.style:
        case ch.fg.simpleColor:
        of terminal.fgBlack: blackColor
        of terminal.fgRed: brightRedColor
        of terminal.fgGreen: brightGreenColor
        of terminal.fgYellow: brightYellowColor
        of terminal.fgBlue: brightBlueColor
        of terminal.fgMagenta: brightMagentaColor
        of terminal.fgCyan: brightCyanColor
        of terminal.fgWhite: whiteColor
        of terminal.fgDefault, terminal.fg8Bit: return ""
      else:
        case ch.fg.simpleColor:
        of terminal.fgBlack: blackColor
        of terminal.fgRed: redColor
        of terminal.fgGreen: greenColor
        of terminal.fgYellow: yellowColor
        of terminal.fgBlue: blueColor
        of terminal.fgMagenta: magentaColor
        of terminal.fgCyan: cyanColor
        of terminal.fgWhite: whiteColor
        of terminal.fgDefault, terminal.fg8Bit: return ""
    of iw.TrueColor:
      let (r, g, b) = iw.fromColor(ch.fg.trueColor)
      (r.int, g.int, b.int, 1.0)
  if ch.cursor:
    vec.a = 0.7
  let (r, g, b, a) = vec
  "color: rgba($1, $2, $3, $4);".format(r, g, b, a)

proc bgColorToString*(ch: iw.TerminalChar): string =
  var vec: Vec4
  vec =
    case ch.bg.kind:
    of iw.SimpleColor:
      if terminal.styleBright in ch.style:
        case ch.bg.simpleColor:
        of terminal.bgBlack: blackColor
        of terminal.bgRed: brightRedColor
        of terminal.bgGreen: brightGreenColor
        of terminal.bgYellow: brightYellowColor
        of terminal.bgBlue: brightBlueColor
        of terminal.bgMagenta: brightMagentaColor
        of terminal.bgCyan: brightCyanColor
        of terminal.bgWhite: whiteColor
        of terminal.bgDefault, terminal.bg8Bit: return ""
      else:
        case ch.bg.simpleColor:
        of terminal.bgBlack: blackColor
        of terminal.bgRed: redColor
        of terminal.bgGreen: greenColor
        of terminal.bgYellow: yellowColor
        of terminal.bgBlue: blueColor
        of terminal.bgMagenta: magentaColor
        of terminal.bgCyan: cyanColor
        of terminal.bgWhite: whiteColor
        of terminal.bgDefault, terminal.bg8Bit: return ""
    of iw.TrueColor:
      let (r, g, b) = iw.fromColor(ch.bg.trueColor)
      (r.int, g.int, b.int, 1.0)
  if ch.cursor:
    vec.a = 0.7
  let (r, g, b, a) = vec
  "background-color: rgba($1, $2, $3, $4);".format(r, g, b, a)

