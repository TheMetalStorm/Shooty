const rl = @import("raylib");
const std = @import("std");
const GameState = @import("GameState.zig");

spritesheet: *rl.Texture2D,
numSpritesHorizontal: usize,
numSpritesVertical: usize,
spriteWidth: usize,
spriteHeight: usize,
frames: std.ArrayList(*rl.Rectangle),
const Self = @This();
pub fn init(_alloc: std.mem.Allocator, _path: []const u8, _numSpritesHorizontal: usize, _numSpritesVertical: usize, _spriteWidth: usize, _spriteHeight: usize) !Self {
    var _frames = std.ArrayList(*rl.Rectangle).init(_alloc);
    const texture = try _alloc.create(rl.Texture2D);

    for (0..(_numSpritesHorizontal * _numSpritesVertical)) |index| {
        const framePtr = try _alloc.create(rl.Rectangle);
        const frame = rl.Rectangle{
            .x = @mod(@as(f32, @floatFromInt(index)), @as(f32, @floatFromInt(_numSpritesHorizontal))) * @as(f32, @floatFromInt(_spriteWidth)),
            .y = @as(f32, @floatFromInt(index / _numSpritesHorizontal)) * @as(f32, @floatFromInt(_spriteHeight)),
            .width = @as(f32, @floatFromInt(_spriteWidth)),
            .height = @as(f32, @floatFromInt(_spriteHeight)),
        };
        framePtr.* = frame;
        try _frames.append(framePtr);
    }

    const pathLen = _path.len;
    const pathZeroTerminated = try _alloc.allocSentinel(u8, pathLen, 0);
    std.mem.copyForwards(u8, pathZeroTerminated, _path);

    texture.* = rl.loadTexture(pathZeroTerminated);
    return Self{
        .spritesheet = texture,
        .numSpritesHorizontal = _numSpritesHorizontal,
        .numSpritesVertical = _numSpritesVertical,
        .spriteWidth = _spriteWidth,
        .spriteHeight = _spriteHeight,
        .frames = _frames,
    };
}

pub fn create(_alloc: std.mem.Allocator, _path: []const u8, _numSpritesHorizontal: usize, _numSpritesVertical: usize, _spriteWidth: usize, _spriteHeight: usize) !*Self {
    const spritesheetPtr = try _alloc.create(Self);
    spritesheetPtr.* = try Self.init(_alloc, _path, _numSpritesHorizontal, _numSpritesVertical, _spriteWidth, _spriteHeight);
    return spritesheetPtr;
}
