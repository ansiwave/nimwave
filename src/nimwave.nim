from illwave as iw import nil
import tables, sets, json, unicode
from strutils import nil
from nimwave/tui import nil
import sequtils

type
  Component*[T] = proc (ctx: var Context[T], localData: ref T, node: JsonNode, children: seq[JsonNode])
  Context*[T] = object
    parent*: ref Context[T]
    tb*: iw.TerminalBuffer
    ids: ref HashSet[string]
    idPath: seq[string]
    components*: Table[string, Component[T]]
    globalData*: ref T
    localData*: ref Table[string, ref T]

proc slice*[T](ctx: Context[T], x, y: int, width, height: Natural): Context[T] =
  result = ctx
  new result.parent
  result.parent[] = ctx
  result.tb = iw.slice(ctx.tb, x, y, width, height)

proc slice*[T](ctx: Context[T], x, y: int, width, height: Natural, bounds: tuple[x: int, y: int, width: int, height: int]): Context[T] =
  result = ctx
  new result.parent
  result.parent[] = ctx
  result.tb = iw.slice(ctx.tb, x, y, width, height, bounds)

proc render*[T](ctx: var Context[T], node: JsonNode)

proc box[T](ctx: var Context[T], localData: ref T, node: JsonNode, children: seq[JsonNode]) =
  var
    xStart = 0
    yStart = 0
  if "border" in node:
    case node["border"].str:
    of "single":
      xStart = 1
      yStart = 1
    of "double":
      xStart = 1
      yStart = 1
    else:
      raise newException(Exception, "Invalid border: " & node["border"].str)
  if children.len > 0:
    assert "direction" in node, "box requires 'direction' to be provided"
    case node["direction"].str:
    of "horizontal":
      var
        x = xStart
        remainingWidth = iw.width(ctx.tb).int
        remainingChildren = children.len
      for child in children:
        let initialWidth = int(remainingWidth / remainingChildren)
        var childContext = slice(ctx, x, yStart, max(0, initialWidth - (xStart * 2)), max(0, iw.height(ctx.tb) - (yStart * 2)))
        render(childContext, child)
        let actualWidth = iw.width(childContext.tb)
        x += actualWidth
        remainingWidth -= actualWidth
        remainingChildren -= 1
      ctx = slice(ctx, 0, 0, x+xStart, iw.height(ctx.tb))
    of "vertical":
      var
        y = yStart
        remainingHeight = iw.height(ctx.tb).int
        remainingChildren = children.len
      for child in children:
        let initialHeight = int(remainingHeight / remainingChildren)
        var childContext = slice(ctx, xStart, y, max(0, iw.width(ctx.tb) - (xStart * 2)), max(0, initialHeight - (yStart * 2)))
        render(childContext, child)
        let actualHeight = iw.height(childContext.tb)
        y += actualHeight
        remainingHeight -= actualHeight
        remainingChildren -= 1
      ctx = slice(ctx, 0, 0, iw.width(ctx.tb), y+yStart)
    else:
      raise newException(Exception, "Invalid direction: " & node["direction"].str)
  if "border" in node:
    case node["border"].str:
    of "single":
      iw.drawRect(ctx.tb, 0, 0, iw.width(ctx.tb)-1, iw.height(ctx.tb)-1)
    of "double":
      iw.drawRect(ctx.tb, 0, 0, iw.width(ctx.tb)-1, iw.height(ctx.tb)-1, doubleStyle = true)
    else:
      raise newException(Exception, "Invalid border: " & node["border"].str)

proc hbox[T](ctx: var Context[T], localData: ref T, node: JsonNode, children: seq[JsonNode]) =
  var o = copy(node)
  o["direction"] = % "horizontal"
  box(ctx, localData, o, children)

proc vbox[T](ctx: var Context[T], localData: ref T, node: JsonNode, children: seq[JsonNode]) =
  var o = copy(node)
  o["direction"] = % "vertical"
  box(ctx, localData, o, children)

proc validateId(id: string): bool =
  for ch in id:
    if ch == '/':
      return false
  true

proc flatten(nodes: seq[JsonNode], flatNodes: var seq[JsonNode]) =
  for node in nodes:
    if node.kind == JArray:
      if node.elems.len > 0:
        flatten(node.elems, flatNodes)
    else:
      flatNodes.add(node)

proc flatten(nodes: seq[JsonNode]): seq[JsonNode] =
  flatten(nodes, result)

proc runComponent[T](ctx: var Context[T], node: JsonNode) =
  assert "type" in node, "'type' required: " & $node
  let cmd = node["type"].str
  var fullId = ""
  if "id" in node:
    assert node["id"].kind == JString, "id must be a string"
    let id = node["id"].str
    assert id.len > 0
    assert validateId(id), "id cannot contain a / character: " & id
    ctx.idPath.add(id)
    fullId = strutils.join(ctx.idPath, "/")
    assert id notin ctx.ids[], "id already exists somewhere else in the tree: " & fullId
    ctx.ids[].incl(fullId)
  let children = flatten(if "children" in node: node["children"].elems else: @[])
  var d: ref T
  if fullId != "":
    if fullId in ctx.localData:
      d = ctx.localData[fullId]
    else:
      new d
      ctx.localData[fullId] = d
  if cmd in ctx.components:
    let f = ctx.components[cmd]
    f(ctx, d, node, children)
  else:
    const
      defaultComponents = {
        "box": box[T],
        "hbox": hbox[T],
        "vbox": vbox[T],
      }.toTable
    if cmd in defaultComponents:
      let f = defaultComponents[cmd]
      f(ctx, d, node, children)
    else:
      raise newException(Exception, "Component not found: " & cmd)

proc render*[T](ctx: var Context[T], node: JsonNode) =
  case node.kind:
  of JString:
    ctx = slice(ctx, 0, 0, min(iw.width(ctx.tb), node.str.runeLen), 1)
    tui.write(ctx.tb, 0, 0, node.str)
  of JObject:
    runComponent(ctx, node)
  of JArray:
    for elem in node.elems:
      render(ctx, elem)
  else:
    raise newException(Exception, "Invalid value: " & $node)

proc initContext*[T](tb: iw.TerminalBuffer): Context[T] =
  result = Context[T](tb: tb)
  new result.ids
  new result.globalData
  new result.localData

proc clean*[T](ctx: Context[T]) =
  let localKeys = ctx.localData[].keys.toSeq
  for id in localKeys:
    if id notin ctx.ids[]:
      ctx.localData[].del(id)

