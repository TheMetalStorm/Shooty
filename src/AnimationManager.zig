const Animation = @import("Animation.zig");
const rl = @import("raylib");
const std = @import("std");
const GameState = @import("GameState.zig");

const Self = @This();

currentAnimation: *Animation = undefined,
animations: std.StringHashMap(*Animation) = undefined,

pub fn init() !Self {
    return Self{ .animations = std.StringHashMap(*Animation).init(GameState.getAlloc()) };
}

pub fn playCurrent(self: *Self, dest: rl.Rectangle, origin: rl.Vector2, rotation: f32, color: rl.Color, dt: f32) void {
    if (self.currentAnimation.frames.items.len == 0) {
        return;
    }
    self.currentAnimation.playedTime += dt * 100;

    if (self.currentAnimation.playedTime >= self.currentAnimation.duration) {
        if (self.currentAnimation.loop) {
            self.currentAnimation.playedTime = 0;
        } else {
            self.currentAnimation.playedTime = self.currentAnimation.duration;
        }
    }

    if (self.currentAnimation.playedTime == self.currentAnimation.duration) return;

    const currentFrame = @as(usize, @intFromFloat(@divFloor(self.currentAnimation.playedTime, self.currentAnimation.frameTime)));

    rl.drawTexturePro(self.currentAnimation.spritesheet.spritesheet.*, self.currentAnimation.frames.items[currentFrame], dest, origin, rotation, color);
}

pub fn setCurrent(self: *Self, name: []const u8) !void {
    GameState.getAlloc().destroy(self.currentAnimation);
    const curr = try GameState.getAlloc().create(Animation);

    curr.* = self.animations.get(name).?.*;
    std.debug.print("{?}\n", .{curr});
    self.currentAnimation = curr;
}

pub fn registerAnimation(self: *Self, name: []const u8, _animation: *Animation) !void {
    try self.animations.put(name, _animation);
}

pub fn deinit(self: *Self) void {
    GameState.getAlloc().destroy(self.currentAnimation);
    self.animations.deinit();
}

pub fn isCurrentDone(self: *Self) bool {
    return self.currentAnimation.playedTime >= self.currentAnimation.duration and !self.currentAnimation.loop;
}
