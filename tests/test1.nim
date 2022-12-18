import unittest

from illwave as iw import nil
from nimwave as nw import nil

type
  State = object
  CustomNode = ref object of nw.Node

include nimwave/prelude

var
  mounted = false
  unmounted = false

method mount*(node: CustomNode, ctx: var nw.Context[State]) =
  mounted = true

method render*(node: CustomNode, ctx: var nw.Context[State]) =
  discard getMounted(node, ctx)

method unmount*(node: CustomNode, ctx: var nw.Context[State]) =
  unmounted = true

test "mount and unmount":
  var ctx = nw.initContext[State]()
  ctx.tb = iw.initTerminalBuffer(0, 0)
  renderRoot(CustomNode(id: "test"), ctx)
  check mounted
  check not unmounted
  renderRoot(CustomNode(id: "test"), ctx)
  check not unmounted
  renderRoot(nw.Text(str: "hi"), ctx)
  check unmounted
