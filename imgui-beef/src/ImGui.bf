using System;

namespace imgui_beef
{
	static class ImGui
	{
		public static char8* VERSION = "1.76";
		public static int VERSION_NUM = 17600;
		public static bool CHECKVERSION()
		{
			bool result = DebugCheckVersionAndDataLayout(VERSION, sizeof(IO), sizeof(Style), sizeof(Vec2), sizeof(Vec4), sizeof(DrawVert), sizeof(DrawIdx));
			Runtime.Assert(result);
			return result;
		}

		public static mixin ASSERT(bool condition) { Runtime.Assert(condition); }
		public static mixin ASSERT(bool condition, String errorMsg) { Runtime.Assert(condition, errorMsg); }

		//-----------------------------------------------------------------------------
		// Basic types
		//-----------------------------------------------------------------------------

		// For better readability where imgui is actually using size_t, since int is not the same size between c++ and Beef
		public typealias size_t = uint;

		public typealias TextureID = void*;
		public typealias ImGuiID = uint;
		public typealias InputTextCallback = function int(InputTextCallbackData* data);
		public typealias SizeCallback = function int(SizeCallbackData* data);

		public typealias ImWchar16 = int16;
		public typealias ImWchar32 = int;
#if IMGUI_USE_WCHAR32
		public typealias ImWchar = ImWchar32;
#else
		public typealias ImWchar = ImWchar16;
#endif


		// Helper method to convert cimgui style getters
		private static T CallGetter<T>(function void(T* pOut) getterFunc)
		{
			T result = ?;
			getterFunc(&result);
			return result;
		}

		//-----------------------------------------------------------------------------
		// ImGui: Dear ImGui end-user API
		//-----------------------------------------------------------------------------

		// Context creation and access
		// Each context create its own ImFontAtlas by default. You may instance one yourself and pass it to CreateContext() to share a font atlas between imgui contexts.
		// None of those functions is reliant on the current context.
		[LinkName("igCreateContext")]
		public static extern Context* CreateContext(FontAtlas* shared_font_atlas = null);
		[LinkName("igDestroyContext")]
		public static extern void DestroyContext(Context* ctx = null); // NULL = destroy current context
		[LinkName("igGetCurrentContext")]
		public static extern Context* GetCurrentContext();
		[LinkName("igSetCurrentContext")]
		public static extern void SetCurrentContext(Context* ctx);

		// Main
		[LinkName("igGetIO")]
		private static extern IO* GetIOImpl(); // access the IO structure (mouse/keyboard/gamepad inputs, time, various configuration options/flags)
		public static ref IO GetIO() { return ref *GetIOImpl(); }
		[LinkName("igGetStyle")]
		private static extern Style* GetStyleImpl(); // access the Style structure (colors, sizes). Always use PushStyleCol(), PushStyleVar() to modify style mid-frame!
		public static ref Style GetStyle() { return ref *GetStyleImpl(); }
		[LinkName("igNewFrame")]
		public static extern void NewFrame(); // start a new Dear ImGui frame, you can submit any command from this point until Render()/EndFrame().
		[LinkName("igEndFrame")]
		public static extern void EndFrame(); // ends the Dear ImGui frame. automatically called by Render(). If you don't need to render data (skipping rendering) you may call EndFrame() without Render()... but you'll have wasted CPU already! If you don't need to render, better to not create any windows and not call NewFrame() at all!
		[LinkName("igRender")]
		public static extern void Render(); // ends the Dear ImGui frame, finalize the draw data. You can get call GetDrawData() to obtain it and run your rendering function (up to v1.60, this used to call io.RenderDrawListsFn(). Nowadays, we allow and prefer calling your render function yourself.)
		[LinkName("igGetDrawData")]
		public static extern DrawData* GetDrawData(); // valid after Render() and until the next call to NewFrame(). this is what you have to render.

		// Demo, Debug, Information
		[LinkName("igShowDemoWindow")]
		public static extern void ShowDemoWindow(bool* p_open = null); // create Demo window (previously called ShowTestWindow). demonstrate most ImGui features. call this to learn about the library! try to make it always available in your application!
		[LinkName("igShowAboutWindow")]
		public static extern void ShowAboutWindow(bool* p_open = null); // create About window. display Dear ImGui version, credits and build/system information.
		[LinkName("igShowMetricsWindow")]
		public static extern void ShowMetricsWindow(bool* p_open = null); // create Debug/Metrics window. display Dear ImGui internals: draw commands (with individual draw calls and vertices), window list, basic internal state, etc.
		[LinkName("igShowStyleEditor")]
		public static extern void ShowStyleEditor(Style* style = null); // add style editor block (not a window). you can pass in a reference ImGuiStyle structure to compare to, revert to and save to (else it uses the default style)
		[LinkName("igShowStyleSelector")]
		public static extern bool ShowStyleSelector(char8* label); // add style selector block (not a window), essentially a combo listing the default styles.
		[LinkName("igShowFontSelector")]
		public static extern void ShowFontSelector(char8* label); // add font selector block (not a window), essentially a combo listing the loaded fonts.
		[LinkName("igShowUserGuide")]
		public static extern void ShowUserGuide(); // add basic help/info block (not a window): how to manipulate ImGui as a end-user (mouse/keyboard controls).
		[LinkName("igGetVersion")]
		public static extern readonly char8* GetVersion(); // get the compiled version string e.g. "1.23" (essentially the compiled value for IMGUI_VERSION)

		// Styles
		[LinkName("igStyleColorsDark")]
		public static extern void StyleColorsDark(Style* style = null);	// new, recommended style (default)
		[LinkName("igStyleColorsClassic")]
		public static extern void StyleColorsClassic(Style* style = null); // classic imgui style
		[LinkName("igStyleColorsLight")]
		public static extern void StyleColorsLight(Style* style = null); // best used with borders and a custom, thicker font

		// Windows
		// - Begin() = push window to the stack and start appending to it. End() = pop window from the stack.
		// - You may append multiple times to the same window during the same frame.
		// - Passing 'bool* p_open != NULL' shows a window-closing widget in the upper-right corner of the window,
		//   which clicking will set the boolean to false when clicked.
		// - Begin() return false to indicate the window is collapsed or fully clipped, so you may early out and omit submitting
		//   anything to the window. Always call a matching End() for each Begin() call, regardless of its return value!
		//   [Important: due to legacy reason, this is inconsistent with most other functions such as BeginMenu/EndMenu,
		//    BeginPopup/EndPopup, etc. where the EndXXX call should only be called if the corresponding BeginXXX function
		//    returned true. Begin and BeginChild are the only odd ones out. Will be fixed in a future update.]
		// - Note that the bottom of window stack always contains a window called "Debug".
		[LinkName("igBegin")]
		public static extern void Begin(char8* name, bool* p_open = null, WindowFlags flags = 0);
		[LinkName("igEnd")]
		public static extern void End();

		// Child Windows
		// - Use child windows to begin into a self-contained independent scrolling/clipping regions within a host window. Child windows can embed their own child.
		// - For each independent axis of 'size': ==0.0f: use remaining host window size / >0.0f: fixed size / <0.0f: use remaining window size minus abs(size) / Each axis can use a different mode, e.g. ImVec2(0,400).
		// - BeginChild() returns false to indicate the window is collapsed or fully clipped, so you may early out and omit submitting anything to the window.
		//   Always call a matching EndChild() for each BeginChild() call, regardless of its return value [as with Begin: this is due to legacy reason and inconsistent with most BeginXXX functions apart from the regular Begin() which behaves like BeginChild().]
		[LinkName("igBeginChildStr")]
		public static extern void BeginChild(char8* str_id, Vec2 size = default, bool border = false, WindowFlags flags = 0);
		[LinkName("igBeginChildID")]
		public static extern void BeginChild(ImGuiID id, Vec2 size = default, bool border = false, WindowFlags flags = 0);
		[LinkName("igEndChild")]
		public static extern void EndChild();

		// Windows Utilities
		// - 'current window' = the window we are appending into while inside a Begin()/End() block. 'next window' = next window we will Begin() into.
		[LinkName("igIsWindowAppearing")]
		public static extern bool IsWindowAppearing();
		[LinkName("igIsWindowCollapsed")]
		public static extern bool IsWindowCollapsed();
		[LinkName("igIsWindowFocused")]
		public static extern bool IsWindowFocused(FocusedFlags flags=0); // is current window focused? or its root/child, depending on flags. see flags for options.
		[LinkName("igIsWindowHovered")]
		public static extern bool IsWindowHovered(HoveredFlags flags=0); // is current window hovered (and typically: not blocked by a popup/modal)? see flags for options. NB: If you are trying to check whether your mouse should be dispatched to imgui or to your app, you should use the 'io.WantCaptureMouse' boolean for that! Please read the FAQ!
		[LinkName("igGetWindowDrawList")]
		public static extern DrawList* GetWindowDrawList(); // get draw list associated to the current window, to append your own drawing primitives
		[LinkName("igGetWindowPos")]
		private static extern void GetWindowPosImpl(Vec2* pOut); // get current window position in screen space (useful if you want to do your own drawing via the DrawList API)
		public static Vec2 GetWindowPos() { return CallGetter<Vec2>(=> GetWindowPosImpl); }
		[LinkName("igGetWindowSize")]
		private static extern void GetWindowSizeImpl(Vec2* pOut); // get current window size
		public static Vec2 GetWindowSize() { return CallGetter<Vec2>(=> GetWindowSizeImpl); }
		[LinkName("igGetWindowWidth")]
		public static extern float GetWindowWidth(); // get current window width (shortcut for GetWindowSize().x)
		[LinkName("igGetWindowHeight")]
		public static extern float GetWindowHeight(); // get current window height (shortcut for GetWindowSize().y)

		// Prefer using SetNextXXX functions (before Begin) rather that SetXXX functions (after Begin).
		[LinkName("igSetNextWindowPos")]
		public static extern void SetNextWindowPos(Vec2 pos, Cond cond = 0, Vec2 pivot = default); // set next window position. call before Begin(). use pivot=(0.5f,0.5f) to center on given point, etc.
		[LinkName("igSetNextWindowSize")]
		public static extern void SetNextWindowSize(Vec2 size, Cond cond = 0); // set next window size. set axis to 0.0f to force an auto-fit on this axis. call before Begin()
		[LinkName("igSetNextWindowSizeConstraints")]
		public static extern void SetNextWindowSizeConstraints(Vec2 size_min, Vec2 size_max, SizeCallback custom_callback = null, void* custom_callback_data = null); // set next window size limits. use -1,-1 on either X/Y axis to preserve the current size. Sizes will be rounded down. Use callback to apply non-trivial programmatic constraints.
		[LinkName("igSetNextWindowContentSize")]
		public static extern void SetNextWindowContentSize(Vec2 size); // set next window content size (~ scrollable client area, which enforce the range of scrollbars). Not including window decorations (title bar, menu bar, etc.) nor WindowPadding. set an axis to 0.0f to leave it automatic. call before Begin()
		[LinkName("igSetNextWindowCollapsed")]
		public static extern void SetNextWindowCollapsed(bool collapsed, Cond cond = 0); // set next window collapsed state. call before Begin()
		[LinkName("igSetNextWindowFocus")]
		public static extern void SetNextWindowFocus(); // set next window to be focused / top-most. call before Begin()
		[LinkName("igSetNextWindowBgAlpha")]
		public static extern void SetNextWindowBgAlpha(float alpha); // set next window background color alpha. helper to easily override the Alpha component of ImGuiCol_WindowBg/ChildBg/PopupBg. you may also use ImGuiWindowFlags_NoBackground.
		[LinkName("igSetWindowPos")]
		public static extern void SetWindowPos(Vec2 pos, Cond cond = 0); // (not recommended) set current window position - call within Begin()/End(). prefer using SetNextWindowPos(), as this may incur tearing and side-effects.
		[LinkName("igSetWindowSize")]
		public static extern void SetWindowSize(Vec2 size, Cond cond = 0); // (not recommended) set current window size - call within Begin()/End(). set to default to force an auto-fit. prefer using SetNextWindowSize(), as this may incur tearing and minor side-effects.
		[LinkName("igSetWindowCollapsed")]
		public static extern void SetWindowCollapsed(bool collapsed, Cond cond = 0); // (not recommended) set current window collapsed state. prefer using SetNextWindowCollapsed().
		[LinkName("igSetWindowFocus")]
		public static extern void SetWindowFocus(); // (not recommended) set current window to be focused / top-most. prefer using SetNextWindowFocus().
		[LinkName("igSetWindowFontScale")]
		public static extern void SetWindowFontScale(float scale); // set font scale. Adjust IO.FontGlobalScale if you want to scale all windows. This is an old API! For correct scaling, prefer to reload font + rebuild ImFontAtlas + call style.ScaleAllSizes().
		[LinkName("igSetWindowPos")]
		public static extern void SetWindowPos(char8* name, Vec2 pos, Cond cond = 0); // set named window position.
		[LinkName("igSetWindowSize")]
		public static extern void SetWindowSize(char8* name, Vec2 size, Cond cond = 0); // set named window size. set axis to 0.0f to force an auto-fit on this axis.
		[LinkName("igSetWindowCollapsed")]
		public static extern void SetWindowCollapsed(char8* name, bool collapsed, Cond cond = 0); // set named window collapsed state
		[LinkName("igSetWindowFocus")]
		public static extern void SetWindowFocus(char8* name); // set named window to be focused / top-most. use NULL to remove focus.

		// Content region
		// - Those functions are bound to be redesigned soon (they are confusing, incomplete and return values in local window coordinates which increases confusion)
		[LinkName("igGetContentRegionMax")]
		private static extern void GetContentRegionMaxImpl(Vec2* pOut); // current content boundaries (typically window boundaries including scrolling, or current column boundaries), in windows coordinates
		public static Vec2 GetContentRegionMax() { return CallGetter<Vec2>(=> GetContentRegionMaxImpl); }
		[LinkName("igGetContentRegionAvail")]
		private static extern void GetContentRegionAvailImpl(Vec2* pOut); // == GetContentRegionMax() - GetCursorPos()
		public static Vec2 GetContentRegionAvail() { return CallGetter<Vec2>(=> GetContentRegionAvailImpl); }
		[LinkName("igGetWindowContentRegionMin")]
		private static extern void GetWindowContentRegionMinImpl(Vec2* pOut); // content boundaries min (roughly (0,0)-Scroll), in window coordinates
		public static Vec2 GetWindowContentRegionMin() { return CallGetter<Vec2>(=> GetWindowContentRegionMinImpl); }
		[LinkName("igGetWindowContentRegionMax")]
		private static extern void GetWindowContentRegionMaxImpl(Vec2* pOut); // content boundaries max (roughly (0,0)+Size-Scroll) where Size can be override with SetNextWindowContentSize(), in window coordinates
		public static Vec2 GetWindowContentRegionMax() { return CallGetter<Vec2>(=> GetWindowContentRegionMaxImpl); }
		[LinkName("igGetWindowContentRegionWidth")]
		public static extern float GetWindowContentRegionWidth(); //

		// Windows Scrolling
		[LinkName("igGetScrollX")]
		public static extern float GetScrollX(); // get scrolling amount [0..GetScrollMaxX()]
		[LinkName("igGetScrollY")]
		public static extern float GetScrollY(); // get scrolling amount [0..GetScrollMaxY()]
		[LinkName("igGetScrollMaxX")]
		public static extern float GetScrollMaxX(); // get maximum scrolling amount ~~ ContentSize.X - WindowSize.X
		[LinkName("igGetScrollMaxY")]
		public static extern float GetScrollMaxY(); // get maximum scrolling amount ~~ ContentSize.Y - WindowSize.Y
		[LinkName("igSetScrollX")]
		public static extern void SetScrollX(float scroll_x); // set scrolling amount [0..GetScrollMaxX()]
		[LinkName("igSetScrollY")]
		public static extern void SetScrollY(float scroll_y); // set scrolling amount [0..GetScrollMaxY()]
		[LinkName("igSetScrollHereX")]
		public static extern void SetScrollHereX(float center_x_ratio = 0.5f); // adjust scrolling amount to make current cursor position visible. center_x_ratio=0.0: left, 0.5: center, 1.0: right. When using to make a "default/current item" visible, consider using SetItemDefaultFocus() instead.
		[LinkName("igSetScrollHereY")]
		public static extern void SetScrollHereY(float center_y_ratio = 0.5f); // adjust scrolling amount to make current cursor position visible. center_y_ratio=0.0: top, 0.5: center, 1.0: bottom. When using to make a "default/current item" visible, consider using SetItemDefaultFocus() instead.
		[LinkName("igSetScrollFromPosX")]
		public static extern void SetScrollFromPosX(float local_x, float center_x_ratio = 0.5f); // adjust scrolling amount to make given position visible. Generally GetCursorStartPos() + offset to compute a valid position.
		[LinkName("igSetScrollFromPosY")]
		public static extern void SetScrollFromPosY(float local_y, float center_y_ratio = 0.5f); // adjust scrolling amount to make given position visible. Generally GetCursorStartPos() + offset to compute a valid position.

		// Parameters stacks (shared)
		[LinkName("igPushFont")]
		public static extern void PushFont(Font* font); // use NULL as a shortcut to push default font
		[LinkName("igPopFont")]
		public static extern void PopFont();
		[LinkName("igPushStyleColorU32")]
		public static extern void PushStyleColor(Col idx, uint32 col);
		[LinkName("igPushStyleColorVec4")]
		public static extern void PushStyleColor(Col idx, Vec4 col);
		[LinkName("igPopStyleColor")]
		public static extern void PopStyleColor(int32 count = 1);
		[LinkName("igPushStyleVarFloat")]
		public static extern void PushStyleVar(StyleVar idx, float val);
		[LinkName("igPushStyleVarVec2")]
		public static extern void PushStyleVar(StyleVar idx, Vec2 val);
		[LinkName("igPopStyleVar")]
		public static extern void PopStyleVar(int32 count = 1);
		[LinkName("igGetStyleColorVec4")]
		private static extern readonly Vec4* GetStyleColorVec4Impl(Col idx); // retrieve style color as stored in ImGuiStyle structure. use to feed back into PushStyleColor(), otherwise use GetColorU32() to get style color with style alpha baked in.
		public static readonly ref Vec4 GetStyleColorVec4(Col idx) { return ref *GetStyleColorVec4Impl(idx); }
		[LinkName("igGetFont")]
		public static extern Font* GetFont(); // get current font
		[LinkName("igGetFontSize")]
		public static extern float GetFontSize(); // get current font size (= height in pixels) of current font with current scale applied
		[LinkName("igGetFontTexUvWhitePixel")]
		private static extern void GetFontTexUvWhitePixelImpl(Vec2* pOut); // get UV coordinate for a while pixel, useful to draw custom shapes via the ImDrawList API
		public static Vec2 GetFontTexUvWhitePixel() { return CallGetter<Vec2>(=> GetFontTexUvWhitePixelImpl); }
		[LinkName("igGetColorU32Col")]
		public static extern uint32 GetColorU32(Col idx, float alpha_mul = 1.0f); // retrieve given style color with style alpha applied and optional extra alpha multiplier
		[LinkName("igGetColorU32Vec4")]
		public static extern uint32 GetColorU32(Vec4 col); // retrieve given color with style alpha applied
		[LinkName("igGetColorU32U32")]
		public static extern uint32 GetColorU32(uint32 col); // retrieve given color with style alpha applied

		// Parameters stacks (current window)
		[LinkName("igPushItemWidth")]
		public static extern void PushItemWidth(float item_width); // push width of items for common large "item+label" widgets. >0.0f: width in pixels, <0.0f align xx pixels to the right of window (so -1.0f always align width to the right side). 0.0f = default to ~2/3 of windows width,
		[LinkName("igPopItemWidth")]
		public static extern void PopItemWidth();
		[LinkName("igSetNextItemWidth")]
		public static extern void SetNextItemWidth(float item_width); // set width of the _next_ common large "item+label" widget. >0.0f: width in pixels, <0.0f align xx pixels to the right of window (so -1.0f always align width to the right side)
		[LinkName("igCalcItemWidth")]
		public static extern float CalcItemWidth(); // width of item given pushed settings and current cursor position. NOT necessarily the width of last item unlike most 'Item' functions.
		[LinkName("igPushTextWrapPos")]
		public static extern void PushTextWrapPos(float wrap_local_pos_x = 0.0f); // push word-wrapping position for Text*() commands. < 0.0f: no wrapping; 0.0f: wrap to end of window (or column); > 0.0f: wrap at 'wrap_pos_x' position in window local space
		[LinkName("igPopTextWrapPos")]
		public static extern void PopTextWrapPos();
		[LinkName("igPushAllowKeyboardFocus")]
		public static extern void PushAllowKeyboardFocus(bool allow_keyboard_focus); // allow focusing using TAB/Shift-TAB, enabled by default but you can disable it for certain widgets
		[LinkName("igPopAllowKeyboardFocus")]
		public static extern void PopAllowKeyboardFocus();
		[LinkName("igPushButtonRepeat")]
		public static extern void PushButtonRepeat(bool _repeat); // in 'repeat' mode, Button*() functions return repeated true in a typematic manner (using io.KeyRepeatDelay/io.KeyRepeatRate setting). Note that you can call IsItemActive() after any Button() to tell if the button is held in the current frame.
		[LinkName("igPopButtonRepeat")]
		public static extern void PopButtonRepeat();

		// Cursor / Layout
		// - By "cursor" we mean the current output position.
		// - The typical widget behavior is to output themselves at the current cursor position, then move the cursor one line down.
		// - You can call SameLine() between widgets to undo the last carriage return and output at the right of the preceeding widget.
		// - Attention! We currently have inconsistencies between window-local and absolute positions we will aim to fix with future API:
		//    Window-local coordinates:   SameLine(), GetCursorPos(), SetCursorPos(), GetCursorStartPos(), GetContentRegionMax(), GetWindowContentRegion*(), PushTextWrapPos()
		//    Absolute coordinate:        GetCursorScreenPos(), SetCursorScreenPos(), all ImDrawList:: functions.
		[LinkName("igSeparator")]
		public static extern void Separator(); // separator, generally horizontal. inside a menu bar or in horizontal layout mode, this becomes a vertical separator.
		[LinkName("igSameLine")]
		public static extern void SameLine(float offset_from_start_x=0.0f, float spacing=-1.0f); // call between widgets or groups to layout them horizontally. X position given in window coordinates.
		[LinkName("igNewLine")]
		public static extern void NewLine(); // undo a SameLine() or force a new line when in an horizontal-layout context.
		[LinkName("igSpacing")]
		public static extern void Spacing(); // add vertical spacing.
		[LinkName("igDummy")]
		public static extern void Dummy(Vec2 size); // add a dummy item of given size. unlike InvisibleButton(), Dummy() won't take the mouse click or be navigable into.
		[LinkName("igIndent")]
		public static extern void Indent(float indent_w = 0.0f); // move content position toward the right, by style.IndentSpacing or indent_w if != 0
		[LinkName("igUnindent")]
		public static extern void Unindent(float indent_w = 0.0f); // move content position back to the left, by style.IndentSpacing or indent_w if != 0
		[LinkName("igBeginGroup")]
		public static extern void BeginGroup(); // lock horizontal starting position
		[LinkName("igEndGroup")]
		public static extern void EndGroup(); // unlock horizontal starting position + capture the whole group bounding box into one "item" (so you can use IsItemHovered() or layout primitives such as SameLine() on whole group, etc.)
		[LinkName("igGetCursorPos")]
		private static extern void GetCursorPosImpl(Vec2* pOut); // cursor position in window coordinates (relative to window position)
		public static Vec2 GetCursorPos() { return CallGetter<Vec2>(=> GetCursorPosImpl); }
		[LinkName("igGetCursorPosX")]
		public static extern float GetCursorPosX(); //   (some functions are using window-relative coordinates, such as: GetCursorPos, GetCursorStartPos, GetContentRegionMax, GetWindowContentRegion* etc.
		[LinkName("igGetCursorPosY")]
		public static extern float GetCursorPosY(); //    other functions such as GetCursorScreenPos or everything in ImDrawList::
		[LinkName("igSetCursorPos")]
		public static extern void SetCursorPos(Vec2 local_pos); //    are using the main, absolute coordinate system.
		[LinkName("igSetCursorPosX")]
		public static extern void SetCursorPosX(float local_x); //    GetWindowPos() + GetCursorPos() == GetCursorScreenPos() etc.)
		[LinkName("igSetCursorPosY")]
		public static extern void SetCursorPosY(float local_y); //
		[LinkName("igGetCursorStartPos")]
		private static extern void GetCursorStartPosImpl(Vec2* pOut); // initial cursor position in window coordinates
		public static Vec2 GetCursorStartPos() { return CallGetter<Vec2>(=> GetCursorStartPosImpl); }
		[LinkName("igGetCursorScreenPos")]
		private static extern void GetCursorScreenPosImpl(Vec2* pOut); // cursor position in absolute screen coordinates [0..io.DisplaySize] (useful to work with ImDrawList API)
		public static Vec2 GetCursorScreenPos() { return CallGetter<Vec2>(=> GetCursorScreenPosImpl); }
		[LinkName("igSetCursorScreenPos")]
		public static extern void SetCursorScreenPos(Vec2 pos); // cursor position in absolute screen coordinates [0..io.DisplaySize]
		[LinkName("igAlignTextToFramePadding")]
		public static extern void AlignTextToFramePadding(); // vertically align upcoming text baseline to FramePadding.y so that it will align properly to regularly framed items (call if you have text on a line before a framed item)
		[LinkName("igGetTextLineHeight")]
		public static extern float GetTextLineHeight(); // ~ FontSize
		[LinkName("igGetTextLineHeightWithSpacing")]
		public static extern float GetTextLineHeightWithSpacing(); // ~ FontSize + style.ItemSpacing.y (distance in pixels between 2 consecutive lines of text)
		[LinkName("igGetFrameHeight")]
		public static extern float GetFrameHeight(); // ~ FontSize + style.FramePadding.y * 2
		[LinkName("igGetFrameHeightWithSpacing")]
		public static extern float GetFrameHeightWithSpacing(); // ~ FontSize + style.FramePadding.y * 2 + style.ItemSpacing.y (distance in pixels between 2 consecutive lines of framed widgets)

		// ID stack/scopes
		// - Read the FAQ for more details about how ID are handled in dear imgui. If you are creating widgets in a loop you most
		//   likely want to push a unique identifier (e.g. object pointer, loop index) to uniquely differentiate them.
		// - The resulting ID are hashes of the entire stack.
		// - You can also use the "Label##foobar" syntax within widget label to distinguish them from each others.
		// - In this header file we use the "label"/"name" terminology to denote a string that will be displayed and used as an ID,
		//   whereas "str_id" denote a string that is only used as an ID and not normally displayed.
		[LinkName("igPushIDStr")]
		public static extern void PushID(char8* str_id); // push string into the ID stack (will hash string).
		[LinkName("igPushIDStrStr")]
		public static extern void PushID(char8* str_id_begin, char8* str_id_end); // push string into the ID stack (will hash string).
		[LinkName("igPushIDPtr")]
		public static extern void PushID(void* ptr_id); // push pointer into the ID stack (will hash pointer).
		[LinkName("igPushIDInt")]
		public static extern void PushID(int int_id); // push integer into the ID stack (will hash integer).
		[LinkName("igPopID")]
		public static extern void PopID(); // pop from the ID stack.
		[LinkName("igGetIDStr")]
		public static extern ImGuiID GetID(char8* str_id); // calculate unique ID (hash of whole ID stack + given parameter). e.g. if you want to query into ImGuiStorage yourself
		[LinkName("igGetIDStrStr")]
		public static extern ImGuiID GetID(char8* str_id_begin, char8* str_id_end);
		[LinkName("igGetIDPtr")]
		public static extern ImGuiID GetID(void* ptr_id);

		// Widgets: Text
		[LinkName("igTextUnformatted")]
		public static extern void TextUnformatted(char8* text, char8* text_end = null); // raw text without formatting. Roughly equivalent to Text("%s", text) but: A) doesn't require null terminated string if 'text_end' is specified, B) it's faster, no memory copy is done, no buffer size limits, recommended for long chunks of text.
		[LinkName("igText")]
		public static extern void Text(char8* fmt, ...); // formatted text
		//[LinkName("igTextV")]
		//public static extern void TextV(char8* fmt, va_list args); // TODO?
		[LinkName("igTextColored")]
		public static extern void TextColored(Vec4 col, char8* fmt, ...); // shortcut for PushStyleColor(ImGuiCol_Text, col); Text(fmt, ...); PopStyleColor();
		//[LinkName("igTextColoredV")]
		//public static extern void TextColoredV(Vec4 col, char8* fmt, va_list args); // TODO?
		[LinkName("igTextDisabled")]
		public static extern void TextDisabled(char8* fmt, ...); // shortcut for PushStyleColor(ImGuiCol_Text, style.Colors[ImGuiCol_TextDisabled]); Text(fmt, ...); PopStyleColor();
		//[LinkName("igTextDisabledV")]
		//public static extern void TextDisabledV(char8* fmt, va_list args); // TODO?
		[LinkName("igTextWrapped")]
		public static extern void TextWrapped(char8* fmt, ...); // shortcut for PushTextWrapPos(0.0f); Text(fmt, ...); PopTextWrapPos();. Note that this won't work on an auto-resizing window if there's no other widgets to extend the window width, yoy may need to set a size using SetNextWindowSize().
		//[LinkName("igTextWrappedV")]
		//public static extern void TextWrappedV(char8* fmt, va_list args); // TODO?
		[LinkName("igLabelText")]
		public static extern void LabelText(char8* label, char8* fmt, ...); // display text+label aligned the same way as value+label widgets
		//[LinkName("igLabelTextV")]
		//public static extern void LabelTextV(char8* label, char8* fmt, va_list args); // TODO?
		[LinkName("igBulletText")]
		public static extern void BulletText(char8* fmt, ...); // shortcut for Bullet()+Text()
		//[LinkName("igBulletTextV")]
		//public static extern void BulletTextV(char8* fmt, va_list args); // TODO?

		// Widgets: Main
		// - Most widgets return true when the value has been changed or when pressed/selected
		// - You may also use one of the many IsItemXXX functions (e.g. IsItemActive, IsItemHovered, etc.) to query widget state.
		[LinkName("igButton")]
		public static extern bool Button(char8* label, Vec2 size = default); // button
		[LinkName("igSmallButton")]
		public static extern bool SmallButton(char8* label); // button with FramePadding=(0,0) to easily embed within text
		[LinkName("igInvisibleButton")]
		public static extern bool InvisibleButton(char8* str_id, Vec2 size = float[](1, 1)); // button behavior without the visuals, frequently useful to build custom behaviors using the public api (along with IsItemActive, IsItemHovered, etc.)
		[LinkName("igArrowButton")]
		public static extern bool ArrowButton(char8* str_id, Dir dir); // square button with an arrow shape
		[LinkName("igImage")]
		public static extern void Image(TextureID user_texture_id, Vec2 size, Vec2 uv0 = default, Vec2 uv1 = float[](1,1), Vec4 tint_col = float[](1,1,1,1), Vec4 border_col = default);
		[LinkName("igImageButton")]
		public static extern bool ImageButton(TextureID user_texture_id, Vec2 size, Vec2 uv0 = default,  Vec2 uv1 = float[](1,1), int32 frame_padding = -1, Vec4 bg_col = default, Vec4 tint_col = float[](1,1,1,1)); // <0 frame_padding uses default frame padding settings. 0 for no padding
		[LinkName("igCheckbox")]
		public static extern bool Checkbox(char8* label, bool* v);
		[LinkName("igCheckboxFlags")]
		public static extern bool CheckboxFlags(char8* label, uint32* flags, uint32 flags_value);
		[LinkName("igRadioButton")]
		public static extern bool RadioButton(char8* label, bool active); // use with e.g. if (RadioButton("one", my_value==1)) { my_value = 1; }
		[LinkName("igRadioButton")]
		public static extern bool RadioButton(char8* label, int32* v, int32 v_button); // shortcut to handle the above pattern when value is an integer
		[LinkName("igProgressBar")]
		public static extern void ProgressBar(float fraction, Vec2 size_arg = float[](-1,0), char8* overlay = null);
		[LinkName("igBullet")]
		public static extern void Bullet(); // draw a small circle and keep the cursor on the same line. advance cursor x position by GetTreeNodeToLabelSpacing(), same distance that TreeNode() uses

		// Widgets: Combo Box
		// - The BeginCombo()/EndCombo() api allows you to manage your contents and selection state however you want it, by creating e.g. Selectable() items.
		// - The old Combo() api are helpers over BeginCombo()/EndCombo() which are kept available for convenience purpose.
		[LinkName("igBeginCombo")]
		public static extern bool BeginCombo(char8* label, char8* preview_value, ComboFlags flags = 0);
		[LinkName("igEndCombo")]
		public static extern void EndCombo(); // only call EndCombo() if BeginCombo() returns true!
		[LinkName("igComboStr_arr")]
		public static extern bool Combo(char8* label, int* current_item, char8*[] items, int32 items_count, int32 popup_max_height_in_items = -1);
		[LinkName("igComboStr")]
		public static extern bool Combo(char8* label, int* current_item, char8* items_separated_by_zeros, int32 popup_max_height_in_items = -1); // Separate items with \0 within a string, end item-list with \0\0. e.g. "One\0Two\0Three\0"
		[LinkName("igComboFnPtr")]
		public static extern bool Combo(char8* label, int* current_item, function bool(void* data, int32 idx, char8** out_text) items_getter, void* data, int32 items_count, int32 popup_max_height_in_items = -1);

		// Widgets: Drags
		// - CTRL+Click on any drag box to turn them into an input box. Manually input values aren't clamped and can go off-bounds.
		// - For all the Float2/Float3/Float4/Int2/Int3/Int4 versions of every functions, note that a 'float v[X]' function argument is the same as 'float* v', the array syntax is just a way to document the number of elements that are expected to be accessible. You can pass address of your first element out of a contiguous set, e.g. &myvector.x
		// - Adjust format string to decorate the value with a prefix, a suffix, or adapt the editing and display precision e.g. "%.3f" -> 1.234; "%5.2f secs" -> 01.23 secs; "Biscuit: %.0f" -> Biscuit: 1; etc.
		// - Speed are per-pixel of mouse movement (v_speed=0.2f: mouse needs to move by 5 pixels to increase value by 1). For gamepad/keyboard navigation, minimum speed is Max(v_speed, minimum_step_at_given_precision).
		// - Use v_min < v_max to clamp edits to given limits. Note that CTRL+Click manual input can override those limits.
		// - Use v_max = FLT_MAX / INT_MAX etc to avoid clamping to a maximum, same with v_min = -FLT_MAX / INT_MIN to avoid clamping to a minimum.
		// - Use v_min > v_max to lock edits.
		[LinkName("igDragFloat")]
		public static extern bool DragFloat(char8* label, float* v, float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, char8* format = "%.3f", float power = 1.0f); // If v_min >= v_max we have no bound
		[LinkName("igDragFloat2")]
		public static extern bool DragFloat2(char8* label, float[2] v, float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, char8* format = "%.3f", float power = 1.0f);
		[LinkName("igDragFloat3")]
		public static extern bool DragFloat3(char8* label, float[3] v, float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, char8* format = "%.3f", float power = 1.0f);
		[LinkName("igDragFloat4")]
		public static extern bool DragFloat4(char8* label, float[4] v, float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, char8* format = "%.3f", float power = 1.0f);
		[LinkName("igDragFloatRange2")]
		public static extern bool DragFloatRange2(char8* label, float* v_current_min, float* v_current_max, float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, char8* format = "%.3f", char8* format_max = null, float power = 1.0f);
		[LinkName("igDragInt")]
		public static extern bool DragInt(char8* label, int* v, float v_speed = 1.0f, int32 v_min = 0, int32 v_max = 0, char8* format = "%d"); // If v_min >= v_max we have no bound
		[LinkName("igDragInt2")]
		public static extern bool DragInt2(char8* label, int[2] v, float v_speed = 1.0f, int32 v_min = 0, int32 v_max = 0, char8* format = "%d");
		[LinkName("igDragInt3")]
		public static extern bool DragInt3(char8* label, int[3] v, float v_speed = 1.0f, int32 v_min = 0, int32 v_max = 0, char8* format = "%d");
		[LinkName("igDragInt4")]
		public static extern bool DragInt4(char8* label, int[4] v, float v_speed = 1.0f, int32 v_min = 0, int32 v_max = 0, char8* format = "%d");
		[LinkName("igDragIntRange2")]
		public static extern bool DragIntRange2(char8* label, int* v_current_min, int* v_current_max, float v_speed = 1.0f, int32 v_min = 0, int32 v_max = 0, char8* format = "%d", char8* format_max = null);
		[LinkName("igDragScalar")]
		public static extern bool DragScalar(char8* label, DataType data_type, void* p_data, float v_speed, void* p_min = null, void* p_max = null, char8* format = null, float power = 1.0f);
		[LinkName("igDragScalarN")]
		public static extern bool DragScalarN(char8* label, DataType data_type, void* p_data, int32 components, float v_speed, void* p_min = null, void* p_max = null, char8* format = null, float power = 1.0f);

		// Widgets: Sliders
		// - CTRL+Click on any slider to turn them into an input box. Manually input values aren't clamped and can go off-bounds.
		// - Adjust format string to decorate the value with a prefix, a suffix, or adapt the editing and display precision e.g. "%.3f" -> 1.234; "%5.2f secs" -> 01.23 secs; "Biscuit: %.0f" -> Biscuit: 1; etc.
		[LinkName("igSliderFloat")]
		public static extern bool SliderFloat(char8* label, float* v, float v_min, float v_max, char8* format = "%.3f", float power = 1.0f); // adjust format to decorate the value with a prefix or a suffix for in-slider labels or unit display. Use power!=1.0 for power curve sliders
		[LinkName("igSliderFloat2")]
		public static extern bool SliderFloat2(char8* label, float[2] v, float v_min, float v_max, char8* format = "%.3f", float power = 1.0f);
		[LinkName("igSliderFloat3")]
		public static extern bool SliderFloat3(char8* label, float[3] v, float v_min, float v_max, char8* format = "%.3f", float power = 1.0f);
		[LinkName("igSliderFloat4")]
		public static extern bool SliderFloat4(char8* label, float[4] v, float v_min, float v_max, char8* format = "%.3f", float power = 1.0f);
		[LinkName("igSliderAngle")]
		public static extern bool SliderAngle(char8* label, float* v_rad, float v_degrees_min = -360.0f, float v_degrees_max = 360.0f, char8* format = "%.0f deg");
		[LinkName("igSliderInt")]
		public static extern bool SliderInt(char8* label, int* v, int32 v_min, int32 v_max, char8* format = "%d");
		[LinkName("igSliderInt2")]
		public static extern bool SliderInt2(char8* label, int[2] v, int32 v_min, int32 v_max, char8* format = "%d");
		[LinkName("igSliderInt3")]
		public static extern bool SliderInt3(char8* label, int[3] v, int32 v_min, int32 v_max, char8* format = "%d");
		[LinkName("igSliderInt4")]
		public static extern bool SliderInt4(char8* label, int[4] v, int32 v_min, int32 v_max, char8* format = "%d");
		[LinkName("igSliderScalar")]
		public static extern bool SliderScalar(char8* label, DataType data_type, void* p_data, void* p_min, void* p_max, char8* format = null, float power = 1.0f);
		[LinkName("igSliderScalarN")]
		public static extern bool SliderScalarN(char8* label, DataType data_type, void* p_data, int32 components, void* p_min, void* p_max, char8* format = null, float power = 1.0f);
		[LinkName("igVSliderFloat")]
		public static extern bool VSliderFloat(char8* label, Vec2 size, float* v, float v_min, float v_max, char8* format = "%.3f", float power = 1.0f);
		[LinkName("igVSliderInt")]
		public static extern bool VSliderInt(char8* label, Vec2 size, int* v, int32 v_min, int32 v_max, char8* format = "%d");
		[LinkName("igVSliderScalar")]
		public static extern bool VSliderScalar(char8* label, Vec2 size, DataType data_type, void* p_data, void* p_min, void* p_max, char8* format = null, float power = 1.0f);

		// Widgets: Input with Keyboard
		// - If you want to use InputText() with std::string or any custom dynamic string type, see misc/cpp/imgui_stdlib.h and comments in imgui_demo.cpp.
		// - Most of the InputTextFlags flags are only useful for InputText() and not for InputFloatX, InputIntX, InputDouble etc.
		[LinkName("igInputText")]
		public static extern bool InputText(char8* label, char8* buf, size_t buf_size, InputTextFlags flags = 0, InputTextCallback callback = null, void* user_data = null);
		[LinkName("igInputTextMultiline")]
		public static extern bool InputTextMultiline(char8* label, char8* buf, size_t buf_size, Vec2 size = default, InputTextFlags flags = 0, InputTextCallback callback = null, void* user_data = null);
		[LinkName("igInputTextWithHint")]
		public static extern bool InputTextWithHint(char8* label, char8* hint, char8* buf, size_t buf_size, InputTextFlags flags = 0, InputTextCallback callback = null, void* user_data = null);
		[LinkName("igInputFloat")]
		public static extern bool InputFloat(char8* label, float* v, float step = 0.0f, float step_fast = 0.0f, char8* format = "%.3f", InputTextFlags flags = 0);
		[LinkName("igInputFloat2")]
		public static extern bool InputFloat2(char8* label, float[2] v, char8* format = "%.3f", InputTextFlags flags = 0);
		[LinkName("igInputFloat3")]
		public static extern bool InputFloat3(char8* label, float[3] v, char8* format = "%.3f", InputTextFlags flags = 0);
		[LinkName("igInputFloat4")]
		public static extern bool InputFloat4(char8* label, float[4] v, char8* format = "%.3f", InputTextFlags flags = 0);
		[LinkName("igInputInt")]
		public static extern bool InputInt(char8* label, int* v, int32 step = 1, int32 step_fast = 100, InputTextFlags flags = 0);
		[LinkName("igInputInt2")]
		public static extern bool InputInt2(char8* label, int[2] v, InputTextFlags flags = 0);
		[LinkName("igInputInt3")]
		public static extern bool InputInt3(char8* label, int[3] v, InputTextFlags flags = 0);
		[LinkName("igInputInt4")]
		public static extern bool InputInt4(char8* label, int[4] v, InputTextFlags flags = 0);
		[LinkName("igInputDouble")]
		public static extern bool InputDouble(char8* label, double* v, double step = 0.0, double step_fast = 0.0, char8* format = "%.6f", InputTextFlags flags = 0);
		[LinkName("igInputScalar")]
		public static extern bool InputScalar(char8* label, DataType data_type, void* p_data, void* p_step = null, void* p_step_fast = null, char8* format = null, InputTextFlags flags = 0);
		[LinkName("igInputScalarN")]
		public static extern bool InputScalarN(char8* label, DataType data_type, void* p_data, int32 components, void* p_step = null, void* p_step_fast = null, char8* format = null, InputTextFlags flags = 0);

		// Widgets: Color Editor/Picker (tip: the ColorEdit* functions have a little colored preview square that can be left-clicked to open a picker, and right-clicked to open an option menu.)
		// - Note that in C++ a 'float v[X]' function argument is the _same_ as 'float* v', the array syntax is just a way to document the number of elements that are expected to be accessible.
		// - You can pass the address of a first float element out of a contiguous structure, e.g. &myvector.x
		[LinkName("igColorEdit3")]
		public static extern bool ColorEdit3(char8* label, float[3] col, ColorEditFlags flags = 0);
		[LinkName("igColorEdit4")]
		public static extern bool ColorEdit4(char8* label, float[4] col, ColorEditFlags flags = 0);
		[LinkName("igColorPicker3")]
		public static extern bool ColorPicker3(char8* label, float[3] col, ColorEditFlags flags = 0);
		[LinkName("igColorPicker4")]
		public static extern bool ColorPicker4(char8* label, float[4] col, ColorEditFlags flags = 0, float* ref_col = null);
		[LinkName("igColorButton")]
		public static extern bool ColorButton(char8* desc_id, Vec4 col, ColorEditFlags flags = 0, Vec2 size = default); // display a colored square/button, hover for details, return true when pressed.
		[LinkName("igSetColorEditOptions")]
		public static extern void SetColorEditOptions(ColorEditFlags flags); // initialize current options (generally on application startup) if you want to select a default format, picker type, etc. User will be able to change many settings, unless you pass the _NoOptions flag to your calls.

		// Widgets: Trees
		// - TreeNode functions return true when the node is open, in which case you need to also call TreePop() when you are finished displaying the tree node contents.
		[LinkName("igTreeNodeStr")]
		public static extern bool TreeNode(char8* label);
		[LinkName("igTreeNodeStrStr")]
		public static extern bool TreeNode(char8* str_id, char8* fmt, ...); // helper variation to easily decorelate the id from the displayed string. Read the FAQ about why and how to use ID. to align arbitrary text at the same level as a TreeNode() you can use Bullet().
		[LinkName("igTreeNodePtr")]
		public static extern bool TreeNode(void* ptr_id, char8* fmt, ...); // "
		//[LinkName("igTreeNodeV")]
		//public static extern bool TreeNodeV(char8* str_id, char8* fmt, va_list args); // TODO?
		//[LinkName("igTreeNodeV")]
		//public static extern bool TreeNodeV(void* ptr_id, char8* fmt, va_list args); // TODO?
		[LinkName("igTreeNodeExStr")]
		public static extern bool TreeNodeEx(char8* label, TreeNodeFlags flags = 0);
		[LinkName("igTreeNodeExStrStr")]
		public static extern bool TreeNodeEx(char8* str_id, TreeNodeFlags flags, char8* fmt, ...); 
		[LinkName("igTreeNodeExPtr")]
		public static extern bool TreeNodeEx(void* ptr_id, TreeNodeFlags flags, char8* fmt, ...); 
		//[LinkName("igTreeNodeExV")]
		//public static extern bool TreeNodeExV(char8* str_id, TreeNodeFlags flags, char8* fmt, va_list args); // TODO?
		//[LinkName("igTreeNodeExV")]
		//public static extern bool TreeNodeExV(void* ptr_id, TreeNodeFlags flags, char8* fmt, va_list args); // TODO?
		[LinkName("igTreePushStr")]
		public static extern void TreePush(char8* str_id); // ~ Indent()+PushId(). Already called by TreeNode() when returning true, but you can call TreePush/TreePop yourself if desired.
		[LinkName("igTreePushPtr")]
		public static extern void TreePush(void* ptr_id = null); // "
		[LinkName("igTreePop")]
		public static extern void TreePop(); // ~ Unindent()+PopId()
		[LinkName("igGetTreeNodeToLabelSpacing")]
		public static extern float GetTreeNodeToLabelSpacing(); // horizontal distance preceding label when using TreeNode*() or Bullet() == (g.FontSize + style.FramePadding.x*2) for a regular unframed TreeNode
		[LinkName("igCollapsingHeaderTreeNodeFlags")]
		public static extern bool CollapsingHeader(char8* label, TreeNodeFlags flags = 0); // if returning 'true' the header is open. doesn't indent nor push on ID stack. user doesn't have to call TreePop().
		[LinkName("igCollapsingHeaderBoolPtr")]
		public static extern bool CollapsingHeader(char8* label, bool* p_open, TreeNodeFlags flags = 0); // when 'p_open' isn't null, display an additional small close button on upper right of the header
		[LinkName("igSetNextItemOpen")]
		public static extern void SetNextItemOpen(bool is_open, Cond cond = 0); // set next TreeNode/CollapsingHeader open state.

		// Widgets: Selectables
		// - A selectable highlights when hovered, and can display another color when selected.
		// - Neighbors selectable extend their highlight bounds in order to leave no gap between them. This is so a series of selected Selectable appear contiguous.
		[LinkName("igSelectableBool")]
		public static extern bool Selectable(char8* label, bool selected = false, SelectableFlags flags = 0, Vec2 size = default); // "bool selected" carry the selection state (read-only). Selectable() is clicked is returns true so you can modify your selection state. size.x==0.0: use remaining width, size.x>0.0: specify width. size.y==0.0: use label height, size.y>0.0: specify height
		[LinkName("igSelectableBoolPtr")]
		public static extern bool Selectable(char8* label, bool* p_selected, SelectableFlags flags = 0, Vec2 size = default); // "bool* p_selected" point to the selection state (read-write), as a convenient helper.

		// Widgets: List Boxes
		// - FIXME: To be consistent with all the newer API, ListBoxHeader/ListBoxFooter should in reality be called BeginListBox/EndListBox. Will rename them.
		[LinkName("igListBoxStr_arr")]
		public static extern bool ListBox(char8* label, int* current_item, char8*[] items, int32 items_count, int32 height_in_items = -1);
		[LinkName("igListBoxFnPtr")]
		public static extern bool ListBox(char8* label, int* current_item, function bool (void* data, int32 idx, char8** out_text) items_getter, void* data, int32 items_count, int32 height_in_items = -1);
		[LinkName("igListBoxHeaderVec2")]
		public static extern bool ListBoxHeader(char8* label, Vec2 size = default); // use if you want to reimplement ListBox() will custom data or interactions. if the function return true, you can output elements then call ListBoxFooter() afterwards.
		[LinkName("igListBoxHeaderInt")]
		public static extern bool ListBoxHeader(char8* label, int32 items_count, int32 height_in_items = -1); // "
		[LinkName("igListBoxFooter")]
		public static extern void ListBoxFooter(); // terminate the scrolling region. only call ListBoxFooter() if ListBoxHeader() returned true!

		// Widgets: Data Plotting
		[LinkName("igPlotLinesFloatPtr")]
		public static extern void PlotLines(char8* label, float* values, int32 values_count, int32 values_offset = 0, char8* overlay_text = null, float scale_min = Float.MaxValue, float scale_max = Float.MaxValue, Vec2 graph_size = default, int32 stride = sizeof(float));
		[LinkName("igPlotLinesFnPtr")]
		public static extern void PlotLines(char8* label, function float(void* data, int32 idx) values_getter, void* data, int32 values_count, int32 values_offset = 0, char8* overlay_text = null, float scale_min = Float.MaxValue, float scale_max = Float.MaxValue, Vec2 graph_size = default);
		[LinkName("igPlotHistogramFloatPtr")]
		public static extern void PlotHistogram(char8* label, float* values, int32 values_count, int32 values_offset = 0, char8* overlay_text = null, float scale_min = Float.MaxValue, float scale_max = Float.MaxValue, Vec2 graph_size = default, int32 stride = sizeof(float));
		[LinkName("igPlotHistogramFnPtr")]
		public static extern void PlotHistogram(char8* label, function float* (void* data, int32 idx) values_getter, void* data, int32 values_count, int32 values_offset = 0, char8* overlay_text = null, float scale_min = Float.MaxValue, float scale_max = Float.MaxValue, Vec2 graph_size = default);

		// Widgets: Value() Helpers.
		// - Those are merely shortcut to calling Text() with a format string. Output single value in "name: value" format (tip: freely declare more in your code to handle your types. you can add functions to the ImGui namespace)
		[LinkName("igValueBool")]
		public static extern void Value(char8* prefix, bool b);
		[LinkName("igValueInt")]
		public static extern void Value(char8* prefix, int32 v);
		[LinkName("igValueUint")]
		public static extern void Value(char8* prefix, uint32 v);
		[LinkName("igValueFloat")]
		public static extern void Value(char8* prefix, float v, char8* float_format = null);

		// Widgets: Menus
		// - Use BeginMenuBar() on a window ImGuiWindowFlags_MenuBar to append to its menu bar.
		// - Use BeginMainMenuBar() to create a menu bar at the top of the screen and append to it.
		// - Use BeginMenu() to create a menu. You can call BeginMenu() multiple time with the same identifier to append more items to it.
		[LinkName("igBeginMenuBar")]
		public static extern bool BeginMenuBar(); // append to menu-bar of current window (requires ImGuiWindowFlags_MenuBar flag set on parent window).
		[LinkName("igEndMenuBar")]
		public static extern void EndMenuBar(); // only call EndMenuBar() if BeginMenuBar() returns true!
		[LinkName("igBeginMainMenuBar")]
		public static extern bool BeginMainMenuBar(); // create and append to a full screen menu-bar.
		[LinkName("igEndMainMenuBar")]
		public static extern void EndMainMenuBar(); // only call EndMainMenuBar() if BeginMainMenuBar() returns true!
		[LinkName("igBeginMenu")]
		public static extern bool BeginMenu(char8* label, bool enabled = true); // create a sub-menu entry. only call EndMenu() if this returns true!
		[LinkName("igEndMenu")]
		public static extern void EndMenu(); // only call EndMenu() if BeginMenu() returns true!
		[LinkName("igMenuItemBool")]
		public static extern bool MenuItem(char8* label, char8* shortcut = null, bool selected = false, bool enabled = true); // return true when activated. shortcuts are displayed for convenience but not processed by ImGui at the moment
		[LinkName("igMenuItemBoolPtr")]
		public static extern bool MenuItem(char8* label, char8* shortcut, bool* p_selected, bool enabled = true); // return true when activated + toggle (*p_selected) if p_selected != null

		// Tooltips
		// - Tooltip are windows following the mouse which do not take focus away.
		[LinkName("igBeginTooltip")]
		public static extern void BeginTooltip(); // begin/append a tooltip window. to create full-featured tooltip (with any kind of items).
		[LinkName("igEndTooltip")]
		public static extern void EndTooltip();
		[LinkName("igSetTooltip")]
		public static extern void SetTooltip(char8* fmt, ...); // set a text-only tooltip, typically use with ImGui::IsItemHovered(). override any previous call to SetTooltip().
		//[LinkName("igSetTooltipV")]
		//public static extern void SetTooltipV(char8* fmt, va_list args); // TODO?

		// Popups, Modals
		// The properties of popups windows are:
		// - They block normal mouse hovering detection outside them. (*)
		// - Unless modal, they can be closed by clicking anywhere outside them, or by pressing ESCAPE.
		// - Their visibility state (~bool) is held internally by imgui instead of being held by the programmer as we are used to with regular Begin() calls.
		//   User can manipulate the visibility state by calling OpenPopup().
		// - We default to use the right mouse (ImGuiMouseButton_Right=1) for the Popup Context functions.
		// (*) You can use IsItemHovered(ImGuiHoveredFlags_AllowWhenBlockedByPopup) to bypass it and detect hovering even when normally blocked by a popup.
		// Those three properties are connected. The library needs to hold their visibility state because it can close popups at any time.
		[LinkName("igOpenPopup")]
		public static extern void OpenPopup(char8* str_id); // call to mark popup as open (don't call every frame!). popups are closed when user click outside, or if CloseCurrentPopup() is called within a BeginPopup()/EndPopup() block. By default, Selectable()/MenuItem() are calling CloseCurrentPopup(). Popup identifiers are relative to the current ID-stack (so OpenPopup and BeginPopup needs to be at the same level).
		[LinkName("igBeginPopup")]
		public static extern bool BeginPopup(char8* str_id, WindowFlags flags = 0); // return true if the popup is open, and you can start outputting to it. only call EndPopup() if BeginPopup() returns true!
		[LinkName("igBeginPopupContextItem")]
		public static extern bool BeginPopupContextItem(char8* str_id = null, MouseButton mouse_button = (MouseButton)1); // helper to open and begin popup when clicked on last item. if you can pass a null str_id only if the previous item had an id. If you want to use that on a non-interactive item such as Text() you need to pass in an explicit ID here. read comments in .cpp!
		[LinkName("igBeginPopupContextWindow")]
		public static extern bool BeginPopupContextWindow(char8* str_id = null, MouseButton mouse_button = (MouseButton)1, bool also_over_items = true); // helper to open and begin popup when clicked on current window.
		[LinkName("igBeginPopupContextVoid")]
		public static extern bool BeginPopupContextVoid(char8* str_id = null, MouseButton mouse_button = (MouseButton)1); // helper to open and begin popup when clicked in void (where there are no imgui windows).
		[LinkName("igBeginPopupModal")]
		public static extern bool BeginPopupModal(char8* name, bool* p_open = null, WindowFlags flags = 0); // modal dialog (regular window with title bar, block interactions behind the modal window, can't close the modal window by clicking outside)
		[LinkName("igEndPopup")]
		public static extern void EndPopup(); // only call EndPopup() if BeginPopupXXX() returns true!
		[LinkName("igOpenPopupOnItemClick")]
		public static extern bool OpenPopupOnItemClick(char8* str_id = null, MouseButton mouse_button = (MouseButton)1); // helper to open popup when clicked on last item (note: actually triggers on the mouse _released_ event to be consistent with popup behaviors). return true when just opened.
		[LinkName("igIsPopupOpen")]
		public static extern bool IsPopupOpen(char8* str_id); // return true if the popup is open at the current begin-ed level of the popup stack.
		[LinkName("igCloseCurrentPopup")]
		public static extern void CloseCurrentPopup(); // close the popup we have begin-ed into. clicking on a MenuItem or Selectable automatically close the current popup.

		// Columns
		// - You can also use SameLine(pos_x) to mimic simplified columns.
		// - The columns API is work-in-progress and rather lacking (columns are arguably the worst part of dear imgui at the moment!)
		// - There is a maximum of 64 columns.
		// - Currently working on new 'Tables' api which will replace columns around Q2 2020 (see GitHub #2957).
		[LinkName("igColumns")]
		public static extern void Columns(int count = 1, char8* id = null, bool border = true);
		[LinkName("igNextColumn")]
		public static extern void NextColumn(); // next column, defaults to current row or next row if the current row is finished
		[LinkName("igGetColumnIndex")]
		public static extern int32 GetColumnIndex(); // get current column index
		[LinkName("igGetColumnWidth")]
		public static extern float GetColumnWidth(int column_index = -1); // get column width (in pixels). pass -1 to use current column
		[LinkName("igSetColumnWidth")]
		public static extern void SetColumnWidth(int column_index, float width); // set column width (in pixels). pass -1 to use current column
		[LinkName("igGetColumnOffset")]
		public static extern float GetColumnOffset(int column_index = -1); // get position of column line (in pixels, from the left side of the contents region). pass -1 to use current column, otherwise 0..GetColumnsCount() inclusive. column 0 is typically 0.0f
		[LinkName("igSetColumnOffset")]
		public static extern void SetColumnOffset(int column_index, float offset_x); // set position of column line (in pixels, from the left side of the contents region). pass -1 to use current column
		[LinkName("igGetColumnsCount")]
		public static extern int32 GetColumnsCount();

		// Tab Bars, Tabs
		[LinkName("igBeginTabBar")]
		public static extern bool BeginTabBar(char8* str_id, TabBarFlags flags = 0); // create and append into a TabBar
		[LinkName("igEndTabBar")]
		public static extern void EndTabBar(); // only call EndTabBar() if BeginTabBar() returns true!
		[LinkName("igBeginTabItem")]
		public static extern bool BeginTabItem(char8* label, bool* p_open = null, TabBarFlags flags = 0);// create a Tab. Returns true if the Tab is selected.
		[LinkName("igEndTabItem")]
		public static extern void EndTabItem(); // only call EndTabItem() if BeginTabItem() returns true!
		[LinkName("igSetTabItemClosed")]
		public static extern void SetTabItemClosed(char8* tab_or_docked_window_label); // notify TabBar or Docking system of a closed tab/window ahead (useful to reduce visual flicker on reorderable tab bars). For tab-bar: call after BeginTabBar() and before Tab submissions. Otherwise call with a window name.

		// Logging/Capture
		// - All text output from the interface can be captured into tty/file/clipboard. By default, tree nodes are automatically opened during logging.
		[LinkName("igLogToTTY")]
		public static extern void LogToTTY(int auto_open_depth = -1); // start logging to tty (stdout)
		[LinkName("igLogToFile")]
		public static extern void LogToFile(int auto_open_depth = -1, char8* filename = null); // start logging to file
		[LinkName("igLogToClipboard")]
		public static extern void LogToClipboard(int auto_open_depth = -1); // start logging to OS clipboard
		[LinkName("igLogFinish")]
		public static extern void LogFinish(); // stop logging (close file, etc.)
		[LinkName("igLogButtons")]
		public static extern void LogButtons(); // helper to display buttons for logging to tty/file/clipboard
		[LinkName("igLogText")]
		public static extern void LogText(char8* fmt, ...); // pass text data straight to log (without being displayed)

		// Drag and Drop
		// - [BETA API] API may evolve!
		[LinkName("igBeginDragDropSource")]
		public static extern bool BeginDragDropSource(DragDropFlags flags = 0); // call when the current item is active. If this return true, you can call SetDragDropPayload() + EndDragDropSource()
		[LinkName("igSetDragDropPayload")]
		public static extern bool SetDragDropPayload(char8* type, void* data, size_t sz, Cond cond = 0); // type is a user defined string of maximum 32 characters. Strings starting with '_' are reserved for dear imgui internal types. Data is copied and held by imgui.
		[LinkName("igEndDragDropSource")]
		public static extern void EndDragDropSource(); // only call EndDragDropSource() if BeginDragDropSource() returns true!
		[LinkName("igBeginDragDropTarget")]
		public static extern bool BeginDragDropTarget(); // call after submitting an item that may receive a payload. If this returns true, you can call AcceptDragDropPayload() + EndDragDropTarget()
		[LinkName("igAcceptDragDropPayload")]
		public static extern readonly Payload* AcceptDragDropPayload(char8* type, DragDropFlags flags = 0); // accept contents of a given type. If ImGuiDragDropFlags_AcceptBeforeDelivery is set you can peek into the payload before the mouse button is released.
		[LinkName("igEndDragDropTarget")]
		public static extern void EndDragDropTarget(); // only call EndDragDropTarget() if BeginDragDropTarget() returns true!
		[LinkName("igGetDragDropPayload")]
		public static extern readonly Payload* GetDragDropPayload(); // peek directly into the current payload from anywhere. may return null. use ImGuiPayload::IsDataType() to test for the payload type.

		// Clipping
		[LinkName("igPushClipRect")]
		public static extern void PushClipRect(Vec2 clip_rect_min, Vec2 clip_rect_max, bool intersect_with_current_clip_rect);
		[LinkName("igPopClipRect")]
		public static extern void PopClipRect();

		// Focus, Activation
		// - Prefer using "SetItemDefaultFocus()" over "if (IsWindowAppearing()) SetScrollHereY()" when applicable to signify "this is the default item"
		[LinkName("igSetItemDefaultFocus")]
		public static extern void SetItemDefaultFocus(); // make last item the default focused item of a window.
		[LinkName("igSetKeyboardFocusHere")]
		public static extern void SetKeyboardFocusHere(int offset = 0); // focus keyboard on the next widget. Use positive 'offset' to access sub components of a multiple component widget. Use -1 to access previous widget.

		// Item/Widgets Utilities
		// - Most of the functions are referring to the last/previous item we submitted.
		// - See Demo Window under "Widgets->Querying Status" for an interactive visualization of most of those functions.
		[LinkName("igIsItemHovered")]
		public static extern bool IsItemHovered(HoveredFlags flags = 0); // is the last item hovered? (and usable, aka not blocked by a popup, etc.). See ImGuiHoveredFlags for more options.
		[LinkName("igIsItemActive")]
		public static extern bool IsItemActive(); // is the last item active? (e.g. button being held, text field being edited. This will continuously return true while holding mouse button on an item. Items that don't interact will always return false)
		[LinkName("igIsItemFocused")]
		public static extern bool IsItemFocused(); // is the last item focused for keyboard/gamepad navigation?
		[LinkName("igIsItemClicked")]
		public static extern bool IsItemClicked(MouseButton mouse_button = 0); // is the last item clicked? (e.g. button/node just clicked on) == IsMouseClicked(mouse_button) && IsItemHovered()
		[LinkName("igIsItemVisible")]
		public static extern bool IsItemVisible(); // is the last item visible? (items may be out of sight because of clipping/scrolling)
		[LinkName("igIsItemEdited")]
		public static extern bool IsItemEdited(); // did the last item modify its underlying value this frame? or was pressed? This is generally the same as the "bool" return value of many widgets.
		[LinkName("igIsItemActivated")]
		public static extern bool IsItemActivated(); // was the last item just made active (item was previously inactive).
		[LinkName("igIsItemDeactivated")]
		public static extern bool IsItemDeactivated(); // was the last item just made inactive (item was previously active). Useful for Undo/Redo patterns with widgets that requires continuous editing.
		[LinkName("igIsItemDeactivatedAfterEdit")]
		public static extern bool IsItemDeactivatedAfterEdit(); // was the last item just made inactive and made a value change when it was active? (e.g. Slider/Drag moved). Useful for Undo/Redo patterns with widgets that requires continuous editing. Note that you may get false positives (some widgets such as Combo()/ListBox()/Selectable() will return true even when clicking an already selected item).
		[LinkName("igIsItemToggledOpen")]
		public static extern bool IsItemToggledOpen(); // was the last item open state toggled? set by TreeNode().
		[LinkName("igIsAnyItemHovered")]
		public static extern bool IsAnyItemHovered(); // is any item hovered?
		[LinkName("igIsAnyItemActive")]
		public static extern bool IsAnyItemActive(); // is any item active?
		[LinkName("igIsAnyItemFocused")]
		public static extern bool IsAnyItemFocused(); // is any item focused?
		[LinkName("igGetItemRectMin")]
		public static extern void GetItemRectMinImpl(Vec2* pOut); // get upper-left bounding rectangle of the last item (screen space)
		public static Vec2 GetItemRectMin() { return CallGetter<Vec2>(=> GetItemRectMinImpl); }
		[LinkName("igGetItemRectMax")]
		public static extern void GetItemRectMaxImpl(Vec2* pOut); // get lower-right bounding rectangle of the last item (screen space)
		public static Vec2 GetItemRectMax() { return CallGetter<Vec2>(=> GetItemRectMaxImpl); }
		[LinkName("igGetItemRectSize")]
		public static extern void GetItemRectSizeImpl(Vec2* pOut); // get size of last item
		public static Vec2 GetItemRectSize() { return CallGetter<Vec2>(=> GetItemRectSizeImpl); }
		[LinkName("igSetItemAllowOverlap")]
		public static extern void SetItemAllowOverlap(); // allow last item to be overlapped by a subsequent item. sometimes useful with invisible buttons, selectables, etc. to catch unused area.

		// Miscellaneous Utilities
		[LinkName("igIsRectVisibleNil")]
		public static extern bool IsRectVisible(Vec2 size); // test if rectangle (of given size, starting from cursor position) is visible / not clipped.
		[LinkName("igIsRectVisibleVec2")]
		public static extern bool IsRectVisible(Vec2 rect_min, Vec2 rect_max); // test if rectangle (in screen space) is visible / not clipped. to perform coarse clipping on user's side.
		[LinkName("igGetTime")]
		public static extern double GetTime(); // get global imgui time. incremented by io.DeltaTime every frame.
		[LinkName("igGetFrameCount")]
		public static extern int32 GetFrameCount(); // get global imgui frame count. incremented by 1 every frame.
		[LinkName("igGetBackgroundDrawList")]
		public static extern DrawList* GetBackgroundDrawList(); // this draw list will be the first rendering one. Useful to quickly draw shapes/text behind dear imgui contents.
		[LinkName("igGetForegroundDrawList")]
		public static extern DrawList* GetForegroundDrawList(); // this draw list will be the last rendered one. Useful to quickly draw shapes/text over dear imgui contents.
		[LinkName("igGetDrawListSharedData")]
		public static extern DrawListSharedData* GetDrawListSharedData(); // you may use this when creating your own ImDrawList instances.
		[LinkName("igGetStyleColorName")]
		public static extern readonly char8* GetStyleColorName(Col idx); // get a string corresponding to the enum value (for display, saving, etc.).
		[LinkName("igSetStateStorage")]
		public static extern void SetStateStorage(Storage* storage); // replace current window storage with our own (if you want to manipulate it yourself, typically clear subsection of it)
		[LinkName("igGetStateStorage")]
		public static extern Storage* GetStateStorage();
		[LinkName("igCalcListClipping")]
		public static extern void CalcListClipping(int items_count, float items_height, int* out_items_display_start, int* out_items_display_end); // calculate coarse clipping for large list of evenly sized items. Prefer using the ImGuiListClipper higher-level helper if you can.
		[LinkName("igBeginChildFrame")]
		public static extern bool BeginChildFrame(ImGuiID id, Vec2 size, WindowFlags flags = 0); // helper to create a child window / scrolling region that looks like a normal widget frame
		[LinkName("igEndChildFrame")]
		public static extern void EndChildFrame(); // always call EndChildFrame() regardless of BeginChildFrame() return values (which indicates a collapsed/clipped window)

		// Text Utilities
		[LinkName("igCalcTextSize")]
		private static extern void CalcTextSizeImpl(Vec2* pOut, char8* text, char8* text_end = null, bool hide_text_after_double_hash = false, float wrap_width = -1.0f);
		public static Vec2 CalcTextSize(char8* text, char8* text_end = null, bool hide_text_after_double_hash = false, float wrap_width = -1.0f)
		{
			Vec2 result = ?;
			CalcTextSizeImpl(&result, text, text_end, hide_text_after_double_hash, wrap_width);
			return result;
		}

		// Color Utilities
		[LinkName("igColorConvertU32ToFloat4")]
		private static extern void ColorConvertU32ToFloat4Impl(Vec4* pOut, uint32 _in);
		public static Vec4 ColorConvertU32ToFloat4(uint32 _in)
		{
			Vec4 result = ?;
			ColorConvertU32ToFloat4Impl(&result, _in);
			return result;
		}
		[LinkName("igColorConvertFloat4ToU32")]
		public static extern uint32 ColorConvertFloat4ToU32(Vec4 _in);
		[LinkName("igColorConvertRGBtoHSV")]
		public static extern void ColorConvertRGBtoHSV(float r, float g, float b, out float out_h, out float out_s, out float out_v);
		[LinkName("igColorConvertHSVtoRGB")]
		public static extern void ColorConvertHSVtoRGB(float h, float s, float v, out float out_r, out float out_g, out float out_b);

		// Inputs Utilities: Keyboard
		// - For 'int user_key_index' you can use your own indices/enums according to how your backend/engine stored them in io.KeysDown[].
		// - We don't know the meaning of those value. You can use GetKeyIndex() to map a ImGuiKey_ value into the user index.
		[LinkName("igGetKeyIndex")]
		public static extern int32 GetKeyIndex(Key imgui_key); // map ImGuiKey_* values into user's key index. == io.KeyMap[key]
		[LinkName("igIsKeyDown")]
		public static extern bool IsKeyDown(int user_key_index); // is key being held. == io.KeysDown[user_key_index].
		[LinkName("igIsKeyPressed")]
		public static extern bool IsKeyPressed(int user_key_index, bool _repeat = true); // was key pressed (went from !Down to Down)? if repeat=true, uses io.KeyRepeatDelay / KeyRepeatRate
		[LinkName("igIsKeyReleased")]
		public static extern bool IsKeyReleased(int user_key_index); // was key released (went from Down to !Down)?
		[LinkName("igGetKeyPressedAmount")]
		public static extern int32 GetKeyPressedAmount(int key_index, float repeat_delay, float rate); // uses provided repeat rate/delay. return a count, most often 0 or 1 but might be >1 if RepeatRate is small enough that DeltaTime > RepeatRate
		[LinkName("igCaptureKeyboardFromApp")]
		public static extern void CaptureKeyboardFromApp(bool want_capture_keyboard_value = true); // attention: misleading name! manually override io.WantCaptureKeyboard flag next frame (said flag is entirely left for your application to handle). e.g. force capture keyboard when your widget is being hovered. This is equivalent to setting "io.WantCaptureKeyboard = want_capture_keyboard_value"; after the next NewFrame() call.

		// Inputs Utilities: Mouse
		// - To refer to a mouse button, you may use named enums in your code e.g. ImGuiMouseButton_Left, ImGuiMouseButton_Right.
		// - You can also use regular integer: it is forever guaranteed that 0=Left, 1=Right, 2=Middle.
		// - Dragging operations are only reported after mouse has moved a certain distance away from the initial clicking position (see 'lock_threshold' and 'io.MouseDraggingThreshold')
		[LinkName("igIsMouseDown")]
		public static extern bool IsMouseDown(MouseButton button); // is mouse button held?
		[LinkName("igIsMouseClicked")]
		public static extern bool IsMouseClicked(MouseButton button, bool _repeat = false); // did mouse button clicked? (went from !Down to Down)
		[LinkName("igIsMouseReleased")]
		public static extern bool IsMouseReleased(MouseButton button); // did mouse button released? (went from Down to !Down)
		[LinkName("igIsMouseDoubleClicked")]
		public static extern bool IsMouseDoubleClicked(MouseButton button); // did mouse button double-clicked? a double-click returns false in IsMouseClicked(). uses io.MouseDoubleClickTime.
		[LinkName("igIsMouseHoveringRect")]
		public static extern bool IsMouseHoveringRect(Vec2 r_min, Vec2 r_max, bool clip = true);// is mouse hovering given bounding rect (in screen space). clipped by current clipping settings, but disregarding of other consideration of focus/window ordering/popup-block.
		[LinkName("igIsMousePosValid")]
		public static extern bool IsMousePosValid(Vec2* mouse_pos = null); // by convention we use (-FLT_MAX,-FLT_MAX) to denote that there is no mouse available
		[LinkName("igIsAnyMouseDown")]
		public static extern bool IsAnyMouseDown(); // is any mouse button held?
		[LinkName("igGetMousePos")]
		public static extern void GetMousePosImpl(Vec2* pOut); // shortcut to ImGui::GetIO().MousePos provided by user, to be consistent with other calls
		public static Vec2 GetMousePos() { return CallGetter<Vec2>(=> GetMousePosImpl); }
		[LinkName("igGetMousePosOnOpeningCurrentPopup")]
		public static extern void GetMousePosOnOpeningCurrentPopupImpl(Vec2* pOut); // retrieve mouse position at the time of opening popup we have BeginPopup() into (helper to avoid user backing that value themselves)
		public static Vec2 GetMousePosOnOpeningCurrentPopup() { return CallGetter<Vec2>(=> GetMousePosOnOpeningCurrentPopupImpl); }
		[LinkName("igIsMouseDragging")]
		public static extern bool IsMouseDragging(MouseButton button, float lock_threshold = -1.0f); // is mouse dragging? (if lock_threshold < -1.0f, uses io.MouseDraggingThreshold)
		[LinkName("igGetMouseDragDelta")]
		public static extern void GetMouseDragDeltaImpl(Vec2* pOut, MouseButton button = 0, float lock_threshold = -1.0f); // return the delta from the initial clicking position while the mouse button is pressed or was just released. This is locked and return 0.0f until the mouse moves past a distance threshold at least once (if lock_threshold < -1.0f, uses io.MouseDraggingThreshold)
		public static Vec2 GetMouseDragDelta(MouseButton button = 0, float lock_threshold = -1.0f)
		{
			Vec2 result = ?;
			GetMouseDragDeltaImpl(&result, button, lock_threshold);
			return result;
		}
		[LinkName("igResetMouseDragDelta")]
		public static extern void ResetMouseDragDelta(MouseButton button = 0); //
		[LinkName("igGetMouseCursor")]
		public static extern MouseCursor GetMouseCursor(); // get desired cursor type, reset in ImGui::NewFrame(), this is updated during the frame. valid before Render(). If you use software rendering by setting io.MouseDrawCursor ImGui will render those for you
		[LinkName("igSetMouseCursor")]
		public static extern void SetMouseCursor(MouseCursor cursor_type); // set desired cursor type
		[LinkName("igCaptureMouseFromApp")]
		public static extern void CaptureMouseFromApp(bool want_capture_mouse_value = true); // attention: misleading name! manually override io.WantCaptureMouse flag next frame (said flag is entirely left for your application to handle). This is equivalent to setting "io.WantCaptureMouse = want_capture_mouse_value;" after the next NewFrame() call.

		// Clipboard Utilities
		// - Also see the LogToClipboard() function to capture GUI into clipboard, or easily output text data to the clipboard.
		[LinkName("igGetClipboardText")]
		public static extern readonly char8* GetClipboardText();
		[LinkName("igSetClipboardText")]
		public static extern void SetClipboardText(char8* text);

		// Settings/.Ini Utilities
		// - The disk functions are automatically called if io.IniFilename != null (default is "imgui.ini").
		// - Set io.IniFilename to null to load/save manually. Read io.WantSaveIniSettings description about handling .ini saving manually.
		[LinkName("igLoadIniSettingsFromDisk")]
		public static extern void LoadIniSettingsFromDisk(char8* ini_filename); // call after CreateContext() and before the first call to NewFrame(). NewFrame() automatically calls LoadIniSettingsFromDisk(io.IniFilename).
		[LinkName("igLoadIniSettingsFromMemory")]
		public static extern void LoadIniSettingsFromMemory(char8* ini_data, size_t ini_size=0); // call after CreateContext() and before the first call to NewFrame() to provide .ini data from your own data source.
		[LinkName("igSaveIniSettingsToDisk")]
		public static extern void SaveIniSettingsToDisk(char8* ini_filename); // this is automatically called (if io.IniFilename is not empty) a few seconds after any modification that should be reflected in the .ini file (and also by DestroyContext).
		[LinkName("igSaveIniSettingsToMemory")]
		public static extern readonly char8* SaveIniSettingsToMemory(uint* out_ini_size = null); // return a zero-terminated string with the .ini data which you can save by your own mean. call when io.WantSaveIniSettings is set, then save data by your own mean and clear io.WantSaveIniSettings.

		// Debug Utilities
		[LinkName("igDebugCheckVersionAndDataLayout")]
		public static extern bool DebugCheckVersionAndDataLayout(char8* version_str, size_t sz_io, size_t sz_style, size_t sz_vec2, size_t sz_vec4, size_t sz_drawvert, size_t sz_drawidx); // This is called by IMGUI_CHECKVERSION() macro.

		// Memory Allocators
		// - All those functions are not reliant on the current context.
		// - If you reload the contents of imgui.cpp at runtime, you may need to call SetCurrentContext() + SetAllocatorFunctions() again because we use global storage for those.
		[LinkName("igSetAllocatorFunctions")]
		public static extern void SetAllocatorFunctions(function void* (size_t sz, void* user_data) alloc_func, function void (void* ptr, void* user_data) free_func, void* user_data = null);
		[LinkName("igMemAlloc")]
		public static extern void* MemAlloc(size_t size);
		[LinkName("igMemFree")]
		public static extern void MemFree(void* ptr);
	}
}