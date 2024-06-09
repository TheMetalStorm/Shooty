const rl = @import("raylib");
const std = @import("std");
const GameState = @import("GameState.zig");
const Animation = @import("Animation.zig");
const AnimationManager = @import("AnimationManager.zig");
const RessourceManager = @import("RessourceManager.zig");

pos: rl.Vector2,
v: f32,
dir: rl.Vector2,
color: rl.Color,
radius: f32 = 5,
animManager: *AnimationManager,

markedDead: bool = false,
lifetime: f32 = 4,
lifetimer: f32 = 0,
alloc: *std.mem.Allocator,

pub const sizeMult: f32 = 4.0;
const Self = @This();
const bulletSpriteRect: rl.Rectangle = rl.Rectangle.init(0.0, 0.0, 16, 16);

pub fn init(
    _alloc: *std.mem.Allocator,
    _x: f32,
    _y: f32,
    _dir: rl.Vector2,
    _v: f32,
    _color: rl.Color,
) !Self {
    var _animManager = try AnimationManager.init(_alloc);
    try _animManager.registerAnimation("bullet_normal", try RessourceManager.getAnimation("bullet_normal"));
    try _animManager.registerAnimation("bullet_die", try RessourceManager.getAnimation("bullet_die"));

    const bulletSound = try RessourceManager.getSound("bullet_fire");
    rl.playSound(bulletSound.*);

    return Self{ .alloc = _alloc, .pos = rl.Vector2.init(_x, _y), .dir = _dir, .v = _v, .color = _color, .animManager = _animManager };
}

pub fn update(self: *Self, dt: f32) !bool {
    self.lifetimer += dt;
    if (self.lifetimer > self.lifetime) {
        self.markedDead = true;
    }

    if (self.markedDead) {
        if (self.animManager.isCurrentDone()) {
            return false;
        }
        return true;
    }
    self.pos.x += self.dir.x * self.v * dt;
    self.pos.y += self.dir.y * self.v * dt;
    return true;
}

pub fn render(self: *Self, dt: f32) !void {
    if (self.animManager.animations.count() == 0) return;
    const angle = @mod(std.math.radiansToDegrees(std.math.atan2(self.dir.y, self.dir.x)) + 360 + 90, 360); // 90 is the offset to make the ship face the mouse

    if (self.markedDead == true) {
        if (!std.mem.eql(u8, self.animManager.currentAnimation.name, "bullet_die")) {
            try self.animManager.setCurrent("bullet_die");
        }
        if (self.animManager.isCurrentDone()) {
            return;
        }
    }
    self.animManager.playCurrent(rl.Rectangle.init(self.pos.x, self.pos.y, bulletSpriteRect.width * sizeMult, bulletSpriteRect.height * sizeMult), rl.Vector2.init(bulletSpriteRect.width * sizeMult / 2, bulletSpriteRect.height * sizeMult / 2), angle, rl.Color.white, dt);
}

pub fn deinit(self: *Self) void {
    self.animManager.deinit();
}
