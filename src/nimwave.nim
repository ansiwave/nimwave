from illwave as iw import nil
import tables, sets, unicode
import macros

type
  Context*[T] = object
    tb*: iw.TerminalBuffer
    ids*: ref HashSet[string]
    mountedNodes*: ref Table[string, Node]
    data*: T
  Node* = ref object of RootObj
    id*: string
  Direction* {.pure.} = enum
    Vertical, Horizontal,
  Border* {.pure.} = enum
    None, Single, Double, Hidden,
  Box* = ref object of Node
    direction*: Direction
    border*: Border
    children*: seq[Node]
  Scroll* = ref object of Node
    scrollX*: int
    scrollY*: int
    changeScrollX*: int
    changeScrollY*: int
    growX*: bool
    growY*: bool
    child*: Node
  TextKind* {.pure.} = enum
    Read,
    Edit,
  Text* = ref object of Node
    str*: string
    case kind*: TextKind
    of Read:
      discard
    of Edit:
      enabled*: bool
      cursorX*: int
      key*: iw.Key
      chars*: seq[Rune]

proc slice*[T](ctx: Context[T], x, y: int, width, height: Natural): Context[T] =
  result = ctx
  result.tb = iw.slice(ctx.tb, x, y, width, height)

proc slice*[T](ctx: Context[T], x, y: int, width, height: Natural, bounds: tuple[x: int, y: int, width: int, height: int]): Context[T] =
  result = ctx
  result.tb = iw.slice(ctx.tb, x, y, width, height, bounds)

proc toSeq(nodes: tuple): seq[Node] =
  for node in nodes.fields:
    when node is tuple:
      result.add(toSeq(node))
    elif node is string:
      result.add(nw.Text(str: node))
    elif node is seq[string]:
      for s in node:
        result.add(nw.Text(str: s))
    else:
      result.add(node)

macro seq*(args: varargs[untyped]): untyped =
  var tup = newTree(nnkTupleConstr)
  for arg in args:
    tup.add(arg)
  quote:
    toSeq(`tup`)

proc initContext*[T](): Context[T] =
  result = Context[T]()
  new result.mountedNodes

