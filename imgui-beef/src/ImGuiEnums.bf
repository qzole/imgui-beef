using System;

namespace imgui_beef
{
	static extension ImGui
	{
		// A primary data type
		public enum DataType : int32
		{
			S8,       // signed char / char (with sensible compilers)
			U8,       // unsigned char
			S16,      // short
			U16,      // unsigned short
			S32,      // int
			U32,      // unsigned int
			S64,      // long long / __int64
			U64,      // unsigned long long / unsigned __int64
			Float,    // float
			Double,   // double
			COUNT
		};

		// A cardinal direction
		public enum Dir : int32
		{
			None    = -1,
			Left    = 0,
			Right   = 1,
			Up      = 2,
			Down    = 3,
			COUNT
		};

		// User fill ImGuiIO.KeyMap[] array with indices into the ImGuiIO.KeysDown[512] array
		public enum Key : int32
		{
			Tab,
			LeftArrow,
			RightArrow,
			UpArrow,
			DownArrow,
			PageUp,
			PageDown,
			Home,
			End,
			Insert,
			Delete,
			Backspace,
			Space,
			Enter,
			Escape,
			KeyPadEnter,
			A,                 // for text edit CTRL+A: select all
			C,                 // for text edit CTRL+C: copy
			V,                 // for text edit CTRL+V: paste
			X,                 // for text edit CTRL+X: cut
			Y,                 // for text edit CTRL+Y: redo
			Z,                 // for text edit CTRL+Z: undo
			COUNT
		};
		
		// Gamepad/Keyboard navigation
		// Keyboard: Set io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard to enable. NewFrame() will automatically fill io.NavInputs[] based on your io.KeysDown[] + io.KeyMap[] arrays.
		// Gamepad:  Set io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad to enable. Back-end: set ImGuiBackendFlags_HasGamepad and fill the io.NavInputs[] fields before calling NewFrame(). Note that io.NavInputs[] is cleared by EndFrame().
		// Read instructions in imgui.cpp for more details. Download PNG/PSD at http://goo.gl/9LgVZW.
		[AllowDuplicates]
		public enum NavInput
		{
			// Gamepad Mapping
			Activate,      // activate / open / toggle / tweak value       // e.g. Cross  (PS4), A (Xbox), A (Switch), Space (Keyboard)
			Cancel,        // cancel / close / exit                        // e.g. Circle (PS4), B (Xbox), B (Switch), Escape (Keyboard)
			Input,         // text input / on-screen keyboard              // e.g. Triang.(PS4), Y (Xbox), X (Switch), Return (Keyboard)
			Menu,          // tap: toggle menu / hold: focus, move, resize // e.g. Square (PS4), X (Xbox), Y (Switch), Alt (Keyboard)
			DpadLeft,      // move / tweak / resize window (w/ PadMenu)    // e.g. D-pad Left/Right/Up/Down (Gamepads), Arrow keys (Keyboard)
			DpadRight,     //
			DpadUp,        //
			DpadDown,      //
			LStickLeft,    // scroll / move window (w/ PadMenu)            // e.g. Left Analog Stick Left/Right/Up/Down
			LStickRight,   //
			LStickUp,      //
			LStickDown,    //
			FocusPrev,     // next window (w/ PadMenu)                     // e.g. L1 or L2 (PS4), LB or LT (Xbox), L or ZL (Switch)
			FocusNext,     // prev window (w/ PadMenu)                     // e.g. R1 or R2 (PS4), RB or RT (Xbox), R or ZL (Switch)
			TweakSlow,     // slower tweaks                                // e.g. L1 or L2 (PS4), LB or LT (Xbox), L or ZL (Switch)
			TweakFast,     // faster tweaks                                // e.g. R1 or R2 (PS4), RB or RT (Xbox), R or ZL (Switch)

			// [Internal] Don't use directly! This is used internally to differentiate keyboard from gamepad inputs for behaviors that require to differentiate them.
			// Keyboard behavior that have no corresponding gamepad mapping (e.g. CTRL+TAB) will be directly reading from io.KeysDown[] instead of io.NavInputs[].
			KeyMenu_,      // toggle menu                                  // = io.KeyAlt
			KeyLeft_,      // move left                                    // = Arrow keys
			KeyRight_,     // move right
			KeyUp_,        // move up
			KeyDown_,      // move down
			COUNT,
			InternalStart_ = KeyMenu_
		};

		// Enumeration for PushStyleColor() / PopStyleColor()
		public enum Col : int32
		{
			Text,
			TextDisabled,
			WindowBg,              // Background of normal windows
			ChildBg,               // Background of child windows
			PopupBg,               // Background of popups, menus, tooltips windows
			Border,
			BorderShadow,
			FrameBg,               // Background of checkbox, radio button, plot, slider, text input
			FrameBgHovered,
			FrameBgActive,
			TitleBg,
			TitleBgActive,
			TitleBgCollapsed,
			MenuBarBg,
			ScrollbarBg,
			ScrollbarGrab,
			ScrollbarGrabHovered,
			ScrollbarGrabActive,
			CheckMark,
			SliderGrab,
			SliderGrabActive,
			Button,
			ButtonHovered,
			ButtonActive,
			Header,                // Header* colors are used for CollapsingHeader, TreeNode, Selectable, MenuItem
			HeaderHovered,
			HeaderActive,
			Separator,
			SeparatorHovered,
			SeparatorActive,
			ResizeGrip,
			ResizeGripHovered,
			ResizeGripActive,
			Tab,
			TabHovered,
			TabActive,
			TabUnfocused,
			TabUnfocusedActive,
			PlotLines,
			PlotLinesHovered,
			PlotHistogram,
			PlotHistogramHovered,
			TextSelectedBg,
			DragDropTarget,
			NavHighlight,          // Gamepad/keyboard: current highlighted item
			NavWindowingHighlight, // Highlight window when using CTRL+TAB
			NavWindowingDimBg,     // Darken/colorize entire screen behind the CTRL+TAB window list, when active
			ModalWindowDimBg,      // Darken/colorize entire screen behind a modal window, when one is active
			COUNT
		};

		// Enumeration for PushStyleVar() / PopStyleVar() to temporarily modify the ImGuiStyle structure.
		// - The enum only refers to fields of ImGuiStyle which makes sense to be pushed/popped inside UI code.
		//   During initialization or between frames, feel free to just poke into ImGuiStyle directly.
		// - Tip: Use your programming IDE navigation facilities on the names in the _second column_ below to find the actual members and their description.
		//   In Visual Studio IDE: CTRL+comma ("Edit.NavigateTo") can follow symbols in comments, whereas CTRL+F12 ("Edit.GoToImplementation") cannot.
		//   With Visual Assist installed: ALT+G ("VAssistX.GoToImplementation") can also follow symbols in comments.
		// - When changing this enum, you need to update the associated internal table GStyleVarInfo[] accordingly. This is where we link enum values to members offset/type.
		public enum StyleVar : int32
		{
			// Enum name --------------------- // Member in ImGuiStyle structure (see ImGuiStyle for descriptions)
			Alpha,               // float     Alpha
			WindowPadding,       // ImVec2    WindowPadding
			WindowRounding,      // float     WindowRounding
			WindowBorderSize,    // float     WindowBorderSize
			WindowMinSize,       // ImVec2    WindowMinSize
			WindowTitleAlign,    // ImVec2    WindowTitleAlign
			ChildRounding,       // float     ChildRounding
			ChildBorderSize,     // float     ChildBorderSize
			PopupRounding,       // float     PopupRounding
			PopupBorderSize,     // float     PopupBorderSize
			FramePadding,        // ImVec2    FramePadding
			FrameRounding,       // float     FrameRounding
			FrameBorderSize,     // float     FrameBorderSize
			ItemSpacing,         // ImVec2    ItemSpacing
			ItemInnerSpacing,    // ImVec2    ItemInnerSpacing
			IndentSpacing,       // float     IndentSpacing
			ScrollbarSize,       // float     ScrollbarSize
			ScrollbarRounding,   // float     ScrollbarRounding
			GrabMinSize,         // float     GrabMinSize
			GrabRounding,        // float     GrabRounding
			TabRounding,         // float     TabRounding
			ButtonTextAlign,     // ImVec2    ButtonTextAlign
			SelectableTextAlign, // ImVec2    SelectableTextAlign
			COUNT
		};

		// Identify a mouse button.
		// Those values are guaranteed to be stable and we frequently use 0/1 directly. Named enums provided for convenience.
		public enum MouseButton : int32
		{
			Left = 0,
			Right = 1,
			Middle = 2,
			COUNT = 5
		};

		// Enumeration for GetMouseCursor()
		// User code may request binding to display given cursor by calling SetMouseCursor(), which is why we have some cursors that are marked unused here
		public enum MouseCursor : int32
		{
			None = -1,
			Arrow = 0,
			TextInput,         // When hovering over InputText, etc.
			ResizeAll,         // (Unused by Dear ImGui functions)
			ResizeNS,          // When hovering over an horizontal border
			ResizeEW,          // When hovering over a vertical border or a column
			ResizeNESW,        // When hovering over the bottom-left corner of a window
			ResizeNWSE,        // When hovering over the bottom-right corner of a window
			Hand,              // (Unused by Dear ImGui functions. Use for e.g. hyperlinks)
			NotAllowed,        // When hovering something with disallowed interaction. Usually a crossed circle.
			COUNT
		};

		// Enumeration for ImGui::SetWindow***(), SetNextWindow***(), SetNextItem***() functions
		// Represent a condition.
		// Important: Treat as a regular enum! Do NOT combine multiple values using binary operators! All the functions above treat 0 as a shortcut to Always.
		public enum Cond : int32
		{
			Always        = 1 << 0,   // Set the variable
			Once          = 1 << 1,   // Set the variable once per runtime session (only the first call with succeed)
			FirstUseEver  = 1 << 2,   // Set the variable if the object/window has no persistently saved data (no entry in .ini file)
			Appearing     = 1 << 3    // Set the variable if the object/window is appearing after being hidden/inactive (or the first time)
		};

	}
}
