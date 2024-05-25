const rl = @import("raylib");
const std = @import("std");

spritesheet: rl.Texture2D,
numSpritesHoriziontal: i32,
numSpritesVertical: i32,
spriteWidth: i32,
spriteHeight: i32,
duration: f32,
frames: []rl.Rectangle,
const Self = @This();

pub fn init(
    _spritesheet: rl.Texture2D,
    _numSpritesHorizontal: i32,
    _numSpritesVertical: i32,
    _spriteWidth: i32,
    _spriteHeight: i32,
    _duration: f32,
    _spriteIndeces: []i32,
) Self {
    var _frames = [_spriteIndeces.len]rl.Rectangle;
    for (0.._spriteIndeces) |index| {
        _frames[index] =
            rl.Rectangle{
            .x = index % _numSpritesHorizontal * _spriteWidth,
            .y = index / _numSpritesHorizontal * _spriteHeight,
            .width = _spriteWidth,
            .height = _spriteHeight,
        };
    }

    return Self{
        .spritesheet = _spritesheet,
        .numSpritesHorizontal = _numSpritesHorizontal,
        .numSpritesVertical = _numSpritesVertical,
        .spriteWidth = _spriteWidth,
        .spriteHeight = _spriteHeight,
        .duration = _duration,
        .spriteIndeces = _spriteIndeces,
        .frames = _frames,
    };
}
