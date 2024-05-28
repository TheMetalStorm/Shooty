const rl = @import("raylib");
const rm = @import("raylib-math");
const std = @import("std");
const Bullet = @import("Bullet.zig");
const Animation = @import("Animation.zig");
const Spritesheet = @import("Spritesheet.zig");
var ressourceArena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
pub const ressourceAlloc = ressourceArena.allocator();
const Self = @This();
var spritesheets: std.StringHashMap(*Spritesheet) = undefined;
var animations: std.StringHashMap(*Animation) = undefined;
pub fn init() !void {
    spritesheets = std.StringHashMap(*Spritesheet).init(ressourceAlloc);
    animations = std.StringHashMap(*Animation).init(ressourceAlloc);

    //INFO: Set the spritesheets heres
    try spritesheets.put("ship", try createSpritesheet(ressourceAlloc, "src/assets/spritesheets/ship.png", 5, 2, 16, 24));
    try spritesheets.put("laser-bolts", try createSpritesheet(ressourceAlloc, "src/assets/spritesheets/laser-bolts.png", 2, 2, 16, 16));
    try spritesheets.put("explosion", try createSpritesheet(ressourceAlloc, "src/assets/spritesheets/explosion.png", 5, 1, 16, 16));
    try spritesheets.put("SpaceShooterAssetPack_Characters", try createSpritesheet(ressourceAlloc, "src/assets/SpaceShooterAssets/SpaceShooterAssetPack_Characters.png", 5, 10, 8, 8));

    //INFO: Set the Animations here
    try animations.put("ship_normal", try createAnimation(ressourceAlloc, "ship_normal", spritesheets.get("ship").?, 1000, &[_]usize{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }, true));
    try animations.put("test", try createAnimation(ressourceAlloc, "test", spritesheets.get("SpaceShooterAssetPack_Characters").?, 1000, &[_]usize{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }, true));

    try animations.put("bullet_normal", try createAnimation(ressourceAlloc, "bullet_normal", spritesheets.get("laser-bolts").?, 50, &[_]usize{ 0, 1 }, true));
    try animations.put("bullet_die", try createAnimation(ressourceAlloc, "bullet_die", spritesheets.get("explosion").?, 30, &[_]usize{ 0, 1, 2, 3, 4 }, false));
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

pub fn getAnimation(name: [:0]const u8) !*Animation {
    return animations.get(name).?;
}

pub fn getSpritesheet(name: [:0]const u8) !*Spritesheet {
    return spritesheets.get(name).?;
}

pub fn deinit() void {
    ressourceArena.deinit();
}
