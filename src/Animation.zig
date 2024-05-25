const rl = @import("raylib");
const std = @import("std");
const GameState = @import("GameState.zig");

name: []const u8,
spritesheet: *rl.Texture2D,
numSpritesHorizontal: usize,
numSpritesVertical: usize,
spriteWidth: usize,
spriteHeight: usize,
duration: f32, //in milliseconds
playedTime: f32,
frameTime: f32,
loop: bool,
frames: std.ArrayList(rl.Rectangle) = undefined,
const Self = @This();

pub fn init(
    _name: []const u8,
    _spritesheet: *rl.Texture2D,
    _numSpritesHorizontal: usize,
    _numSpritesVertical: usize,
    _spriteWidth: usize,
    _spriteHeight: usize,
    _duration: f32,
    comptime _spriteIndices: []const usize,
    _loop: bool,
) !Self {
    var _frames: std.ArrayList(rl.Rectangle) = std.ArrayList(rl.Rectangle).init(GameState.getAlloc());
    for (_spriteIndices) |index| {
        try _frames.append(rl.Rectangle{
            .x = @mod(@as(f32, @floatFromInt(index)), @as(f32, @floatFromInt(_numSpritesHorizontal))) * @as(f32, @floatFromInt(_spriteWidth)),
            .y = @floor(@as(f32, @floatFromInt(index)) / @as(f32, @floatFromInt(_numSpritesVertical))) * @as(f32, @floatFromInt(_spriteHeight)),
            .width = @as(f32, @floatFromInt(_spriteWidth)),
            .height = @as(f32, @floatFromInt(_spriteHeight)),
        });
        std.debug.print("{?}\n", .{_frames.getLast()});
    }

    const spriteFrameTime = _duration / @as(f32, @floatFromInt(_spriteIndices.len));

    return Self{
        .name = _name,
        .spritesheet = _spritesheet,
        .numSpritesHorizontal = _numSpritesHorizontal,
        .numSpritesVertical = _numSpritesVertical,
        .spriteWidth = _spriteWidth,
        .spriteHeight = _spriteHeight,
        .duration = _duration,
        .frames = _frames,
        .frameTime = spriteFrameTime,
        .loop = _loop,
        .playedTime = 0.0,
    };
}

pub fn play(self: *Self, dest: rl.Rectangle, origin: rl.Vector2, rotation: f32, color: rl.Color, dt: f32) void {
    if (self.frames.items.len == 0) {
        return;
    }
    self.playedTime += dt * 100;

    if (self.playedTime >= self.duration) {
        if (self.loop) {
            self.playedTime = 0;
        } else {
            self.playedTime = self.duration;
        }
    }

    const currentFrame = @as(usize, @intFromFloat(@divFloor(self.playedTime, self.frameTime)));

    rl.drawTexturePro(self.spritesheet.*, self.frames.items[currentFrame], dest, origin, rotation, color);
}
