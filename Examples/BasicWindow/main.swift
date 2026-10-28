// raylib's core_basic_window example, in Swift. Press Escape or close the window to quit.

import Raylib

SetConfigFlags([.vsyncHint, .windowResizable])
InitWindow(800, 450, "raylib-swift - basic window")
SetTargetFPS(60)

while !WindowShouldClose() {
    BeginDrawing()
    ClearBackground(.rayWhite)
    DrawText("Congrats! You created your first window!", 190, 200, 20, .lightGray)
    if IsKeyDown(.space) {
        DrawText("Space is down", 190, 240, 20, .maroon)
    }
    EndDrawing()
}

CloseWindow()
