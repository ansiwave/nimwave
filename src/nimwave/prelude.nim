from nimwave import nil
from sequtils import nil
from ansiutils/codes import nil
from tables import nil
from sets import nil
from nimwave/tui import nil
from illwave as iw import nil

method mount*(node: nimwave.Component, ctx: var nimwave.Context[State]) {.base, locks: "unknown".} =
  discard

method render*(node: nimwave.Component, ctx: var nimwave.Context[State]) {.base, locks: "unknown".} =
  if node.id != "":
    ctx.idPath.add(node.id)

method unmount*(node: nimwave.Component, ctx: var nimwave.Context[State]) {.base, locks: "unknown".} =
  discard

proc renderRoot*(node: nimwave.Component, ctx: var nimwave.Context[State]) =
  if ctx.tb.buf == nil:
    raise newException(Exception, "The `tb` field must be set in the context object")
  new ctx.ids
  render(node, ctx)
  # unmount any components that weren't in the tree
  for idPath in sequtils.toSeq(ctx.mountedComponents[].keys):
    if not sets.contains(ctx.ids[], idPath):
      let comp = ctx.mountedComponents[idPath]
      unmount(comp, ctx)
      ctx.mountedComponents[].del(idPath)
  # reset id fields
  ctx.ids = nil
  ctx.idPath = @[]

proc getMounted*[T](node: T, ctx: var nimwave.Context[State]): T =
  if node.id == "":
    raise newException(Exception, "Node has no id")
  elif ctx.idPath.len == 0 or ctx.idPath[^1] != node.id:
    raise newException(Exception, "You must call the base method first! You can do it like this:\nprocCall render(nimwave.Component(node), ctx)")
  if sets.contains(ctx.ids[], ctx.idPath):
    raise newException(Exception, "id already exists somewhere else in the tree: " & $ctx.idPath)
  sets.incl(ctx.ids[], ctx.idPath)
  if not tables.contains(ctx.mountedComponents, ctx.idPath):
    mount(node, ctx)
    ctx.mountedComponents[ctx.idPath] = node
    return node
  else:
    return cast[T](ctx.mountedComponents[ctx.idPath])

# box

type
  Direction* {.pure.} = enum
    Vertical, Horizontal,
  Border* {.pure.} = enum
    None, Single, Double, Hidden,
  Box* = ref object of nimwave.Component
    direction*: Direction
    border*: Border
    children*: seq[nimwave.Component]

method render*(node: Box, ctx: var nimwave.Context[State]) =
  procCall render(nimwave.Component(node), ctx)
  var
    xStart = 0
    yStart = 0
  case node.border:
  of None:
    discard
  of Single, Double, Hidden:
    xStart = 1
    yStart = 1
  if node.children.len > 0:
    case node.direction:
    of Horizontal:
      var
        x = xStart
        remainingWidth = iw.width(ctx.tb).int
        remainingChildren = node.children.len
        maxHeight = iw.height(ctx.tb)
      for child in node.children:
        let initialWidth = int(remainingWidth / remainingChildren)
        var childContext = nimwave.slice(ctx, x, yStart, max(0, initialWidth - (xStart * 2)), max(0, iw.height(ctx.tb) - (yStart * 2)))
        render(child, childContext)
        let actualWidth = iw.width(childContext.tb)
        x += actualWidth
        remainingWidth -= actualWidth
        remainingChildren -= 1
        maxHeight = max(maxHeight, iw.height(childContext.tb)+(yStart*2))
      ctx = nimwave.slice(ctx, 0, 0, x+xStart, maxHeight)
    of Vertical:
      var
        y = yStart
        remainingHeight = iw.height(ctx.tb).int
        remainingChildren = node.children.len
        maxWidth = iw.width(ctx.tb)
      for child in node.children:
        let initialHeight = int(remainingHeight / remainingChildren)
        var childContext = nimwave.slice(ctx, xStart, y, max(0, iw.width(ctx.tb) - (xStart * 2)), max(0, initialHeight - (yStart * 2)))
        render(child, childContext)
        let actualHeight = iw.height(childContext.tb)
        y += actualHeight
        remainingHeight -= actualHeight
        remainingChildren -= 1
        maxWidth = max(maxWidth, iw.width(childContext.tb)+(xStart*2))
      ctx = nimwave.slice(ctx, 0, 0, maxWidth, y+yStart)
  case node.border:
  of Single:
    iw.drawRect(ctx.tb, 0, 0, iw.width(ctx.tb)-1, iw.height(ctx.tb)-1)
  of Double:
    iw.drawRect(ctx.tb, 0, 0, iw.width(ctx.tb)-1, iw.height(ctx.tb)-1, doubleStyle = true)
  else:
    discard

# scroll

type
  Scroll* = ref object of nimwave.Component
    scrollX*: int
    scrollY*: int
    changeScrollX*: int
    changeScrollY*: int
    growX*: bool
    growY*: bool
    child*: nimwave.Component

method render*(node: Scroll, ctx: var nimwave.Context[State]) =
  procCall render(nimwave.Component(node), ctx)
  let mnode = getMounted(node, ctx)
  let
    width = iw.width(ctx.tb)
    height = iw.height(ctx.tb)
    boundsWidth =
      if mnode.growX:
        -1
      else:
        width
    boundsHeight =
      if mnode.growY:
        -1
      else:
        height
    bounds = (0, 0, boundsWidth, boundsHeight)
  var ctx = nimwave.slice(ctx, mnode.scrollX, mnode.scrollY, width, height, bounds)
  render(node.child, ctx)
  if node.changeScrollX != 0:
    mnode.scrollX += node.changeScrollX
    let minX = width - iw.width(ctx.tb)
    if minX < 0:
      mnode.scrollX = mnode.scrollX.clamp(minX, 0)
    else:
      mnode.scrollX = 0
  if node.changeScrollY != 0:
    mnode.scrollY += node.changeScrollY
    let minY = height - iw.height(ctx.tb)
    if minY < 0:
      mnode.scrollY = mnode.scrollY.clamp(minY, 0)
    else:
      mnode.scrollY = 0

# text

type
  TextKind* {.pure.} = enum
    Read,
    Edit,
  Text* = ref object of nimwave.Component
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

method render*(node: Text, ctx: var nimwave.Context[State]) =
  procCall render(nimwave.Component(node), ctx)
  case node.kind:
  of Read:
    ctx = nimwave.slice(ctx, 0, 0, codes.stripCodes(node.text).runeLen, 1)
    tui.write(ctx.tb, 0, 0, node.text)
  of Edit:
    let mnode = getMounted(node, ctx)
    if node.enabled:
      case node.key:
      of iw.Key.Backspace:
        if mnode.cursorX > 0:
          let
            line = mnode.text.toRunes
            x = mnode.cursorX - 1
            newLine = $line[0 ..< x] & $line[x + 1 ..< line.len]
          mnode.text = newLine
          mnode.cursorX -= 1
      of iw.Key.Delete:
        if mnode.cursorX < mnode.text.runeLen:
          let
            line = mnode.text.toRunes
            newLine = $line[0 ..< mnode.cursorX] & $line[mnode.cursorX + 1 ..< line.len]
          mnode.text = newLine
      of iw.Key.Left:
        mnode.cursorX -= 1
        if mnode.cursorX < 0:
          mnode.cursorX = 0
      of iw.Key.Right:
        mnode.cursorX += 1
        if mnode.cursorX > mnode.text.runeLen:
          mnode.cursorX = mnode.text.runeLen
      of iw.Key.Home:
        mnode.cursorX = 0
      of iw.Key.End:
        mnode.cursorX = mnode.text.runeLen
      else:
        discard
      for ch in node.chars:
        let
          line = mnode.text.toRunes
          before = line[0 ..< mnode.cursorX]
          after = line[mnode.cursorX ..< line.len]
        mnode.text = $before & $ch & $after
        mnode.cursorX += 1
    # create scroll component if it doesn't exist
    if mnode.scroll == nil:
      mnode.scroll = Scroll(id: "text-scroll")
    mnode.scroll.child = Text(text: mnode.text)
    # update scroll position
    let cursorXDiff = mnode.scroll.scrollX + mnode.cursorX
    if cursorXDiff >= iw.width(ctx.tb) - 1:
      mnode.scroll.scrollX = iw.width(ctx.tb) - 1 - mnode.cursorX
    elif cursorXDiff < 0:
      mnode.scroll.scrollX = 0 - mnode.cursorX
    # render
    ctx = nimwave.slice(ctx, 0, 0, iw.width(ctx.tb), 1)
    render(mnode.scroll, ctx)
    if node.enabled:
      var cell = ctx.tb[mnode.scroll.scrollX + mnode.cursorX, 0]
      cell.bg = iw.bgYellow
      cell.fg = iw.fgBlack
      ctx.tb[mnode.scroll.scrollX + mnode.cursorX, 0] = cell
