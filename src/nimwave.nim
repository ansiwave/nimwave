from illwave as iw import nil
import tables, sets, json, unicode
from nimwave/tui import nil
from sequtils import nil
from ansiutils/codes import nil

type
  MountProc*[T] = proc (ctx: var Context[T], node: JsonNode): RenderProc[T]
  RenderProc*[T] = proc (ctx: var Context[T], node: JsonNode)
  Context*[T] = object
    tb*: iw.TerminalBuffer
    ids: ref HashSet[seq[string]]
    idPath: seq[string]
    components*: Table[string, RenderProc[T]]
    statefulComponents*: Table[string, MountProc[T]]
    mountedComponents: ref Table[seq[string], RenderProc[T]]
    data*: T

proc slice*[T](ctx: Context[T], x, y: int, width, height: Natural): Context[T] =
  result = ctx
  result.tb = iw.slice(ctx.tb, x, y, width, height)

proc slice*[T](ctx: Context[T], x, y: int, width, height: Natural, bounds: tuple[x: int, y: int, width: int, height: int]): Context[T] =
  result = ctx
  result.tb = iw.slice(ctx.tb, x, y, width, height, bounds)

proc renderComponent[T](ctx: var Context[T], node: JsonNode) =
  if "type" notin node:
    raise newException(Exception, "'type' required:\n" & $node)
  let cmd = node["type"].str
  var idPath: seq[string]
  if "id" in node:
    if node["id"].kind != JString:
      raise newException(Exception, "id must be a string")
    let id = node["id"].str
    ctx.idPath.add(id)
    if ctx.idPath in ctx.ids[]:
      raise newException(Exception, "id already exists somewhere else in the tree: " & $ctx.idPath)
    ctx.ids[].incl(ctx.idPath)
    idPath = ctx.idPath
  if cmd in ctx.components:
    let f = ctx.components[cmd]
    f(ctx, node)
  elif idPath.len > 0 and idPath in ctx.mountedComponents:
    let f = ctx.mountedComponents[idPath]
    f(ctx, node)
  elif cmd in ctx.statefulComponents:
    if idPath.len == 0:
      raise newException(Exception, "'id' required for stateful component:\n" & $node)
    let m = ctx.statefulComponents[cmd]
    let f = m(ctx, node)
    if f == nil:
      raise newException(Exception, "Stateful component did not return a render proc: " & cmd)
    ctx.mountedComponents[idPath] = f
    f(ctx, node)
  else:
    raise newException(Exception, "Component not found: " & cmd)

proc render*[T](ctx: var Context[T], node: JsonNode) =
  if ctx.tb.buf == nil:
    raise newException(Exception, "The `tb` field must be set in the context object")
  if ctx.ids == nil:
    new ctx.ids
    render(ctx, node)
    # unmount any components that weren't in the tree
    for idPath in sequtils.toSeq(ctx.mountedComponents[].keys):
      if idPath notin ctx.ids[]:
        ctx.mountedComponents[].del(idPath)
    # reset id fields
    ctx.ids = nil
    ctx.idPath = @[]
    return
  case node.kind:
  of JString:
    ctx = slice(ctx, 0, 0, codes.stripCodes(node.str).runeLen, 1)
    try:
      tui.write(ctx.tb, 0, 0, node.str)
    except Exception as ex:
      when defined(release):
        discard
      else:
        raise ex
  of JObject:
    renderComponent(ctx, node)
  of JArray:
    for elem in node.elems:
      render(ctx, elem)
  else:
    raise newException(Exception, "Invalid value:\n" & $node)

proc render*[T](ctx: var Context[T], text: string) =
  render(ctx, % text)

proc flatten(nodes: seq[JsonNode], flatNodes: var seq[JsonNode]) =
  for node in nodes:
    if node.kind == JArray:
      if node.elems.len > 0:
        flatten(node.elems, flatNodes)
    else:
      flatNodes.add(node)

proc flatten(nodes: seq[JsonNode]): seq[JsonNode] =
  flatten(nodes, result)

type
  Direction = enum
    Vertical, Horizontal,

proc renderBox[T](ctx: var Context[T], node: JsonNode, direction: Direction) =
  var
    xStart = 0
    yStart = 0
  if "border" in node:
    case node["border"].str:
    of "single", "double", "none":
      xStart = 1
      yStart = 1
  let children = if "children" in node: flatten(node["children"].elems) else: @[]
  if children.len > 0:
    case direction:
    of Horizontal:
      var
        x = xStart
        remainingWidth = iw.width(ctx.tb).int
        remainingChildren = children.len
        maxHeight = iw.height(ctx.tb)
      for child in children:
        let initialWidth = int(remainingWidth / remainingChildren)
        var childContext = slice(ctx, x, yStart, max(0, initialWidth - (xStart * 2)), max(0, iw.height(ctx.tb) - (yStart * 2)))
        render(childContext, child)
        let actualWidth = iw.width(childContext.tb)
        x += actualWidth
        remainingWidth -= actualWidth
        remainingChildren -= 1
        maxHeight = max(maxHeight, iw.height(childContext.tb)+(yStart*2))
      ctx = slice(ctx, 0, 0, x+xStart, maxHeight)
    of Vertical:
      var
        y = yStart
        remainingHeight = iw.height(ctx.tb).int
        remainingChildren = children.len
        maxWidth = iw.width(ctx.tb)
      for child in children:
        let initialHeight = int(remainingHeight / remainingChildren)
        var childContext = slice(ctx, xStart, y, max(0, iw.width(ctx.tb) - (xStart * 2)), max(0, initialHeight - (yStart * 2)))
        render(childContext, child)
        let actualHeight = iw.height(childContext.tb)
        y += actualHeight
        remainingHeight -= actualHeight
        remainingChildren -= 1
        maxWidth = max(maxWidth, iw.width(childContext.tb)+(xStart*2))
      ctx = slice(ctx, 0, 0, maxWidth, y+yStart)
  if "border" in node:
    case node["border"].str:
    of "single":
      iw.drawRect(ctx.tb, 0, 0, iw.width(ctx.tb)-1, iw.height(ctx.tb)-1)
    of "double":
      iw.drawRect(ctx.tb, 0, 0, iw.width(ctx.tb)-1, iw.height(ctx.tb)-1, doubleStyle = true)

proc renderHBox*[T](ctx: var Context[T], node: JsonNode) =
  renderBox(ctx, node, Horizontal)

proc renderVBox*[T](ctx: var Context[T], node: JsonNode) =
  renderBox(ctx, node, Vertical)

type
  ScrollState* = object
    scrollX*: int
    scrollY*: int

proc renderScroll*[T](ctx: var Context[T], node: JsonNode, state: ref ScrollState) =
  let
    width = iw.width(ctx.tb)
    height = iw.height(ctx.tb)
    boundsWidth =
      if "grow-x" in node and node["grow-x"].bval:
        -1
      else:
        width
    boundsHeight =
      if "grow-y" in node and node["grow-y"].bval:
        -1
      else:
        height
    bounds = (0, 0, boundsWidth, boundsHeight)
  var ctx = slice(ctx, state[].scrollX, state[].scrollY, width, height, bounds)
  render(ctx, %* node["child"])
  if "change-scroll-x" in node:
    state[].scrollX += node["change-scroll-x"].num.int
    let minX = width - iw.width(ctx.tb)
    if minX < 0:
      state[].scrollX = state[].scrollX.clamp(minX, 0)
    else:
      state[].scrollX = 0
  if "change-scroll-y" in node:
    state[].scrollY += node["change-scroll-y"].num.int
    let minY = height - iw.height(ctx.tb)
    if minY < 0:
      state[].scrollY = state[].scrollY.clamp(minY, 0)
    else:
      state[].scrollY = 0

proc mountScroll*[T](ctx: var Context[T], node: JsonNode, state: ref ScrollState): RenderProc[T] =
  return
    proc (ctx: var Context[T], node: JsonNode) =
      renderScroll(ctx, node, state)

proc mountScroll*[T](ctx: var Context[T], node: JsonNode): RenderProc[T] =
  var state = new ScrollState
  return mountScroll(ctx, node, state)

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

proc initContext*[T](): Context[T] =
  result = Context[T]()
  new result.mountedComponents
  result.components["nimwave.hbox"] = renderHBox[T]
  result.components["nimwave.vbox"] = renderVBox[T]
  result.statefulComponents["nimwave.scroll"] = mountScroll[T]

