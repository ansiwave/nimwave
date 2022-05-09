from illwave as iw import nil
import tables, sets, json
from strutils import nil
from nimwave/tui import nil

type
  Actions = Table[string, proc (tb: var State, opts: JsonNode)]
  State* = object
    tb*: iw.TerminalBuffer
    ids: ref HashSet[string]
    idPath: seq[string]
    actions: Actions

proc slice*(state: State, x, y: int, width, height: Natural): State =
  result = state
  result.tb.slice.x += x
  result.tb.slice.y += y
  result.tb.slice.width = width
  result.tb.slice.height = height

proc contains*(tb: iw.TerminalBuffer, mouse: iw.MouseInfo): bool =
  mouse.x >= tb.slice.x and
    mouse.x <= tb.slice.x + tb.slice.width and
    mouse.y >= tb.slice.y and
    mouse.y <= tb.slice.y + tb.slice.height

proc render*(state: var State, node: JsonNode)

proc box(state: var State, id: string, opts: JsonNode, children: seq[JsonNode]) =
  var
    xStart = 0
    yStart = 0
  if "border" in opts:
    case opts["border"].str:
    of "single":
      iw.drawRect(state.tb, 0, 0, iw.width(state.tb)-1, iw.height(state.tb)-1)
      xStart = 1
      yStart = 1
    of "double":
      iw.drawRect(state.tb, 0, 0, iw.width(state.tb)-1, iw.height(state.tb)-1, doubleStyle = true)
      xStart = 1
      yStart = 1
  assert "direction" in opts, "box requires 'direction' to be provided"
  if children.len > 0:
    case opts["direction"].str:
    of "horizontal":
      var
        x = xStart
        remainingWidth = iw.width(state.tb)
        remainingChildren = children.len
      for child in children:
        let preWidth = int(remainingWidth / remainingChildren)
        var newState = slice(state, x, yStart, preWidth - (xStart * 2), iw.height(state.tb) - (yStart * 2))
        render(newState, child)
        let postWidth = iw.width(newState.tb)
        x += postWidth
        if postWIdth > remainingWidth:
          break
        remainingWidth -= postWidth
        remainingChildren -= 1
    of "vertical":
      var
        y = yStart
        remainingHeight = iw.height(state.tb)
        remainingChildren = children.len
      for child in children:
        let preHeight = int(remainingHeight / remainingChildren)
        var newState = slice(state, xStart, y, iw.width(state.tb) - (xStart * 2), preHeight - (yStart * 2))
        render(newState, child)
        let postHeight = iw.height(newState.tb)
        y += postHeight
        if postHeight > remainingHeight:
          break
        remainingHeight -= postHeight
        remainingChildren -= 1
    else:
      raise newException(Exception, "Invalid direction: " & opts["direction"].str)

proc hbox(state: var State, id: string, opts: JsonNode, children: seq[JsonNode]) =
  var o = copy(opts)
  o["direction"] = % "horizontal"
  box(state, id, o, children)

proc vbox(state: var State, id: string, opts: JsonNode, children: seq[JsonNode]) =
  var o = copy(opts)
  o["direction"] = % "vertical"
  box(state, id, o, children)

var
  components* = {
    "box": box,
    "hbox": hbox,
    "vbox": vbox,
  }.toTable

proc validateId(id: string): bool =
  for ch in id:
    if ch notin {'a'..'z', 'A'..'Z', '0'..'9', '-'}:
      return false
  true

proc render*(state: var State, node: JsonNode) =
  case node.kind:
  of JString:
    tui.write(state.tb, 0, 0, node.str)
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
      assert components.hasKey(cmd), "Component not found: " & cmd
      var fullId = ""
      if "id" in opts:
        assert opts["id"].kind == JString, "id must be a string"
        let id = opts["id"].str
        assert id.len > 0
        assert validateId(id), "id can only have letters, numbers, and dashes: " & id
        state.idPath.add(id)
        fullId = strutils.join(state.idPath, "/")
        assert id notin state.ids[], "id already exists somewhere else in the tree: " & fullId
        state.ids[].incl(fullId)
      let f = components[cmd]
      f(state, fullId, opts, children)
      if "action" in opts:
        let actionName = opts["action"].str
        assert actionName in state.actions, "Action not found: " & actionName
        let a = state.actions[actionName]
        a(state, opts)
  else:
    raise newException(Exception, "Invalid value: " & $node)

proc render*(state: var State, actions: Actions, node: JsonNode) =
  for k, v in actions.pairs:
    state.actions[k] = v
  render(state, node)

proc render*(tb: var iw.TerminalBuffer, actions: Actions, node: JsonNode) =
  var state = State(tb: tb)
  new state.ids
  for k, v in actions.pairs:
    state.actions[k] = v
  render(state, node)

proc render*(tb: var iw.TerminalBuffer, node: JsonNode) =
  render(tb, Actions(), node)

