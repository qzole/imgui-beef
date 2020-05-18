# ImGui-Beef
**imgui-beef** is a Beef wrapper library for [Dear ImGui v1.75](https://github.com/ocornut/imgui)

> **Attention!** This binding is still in development. Bugs may occur.
	Binaries are removed from repo. You can download this library with binaries from [Release page](https://github.com/qzole/imgui-beef/releases)!

This wrapper currently uses [cimgui](https://github.com/cimgui/cimgui) bindings, since I couldn't wrap the c++ api of ImGui because of the hidden "bf" namespace when using [StdCall] property.

## IMPORTANT CAVEAT!
As of the current Beef version (0.42.3) the SDL bindings need two modifications to work properly with the official SDL bindings included with Beef. These modifications will be part of the 0.42.4 release:
 - https://github.com/beefytech/Beef/pull/258
 - https://github.com/beefytech/Beef/pull/259

## What is done
- Bindings for:
    - The main ImGui API more or less complete
    - Several ImGui structs used for communicating with ImGui
- Windowing / Input backends:
    - SDL, converted to Beef based on offical ImGui implementation.
    - GLFW, converted to Beef based on offical ImGui implementation.
- Rendering backends:
    - SDL Renderer, converted to Beef based on: https://github.com/Tyyppi77/imgui_sdl
    - OpenGL3, converted to Beef based on offical ImGui implementation with slight change to initialization.

## TODO:
- Finish bindings for main ImGui structs and their public API
- Windowing / Input backends:
    - Allegro 5
    - GLUT/FreeGLUT
    - OSX / Cocoa
    - Windows API
- Rendering backends:
    - DirectX9
    - DirectX10
    - DirectX11
    - DirectX12
    - Metal
    - OpenGL2
    - Vulkan
- Combined backends:
    - Marmalade + IwGx
    
# Quick Start *(using Beef IDE)*
1. **Download** imgui-beef and copy the main project and the backend projects here: **C:\Program Files\BeefLang\BeefLibs**.
2. Right-click on your workspace and select **Add from Installed** and choose imgui-beef + your desired backends.
3. **Make** imgui-beef + your desired backends **as a dependency** of your project.

## Tip & Tricks
1. You should make your workspace looks like this
```
Workspace-Folder\
    |__ Project1\ 
    |__ Project2\
    |__ Project3\
    |__ imgui-beef\
    |__ imgui-impl-sdl-beef\
    |__ imgui-impl-sdl-renderer-beef\
    |__ some-other-lib\
```

# More Info
- Thank you for M0n7y5, whose [**raylib**](https://github.com/M0n7y5/raylib-beef) bindings' readme structure gave heavy inspiration for this readme document.
- For any questions, I'm usually lurking in BeefLang discord channel: https://discord.gg/rnsc9YP

# Contribution
I'll be glad for any contribution & pull requests
