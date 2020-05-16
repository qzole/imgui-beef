using System;

namespace imgui_beef
{
	static extension ImGui
	{
		// Flags for ImGui::Begin()
		public enum WindowFlags : int32
		{
			None                   = 0,
			NoTitleBar             = 1 << 0,   // Disable title-bar
			NoResize               = 1 << 1,   // Disable user resizing with the lower-right grip
			NoMove                 = 1 << 2,   // Disable user moving the window
			NoScrollbar            = 1 << 3,   // Disable scrollbars (window can still scroll with mouse or programmatically)
			NoScrollWithMouse      = 1 << 4,   // Disable user vertically scrolling with mouse wheel. On child window, mouse wheel will be forwarded to the parent unless NoScrollbar is also set.
			NoCollapse             = 1 << 5,   // Disable user collapsing window by double-clicking on it
			AlwaysAutoResize       = 1 << 6,   // Resize every window to its content every frame
			NoBackground           = 1 << 7,   // Disable drawing background color (WindowBg, etc.) and outside border. Similar as using SetNextWindowBgAlpha(0.0f).
			NoSavedSettings        = 1 << 8,   // Never load/save settings in .ini file
			NoMouseInputs          = 1 << 9,   // Disable catching mouse, hovering test with pass through.
			MenuBar                = 1 << 10,  // Has a menu-bar
			HorizontalScrollbar    = 1 << 11,  // Allow horizontal scrollbar to appear (off by default). You may use SetNextWindowContentSize(ImVec2(width,0.0f)); prior to calling Begin() to specify width. Read code in imgui_demo in the "Horizontal Scrolling" section.
			NoFocusOnAppearing     = 1 << 12,  // Disable taking focus when transitioning from hidden to visible state
			NoBringToFrontOnFocus  = 1 << 13,  // Disable bringing window to front when taking focus (e.g. clicking on it or programmatically giving it focus)
			AlwaysVerticalScrollbar= 1 << 14,  // Always show vertical scrollbar (even if ContentSize.y < Size.y)
			AlwaysHorizontalScrollbar=1<< 15,  // Always show horizontal scrollbar (even if ContentSize.x < Size.x)
			AlwaysUseWindowPadding = 1 << 16,  // Ensure child windows without border uses style.WindowPadding (ignored by default for non-bordered child windows, because more convenient)
			NoNavInputs            = 1 << 18,  // No gamepad/keyboard navigation within the window
			NoNavFocus             = 1 << 19,  // No focusing toward this window with gamepad/keyboard navigation (e.g. skipped by CTRL+TAB)
			UnsavedDocument        = 1 << 20,  // Append '*' to title without affecting the ID, as a convenience to avoid using the ### operator. When used in a tab/docking context, tab is selected on closure and closure is deferred by one frame to allow code to cancel the closure (with a confirmation popup, etc.) without flicker.
			NoNav                  = NoNavInputs | NoNavFocus,
			NoDecoration           = NoTitleBar | NoResize | NoScrollbar | NoCollapse,
			NoInputs               = NoMouseInputs | NoNavInputs | NoNavFocus,

			// [Internal]
			NavFlattened           = 1 << 23,  // [BETA] Allow gamepad/keyboard navigation to cross over parent border to this child (only use on child that have no scrolling!)
			ChildWindow            = 1 << 24,  // Don't use! For internal use by BeginChild()
			Tooltip                = 1 << 25,  // Don't use! For internal use by BeginTooltip()
			Popup                  = 1 << 26,  // Don't use! For internal use by BeginPopup()
			Modal                  = 1 << 27,  // Don't use! For internal use by BeginPopupModal()
			ChildMenu              = 1 << 28   // Don't use! For internal use by BeginMenu()

			// [Obsolete]
			//ShowBorders          = 1 << 7,   // --> Set style.FrameBorderSize=1.0f or style.WindowBorderSize=1.0f to enable borders around items or windows.
			//ResizeFromAnySide    = 1 << 17,  // --> Set io.ConfigWindowsResizeFromEdges=true and make sure mouse cursors are supported by back-end (io.BackendFlags & HasMouseCursors)
		};

		// Flags for ImGui::InputText()
		public enum InputTextFlags : int32
		{
			None                = 0,
			CharsDecimal        = 1 << 0,   // Allow 0123456789.+-*/
			CharsHexadecimal    = 1 << 1,   // Allow 0123456789ABCDEFabcdef
			CharsUppercase      = 1 << 2,   // Turn a..z into A..Z
			CharsNoBlank        = 1 << 3,   // Filter out spaces, tabs
			AutoSelectAll       = 1 << 4,   // Select entire text when first taking mouse focus
			EnterReturnsTrue    = 1 << 5,   // Return 'true' when Enter is pressed (as opposed to every time the value was modified). Consider looking at the IsItemDeactivatedAfterEdit() function.
			CallbackCompletion  = 1 << 6,   // Callback on pressing TAB (for completion handling)
			CallbackHistory     = 1 << 7,   // Callback on pressing Up/Down arrows (for history handling)
			CallbackAlways      = 1 << 8,   // Callback on each iteration. User code may query cursor position, modify text buffer.
			CallbackCharFilter  = 1 << 9,   // Callback on character inputs to replace or discard them. Modify 'EventChar' to replace or discard, or return 1 in callback to discard.
			AllowTabInput       = 1 << 10,  // Pressing TAB input a '\t' character into the text field
			CtrlEnterForNewLine = 1 << 11,  // In multi-line mode, unfocus with Enter, add new line with Ctrl+Enter (default is opposite: unfocus with Ctrl+Enter, add line with Enter).
			NoHorizontalScroll  = 1 << 12,  // Disable following the cursor horizontally
			AlwaysInsertMode    = 1 << 13,  // Insert mode
			ReadOnly            = 1 << 14,  // Read-only mode
			Password            = 1 << 15,  // Password mode, display all characters as '*'
			NoUndoRedo          = 1 << 16,  // Disable undo/redo. Note that input text owns the text data while active, if you want to provide your own undo/redo stack you need e.g. to call ClearActiveID().
			CharsScientific     = 1 << 17,  // Allow 0123456789.+-*/eE (Scientific notation input)
			CallbackResize      = 1 << 18,  // Callback on buffer capacity changes request (beyond 'buf_size' parameter value), allowing the string to grow. Notify when the string wants to be resized (for string types which hold a cache of their Size). You will be provided a new BufSize in the callback and NEED to honor it. (see misc/cpp/imgui_stdlib.h for an example of using this)
			// [Internal]
			Multiline           = 1 << 20,  // For internal use by InputTextMultiline()
			NoMarkEdited        = 1 << 21   // For internal use by functions using InputText() before reformatting data
		};

		// Flags for ImGui::TreeNodeEx(), ImGui::CollapsingHeader*()
		public enum TreeNodeFlags : int32
		{
			None                 = 0,
			Selected             = 1 << 0,   // Draw as selected
			Framed               = 1 << 1,   // Full colored frame (e.g. for CollapsingHeader)
			AllowItemOverlap     = 1 << 2,   // Hit testing to allow subsequent widgets to overlap this one
			NoTreePushOnOpen     = 1 << 3,   // Don't do a TreePush() when open (e.g. for CollapsingHeader) = no extra indent nor pushing on ID stack
			NoAutoOpenOnLog      = 1 << 4,   // Don't automatically and temporarily open node when Logging is active (by default logging will automatically open tree nodes)
			DefaultOpen          = 1 << 5,   // Default node to be open
			OpenOnDoubleClick    = 1 << 6,   // Need double-click to open node
			OpenOnArrow          = 1 << 7,   // Only open when clicking on the arrow part. If OpenOnDoubleClick is also set, single-click arrow or double-click all box to open.
			Leaf                 = 1 << 8,   // No collapsing, no arrow (use as a convenience for leaf nodes).
			Bullet               = 1 << 9,   // Display a bullet instead of arrow
			FramePadding         = 1 << 10,  // Use FramePadding (even for an unframed text node) to vertically align text baseline to regular widget height. Equivalent to calling AlignTextToFramePadding().
			SpanAvailWidth       = 1 << 11,  // Extend hit box to the right-most edge, even if not framed. This is not the default in order to allow adding other items on the same line. In the future we may refactor the hit system to be front-to-back, allowing natural overlaps and then this can become the default.
			SpanFullWidth        = 1 << 12,  // Extend hit box to the left-most and right-most edges (bypass the indented area).
			NavLeftJumpsBackHere = 1 << 13,  // (WIP) Nav: left direction may move to this TreeNode() from any of its child (items submitted between TreeNode and TreePop)
			//NoScrollOnOpen     = 1 << 14,  // FIXME: TODO: Disable automatic scroll on TreePop() if node got just open and contents is not visible
			CollapsingHeader     = Framed | NoTreePushOnOpen | NoAutoOpenOnLog
		};

		// Flags for ImGui::Selectable()
		public enum SelectableFlags : int32
		{
			None               = 0,
			DontClosePopups    = 1 << 0,   // Clicking this don't close parent popup window
			SpanAllColumns     = 1 << 1,   // Selectable frame can span all columns (text will still fit in current column)
			AllowDoubleClick   = 1 << 2,   // Generate press events on double clicks too
			Disabled           = 1 << 3,   // Cannot be selected, display grayed out text
			AllowItemOverlap   = 1 << 4    // (WIP) Hit testing to allow subsequent widgets to overlap this one
		};

		// Flags for ImGui::BeginCombo()
		public enum ComboFlags : int32
		{
			None                    = 0,
			PopupAlignLeft          = 1 << 0,   // Align the popup toward the left by default
			HeightSmall             = 1 << 1,   // Max ~4 items visible. Tip: If you want your combo popup to be a specific size you can use SetNextWindowSizeConstraints() prior to calling BeginCombo()
			HeightRegular           = 1 << 2,   // Max ~8 items visible (default)
			HeightLarge             = 1 << 3,   // Max ~20 items visible
			HeightLargest           = 1 << 4,   // As many fitting items as possible
			NoArrowButton           = 1 << 5,   // Display on the preview box without the square arrow button
			NoPreview               = 1 << 6,   // Display only a square arrow button
			HeightMask_             = HeightSmall | HeightRegular | HeightLarge | HeightLargest
		};

		// Flags for ImGui::BeginTabBar()
		[AllowDuplicates]
		public enum TabBarFlags : int32
		{
			None                           = 0,
			Reorderable                    = 1 << 0,   // Allow manually dragging tabs to re-order them + New tabs are appended at the end of list
			AutoSelectNewTabs              = 1 << 1,   // Automatically select new tabs when they appear
			TabListPopupButton             = 1 << 2,   // Disable buttons to open the tab list popup
			NoCloseWithMiddleMouseButton   = 1 << 3,   // Disable behavior of closing tabs (that are submitted with p_open != NULL) with middle mouse button. You can still repro this behavior on user's side with if (IsItemHovered() && IsMouseClicked(2)) *p_open = false.
			NoTabListScrollingButtons      = 1 << 4,   // Disable scrolling buttons (apply when fitting policy is FittingPolicyScroll)
			NoTooltip                      = 1 << 5,   // Disable tooltips when hovering a tab
			FittingPolicyResizeDown        = 1 << 6,   // Resize tabs when they don't fit
			FittingPolicyScroll            = 1 << 7,   // Add scroll buttons when tabs don't fit
			FittingPolicyMask_             = FittingPolicyResizeDown | FittingPolicyScroll,
			FittingPolicyDefault_          = FittingPolicyResizeDown
		};

		// Flags for ImGui::BeginTabItem()
		public enum TabItemFlags : int32
		{
			None                          = 0,
			UnsavedDocument               = 1 << 0,   // Append '*' to title without affecting the ID, as a convenience to avoid using the ### operator. Also: tab is selected on closure and closure is deferred by one frame to allow code to undo it without flicker.
			SetSelected                   = 1 << 1,   // Trigger flag to programmatically make the tab selected when calling BeginTabItem()
			NoCloseWithMiddleMouseButton  = 1 << 2,   // Disable behavior of closing tabs (that are submitted with p_open != NULL) with middle mouse button. You can still repro this behavior on user's side with if (IsItemHovered() && IsMouseClicked(2)) *p_open = false.
			NoPushId                      = 1 << 3    // Don't call PushID(tab->ID)/PopID() on BeginTabItem()/EndTabItem()
		};

		// Flags for ImGui::IsWindowFocused()
		public enum FocusedFlags : int32
		{
			None                          = 0,
			ChildWindows                  = 1 << 0,   // IsWindowFocused(): Return true if any children of the window is focused
			RootWindow                    = 1 << 1,   // IsWindowFocused(): Test from root window (top most parent of the current hierarchy)
			AnyWindow                     = 1 << 2,   // IsWindowFocused(): Return true if any window is focused. Important: If you are trying to tell how to dispatch your low-level inputs, do NOT use this. Use 'io.WantCaptureMouse' instead! Please read the FAQ!
			RootAndChildWindows           = RootWindow | ChildWindows
		};

		// Flags for ImGui::IsItemHovered(), ImGui::IsWindowHovered()
		// Note: if you are trying to check whether your mouse should be dispatched to Dear ImGui or to your app, you should use 'io.WantCaptureMouse' instead! Please read the FAQ!
		// Note: windows with the NoInputs flag are ignored by IsWindowHovered() calls.
		public enum HoveredFlags : int32
		{
			None                          = 0,        // Return true if directly over the item/window, not obstructed by another window, not obstructed by an active popup or modal blocking inputs under them.
			ChildWindows                  = 1 << 0,   // IsWindowHovered() only: Return true if any children of the window is hovered
			RootWindow                    = 1 << 1,   // IsWindowHovered() only: Test from root window (top most parent of the current hierarchy)
			AnyWindow                     = 1 << 2,   // IsWindowHovered() only: Return true if any window is hovered
			AllowWhenBlockedByPopup       = 1 << 3,   // Return true even if a popup window is normally blocking access to this item/window
			//AllowWhenBlockedByModal     = 1 << 4,   // Return true even if a modal popup window is normally blocking access to this item/window. FIXME-TODO: Unavailable yet.
			AllowWhenBlockedByActiveItem  = 1 << 5,   // Return true even if an active item is blocking access to this item/window. Useful for Drag and Drop patterns.
			AllowWhenOverlapped           = 1 << 6,   // Return true even if the position is obstructed or overlapped by another window
			AllowWhenDisabled             = 1 << 7,   // Return true even if the item is disabled
			RectOnly                      = AllowWhenBlockedByPopup | AllowWhenBlockedByActiveItem | AllowWhenOverlapped,
			RootAndChildWindows           = RootWindow | ChildWindows
		};

		// Flags for ImGui::BeginDragDropSource(), ImGui::AcceptDragDropPayload()
		public enum DragDropFlags : int32
		{
			None                         = 0,
			// BeginDragDropSource() flags
			SourceNoPreviewTooltip       = 1 << 0,   // By default, a successful call to BeginDragDropSource opens a tooltip so you can display a preview or description of the source contents. This flag disable this behavior.
			SourceNoDisableHover         = 1 << 1,   // By default, when dragging we clear data so that IsItemHovered() will return false, to avoid subsequent user code submitting tooltips. This flag disable this behavior so you can still call IsItemHovered() on the source item.
			SourceNoHoldToOpenOthers     = 1 << 2,   // Disable the behavior that allows to open tree nodes and collapsing header by holding over them while dragging a source item.
			SourceAllowNullID            = 1 << 3,   // Allow items such as Text(), Image() that have no unique identifier to be used as drag source, by manufacturing a temporary identifier based on their window-relative position. This is extremely unusual within the dear imgui ecosystem and so we made it explicit.
			SourceExtern                 = 1 << 4,   // External source (from outside of dear imgui), won't attempt to read current item/window info. Will always return true. Only one Extern source can be active simultaneously.
			SourceAutoExpirePayload      = 1 << 5,   // Automatically expire the payload if the source cease to be submitted (otherwise payloads are persisting while being dragged)
			// AcceptDragDropPayload() flags
			AcceptBeforeDelivery         = 1 << 10,  // AcceptDragDropPayload() will returns true even before the mouse button is released. You can then call IsDelivery() to test if the payload needs to be delivered.
			AcceptNoDrawDefaultRect      = 1 << 11,  // Do not draw the default highlight rectangle when hovering over target.
			AcceptNoPreviewTooltip       = 1 << 12,  // Request hiding the BeginDragDropSource tooltip from the BeginDragDropTarget site.
			AcceptPeekOnly               = AcceptBeforeDelivery | AcceptNoDrawDefaultRect  // For peeking ahead and inspecting the payload before delivery.
		};

		// To test io.KeyMods (which is a combination of individual fields io.KeyCtrl, io.KeyShift, io.KeyAlt set by user/back-end)
		public enum KeyModFlags : int32
		{
			None       = 0,
			Ctrl       = 1 << 0,
			Shift      = 1 << 1,
			Alt        = 1 << 2,
			Super      = 1 << 3
		};
		
		// Configuration flags stored in io.ConfigFlags. Set by user/application.
		public enum ConfigFlags : int32
		{
			None                   = 0,
			NavEnableKeyboard      = 1 << 0,   // Master keyboard navigation enable flag. NewFrame() will automatically fill io.NavInputs[] based on io.KeysDown[].
			NavEnableGamepad       = 1 << 1,   // Master gamepad navigation enable flag. This is mostly to instruct your imgui back-end to fill io.NavInputs[]. Back-end also needs to set HasGamepad.
			NavEnableSetMousePos   = 1 << 2,   // Instruct navigation to move the mouse cursor. May be useful on TV/console systems where moving a virtual mouse is awkward. Will update io.MousePos and set io.WantSetMousePos=true. If enabled you MUST honor io.WantSetMousePos requests in your binding, otherwise ImGui will react as if the mouse is jumping around back and forth.
			NavNoCaptureKeyboard   = 1 << 3,   // Instruct navigation to not set the io.WantCaptureKeyboard flag when io.NavActive is set.
			NoMouse                = 1 << 4,   // Instruct imgui to clear mouse position/buttons in NewFrame(). This allows ignoring the mouse information set by the back-end.
			NoMouseCursorChange    = 1 << 5,   // Instruct back-end to not alter mouse cursor shape and visibility. Use if the back-end cursor changes are interfering with yours and you don't want to use SetMouseCursor() to change mouse cursor. You may want to honor requests from imgui by reading GetMouseCursor() yourself instead.

			// User storage (to allow your back-end/engine to communicate to code that may be shared between multiple projects. Those flags are not used by core Dear ImGui)
			IsSRGB                 = 1 << 20,  // Application is SRGB-aware.
			IsTouchScreen          = 1 << 21   // Application is using a touch screen instead of a mouse.
		};

		// Back-end capabilities flags stored in io.BackendFlags. Set by imgui_impl_xxx or custom back-end.
		public enum BackendFlags : int32
		{
			None                  = 0,
			HasGamepad            = 1 << 0,   // Back-end Platform supports gamepad and currently has one connected.
			HasMouseCursors       = 1 << 1,   // Back-end Platform supports honoring GetMouseCursor() value to change the OS cursor shape.
			HasSetMousePos        = 1 << 2,   // Back-end Platform supports io.WantSetMousePos requests to reposition the OS mouse position (only used if NavEnableSetMousePos is set).
			RendererHasVtxOffset  = 1 << 3    // Back-end Renderer supports ImDrawCmd::VtxOffset. This enables output of large meshes (64K+ vertices) while still using 16-bit indices.
		};

		// Flags for ColorEdit3() / ColorEdit4() / ColorPicker3() / ColorPicker4() / ColorButton()
		public enum ColorEditFlags : int32
		{
			None            = 0,
			NoAlpha         = 1 << 1,   //              // ColorEdit, ColorPicker, ColorButton: ignore Alpha component (will only read 3 components from the input pointer).
			NoPicker        = 1 << 2,   //              // ColorEdit: disable picker when clicking on colored square.
			NoOptions       = 1 << 3,   //              // ColorEdit: disable toggling options menu when right-clicking on inputs/small preview.
			NoSmallPreview  = 1 << 4,   //              // ColorEdit, ColorPicker: disable colored square preview next to the inputs. (e.g. to show only the inputs)
			NoInputs        = 1 << 5,   //              // ColorEdit, ColorPicker: disable inputs sliders/text widgets (e.g. to show only the small preview colored square).
			NoTooltip       = 1 << 6,   //              // ColorEdit, ColorPicker, ColorButton: disable tooltip when hovering the preview.
			NoLabel         = 1 << 7,   //              // ColorEdit, ColorPicker: disable display of inline text label (the label is still forwarded to the tooltip and picker).
			NoSidePreview   = 1 << 8,   //              // ColorPicker: disable bigger color preview on right side of the picker, use small colored square preview instead.
			NoDragDrop      = 1 << 9,   //              // ColorEdit: disable drag and drop target. ColorButton: disable drag and drop source.
			NoBorder        = 1 << 10,  //              // ColorButton: disable border (which is enforced by default)

			// User Options (right-click on widget to change some of them).
			AlphaBar        = 1 << 16,  //              // ColorEdit, ColorPicker: show vertical alpha bar/gradient in picker.
			AlphaPreview    = 1 << 17,  //              // ColorEdit, ColorPicker, ColorButton: display preview as a transparent color over a checkerboard, instead of opaque.
			AlphaPreviewHalf= 1 << 18,  //              // ColorEdit, ColorPicker, ColorButton: display half opaque / half checkerboard, instead of opaque.
			HDR             = 1 << 19,  //              // (WIP) ColorEdit: Currently only disable 0.0f..1.0f limits in RGBA edition (note: you probably want to use Float flag as well).
			DisplayRGB      = 1 << 20,  // [Display]    // ColorEdit: override _display_ type among RGB/HSV/Hex. ColorPicker: select any combination using one or more of RGB/HSV/Hex.
			DisplayHSV      = 1 << 21,  // [Display]    // "
			DisplayHex      = 1 << 22,  // [Display]    // "
			Uint8           = 1 << 23,  // [DataType]   // ColorEdit, ColorPicker, ColorButton: _display_ values formatted as 0..255.
			Float           = 1 << 24,  // [DataType]   // ColorEdit, ColorPicker, ColorButton: _display_ values formatted as 0.0f..1.0f floats instead of 0..255 integers. No round-trip of value via integers.
			PickerHueBar    = 1 << 25,  // [Picker]     // ColorPicker: bar for Hue, rectangle for Sat/Value.
			PickerHueWheel  = 1 << 26,  // [Picker]     // ColorPicker: wheel for Hue, triangle for Sat/Value.
			InputRGB        = 1 << 27,  // [Input]      // ColorEdit, ColorPicker: input and output data in RGB format.
			InputHSV        = 1 << 28,  // [Input]      // ColorEdit, ColorPicker: input and output data in HSV format.

			// Defaults Options. You can set application defaults using SetColorEditOptions(). The intent is that you probably don't want to
			// override them in most of your calls. Let the user choose via the option menu and/or call SetColorEditOptions() once during startup.
			_OptionsDefault = Uint8|DisplayRGB|InputRGB|PickerHueBar,

			// [Internal] Masks
			_DisplayMask    = DisplayRGB|DisplayHSV|DisplayHex,
			_DataTypeMask   = Uint8|Float,
			_PickerMask     = PickerHueWheel|PickerHueBar,
			_InputMask      = InputRGB|InputHSV
		};

		
		public enum DrawCornerFlags : int32
		{
			ImDrawCornerFlags_None      = 0,
			ImDrawCornerFlags_TopLeft   = 1 << 0, // 0x1
			ImDrawCornerFlags_TopRight  = 1 << 1, // 0x2
			ImDrawCornerFlags_BotLeft   = 1 << 2, // 0x4
			ImDrawCornerFlags_BotRight  = 1 << 3, // 0x8
			ImDrawCornerFlags_Top       = ImDrawCornerFlags_TopLeft | ImDrawCornerFlags_TopRight,   // 0x3
			ImDrawCornerFlags_Bot       = ImDrawCornerFlags_BotLeft | ImDrawCornerFlags_BotRight,   // 0xC
			ImDrawCornerFlags_Left      = ImDrawCornerFlags_TopLeft | ImDrawCornerFlags_BotLeft,    // 0x5
			ImDrawCornerFlags_Right     = ImDrawCornerFlags_TopRight | ImDrawCornerFlags_BotRight,  // 0xA
			ImDrawCornerFlags_All       = 0xF     // In your function calls you may use ~0 (= all bits sets) instead of ImDrawCornerFlags_All, as a convenience
		};

		public enum DrawListFlags : int32
		{
			ImDrawListFlags_None             = 0,
			ImDrawListFlags_AntiAliasedLines = 1 << 0,  // Lines are anti-aliased (*2 the number of triangles for 1.0f wide line, otherwise *3 the number of triangles)
			ImDrawListFlags_AntiAliasedFill  = 1 << 1,  // Filled shapes have anti-aliased edges (*2 the number of vertices)
			ImDrawListFlags_AllowVtxOffset   = 1 << 2   // Can emit 'VtxOffset > 0' to allow large meshes. Set when 'RendererHasVtxOffset' is enabled.
		};

		public enum FontAtlasFlags : int32
		{
			ImFontAtlasFlags_None               = 0,
			ImFontAtlasFlags_NoPowerOfTwoHeight = 1 << 0,   // Don't round the height to next power of two
			ImFontAtlasFlags_NoMouseCursors     = 1 << 1    // Don't build software mouse cursors into the atlas
		};
	}
}
