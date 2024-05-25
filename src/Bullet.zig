const rl = @import("raylib");
const std = @import("std");
const GameState = @import("GameState.zig");
const Animation = @import("Animation.zig");

pos: rl.Vector2,
v: f32,
dir: rl.Vector2,
color: rl.Color,
radius: f32 = 5,
currentAnimation: *Animation = undefined,
animations: std.StringHashMap(*Animation) = std.StringHashMap(*Animation).init(GameState.getAlloc()),

const Self = @This();
const bulletSpriteRect: rl.Rectangle = rl.Rectangle.init(0.0, 0.0, 16, 16);

pub fn init(_x: f32, _y: f32, _dir: rl.Vector2, _v: f32, _color: rl.Color) !Self { //, _texture: rl.Texture2D) Self {

    const bulletTexture = try GameState.getAlloc().create(rl.Texture2D);
    const b = rl.Texture2D.init("src/assets/spritesheets/laser-bolts.png");
    bulletTexture.* = b;

    const usedSprites = [2]usize{ 0, 1 };
    const bulletAnimPointer = try GameState.getAlloc().create(Animation);
    const bulletAnim = try Animation.init("normal", bulletTexture, 2, 2, 16, 16, 50, &usedSprites, true);
    bulletAnimPointer.* = bulletAnim;
    var a = Self{
        .pos = rl.Vector2.init(_x, _y),
        .dir = _dir,
        .v = _v,
        .color = _color,
    }; //, .texture = _texture };
    try a.addAnimation(bulletAnimPointer.name, bulletAnimPointer);
    return a;
}

pub fn update(self: *Self, dt: f32) void {
    self.pos.x += self.dir.x * self.v * dt;
    self.pos.y += self.dir.y * self.v * dt;
}

pub fn render(self: *Self, dt: f32) void {
    if (self.animations.count() == 0) return;

    const angle = @mod(std.math.radiansToDegrees(std.math.atan2(self.dir.y, self.dir.x)) + 360 + 90, 360); // 90 is the offset to make the ship face the mouse
    const sizeMult = 4;
    //std.debug.print("{?}", .{self.currentAnimation});
    //Animation.play: same signature as drawTexturePro but with an Animation instead of texture and source rectangle
    self.currentAnimation.play(rl.Rectangle.init(self.pos.x, self.pos.y, bulletSpriteRect.width * sizeMult, bulletSpriteRect.height * sizeMult), rl.Vector2.init(bulletSpriteRect.width * sizeMult / 2, bulletSpriteRect.height * sizeMult / 2), angle, rl.Color.white, dt);
    // rl.drawTexturePro(texture, bulletSpriteRect, rl.Rectangle.init(self.pos.x, self.pos.y, bulletSpriteRect.width * sizeMult, bulletSpriteRect.height * sizeMult), rl.Vector2.init(bulletSpriteRect.width * sizeMult / 2, bulletSpriteRect.height * sizeMult / 2), angle, rl.Color.white);
    // rl.drawCircle(@intFromFloat(self.pos.x), @intFromFloat(self.pos.y), self.radius, self.color);
}

pub fn setAnimation(self: *Self, name: []const u8) void {
    //std.debug.print("{?}\n", .{animations.get(name)});

    self.currentAnimation = self.animations.get(name) orelse return;
}

pub fn addAnimation(self: *Self, name: []const u8, _animation: *Animation) !void {
    try self.animations.put(name, _animation);
}

pub fn deinit(self: *Self) void {
    self.animations.deinit();
}
