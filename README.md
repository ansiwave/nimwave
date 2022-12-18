With NIMWAVE, you can build TUI programs for the terminal, the desktop (via OpenGL/GLFW) and the web (via web assembly). Pedantic nerds love to point out that TUI stands for *text* user interface, not terminal. NIMWAVE is what happens when one of those nerds writes a library. Let's decouple TUIs from the terminal by running them where the normies are.

<p align="center">
  <img src="nimwave.png" >
</p>

##  Getting Started

The best way to begin is to clone [the starter project](https://github.com/ansiwave/nimwave_starter) and run the commands in its README.

For a much more involved example project, see [ANSIWAVE BBS](https://github.com/ansiwave/ansiwave_bbs). It is the project that NIMWAVE was extracted from.

## Documentation

NIMWAVE provides a way to build your UI with a hierarchy of nodes. Here's an example that renders a few lines of text:

```nim
render(
  nw.Box(
    direction: nw.Direction.Vertical,
    border: nw.Border.Single,
    children: nw.seq(
      "Hello, world!",
      "Nim rocks",
    ),
  ),
  ctx
)
```

### Custom nodes

The `nw.Box` is a built-in node. You can easily define your own nodes as well. For example, let's move that into a custom node:

```nim
type
  MyCustomNode = ref object of nw.Node
    lines: seq[string]

method render*(node: MyCustomNode, ctx: var nw.Context[State]) =
  render(
    nw.Box(
      direction: nw.Direction.Vertical,
      border: nw.Border.Single,
      children: nw.seq(node.lines),
    ),
    ctx
  )
```

Now it can be rendered like this:

```nim
render(MyCustomNode(lines: @["Hello, world!", "Nim rocks"]), ctx)
```

### Resizing nodes

By default, a node will receive a size from its parent node. This size can be found from `iw.width(ctx.tb)` and `iw.height(ctx.tb)`. Any node can change its own size using `nw.slice` like this:

```nim
method render*(node: MyCustomNode, ctx: var nw.Context[State]) =
  ctx = nw.slice(ctx, 0, 0, iw.width(ctx.tb), node.lines.len+2)
  render(
    nw.Box(
      direction: nw.Direction.Vertical,
      border: nw.Border.Single,
      children: nw.seq(node.lines),
    ),
    ctx
  )
```

Here, the node is retaining the width given to it by the parent, but it is resizing its height to be the number of lines of text plus 2 (for the border).

### Adding styling

All low level render operations are dona via [illwave](https://github.com/ansiwave/illwave). You can manipulate individual cells in the `TerminalBuffer` like this:

```nim
# change the foreground/background color
ctx.tb[0, 0].fg = iw.fgBlue
ctx.tb[0, 0].bg = iw.bgYellow

# change the character
ctx.tb[0, 0].ch = "Z".toRunes[0]
```

The coordinates here are relative, so `0, 0` will be the top left corner of the node you are in, not the top left corner of the entire terminal.

Also, strings may include ANSI escape codes directly:

```nim
render(nw.Text(str: "\e[32;43mHello, world!\e[0m"), ctx)
```

### Stateful nodes

Some nodes require local state. For example, let's make a button that increments a number every time it is clicked. First, we'll make a custom node for the button:

```nim
type
  Button = ref object of nw.Node
    str: string
    mouse: iw.MouseInfo
    action: proc ()

method render*(node: Button, ctx: var nw.Context[State]) =
  ctx = nw.slice(ctx, 0, 0, node.str.runeLen+2, iw.height(ctx.tb))
  if node.mouse.action == iw.MouseButtonAction.mbaPressed and iw.contains(ctx.tb, node.mouse):
    node.action()
  render(
    nw.Box(
      direction: nw.Direction.Horizontal,
      border: nw.Border.Single,
      children: nw.seq(node.str),
    ),
    ctx
  )
```

Next, we make a node that places this button next to a count, and increments the count when the button is clicked:

```nim
type
  Counter = ref object of nw.Node
    mouse: iw.MouseInfo
    count: int

method render*(node: Counter, ctx: var nw.Context[State]) =
  let mnode = getMounted(node, ctx)
  ctx = nw.slice(ctx, 0, 0, 15, 3)
  proc incCount() =
    mnode.count += 1
  render(
    nw.Box(
      direction: nw.Direction.Horizontal,
      border: nw.Border.None,
      children: nw.seq(
        nw.Box(
          direction: nw.Direction.Horizontal,
          border: nw.Border.Hidden,
          children: nw.seq($mnode.count),
        ),
        Button(str: "Count", mouse: node.mouse, action: incCount),
      ),
    ),
    ctx
  )
```

For a node to maintain state, it must be "mounted", which just means its reference is stored in the context. When you call `getMounted`, it will look for the mounted version of that node and return it. If it hasn't been mounted yet, it'll do so. If you want to run custom code when a node mounts or unmounts, you can define a `mount` and `unmount` method with the same signature as `render`.

The mounted version, called `mnode` here, is the one you should use to read/write stateful data. Meanwhile, if you want to read any new data that came after mounting, such as the `mouse` data, you should read from the original `node` argument. If you tried reading that from `mnode` it would give you the value that it was when it mounted.

The `Counter` can then be rendered like this:

```nim
render(Counter(id: "counter", mouse: mouse), ctx)
```

Note that all mounted nodes *must* have a unique `id`. If the parent node has an id, it is best to combine them together, such as `node.id & "/counter"`, to ensure it will be unique. NIMWAVE tries its best to throw an error if you reuse an id, but it's not always possible to tell, so it is up to you to ensure this.

### Storing state in the Context

Another place to store state is inside the `Context` object. This object is passed to every node, so this is a nice way to pass state that should be accessible everywhere. The starter project defines it like this:

```nim
type
  State = object
    focusIndex*: int
    focusAreas*: ref seq[iw.TerminalBuffer]

var ctx = nw.initContext[State]()
```

This object is completely up to you to define, and it will be accessible to you from `ctx.data`. In this case, it contains state for a simple focus system. The starter project defines this function:

```nim
proc addFocusArea(ctx: var nw.Context[State]): bool =
  result = ctx.data.focusIndex == ctx.data.focusAreas[].len
  ctx.data.focusAreas[].add(ctx.tb)
```

Inside nodes that should be focusable, you'll find `let focused = addFocusArea(ctx)` which adds the node's `TerminalBuffer` to the `focusAreas` and returns true if its length equals the `focusIndex`.

This is just one way to implement a focus system. Notice that this object is using both a value type and a ref type. Always consider what kind of behavior you want; value types will be copied from node to node, so if they are modified from inside a node, the change will only be visible to its own children. Use a ref type if you want all nodes to see/modify the same data.
