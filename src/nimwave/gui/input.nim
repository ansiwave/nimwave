from illwave as iw import nil
import paranim/glfw
import tables

const
  glfwToIllwaveKey* =
    {GLFWKey.Backspace: iw.Key.Backspace,
     GLFWKey.Delete: iw.Key.Delete,
     GLFWKey.Tab: iw.Key.Tab,
     GLFWKey.Enter: iw.Key.Enter,
     GLFWKey.Escape: iw.Key.Escape,
     GLFWKey.Up: iw.Key.Up,
     GLFWKey.Down: iw.Key.Down,
     GLFWKey.Left: iw.Key.Left,
     GLFWKey.Right: iw.Key.Right,
     GLFWKey.Home: iw.Key.Home,
     GLFWKey.End: iw.Key.End,
     GLFWKey.PageUp: iw.Key.PageUp,
     GLFWKey.PageDown: iw.Key.PageDown,
     GLFWKey.Insert: iw.Key.Insert,
     }.toTable
  glfwToIllwaveCtrlKey* =
    {GLFWKey.A: iw.Key.CtrlA,
     GLFWKey.B: iw.Key.CtrlB,
     GLFWKey.C: iw.Key.CtrlC,
     GLFWKey.D: iw.Key.CtrlD,
     GLFWKey.E: iw.Key.CtrlE,
     GLFWKey.F: iw.Key.CtrlF,
     GLFWKey.G: iw.Key.CtrlG,
     GLFWKey.H: iw.Key.CtrlH,
     # Ctrl-I is Tab
     GLFWKey.J: iw.Key.CtrlJ,
     GLFWKey.K: iw.Key.CtrlK,
     GLFWKey.L: iw.Key.CtrlL,
     # Ctrl-M is Enter
     GLFWKey.N: iw.Key.CtrlN,
     GLFWKey.O: iw.Key.CtrlO,
     GLFWKey.P: iw.Key.CtrlP,
     GLFWKey.Q: iw.Key.CtrlQ,
     GLFWKey.R: iw.Key.CtrlR,
     GLFWKey.S: iw.Key.CtrlS,
     GLFWKey.T: iw.Key.CtrlT,
     GLFWKey.U: iw.Key.CtrlU,
     GLFWKey.V: iw.Key.CtrlV,
     GLFWKey.W: iw.Key.CtrlW,
     GLFWKey.X: iw.Key.CtrlX,
     GLFWKey.Y: iw.Key.CtrlY,
     GLFWKey.Z: iw.Key.CtrlZ,
     GLFWKey.Backslash: iw.Key.CtrlBackslash,
     GLFWKey.RightBracket: iw.Key.CtrlRightBracket,
     }.toTable
  glfwToIllwaveMouseButton* =
    {GLFWMouseButton.Button1: iw.MouseButton.mbLeft,
     GLFWMouseButton.Button2: iw.MouseButton.mbRight,
     }.toTable
  glfwToIllwaveMouseAction* =
    {GLFWPress: iw.MouseButtonAction.mbaPressed,
     GLFWRelease: iw.MouseButtonAction.mbaReleased,
     }.toTable

