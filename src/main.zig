const std = @import("std");
const rl = @import("raylib");
const Player = @import("Player.zig");
const Enemy = @import("Enemy.zig");
const Bullet = @import("Bullet.zig");
const Animation = @import("Animation.zig");
const GameState = @import("GameState.zig");

const screenWidth = 800;
const screenHeight = 450;

var ressourceArena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
pub const ressourceAlloc = ressourceArena.allocator();

pub fn main() !void {
    rl.initWindow(screenWidth, screenHeight, "Shooty");
    defer rl.closeWindow();
    rl.setTargetFPS(60);
    var gs = try GameState.init(ressourceAlloc);
    while (!rl.windowShouldClose()) {

        //update
        const dt = rl.getFrameTime();

        try gs.update(dt);

        //render
        rl.beginDrawing();
        gs.camera.begin();

        rl.clearBackground(rl.Color.fromInt(0x052c46ff));
        try gs.render(dt);
        gs.camera.end();
        drawGUI(&gs);
        rl.endDrawing();
    }
    gs.deinit();
    ressourceArena.deinit();
}

fn drawGUI(gs: *GameState) void {
    rl.drawText(rl.textFormat("Score: %02i", .{gs.score}), 20, 20, 20, rl.Color.red);
    rl.drawText(rl.textFormat("FrameTime: %02f", .{rl.getFrameTime()}), 20, 60, 20, rl.Color.red);
    rl.drawText(rl.textFormat("FPS: %.2f", .{1.0 / rl.getFrameTime()}), 20, 80, 20, rl.Color.red);
}
