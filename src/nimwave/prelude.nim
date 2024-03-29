from nimwave as nw import nil
from sequtils import nil
from ansiutils/codes import nil
from tables import `[]`, `[]=`, keys, del
from sets import nil
from nimwave/tui import nil
from illwave as iw import `[]`, `[]=`, `==`
from unicode import `$`, runeLen, toRunes

method mount*(node: nw.Node, ctx: var nw.Context[State]) {.base, locks: "unknown".} =
  discard

method render*(node: nw.Node, ctx: var nw.Context[State]) {.base, locks: "unknown".} =
  discard

method unmount*(node: nw.Node, ctx: var nw.Context[State]) {.base, locks: "unknown".} =
  discard

proc renderRoot*(node: nw.Node, ctx: var nw.Context[State]) =
  if ctx.tb.buf == nil:
    raise newException(Exception, "The `tb` field must be set in the context object")
  new ctx.ids
  render(node, ctx)
  # unmount any components that weren't in the tree
  for id in sequtils.toSeq(ctx.mountedNodes[].keys):
    if not sets.contains(ctx.ids[], id):
      let comp = ctx.mountedNodes[id]
      unmount(comp, ctx)
      ctx.mountedNodes[].del(id)
  # reset ids
  ctx.ids = nil

proc getMounted*[T](node: T, ctx: var nw.Context[State]): T =
  if node.id == "":
    raise newException(Exception, "Node has no id")
  if ctx.ids != nil:
    sets.incl(ctx.ids[], node.id)
  if not tables.contains(ctx.mountedNodes, node.id):
    mount(node, ctx)
    ctx.mountedNodes[node.id] = node
    return node
  else:
    let mnode = ctx.mountedNodes[node.id]
    if not(mnode of T):
      raise newException(Exception, "Node with id '" & node.id & "' is not a " & $T & ". Maybe there are two nodes with the same id?")
    return cast[T](mnode)

# box

method render*(node: nw.Box, ctx: var nw.Context[State]) =
  var
    xStart = 0
    yStart = 0
  case node.border:
  of nw.Border.None:
    discard
  of nw.Border.Single, nw.Border.Double, nw.Border.Hidden:
    xStart = 1
    yStart = 1
  if node.children.len > 0:
    case node.direction:
    of nw.Direction.Horizontal:
      var
        x = xStart
        remainingWidth = iw.width(ctx.tb).int
        remainingChildren = node.children.len
        maxHeight = iw.height(ctx.tb)
      for child in node.children:
        let initialWidth = int(remainingWidth / remainingChildren)
        var childContext = nw.slice(ctx, x, yStart, max(0, initialWidth - (xStart * 2)), max(0, iw.height(ctx.tb) - (yStart * 2)))
        render(child, childContext)
        let actualWidth = iw.width(childContext.tb)
        x += actualWidth
        remainingWidth -= actualWidth
        remainingChildren -= 1
        maxHeight = max(maxHeight, iw.height(childContext.tb)+(yStart*2))
      ctx = nw.slice(ctx, 0, 0, x+xStart, maxHeight)
    of nw.Direction.Vertical:
      var
        y = yStart
        remainingHeight = iw.height(ctx.tb).int
        remainingChildren = node.children.len
        maxWidth = iw.width(ctx.tb)
      for child in node.children:
        let initialHeight = int(remainingHeight / remainingChildren)
        var childContext = nw.slice(ctx, xStart, y, max(0, iw.width(ctx.tb) - (xStart * 2)), max(0, initialHeight - (yStart * 2)))
        render(child, childContext)
        let actualHeight = iw.height(childContext.tb)
        y += actualHeight
        remainingHeight -= actualHeight
        remainingChildren -= 1
        maxWidth = max(maxWidth, iw.width(childContext.tb)+(xStart*2))
      ctx = nw.slice(ctx, 0, 0, maxWidth, y+yStart)
  case node.border:
  of nw.Border.Single:
    iw.drawRect(ctx.tb, 0, 0, iw.width(ctx.tb)-1, iw.height(ctx.tb)-1)
  of nw.Border.Double:
    iw.drawRect(ctx.tb, 0, 0, iw.width(ctx.tb)-1, iw.height(ctx.tb)-1, doubleStyle = true)
  else:
    discard

# scroll

method render*(node: nw.Scroll, ctx: var nw.Context[State]) =
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
  var ctx = nw.slice(ctx, mnode.scrollX, mnode.scrollY, width, height, bounds)
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

method render*(node: nw.Text, ctx: var nw.Context[State]) =
  case node.kind:
  of nw.TextKind.Read:
    ctx = nw.slice(ctx, 0, 0, codes.stripCodes(node.str).runeLen, 1)
    tui.write(ctx.tb, 0, 0, node.str)
  of nw.TextKind.Edit:
    let mnode = getMounted(node, ctx)
    if mnode.cursorX > mnode.str.runeLen:
      mnode.cursorX = mnode.str.runeLen
    if node.enabled:
      case node.key:
      of iw.Key.Backspace:
        if mnode.cursorX > 0:
          let
            line = mnode.str.toRunes
            x = mnode.cursorX - 1
            newLine = $line[0 ..< x] & $line[x + 1 ..< line.len]
          mnode.str = newLine
          mnode.cursorX -= 1
      of iw.Key.Delete:
        if mnode.cursorX < mnode.str.runeLen:
          let
            line = mnode.str.toRunes
            newLine = $line[0 ..< mnode.cursorX] & $line[mnode.cursorX + 1 ..< line.len]
          mnode.str = newLine
      of iw.Key.Left:
        mnode.cursorX -= 1
        if mnode.cursorX < 0:
          mnode.cursorX = 0
      of iw.Key.Right:
        mnode.cursorX += 1
        if mnode.cursorX > mnode.str.runeLen:
          mnode.cursorX = mnode.str.runeLen
      of iw.Key.Home:
        mnode.cursorX = 0
      of iw.Key.End:
        mnode.cursorX = mnode.str.runeLen
      else:
        discard
      for ch in node.chars:
        let
          line = mnode.str.toRunes
          before = line[0 ..< mnode.cursorX]
          after = line[mnode.cursorX ..< line.len]
        mnode.str = $before & $ch & $after
        mnode.cursorX += 1
    # get scroll component
    let scroll = getMounted(nw.Scroll(id: node.id & "/scroll"), ctx)
    scroll.child = nw.Text(str: mnode.str)
    # update scroll position
    let cursorXDiff = scroll.scrollX + mnode.cursorX
    if cursorXDiff >= iw.width(ctx.tb) - 1:
      scroll.scrollX = iw.width(ctx.tb) - 1 - mnode.cursorX
    elif cursorXDiff < 0:
      scroll.scrollX = 0 - mnode.cursorX
    # render
    ctx = nw.slice(ctx, 0, 0, iw.width(ctx.tb), 1)
    render(scroll, ctx)
    if node.enabled:
      var cell = ctx.tb[scroll.scrollX + mnode.cursorX, 0]
      cell.bg = iw.bgYellow
      cell.fg = iw.fgBlack
      ctx.tb[scroll.scrollX + mnode.cursorX, 0] = cell
