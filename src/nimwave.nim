from illwave as iw import nil
import tables, sets, unicode
from nimwave/tui import nil
from ansiutils/codes import nil

type
  Context*[T] = object
    tb*: iw.TerminalBuffer
    ids*: ref HashSet[seq[string]]
    idPath*: seq[string]
    mountedComponents*: ref Table[seq[string], Component]
    data*: T
  Component* = ref object of RootObj
    id*: string

proc slice*[T](ctx: Context[T], x, y: int, width, height: Natural): Context[T] =
  result = ctx
  result.tb = iw.slice(ctx.tb, x, y, width, height)

proc slice*[T](ctx: Context[T], x, y: int, width, height: Natural, bounds: tuple[x: int, y: int, width: int, height: int]): Context[T] =
  result = ctx
  result.tb = iw.slice(ctx.tb, x, y, width, height, bounds)

proc all*(comps: varargs[Component]): seq[Component] =
  for comp in comps:
    result.add(comp)

proc initContext*[T](): Context[T] =
  result = Context[T]()
  new result.mountedComponents

