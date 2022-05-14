from illwave as iw import nil
import tables, sets, json, unicode
from strutils import nil
from nimwave/tui import nil

type
  Component* = proc (ctx: var Context, id: string, node: JsonNode, children: seq[JsonNode])
  Context* = object
    parent*: ref Context
    tb*: iw.TerminalBuffer
    ids: ref HashSet[string]
    idPath: seq[string]
    components*: Table[string, Component]

proc slice*(ctx: Context, x, y: int, width, height: Natural, grow: tuple[top: bool, right: bool, bottom: bool, left: bool] = (false, false, false, false)): Context =
  result = ctx
  new result.parent
  result.parent[] = ctx
  result.tb = iw.slice(ctx.tb, x, y, width, height, grow)

proc render*(ctx: var Context, node: JsonNode)

proc box(ctx: var Context, id: string, node: JsonNode, children: seq[JsonNode]) =
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

proc hbox(ctx: var Context, id: string, node: JsonNode, children: seq[JsonNode]) =
  var o = copy(node)
  o["direction"] = % "horizontal"
  box(ctx, id, o, children)

proc vbox(ctx: var Context, id: string, node: JsonNode, children: seq[JsonNode]) =
  var o = copy(node)
  o["direction"] = % "vertical"
  box(ctx, id, o, children)

var
  defaultComponents = {
    "box": box,
    "hbox": hbox,
    "vbox": vbox,
  }.toTable

proc validateId(id: string): bool =
  for ch in id:
    if ch == '/':
      return false
  true

proc runComponent(ctx: var Context, node: JsonNode, children: seq[JsonNode]) =
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
  if cmd in ctx.components:
    let f = ctx.components[cmd]
    f(ctx, fullId, node, children)
  elif cmd in defaultComponents:
    let f = defaultComponents[cmd]
    f(ctx, fullId, node, children)
  else:
    raise newException(Exception, "Component not found: " & cmd)

proc render*(ctx: var Context, node: JsonNode) =
  case node.kind:
  of JString:
    ctx = slice(ctx, 0, 0, node.str.runeLen, 1)
    tui.write(ctx.tb, 0, 0, node.str)
  of JObject:
    runComponent(ctx, node, @[])
  of JArray:
    if node.elems.len > 0:
      let
        firstElem = node.elems[0]
        children = node.elems[1 ..< node.elems.len]
      if firstElem.kind == JObject:
        runComponent(ctx, firstElem, children)
      else:
        for elem in node.elems:
          render(ctx, elem)
  else:
    raise newException(Exception, "Invalid value: " & $node)

proc initContext*(tb: iw.TerminalBuffer): Context =
  result = Context(tb: tb)
  new result.ids

