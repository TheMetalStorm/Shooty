const rl = @import("raylib");
const std = @import("std");
const GameState = @import("GameState.zig");

spritesheet: *rl.Texture2D,
numSpritesHorizontal: usize,
numSpritesVertical: usize,
spriteWidth: usize,
spriteHeight: usize,

const Self = @This();
pub fn init(_alloc: std.mem.Allocator, _path: []const u8, _numSpritesHorizontal: usize, _numSpritesVertical: usize, _spriteWidth: usize, _spriteHeight: usize) !Self {
    const texture = try _alloc.create(rl.Texture2D);

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
    };
}
