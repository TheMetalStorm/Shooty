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
spriteIndices: []const usize,
const Self = @This();

pub fn init(
    _name: []const u8,
    _spritesheet: *Spritesheet,
    _duration: f32,
    _spriteIndices: []const usize,
    _loop: bool,
) !Self {
    const spriteFrameTime = _duration / @as(f32, @floatFromInt(_spriteIndices.len));

    return Self{
        .name = _name,
        .spritesheet = _spritesheet,
        .duration = _duration,
        .frameTime = spriteFrameTime,
        .loop = _loop,
        .playedTime = 0.0,
        .spriteIndices = _spriteIndices,
    };
}

pub fn create(
    _alloc: std.mem.Allocator,
    _name: []const u8,
    _spritesheet: *Spritesheet,
    _duration: f32,
    _spriteIndices: []const usize,
    _loop: bool,
) !*Self {
    const animPtr = try _alloc.create(Self);
    animPtr.* = try Self.init(_name, _spritesheet, _duration, _spriteIndices, _loop);
    return animPtr;
}
