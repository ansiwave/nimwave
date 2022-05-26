from illwave as iw import nil
import tables, sets, json, unicode
from nimwave/tui import nil

type
  MountProc*[T] = proc (ctx: var Context[T], node: JsonNode): RenderProc[T]
  RenderProc*[T] = proc (ctx: var Context[T], node: JsonNode)
  Context*[T] = object
    tb*: iw.TerminalBuffer
    ids*: ref HashSet[seq[string]]
    idPath*: seq[string]
    components*: Table[string, RenderProc[T]]
    statefulComponents*: Table[string, MountProc[T]]
    mountedComponents*: ref Table[seq[string], RenderProc[T]]
    data*: T

proc slice*[T](ctx: Context[T], x, y: int, width, height: Natural): Context[T] =
  result = ctx
  result.tb = iw.slice(ctx.tb, x, y, width, height)

proc slice*[T](ctx: Context[T], x, y: int, width, height: Natural, bounds: tuple[x: int, y: int, width: int, height: int]): Context[T] =
  result = ctx
  result.tb = iw.slice(ctx.tb, x, y, width, height, bounds)

proc runComponent[T](ctx: var Context[T], node: JsonNode) =
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
    ctx.mountedComponents[idPath] = f
    f(ctx, node)
  else:
    raise newException(Exception, "Component not found: " & cmd)

proc render*[T](ctx: var Context[T], node: JsonNode) =
  if ctx.tb.buf == nil:
    raise newException(Exception, "The `tb` field must be set in the context object")
  if ctx.ids == nil:
    var newCtx = ctx
    new newCtx.ids
    render(newCtx, node)
    return
  case node.kind:
  of JString:
    ctx = slice(ctx, 0, 0, node.str.runeLen, 1)
    when defined(release):
      tui.writeMaybe(ctx.tb, 0, 0, node.str)
    else:
      tui.write(ctx.tb, 0, 0, node.str)
  of JObject:
    runComponent(ctx, node)
  of JArray:
    for elem in node.elems:
      render(ctx, elem)
  else:
    raise newException(Exception, "Invalid value:\n" & $node)

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

proc box[T](ctx: var Context[T], node: JsonNode, direction: Direction) =
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
        maxHeight = max(maxHeight, iw.height(childContext.tb))
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
        maxWidth = max(maxWidth, iw.width(childContext.tb))
      ctx = slice(ctx, 0, 0, maxWidth, y+yStart)
    else:
      raise newException(Exception, "Invalid direction: " & node["direction"].str)
  if "border" in node:
    case node["border"].str:
    of "single":
      iw.drawRect(ctx.tb, 0, 0, iw.width(ctx.tb)-1, iw.height(ctx.tb)-1)
    of "double":
      iw.drawRect(ctx.tb, 0, 0, iw.width(ctx.tb)-1, iw.height(ctx.tb)-1, doubleStyle = true)

proc hbox[T](ctx: var Context[T], node: JsonNode) =
  box(ctx, node, Horizontal)

proc vbox[T](ctx: var Context[T], node: JsonNode) =
  box(ctx, node, Vertical)

proc initContext*[T](): Context[T] =
  result = Context[T]()
  new result.mountedComponents
  result.components["hbox"] = hbox[T]
  result.components["vbox"] = vbox[T]

