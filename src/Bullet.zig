const rl = @import("raylib");
const std = @import("std");
const GameState = @import("GameState.zig");
const Animation = @import("Animation.zig");
const AnimationManager = @import("AnimationManager.zig");

pos: rl.Vector2,
v: f32,
dir: rl.Vector2,
color: rl.Color,
radius: f32 = 5,
animManager: *AnimationManager,

markedDead: bool = false,
active: bool = true,
gs: *GameState,
lifetime: f32 = 2,
lifetimer: f32 = 0,

const Self = @This();
const bulletSpriteRect: rl.Rectangle = rl.Rectangle.init(0.0, 0.0, 16, 16);

pub fn init(
    _x: f32,
    _y: f32,
    _dir: rl.Vector2,
    _v: f32,
    _color: rl.Color,
    _gs: *GameState,
) !Self { //, _texture: rl.Texture2D) Self {

    const _animManagerPtr = try GameState.getAlloc().create(AnimationManager);
    var _animManager = try AnimationManager.init();

    try _animManager.registerAnimation("bullet_normal", _gs.animations.get("bullet_normal").?);
    try _animManager.registerAnimation("bullet_die", _gs.animations.get("bullet_die").?);

    _animManagerPtr.* = _animManager;

    return Self{ .pos = rl.Vector2.init(_x, _y), .dir = _dir, .v = _v, .color = _color, .gs = _gs, .animManager = _animManagerPtr }; //, .texture = _texture };
}

pub fn update(self: *Self, dt: f32) void {
    self.lifetimer += dt;
    if (self.lifetimer > self.lifetime) {
        self.markedDead = true;
    }

    if (self.markedDead) {
        if (self.animManager.isCurrentDone()) {
            self.active = false;
            //TODO: we still have the pointer to this Bullet in gs.bullets, but we mark it as inactive so no use-after-free.
            //still would be better to remove it from the list, but that would mess with the array indices we would use to
            // find and remove the ptr
            //gets removed at end of Game or maybe when we load a new level (if we ever do that)
            self.deinit();
        }
        return;
    }
    self.pos.x += self.dir.x * self.v * dt;
    self.pos.y += self.dir.y * self.v * dt;
}

pub fn render(self: *Self, dt: f32) !void {
    if (self.animManager.animations.count() == 0) return;
    const sizeMult = 4;

    if (self.markedDead == true) {
        if (!std.mem.eql(u8, self.animManager.currentAnimation.name, "bullet_die")) {
            try self.animManager.setCurrent("bullet_die");
        }
        if (self.animManager.isCurrentDone()) {
            return;
        }
        self.animManager.playCurrent(rl.Rectangle.init(self.pos.x, self.pos.y, bulletSpriteRect.width * sizeMult, bulletSpriteRect.height * sizeMult), rl.Vector2.init(bulletSpriteRect.width * sizeMult / 2, bulletSpriteRect.height * sizeMult / 2), 0, rl.Color.white, dt);
        return;
    }
    const angle = @mod(std.math.radiansToDegrees(std.math.atan2(self.dir.y, self.dir.x)) + 360 + 90, 360); // 90 is the offset to make the ship face the mouse
    self.animManager.playCurrent(rl.Rectangle.init(self.pos.x, self.pos.y, bulletSpriteRect.width * sizeMult, bulletSpriteRect.height * sizeMult), rl.Vector2.init(bulletSpriteRect.width * sizeMult / 2, bulletSpriteRect.height * sizeMult / 2), angle, rl.Color.white, dt);
}

pub fn deinit(self: *Self) void {
    self.animManager.deinit();
}
