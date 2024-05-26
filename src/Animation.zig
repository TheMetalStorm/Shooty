const rl = @import("raylib");
const std = @import("std");
const GameState = @import("GameState.zig");
const Spritesheet = @import("Spritesheet.zig");

name: []const u8,
spritesheet: *Spritesheet,
duration: f32, //in milliseconds
playedTime: f32,
frameTime: f32,
loop: bool,
frames: std.ArrayList(rl.Rectangle) = undefined,
const Self = @This();

pub fn init(
    _alloc: std.mem.Allocator,
    _name: []const u8,
    _spritesheet: *Spritesheet,
    _duration: f32,
    _spriteIndices: []const usize,
    _loop: bool,
) !Self {
    var _frames: std.ArrayList(rl.Rectangle) = std.ArrayList(rl.Rectangle).init(_alloc);
    for (_spriteIndices) |index| {
        try _frames.append(rl.Rectangle{
            .x = @mod(@as(f32, @floatFromInt(index)), @as(f32, @floatFromInt(_spritesheet.numSpritesHorizontal))) * @as(f32, @floatFromInt(_spritesheet.spriteWidth)),
            .y = @floor(@as(f32, @floatFromInt(index)) / @as(f32, @floatFromInt(_spritesheet.numSpritesVertical))) * @as(f32, @floatFromInt(_spritesheet.spriteHeight)),
            .width = @as(f32, @floatFromInt(_spritesheet.spriteWidth)),
            .height = @as(f32, @floatFromInt(_spritesheet.spriteHeight)),
        });
    }

    const spriteFrameTime = _duration / @as(f32, @floatFromInt(_spriteIndices.len));

    return Self{
        .name = _name,
        .spritesheet = _spritesheet,
        .duration = _duration,
        .frames = _frames,
        .frameTime = spriteFrameTime,
        .loop = _loop,
        .playedTime = 0.0,
    };
}
