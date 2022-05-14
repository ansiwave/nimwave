from illwave as iw import nil
import tables, sets, json, unicode
from strutils import nil
from nimwave/tui import nil

type
  Component* = proc (ctx: var Context, id: string, opts: JsonNode, children: seq[JsonNode])
  Context* = object
    tb*: iw.TerminalBuffer
    ids: ref HashSet[string]
    idPath: seq[string]
    components*: Table[string, Component]

proc slice*(ctx: Context, x, y: int, width, height: Natural, grow: tuple[top: bool, right: bool, bottom: bool, left: bool] = (false, false, false, false)): Context =
  result = ctx
  result.tb = iw.slice(result.tb, x, y, width, height, grow)

proc render*(ctx: var Context, node: JsonNode)

proc box(ctx: var Context, id: string, opts: JsonNode, children: seq[JsonNode]) =
  var
    xStart = 0
    yStart = 0
  if "border" in opts:
    case opts["border"].str:
    of "single":
      iw.drawRect(ctx.tb, 0, 0, iw.width(ctx.tb)-1, iw.height(ctx.tb)-1)
      xStart = 1
      yStart = 1
    of "double":
      iw.drawRect(ctx.tb, 0, 0, iw.width(ctx.tb)-1, iw.height(ctx.tb)-1, doubleStyle = true)
      xStart = 1
      yStart = 1
    else:
      raise newException(Exception, "Invalid border: " & opts["border"].str)
  if children.len > 0:
    assert "direction" in opts, "box requires 'direction' to be provided"
    case opts["direction"].str:
    of "horizontal":
      var
        x = xStart
        remainingWidth = iw.width(ctx.tb).int
        remainingChildren = children.len
      for child in children:
        var childContext = slice(ctx, x, yStart, max(0, remainingWidth - (xStart * 2)), max(0, iw.height(ctx.tb) - (yStart * 2)))
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
        var childContext = slice(ctx, xStart, y, max(0, iw.width(ctx.tb) - (xStart * 2)), max(0, remainingHeight - (yStart * 2)))
        render(childContext, child)
        let actualHeight = iw.height(childContext.tb)
        y += actualHeight
        remainingHeight -= actualHeight
        remainingChildren -= 1
      ctx = slice(ctx, 0, 0, iw.width(ctx.tb), y+yStart)
    else:
      raise newException(Exception, "Invalid direction: " & opts["direction"].str)

proc hbox(ctx: var Context, id: string, opts: JsonNode, children: seq[JsonNode]) =
  var o = copy(opts)
  o["direction"] = % "horizontal"
  box(ctx, id, o, children)

proc vbox(ctx: var Context, id: string, opts: JsonNode, children: seq[JsonNode]) =
  var o = copy(opts)
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

proc render*(ctx: var Context, node: JsonNode) =
  case node.kind:
  of JString:
    ctx = slice(ctx, 0, 0, node.str.runeLen, iw.height(ctx.tb))
    tui.write(ctx.tb, 0, 0, node.str)
  of JArray:
    if node.elems.len > 0:
      let
        cmd = node.elems[0].str
        args = node.elems[1 ..< node.elems.len]
        (opts, children) =
          if args.len > 0:
            if args[0].kind == JObject:
              (args[0], args[1 ..< args.len])
            else:
              (newJObject(), args)
          else:
            (newJObject(), @[])
      var fullId = ""
      if "id" in opts:
        assert opts["id"].kind == JString, "id must be a string"
        let id = opts["id"].str
        assert id.len > 0
        assert validateId(id), "id cannot contain a / character: " & id
        ctx.idPath.add(id)
        fullId = strutils.join(ctx.idPath, "/")
        assert id notin ctx.ids[], "id already exists somewhere else in the tree: " & fullId
        ctx.ids[].incl(fullId)
      if cmd in ctx.components:
        let f = ctx.components[cmd]
        f(ctx, fullId, opts, children)
      elif cmd in defaultComponents:
        let f = defaultComponents[cmd]
        f(ctx, fullId, opts, children)
      else:
        raise newException(Exception, "Component not found: " & cmd)
  else:
    raise newException(Exception, "Invalid value: " & $node)

proc initContext*(tb: iw.TerminalBuffer): Context =
  result = Context(tb: tb)
  new result.ids

