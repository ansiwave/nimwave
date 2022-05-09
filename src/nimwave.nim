from illwave as iw import nil
import tables, sets, json
from strutils import nil
from nimwave/tui import nil

type
  State* = object
    tb*: iw.TerminalBuffer
    id*: string
    ids*: ref HashSet[string]
    idPath: seq[string]
    preferredWidth*: Natural
    preferredHeight*: Natural

proc slice*(state: State, x, y: int, width, height: Natural): State =
  result = state
  result.tb.slice.x += x
  result.tb.slice.y += y
  result.tb.slice.width = width
  result.tb.slice.height = height

proc render*(state: var State, node: JsonNode)

proc rect(tb: var iw.TerminalBuffer, opts: JsonNode): tuple[x: int, y: int] =
  var
    x = 0
    y = 0
  if "border" in opts:
    case opts["border"].str:
    of "single":
      iw.drawRect(tb, 0, 0, iw.width(tb)-1, iw.height(tb)-1)
      x = 1
      y = 1
    of "double":
      iw.drawRect(tb, 0, 0, iw.width(tb)-1, iw.height(tb)-1, doubleStyle = true)
      x = 1
      y = 1
  (x, y)

proc hbox(state: var State, opts: JsonNode, children: seq[JsonNode]) =
  let (xStart, yStart) = rect(state.tb, opts)
  if children.len > 0:
    let w = int(iw.width(state.tb) / children.len)
    var x = xStart
    for child in children:
      var newState = slice(state, x, yStart, w - (xStart * 2), iw.height(state.tb) - (yStart * 2))
      render(newState, child)
      if newState.preferredWidth > 0:
        x += min(newState.preferredWidth, w)
      else:
        x += w

proc vbox(state: var State, opts: JsonNode, children: seq[JsonNode]) =
  let (xStart, yStart) = rect(state.tb, opts)
  if children.len > 0:
    let h = int(iw.height(state.tb) / children.len)
    var y = yStart
    for child in children:
      var newState = slice(state, xStart, y, iw.width(state.tb) - (xStart * 2), h - (yStart * 2))
      render(newState, child)
      if newState.preferredHeight > 0:
        y += min(newState.preferredHeight, h)
      else:
        y += h

var
  components* = {
    "hbox": hbox,
    "vbox": vbox,
  }.toTable

proc validateId(id: string): bool =
  for ch in id:
    if ch notin {'a'..'z', 'A'..'Z', '0'..'9', '-'}:
      return false
  true

proc render*(state: var State, node: JsonNode) =
  state.preferredWidth = 0
  state.preferredHeight = 0
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
      if opts.hasKey("id"):
        assert opts["id"].kind == JString, "id must be a string"
        let id = opts["id"].str
        assert id.len > 0
        assert validateId(id), "id can only have letters, numbers, and dashes: " & id
        state.idPath.add(id)
        state.id = strutils.join(state.idPath, "/")
        assert state.id notin state.ids[], "id already exists somewhere else in the tree: " & state.id
        state.ids[].incl(state.id)
      else:
        state.id = ""
      let f = components[cmd]
      f(state, opts, children)
  else:
    discard

proc render*(tb: var iw.TerminalBuffer, node: JsonNode) =
  var state = State(tb: tb)
  new state.ids
  render(state, node)

