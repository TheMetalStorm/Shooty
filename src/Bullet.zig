const rl = @import("raylib");
const std = @import("std");
const GameState = @import("GameState.zig");
const Animation = @import("Animation.zig");

pos: rl.Vector2,
v: f32,
dir: rl.Vector2,
color: rl.Color,
radius: f32 = 5,
//refactor into own struct ?AnimationManger?
currentAnimation: *Animation = undefined,
animations: std.StringHashMap(*Animation) = std.StringHashMap(*Animation).init(GameState.getAlloc()),
markedDead: bool = false,
active: bool = true,
gs: *GameState,
lifetime: f32 = 2,
lifetimer: f32 = 0,

const Self = @This();
const bulletSpriteRect: rl.Rectangle = rl.Rectangle.init(0.0, 0.0, 16, 16);

pub fn init(_x: f32, _y: f32, _dir: rl.Vector2, _v: f32, _color: rl.Color, _gs: *GameState) !Self { //, _texture: rl.Texture2D) Self {

    var ret = Self{ .pos = rl.Vector2.init(_x, _y), .dir = _dir, .v = _v, .color = _color, .gs = _gs }; //, .texture = _texture };
    const usedSprites = [2]usize{ 0, 1 };
    const bulletAnimPointer = try GameState.getAlloc().create(Animation);
    const bulletTexture = _gs.spritesheets.get("laser-bolts") orelse return error.GenericError;
    const bulletAnim = try Animation.init("normal", bulletTexture, 2, 2, 16, 16, 50, &usedSprites, true);
    bulletAnimPointer.* = bulletAnim;
    try ret.addAnimation(bulletAnimPointer.name, bulletAnimPointer);

    const usedSprites1 = [5]usize{ 0, 1, 2, 3, 4 };
    const bulletAnimPointer1 = try GameState.getAlloc().create(Animation);
    const bulletTexture1 = _gs.spritesheets.get("explosion") orelse return error.GenericError;
    const bulletAnim1 = try Animation.init("die", bulletTexture1, 5, 1, 16, 16, 50, &usedSprites1, false);
    bulletAnimPointer1.* = bulletAnim1;
    try ret.addAnimation(bulletAnimPointer1.name, bulletAnimPointer1);

    return ret;
}

pub fn update(self: *Self, dt: f32) void {
    self.lifetimer += dt;
    if (self.lifetimer > self.lifetime) {
        self.markedDead = true;
    }

    if (self.markedDead) {
        if (self.currentAnimation.isDone()) {
            self.active = false;
            //we still have the pointer to this Bullet in gs.bullets, but we mark it as inactive so no use-after-free.
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

pub fn render(self: *Self, dt: f32) void {
    if (self.animations.count() == 0) return;
    const sizeMult = 4;

    if (self.markedDead == true) {
        if (!std.mem.eql(u8, self.currentAnimation.name, "die")) {
            self.currentAnimation = self.animations.get("die") orelse return;
        }
        if (self.currentAnimation.isDone()) {
            return;
        }
        self.currentAnimation.play(rl.Rectangle.init(self.pos.x, self.pos.y, bulletSpriteRect.width * sizeMult, bulletSpriteRect.height * sizeMult), rl.Vector2.init(bulletSpriteRect.width * sizeMult / 2, bulletSpriteRect.height * sizeMult / 2), 0, rl.Color.white, dt);
        return;
    }
    const angle = @mod(std.math.radiansToDegrees(std.math.atan2(self.dir.y, self.dir.x)) + 360 + 90, 360); // 90 is the offset to make the ship face the mouse
    self.currentAnimation.play(rl.Rectangle.init(self.pos.x, self.pos.y, bulletSpriteRect.width * sizeMult, bulletSpriteRect.height * sizeMult), rl.Vector2.init(bulletSpriteRect.width * sizeMult / 2, bulletSpriteRect.height * sizeMult / 2), angle, rl.Color.white, dt);
}

pub fn setAnimation(self: *Self, name: []const u8) void {
    self.currentAnimation = self.animations.get(name) orelse return;
}

pub fn addAnimation(self: *Self, name: []const u8, _animation: *Animation) !void {
    try self.animations.put(name, _animation);
}

pub fn deinit(self: *Self) void {
    self.animations.deinit();
}
