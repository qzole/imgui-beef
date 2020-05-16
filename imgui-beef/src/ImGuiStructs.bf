using System;

namespace imgui_beef
{
	static extension ImGui
	{
		// TODO convert all these forward declarations to actual structs
		//public struct DrawChannel; // Temporary storage to output draw commands out of order, used by DrawListSplitter and DrawList::ChannelsSplit()
		//public struct DrawCmd; // A single draw command within a parent DrawList (generally maps to 1 GPU draw call, unless it is a callback)
		//public struct DrawData; // All draw command lists required to render the frame + pos/size coordinates to use for the projection matrix.
		//public struct DrawList; // A single draw command list (generally one per window, conceptually you may see this as a dynamic "mesh" builder)
		public struct DrawListSharedData; // Data shared among multiple draw lists (typically owned by parent ImGui context, but you may create one yourself)
		//public struct DrawListSplitter; // Helper to split a draw list into different layers which can be drawn into out of order, then flattened back.
		//public struct DrawVert; // A single vertex (pos + uv + col = 20 bytes by default. Override layout with IMGUI_OVERRIDE_DRAWVERT_STRUCT_LAYOUT)
		//public struct Font; // Runtime data for a single font within a parent FontAtlas
		//public struct FontAtlas; // Runtime data for multiple fonts, bake multiple fonts into a single texture, TTF/OTF font loader
		//public struct FontConfig; // Configuration data when adding a font or merging fonts
		//public struct FontGlyph; // A single font glyph (code point + coordinates within in FontAtlas + offset)
		public struct FontGlyphRangesBuilder; // Helper to build glyph ranges from text/string data
		public struct Color; // Helper functions to create a color that can be converted to either u32 or float4 (*OBSOLETE* please avoid using)
		public struct Context; // Dear ImGui context (opaque structure, unless including imgui_internal.h)
		//public struct IO; // Main configuration and I/O between your application and ImGui
		//public struct InputTextCallbackData; // Shared state of InputText() when using custom InputTextCallback (rare/advanced use)
		public struct ListClipper; // Helper to manually clip large list of items
		public struct OnceUponAFrame; // Helper for running a block of code not more than once a frame, used by IMGUI_ONCE_UPON_A_FRAME macro
		public struct Payload; // User data payload for drag and drop operations
		public struct SizeCallbackData; // Callback data when using SetNextWindowSizeConstraints() (rare/advanced use)
		public struct Storage; // Helper for key->value storage
		//public struct Style; // Runtime data for styling/colors
		public struct TextBuffer; // Helper to hold and append into a text buffer (~string builder)
		public struct TextFilter; // Helper to parse and apply text filters (e.g. "aaaaa[,bbbbb][,ccccc]")

		[CRepr]
		public struct Vec2
		{
			public float x, y;
			public this() { x = y = 0.0f; }
			public this(float _x, float _y) { x = _x; y = _y; }
			public static operator Vec2(float[2] v) { return .(v[0], v[1]); }
		};

		[CRepr]
		public struct Vec4
		{
			public float x, y, z, w;
			public this() { x = y = z = w = 0.0f; }
			public this(float _x, float _y, float _z, float _w) { x = _x; y = _y; z = _z; w = _w; }
			public static operator Vec4(float[4] v) { return .(v[0], v[1], v[2], v[3]); }
		};

		//-----------------------------------------------------------------------------
		// Helper: ImVector<>
		// Lightweight std::vector<>-like class to avoid dragging dependencies (also, some implementations of STL with debug enabled are absurdly slow, we bypass it so our code runs fast in debug).
		//-----------------------------------------------------------------------------
		// - You generally do NOT need to care or use this ever. But we need to make it available in imgui.h because some of our public structures are relying on it.
		// - We use std-like naming convention here, which is a little unusual for this codebase.
		// - Important: clear() frees memory, resize(0) keep the allocated buffer. We use resize(0) a lot to intentionally recycle allocated buffers across frames and amortize our costs.
		// - Important: our implementation does NOT call C++ constructors/destructors, we treat everything as raw data! This is intentional but be extra mindful of that,
		//   Do NOT use this class as a std::vector replacement in your own code! Many of the structures used by dear imgui can be safely initialized by a zero-memset.
		//-----------------------------------------------------------------------------

		[CRepr]
		public struct ImVector<T>
		{
			public int32 Size;
			public int32 Capacity;
			public T* Data;

			// No implementation for this struct, only the size matters, we don't directly manipulate these types of vectors from Beef side.
		}

		//-----------------------------------------------------------------------------
		// ImGuiStyle
		// You may modify the ImGui::GetStyle() main instance during initialization and before NewFrame().
		// During the frame, use ImGui::PushStyleVar(ImGuiStyleVar_XXXX)/PopStyleVar() to alter the main style values,
		// and ImGui::PushStyleColor(ImGuiCol_XXX)/PopStyleColor() for colors.
		//-----------------------------------------------------------------------------

		[CRepr]
		public struct Style
		{
			public float       Alpha;                      // Global alpha applies to everything in Dear ImGui.
			public Vec2        WindowPadding;              // Padding within a window.
			public float       WindowRounding;             // Radius of window corners rounding. Set to 0.0f to have rectangular windows.
			public float       WindowBorderSize;           // Thickness of border around windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
			public Vec2        WindowMinSize;              // Minimum window size. This is a global setting. If you want to constraint individual windows, use SetNextWindowSizeConstraints().
			public Vec2        WindowTitleAlign;           // Alignment for title bar text. Defaults to (0.0f,0.5f) for left-aligned,vertically centered.
			public Dir         WindowMenuButtonPosition;   // Side of the collapsing/docking button in the title bar (None/Left/Right). Defaults to ImGuiDir_Left.
			public float       ChildRounding;              // Radius of child window corners rounding. Set to 0.0f to have rectangular windows.
			public float       ChildBorderSize;            // Thickness of border around child windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
			public float       PopupRounding;              // Radius of popup window corners rounding. (Note that tooltip windows use WindowRounding)
			public float       PopupBorderSize;            // Thickness of border around popup/tooltip windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
			public Vec2        FramePadding;               // Padding within a framed rectangle (used by most widgets).
			public float       FrameRounding;              // Radius of frame corners rounding. Set to 0.0f to have rectangular frame (used by most widgets).
			public float       FrameBorderSize;            // Thickness of border around frames. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
			public Vec2        ItemSpacing;                // Horizontal and vertical spacing between widgets/lines.
			public Vec2        ItemInnerSpacing;           // Horizontal and vertical spacing between within elements of a composed widget (e.g. a slider and its label).
			public Vec2        TouchExtraPadding;          // Expand reactive bounding box for touch-based system where touch position is not accurate enough. Unfortunately we don't sort widgets so priority on overlap will always be given to the first widget. So don't grow this too much!
			public float       IndentSpacing;              // Horizontal indentation when e.g. entering a tree node. Generally == (FontSize + FramePadding.x*2).
			public float       ColumnsMinSpacing;          // Minimum horizontal spacing between two columns. Preferably > (FramePadding.x + 1).
			public float       ScrollbarSize;              // Width of the vertical scrollbar, Height of the horizontal scrollbar.
			public float       ScrollbarRounding;          // Radius of grab corners for scrollbar.
			public float       GrabMinSize;                // Minimum width/height of a grab box for slider/scrollbar.
			public float       GrabRounding;               // Radius of grabs corners rounding. Set to 0.0f to have rectangular slider grabs.
			public float       TabRounding;                // Radius of upper corners of a tab. Set to 0.0f to have rectangular tabs.
			public float       TabBorderSize;              // Thickness of border around tabs.
			public Dir         ColorButtonPosition;        // Side of the color button in the ColorEdit4 widget (left/right). Defaults to ImGuiDir_Right.
			public Vec2        ButtonTextAlign;            // Alignment of button text when button is larger than text. Defaults to (0.5f, 0.5f) (centered).
			public Vec2        SelectableTextAlign;        // Alignment of selectable text. Defaults to (0.0f, 0.0f) (top-left aligned). It's generally important to keep this left-aligned if you want to lay multiple items on a same line.
			public Vec2        DisplayWindowPadding;       // Window position are clamped to be visible within the display area by at least this amount. Only applies to regular windows.
			public Vec2        DisplaySafeAreaPadding;     // If you cannot see the edges of your screen (e.g. on a TV) increase the safe area padding. Apply to popups/tooltips as well regular windows. NB: Prefer configuring your TV sets correctly!
			public float       MouseCursorScale;           // Scale software rendered mouse cursor (when io.MouseDrawCursor is enabled). May be removed later.
			public bool        AntiAliasedLines;           // Enable anti-aliasing on lines/borders. Disable if you are really tight on CPU/GPU.
			public bool        AntiAliasedFill;            // Enable anti-aliasing on filled shapes (rounded rectangles, circles, etc.)
			public float       CurveTessellationTol;       // Tessellation tolerance when using PathBezierCurveTo() without a specific number of segments. Decrease for highly tessellated curves (higher quality, more polygons), increase to reduce quality.
			public float       CircleSegmentMaxError;      // Maximum error (in pixels) allowed when using AddCircle()/AddCircleFilled() or drawing rounded corner rectangles with no explicit segment count specified. Decrease for higher quality but more geometry.
			public Vec4[(.)Col.COUNT] Colors;

			public this()
			{
				Alpha                   = 1.0f;             // Global alpha applies to everything in ImGui
				WindowPadding           = .(8,8);      // Padding within a window
				WindowRounding          = 7.0f;             // Radius of window corners rounding. Set to 0.0f to have rectangular windows
				WindowBorderSize        = 1.0f;             // Thickness of border around windows. Generally set to 0.0f or 1.0f. Other values not well tested.
				WindowMinSize           = .(32,32);    // Minimum window size
				WindowTitleAlign        = .(0.0f,0.5f);// Alignment for title bar text
				WindowMenuButtonPosition= .Left;    // Position of the collapsing/docking button in the title bar (left/right). Defaults to ImGuiDir_Left.
				ChildRounding           = 0.0f;             // Radius of child window corners rounding. Set to 0.0f to have rectangular child windows
				ChildBorderSize         = 1.0f;             // Thickness of border around child windows. Generally set to 0.0f or 1.0f. Other values not well tested.
				PopupRounding           = 0.0f;             // Radius of popup window corners rounding. Set to 0.0f to have rectangular child windows
				PopupBorderSize         = 1.0f;             // Thickness of border around popup or tooltip windows. Generally set to 0.0f or 1.0f. Other values not well tested.
				FramePadding            = .(4,3);      // Padding within a framed rectangle (used by most widgets)
				FrameRounding           = 0.0f;             // Radius of frame corners rounding. Set to 0.0f to have rectangular frames (used by most widgets).
				FrameBorderSize         = 0.0f;             // Thickness of border around frames. Generally set to 0.0f or 1.0f. Other values not well tested.
				ItemSpacing             = .(8,4);      // Horizontal and vertical spacing between widgets/lines
				ItemInnerSpacing        = .(4,4);      // Horizontal and vertical spacing between within elements of a composed widget (e.g. a slider and its label)
				TouchExtraPadding       = .(0,0);      // Expand reactive bounding box for touch-based system where touch position is not accurate enough. Unfortunately we don't sort widgets so priority on overlap will always be given to the first widget. So don't grow this too much!
				IndentSpacing           = 21.0f;            // Horizontal spacing when e.g. entering a tree node. Generally == (FontSize + FramePadding.x*2).
				ColumnsMinSpacing       = 6.0f;             // Minimum horizontal spacing between two columns. Preferably > (FramePadding.x + 1).
				ScrollbarSize           = 14.0f;            // Width of the vertical scrollbar, Height of the horizontal scrollbar
				ScrollbarRounding       = 9.0f;             // Radius of grab corners rounding for scrollbar
				GrabMinSize             = 10.0f;            // Minimum width/height of a grab box for slider/scrollbar
				GrabRounding            = 0.0f;             // Radius of grabs corners rounding. Set to 0.0f to have rectangular slider grabs.
				TabRounding             = 4.0f;             // Radius of upper corners of a tab. Set to 0.0f to have rectangular tabs.
				TabBorderSize           = 0.0f;             // Thickness of border around tabs.
				ColorButtonPosition     = .Right;   // Side of the color button in the ColorEdit4 widget (left/right). Defaults to ImGuiDir_Right.
				ButtonTextAlign         = .(0.5f,0.5f);// Alignment of button text when button is larger than text.
				SelectableTextAlign     = .(0.0f,0.0f);// Alignment of selectable text. Defaults to (0.0f, 0.0f) (top-left aligned). It's generally important to keep this left-aligned if you want to lay multiple items on a same line.
				DisplayWindowPadding    = .(19,19);    // Window position are clamped to be visible within the display area or monitors by at least this amount. Only applies to regular windows.
				DisplaySafeAreaPadding  = .(3,3);      // If you cannot see the edge of your screen (e.g. on a TV) increase the safe area padding. Covers popups/tooltips as well regular windows.
				MouseCursorScale        = 1.0f;             // Scale software rendered mouse cursor (when io.MouseDrawCursor is enabled). May be removed later.
				AntiAliasedLines        = true;             // Enable anti-aliasing on lines/borders. Disable if you are really short on CPU/GPU.
				AntiAliasedFill         = true;             // Enable anti-aliasing on filled shapes (rounded rectangles, circles, etc.)
				CurveTessellationTol    = 1.25f;            // Tessellation tolerance when using PathBezierCurveTo() without a specific number of segments. Decrease for highly tessellated curves (higher quality, more polygons), increase to reduce quality.
				CircleSegmentMaxError   = 1.60f;            // Maximum error (in pixels) allowed when using AddCircle()/AddCircleFilled() or drawing rounded corner rectangles with no explicit segment count specified. Decrease for higher quality but more geometry.

				// Default theme
				StyleColorsDark(&this);
			}

			// To scale your entire UI (e.g. if you want your app to use High DPI or generally be DPI aware) you may use this helper function. Scaling the fonts is done separately and is up to you.
			// Important: This operation is lossy because we round all sizes to integer. If you need to change your scale multiples, call this over a freshly initialized ImGuiStyle structure rather than scaling multiple times.
			[LinkName("ImGuiStyle_ScaleAllSizes")]
			private static extern void ScaleAllSizesImpl(Style* self, float scale_factor);
			public void ScaleAllSizes(float scale_factor) mut { ScaleAllSizesImpl(&this, scale_factor); }
		};

		//-----------------------------------------------------------------------------
		// ImGuiIO
		// Communicate most settings and inputs/outputs to Dear ImGui using this structure.
		// Access via ImGui::GetIO(). Read 'Programmer guide' section in .cpp file for general usage.
		//-----------------------------------------------------------------------------

		[CRepr]
		public struct IO
		{
			//------------------------------------------------------------------
			// Configuration (fill once)                // Default value
			//------------------------------------------------------------------

			public ConfigFlags   ConfigFlags;                  // = 0              // See ImGuiConfigFlags_ enum. Set by user/application. Gamepad/keyboard navigation options, etc.
			public BackendFlags  BackendFlags;                 // = 0              // See ImGuiBackendFlags_ enum. Set by back-end (imgui_impl_xxx files or custom back-end) to communicate features supported by the back-end.
			public Vec2        DisplaySize;                    // <unset>          // Main display size, in pixels.
			public float       DeltaTime;                      // = 1.0f/60.0f     // Time elapsed since last frame, in seconds.
			public float       IniSavingRate;                  // = 5.0f           // Minimum time between saving positions/sizes to .ini file, in seconds.
			public char8*      IniFilename;                    // = "imgui.ini"    // Path to .ini file. Set NULL to disable automatic .ini loading/saving, if e.g. you want to manually load/save from memory.
			public char8*      LogFilename;                    // = "imgui_log.txt"// Path to .log file (default parameter to ImGui::LogToFile when no file is specified).
			public float       MouseDoubleClickTime;           // = 0.30f          // Time for a double-click, in seconds.
			public float       MouseDoubleClickMaxDist;        // = 6.0f           // Distance threshold to stay in to validate a double-click, in pixels.
			public float       MouseDragThreshold;             // = 6.0f           // Distance threshold before considering we are dragging.
			public int32[(.)Key.COUNT] KeyMap;                 // <unset>          // Map of indices into the KeysDown[512] entries array which represent your "native" keyboard state.
			public float       KeyRepeatDelay;                 // = 0.250f         // When holding a key/button, time before it starts repeating, in seconds (for buttons in Repeat mode, etc.).
			public float       KeyRepeatRate;                  // = 0.050f         // When holding a key/button, rate at which it repeats, in seconds.
			public void*       UserData;                       // = NULL           // Store your own data for retrieval by callbacks.

			public FontAtlas*  Fonts;                          // <auto>           // Font atlas: load, rasterize and pack one or more fonts into a single texture.
			public float       FontGlobalScale;                // = 1.0f           // Global scale all fonts
			public bool        FontAllowUserScaling;           // = false          // Allow user scaling text of individual window with CTRL+Wheel.
			public Font*       FontDefault;                    // = NULL           // Font to use on NewFrame(). Use NULL to uses Fonts->Fonts[0].
			public Vec2        DisplayFramebufferScale;        // = (1, 1)         // For retina display or other situations where window coordinates are different from framebuffer coordinates. This generally ends up in ImDrawData::FramebufferScale.

			// Miscellaneous options
			public bool        MouseDrawCursor;                // = false          // Request ImGui to draw a mouse cursor for you (if you are on a platform without a mouse cursor). Cannot be easily renamed to 'io.ConfigXXX' because this is frequently used by back-end implementations.
			public bool        ConfigMacOSXBehaviors;          // = defined(__APPLE__) // OS X style: Text editing cursor movement using Alt instead of Ctrl, Shortcuts using Cmd/Super instead of Ctrl, Line/Text Start and End using Cmd+Arrows instead of Home/End, Double click selects by word instead of selecting whole text, Multi-selection in lists uses Cmd/Super instead of Ctrl (was called io.OptMacOSXBehaviors prior to 1.63)
			public bool        ConfigInputTextCursorBlink;     // = true           // Set to false to disable blinking cursor, for users who consider it distracting. (was called: io.OptCursorBlink prior to 1.63)
			public bool        ConfigWindowsResizeFromEdges;   // = true           // Enable resizing of windows from their edges and from the lower-left corner. This requires (io.BackendFlags & ImGuiBackendFlags_HasMouseCursors) because it needs mouse cursor feedback. (This used to be a per-window ImGuiWindowFlags_ResizeFromAnySide flag)
			public bool        ConfigWindowsMoveFromTitleBarOnly; // = false       // [BETA] Set to true to only allow moving windows when clicked+dragged from the title bar. Windows without a title bar are not affected.
			public float       ConfigWindowsMemoryCompactTimer;// = 60.0f          // [BETA] Compact window memory usage when unused. Set to -1.0f to disable.

			//------------------------------------------------------------------
			// Platform Functions
			// (the imgui_impl_xxxx back-end files are setting those up for you)
			//------------------------------------------------------------------

			// Optional: Platform/Renderer back-end name (informational only! will be displayed in About Window) + User data for back-end/wrappers to store their own stuff.
			public char8*      BackendPlatformName;            // = NULL
			public char8*      BackendRendererName;            // = NULL
			public void*       BackendPlatformUserData;        // = NULL           // User data for platform back-end
			public void*       BackendRendererUserData;        // = NULL           // User data for renderer back-end
			public void*       BackendLanguageUserData;        // = NULL           // User data for non C++ programming language back-end

			// Optional: Access OS clipboard
			// (default to use native Win32 clipboard on Windows, otherwise uses a private clipboard. Override to access OS clipboard on other architectures)
			public function char8*(void* user_data) GetClipboardTextFn;
			public function void(void* user_data, char8* text) SetClipboardTextFn;
			public void*       ClipboardUserData;

			// Optional: Notify OS Input Method Editor of the screen position of your cursor for text input position (e.g. when using Japanese/Chinese IME on Windows)
			// (default to use native imm32 api on Windows)
			public function void(int x, int y) ImeSetInputScreenPosFn;
#if BF_PLATFORM_WINDOWS
			public Windows.HWnd ImeWindowHandle;               // = NULL           // (Windows) Set this to your HWND to get automatic IME cursor positioning.
#else
			public void*       ImeWindowHandle;                // = NULL           // (Windows) Set this to your HWND to get automatic IME cursor positioning.
#endif

			// This is only here to keep ImGuiIO the same size/layout, so that IMGUI_DISABLE_OBSOLETE_FUNCTIONS can exceptionally be used outside of imconfig.h.
			public void*       RenderDrawListsFnUnused;

			//------------------------------------------------------------------
			// Input - Fill before calling NewFrame()
			//------------------------------------------------------------------

			public Vec2        MousePos;                       // Mouse position, in pixels. Set to ImVec2(-FLT_MAX,-FLT_MAX) if mouse is unavailable (on another screen, etc.)
			public bool[5]     MouseDown;                      // Mouse buttons: 0=left, 1=right, 2=middle + extras. ImGui itself mostly only uses left button (BeginPopupContext** are using right button). Others buttons allows us to track if the mouse is being used by your application + available to user as a convenience via IsMouse** API.
			public float       MouseWheel;                     // Mouse wheel Vertical: 1 unit scrolls about 5 lines text.
			public float       MouseWheelH;                    // Mouse wheel Horizontal. Most users don't have a mouse with an horizontal wheel, may not be filled by all back-ends.
			public bool        KeyCtrl;                        // Keyboard modifier pressed: Control
			public bool        KeyShift;                       // Keyboard modifier pressed: Shift
			public bool        KeyAlt;                         // Keyboard modifier pressed: Alt
			public bool        KeySuper;                       // Keyboard modifier pressed: Cmd/Super/Windows
			public bool[512]   KeysDown;                       // Keyboard keys that are pressed (ideally left in the "native" order your engine has access to keyboard keys, so you can use your own defines/enums for keys).
			public float[(.)NavInput.COUNT] NavInputs;         // Gamepad inputs. Cleared back to zero by EndFrame(). Keyboard keys will be auto-mapped and be written here by NewFrame().

			// Functions
			[LinkName("ImGuiIO_AddInputCharacter")]
			private static extern void AddInputCharacterImpl(IO* self, uint c); // Queue new character input
			public void AddInputCharacter(uint c) mut { AddInputCharacterImpl(&this, c); }
			[LinkName("ImGuiIO_AddInputCharacterUTF16")]
			private static extern void AddInputCharacterUTF16Impl(IO* self, ImWchar16 c); // Queue new character input from an UTF-16 character, it can be a surrogate
			public void AddInputCharacterUTF16(ImWchar16 c) mut { AddInputCharacterUTF16Impl(&this, c); }
			[LinkName("ImGuiIO_AddInputCharactersUTF8")]
			private static extern void AddInputCharactersUTF8Impl(IO* self, char8* str); // Queue new characters input from an UTF-8 string
			public void AddInputCharactersUTF8(char8* str) mut { AddInputCharactersUTF8Impl(&this, str); }
			[LinkName("ImGuiIO_ClearInputCharacters")]
			private static extern void ClearInputCharactersImpl(IO* self); // Clear the text input buffer manually
			public void ClearInputCharacters() mut { ClearInputCharactersImpl(&this); }

			//------------------------------------------------------------------
			// Output - Updated by NewFrame() or EndFrame()/Render()
			// (when reading from the io.WantCaptureMouse, io.WantCaptureKeyboard flags to dispatch your inputs, it is
			//  generally easier and more correct to use their state BEFORE calling NewFrame(). See FAQ for details!)
			//------------------------------------------------------------------

			public bool        WantCaptureMouse;               // Set when Dear ImGui will use mouse inputs, in this case do not dispatch them to your main game/application (either way, always pass on mouse inputs to imgui). (e.g. unclicked mouse is hovering over an imgui window, widget is active, mouse was clicked over an imgui window, etc.).
			public bool        WantCaptureKeyboard;            // Set when Dear ImGui will use keyboard inputs, in this case do not dispatch them to your main game/application (either way, always pass keyboard inputs to imgui). (e.g. InputText active, or an imgui window is focused and navigation is enabled, etc.).
			public bool        WantTextInput;                  // Mobile/console: when set, you may display an on-screen keyboard. This is set by Dear ImGui when it wants textual keyboard input to happen (e.g. when a InputText widget is active).
			public bool        WantSetMousePos;                // MousePos has been altered, back-end should reposition mouse on next frame. Rarely used! Set only when ImGuiConfigFlags_NavEnableSetMousePos flag is enabled.
			public bool        WantSaveIniSettings;            // When manual .ini load/save is active (io.IniFilename == NULL), this will be set to notify your application that you can call SaveIniSettingsToMemory() and save yourself. Important: clear io.WantSaveIniSettings yourself after saving!
			public bool        NavActive;                      // Keyboard/Gamepad navigation is currently allowed (will handle ImGuiKey_NavXXX events) = a window is focused and it doesn't use the ImGuiWindowFlags_NoNavInputs flag.
			public bool        NavVisible;                     // Keyboard/Gamepad navigation is visible and allowed (will handle ImGuiKey_NavXXX events).
			public float       Framerate;                      // Application framerate estimate, in frame per second. Solely for convenience. Rolling average estimation based on io.DeltaTime over 120 frames.
			public int32       MetricsRenderVertices;          // Vertices output during last call to Render()
			public int32       MetricsRenderIndices;           // Indices output during last call to Render() = number of triangles * 3
			public int32       MetricsRenderWindows;           // Number of visible windows
			public int32       MetricsActiveWindows;           // Number of active windows
			public int32       MetricsActiveAllocations;       // Number of active allocations, updated by MemAlloc/MemFree based on current context. May be off if you have multiple imgui contexts.
			public Vec2        MouseDelta;                     // Mouse delta. Note that this is zero if either current or previous position are invalid (-FLT_MAX,-FLT_MAX), so a disappearing/reappearing mouse won't have a huge delta.

			//------------------------------------------------------------------
			// [Internal] Dear ImGui will maintain those fields. Forward compatibility not guaranteed!
			//------------------------------------------------------------------

			KeyModFlags KeyMods;                     // Key mods flags (same as io.KeyCtrl/KeyShift/KeyAlt/KeySuper but merged into flags), updated by NewFrame()
			Vec2        MousePosPrev;                // Previous mouse position (note that MouseDelta is not necessary == MousePos-MousePosPrev, in case either position is invalid)
			Vec2[5]     MouseClickedPos;             // Position at time of clicking
			double[5]   MouseClickedTime;            // Time of last click (used to figure out double-click)
			bool[5]     MouseClicked;                // Mouse button went from !Down to Down
			bool[5]     MouseDoubleClicked;          // Has mouse button been double-clicked?
			bool[5]     MouseReleased;               // Mouse button went from Down to !Down
			bool[5]     MouseDownOwned;              // Track if button was clicked inside a dear imgui window. We don't request mouse capture from the application if click started outside ImGui bounds.
			bool[5]     MouseDownWasDoubleClick;     // Track if button down was a double-click
			float[5]    MouseDownDuration;           // Duration the mouse button has been down (0.0f == just clicked)
			float[5]    MouseDownDurationPrev;       // Previous time the mouse button has been down
			Vec2[5]     MouseDragMaxDistanceAbs;     // Maximum distance, absolute, on each axis, of how much mouse has traveled from the clicking point
			float[5]    MouseDragMaxDistanceSqr;     // Squared maximum distance of how much mouse has traveled from the clicking point
			float[512]  KeysDownDuration;            // Duration the keyboard key has been down (0.0f == just pressed)
			float[512]  KeysDownDurationPrev;        // Previous duration the key has been down
			float[(.)NavInput.COUNT] NavInputsDownDuration;
			float[(.)NavInput.COUNT] NavInputsDownDurationPrev;
			ImWchar16   InputQueueSurrogate;            // For AddInputCharacterUTF16
			ImVector<ImWchar> InputQueueCharacters;     // Queue of _characters_ input (obtained by platform back-end). Fill using AddInputCharacter() helper.

			//IMGUI_API   ImGuiIO(); // TODO?
		};

		//-----------------------------------------------------------------------------
		// Misc data structures
		//-----------------------------------------------------------------------------

		// Shared state of InputText(), passed as an argument to your callback when a ImGuiInputTextFlags_Callback* flag is used.
		// The callback function should return 0 by default.
		// Callbacks (follow a flag name and see comments in ImGuiInputTextFlags_ declarations for more details)
		// - ImGuiInputTextFlags_CallbackCompletion:  Callback on pressing TAB
		// - ImGuiInputTextFlags_CallbackHistory:     Callback on pressing Up/Down arrows
		// - ImGuiInputTextFlags_CallbackAlways:      Callback on each iteration
		// - ImGuiInputTextFlags_CallbackCharFilter:  Callback on character inputs to replace or discard them. Modify 'EventChar' to replace or discard, or return 1 in callback to discard.
		// - ImGuiInputTextFlags_CallbackResize:      Callback on buffer capacity changes request (beyond 'buf_size' parameter value), allowing the string to grow.
		[CRepr]
		public struct InputTextCallbackData // Shared state of InputText() when using custom InputTextCallback (rare/advanced use)
		{
			public InputTextFlags      EventFlag;      // One ImGuiInputTextFlags_Callback*    // Read-only
			public InputTextFlags      Flags;          // What user passed to InputText()      // Read-only
			public void*               UserData;       // What user passed to InputText()      // Read-only

			// Arguments for the different callback events
			// - To modify the text buffer in a callback, prefer using the InsertChars() / DeleteChars() function. InsertChars() will take care of calling the resize callback if necessary.
			// - If you know your edits are not going to resize the underlying buffer allocation, you may modify the contents of 'Buf[]' directly. You need to update 'BufTextLen' accordingly (0 <= BufTextLen < BufSize) and set 'BufDirty'' to true so InputText can update its internal state.
			public ImWchar             EventChar;      // Character input                      // Read-write   // [CharFilter] Replace character with another one, or set to zero to drop. return 1 is equivalent to setting EventChar=0;
			public Key                 EventKey;       // Key pressed (Up/Down/TAB)            // Read-only    // [Completion,History]
			public char8*              Buf;            // Text buffer                          // Read-write   // [Resize] Can replace pointer / [Completion,History,Always] Only write to pointed data, don't replace the actual pointer!
			public int                 BufTextLen;     // Text length (in bytes)               // Read-write   // [Resize,Completion,History,Always] Exclude zero-terminator storage. In C land: == strlen(some_text), in C++ land: string.length()
			public int                 BufSize;        // Buffer size (in bytes) = capacity+1  // Read-only    // [Resize,Completion,History,Always] Include zero-terminator storage. In C land == ARRAYSIZE(my_char_array), in C++ land: string.capacity()+1
			public bool                BufDirty;       // Set if you modify Buf/BufTextLen!    // Write        // [Completion,History,Always]
			public int                 CursorPos;      //                                      // Read-write   // [Completion,History,Always]
			public int                 SelectionStart; //                                      // Read-write   // [Completion,History,Always] == to SelectionEnd when no selection)
			public int                 SelectionEnd;   //                                      // Read-write   // [Completion,History,Always]

			// Helper functions for text manipulation.
			// Use those function to benefit from the CallbackResize behaviors. Calling those function reset the selection.
			public this() { this = default; }

			// Public API to manipulate UTF-8 text
			// We expose UTF-8 to the user (unlike the STB_TEXTEDIT_* functions which are manipulating wchar)
			// FIXME: The existence of this rarely exercised code path is a bit of a nuisance.
			[LinkName("ImGuiInputTextCallbackData_DeleteChars")]
			private static extern void DeleteCharsImpl(InputTextCallbackData* self, int pos, int bytes_count);
			public void DeleteChars(int pos, int bytes_count) mut { DeleteCharsImpl(&this, pos, bytes_count); }
			[LinkName("ImGuiInputTextCallbackData_InsertChars")]
			private static extern void InsertCharsImpl(InputTextCallbackData* self, int pos, char8* text, char8* text_end = null);
			public void InsertChars(int pos, char8* text, char8* text_end = null) mut { InsertCharsImpl(&this, pos, text, text_end); }
			public bool HasSelection() { return SelectionStart != SelectionEnd; }
		}

		//-----------------------------------------------------------------------------
		// Helpers
		//-----------------------------------------------------------------------------

		// Helper: Unicode defines
		public const uint32 UNICODE_CODEPOINT_INVALID = 0xFFFD;     // Invalid Unicode code point (standard value).
#if IMGUI_USE_WCHAR32
		public const uint32 UNICODE_CODEPOINT_MAX     = 0x10FFFF;   // Maximum Unicode code point supported by this build.
#else
		public const uint32 UNICODE_CODEPOINT_MAX     = 0xFFFF;     // Maximum Unicode code point supported by this build.
#endif

		//-----------------------------------------------------------------------------
		// Draw List API (ImDrawCmd, ImDrawIdx, ImDrawVert, ImDrawChannel, ImDrawListSplitter, ImDrawListFlags, ImDrawList, ImDrawData)
		// Hold a series of drawing commands. The user provides a renderer for ImDrawData which essentially contains an array of ImDrawList.
		//-----------------------------------------------------------------------------

		// ImDrawCallback: Draw callbacks for advanced uses [configurable type: override in imconfig.h]
		// NB: You most likely do NOT need to use draw callbacks just to create your own widget or customized UI rendering,
		// you can poke into the draw list for that! Draw callback may be useful for example to:
		//  A) Change your GPU render state,
		//  B) render a complex 3D scene inside a UI element without an intermediate texture/render target, etc.
		// The expected behavior from your rendering function is 'if (cmd.UserCallback != NULL) { cmd.UserCallback(parent_list, cmd); } else { RenderTriangles() }'
		// If you want to override the signature of ImDrawCallback, you can simply use e.g. '#define ImDrawCallback MyDrawCallback' (in imconfig.h) + update rendering back-end accordingly.
#if ImDrawCallback
#else
		public typealias DrawCallback = function void(DrawList* parent_list, DrawCmd* cmd);
#endif

		// Special Draw callback value to request renderer back-end to reset the graphics/render state.
		// The renderer back-end needs to handle this special value, otherwise it will crash trying to call a function at this address.
		// This is useful for example if you submitted callbacks which you know have altered the render state and you want it to be restored.
		// It is not done by default because they are many perfectly useful way of altering render state for imgui contents (e.g. changing shader/blending settings before an Image call).
		public static DrawCallback* DrawCallback_ResetRenderState = (.)(void*)-1;

		// Typically, 1 command = 1 GPU draw call (unless command is a callback)
		// Pre 1.71 back-ends will typically ignore the VtxOffset/IdxOffset fields. When 'io.BackendFlags & ImGuiBackendFlags_RendererHasVtxOffset'
		// is enabled, those fields allow us to render meshes larger than 64K vertices while keeping 16-bit indices.
		[CRepr]
		public struct DrawCmd
		{
			public uint32        ElemCount;              // Number of indices (multiple of 3) to be rendered as triangles. Vertices are stored in the callee ImDrawList's vtx_buffer[] array, indices in idx_buffer[].
			public Vec4          ClipRect;               // Clipping rectangle (x1, y1, x2, y2). Subtract ImDrawData->DisplayPos to get clipping rectangle in "viewport" coordinates
			public TextureID     TextureId;              // User-provided texture ID. Set by user in ImfontAtlas::SetTexID() for fonts or passed to Image*() functions. Ignore if never using images or multiple fonts atlas.
			public uint32        VtxOffset;              // Start offset in vertex buffer. Pre-1.71 or without ImGuiBackendFlags_RendererHasVtxOffset: always 0. With ImGuiBackendFlags_RendererHasVtxOffset: may be >0 to support meshes larger than 64K vertices with 16-bit indices.
			public uint32        IdxOffset;              // Start offset in index buffer. Always equal to sum of ElemCount drawn so far.
			public DrawCallback  UserCallback;           // If != NULL, call the function instead of rendering the vertices. clip_rect and texture_id will be set normally.
			public void*         UserCallbackData;       // The draw callback code can access this.

			public this() { ElemCount = 0; ClipRect = default; TextureId = (.)null; VtxOffset = IdxOffset = 0;  UserCallback = null; UserCallbackData = null; }
		};

		// Vertex index, default to 16-bit
		// To allow large meshes with 16-bit indices: set 'io.BackendFlags |= ImGuiBackendFlags_RendererHasVtxOffset' and handle ImDrawCmd::VtxOffset in the renderer back-end (recommended).
		// To use 32-bit indices: override with '#define ImDrawIdx unsigned int' in imconfig.h.
#if ImDrawIdx
#else
		public typealias DrawIdx = uint16;
#endif

		// Vertex layout
#if IMGUI_OVERRIDE_DRAWVERT_STRUCT_LAYOUT
#else
		[CRepr]
		public struct DrawVert
		{
			public Vec2   pos;
			public Vec2   uv;
			public uint32 col;
		};
#endif

		// For use by ImDrawListSplitter.
		[CRepr]
		public struct DrawChannel
		{
			public ImVector<DrawCmd>         _CmdBuffer;
			public ImVector<DrawIdx>         _IdxBuffer;
		};

		// Split/Merge functions are used to split the draw list into different layers which can be drawn into out of order.
		// This is used by the Columns api, so items of each column can be batched together in a same draw call.
		[CRepr]
		public struct DrawListSplitter
		{
			public int                         _Current;    // Current channel number (0)
			public int                         _Count;      // Number of active channels (1+)
			public ImVector<DrawChannel>       _Channels;   // Draw channels (not resized down so _Count might be < Channels.Size)

			//inline DrawListSplitter()  { Clear(); }
			//inline ~ImDrawListSplitter() { ClearFreeMemory(); }
			//inline void                 Clear() { _Current = 0; _Count = 1; } // Do not clear Channels[] so our allocations are reused next frame
			//IMGUI_API void              ClearFreeMemory();
			//IMGUI_API void              Split(ImDrawList* draw_list, int count);
			//IMGUI_API void              Merge(ImDrawList* draw_list);
			//IMGUI_API void              SetCurrentChannel(ImDrawList* draw_list, int channel_idx);
		};

		// Draw command list
		// This is the low-level list of polygons that ImGui:: functions are filling. At the end of the frame,
		// all command lists are passed to your ImGuiIO::RenderDrawListFn function for rendering.
		// Each dear imgui window contains its own ImDrawList. You can use ImGui::GetWindowDrawList() to
		// access the current window draw list and draw custom primitives.
		// You can interleave normal ImGui:: calls and adding primitives to the current draw list.
		// All positions are generally in pixel coordinates (top-left at (0,0), bottom-right at io.DisplaySize), but you are totally free to apply whatever transformation matrix to want to the data (if you apply such transformation you'll want to apply it to ClipRect as well)
		// Important: Primitives are always added to the list and not culled (culling is done at higher-level by ImGui:: functions), if you use this API a lot consider coarse culling your drawn objects.
		[CRepr]
		public struct DrawList
		{
			// This is what you have to render
			public ImVector<DrawCmd>     CmdBuffer;          // Draw commands. Typically 1 command = 1 GPU draw call, unless the command is a callback.
			public ImVector<DrawIdx>     IdxBuffer;          // Index buffer. Each command consume ImDrawCmd::ElemCount of those
			public ImVector<DrawVert>    VtxBuffer;          // Vertex buffer.
			public DrawListFlags         Flags;              // Flags, you may poke into these to adjust anti-aliasing settings per-primitive.

			// [Internal, used while building lists]
			public readonly DrawListSharedData* _Data;         // Pointer to shared draw data (you can use ImGui::GetDrawListSharedData() to get the one from current ImGui context)
			public readonly char8*         _OwnerName;         // Pointer to owner window's name for debugging
			public uint32                  _VtxCurrentOffset;  // [Internal] Always 0 unless 'Flags & ImDrawListFlags_AllowVtxOffset'.
			public uint32                  _VtxCurrentIdx;     // [Internal] Generally == VtxBuffer.Size unless we are past 64K vertices, in which case this gets reset to 0.
			public DrawVert*               _VtxWritePtr;       // [Internal] point within VtxBuffer.Data after each add command (to avoid using the ImVector<> operators too much)
			public DrawIdx*                _IdxWritePtr;       // [Internal] point within IdxBuffer.Data after each add command (to avoid using the ImVector<> operators too much)
			public ImVector<Vec4>          _ClipRectStack;     // [Internal]
			public ImVector<TextureID>     _TextureIdStack;    // [Internal]
			public ImVector<Vec2>          _Path;              // [Internal] current path building
			public DrawListSplitter        _Splitter;          // [Internal] for channels api

			// If you want to create ImDrawList instances, pass them ImGui::GetDrawListSharedData() or create and use your own ImDrawListSharedData (so you can use ImDrawList without ImGui)
			//ImDrawList(const ImDrawListSharedData* shared_data) { _Data = shared_data; _OwnerName = NULL; Clear(); }
			//~ImDrawList() { ClearFreeMemory(); }
			//IMGUI_API void  PushClipRect(ImVec2 clip_rect_min, ImVec2 clip_rect_max, bool intersect_with_current_clip_rect = false);  // Render-level scissoring. This is passed down to your render function but not used for CPU-side coarse clipping. Prefer using higher-level ImGui::PushClipRect() to affect logic (hit-testing and widget culling)
			//IMGUI_API void  PushClipRectFullScreen();
			//IMGUI_API void  PopClipRect();
			//IMGUI_API void  PushTextureID(ImTextureID texture_id);
			//IMGUI_API void  PopTextureID();
			//inline ImVec2   GetClipRectMin() const { const ImVec4& cr = _ClipRectStack.back(); return ImVec2(cr.x, cr.y); }
			//inline ImVec2   GetClipRectMax() const { const ImVec4& cr = _ClipRectStack.back(); return ImVec2(cr.z, cr.w); }

			// Primitives
			// - For rectangular primitives, "p_min" and "p_max" represent the upper-left and lower-right corners.
			// - For circle primitives, use "num_segments == 0" to automatically calculate tessellation (preferred).
			//   In future versions we will use textures to provide cheaper and higher-quality circles.
			//   Use AddNgon() and AddNgonFilled() functions if you need to guaranteed a specific number of sides.
			//IMGUI_API void  AddLine(const ImVec2& p1, const ImVec2& p2, ImU32 col, float thickness = 1.0f);
			//IMGUI_API void  AddRect(const ImVec2& p_min, const ImVec2& p_max, ImU32 col, float rounding = 0.0f, ImDrawCornerFlags rounding_corners = ImDrawCornerFlags_All, float thickness = 1.0f);   // a: upper-left, b: lower-right (== upper-left + size), rounding_corners_flags: 4 bits corresponding to which corner to round
			//IMGUI_API void  AddRectFilled(const ImVec2& p_min, const ImVec2& p_max, ImU32 col, float rounding = 0.0f, ImDrawCornerFlags rounding_corners = ImDrawCornerFlags_All);                     // a: upper-left, b: lower-right (== upper-left + size)
			//IMGUI_API void  AddRectFilledMultiColor(const ImVec2& p_min, const ImVec2& p_max, ImU32 col_upr_left, ImU32 col_upr_right, ImU32 col_bot_right, ImU32 col_bot_left);
			//IMGUI_API void  AddQuad(const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, const ImVec2& p4, ImU32 col, float thickness = 1.0f);
			//IMGUI_API void  AddQuadFilled(const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, const ImVec2& p4, ImU32 col);
			//IMGUI_API void  AddTriangle(const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, ImU32 col, float thickness = 1.0f);
			//IMGUI_API void  AddTriangleFilled(const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, ImU32 col);
			//IMGUI_API void  AddCircle(const ImVec2& center, float radius, ImU32 col, int num_segments = 12, float thickness = 1.0f);
			//IMGUI_API void  AddCircleFilled(const ImVec2& center, float radius, ImU32 col, int num_segments = 12);
			//IMGUI_API void  AddNgon(const ImVec2& center, float radius, ImU32 col, int num_segments, float thickness = 1.0f);
			//IMGUI_API void  AddNgonFilled(const ImVec2& center, float radius, ImU32 col, int num_segments);
			//IMGUI_API void  AddText(const ImVec2& pos, ImU32 col, const char* text_begin, const char* text_end = NULL);
			//IMGUI_API void  AddText(const ImFont* font, float font_size, const ImVec2& pos, ImU32 col, const char* text_begin, const char* text_end = NULL, float wrap_width = 0.0f, const ImVec4* cpu_fine_clip_rect = NULL);
			//IMGUI_API void  AddPolyline(const ImVec2* points, int num_points, ImU32 col, bool closed, float thickness);
			//IMGUI_API void  AddConvexPolyFilled(const ImVec2* points, int num_points, ImU32 col); // Note: Anti-aliased filling requires points to be in clockwise order.
			//IMGUI_API void  AddBezierCurve(const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, const ImVec2& p4, ImU32 col, float thickness, int num_segments = 0);

			// Image primitives
			// - Read FAQ to understand what ImTextureID is.
			// - "p_min" and "p_max" represent the upper-left and lower-right corners of the rectangle.
			// - "uv_min" and "uv_max" represent the normalized texture coordinates to use for those corners. Using (0,0)->(1,1) texture coordinates will generally display the entire texture.
			//IMGUI_API void  AddImage(ImTextureID user_texture_id, const ImVec2& p_min, const ImVec2& p_max, const ImVec2& uv_min = ImVec2(0, 0), const ImVec2& uv_max = ImVec2(1, 1), ImU32 col = IM_COL32_WHITE);
			//IMGUI_API void  AddImageQuad(ImTextureID user_texture_id, const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, const ImVec2& p4, const ImVec2& uv1 = ImVec2(0, 0), const ImVec2& uv2 = ImVec2(1, 0), const ImVec2& uv3 = ImVec2(1, 1), const ImVec2& uv4 = ImVec2(0, 1), ImU32 col = IM_COL32_WHITE);
			//IMGUI_API void  AddImageRounded(ImTextureID user_texture_id, const ImVec2& p_min, const ImVec2& p_max, const ImVec2& uv_min, const ImVec2& uv_max, ImU32 col, float rounding, ImDrawCornerFlags rounding_corners = ImDrawCornerFlags_All);

			// Stateful path API, add points then finish with PathFillConvex() or PathStroke()
			//inline    void  PathClear()                                                 { _Path.Size = 0; }
			//inline    void  PathLineTo(const ImVec2& pos)                               { _Path.push_back(pos); }
			//inline    void  PathLineToMergeDuplicate(const ImVec2& pos)                 { if (_Path.Size == 0 || memcmp(&_Path.Data[_Path.Size-1], &pos, 8) != 0) _Path.push_back(pos); }
			//inline    void  PathFillConvex(ImU32 col)                                   { AddConvexPolyFilled(_Path.Data, _Path.Size, col); _Path.Size = 0; }  // Note: Anti-aliased filling requires points to be in clockwise order.
			//inline    void  PathStroke(ImU32 col, bool closed, float thickness = 1.0f)  { AddPolyline(_Path.Data, _Path.Size, col, closed, thickness); _Path.Size = 0; }
			//IMGUI_API void  PathArcTo(const ImVec2& center, float radius, float a_min, float a_max, int num_segments = 10);
			//IMGUI_API void  PathArcToFast(const ImVec2& center, float radius, int a_min_of_12, int a_max_of_12);                                            // Use precomputed angles for a 12 steps circle
			//IMGUI_API void  PathBezierCurveTo(const ImVec2& p2, const ImVec2& p3, const ImVec2& p4, int num_segments = 0);
			//IMGUI_API void  PathRect(const ImVec2& rect_min, const ImVec2& rect_max, float rounding = 0.0f, ImDrawCornerFlags rounding_corners = ImDrawCornerFlags_All);

			// Advanced
			//IMGUI_API void  AddCallback(ImDrawCallback callback, void* callback_data);  // Your rendering function must check for 'UserCallback' in ImDrawCmd and call the function instead of rendering triangles.
			//IMGUI_API void  AddDrawCmd();                                               // This is useful if you need to forcefully create a new draw call (to allow for dependent rendering / blending). Otherwise primitives are merged into the same draw-call as much as possible
			//IMGUI_API ImDrawList* CloneOutput() const;                                  // Create a clone of the CmdBuffer/IdxBuffer/VtxBuffer.

			// Advanced: Channels
			// - Use to split render into layers. By switching channels to can render out-of-order (e.g. submit FG primitives before BG primitives)
			// - Use to minimize draw calls (e.g. if going back-and-forth between multiple clipping rectangles, prefer to append into separate channels then merge at the end)
			// - FIXME-OBSOLETE: This API shouldn't have been in ImDrawList in the first place!
			//   Prefer using your own persistent copy of ImDrawListSplitter as you can stack them.
			//   Using the ImDrawList::ChannelsXXXX you cannot stack a split over another.
			//inline void     ChannelsSplit(int count)    { _Splitter.Split(this, count); }
			//inline void     ChannelsMerge()             { _Splitter.Merge(this); }
			//inline void     ChannelsSetCurrent(int n)   { _Splitter.SetCurrentChannel(this, n); }

			// Internal helpers
			// NB: all primitives needs to be reserved via PrimReserve() beforehand!
			//IMGUI_API void  Clear();
			//IMGUI_API void  ClearFreeMemory();
			//IMGUI_API void  PrimReserve(int idx_count, int vtx_count);
			//IMGUI_API void  PrimUnreserve(int idx_count, int vtx_count);
			//IMGUI_API void  PrimRect(const ImVec2& a, const ImVec2& b, ImU32 col);      // Axis aligned rectangle (composed of two triangles)
			//IMGUI_API void  PrimRectUV(const ImVec2& a, const ImVec2& b, const ImVec2& uv_a, const ImVec2& uv_b, ImU32 col);
			//IMGUI_API void  PrimQuadUV(const ImVec2& a, const ImVec2& b, const ImVec2& c, const ImVec2& d, const ImVec2& uv_a, const ImVec2& uv_b, const ImVec2& uv_c, const ImVec2& uv_d, ImU32 col);
			//inline    void  PrimWriteVtx(const ImVec2& pos, const ImVec2& uv, ImU32 col){ _VtxWritePtr->pos = pos; _VtxWritePtr->uv = uv; _VtxWritePtr->col = col; _VtxWritePtr++; _VtxCurrentIdx++; }
			//inline    void  PrimWriteIdx(ImDrawIdx idx)                                 { *_IdxWritePtr = idx; _IdxWritePtr++; }
			//inline    void  PrimVtx(const ImVec2& pos, const ImVec2& uv, ImU32 col)     { PrimWriteIdx((ImDrawIdx)_VtxCurrentIdx); PrimWriteVtx(pos, uv, col); }
			//IMGUI_API void  UpdateClipRect();
			//IMGUI_API void  UpdateTextureID();
		};

		// All draw data to render a Dear ImGui frame
		// (NB: the style and the naming convention here is a little inconsistent, we currently preserve them for backward compatibility purpose,
		// as this is one of the oldest structure exposed by the library! Basically, ImDrawList == CmdList)
		[CRepr]
		public struct DrawData
		{
			public bool            Valid;                  // Only valid after Render() is called and before the next NewFrame() is called.
			public DrawList**      CmdLists;               // Array of ImDrawList* to render. The ImDrawList are owned by ImGuiContext and only pointed to from here.
			public int32           CmdListsCount;          // Number of ImDrawList* to render
			public int32           TotalIdxCount;          // For convenience, sum of all ImDrawList's IdxBuffer.Size
			public int32           TotalVtxCount;          // For convenience, sum of all ImDrawList's VtxBuffer.Size
			public Vec2            DisplayPos;             // Upper-left position of the viewport to render (== upper-left of the orthogonal projection matrix to use)
			public Vec2            DisplaySize;            // Size of the viewport to render (== io.DisplaySize for the main viewport) (DisplayPos + DisplaySize == lower-right of the orthogonal projection matrix to use)
			public Vec2            FramebufferScale;       // Amount of pixels for each unit of DisplaySize. Based on io.DisplayFramebufferScale. Generally (1,1) on normal display, (2,2) on OSX with Retina display.

			// Functions
			//ImDrawData()    { Valid = false; Clear(); }
			//~ImDrawData()   { Clear(); }
			//void Clear()    { Valid = false; CmdLists = NULL; CmdListsCount = TotalVtxCount = TotalIdxCount = 0; DisplayPos = DisplaySize = FramebufferScale = ImVec2(0.f, 0.f); } // The ImDrawList are owned by ImGuiContext!
			//IMGUI_API void  DeIndexAllBuffers();                    // Helper to convert all buffers from indexed to non-indexed, in case you cannot render indexed. Note: this is slow and most likely a waste of resources. Always prefer indexed rendering!
			//IMGUI_API void  ScaleClipRects(const ImVec2& fb_scale); // Helper to scale the ClipRect field of each ImDrawCmd. Use if your final output buffer is at a different scale than Dear ImGui expects, or if there is a difference between your window resolution and framebuffer resolution.
		};

		//-----------------------------------------------------------------------------
		// Font API (ImFontConfig, ImFontGlyph, ImFontAtlasFlags, ImFontAtlas, ImFontGlyphRangesBuilder, ImFont)
		//-----------------------------------------------------------------------------

		[CRepr]
		public struct FontConfig
		{
			void*           FontData;               //          // TTF/OTF data
			int32           FontDataSize;           //          // TTF/OTF data size
			bool            FontDataOwnedByAtlas;   // true     // TTF/OTF data ownership taken by the container ImFontAtlas (will delete memory itself).
			int32           FontNo;                 // 0        // Index of font within TTF/OTF file
			float           SizePixels;             //          // Size in pixels for rasterizer (more or less maps to the resulting font height).
			int32           OversampleH;            // 3        // Rasterize at higher quality for sub-pixel positioning. Read https://github.com/nothings/stb/blob/master/tests/oversample/README.md for details.
			int32           OversampleV;            // 1        // Rasterize at higher quality for sub-pixel positioning. We don't use sub-pixel positions on the Y axis.
			bool            PixelSnapH;             // false    // Align every glyph to pixel boundary. Useful e.g. if you are merging a non-pixel aligned font with the default font. If enabled, you can set OversampleH/V to 1.
			Vec2            GlyphExtraSpacing;      // 0, 0     // Extra spacing (in pixels) between glyphs. Only X axis is supported for now.
			Vec2            GlyphOffset;            // 0, 0     // Offset all glyphs from this font input.
			ImWchar*        GlyphRanges;            // NULL     // Pointer to a user-provided list of Unicode range (2 value per range, values are inclusive, zero-terminated list). THE ARRAY DATA NEEDS TO PERSIST AS LONG AS THE FONT IS ALIVE.
			float           GlyphMinAdvanceX;       // 0        // Minimum AdvanceX for glyphs, set Min to align font icons, set both Min/Max to enforce mono-space font
			float           GlyphMaxAdvanceX;       // FLT_MAX  // Maximum AdvanceX for glyphs
			bool            MergeMode;              // false    // Merge into previous ImFont, so you can combine multiple inputs font into one ImFont (e.g. ASCII font + icons + Japanese glyphs). You may want to use GlyphOffset.y when merge font of different heights.
			uint32          RasterizerFlags;        // 0x00     // Settings for custom font rasterizer (e.g. ImGuiFreeType). Leave as zero if you aren't using one.
			float           RasterizerMultiply;     // 1.0f     // Brighten (>1.0f) or darken (<1.0f) font output. Brightening small fonts may be a good workaround to make them more readable.
			ImWchar         EllipsisChar;           // -1       // Explicitly specify unicode codepoint of ellipsis character. When fonts are being merged first specified ellipsis will be used.

			// [Internal]
			char8[40]       Name;                   // Name (strictly to ease debugging)
			Font*           DstFont;

			public this()
			{
				FontData = null;
				FontDataSize = 0;
				FontDataOwnedByAtlas = true;
				FontNo = 0;
				SizePixels = 0.0f;
				OversampleH = 3; // FIXME: 2 may be a better default?
				OversampleV = 1;
				PixelSnapH = false;
				GlyphExtraSpacing = Vec2(0.0f, 0.0f);
				GlyphOffset = Vec2(0.0f, 0.0f);
				GlyphRanges = null;
				GlyphMinAdvanceX = 0.0f;
				GlyphMaxAdvanceX = Float.MaxValue;
				MergeMode = false;
				RasterizerFlags = 0x00;
				RasterizerMultiply = 1.0f;
				EllipsisChar = (ImWchar)-1;
				Name = default;
				DstFont = null;
			}
		};

		// Hold rendering data for one glyph.
		// (Note: some language parsers may fail to convert the 31+1 bitfield members, in this case maybe drop store a single u32 or we can rework this)
		[CRepr]
		public struct FontGlyph
		{
			// FIXME shift! Codepoint : 31, Visible : 1
			public uint32 Codepoint // 0x0000..0xFFFF
			{
				get { return codepointVisible; }
				set mut { codepointVisible = value;  }
			}
			public uint32 Visible // Flag to allow early out when rendering
			{
				get { return codepointVisible; }
				set mut { codepointVisible = value;  }
			}
			private uint32 codepointVisible;
			float           AdvanceX;           // Distance to next character (= data from font + ImFontConfig::GlyphExtraSpacing.x baked in)
			float           X0, Y0, X1, Y1;     // Glyph corners
			float           U0, V0, U1, V1;     // Texture coordinates
		};

		// See ImFontAtlas::AddCustomRectXXX functions.
		[CRepr]
		public struct FontAtlasCustomRect
		{
			uint32          ID;             // Input    // User ID. Use < 0x110000 to map into a font glyph, >= 0x110000 for other/internal/custom texture data.
			uint16          Width, Height;  // Input    // Desired rectangle dimension
			uint16          X, Y;           // Output   // Packed position in Atlas
			float           GlyphAdvanceX;  // Input    // For custom font glyphs only (ID < 0x110000): glyph xadvance
			Vec2            GlyphOffset;    // Input    // For custom font glyphs only (ID < 0x110000): glyph display offset
			Font*           Font;           // Input    // For custom font glyphs only (ID < 0x110000): target font
			this()          { ID = 0xFFFFFFFF; Width = Height = 0; X = Y = 0xFFFF; GlyphAdvanceX = 0.0f; GlyphOffset = .(0,0); Font = null; }
			bool IsPacked() { return X != 0xFFFF; }
		};

		// Load and rasterize multiple TTF/OTF fonts into a same texture. The font atlas will build a single texture holding:
		//  - One or more fonts.
		//  - Custom graphics data needed to render the shapes needed by Dear ImGui.
		//  - Mouse cursor shapes for software cursor rendering (unless setting 'Flags |= ImFontAtlasFlags_NoMouseCursors' in the font atlas).
		// It is the user-code responsibility to setup/build the atlas, then upload the pixel data into a texture accessible by your graphics api.
		//  - Optionally, call any of the AddFont*** functions. If you don't call any, the default font embedded in the code will be loaded for you.
		//  - Call GetTexDataAsAlpha8() or GetTexDataAsRGBA32() to build and retrieve pixels data.
		//  - Upload the pixels data into a texture within your graphics system (see imgui_impl_xxxx.cpp examples)
		//  - Call SetTexID(my_tex_id); and pass the pointer/identifier to your texture in a format natural to your graphics API.
		//    This value will be passed back to you during rendering to identify the texture. Read FAQ entry about ImTextureID for more details.
		// Common pitfalls:
		// - If you pass a 'glyph_ranges' array to AddFont*** functions, you need to make sure that your array persist up until the
		//   atlas is build (when calling GetTexData*** or Build()). We only copy the pointer, not the data.
		// - Important: By default, AddFontFromMemoryTTF() takes ownership of the data. Even though we are not writing to it, we will free the pointer on destruction.
		//   You can set font_cfg->FontDataOwnedByAtlas=false to keep ownership of your data and it won't be freed,
		// - Even though many functions are suffixed with "TTF", OTF data is supported just as well.
		// - This is an old API and it is currently awkward for those and and various other reasons! We will address them in the future!
		[CRepr]
		public struct FontAtlas // TODO finish rest of FontAtlas
		{
			//IMGUI_API ImFontAtlas();
			//IMGUI_API ~ImFontAtlas();
			//IMGUI_API ImFont*           AddFont(const ImFontConfig* font_cfg);
			//IMGUI_API ImFont*           AddFontDefault(const ImFontConfig* font_cfg = NULL);
			//IMGUI_API ImFont*           AddFontFromFileTTF(const char* filename, float size_pixels, const ImFontConfig* font_cfg = NULL, const ImWchar* glyph_ranges = NULL);
			//IMGUI_API ImFont*           AddFontFromMemoryTTF(void* font_data, int font_size, float size_pixels, const ImFontConfig* font_cfg = NULL, const ImWchar* glyph_ranges = NULL); // Note: Transfer ownership of 'ttf_data' to ImFontAtlas! Will be deleted after destruction of the atlas. Set font_cfg->FontDataOwnedByAtlas=false to keep ownership of your data and it won't be freed.
			//IMGUI_API ImFont*           AddFontFromMemoryCompressedTTF(const void* compressed_font_data, int compressed_font_size, float size_pixels, const ImFontConfig* font_cfg = NULL, const ImWchar* glyph_ranges = NULL); // 'compressed_font_data' still owned by caller. Compress with binary_to_compressed_c.cpp.
			//IMGUI_API ImFont*           AddFontFromMemoryCompressedBase85TTF(const char* compressed_font_data_base85, float size_pixels, const ImFontConfig* font_cfg = NULL, const ImWchar* glyph_ranges = NULL);              // 'compressed_font_data_base85' still owned by caller. Compress with binary_to_compressed_c.cpp with -base85 parameter.
			//IMGUI_API void              ClearInputData();           // Clear input data (all ImFontConfig structures including sizes, TTF data, glyph ranges, etc.) = all the data used to build the texture and fonts.
			//IMGUI_API void              ClearTexData();             // Clear output texture data (CPU side). Saves RAM once the texture has been copied to graphics memory.
			//IMGUI_API void              ClearFonts();               // Clear output font data (glyphs storage, UV coordinates).
			//IMGUI_API void              Clear();                    // Clear all input and output.

			// Build atlas, retrieve pixel data.
			// User is in charge of copying the pixels into graphics memory (e.g. create a texture with your engine). Then store your texture handle with SetTexID().
			// The pitch is always = Width * BytesPerPixels (1 or 4)
			// Building in RGBA32 format is provided for convenience and compatibility, but note that unless you manually manipulate or copy color data into
			// the texture (e.g. when using the AddCustomRect*** api), then the RGB pixels emitted will always be white (~75% of memory/bandwidth waste.
			//IMGUI_API bool              Build();                    // Build pixels data. This is called automatically for you by the GetTexData*** functions.
			//IMGUI_API void              GetTexDataAsAlpha8(unsigned char** out_pixels, int* out_width, int* out_height, int* out_bytes_per_pixel = NULL);  // 1 byte per-pixel
			[LinkName("ImFontAtlas_GetTexDataAsRGBA32")]
			private static extern void  GetTexDataAsRGBA32Impl(FontAtlas* self, uint8** out_pixels, int32* out_width, int32* out_height, int32* out_bytes_per_pixel = null);  // 4 bytes-per-pixel
			public void              	GetTexDataAsRGBA32(out uint8* out_pixels, out int32 out_width, out int32 out_height, int32* out_bytes_per_pixel = null) mut
			{
				out_pixels = ?; out_width = ?; out_height = ?;
				GetTexDataAsRGBA32Impl(&this, &out_pixels, &out_width, &out_height, out_bytes_per_pixel);
			}
			public bool                        IsBuilt()                   { return Fonts.Size > 0 && (TexPixelsAlpha8 != null || TexPixelsRGBA32 != null); }
			public void                        SetTexID(TextureID id) mut  { TexID = id; }

			//-------------------------------------------
			// Glyph Ranges
			//-------------------------------------------

			// Helpers to retrieve list of common Unicode ranges (2 value per range, values are inclusive, zero-terminated list)
			// NB: Make sure that your string are UTF-8 and NOT in your local code page. In C++11, you can create UTF-8 string literal using the u8"Hello world" syntax. See FAQ for details.
			// NB: Consider using ImFontGlyphRangesBuilder to build glyph ranges from textual data.
			//IMGUI_API const ImWchar*    GetGlyphRangesDefault();                // Basic Latin, Extended Latin
			//IMGUI_API const ImWchar*    GetGlyphRangesKorean();                 // Default + Korean characters
			//IMGUI_API const ImWchar*    GetGlyphRangesJapanese();               // Default + Hiragana, Katakana, Half-Width, Selection of 1946 Ideographs
			//IMGUI_API const ImWchar*    GetGlyphRangesChineseFull();            // Default + Half-Width + Japanese Hiragana/Katakana + full set of about 21000 CJK Unified Ideographs
			//IMGUI_API const ImWchar*    GetGlyphRangesChineseSimplifiedCommon();// Default + Half-Width + Japanese Hiragana/Katakana + set of 2500 CJK Unified Ideographs for common simplified Chinese
			//IMGUI_API const ImWchar*    GetGlyphRangesCyrillic();               // Default + about 400 Cyrillic characters
			//IMGUI_API const ImWchar*    GetGlyphRangesThai();                   // Default + Thai characters
			//IMGUI_API const ImWchar*    GetGlyphRangesVietnamese();             // Default + Vietnamese characters

			//-------------------------------------------
			// [BETA] Custom Rectangles/Glyphs API
			//-------------------------------------------

			// You can request arbitrary rectangles to be packed into the atlas, for your own purposes.
			// After calling Build(), you can query the rectangle position and render your pixels.
			// You can also request your rectangles to be mapped as font glyph (given a font + Unicode point),
			// so you can render e.g. custom colorful icons and use them as regular glyphs.
			// Read docs/FONTS.txt for more details about using colorful icons.
			//IMGUI_API int               AddCustomRectRegular(unsigned int id, int width, int height);                                                                   // Id needs to be >= 0x110000. Id >= 0x80000000 are reserved for ImGui and ImDrawList
			//IMGUI_API int               AddCustomRectFontGlyph(ImFont* font, ImWchar id, int width, int height, float advance_x, const ImVec2& offset = ImVec2(0,0));   // Id needs to be < 0x110000 to register a rectangle to map into a specific font.
			public FontAtlasCustomRect* GetCustomRectByIndex(int index) { if (index < 0) return null; return &CustomRects.Data[index]; }

			// [Internal]
			//IMGUI_API void              CalcCustomRectUV(const ImFontAtlasCustomRect* rect, ImVec2* out_uv_min, ImVec2* out_uv_max) const;
			//IMGUI_API bool              GetMouseCursorTexData(ImGuiMouseCursor cursor, ImVec2* out_offset, ImVec2* out_size, ImVec2 out_uv_border[2], ImVec2 out_uv_fill[2]);

			//-------------------------------------------
			// Members
			//-------------------------------------------

			public bool                        Locked;             // Marked as Locked by ImGui::NewFrame() so attempt to modify the atlas will assert.
			public FontAtlasFlags              Flags;              // Build flags (see ImFontAtlasFlags_)
			public TextureID                   TexID;              // User data to refer to the texture once it has been uploaded to user's graphic systems. It is passed back to you during rendering via the ImDrawCmd structure.
			public int32                       TexDesiredWidth;    // Texture width desired by user before Build(). Must be a power-of-two. If have many glyphs your graphics API have texture size restrictions you may want to increase texture width to decrease height.
			public int32                       TexGlyphPadding;    // Padding between glyphs within texture in pixels. Defaults to 1. If your rendering method doesn't rely on bilinear filtering you may set this to 0.

			// [Internal]
			// NB: Access texture data via GetTexData*() calls! Which will setup a default font for you.
			public uint8*                      TexPixelsAlpha8;    // 1 component per pixel, each component is unsigned 8-bit. Total size = TexWidth * TexHeight
			public uint32*                     TexPixelsRGBA32;    // 4 component per pixel, each component is unsigned 8-bit. Total size = TexWidth * TexHeight * 4
			public int32                       TexWidth;           // Texture width calculated during Build().
			public int32                       TexHeight;          // Texture height calculated during Build().
			public Vec2                        TexUvScale;         // = (1.0f/TexWidth, 1.0f/TexHeight)
			public Vec2                        TexUvWhitePixel;    // Texture coordinates to a white pixel
			public ImVector<Font*>             Fonts;              // Hold all the fonts returned by AddFont*. Fonts[0] is the default font upon calling ImGui::NewFrame(), use ImGui::PushFont()/PopFont() to change the current font.
			public ImVector<FontAtlasCustomRect> CustomRects;      // Rectangles for packing custom texture data into the atlas.
			public ImVector<FontConfig>        ConfigData;         // Internal data
			public int32[1]                    CustomRectIds;      // Identifiers of custom texture rectangle used by ImFontAtlas/ImDrawList
		};

		// Font runtime data and rendering
		// ImFontAtlas automatically loads a default embedded font for you when you call GetTexDataAsAlpha8() or GetTexDataAsRGBA32().
		[CRepr]
		public struct Font
		{
			// Members: Hot ~20/24 bytes (for CalcTextSize)
			public ImVector<float>             IndexAdvanceX;      // 12-16 // out //            // Sparse. Glyphs->AdvanceX in a directly indexable way (cache-friendly for CalcTextSize functions which only this this info, and are often bottleneck in large UI).
			public float                       FallbackAdvanceX;   // 4     // out // = FallbackGlyph->AdvanceX
			public float                       FontSize;           // 4     // in  //            // Height of characters/line, set during loading (don't change after loading)

			// Members: Hot ~36/48 bytes (for CalcTextSize + render loop)
			public ImVector<ImWchar>           IndexLookup;        // 12-16 // out //            // Sparse. Index glyphs by Unicode code-point.
			public ImVector<FontGlyph>         Glyphs;             // 12-16 // out //            // All glyphs.
			public FontGlyph*                  FallbackGlyph;      // 4-8   // out // = FindGlyph(FontFallbackChar)
			public Vec2                        DisplayOffset;      // 8     // in  // = (0,0)    // Offset font rendering by xx pixels

			// Members: Cold ~32/40 bytes
			public FontAtlas*                  ContainerAtlas;     // 4-8   // out //            // What we has been loaded into
			public readonly FontConfig*        ConfigData;         // 4-8   // in  //            // Pointer within ContainerAtlas->ConfigData
			public uint16                      ConfigDataCount;    // 2     // in  // ~ 1        // Number of ImFontConfig involved in creating this font. Bigger than 1 when merging multiple font sources into one ImFont.
			public ImWchar                     FallbackChar;       // 2     // in  // = '?'      // Replacement character if a glyph isn't found. Only set via SetFallbackChar()
			public ImWchar                     EllipsisChar;       // 2     // out // = -1       // Character used for ellipsis rendering.
			public bool                        DirtyLookupTables;  // 1     // out //
			public float                       Scale;              // 4     // in  // = 1.f      // Base font scale, multiplied by the per-window font scale which you can adjust with SetWindowFontScale()
			public float                       Ascent, Descent;    // 4+4   // out //            // Ascent: distance from top to bottom of e.g. 'A' [0..FontSize]
			public int32                       MetricsTotalSurface;// 4     // out //            // Total surface in pixels to get an idea of the font rasterization/texture cost (not exact, we approximate the cost of padding between glyphs)
			public uint8[(UNICODE_CODEPOINT_MAX+1)/4096/8] Used4kPagesMap; // 2 bytes if ImWchar=ImWchar16, 34 bytes if ImWchar==ImWchar32. Store 1-bit for each block of 4K codepoints that has one active glyph. This is mainly used to facilitate iterations accross all used codepoints.

			// Methods
			//IMGUI_API ImFont();
			//IMGUI_API ~ImFont();
			//IMGUI_API const ImFontGlyph*FindGlyph(ImWchar c) const;
			//IMGUI_API const ImFontGlyph*FindGlyphNoFallback(ImWchar c) const;
			//float                       GetCharAdvance(ImWchar c) const     { return ((int)c < IndexAdvanceX.Size) ? IndexAdvanceX[(int)c] : FallbackAdvanceX; }
			//bool                        IsLoaded() const                    { return ContainerAtlas != NULL; }
			//const char*                 GetDebugName() const                { return ConfigData ? ConfigData->Name : "<unknown>"; }

			// 'max_width' stops rendering after a certain width (could be turned into a 2d size). FLT_MAX to disable.
			// 'wrap_width' enable automatic word-wrapping across multiple lines to fit into given width. 0.0f to disable.
			//IMGUI_API ImVec2            CalcTextSizeA(float size, float max_width, float wrap_width, const char* text_begin, const char* text_end = NULL, const char** remaining = NULL) const; // utf8
			//IMGUI_API const char*       CalcWordWrapPositionA(float scale, const char* text, const char* text_end, float wrap_width) const;
			//IMGUI_API void              RenderChar(ImDrawList* draw_list, float size, ImVec2 pos, ImU32 col, ImWchar c) const;
			//IMGUI_API void              RenderText(ImDrawList* draw_list, float size, ImVec2 pos, ImU32 col, const ImVec4& clip_rect, const char* text_begin, const char* text_end, float wrap_width = 0.0f, bool cpu_fine_clip = false) const;

			// [Internal] Don't use!
			//IMGUI_API void              BuildLookupTable();
			//IMGUI_API void              ClearOutputData();
			//IMGUI_API void              GrowIndex(int new_size);
			//IMGUI_API void              AddGlyph(ImWchar c, float x0, float y0, float x1, float y1, float u0, float v0, float u1, float v1, float advance_x);
			//IMGUI_API void              AddRemapChar(ImWchar dst, ImWchar src, bool overwrite_dst = true); // Makes 'dst' character/glyph points to 'src' character/glyph. Currently needs to be called AFTER fonts have been built.
			//IMGUI_API void              SetGlyphVisible(ImWchar c, bool visible);
			//IMGUI_API void              SetFallbackChar(ImWchar c);
			//IMGUI_API bool              IsGlyphRangeUnused(unsigned int c_begin, unsigned int c_last);
		};
	}
}
