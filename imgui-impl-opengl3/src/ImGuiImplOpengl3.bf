using System;

namespace imgui_beef {
	static class ImGuiImplOpengl3 {
		// dear imgui: Renderer for modern OpenGL with shaders / programmatic pipeline
		// - Desktop GL: 2.x 3.x 4.x
		// - Embedded GL: ES 2.0 (WebGL 1.0), ES 3.0 (WebGL 2.0)
		// This needs to be used along with a Platform Binding (e.g. GLFW, SDL, Win32, custom..)

		// Implemented features:
		//  [X] Renderer: User texture binding. Use 'GLuint' OpenGL texture identifier as void*/ImTextureID. Read the FAQ about ImTextureID!
		//  [x] Renderer: Desktop GL only: Support for large meshes (64k+ vertices) with 16-bit indices.

		// You can copy and use unmodified imgui_impl_* files in your project. See main.cpp for an example of using this.
		// If you are new to dear imgui, read examples/README.txt and read the documentation at the top of imgui.cpp.
		// https://github.com/ocornut/imgui

		// CHANGELOG
		// (minor and older changes stripped away, please see git history for details)
		//  2020-05-08: OpenGL: Made default GLSL version 150 (instead of 130) on OSX.
		//  2020-04-21: OpenGL: Fixed handling of glClipControl(GL_UPPER_LEFT) by inverting projection matrix.
		//  2020-04-12: OpenGL: Fixed context version check mistakenly testing for 4.0+ instead of 3.2+ to enable ImGuiBackendFlags_RendererHasVtxOffset.
		//  2020-03-24: OpenGL: Added support for glbinding 2.x OpenGL loader.
		//  2020-01-07: OpenGL: Added support for glbinding 3.x OpenGL loader.
		//  2019-10-25: OpenGL: Using a combination of GL define and runtime GL version to decide whether to use glDrawElementsBaseVertex(). Fix building with pre-3.2 GL loaders.
		//  2019-09-22: OpenGL: Detect default GL loader using __has_include compiler facility.
		//  2019-09-16: OpenGL: Tweak initialization code to allow application calling ImGui_ImplOpenGL3_CreateFontsTexture() before the first NewFrame() call.
		//  2019-05-29: OpenGL: Desktop GL only: Added support for large mesh (64K+ vertices), enable ImGuiBackendFlags_RendererHasVtxOffset flag.
		//  2019-04-30: OpenGL: Added support for special ImDrawCallback_ResetRenderState callback to reset render state.
		//  2019-03-29: OpenGL: Not calling glBindBuffer more than necessary in the render loop.
		//  2019-03-15: OpenGL: Added a dummy GL call + comments in ImGui_ImplOpenGL3_Init() to detect uninitialized GL function loaders early.
		//  2019-03-03: OpenGL: Fix support for ES 2.0 (WebGL 1.0).
		//  2019-02-20: OpenGL: Fix for OSX not supporting OpenGL 4.5, we don't try to read GL_CLIP_ORIGIN even if defined by the headers/loader.
		//  2019-02-11: OpenGL: Projecting clipping rectangles correctly using draw_data.FramebufferScale to allow multi-viewports for retina display.
		//  2019-02-01: OpenGL: Using GLSL 410 shaders for any version over 410 (e.g. 430, 450).
		//  2018-11-30: Misc: Setting up io.BackendRendererName so it can be displayed in the About Window.
		//  2018-11-13: OpenGL: Support for GL 4.5's glClipControl(GL_UPPER_LEFT) / GL_CLIP_ORIGIN.
		//  2018-08-29: OpenGL: Added support for more OpenGL loaders: glew and glad, with comments indicative that any loader can be used.
		//  2018-08-09: OpenGL: Default to OpenGL ES 3 on iOS and Android. GLSL version default to "#version 300 ES".
		//  2018-07-30: OpenGL: Support for GLSL 300 ES and 410 core. Fixes for Emscripten compilation.
		//  2018-07-10: OpenGL: Support for more GLSL versions (based on the GLSL version string). Added error output when shaders fail to compile/link.
		//  2018-06-08: Misc: Extracted imgui_impl_opengl3.cpp/.h away from the old combined GLFW/SDL+OpenGL3 examples.
		//  2018-06-08: OpenGL: Use draw_data.DisplayPos and draw_data.DisplaySize to setup projection matrix and clipping rectangle.
		//  2018-05-25: OpenGL: Removed unnecessary backup/restore of GL_ELEMENT_ARRAY_BUFFER_BINDING since this is part of the VAO state.
		//  2018-05-14: OpenGL: Making the call to glBindSampler() optional so 3.2 context won't fail if the function is a NULL pointer.
		//  2018-03-06: OpenGL: Added const char* glsl_version parameter to ImGui_ImplOpenGL3_Init() so user can override the GLSL version e.g. "#version 150".
		//  2018-02-23: OpenGL: Create the VAO in the render function so the setup can more easily be used with multiple shared GL context.
		//  2018-02-16: Misc: Obsoleted the io.RenderDrawListsFn callback and exposed ImGui_ImplSdlGL3_RenderDrawData() in the .h file so you can call it yourself.
		//  2018-01-07: OpenGL: Changed GLSL shader version from 330 to 150.
		//  2017-09-01: OpenGL: Save and restore current bound sampler. Save and restore current polygon mode.
		//  2017-05-01: OpenGL: Fixed save and restore of current blend func state.
		//  2017-05-01: OpenGL: Fixed save and restore of current GL_ACTIVE_TEXTURE.
		//  2016-09-05: OpenGL: Fixed save and restore of current scissor rectangle.
		//  2016-07-29: OpenGL: Explicitly setting GL_UNPACK_ROW_LENGTH to reduce issues because SDL changes it. (#752)

		//----------------------------------------
		// OpenGL    GLSL      GLSL
		// version   version   string
		//----------------------------------------
		//  2.0       110       "#version 110"
		//  2.1       120       "#version 120"
		//  3.0       130       "#version 130"
		//  3.1       140       "#version 140"
		//  3.2       150       "#version 150"
		//  3.3       330       "#version 330 core"
		//  4.0       400       "#version 400 core"
		//  4.1       410       "#version 410 core"
		//  4.2       420       "#version 410 core"
		//  4.3       430       "#version 430 core"
		//  ES 2.0    100       "#version 100"      = WebGL 1.0
		//  ES 3.0    300       "#version 300 es"   = WebGL 2.0
		//----------------------------------------

		private typealias GL = ImGuiImplOpengl3GL; // will be replace by 'using static' in next release when beefy fixed it

		private static uint         g_GlVersion = 0;              // Extracted at runtime using GL_MAJOR_VERSION, GL_MINOR_VERSION queries (e.g. 320 for GL 3.2)
		private static String       g_GlslVersionString = "";     // Specified by user or detected based on compile time GL settings.
		private static uint         g_FontTexture = 0;
		private static uint         g_ShaderHandle = 0;
		private static uint         g_VertHandle = 0;
		private static uint         g_FragHandle = 0;
		private static int          g_AttribLocationTex = 0;	  // Uniforms location
		private static int          g_AttribLocationProjMtx = 0;  
		private static int          g_AttribLocationVtxPos = 0;	  // Vertex attributes location
		private static int          g_AttribLocationVtxUV = 0;
		private static int          g_AttribLocationVtxColor = 0; 
		private static uint         g_VboHandle = 0;
		private static uint         g_ElementsHandle = 0;
							    
		public static bool Init(ImGuiImplOpengl3GL.GetProcAddressFunc getProcAddress, StringView glsl_version_ = default) {
			StringView glsl_version = glsl_version_;

			ImGuiImplOpengl3GL.Init(getProcAddress);

			// Query for GL version (e.g. 320 for GL 3.2)
#if !IMGUI_IMPL_OPENGL_ES2
			int major = 0;
			int minor = 0;
			GL.glGetIntegerv(GL.GL_MAJOR_VERSION, &major);
			GL.glGetIntegerv(GL.GL_MINOR_VERSION, &minor);
			g_GlVersion = (uint) (major * 100 + minor * 10);
#else
			g_GlVersion = 200; // GLES 2
#endif

			// Setup back-end capabilities flags
			ref ImGui.IO io = ref ImGui.GetIO();
			io.BackendRendererName = "imgui_impl_opengl3";
#if IMGUI_IMPL_OPENGL_MAY_HAVE_VTX_OFFSET
			if (g_GlVersion >= 320)
			    io.BackendFlags |= .RendererHasVtxOffset;  // We can honor the ImDrawCmd::VtxOffset field, allowing for large meshes.
#endif

			// Store GLSL version string so we can refer to it later in case we recreate shaders.
			// Note: GLSL version is NOT the same as GL version. Leave this to NULL if unsure.
#if IMGUI_IMPL_OPENGL_ES2
			if (glsl_version.Length == 0)
			    glsl_version = "#version 100";
#elif IMGUI_IMPL_OPENGL_ES3
			if (glsl_version.Length == 0)
			    glsl_version = "#version 300 es";
#elif __APPLE__
			if (glsl_version.Length == 0)
			    glsl_version = "#version 150";
#else
			if (glsl_version.Length == 0) glsl_version = "#version 130";
#endif
			g_GlslVersionString = new String(glsl_version);

			return true;
		}

		public static void Shutdown() {
			DestroyDeviceObjects();
			delete g_GlslVersionString;
		}

		public static void NewFrame() {
			if (g_ShaderHandle == 0) CreateDeviceObjects();
		}

		private static void SetupRenderState(ImGui.DrawData* draw_data, int fb_width, int fb_height, uint vertex_array_object) {
		    // Setup render state: alpha-blending enabled, no face culling, no depth testing, scissor enabled, polygon fill
		    GL.glEnable(GL.GL_BLEND);
		    GL.glBlendEquation(GL.GL_FUNC_ADD);
		    GL.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);
		    GL.glDisable(GL.GL_CULL_FACE);
		    GL.glDisable(GL.GL_DEPTH_TEST);
		    GL.glEnable(GL.GL_SCISSOR_TEST);
#if GL_POLYGON_MODE
		    GL.glPolygonMode(GL.GL_FRONT_AND_BACK, GL.GL_FILL);
#endif

		    // Support for GL 4.5 rarely used glClipControl(GL_UPPER_LEFT)
		    bool clip_origin_lower_left = true;
#if GL_CLIP_ORIGIN && !__APPLE__
		    uint current_clip_origin = 0;
			GL.glGetIntegerv(GL.GL_CLIP_ORIGIN, (int*) &current_clip_origin);
		    if (current_clip_origin == GL.GL_UPPER_LEFT) clip_origin_lower_left = false;
#endif

		    // Setup viewport, orthographic projection matrix
		    // Our visible imgui space lies from draw_data.DisplayPos (top left) to draw_data.DisplayPos+data_data.DisplaySize (bottom right). DisplayPos is (0,0) for single viewport apps.
		    GL.glViewport(0, 0, (int) fb_width, (int) fb_height);
		    float L = draw_data.DisplayPos.x;
		    float R = draw_data.DisplayPos.x + draw_data.DisplaySize.x;
		    float T = draw_data.DisplayPos.y;
		    float B = draw_data.DisplayPos.y + draw_data.DisplaySize.y;
		    if (!clip_origin_lower_left) { // Swap top and bottom if origin is upper left
				float tmp = T;
				T = B;
				B = tmp;
			}

		    float[4][4] ortho_projection = .(
		        .(2.0f/(R-L),   0.0f,         0.0f,   0.0f),
		        .(0.0f,         2.0f/(T-B),   0.0f,   0.0f),
		        .(0.0f,         0.0f,        -1.0f,   0.0f),
		        .((R+L)/(L-R),  (T+B)/(B-T),  0.0f,   1.0f)
		    );

		    GL.glUseProgram(g_ShaderHandle);
		    GL.glUniform1i(g_AttribLocationTex, 0);
		    GL.glUniformMatrix4fv(g_AttribLocationProjMtx, 1, GL.GL_FALSE, &ortho_projection[0][0]);
#if GL_SAMPLER_BINDING
		    GL.glBindSampler(0, 0); // We use combined texture/sampler state. Applications using GL 3.3 may set that otherwise.
#endif

		    (void) vertex_array_object;
#if !IMGUI_IMPL_OPENGL_ES2
		    GL.glBindVertexArray(vertex_array_object);
#endif

		    // Bind vertex/index buffers and setup attributes for ImDrawVert
		    GL.glBindBuffer(GL.GL_ARRAY_BUFFER, g_VboHandle);
		    GL.glBindBuffer(GL.GL_ELEMENT_ARRAY_BUFFER, g_ElementsHandle);
		    GL.glEnableVertexAttribArray((.) g_AttribLocationVtxPos);
		    GL.glEnableVertexAttribArray((.) g_AttribLocationVtxUV);
		    GL.glEnableVertexAttribArray((.) g_AttribLocationVtxColor);
		    GL.glVertexAttribPointer((.) g_AttribLocationVtxPos,   2, GL.GL_FLOAT,         GL.GL_FALSE, sizeof(ImGui.DrawVert), (void*) 0);
			int stride = sizeof(ImGui.Vec2);
		    GL.glVertexAttribPointer((.) g_AttribLocationVtxUV,    2, GL.GL_FLOAT,         GL.GL_FALSE, sizeof(ImGui.DrawVert), (void*) stride);
			stride += sizeof(ImGui.Vec2);
		    GL.glVertexAttribPointer((.) g_AttribLocationVtxColor, 4, GL.GL_UNSIGNED_BYTE, GL.GL_TRUE,  sizeof(ImGui.DrawVert), (void*) stride);
		}

		public static void RenderDrawData(ImGui.DrawData* draw_data) {
			// Avoid rendering when minimized, scale coordinates for retina displays (screen coordinates != framebuffer coordinates)
			int fb_width = (int)(draw_data.DisplaySize.x * draw_data.FramebufferScale.x);
			int fb_height = (int)(draw_data.DisplaySize.y * draw_data.FramebufferScale.y);
			if (fb_width <= 0 || fb_height <= 0)
			    return;

			// Backup GL state
			uint last_active_texture = 0; GL.glGetIntegerv(GL.GL_ACTIVE_TEXTURE, (int*) &last_active_texture);
			GL.glActiveTexture(GL.GL_TEXTURE0);
			int last_program = 0; GL.glGetIntegerv(GL.GL_CURRENT_PROGRAM, &last_program);
			int last_texture = 0; GL.glGetIntegerv(GL.GL_TEXTURE_BINDING_2D, &last_texture);
#if GL_SAMPLER_BINDING
			int last_sampler = 0; GL.glGetIntegerv(GL.GL_SAMPLER_BINDING, &last_sampler);
#endif
			int last_array_buffer = 0; GL.glGetIntegerv(GL.GL_ARRAY_BUFFER_BINDING, &last_array_buffer);
#if !IMGUI_IMPL_OPENGL_ES2
			int last_vertex_array_object = 0; GL.glGetIntegerv(GL.GL_VERTEX_ARRAY_BINDING, &last_vertex_array_object);
#endif
#if !GL_POLYGON_MODE
			int[2] last_polygon_mode = .(0,); GL.glGetIntegerv(GL.GL_POLYGON_MODE, &last_polygon_mode);
#endif
			int[4] last_viewport = .(0,); GL.glGetIntegerv(GL.GL_VIEWPORT, &last_viewport);
			int[4] last_scissor_box = .(0,); GL.glGetIntegerv(GL.GL_SCISSOR_BOX, &last_scissor_box);
			uint last_blend_src_rgb = 0; GL.glGetIntegerv(GL.GL_BLEND_SRC_RGB, (int*) &last_blend_src_rgb);
			uint last_blend_dst_rgb = 0; GL.glGetIntegerv(GL.GL_BLEND_DST_RGB, (int*) &last_blend_dst_rgb);
			uint last_blend_src_alpha = 0; GL.glGetIntegerv(GL.GL_BLEND_SRC_ALPHA, (int*) &last_blend_src_alpha);
			uint last_blend_dst_alpha = 0; GL.glGetIntegerv(GL.GL_BLEND_DST_ALPHA, (int*) &last_blend_dst_alpha);
			uint last_blend_equation_rgb = 0; GL.glGetIntegerv(GL.GL_BLEND_EQUATION_RGB, (int*) &last_blend_equation_rgb);
			uint last_blend_equation_alpha = 0; GL.glGetIntegerv(GL.GL_BLEND_EQUATION_ALPHA, (int*) &last_blend_equation_alpha);
			uint8 last_enable_blend = GL.glIsEnabled(GL.GL_BLEND);
			uint8 last_enable_cull_face = GL.glIsEnabled(GL.GL_CULL_FACE);
			uint8 last_enable_depth_test = GL.glIsEnabled(GL.GL_DEPTH_TEST);
			uint8 last_enable_scissor_test = GL.glIsEnabled(GL.GL_SCISSOR_TEST);

			// Setup desired GL state
			// Recreate the VAO every time (this is to easily allow multiple GL contexts to be rendered to. VAO are not shared among GL contexts)
			// The renderer would actually work without any VAO bound, but then our VertexAttrib calls would overwrite the default one currently bound.
			uint vertex_array_object = 0;
#if IMGUI_IMPL_OPENGL_ES2
			GL.glGenVertexArrays(1, &vertex_array_object);
#endif
			SetupRenderState(draw_data, fb_width, fb_height, vertex_array_object);

			// Will project scissor/clipping rectangles into framebuffer space
			ImGui.Vec2 clip_off = draw_data.DisplayPos;         // (0,0) unless using multi-viewports
			ImGui.Vec2 clip_scale = draw_data.FramebufferScale; // (1,1) unless using retina display which are often (2,2)

			// Render command lists
			for (int n < draw_data.CmdListsCount){
			    ImGui.DrawList* cmd_list = draw_data.CmdLists[n];

			    // Upload vertex/index buffers
			    GL.glBufferData(GL.GL_ARRAY_BUFFER, (int) cmd_list.VtxBuffer.Size * sizeof(ImGui.DrawVert), (void*) cmd_list.VtxBuffer.Data, GL.GL_STREAM_DRAW);
			    GL.glBufferData(GL.GL_ELEMENT_ARRAY_BUFFER, (int) cmd_list.IdxBuffer.Size * sizeof(ImGui.DrawIdx), (void*) cmd_list.IdxBuffer.Data, GL.GL_STREAM_DRAW);

			    for (int cmd_i < cmd_list.CmdBuffer.Size) {
			        ImGui.DrawCmd* pcmd = &cmd_list.CmdBuffer.Data[cmd_i];
			        if (pcmd.UserCallback != null) {
			            // User callback, registered via ImDrawList::AddCallback()
			            // (ImDrawCallback_ResetRenderState is a special callback value used by the user to request the renderer to reset render state.)
			            if (&pcmd.UserCallback == ImGui.DrawCallback_ResetRenderState)
			                SetupRenderState(draw_data, fb_width, fb_height, vertex_array_object);
			            else
			                pcmd.UserCallback(cmd_list, pcmd);
			        } else {
			            // Project scissor/clipping rectangles into framebuffer space
			            ImGui.Vec4 clip_rect;
			            clip_rect.x = (pcmd.ClipRect.x - clip_off.x) * clip_scale.x;
			            clip_rect.y = (pcmd.ClipRect.y - clip_off.y) * clip_scale.y;
			            clip_rect.z = (pcmd.ClipRect.z - clip_off.x) * clip_scale.x;
			            clip_rect.w = (pcmd.ClipRect.w - clip_off.y) * clip_scale.y;

			            if (clip_rect.x < fb_width && clip_rect.y < fb_height && clip_rect.z >= 0.0f && clip_rect.w >= 0.0f)
			            {
			                // Apply scissor/clipping rectangle
			                GL.glScissor((int)clip_rect.x, (int)(fb_height - clip_rect.w), (int)(clip_rect.z - clip_rect.x), (int)(clip_rect.w - clip_rect.y));

			                // Bind texture, Draw
			                GL.glBindTexture(GL.GL_TEXTURE_2D, (uint) pcmd.TextureId);
#if IMGUI_IMPL_OPENGL_MAY_HAVE_VTX_OFFSET
			                if (g_GlVersion >= 320) {
								int a = pcmd.IdxOffset * sizeof(ImGui.DrawIdx);
			                    GL.glDrawElementsBaseVertex(GL.GL_TRIANGLES, (int) pcmd.ElemCount, sizeof(ImGui.DrawIdx) == 2 ? GL.GL_UNSIGNED_SHORT : GL.GL_UNSIGNED_INT, (void*) a, (int)pcmd.VtxOffset);
			                } else
#endif
							{
								int a = pcmd.IdxOffset * sizeof(ImGui.DrawIdx);
			                	GL.glDrawElements(GL.GL_TRIANGLES, (int)pcmd.ElemCount, sizeof(ImGui.DrawIdx) == 2 ? GL.GL_UNSIGNED_SHORT : GL.GL_UNSIGNED_INT, (void*) a);
							}
			            }
			        }
			    }
			}

			// Destroy the temporary VAO
#if !IMGUI_IMPL_OPENGL_ES2
			GL.glDeleteVertexArrays(1, &vertex_array_object);
#endif

			// Restore modified GL state
			GL.glUseProgram((.) last_program);
			GL.glBindTexture(GL.GL_TEXTURE_2D, (.) last_texture);
#if GL_SAMPLER_BINDING
			GL.glBindSampler(0, (.) last_sampler);
#endif
			GL.glActiveTexture(last_active_texture);
#if !IMGUI_IMPL_OPENGL_ES2
			GL.glBindVertexArray((.) last_vertex_array_object);
#endif
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, (.) last_array_buffer);
			GL.glBlendEquationSeparate(last_blend_equation_rgb, last_blend_equation_alpha);
			GL.glBlendFuncSeparate((.) last_blend_src_rgb, (.) last_blend_dst_rgb, (.) last_blend_src_alpha, (.) last_blend_dst_alpha);
			if (last_enable_blend == GL.GL_TRUE) GL.glEnable(GL.GL_BLEND); else GL.glDisable(GL.GL_BLEND);
			if (last_enable_cull_face == GL.GL_TRUE) GL.glEnable(GL.GL_CULL_FACE); else GL.glDisable(GL.GL_CULL_FACE);
			if (last_enable_depth_test == GL.GL_TRUE) GL.glEnable(GL.GL_DEPTH_TEST); else GL.glDisable(GL.GL_DEPTH_TEST);
			if (last_enable_scissor_test == GL.GL_TRUE) GL.glEnable(GL.GL_SCISSOR_TEST); else GL.glDisable(GL.GL_SCISSOR_TEST);
#if GL_POLYGON_MODE
			GL.glPolygonMode(GL.GL_FRONT_AND_BACK, (uint) last_polygon_mode[0]);
#endif
			GL.glViewport(last_viewport[0], last_viewport[1], (int) last_viewport[2], (int) last_viewport[3]);
			GL.glScissor(last_scissor_box[0], last_scissor_box[1], (int) last_scissor_box[2], (int) last_scissor_box[3]);
		}

		public static bool CreateFontsTexture() {
			// Build texture atlas
			ref ImGui.IO io = ref ImGui.GetIO();
			uint8* pixels;
			int32 width, height;
			io.Fonts.GetTexDataAsRGBA32(out pixels, out width, out height);   // Load as RGBA 32-bit (75% of the memory is wasted, but default font is so small) because it is more likely to be compatible with user's existing shaders. If your ImTextureId represent a higher-level concept than just a GL texture id, consider calling GetTexDataAsAlpha8() instead to save on GPU memory.

			// Upload texture to graphics system
			int last_texture = 0;
			GL.glGetIntegerv(GL.GL_TEXTURE_BINDING_2D, &last_texture);
			GL.glGenTextures(1, &g_FontTexture);
			GL.glBindTexture(GL.GL_TEXTURE_2D, g_FontTexture);
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR);
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR);
#if GL_UNPACK_ROW_LENGTH
			GL.glPixelStorei(GL.GL_UNPACK_ROW_LENGTH, 0);
#endif
			GL.glTexImage2D(GL.GL_TEXTURE_2D, 0, GL.GL_RGBA, width, height, 0, GL.GL_RGBA, GL.GL_UNSIGNED_BYTE, pixels);

			// Store our identifier
			io.Fonts.TexID = (ImGui.TextureID) g_FontTexture;

			// Restore state
			GL.glBindTexture(GL.GL_TEXTURE_2D, (.) last_texture);

			return true;
		}

		public static void DestroyFontsTexture() {
			if (g_FontTexture != 0) {
			    ref ImGui.IO io = ref ImGui.GetIO();
			    GL.glDeleteTextures(1, &g_FontTexture);
			    io.Fonts.TexID = (void*) 0;
			    g_FontTexture = 0;
			}
		}

		// If you get an error please report on github. You may try different GL context version or GLSL version. See GL<>GLSL version table at the top of this file.
		private static bool CheckShader(uint handle, StringView desc) {
		    int status = 0, log_length = 0;
		    GL.glGetShaderiv(handle, GL.GL_COMPILE_STATUS, &status);
		    GL.glGetShaderiv(handle, GL.GL_INFO_LOG_LENGTH, &log_length);
		    if (status == GL.GL_FALSE) Console.Error.WriteLine("ERROR: CreateDeviceObjects: failed to compile {}!", desc);
		    if (log_length > 1) {
				char8* msg = new char8[log_length]*;
				GL.glGetShaderInfoLog(handle, log_length, null, msg);
				Console.Error.WriteLine("{}", scope String(msg));
				delete msg;
		    }
		    return status == GL.GL_TRUE;
		}

		// If you get an error please report on GitHub. You may try different GL context version or GLSL version.
		private static bool CheckProgram(uint handle, StringView desc) {
		    int status = 0, log_length = 0;
		    GL.glGetProgramiv(handle, GL.GL_LINK_STATUS, &status);
		    GL.glGetProgramiv(handle, GL.GL_INFO_LOG_LENGTH, &log_length);
		    if (status == GL.GL_FALSE) Console.Error.WriteLine("ERROR: CreateDeviceObjects: failed to link {}! (with GLSL '{}')", desc, g_GlslVersionString);
		    if (log_length > 1) {
				char8* msg = new char8[log_length]*;
				GL.glGetProgramInfoLog(handle, log_length, null, msg);
				Console.Error.WriteLine("{}", scope String(msg));
				delete msg;
		    }
		    return status == GL.GL_TRUE;
		}

		public static bool CreateDeviceObjects() {
			// Backup GL state
			int last_texture = 0, last_array_buffer = 0;
			GL.glGetIntegerv(GL.GL_TEXTURE_BINDING_2D, &last_texture);
			GL.glGetIntegerv(GL.GL_ARRAY_BUFFER_BINDING, &last_array_buffer);
#if !IMGUI_IMPL_OPENGL_ES2
			int last_vertex_array = 0;
			GL.glGetIntegerv(GL.GL_VERTEX_ARRAY_BINDING, &last_vertex_array);
#endif

			// Parse GLSL version string
			int glsl_version = 130;
			int i = g_GlslVersionString.LastIndexOf(' ');
			glsl_version = int.Parse(.(g_GlslVersionString, i + 1, g_GlslVersionString.Length - i - 1));

			StringView vertex_shader_glsl_120 =
				"""
				uniform mat4 ProjMtx;
				attribute vec2 Position;
				attribute vec2 UV;
				attribute vec4 Color;
				varying vec2 Frag_UV;
				varying vec4 Frag_Color;
				void main()
				{
					Frag_UV = UV;
					Frag_Color = Color;
					gl_Position = ProjMtx * vec4(Position.xy,0,1);
				}
				""";

			StringView vertex_shader_glsl_130 =
				"""
				uniform mat4 ProjMtx;
				in vec2 Position;
				in vec2 UV;
				in vec4 Color;
				out vec2 Frag_UV;
				out vec4 Frag_Color;
				void main()
				{
					Frag_UV = UV;
					Frag_Color = Color;
					gl_Position = ProjMtx * vec4(Position.xy,0,1);
				}
				""";

			StringView vertex_shader_glsl_300_es =
				"""
				precision mediump float;
				layout (location = 0) in vec2 Position;
				layout (location = 1) in vec2 UV;
				layout (location = 2) in vec4 Color;
				uniform mat4 ProjMtx;
				out vec2 Frag_UV;
				out vec4 Frag_Color;
				void main()
				{
					Frag_UV = UV;
					Frag_Color = Color;
					gl_Position = ProjMtx * vec4(Position.xy,0,1);
				}
				""";

			StringView vertex_shader_glsl_410_core =
				"""
				layout (location = 0) in vec2 Position;
				layout (location = 1) in vec2 UV;
				layout (location = 2) in vec4 Color;
				uniform mat4 ProjMtx;
				out vec2 Frag_UV;
				out vec4 Frag_Color;
				void main()
				{
					Frag_UV = UV;
					Frag_Color = Color;
					gl_Position = ProjMtx * vec4(Position.xy,0,1);
				}
				""";

			StringView fragment_shader_glsl_120 =
				"""
				#ifdef GL_ES
					precision mediump float;
				#endif
				uniform sampler2D Texture;
				varying vec2 Frag_UV;
				varying vec4 Frag_Color;
				void main()
				{
					gl_FragColor = Frag_Color * texture2D(Texture, Frag_UV.st);
				}
				""";

			StringView fragment_shader_glsl_130 =
				"""
				uniform sampler2D Texture;
				in vec2 Frag_UV;
				in vec4 Frag_Color;
				out vec4 Out_Color;
				void main()
				{
					Out_Color = Frag_Color * texture(Texture, Frag_UV.st);
				}
				""";

			StringView fragment_shader_glsl_300_es =
				"""
				precision mediump float;
				uniform sampler2D Texture;
				in vec2 Frag_UV;
				in vec4 Frag_Color;
				layout (location = 0) out vec4 Out_Color;
				void main()
				{
					Out_Color = Frag_Color * texture(Texture, Frag_UV.st);
				}
				""";

			StringView fragment_shader_glsl_410_core =
				"""
				in vec2 Frag_UV;
				in vec4 Frag_Color;
				uniform sampler2D Texture;
				layout (location = 0) out vec4 Out_Color;
				void main()
				{
					Out_Color = Frag_Color * texture(Texture, Frag_UV.st);
				}
				""";

			// Select shaders matching our GLSL versions
			StringView* vertex_shader = null;
			StringView* fragment_shader = null;
			if (glsl_version < 130) {
			    vertex_shader = &vertex_shader_glsl_120;
			    fragment_shader = &fragment_shader_glsl_120;
			} else if (glsl_version >= 410) {
			    vertex_shader = &vertex_shader_glsl_410_core;
			    fragment_shader = &fragment_shader_glsl_410_core;
			} else if (glsl_version == 300) {
			    vertex_shader = &vertex_shader_glsl_300_es;
			    fragment_shader = &fragment_shader_glsl_300_es;
			} else {
			    vertex_shader = &vertex_shader_glsl_130;
			    fragment_shader = &fragment_shader_glsl_130;
			}

			// Create shaders
			String vertex_shader_with_version = new .(g_GlslVersionString);
			vertex_shader_with_version.Append("\n");
			vertex_shader_with_version.Append(*vertex_shader);
			char8* cstr = vertex_shader_with_version.CStr();
			g_VertHandle = GL.glCreateShader(GL.GL_VERTEX_SHADER);
			GL.glShaderSource(g_VertHandle, 2, &cstr, null);
			GL.glCompileShader(g_VertHandle);
			CheckShader(g_VertHandle, "vertex shader");
			delete vertex_shader_with_version;

			String fragment_shader_with_version = new .(g_GlslVersionString);
			fragment_shader_with_version.Append("\n");
			fragment_shader_with_version.Append(*fragment_shader);
			cstr = fragment_shader_with_version.CStr();
			g_FragHandle = GL.glCreateShader(GL.GL_FRAGMENT_SHADER);
			GL.glShaderSource(g_FragHandle, 2, &cstr, null);
			GL.glCompileShader(g_FragHandle);
			CheckShader(g_FragHandle, "fragment shader");
			delete fragment_shader_with_version;

			g_ShaderHandle = GL.glCreateProgram();
			GL.glAttachShader(g_ShaderHandle, g_VertHandle);
			GL.glAttachShader(g_ShaderHandle, g_FragHandle);
			GL.glLinkProgram(g_ShaderHandle);
			CheckProgram(g_ShaderHandle, "shader program");

			g_AttribLocationTex = GL.glGetUniformLocation(g_ShaderHandle, "Texture");
			g_AttribLocationProjMtx = GL.glGetUniformLocation(g_ShaderHandle, "ProjMtx");
			g_AttribLocationVtxPos = GL.glGetAttribLocation(g_ShaderHandle, "Position");
			g_AttribLocationVtxUV = GL.glGetAttribLocation(g_ShaderHandle, "UV");
			g_AttribLocationVtxColor = GL.glGetAttribLocation(g_ShaderHandle, "Color");

			// Create buffers
			GL.glGenBuffers(1, &g_VboHandle);
			GL.glGenBuffers(1, &g_ElementsHandle);

			CreateFontsTexture();

			// Restore modified GL state
			GL.glBindTexture(GL.GL_TEXTURE_2D, (.) last_texture);
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, (.) last_array_buffer);
#if !IMGUI_IMPL_OPENGL_ES2
			GL.glBindVertexArray((.) last_vertex_array);
#endif

			return true;
		}

		public static void DestroyDeviceObjects() {
			if (g_VboHandle != 0)        { GL.glDeleteBuffers(1, &g_VboHandle); g_VboHandle = 0; }
			if (g_ElementsHandle != 0)   { GL.glDeleteBuffers(1, &g_ElementsHandle); g_ElementsHandle = 0; }
			if (g_ShaderHandle != 0 && g_VertHandle != 0) { GL.glDetachShader(g_ShaderHandle, g_VertHandle); }
			if (g_ShaderHandle != 0 && g_FragHandle != 0) { GL.glDetachShader(g_ShaderHandle, g_FragHandle); }
			if (g_VertHandle != 0)       { GL.glDeleteShader(g_VertHandle); g_VertHandle = 0; }
			if (g_FragHandle != 0)       { GL.glDeleteShader(g_FragHandle); g_FragHandle = 0; }
			if (g_ShaderHandle != 0)     { GL.glDeleteProgram(g_ShaderHandle); g_ShaderHandle = 0; }

			DestroyFontsTexture();
		}
	}
}
