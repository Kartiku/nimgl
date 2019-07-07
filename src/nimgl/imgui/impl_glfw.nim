# Copyright 2019, NimGL contributors.

## ImGUI GLFW Implementation
## ====
## Implementation based on the imgui examples implementations.
## Feel free to use and modify this implementation.
## This needs to be used along with a Renderer.

import ../imgui, ../glfw

type
  GlfwClientApi = enum
    igGlfwClientApi_Unkown
    igGlfwClientApi_OpenGl
    igGlfwClientApi_Vulkan

var
  gWindow: GLFWwindow
  gClientApi = igGlfwClientApi_Unkown
  gTime: float64 = 0.0f
  gMouseJustPressed: array[5, bool]
  gMouseCursors: array[ImGuiMouseCursor.high.int32 + 1, GLFWCursor]

  # Store previous callbacks so they can be chained
  gPrevMouseButtonCallback: glfwMouseButtonProc = nil
  gPrevScrollCallback: glfwScrollProc = nil
  gPrevKeyCallback: glfwKeyProc = nil
  gPrevCharCallback: glfwCharProc = nil

proc igGlfwGetClipboardText(user_data: pointer): cstring {.cdecl.} =
  cast[GLFWwindow](user_data).getClipboardString()

proc igGlfwSetClipboardText(user_data: pointer, text: cstring): void {.cdecl.} =
  cast[GLFWwindow](user_data).setClipboardString(text)

proc igGlfwMouseCallback*(window: GLFWWindow, button: GLFWMouseButton, action: GLFWMouseAction, mods: GLFWKeyMod): void {.cdecl.} =
  if gPrevMouseButtonCallback != nil:
    gPrevMouseButtonCallback(window, button, action, mods)

  if action == maPress and button.ord >= 0 and button.ord < gMouseJustPressed.len:
    gMouseJustPressed[button.ord] = true

proc igGlfwScrollCallback*(window: GLFWWindow, xoff: float64, yoff: float64): void {.cdecl.} =
  if gPrevScrollCallback != nil:
    gPrevScrollCallback(window, xoff, yoff)

  let io = igGetIO()
  io.mouseWheelH += xoff.float32
  io.mouseWheel += yoff.float32

proc igGlfwKeyCallback*(window: GLFWWindow, key: GLFWKey, scancode: int32, action: GLFWKeyAction, mods: GLFWKeyMod): void {.cdecl.} =
  if gPrevKeyCallback != nil:
    gPrevKeyCallback(window, key, scancode, action, mods)

  let io = igGetIO()
  if key.ord < 511 and key.ord >= 0:
    if action == kaPress:
      io.keysDown[key.ord] = true
    elif action == kaRelease:
      io.keysDown[key.ord] = false

  io.keyCtrl = io.keysDown[keyLeftControl.ord] or io.keysDown[keyRightControl.ord]
  io.keyShift = io.keysDown[keyLeftShift.ord] or io.keysDown[keyRightShift.ord]
  io.keyAlt = io.keysDown[keyLeftAlt.ord] or io.keysDown[keyRightAlt.ord]
  io.keySuper = io.keysDown[keyLeftSuper.ord] or io.keysDown[keyRightSuper.ord]

proc igGlfwCharCallback*(window: GLFWWindow, code: uint32): void {.cdecl.} =
  if gPrevCharCallback != nil:
    gPrevCharCallback(window, code)

  let io = igGetIO()
  if code > 0'u32 and code < 0x10000'u32:
    io.addInputCharacter(cast[ImWchar](code))

proc igGlfwInstallCallbacks(window: GLFWwindow) =
  # The already set callback proc should be returned. Store these and and chain callbacks.
  gPrevMouseButtonCallback = gWindow.setMouseButtonCallback(igGlfwMouseCallback)
  gPrevScrollCallback = gWindow.setScrollCallback(igGlfwScrollCallback)
  gPrevKeyCallback = gWindow.setKeyCallback(igGlfwKeyCallback)
  gPrevCharCallback = gWindow.setCharCallback(igGlfwCharCallback)

proc igGlfwInit(window: GLFWwindow, install_callbacks: bool, client_api: GlfwClientApi): bool =
  gWindow = window
  gTime = 0.0f

  let io = igGetIO()
  io.backendFlags = (io.backendFlags.int32 or ImGuiBackendFlags.HasMouseCursors.int32).ImGuiBackendFlags
  io.backendFlags = (io.backendFlags.int32 or ImGuiBackendFlags.HasSetMousePos.int32).ImGuiBackendFlags

  io.keyMap[ImGuiKey.Tab.int32] = keyTab.ord
  io.keyMap[ImGuiKey.LeftArrow.int32] = keyLeft.ord
  io.keyMap[ImGuiKey.RightArrow.int32] = keyRight.ord
  io.keyMap[ImGuiKey.UpArrow.int32] = keyUp.ord
  io.keyMap[ImGuiKey.DownArrow.int32] = keyDown.ord
  io.keyMap[ImGuiKey.PageUp.int32] = keyPage_up.ord
  io.keyMap[ImGuiKey.PageDown.int32] = keyPage_down.ord
  io.keyMap[ImGuiKey.Home.int32] = keyHome.ord
  io.keyMap[ImGuiKey.End.int32] = keyEnd.ord
  io.keyMap[ImGuiKey.Insert.int32] = keyInsert.ord
  io.keyMap[ImGuiKey.Delete.int32] = keyDelete.ord
  io.keyMap[ImGuiKey.Backspace.int32] = keyBackspace.ord
  io.keyMap[ImGuiKey.Space.int32] = keySpace.ord
  io.keyMap[ImGuiKey.Enter.int32] = keyEnter.ord
  io.keyMap[ImGuiKey.Escape.int32] = keyEscape.ord
  io.keyMap[ImGuiKey.A.int32] = keyA.ord
  io.keyMap[ImGuiKey.C.int32] = keyC.ord
  io.keyMap[ImGuiKey.V.int32] = keyV.ord
  io.keyMap[ImGuiKey.X.int32] = keyX.ord
  io.keyMap[ImGuiKey.Y.int32] = keyY.ord
  io.keyMap[ImGuiKey.Z.int32] = keyZ.ord

  # HELP: If you know how to convert char * to const char * through Nim pragmas
  # and types, I would love to know.
  when not defined(cpp):
    io.setClipboardTextFn = igGlfwSetClipboardText
    io.getClipboardTextFn = igGlfwGetClipboardText
  io.clipboardUserData = gWindow
  when defined windows:
    io.imeWindowHandle = gWindow.getWin32Window()

  gMouseCursors[ImGuiMouseCursor.Arrow.int32] = glfwCreateStandardCursor(csArrow)
  gMouseCursors[ImGuiMouseCursor.TextInput.int32] = glfwCreateStandardCursor(csIbeam)
  gMouseCursors[ImGuiMouseCursor.ResizeAll.int32] = glfwCreateStandardCursor(csArrow)
  gMouseCursors[ImGuiMouseCursor.ResizeNS.int32] = glfwCreateStandardCursor(csVresize)
  gMouseCursors[ImGuiMouseCursor.ResizeEW.int32] = glfwCreateStandardCursor(csHresize)
  gMouseCursors[ImGuiMouseCursor.ResizeNESW.int32] = glfwCreateStandardCursor(csArrow)
  gMouseCursors[ImGuiMouseCursor.ResizeNWSE.int32] = glfwCreateStandardCursor(csArrow)
  gMouseCursors[ImGuiMouseCursor.Hand.int32] = glfwCreateStandardCursor(csHand)

  if install_callbacks:
    igGlfwInstallCallbacks(window)

  gClientApi = client_api
  return true

proc igGlfwInitForOpenGL*(window: GLFWwindow, install_callbacks: bool): bool =
  igGlfwInit(window, install_callbacks, igGlfwClientApi_OpenGL)

# @TODO: Vulkan support

proc igGlfwUpdateMousePosAndButtons() =
  let io = igGetIO()
  for i in 0 ..< io.mouseDown.len:
    io.mouseDown[i] = gMouseJustPressed[i] or gWindow.getMouseButton(i.int32) != 0
    gMouseJustPressed[i] = false

  let mousePosBackup = io.mousePos
  io.mousePos = ImVec2(x: -high(float32), y: -high(float32))

  when defined(emscripten): # TODO: actually add support for all the library with emscripten
    let focused = true
  else:
    let focused = gWindow.getWindowAttrib(whFocused) != 0

  if focused:
    if io.wantSetMousePos:
      gWindow.setCursorPos(mousePosBackup.x, mousePosBackup.y)
    else:
      var mouseX: float64
      var mouseY: float64
      gWindow.getCursorPos(mouseX.addr, mouseY.addr)
      io.mousePos = ImVec2(x: mouseX.float32, y: mouseY.float32)

proc igGlfwUpdateMouseCursor() =
  let io = igGetIO()
  if (io.configFlags.int32 and ImGuiConfigFlags.NoMouseCursorChange.int32) or (gWindow.getInputMode(EGLFW_CURSOR) == GLFW_CURSOR_DISABLED):
    return

  var igCursor: ImGuiMouseCursor = igGetMouseCursor()
  if igCursor == ImGuiMouseCursor.None or io.mouseDrawCursor:
    gWindow.setInputMode(EGLFW_CURSOR, GLFW_CURSOR_HIDDEN)
  else:
    gWindow.setInputMode(EGLFW_CURSOR, GLFW_CURSOR_NORMAL)

proc igGlfwNewFrame*() =
  let io = igGetIO()
  assert io.fonts.isBuilt()

  var w: int32
  var h: int32
  var displayW: int32
  var displayH: int32

  gWindow.getWindowSize(w.addr, h.addr)
  gWindow.getFramebufferSize(displayW.addr, displayH.addr)
  io.displaySize = ImVec2(x: w.float32, y: h.float32)
  io.displayFramebufferScale = ImVec2(x: if w > 0: displayW.float32 / w.float32 else: 0.0f, y: if h > 0: displayH.float32 / h.float32 else: 0.0f)

  let currentTime = glfwGetTime()
  io.deltaTime = if gTime > 0.0f: (currentTime - gTime).float32 else: (1.0f / 60.0f).float32
  gTime = currentTime

  igGlfwUpdateMousePosAndButtons()
  igGlfwUpdateMouseCursor()

  # @TODO: gamepad mapping

proc igGlfwShutdown*() =
  for i in 0 ..< ImGuiMouseCursor.high.int32 + 1:
    glfwDestroyCursor(gMouseCursors[i])
    gMouseCursors[i] = nil
  gClientApi = igGlfwClientApi_Unkown
