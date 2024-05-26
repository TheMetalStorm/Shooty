const rl = @import("raylib");
const std = @import("std");
const GameState = @import("GameState.zig");

spritesheet: *rl.Texture2D,
numSpritesHorizontal: usize,
numSpritesVertical: usize,
spriteWidth: usize,
spriteHeight: usize,

const Self = @This();
pub fn init(_path: [:0]const u8, _numSpritesHorizontal: usize, _numSpritesVertical: usize, _spriteWidth: usize, _spriteHeight: usize) !Self {
    const texture = try GameState.getAlloc().create(rl.Texture2D);
    texture.* = rl.loadTexture(_path);
    return Self{
        .spritesheet = texture,
        .numSpritesHorizontal = _numSpritesHorizontal,
        .numSpritesVertical = _numSpritesVertical,
        .spriteWidth = _spriteWidth,
        .spriteHeight = _spriteHeight,
    };
}
