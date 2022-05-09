from illwave as iw import `[]`, `[]=`, `==`
from strutils import nil
import unicode
from ./tui/kdtree import nil
from ./tui/termtools/runewidth import nil
from terminal import nil
from colors import nil
from ansiutils/codes import nil

const simpleColors = [
  ([0.0, 0.0, 0.0], (terminal.fgBlack, terminal.bgBlack)),
  ([255.0, 0.0, 0.0], (terminal.fgRed, terminal.bgRed)),
  ([0.0, 128.0, 0.0], (terminal.fgGreen, terminal.bgGreen)),
  ([255.0, 255.0, 0.0], (terminal.fgYellow, terminal.bgYellow)),
  ([0.0, 0.0, 255.0], (terminal.fgBlue, terminal.bgBlue)),
  ([255.0, 0.0, 255.0], (terminal.fgMagenta, terminal.bgMagenta)),
  ([0.0, 255.0, 255.0], (terminal.fgCyan, terminal.bgCyan)),
  ([255.0, 255.0, 255.0], (terminal.fgWhite, terminal.bgWhite)),
]
var tree = kdtree.newKdTree[(terminal.ForegroundColor, terminal.BackgroundColor)](simpleColors)

proc applyCode(tb: var iw.TerminalBuffer, code: string) =
  let
    trimmed = code[1 ..< code.len - 1]
    params = codes.parseParams(trimmed)
  var i = 0
  while i < params.len:
    let param = params[i]
    if param == 0:
      iw.setBackgroundColor(tb, terminal.bgDefault)
      iw.setForegroundColor(tb, terminal.fgDefault)
      iw.setStyle(tb, {})
    elif param >= 1 and param <= 9:
      var style = iw.getStyle(tb)
      style.incl(terminal.Style(param))
      iw.setStyle(tb, style)
    elif param == 22:
      var style = iw.getStyle(tb)
      style.excl(terminal.Style(1))
      style.excl(terminal.Style(2))
      iw.setStyle(tb, style)
    elif param >= 30 and param <= 37:
      iw.setForegroundColor(tb, terminal.ForegroundColor(param))
    elif param >= 40 and param <= 47:
      iw.setBackgroundColor(tb, terminal.BackgroundColor(param))
    elif param == 38 or param == 48:
      if i + 1 < params.len:
        let mode = params[i + 1]
        # convert 256 colors to standard 8 terminal colors
        if mode == 5:
          if i + 2 < params.len:
            # TODO: correctly convert the 256 color value to one of the 8 terminal colors
            if param == 38:
              iw.setForegroundColor(tb, terminal.fgDefault)
            else:
              iw.setBackgroundColor(tb, terminal.bgDefault)
            i += 3
            continue
        # convert truecolor to standard 8 terminal colors
        elif mode == 2:
          if i + 4 < params.len:
            let
              r = params[i + 2].uint8
              g = params[i + 3].uint8
              b = params[i + 4].uint8
            if iw.gIllwaveInitialized and not terminal.isTruecolorSupported():
              let (pt, value, dist) = kdtree.nearestNeighbour(tree, [float(r), float(g), float(b)])
              if param == 38:
                iw.setForegroundColor(tb, value[0])
              else:
                iw.setBackgroundColor(tb, value[1])
            else:
              if param == 38:
                iw.setForegroundColor(tb, iw.toColor(r, g, b))
              else:
                iw.setBackgroundColor(tb, iw.toColor(r, g, b))
            i += 5
            continue
        # the values appear to be invalid so just stop trying to make sense of them
        break
    i += 1

proc write*(tb: var iw.TerminalBuffer, x, y: int, s: string) =
  if y < 0 or y > iw.height(tb):
    return
  var currX = x
  var esccodes: seq[string]
  for ch in runes(s):
    if codes.parseCode(esccodes, ch):
      continue
    for code in esccodes:
      applyCode(tb, code)
    let c = iw.TerminalChar(ch: ch, fg: iw.getForegroundColor(tb), bg: iw.getBackgroundColor(tb),
                            style: iw.getStyle(tb))
    tb[currX, y] = c
    currX += 1
    if runewidth.runeWidth(ch) == 2:
      tb[currX, y] = iw.TerminalChar()
      currX += 1
    esccodes = @[]
  for code in esccodes:
    applyCode(tb, code)
  iw.setCursorXPos(tb, currX)
  iw.setCursorYPos(tb, y)

proc writeMaybe*(tb: var iw.TerminalBuffer, x, y: int, s: string) =
  try:
    write(tb, x, y, s)
  except Exception as ex:
    discard

proc write*(lines: seq[ref string]): seq[seq[iw.TerminalChar]] =
  var tb = iw.initTerminalBuffer(0, 0)
  var esccodes: seq[string]
  for line in lines:
    var chars: seq[iw.TerminalChar]
    for ch in runes(line[]):
      if codes.parseCode(esccodes, ch):
        continue
      for code in esccodes:
        applyCode(tb, code)
      let c = iw.TerminalChar(ch: ch, fg: iw.getForegroundColor(tb), bg: iw.getBackgroundColor(tb),
                              style: iw.getStyle(tb))
      chars.add c
      esccodes = @[]
    result.add chars

proc writeMaybe*(lines: seq[ref string]): seq[seq[iw.TerminalChar]] =
  try:
    result = write(lines)
  except Exception as ex:
    discard

