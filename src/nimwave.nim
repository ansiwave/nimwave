from illwave as iw import nil
import tables, sets, unicode
from nimwave/tui import nil
from ansiutils/codes import nil

type
  Context*[T] = object
    tb*: iw.TerminalBuffer
    ids*: ref HashSet[seq[string]]
    idPath*: seq[string]
    mountedNodes*: ref Table[seq[string], Node]
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
    text*: string
    case kind*: TextKind
    of Read:
      discard
    of Edit:
      enabled*: bool
      cursorX*: int
      key*: iw.Key
      chars*: seq[Rune]
      scroll*: Scroll

proc slice*[T](ctx: Context[T], x, y: int, width, height: Natural): Context[T] =
  result = ctx
  result.tb = iw.slice(ctx.tb, x, y, width, height)

proc slice*[T](ctx: Context[T], x, y: int, width, height: Natural, bounds: tuple[x: int, y: int, width: int, height: int]): Context[T] =
  result = ctx
  result.tb = iw.slice(ctx.tb, x, y, width, height, bounds)

proc all*(comps: varargs[Node]): seq[Node] =
  for comp in comps:
    result.add(comp)

proc initContext*[T](): Context[T] =
  result = Context[T]()
  new result.mountedNodes

