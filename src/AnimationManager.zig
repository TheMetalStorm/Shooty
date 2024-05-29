const Animation = @import("Animation.zig");
const rl = @import("raylib");
const std = @import("std");
const GameState = @import("GameState.zig");

const Self = @This();

currentAnimation: *Animation = undefined,
animations: std.StringHashMap(*Animation) = undefined,
alloc: *std.mem.Allocator,
pub fn init(_alloc: *std.mem.Allocator) !*Self {
    const _animManagerPtr = try _alloc.create(Self);
    const _animManager = Self{ .animations = std.StringHashMap(*Animation).init(_alloc.*), .alloc = _alloc };
    _animManagerPtr.* = _animManager;
    return _animManagerPtr;
}

pub fn playCurrent(self: *Self, dest: rl.Rectangle, origin: rl.Vector2, rotation: f32, color: rl.Color, dt: f32) void {
    if (self.currentAnimation.frames.items.len == 0) {
        return;
    }

    if (self.currentAnimation.frames.items.len == 1) {
        rl.drawTexturePro(self.currentAnimation.spritesheet.spritesheet.*, self.currentAnimation.frames.items[0], dest, origin, rotation, color);
        return;
    }

    // if (!rl.isKeyDown(rl.KeyboardKey.key_space)) {
    self.currentAnimation.playedTime += dt * 100;
    // }

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
    // rl.drawText(rl.textFormat("Current Frame: %02i", .{currentFrame}), rl.getWorldToScreen2D(position: Vector2, camera: Camera2D)@as(i32, @intFromFloat(self.currentAnimation.frames.items[currentFrame].x)) + 20, @as(i32, @intFromFloat(self.currentAnimation.frames.items[currentFrame].y)) + 20, 20, rl.Color.red);
}

pub fn setCurrent(self: *Self, name: []const u8) !void {
    const curr = try self.alloc.create(Animation);

    curr.* = self.animations.get(name).?.*;
    self.currentAnimation = curr;
}

pub fn registerAnimation(self: *Self, name: []const u8, _animation: *Animation) !void {
    try self.animations.put(name, _animation);
}

pub fn deinit(self: *Self) void {
    self.animations.deinit();
}

pub fn isCurrentDone(self: *Self) bool {
    return self.currentAnimation.playedTime >= self.currentAnimation.duration and !self.currentAnimation.loop;
}
