from illwave as iw import nil
import tables, sets, unicode
from nimwave/tui import nil
from ansiutils/codes import nil

type
  Context*[T] = object
    tb*: iw.TerminalBuffer
    ids*: ref HashSet[seq[string]]
    idPath*: seq[string]
    mountedComponents*: ref Table[seq[string], Component]
    data*: T
  Component* = ref object of RootObj
    id*: string

proc slice*[T](ctx: Context[T], x, y: int, width, height: Natural): Context[T] =
  result = ctx
  result.tb = iw.slice(ctx.tb, x, y, width, height)

proc slice*[T](ctx: Context[T], x, y: int, width, height: Natural, bounds: tuple[x: int, y: int, width: int, height: int]): Context[T] =
  result = ctx
  result.tb = iw.slice(ctx.tb, x, y, width, height, bounds)

proc all*(comps: varargs[Component]): seq[Component] =
  for comp in comps:
    result.add(comp)

# edit text

#[
type
  TextState* = object
    text*: string
    cursorX*: int

proc renderText*[T](ctx: var Context[T], node: JsonNode, state: ref TextState, scrollState: ref ScrollState) =
  let edit = if "edit" in node: node["edit"].fields else: initOrderedTable[string, JsonNode](0)
  if edit.len > 0:
    let
      key = if "keycode" in edit: iw.Key(edit["keycode"].num.int) else: iw.Key.None
      chars = if "chars" in edit: edit["chars"].str.toRunes else: @[]
    case key:
    of iw.Key.Backspace:
      if state[].cursorX > 0:
        let
          line = state[].text.toRunes
          x = state[].cursorX - 1
          newLine = $line[0 ..< x] & $line[x + 1 ..< line.len]
        state[].text = newLine
        state[].cursorX -= 1
    of iw.Key.Delete:
      if state[].cursorX < state[].text.runeLen:
        let
          line = state[].text.toRunes
          newLine = $line[0 ..< state[].cursorX] & $line[state[].cursorX + 1 ..< line.len]
        state[].text = newLine
    of iw.Key.Left:
      state[].cursorX -= 1
      if state[].cursorX < 0:
        state[].cursorX = 0
    of iw.Key.Right:
      state[].cursorX += 1
      if state[].cursorX > state[].text.runeLen:
        state[].cursorX = state[].text.runeLen
    of iw.Key.Home:
      state[].cursorX = 0
    of iw.Key.End:
      state[].cursorX = state[].text.runeLen
    else:
      discard
    for ch in chars:
      let
        line = state[].text.toRunes
        before = line[0 ..< state[].cursorX]
        after = line[state[].cursorX ..< line.len]
      state[].text = $before & $ch & $after
      state[].cursorX += 1
    # update scroll position
    let cursorXDiff = scrollState[].scrollX + state[].cursorX
    if cursorXDiff >= iw.width(ctx.tb) - 1:
      scrollState[].scrollX = iw.width(ctx.tb) - 1 - state[].cursorX
    elif cursorXDiff < 0:
      scrollState[].scrollX = 0 - state[].cursorX
  # create scroll component
  proc mountTextScroll(ctx: var Context[T], node: JsonNode): RenderProc[T] =
    return mountScroll(ctx, node, scrollState)
  ctx.statefulComponents["text-scroll"] = mountTextScroll
  # render
  ctx = slice(ctx, 0, 0, iw.width(ctx.tb), 1)
  render(ctx, %* {
    "type": "text-scroll",
    "id": "text-scroll",
    "child": state[].text,
  })
  if edit.len > 0:
    var cell = ctx.tb[scrollState[].scrollX + state[].cursorX, 0]
    cell.bg = iw.bgYellow
    cell.fg = iw.fgBlack
    ctx.tb[scrollState[].scrollX + state[].cursorX, 0] = cell

proc mountText*[T](ctx: var Context[T], node: JsonNode, state: ref TextState): RenderProc[T] =
  var scrollState = new ScrollState
  return
    proc (ctx: var Context[T], node: JsonNode) =
      renderText(ctx, node, state, scrollState)
]#

proc initContext*[T](): Context[T] =
  result = Context[T]()
  new result.mountedComponents

