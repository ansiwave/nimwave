from illwave as iw import `[]`, `[]=`, `==`
from strutils import format
import tables

from terminal import nil

from htmlparser import nil
from xmltree import `$`, `[]`

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

proc parseRgb(rgb: string, output: var tuple[r: int, g: int, b: int]): bool =
  let parts = strutils.split(rgb, {'(', ')'})
  if parts.len >= 2:
    let
      cmd = strutils.strip(parts[0])
      args = strutils.strip(parts[1])
    if cmd == "rgba" or cmd == "rgb":
      let colors = strutils.split(args, ',')
      if colors.len >= 3:
        try:
          let
            r = strutils.parseInt(strutils.strip(colors[0]))
            g = strutils.parseInt(strutils.strip(colors[1]))
            b = strutils.parseInt(strutils.strip(colors[2]))
          output = (r, g, b)
          return true
        except Exception as ex:
          discard
  false

proc fgToAnsi(color: string): string =
  case color:
  of "black":
    "\e[30m"
  of "red":
    "\e[31m"
  of "green":
    "\e[32m"
  of "yellow":
    "\e[330m"
  of "blue":
    "\e[34m"
  of "magenta":
    "\e[35m"
  of "cyan":
    "\e[36m"
  of "white":
    "\e[37m"
  else:
    var rgb: tuple[r: int, g: int, b: int]
    if parseRgb(color, rgb):
      "\e[38;2;$1;$2;$3m".format(rgb[0], rgb[1], rgb[2])
    else:
      ""

proc bgToAnsi(color: string): string =
  case color:
  of "black":
    "\e[40m"
  of "red":
    "\e[41m"
  of "green":
    "\e[42m"
  of "yellow":
    "\e[43m"
  of "blue":
    "\e[44m"
  of "magenta":
    "\e[45m"
  of "cyan":
    "\e[46m"
  of "white":
    "\e[47m"
  else:
    var rgb: tuple[r: int, g: int, b: int]
    if parseRgb(color, rgb):
      "\e[48;2;$1;$2;$3m".format(rgb[0], rgb[1], rgb[2])
    else:
      ""

proc htmlToAnsi*(node: xmltree.XmlNode): string =
  var
    fg: string
    bg: string
  case xmltree.kind(node):
  of xmltree.xnVerbatimText, xmltree.xnElement:
    case xmltree.tag(node):
    of "span":
      let
        style = xmltree.attr(node, "style")
        statements = strutils.split(style, ';')
      for statement in statements:
        let parts = strutils.split(statement, ':')
        if parts.len == 2:
          let
            key = strutils.strip(parts[0])
            val = strutils.strip(parts[1])
          if key == "color":
            fg = fgToAnsi(val)
          elif key == "background-color":
            bg = bgToAnsi(val)
    else:
      discard
  else:
    discard
  let colors = fg & bg
  if colors.len > 0:
    result &= colors
  for i in 0 ..< xmltree.len(node):
    result &= htmlToAnsi(node[i])
  if colors.len > 0:
    result &= "\e[0m"
  case xmltree.kind(node):
  of xmltree.xnText:
    result &= xmltree.innerText(node)
  of xmltree.xnVerbatimText, xmltree.xnElement:
    case xmltree.tag(node):
    of "div":
      result &= "\n"
    else:
      discard
  else:
    discard

proc htmlToAnsi*(html: string): string =
  result = htmlToAnsi(htmlparser.parseHtml(html))
  if strutils.endsWith(result, "\n"):
    result = result[0 ..< result.len-1]

