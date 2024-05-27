const std = @import("std");
const rl = @import("raylib");
const Player = @import("Player.zig");
const Enemy = @import("Enemy.zig");
const Bullet = @import("Bullet.zig");
const Animation = @import("Animation.zig");
const GameState = @import("GameState.zig");
const Spritesheet = @import("Spritesheet.zig");

const screenWidth = 800;
const screenHeight = 450;

var ressourceArena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
pub const ressourceAlloc = ressourceArena.allocator();

pub fn main() !void {
    rl.initWindow(screenWidth, screenHeight, "Shooty");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var _spritesheets = std.StringHashMap(*Spritesheet).init(ressourceAlloc);
    var _animations = std.StringHashMap(*Animation).init(ressourceAlloc);

    //INFO: Set the spritesheets heres
    try _spritesheets.put("laser-bolts", try createSpritesheet(ressourceAlloc, "src/assets/spritesheets/laser-bolts.png", 2, 2, 16, 16));
    try _spritesheets.put("explosion", try createSpritesheet(ressourceAlloc, "src/assets/spritesheets/explosion.png", 5, 1, 16, 16));

    //INFO: Set the Animations here
    try _animations.put("bullet_normal", try createAnimation(ressourceAlloc, "bullet_normal", _spritesheets.get("laser-bolts").?, 50, &[_]usize{ 0, 1 }, true));
    try _animations.put("bullet_die", try createAnimation(ressourceAlloc, "bullet_die", _spritesheets.get("explosion").?, 30, &[_]usize{ 0, 1, 2, 3, 4 }, false));

    var gs = try GameState.init(&_spritesheets, &_animations);

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

fn createSpritesheet(alloc: std.mem.Allocator, path: [:0]const u8, numW: usize, numH: usize, spriteWidth: usize, spriteHeight: usize) !*Spritesheet {
    const spritesheetPtr = try alloc.create(Spritesheet);
    spritesheetPtr.* = try Spritesheet.init(alloc, path, numW, numH, spriteWidth, spriteHeight);
    return spritesheetPtr;
}

fn createAnimation(alloc: std.mem.Allocator, name: [:0]const u8, spritesheet: *Spritesheet, length: f32, spriteIndices: []const usize, loop: bool) !*Animation {
    const animPtr = try alloc.create(Animation);
    animPtr.* = try Animation.init(alloc, name, spritesheet, length, spriteIndices, loop);
    return animPtr;
}

fn drawGUI(gs: *GameState) void {
    rl.drawText(rl.textFormat("Score: %02i", .{gs.score}), 20, 20, 20, rl.Color.red);
    rl.drawText(rl.textFormat("Frame Time: %02f", .{rl.getFrameTime()}), 20, 60, 20, rl.Color.red);
    rl.drawText(rl.textFormat("FPS: %.2f", .{1.0 / rl.getFrameTime()}), 20, 80, 20, rl.Color.red);
}
