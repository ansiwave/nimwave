from illwave as iw import nil
import tables, json

type
  ComponentProc* = proc (tb: var iw.TerminalBuffer, opts: JsonNode, children: seq[JsonNode]) {.closure.}
  Components* = Table[string, ComponentProc]

proc render*(tb: var iw.TerminalBuffer, node: JsonNode)

var
  components* = {
    "hbox":
    proc (tb: var iw.TerminalBuffer, opts: JsonNode, children: seq[JsonNode]) {.closure.} =
      if children.len > 0:
        let w = int(iw.width(tb) / children.len)
        var x = 0
        for obj in children:
          var t = iw.slice(tb, x, 0, w, iw.height(tb))
          render(t, obj)
          x += w
    ,
    "vbox":
    proc (tb: var iw.TerminalBuffer, opts: JsonNode, children: seq[JsonNode]) {.closure.} =
      if children.len > 0:
        let h = int(iw.height(tb) / children.len)
        var y = 0
        for obj in children:
          var t = iw.slice(tb, 0, y, iw.width(tb), h)
          render(t, obj)
          y += h
    ,
    "rect":
    proc (tb: var iw.TerminalBuffer, opts: JsonNode, children: seq[JsonNode]) {.closure.} =
      iw.drawRect(tb, 0, 0, iw.width(tb)-1, iw.height(tb)-1)
    ,
  }.toTable

proc render*(tb: var iw.TerminalBuffer, node: JsonNode) =
  case node.kind:
  of JArray:
    if node.elems.len > 0:
      let
        cmd = node.elems[0].getStr
        args = node.elems[1 ..< node.elems.len]
        (opts, children) =
          if args.len > 0:
            if args[0].kind == JObject:
              (args[0], args[1 ..< args.len])
            else:
              (newJObject(), args)
          else:
            (newJObject(), @[])
      doAssert components.hasKey(cmd)
      components[cmd](tb, opts, children)
  else:
    discard

