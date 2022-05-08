from illwave as iw import nil
import tables, json

proc render*(tb: var iw.TerminalBuffer, node: JsonNode)

proc hbox(tb: var iw.TerminalBuffer, opts: JsonNode, children: seq[JsonNode]) =
  if children.len > 0:
    let w = int(iw.width(tb) / children.len)
    var x = 0
    for child in children:
      var t = iw.slice(tb, x, 0, w, iw.height(tb))
      render(t, child)
      x += w

proc vbox(tb: var iw.TerminalBuffer, opts: JsonNode, children: seq[JsonNode]) =
  if children.len > 0:
    let h = int(iw.height(tb) / children.len)
    var y = 0
    for child in children:
      var t = iw.slice(tb, 0, y, iw.width(tb), h)
      render(t, child)
      y += h

proc rect(tb: var iw.TerminalBuffer, opts: JsonNode, children: seq[JsonNode]) =
  iw.drawRect(tb, 0, 0, iw.width(tb)-1, iw.height(tb)-1)
  var t = iw.slice(tb, 1, 1, iw.width(tb)-2, iw.height(tb)-2)
  for child in children:
    render(t, child)

var
  components = {
    "hbox": hbox,
    "vbox": vbox,
    "rect": rect,
  }.toTable

proc render*(tb: var iw.TerminalBuffer, node: JsonNode) =
  case node.kind:
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
      doAssert components.hasKey(cmd)
      let f = components[cmd]
      f(tb, opts, children)
  else:
    discard

