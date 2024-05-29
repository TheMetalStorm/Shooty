const rl = @import("raylib");
const rm = @import("raylib-math");
const std = @import("std");
const Bullet = @import("Bullet.zig");
const Animation = @import("Animation.zig");
const Spritesheet = @import("Spritesheet.zig");

var assetPath: []const u8 = undefined;
var ressourceArena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
pub const ressourceAlloc = ressourceArena.allocator();
const Self = @This();
var spritesheets: std.StringHashMap(*Spritesheet) = undefined;
var animations: std.StringHashMap(*Animation) = undefined;
var sounds: std.StringHashMap(*rl.Sound) = undefined;

pub fn init(_assetPath: []const u8) !void {
    assetPath = _assetPath;
    spritesheets = std.StringHashMap(*Spritesheet).init(ressourceAlloc);
    animations = std.StringHashMap(*Animation).init(ressourceAlloc);
    sounds = std.StringHashMap(*rl.Sound).init(ressourceAlloc);
}

pub fn loadSpritesheet(path: []const u8, numW: usize, numH: usize, spriteWidth: usize, spriteHeight: usize) !void {
    const fullPath = try std.mem.concat(ressourceAlloc, u8, &[_][]const u8{ assetPath, path });
    try spritesheets.put(path, try createSpritesheet(fullPath, numW, numH, spriteWidth, spriteHeight));
}

pub fn loadSound(
    name: []const u8,
    path: []const u8,
) !void {
    try sounds.put(name, try creatSound(path));
}

pub fn loadAnimation(name: []const u8, spriteName: []const u8, length: f32, spriteIndices: []const usize, loop: bool) !void {
    try animations.put(name, try createAnimation(name, spritesheets.get(spriteName).?, length, spriteIndices, loop));
}

fn creatSound(path: []const u8) !*rl.Sound {
    const fullPath = try std.mem.concat(ressourceAlloc, u8, &[_][]const u8{ assetPath, path });
    const pathLen = fullPath.len;
    const pathZeroTerminated = try ressourceAlloc.allocSentinel(u8, pathLen, 0);
    std.mem.copyForwards(u8, pathZeroTerminated, fullPath);

    const audioPtr = try ressourceAlloc.create(rl.Sound);
    audioPtr.* = rl.loadSound(pathZeroTerminated);
    return audioPtr;
}

fn createSpritesheet(path: []const u8, numW: usize, numH: usize, spriteWidth: usize, spriteHeight: usize) !*Spritesheet {
    const spritesheetPtr = try ressourceAlloc.create(Spritesheet);
    spritesheetPtr.* = try Spritesheet.init(ressourceAlloc, path, numW, numH, spriteWidth, spriteHeight);
    return spritesheetPtr;
}

fn createAnimation(name: []const u8, spritesheet: *Spritesheet, length: f32, spriteIndices: []const usize, loop: bool) !*Animation {
    const animPtr = try ressourceAlloc.create(Animation);
    animPtr.* = try Animation.init(ressourceAlloc, name, spritesheet, length, spriteIndices, loop);
    return animPtr;
}

pub fn getAnimation(name: []const u8) !*Animation {
    return animations.get(name).?;
}

pub fn getSpritesheet(name: []const u8) !*Spritesheet {
    return spritesheets.get(name).?;
}

pub fn getSound(name: []const u8) !*rl.Sound {
    return sounds.get(name).?;
}

pub fn deinit() void {
    var aIterator = sounds.keyIterator();
    while (aIterator.next()) |key| {
        rl.unloadSound(sounds.get(key.*).?.*);
    }
    var sIterator = spritesheets.keyIterator();
    while (sIterator.next()) |key| {
        spritesheets.get(key.*).?.deinit();
    }

    ressourceArena.deinit();
}
