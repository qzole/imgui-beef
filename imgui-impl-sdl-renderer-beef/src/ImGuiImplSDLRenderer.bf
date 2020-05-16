using System;
using System.Collections;
using imgui_beef;
using SDL2;

namespace imgui_beef
{
	// A Beef port of https://github.com/Tyyppi77/imgui_sdl
	static class ImGuiImplSDLRenderer
	{
		static Device currentDevice = null;
		static Texture currentFontTexture = null;

		public static void Initialize(SDL.Renderer* renderer, int32 windowWidth, int32 windowHeight)
		{
			ref ImGui.IO io = ref ImGui.GetIO();
			io.DisplaySize.x = windowWidth;
			io.DisplaySize.y = windowHeight;

			ImGui.GetStyle().WindowRounding = 0.0f;
			ImGui.GetStyle().AntiAliasedFill = false;
			ImGui.GetStyle().AntiAliasedLines = false;

			// Loads the font texture.
			uint8* pixels;
			int32 width, height;
			io.Fonts.GetTexDataAsRGBA32(out pixels, out width,  out height);
			uint32 rmask = 0x000000ff, gmask = 0x0000ff00, bmask = 0x00ff0000, amask = 0xff000000;
			SDL.Surface* surface = SDL.CreateRGBSurfaceFrom((.)pixels, width, height, 32, 4 * width, rmask, gmask, bmask, amask);

			currentFontTexture = new Texture();
			currentFontTexture.surface = surface;
			currentFontTexture.source = SDL.CreateTextureFromSurface(renderer, surface);
			io.Fonts.TexID = (void*)currentFontTexture;

			currentDevice = new Device(renderer);
		}

		public static void Deinitialize()
		{
			// Frees up the memory of the font texture.
			//ref ImGui.IO io = ref ImGui.GetIO();
			//Texture texture = (.)io.Fonts.TexID;
			delete currentFontTexture;
			currentFontTexture = null;

			delete currentDevice;
			currentDevice = null;
		}

		public static void Render(ImGui.DrawData* drawData)
		{
			SDL.BlendMode blendMode;
			SDL.GetRenderDrawBlendMode(currentDevice.renderer, out blendMode);
			SDL.SetRenderDrawBlendMode(currentDevice.renderer, SDL.BlendMode.Blend);

			uint8 initialR, initialG, initialB, initialA;
			SDL.GetRenderDrawColor(currentDevice.renderer, out initialR, out initialG, out initialB, out initialA);

			bool initialClipEnabled = SDL.RenderIsClipEnabled(currentDevice.renderer);
			SDL.Rect initialClipRect;
			SDL.RenderGetClipRect(currentDevice.renderer, out initialClipRect);

			SDL.Texture* initialRenderTarget = SDL.GetRenderTarget(currentDevice.renderer);

			ref ImGui.IO io = ref ImGui.GetIO();

			for (int32 n = 0; n < drawData.CmdListsCount; ++n)
			{
				var commandList = drawData.CmdLists[n];
				var vertexBuffer = commandList.VtxBuffer;
				var indexBuffer = commandList.IdxBuffer.Data;

				for (int32 cmd_i = 0; cmd_i < commandList.CmdBuffer.Size; ++cmd_i)
				{
					readonly ImGui.DrawCmd* drawCommand = &commandList.CmdBuffer.Data[cmd_i];

					SDL.Rect clipRect = .(
						(.)drawCommand.ClipRect.x,
						(.)drawCommand.ClipRect.y,
						(.)(drawCommand.ClipRect.z - drawCommand.ClipRect.x),
						(.)(drawCommand.ClipRect.w - drawCommand.ClipRect.y)
					);
					currentDevice.SetClipRect(clipRect);

					if (drawCommand.UserCallback != null)
					{
						drawCommand.UserCallback(commandList, drawCommand);
					}
					else
					{
						bool isWrappedTexture = drawCommand.TextureId == io.Fonts.TexID;

						// Loops over triangles.
						for (uint32 i = 0; i + 3 <= drawCommand.ElemCount; i += 3)
						{
							ImGui.DrawVert v0 = vertexBuffer.Data[indexBuffer[i + 0]];
							ImGui.DrawVert v1 = vertexBuffer.Data[indexBuffer[i + 1]];
							ImGui.DrawVert v2 = vertexBuffer.Data[indexBuffer[i + 2]];

							Rect bounding = Rect.CalculateBoundingBox(v0, v1, v2);

							bool isTriangleUniformColor = v0.col == v1.col && v1.col == v2.col;
							ImGui.Vec2 whitePixel = ImGui.GetIO().Fonts.TexUvWhitePixel;

							bool doesTriangleUseOnlyColor = v0.uv.x == v1.uv.x && v0.uv.x == v2.uv.x && v0.uv.x == whitePixel.x
														 && v0.uv.y == v1.uv.y && v0.uv.y == v2.uv.y && v0.uv.y == whitePixel.y;

							// Actually, since we render a whole bunch of rectangles, we try to first detect those, and render them more efficiently.
							// How are rectangles detected? It's actually pretty simple: If all 6 vertices lie on the extremes of the bounding box,
							// it's a rectangle.
							if (i + 6 <= drawCommand.ElemCount)
							{
								readonly ref ImGui.DrawVert v3 = ref vertexBuffer.Data[indexBuffer[i + 3]];
								readonly ref ImGui.DrawVert v4 = ref vertexBuffer.Data[indexBuffer[i + 4]];
								readonly ref ImGui.DrawVert v5 = ref vertexBuffer.Data[indexBuffer[i + 5]];
							
								bool isUniformColor = isTriangleUniformColor && v2.col == v3.col && v3.col == v4.col && v4.col == v5.col;
							
								if (isUniformColor
								&& bounding.IsOnExtreme(v0.pos)
								&& bounding.IsOnExtreme(v1.pos)
								&& bounding.IsOnExtreme(v2.pos)
								&& bounding.IsOnExtreme(v3.pos)
								&& bounding.IsOnExtreme(v4.pos)
								&& bounding.IsOnExtreme(v5.pos))
								{
									// ImGui gives the triangles in a nice order: the first vertex happens to be the topleft corner of our rectangle.
									// We need to check for the orientation of the texture, as I believe in theory ImGui could feed us a flipped texture,
									// so that the larger texture coordinates are at topleft instead of bottomright.
									// We don't consider equal texture coordinates to require a flip, as then the rectangle is mostlikely simply a colored rectangle.
									bool doHorizontalFlip = v2.uv.x < v0.uv.x;
									bool doVerticalFlip = v2.uv.y < v0.uv.y;
							
									if (isWrappedTexture)
									{
										DrawRectangle(bounding, currentFontTexture, .(v0.col), doHorizontalFlip, doVerticalFlip);
									}
									else
									{
										DrawRectangle(bounding, (.)drawCommand.TextureId, .(v0.col), doHorizontalFlip, doVerticalFlip);
									}
							
									i += 3;  // Additional increment to account for the extra 3 vertices we consumed.
									continue;
								}
							}

							if (isTriangleUniformColor && doesTriangleUseOnlyColor)
							{
								DrawUniformColorTriangle(v0, v1, v2);
							}
							else
							{
								// Currently we assume that any non rectangular texture samples the font texture. Dunno if that's what actually happens, but it seems to work.
								Runtime.Assert(isWrappedTexture);
								//DrawTriangle(v0, v1, v2, (.)(drawCommand.TextureId));
								DrawTriangle(v0, v1, v2, currentFontTexture);
							}
						}
					}

					indexBuffer += drawCommand.ElemCount;
				}
			}

			SDL.RenderSetClipRect(currentDevice.renderer, null);

			SDL.SetRenderTarget(currentDevice.renderer, initialRenderTarget);

			SDL.RenderSetClipRect(currentDevice.renderer, initialClipEnabled ? &initialClipRect : null);

			SDL.SetRenderDrawColor(currentDevice.renderer, initialR, initialG, initialB, initialA);

			SDL.SetRenderDrawBlendMode(currentDevice.renderer, blendMode);
		}

		
		static void DrawRectangle(Rect bounding, SDL.Texture* texture, int textureWidth, int textureHeight, Color color, bool doHorizontalFlip, bool doVerticalFlip)
		{
			// We are safe to assume uniform color here, because the caller checks it and and uses the triangle renderer to render those.

			SDL.Rect destination = .(
				(.)(bounding.MinX),
				(.)(bounding.MinY),
				(.)(bounding.MaxX - bounding.MinX),
				(.)(bounding.MaxY - bounding.MinY)
			);

			// If the area isn't textured, we can just draw a rectangle with the correct color.
			if (bounding.UsesOnlyColor())
			{
				color.UseAsDrawColor(currentDevice.renderer);
				SDL.RenderFillRect(currentDevice.renderer, &destination);
			}
			else
			{
				// We can now just calculate the correct source rectangle and draw it.

				SDL.Rect source = .(
					(.)(bounding.MinU * textureWidth),
					(.)(bounding.MinV * textureHeight),
					(.)((bounding.MaxU - bounding.MinU) * textureWidth),
					(.)((bounding.MaxV - bounding.MinV) * textureHeight)
				);

				SDL.RendererFlip flip = ((doHorizontalFlip ? SDL.RendererFlip.Horizontal : 0) | (doVerticalFlip ? SDL.RendererFlip.Vertical : 0));

				SDL.SetTextureColorMod(texture, (.)(color.R * 255), (.)(color.G * 255), (.)(color.B * 255));
				SDL.RenderCopyEx(currentDevice.renderer, texture, &source, &destination, 0.0, null, flip);
			}
		}

		static void DrawRectangle(Rect bounding, Texture texture, Color color, bool doHorizontalFlip, bool doVerticalFlip)
		{
			DrawRectangle(bounding, texture.source, texture.surface.w, texture.surface.h, color, doHorizontalFlip, doVerticalFlip);
		}

		static void DrawRectangle(Rect bounding, SDL.Texture* texture, Color color, bool doHorizontalFlip, bool doVerticalFlip)
		{
			uint32 format;
			int32 access, width, height;
			SDL.QueryTexture(texture, out format, out access, out width, out height);
			DrawRectangle(bounding, texture, width, height, color, doHorizontalFlip, doVerticalFlip);
		}

		static void DrawCachedTriangle(Device.TriangleCacheItem triangle, FixedPointTriangleRenderInfo renderInfo)
		{
			SDL.Rect destination = .(renderInfo.MinX, renderInfo.MinY, triangle.Width, triangle.Height);
			SDL.RenderCopy(currentDevice.renderer, triangle.Texture, null, &destination);
		}

		static void DrawTriangle(ImGui.DrawVert v1, ImGui.DrawVert v2, ImGui.DrawVert v3, Texture texture)
		{
			// The naming inconsistency in the parameters is intentional. The fixed point algorithm wants the vertices in a counter clockwise order.
			var renderInfo = FixedPointTriangleRenderInfo.CalculateFixedPointTriangleInfo(v3.pos, v2.pos, v1.pos);

			// First we check if there is a cached version of this triangle already waiting for us. If so, we can just do a super fast texture copy.

			Device.GenericTriangleKey key;
			key.v1 = .((.)(Math.Round(v1.pos.x) - renderInfo.MinX), (.)(Math.Round(v1.pos.y) - renderInfo.MinY), v1.uv.x, v1.uv.y, v1.col);
			key.v2 = .((.)(Math.Round(v2.pos.x) - renderInfo.MinX), (.)(Math.Round(v2.pos.y) - renderInfo.MinY), v2.uv.x, v2.uv.y, v2.col);
			key.v3 = .((.)(Math.Round(v3.pos.x) - renderInfo.MinX), (.)(Math.Round(v3.pos.y) - renderInfo.MinY), v3.uv.x, v3.uv.y, v3.col);

			if (currentDevice.genericTriangleCache.Contains(key))
			{
				Device.TriangleCacheItem cached = currentDevice.genericTriangleCache.At(key);
				DrawCachedTriangle(cached, renderInfo);
				return;
			}

			InterpolatedFactorEquation<float> textureU = scope .(v1.uv.x, v2.uv.x, v3.uv.x, v1.pos, v2.pos, v3.pos);
			InterpolatedFactorEquation<float> textureV = scope .(v1.uv.y, v2.uv.y, v3.uv.y, v1.pos, v2.pos, v3.pos);
			InterpolatedFactorEquation<Color> shadeColor = scope .(Color(v1.col), Color(v2.col), Color(v3.col), v1.pos, v2.pos, v3.pos);

			Device.TriangleCacheItem cached = new .();
			DrawTriangleWithColorFunction(renderInfo, scope [&](x, y) => {
				float u = textureU.Evaluate(x, y);
				float v = textureV.Evaluate(x, y);
				Color sampled = texture.Sample(u, v);
				Color shade = shadeColor.Evaluate(x, y);

				return sampled * shade;
			}, cached); // fills out cache

			if (cached.Texture == null)
			{
				delete cached;
				return;
			}

			SDL.Rect destination = .(renderInfo.MinX, renderInfo.MinY, cached.Width, cached.Height);
			SDL.RenderCopy(currentDevice.renderer, cached.Texture, null, &destination);

			currentDevice.genericTriangleCache.Insert(key, cached); // cached stored for later
		}

		static void DrawUniformColorTriangle(ImGui.DrawVert v1, ImGui.DrawVert v2, ImGui.DrawVert v3)
		{
			Color color = .(v1.col);
			// The naming inconsistency in the parameters is intentional. The fixed point algorithm wants the vertices in a counter clockwise order.
			var renderInfo = FixedPointTriangleRenderInfo.CalculateFixedPointTriangleInfo(v3.pos, v2.pos, v1.pos);

			Device.UniformColorTriangleKey key;
			key.color = v1.col;
			key.v1X = (.)(Math.Round(v1.pos.x) - renderInfo.MinX);
			key.v1Y = (.)(Math.Round(v1.pos.y) - renderInfo.MinY);
			key.v2X = (.)(Math.Round(v2.pos.x) - renderInfo.MinX);
			key.v2Y = (.)(Math.Round(v2.pos.y) - renderInfo.MinY);
			key.v3X = (.)(Math.Round(v3.pos.x) - renderInfo.MinX);
			key.v3Y = (.)(Math.Round(v3.pos.y) - renderInfo.MinY);

			if (currentDevice.uniformColorTriangleCache.Contains(key))
			{
				Device.TriangleCacheItem cached = currentDevice.uniformColorTriangleCache.At(key);
				DrawCachedTriangle(cached, renderInfo);
				return;
			}

			Device.TriangleCacheItem cached = new .();
			DrawTriangleWithColorFunction(renderInfo, scope [&](x, y) => { return color; }, cached);
			
			if (cached.Texture == null)
			{
				delete cached;
				return;
			}

			SDL.Rect destination;
			destination.x = (.)renderInfo.MinX;
			destination.y = (.)renderInfo.MinY;
			destination.w = (.)cached.Width;
			destination.h = (.)cached.Height;
			SDL.RenderCopy(currentDevice.renderer, cached.Texture, null, &destination);

			currentDevice.uniformColorTriangleCache.Insert(key, cached);
		}

		static void DrawTriangleWithColorFunction(FixedPointTriangleRenderInfo renderInfo, delegate Color(float x, float y) colorFunction, Device.TriangleCacheItem cacheItem)
		{
			// Implementation source: https://web.archive.org/web/20171128164608/http://forum.devmaster.net/t/advanced-rasterization/6145.
			// This is a fixed point implementation that rounds to top-left.
			
			int32 deltaX12 = renderInfo.X1 - renderInfo.X2;
			int32 deltaX23 = renderInfo.X2 - renderInfo.X3;
			int32 deltaX31 = renderInfo.X3 - renderInfo.X1;

			int32 deltaY12 = renderInfo.Y1 - renderInfo.Y2;
			int32 deltaY23 = renderInfo.Y2 - renderInfo.Y3;
			int32 deltaY31 = renderInfo.Y3 - renderInfo.Y1;

			int32 fixedDeltaX12 = deltaX12 << 4;
			int32 fixedDeltaX23 = deltaX23 << 4;
			int32 fixedDeltaX31 = deltaX31 << 4;

			int32 fixedDeltaY12 = deltaY12 << 4;
			int32 fixedDeltaY23 = deltaY23 << 4;
			int32 fixedDeltaY31 = deltaY31 << 4;

			int32 width = renderInfo.MaxX - renderInfo.MinX;
			int32 height = renderInfo.MaxY - renderInfo.MinY;
			if (width == 0 || height == 0) return;

			int32 c1 = deltaY12 * renderInfo.X1 - deltaX12 * renderInfo.Y1;
			int32 c2 = deltaY23 * renderInfo.X2 - deltaX23 * renderInfo.Y2;
			int32 c3 = deltaY31 * renderInfo.X3 - deltaX31 * renderInfo.Y3;

			if (deltaY12 < 0 || (deltaY12 == 0 && deltaX12 > 0)) c1++;
			if (deltaY23 < 0 || (deltaY23 == 0 && deltaX23 > 0)) c2++;
			if (deltaY31 < 0 || (deltaY31 == 0 && deltaX31 > 0)) c3++;

			int32 edgeStart1 = c1 + deltaX12 * (renderInfo.MinY << 4) - deltaY12 * (renderInfo.MinX << 4);
			int32 edgeStart2 = c2 + deltaX23 * (renderInfo.MinY << 4) - deltaY23 * (renderInfo.MinX << 4);
			int32 edgeStart3 = c3 + deltaX31 * (renderInfo.MinY << 4) - deltaY31 * (renderInfo.MinX << 4);
			
			SDL.Texture* cache = currentDevice.MakeTexture((.)width, (.)height);
			currentDevice.DisableClip();
			currentDevice.UseAsRenderTarget(cache);

			for (int32 y = renderInfo.MinY; y < renderInfo.MaxY; y++)
			{
				int32 edge1 = edgeStart1;
				int32 edge2 = edgeStart2;
				int32 edge3 = edgeStart3;

				for (int32 x = renderInfo.MinX; x < renderInfo.MaxX; x++)
				{
					if (edge1 > 0 && edge2 > 0 && edge3 > 0)
					{
						currentDevice.SetAt((.)(x - renderInfo.MinX), (.)(y - renderInfo.MinY), colorFunction(x + 0.5f, y + 0.5f));
					}

					edge1 -= fixedDeltaY12;
					edge2 -= fixedDeltaY23;
					edge3 -= fixedDeltaY31;
				}

				edgeStart1 += fixedDeltaX12;
				edgeStart2 += fixedDeltaX23;
				edgeStart3 += fixedDeltaX31;
			}

			currentDevice.UseAsRenderTarget(null);
			currentDevice.EnableClip();

			cacheItem.Texture = cache;
			cacheItem.Width = (.)width;
			cacheItem.Height = (.)height;
		}

		class Device
		{
			public SDL.Renderer* renderer;
			public SDL.Rect clip;
			public LRUCache<UniformColorTriangleKey, TriangleCacheItem> uniformColorTriangleCache ~ delete _;
			public LRUCache<GenericTriangleKey, TriangleCacheItem> genericTriangleCache ~ delete _;
	
			// You can tweak these to values that you find that work the best.
			const int32 UniformColorTriangleCacheSize = 512;
			const int32 GenericTriangleCacheSize = 128;
	
			public class TriangleCacheItem
			{
				public SDL.Texture* Texture = null ~ { if (_ != null) SDL.DestroyTexture(_); };
				public int32 Width = 0;
				public int32 Height = 0;
			};
	
			// Uniform color is identified by its color and the coordinates of the edges.
			public struct UniformColorTriangleKey : IHashable
			{
				public uint32 color;
				public int32 v1X;
				public int32 v1Y;
				public int32 v2X;
				public int32 v2Y;
				public int32 v3X;
				public int32 v3Y;
	
				public int GetHashCode()
				{
					int result = 0;
					result ^= color + 0x9e3779b9 + (result << 6) + (result >> 2);
					result ^= v1X + 0x9e3779b9 + (result << 6) + (result >> 2);
					result ^= v1Y + 0x9e3779b9 + (result << 6) + (result >> 2);
					result ^= v2X + 0x9e3779b9 + (result << 6) + (result >> 2);
					result ^= v2Y + 0x9e3779b9 + (result << 6) + (result >> 2);
					result ^= v3X + 0x9e3779b9 + (result << 6) + (result >> 2);
					result ^= v3Y + 0x9e3779b9 + (result << 6) + (result >> 2);
					return result;
				}
			};
			
			// The generic triangle cache unfortunately has to be basically a full representation of the triangle.
			// This includes the (offset) vertex positions, texture coordinates and vertex colors.
			public struct GenericTriangleVertexKey : IHashable
			{
				public int32 X, Y;
				public double U, V;
				public uint32 color;
	
				public this(int32 x, int32 y, double u, double tc2, uint32 c)
				{
					X = x;
					Y = y;
					U = u;
					V = tc2;
					color = c;
				}
	
				public int GetHashCode()
				{
					int result = 0;
					result ^= X + 0x9e3779b9 + (result << 6) + (result >> 2);
					result ^= Y + 0x9e3779b9 + (result << 6) + (result >> 2);
					result ^= (.)U + 0x9e3779b9 + (result << 6) + (result >> 2);
					result ^= (.)V + 0x9e3779b9 + (result << 6) + (result >> 2);
					result ^= color + 0x9e3779b9 + (result << 6) + (result >> 2);
					return result;
				}
			};
	
			public struct GenericTriangleKey : IHashable
			{
				public GenericTriangleVertexKey v1;
				public GenericTriangleVertexKey v2;
				public GenericTriangleVertexKey v3;
	
				public int GetHashCode()
				{
					int result = 0;
					result ^= v1.GetHashCode() + 0x9e3779b9 + (result << 6) + (result >> 2);
					result ^= v2.GetHashCode() + 0x9e3779b9 + (result << 6) + (result >> 2);
					result ^= v3.GetHashCode() + 0x9e3779b9 + (result << 6) + (result >> 2);
					return result;
				}
			};
	
	
			public this(SDL.Renderer* renderer)
			{
				this.renderer = renderer;
				clip = default;
				uniformColorTriangleCache = new .(UniformColorTriangleCacheSize);
				genericTriangleCache = new .(GenericTriangleCacheSize);
			}
	
			public void SetClipRect(SDL.Rect rect)
			{
				clip = rect;
				SDL.RenderSetClipRect(renderer, &clip);
			}
	
			public void EnableClip() { SetClipRect(clip); }
			public void DisableClip() { SDL.RenderSetClipRect(renderer, null); }
	
			public void SetAt(int32 x, int32 y, Color color)
			{
				color.UseAsDrawColor(renderer);
				SDL.RenderDrawPoint(renderer, x, y);
			}
	
			public SDL.Texture* MakeTexture(int32 width, int32 height)
			{
				SDL.Texture* texture = SDL.CreateTexture(renderer, (.)SDL.PIXELFORMAT_RGBA8888, (.)SDL.TextureAccess.Target, width, height);
				SDL.SetTextureBlendMode(texture, SDL.BlendMode.Blend);
				return texture;
			}
	
			public void UseAsRenderTarget(SDL.Texture* texture)
			{
				SDL.SetRenderTarget(renderer, texture);
				if (texture != null)
				{
					SDL.SetRenderDrawColor(renderer, 0, 0, 0, 0);
					SDL.RenderClear(renderer);
				}
			}
		}
	
		class Texture
		{
			public SDL.Surface* surface ~ SDL.FreeSurface(_);
			public SDL.Texture* source ~ SDL.DestroyTexture(_);
	
			public Color Sample(float u, float v)
			{
				int x = (.)(Math.Round(u * (surface.w - 1) + 0.5f));
				int y = (.)(Math.Round(v * (surface.h - 1) + 0.5f));
	
				int location = y * surface.w + x;
				Runtime.Assert(location < surface.w * surface.h);
	
				return .(((uint32*)surface.pixels)[location]);
			}
		}
	
		class LRUCache<Key, Value> where Key : IHashable where Value : delete
		{
			public this(int maxSize) { this.maxSize = maxSize; }
	
			public bool Contains(Key key) => container.ContainsKey(key);
	
			public readonly ref Value At(Key key)
			{
				Runtime.Assert(container.ContainsKey(key));
	
				if (order.Back != key)
				{
					order.Remove(key);
					order.Add(key);
				}
				return ref container[key];
			}
	
			public void Insert(Key key, Value value)
			{
				if (container.GetAndRemove(key) != .Err)
				{
					order.Remove(key);
				}
				
				order.Add(key);
				container.Add(.(key, value));
	
				Clean();
			}
	
			private void Clean()
			{
				while (container.Count > maxSize)
				{
					delete container.GetAndRemove(order.PopFront()).Get().value;
				}
			}
	
			int maxSize;
			List<Key> order = new .() ~delete _;
			Dictionary<Key, Value> container = new .() ~ { for (var v in _) { delete v.value; } delete _; };
		}

		// TODO this shouldn't be public but there is an error when compiling a lambda for rendering about inconsistent accessibility
		public struct Color
		{
			public readonly float R, G, B, A;
	
			public this(uint32 color)
			{
				R = (((color >>  0) & 0xff) / 255.0f);
				G = (((color >>  8) & 0xff) / 255.0f);
				B = (((color >> 16) & 0xff) / 255.0f);
				A = (((color >> 24) & 0xff) / 255.0f);
			}
			public this(float r, float g, float b, float a)
			{
				R = r;
				G = g;
				B = b;
				A = a;
			}
	
			public static Color operator*(Color c1, Color c2) { return .(c1.R * c2.R, c1.G * c2.G, c1.B * c2.B, c1.A * c2.A); }
			public static Color operator*(Color c, float v) { return .(c.R * v, c.G * v, c.B * v, c.A * v); }
			public static Color operator+(Color c1, Color c2) { return .(c1.R + c2.R, c1.G + c2.G, c1.B + c2.B, c1.A + c2.A); }
	
			public uint32 ToInt()
			{
				return	(((uint32)(R * 255) & 0xff) << 0)
					  | (((uint32)(G * 255) & 0xff) << 8)
					  | (((uint32)(B * 255) & 0xff) << 16)
					  | (((uint32)(A * 255) & 0xff) << 24);
			}
	
			public void UseAsDrawColor(SDL.Renderer* renderer)
			{
				SDL.SetRenderDrawColor(renderer,
					(.)(R * 255),
					(.)(G * 255),
					(.)(B * 255),
					(.)(A * 255));
			}
		}
	
		class InterpolatedFactorEquation<T> where T : var
		{
			public this(T value0, T value1, T value2, ImGui.Vec2 v0, ImGui.Vec2 v1, ImGui.Vec2 v2)
			{
				Value0 = value0;
				Value1 = value1;
				Value2 = value2;
				V0 = v0;
				V1 = v1;
				V2 = v2;
				Divisor = (V1.y - V2.y) * (V0.x - V2.x) + (V2.x - V1.x) * (V0.y - V2.y);
			}
	
			public T Evaluate(float x, float y)
			{
				float w1 = ((V1.y - V2.y) * (x - V2.x) + (V2.x - V1.x) * (y - V2.y)) / Divisor;
				float w2 = ((V2.y - V0.y) * (x - V2.x) + (V0.x - V2.x) * (y - V2.y)) / Divisor;
				float w3 = 1.0f - w1 - w2;
	
				return (.)((Value0 * w1) + (Value1 * w2) + (Value2 * w3));
			}
	
			readonly T Value0;
			readonly T Value1;
			readonly T Value2;
	
			ImGui.Vec2 V0;
			ImGui.Vec2 V1;
			ImGui.Vec2 V2;
	
			readonly float Divisor;
		}
		
		static float Min3(float v0, float v1, float v2)
		{
			if (v0 < v1)
			{
				return (v0 < v2) ? v0 : v2;
			}
			if (v0.IsNaN) return v0;
			if (v1 < v2) return v1;
			if (v1.IsNaN) return v1;
			return v2;
		}
	
		static float Max3(float v0, float v1, float v2)
		{
			if (v0 > v1)
			{
				return (v0 > v2) ? v0 : v2;
			}
			if (v0.IsNaN) return v0;
			if (v1 > v2) return v1;
			if (v1.IsNaN) return v1;
			return v2;
		}
	
		struct Rect
		{
			public float MinX, MinY, MaxX, MaxY;
			public float MinU, MinV, MaxU, MaxV;
	
			public bool IsOnExtreme(ImGui.Vec2 point)
			{
				return (point.x == MinX || point.x == MaxX) && (point.y == MinY || point.y == MaxY);
			}
	
			public bool UsesOnlyColor()
			{
				ImGui.Vec2 whitePixel = ImGui.GetIO().Fonts.TexUvWhitePixel;
	
				return MinU == MaxU && MinU == whitePixel.x && MinV == MaxV && MaxV == whitePixel.y;
			}
	
			public static Rect CalculateBoundingBox(ImGui.DrawVert v0, ImGui.DrawVert v1, ImGui.DrawVert v2)
			{
				Rect result;
				result.MinX = Min3(v0.pos.x, v1.pos.x, v2.pos.x);
				result.MinY = Min3(v0.pos.y, v1.pos.y, v2.pos.y);
				result.MaxX = Max3(v0.pos.x, v1.pos.x, v2.pos.x);
				result.MaxY = Max3(v0.pos.y, v1.pos.y, v2.pos.y);
				result.MinU = Min3(v0.uv.x, v1.uv.x, v2.uv.x);
				result.MinV = Min3(v0.uv.y, v1.uv.y, v2.uv.y);
				result.MaxU = Max3(v0.uv.x, v1.uv.x, v2.uv.x);
				result.MaxV = Max3(v0.uv.y, v1.uv.y, v2.uv.y);
				return result;
			}
		}
	
		struct FixedPointTriangleRenderInfo
		{
			public int32 X1, X2, X3, Y1, Y2, Y3;
			public int32 MinX, MaxX, MinY, MaxY;
	
			public static FixedPointTriangleRenderInfo CalculateFixedPointTriangleInfo(ImGui.Vec2 v1, ImGui.Vec2 v2, ImGui.Vec2 v3)
			{
				const float scale = 16.0f;
	
				FixedPointTriangleRenderInfo result;
				result.X1 = (.)(Math.Round(v1.x * scale));
				result.X2 = (.)(Math.Round(v2.x * scale));
				result.X3 = (.)(Math.Round(v3.x * scale));
	
				result.Y1 = (.)(Math.Round(v1.y * scale));
				result.Y2 = (.)(Math.Round(v2.y * scale));
				result.Y3 = (.)(Math.Round(v3.y * scale));
	
				result.MinX = ((.)(Min3(result.X1, result.X2, result.X3) + 0xF) >> 4);
				result.MaxX = ((.)(Max3(result.X1, result.X2, result.X3) + 0xF) >> 4);
				result.MinY = ((.)(Min3(result.Y1, result.Y2, result.Y3) + 0xF) >> 4);
				result.MaxY = ((.)(Max3(result.Y1, result.Y2, result.Y3) + 0xF) >> 4);
				return result;
			}
		}
	}
}
