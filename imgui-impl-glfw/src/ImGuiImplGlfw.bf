using System;
using glfw_beef;

namespace imgui_beef {
	static class ImGuiImplGlfw {
		// dear imgui: Platform Binding for GLFW
		// This needs to be used along with a Renderer (e.g. OpenGL3, Vulkan..)
		// (Info: GLFW is a cross-platform general purpose library for handling windows, inputs, OpenGL/Vulkan graphics context creation, etc.)
		// (Requires: GLFW 3.1+)

		// Implemented features:
		//  [X] Platform: Clipboard support.
		//  [X] Platform: Gamepad support. Enable with 'io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad'.
		//  [X] Platform: Mouse cursor shape and visibility. Disable with 'io.ConfigFlags |= ImGuiConfigFlags_NoMouseCursorChange' (note: the resizing cursors requires GLFW 3.4+).
		//  [X] Platform: Keyboard arrays indexed using GLFW_KEY_* codes, e.g. ImGui::IsKeyPressed(GLFW_KEY_SPACE).

		// You can copy and use unmodified imgui_impl_* files in your project. See main.cpp for an example of using this.
		// If you are new to dear imgui, read examples/README.txt and read the documentation at the top of imgui.cpp.
		// https://github.com/ocornut/imgui

		// CHANGELOG
		// (minor and older changes stripped away, please see git history for details)
		//  2020-01-17: Inputs: Disable error callback while assigning mouse cursors because some X11 setup don't have them and it generates errors.
		//  2019-12-05: Inputs: Added support for new mouse cursors added in GLFW 3.4+ (resizing cursors, not allowed cursor).
		//  2019-10-18: Misc: Previously installed user callbacks are now restored on shutdown.
		//  2019-07-21: Inputs: Added mapping for ImGuiKey_KeyPadEnter.
		//  2019-05-11: Inputs: Don't filter value from character callback before calling AddInputCharacter().
		//  2019-03-12: Misc: Preserve DisplayFramebufferScale when main window is minimized.
		//  2018-11-30: Misc: Setting up io.BackendPlatformName so it can be displayed in the About Window.
		//  2018-11-07: Inputs: When installing our GLFW callbacks, we save user's previously installed ones - if any - and chain call them.
		//  2018-08-01: Inputs: Workaround for Emscripten which doesn't seem to handle focus related calls.
		//  2018-06-29: Inputs: Added support for the ImGuiMouseCursor_Hand cursor.
		//  2018-06-08: Misc: Extracted imgui_impl_glfw.cpp/.h away from the old combined GLFW+OpenGL/Vulkan examples.
		//  2018-03-20: Misc: Setup io.BackendFlags ImGuiBackendFlags_HasMouseCursors flag + honor ImGuiConfigFlags_NoMouseCursorChange flag.
		//  2018-02-20: Inputs: Added support for mouse cursors (ImGui::GetMouseCursor() value, passed to glfwSetCursor()).
		//  2018-02-06: Misc: Removed call to ImGui::Shutdown() which is not available from 1.60 WIP, user needs to call CreateContext/DestroyContext themselves.
		//  2018-02-06: Inputs: Added mapping for ImGuiKey_Space.
		//  2018-01-25: Inputs: Added gamepad support if ImGuiConfigFlags_NavEnableGamepad is set.
		//  2018-01-25: Inputs: Honoring the io.WantSetMousePos by repositioning the mouse (when using navigation and ImGuiConfigFlags_NavMoveMouse is set).
		//  2018-01-20: Inputs: Added Horizontal Mouse Wheel support.
		//  2018-01-18: Inputs: Added mapping for ImGuiKey_Insert.
		//  2017-08-25: Inputs: MousePos set to -FLT_MAX,-FLT_MAX when mouse is unavailable/missing (instead of -1,-1).
		//  2016-10-15: Misc: Added a void* user_data parameter to Clipboard function handlers.

		private enum GlfwClientApi {
		    GlfwClientApi_Unknown,
		    GlfwClientApi_OpenGL,
		    GlfwClientApi_Vulkan
		};

		private static GlfwWindow*                              g_Window = null;    // Main window
		private static GlfwClientApi                            g_ClientApi = .GlfwClientApi_Unknown;
		private static double                                   g_Time = 0.0;
		private static bool[5]                                  g_MouseJustPressed = .(false, false, false, false, false);
		private static GlfwCursor*[(.) ImGui.MouseCursor.COUNT] g_MouseCursors = .(null,);
		private static bool                                     g_InstalledCallbacks = false;

		private static Glfw.MouseButtonCallback                 g_PrevUserCallbackMousebutton = null;
		private static Glfw.ScrollCallback                      g_PrevUserCallbackScroll = null;
		private static Glfw.KeyCallback                         g_PrevUserCallbackKey = null;
		private static Glfw.CharCallback                        g_PrevUserCallbackChar = null;

		private static char8* ImGui_ImplGlfw_GetClipboardText(void* user_data) {
		    return Glfw.[Friend]glfwGetClipboardString((GlfwWindow*) user_data);
		}

		private static void ImGui_ImplGlfw_SetClipboardText(void* user_data, char8* text) {
		    Glfw.[Friend]glfwSetClipboardString((GlfwWindow*) user_data, text);
		}

		public static bool ImGui_ImplGlfw_Init(GlfwWindow* window, bool installCallbacks, GlfwClientApi clientApi)
		{
		    g_Window = window;
		    g_Time = 0.0;

		    // Setup back-end capabilities flags
		    ref ImGui.IO io = ref ImGui.GetIO();
		    io.BackendFlags |= .HasMouseCursors;         // We can honor GetMouseCursor() values (optional)
		    io.BackendFlags |= .HasSetMousePos;          // We can honor io.WantSetMousePos requests (optional, rarely used)
		    io.BackendPlatformName = "imgui_impl_glfw";

		    // Keyboard mapping. ImGui will use those indices to peek into the io.KeysDown[] array.
		    io.KeyMap[(int) ImGui.Key.Tab] = (.) GlfwInput.Key.Tab;
			io.KeyMap[(int) ImGui.Key.LeftArrow] = (.) GlfwInput.Key.Left;
			io.KeyMap[(int) ImGui.Key.RightArrow] = (.) GlfwInput.Key.Right;
			io.KeyMap[(int) ImGui.Key.UpArrow] = (.) GlfwInput.Key.Up;
			io.KeyMap[(int) ImGui.Key.DownArrow] = (.) GlfwInput.Key.Down;
			io.KeyMap[(int) ImGui.Key.PageUp] = (.) GlfwInput.Key.PageUp;
			io.KeyMap[(int) ImGui.Key.PageDown] = (.) GlfwInput.Key.PageDown;
			io.KeyMap[(int) ImGui.Key.Home] = (.) GlfwInput.Key.Home;
			io.KeyMap[(int) ImGui.Key.End] = (.) GlfwInput.Key.End;
			io.KeyMap[(int) ImGui.Key.Insert] = (.) GlfwInput.Key.Insert;
			io.KeyMap[(int) ImGui.Key.Delete] = (.) GlfwInput.Key.Delete;
			io.KeyMap[(int) ImGui.Key.Backspace] = (.) GlfwInput.Key.Backspace;
			io.KeyMap[(int) ImGui.Key.Space] = (.) GlfwInput.Key.Space;
			io.KeyMap[(int) ImGui.Key.Enter] = (.) GlfwInput.Key.Enter;
			io.KeyMap[(int) ImGui.Key.Escape] = (.) GlfwInput.Key.Escape;
			io.KeyMap[(int) ImGui.Key.KeyPadEnter] = (.) GlfwInput.Key.KpEnter;
			io.KeyMap[(int) ImGui.Key.A] = (.) GlfwInput.Key.A;
			io.KeyMap[(int) ImGui.Key.C] = (.) GlfwInput.Key.C;
			io.KeyMap[(int) ImGui.Key.V] = (.) GlfwInput.Key.V;
			io.KeyMap[(int) ImGui.Key.X] = (.) GlfwInput.Key.X;
			io.KeyMap[(int) ImGui.Key.Y] = (.) GlfwInput.Key.Y;
			io.KeyMap[(int) ImGui.Key.Z] = (.) GlfwInput.Key.Z;

		    io.SetClipboardTextFn = => ImGui_ImplGlfw_SetClipboardText;
		    io.GetClipboardTextFn = => ImGui_ImplGlfw_GetClipboardText;
		    io.ClipboardUserData = g_Window;
#if BF_PLATFORM_WINDOWS
		    io.ImeWindowHandle = Glfw.GetWin32Window(g_Window);
#endif

		    // Create mouse cursors
		    // (By design, on X11 cursors are user configurable and some cursors may be missing. When a cursor doesn't exist,
		    // GLFW will emit an error which will often be printed by the app, so we temporarily disable error reporting.
		    // Missing cursors will return NULL and our _UpdateMouseCursor() function will use the Arrow cursor instead.)
		    Glfw.ErrorCallback prev_error_callback = Glfw.SetErrorCallback(null, false);	 
		    g_MouseCursors[(int) ImGui.MouseCursor.Arrow] = Glfw.CreateStandardCursor(.Arrow);
		    g_MouseCursors[(int) ImGui.MouseCursor.TextInput] = Glfw.CreateStandardCursor(.IBeam);
		    g_MouseCursors[(int) ImGui.MouseCursor.ResizeNS] = Glfw.CreateStandardCursor(.VResize);
		    g_MouseCursors[(int) ImGui.MouseCursor.ResizeEW] = Glfw.CreateStandardCursor(.HResize);
		    g_MouseCursors[(int) ImGui.MouseCursor.Hand] = Glfw.CreateStandardCursor(.Hand);
//#if !GLFW_HAS_NEW_CURSORS
		    /*g_MouseCursors[(int) ImGui.MouseCursor.ResizeAll] = Glfw.CreateStandardCursor(GLFW_RESIZE_ALL_CURSOR);
		    g_MouseCursors[(int) ImGui.MouseCursor.ResizeNESW] = Glfw.CreateStandardCursor(GLFW_RESIZE_NESW_CURSOR);
		    g_MouseCursors[(int) ImGui.MouseCursor.ResizeNWSE] = Glfw.CreateStandardCursor(GLFW_RESIZE_NWSE_CURSOR);
		    g_MouseCursors[(int) ImGui.MouseCursor.NotAllowed] = Glfw.CreateStandardCursor(GLFW_NOT_ALLOWED_CURSOR);*/
//#else
		    g_MouseCursors[(int) ImGui.MouseCursor.ResizeAll] = Glfw.CreateStandardCursor(.Arrow);
		    g_MouseCursors[(int) ImGui.MouseCursor.ResizeNESW] = Glfw.CreateStandardCursor(.Arrow);
		    g_MouseCursors[(int) ImGui.MouseCursor.ResizeNWSE] = Glfw.CreateStandardCursor(.Arrow);
		    g_MouseCursors[(int) ImGui.MouseCursor.NotAllowed] = Glfw.CreateStandardCursor(.Arrow); 
//#endif
		    Glfw.SetErrorCallback(prev_error_callback);

		    // Chain GLFW callbacks: our callbacks will call the user's previously installed callbacks, if any.
		    g_PrevUserCallbackMousebutton = null;
		    g_PrevUserCallbackScroll = null;
		    g_PrevUserCallbackKey = null;
		    g_PrevUserCallbackChar = null;
		    if (installCallbacks) {
		        g_InstalledCallbacks = true;
		        g_PrevUserCallbackMousebutton = Glfw.SetMouseButtonCallback(window, new => ImGui_ImplGlfw_MouseButtonCallback, false);
		        g_PrevUserCallbackScroll = Glfw.SetScrollCallback(window, new => ImGui_ImplGlfw_ScrollCallback, false);
		        g_PrevUserCallbackKey = Glfw.SetKeyCallback(window, new => ImGui_ImplGlfw_KeyCallback, false);
		        g_PrevUserCallbackChar = Glfw.SetCharCallback(window, new => ImGui_ImplGlfw_CharCallback, false);
		    }

		    g_ClientApi = clientApi;
		    return true;
		}

		public static bool ImGui_ImplGlfw_InitForOpenGL(GlfwWindow* window, bool installCallbacks) {
			return ImGui_ImplGlfw_Init(window, installCallbacks, .GlfwClientApi_OpenGL);
		}

		public static bool ImGui_ImplGlfw_InitForVulkan(GlfwWindow* window, bool installCallbacks) {
			return ImGui_ImplGlfw_Init(window, installCallbacks, .GlfwClientApi_Vulkan);
		}

		public static void ImGui_ImplGlfw_Shutdown() {
			if (g_InstalledCallbacks) {
			    Glfw.SetMouseButtonCallback(g_Window, g_PrevUserCallbackMousebutton);
			    Glfw.SetScrollCallback(g_Window, g_PrevUserCallbackScroll);
			    Glfw.SetKeyCallback(g_Window, g_PrevUserCallbackKey);
			    Glfw.SetCharCallback(g_Window, g_PrevUserCallbackChar);
			    g_InstalledCallbacks = false;
			}

			for (ImGui.MouseCursor cursor_n = 0; cursor_n < ImGui.MouseCursor.COUNT; cursor_n++) {
			    Glfw.DestroyCursor(g_MouseCursors[(int) cursor_n]);
			    g_MouseCursors[(int) cursor_n] = null;
			}
			g_ClientApi = .GlfwClientApi_Unknown;
		}

		public static void ImGui_ImplGlfw_NewFrame() {
			ref ImGui.IO io = ref ImGui.GetIO();
			ImGui.ASSERT!(io.Fonts.IsBuilt(), "Font atlas not built! It is generally built by the renderer back-end. Missing call to renderer _NewFrame() function? e.g. ImGui_ImplOpenGL3_NewFrame().");

			// Setup display size (every frame to accommodate for window resizing)
			int w = 0;
			int h = 0;
			int display_w = 0;
			int display_h = 0;
			Glfw.GetWindowSize(g_Window, ref w, ref h);
			Glfw.GetFramebufferSize(g_Window, ref display_w, ref display_h);
			io.DisplaySize = ImGui.Vec2((float)w, (float)h);
			if (w > 0 && h > 0)
			    io.DisplayFramebufferScale = ImGui.Vec2((float)display_w / w, (float)display_h / h);

			// Setup time step
			double current_time = Glfw.GetTime();
			io.DeltaTime = g_Time > 0.0 ? (float)(current_time - g_Time) : (float)(1.0f/60.0f);
			g_Time = current_time;

			ImGui_ImplGlfw_UpdateMousePosAndButtons();
			ImGui_ImplGlfw_UpdateMouseCursor();

			// Update game controllers (if enabled and available)
			ImGui_ImplGlfw_UpdateGamepads();
		}

		private static void ImGui_ImplGlfw_UpdateMousePosAndButtons() {
		    // Update buttons
		    ref ImGui.IO io = ref ImGui.GetIO();
		    for (int i = 0; i < io.MouseDown.Count; i++) {
		        // If a mouse press event came, always pass it as "mouse held this frame", so we don't miss click-release events that are shorter than 1 frame.
		        io.MouseDown[i] = g_MouseJustPressed[i] || Glfw.GetMouseButton(g_Window, (.) i) != 0;
		        g_MouseJustPressed[i] = false;
		    }

		    // Update mouse position
		    ImGui.Vec2 mouse_pos_backup = io.MousePos;
		    io.MousePos = ImGui.Vec2(-Float.MaxValue, -Float.MaxValue);
#if __EMSCRIPTEN__
		    bool focused = true; // Emscripten
#else
		    bool focused = Glfw.GetWindowAttrib(g_Window, .Focused) != 0;
#endif
		    if (focused) {
		        if (io.WantSetMousePos) {
		            Glfw.SetCursorPos(g_Window, (double)mouse_pos_backup.x, (double)mouse_pos_backup.y);
		        }
		        else {
		            double mouse_x = 0;
					double mouse_y = 0;
		            Glfw.GetCursorPos(g_Window, ref mouse_x, ref mouse_y);
		            io.MousePos = ImGui.Vec2((float)mouse_x, (float)mouse_y);
		        }
		    }
		}

		private static void ImGui_ImplGlfw_UpdateMouseCursor() {
		    ref ImGui.IO io = ref ImGui.GetIO();
		    if ((io.ConfigFlags.HasFlag(.NoMouseCursorChange)) || Glfw.GetInputMode(g_Window, .Cursor) == GlfwInput.CursorInputMode.Disabled.Underlying)
		        return;

		    ImGui.MouseCursor imgui_cursor = ImGui.GetMouseCursor();
		    if (imgui_cursor == .None || io.MouseDrawCursor) {
		        // Hide OS mouse cursor if imgui is drawing it or if it wants no cursor
		        Glfw.SetInputMode(g_Window, .Cursor, GlfwInput.CursorInputMode.Hidded);
		    }
		    else {
		        // Show OS mouse cursor
		        // FIXME-PLATFORM: Unfocused windows seems to fail changing the mouse cursor with GLFW 3.2, but 3.3 works here.
		        Glfw.SetCursor(g_Window, g_MouseCursors[(int) imgui_cursor] != null ? g_MouseCursors[(int) imgui_cursor] : g_MouseCursors[ImGui.MouseCursor.Arrow.Underlying]);
		        Glfw.SetInputMode(g_Window, .Cursor, GlfwInput.CursorInputMode.Normal);
		    }
		}

		private static void ImGui_ImplGlfw_UpdateGamepads() {
		    ref ImGui.IO io = ref ImGui.GetIO();
			io.NavInputs = default;
		    if (!io.ConfigFlags.HasFlag(ImGui.ConfigFlags.NavEnableGamepad)) return;

		    // Update gamepad inputs
			int axes_count = 0, buttons_count = 0;
			float* axes = Glfw.GetJoystickAxes(GlfwInput.Joystick.Joystick1.Underlying, ref axes_count);	 
			GlfwInput.Action* buttons = Glfw.GetJoystickButtons(GlfwInput.Joystick.Joystick1.Underlying, ref buttons_count);

			mixin MAP_BUTTON(ImGui.NavInput NAV_NO, int BUTTON_NO) {
				if (buttons_count > BUTTON_NO && buttons[BUTTON_NO] == .Press) io.NavInputs[(int) NAV_NO] = 1.0f;
			}

			mixin MAP_ANALOG(ImGui.NavInput NAV_NO, int AXIS_NO, float V0, float V1) {
				float v = (axes_count > AXIS_NO) ? axes[AXIS_NO] : V0; v = (v - V0) / (V1 - V0);
				if (v > 1.0f) v = 1.0f;
				if (io.NavInputs[(int) NAV_NO] < v) io.NavInputs[(int) NAV_NO] = v;
			}

		    MAP_BUTTON!(ImGui.NavInput.Activate,   0);     // Cross / A
		    MAP_BUTTON!(ImGui.NavInput.Cancel,     1);     // Circle / B
		    MAP_BUTTON!(ImGui.NavInput.Menu,       2);     // Square / X
		    MAP_BUTTON!(ImGui.NavInput.Input,      3);     // Triangle / Y
		    MAP_BUTTON!(ImGui.NavInput.DpadLeft,   13);    // D-Pad Left
		    MAP_BUTTON!(ImGui.NavInput.DpadRight,  11);    // D-Pad Right
		    MAP_BUTTON!(ImGui.NavInput.DpadUp,     10);    // D-Pad Up
		    MAP_BUTTON!(ImGui.NavInput.DpadDown,   12);    // D-Pad Down
		    MAP_BUTTON!(ImGui.NavInput.FocusPrev,  4);     // L1 / LB
		    MAP_BUTTON!(ImGui.NavInput.FocusNext,  5);     // R1 / RB
		    MAP_BUTTON!(ImGui.NavInput.TweakSlow,  4);     // L1 / LB
		    MAP_BUTTON!(ImGui.NavInput.TweakFast,  5);     // R1 / RB
		    MAP_ANALOG!(ImGui.NavInput.LStickLeft, 0,  -0.3f,  -0.9f);
		    MAP_ANALOG!(ImGui.NavInput.LStickRight,0,  0.3f,  0.9f);
		    MAP_ANALOG!(ImGui.NavInput.LStickUp,   1,  0.3f,  0.9f); 
		    MAP_ANALOG!(ImGui.NavInput.LStickDown, 1,  -0.3f,  -0.9f);

		    if (axes_count > 0 && buttons_count > 0) io.BackendFlags |= ImGui.BackendFlags.HasGamepad;
		    else io.BackendFlags &= ~ImGui.BackendFlags.HasGamepad;
		}

		// GLFW callbacks
		// - When calling Init with 'installCallbacks=true': GLFW callbacks will be installed for you. They will call user's previously installed callbacks, if any.
		// - When calling Init with 'installCallbacks=false': GLFW callbacks won't be installed. You will need to call those function yourself from your own GLFW callbacks.

		public static void ImGui_ImplGlfw_MouseButtonCallback(GlfwWindow* window, GlfwInput.MouseButton button, GlfwInput.Action action, int mods) {
			if (g_PrevUserCallbackMousebutton != null)
			    g_PrevUserCallbackMousebutton(window, button, action, mods);

			if (action == .Press && button >= 0 && button.Underlying < g_MouseJustPressed.Count)
			    g_MouseJustPressed[button.Underlying] = true;				  
		}

		public static void ImGui_ImplGlfw_ScrollCallback(GlfwWindow* window, double xoffset, double yoffset) {
			if (g_PrevUserCallbackScroll != null)
			    g_PrevUserCallbackScroll(window, xoffset, yoffset);

			ref ImGui.IO io = ref ImGui.GetIO();
			io.MouseWheelH += (float) xoffset;
			io.MouseWheel += (float) yoffset;
		}

		public static void ImGui_ImplGlfw_KeyCallback(GlfwWindow* window, GlfwInput.Key key, int scancode, GlfwInput.Action action, int mods) {
			if (g_PrevUserCallbackKey != null)
			    g_PrevUserCallbackKey(window, key, scancode, action, mods);

			ref ImGui.IO io = ref ImGui.GetIO();
			if (action == .Press) io.KeysDown[key.Underlying] = true;
			if (action == .Release) io.KeysDown[key.Underlying] = false;	

			// Modifiers are not reliable across systems
			io.KeyCtrl = io.KeysDown[GlfwInput.Key.LeftControl.Underlying] || io.KeysDown[GlfwInput.Key.RightControl.Underlying];
			io.KeyShift = io.KeysDown[GlfwInput.Key.LeftShift.Underlying] || io.KeysDown[GlfwInput.Key.RightShift.Underlying];
			io.KeyAlt = io.KeysDown[GlfwInput.Key.LeftAlt.Underlying] || io.KeysDown[GlfwInput.Key.RightAlt.Underlying];
#if BF_PLATFORM_WINDOWS
			io.KeySuper = false;
#else
			io.KeySuper = io.KeysDown[GlfwInput.Key.LeftSuper.Underlying] || io.KeysDown[GlfwInput.Key.RightSuper.Underlying];
#endif
		}

		public static void ImGui_ImplGlfw_CharCallback(GlfwWindow* window, uint c) {
			if (g_PrevUserCallbackChar != null)
			    g_PrevUserCallbackChar(window, c);

			ref ImGui.IO io = ref ImGui.GetIO();
			io.AddInputCharacter(c);
		}
	}
}
