const rl = @import("raylib");
const std = @import("std");
const GameState = @import("GameState.zig");
const Animation = @import("Animation.zig");

pos: rl.Vector2,
v: f32,
dir: rl.Vector2,
color: rl.Color,
radius: f32 = 5,

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var arenaAlloc = arena.allocator();

const Self = @This();
const bulletSpriteRect: rl.Rectangle = rl.Rectangle.init(0.0, 16.0, 16, 16);

//var texture = null;
//var animations: std.HashMap([]const u8, *Animation) = undefined;
var currentAnimation: *Animation = undefined;

pub fn init(_x: f32, _y: f32, _dir: rl.Vector2, _v: f32, _color: rl.Color) Self { //, _texture: rl.Texture2D) Self {
    //animations = std.HashMap(Animation).init(arenaAlloc);
    return Self{ .pos = rl.Vector2.init(_x, _y), .dir = _dir, .v = _v, .color = _color }; //, .texture = _texture };
}

pub fn update(self: *Self, dt: f32) void {
    self.pos.x += self.dir.x * self.v * dt;
    self.pos.y += self.dir.y * self.v * dt;
}

pub fn render(self: *Self) void {
    // const angle = @mod(std.math.radiansToDegrees(std.math.atan2(self.dir.y, self.dir.x)) + 360 + 90, 360); // 90 is the offset to make the ship face the mouse
    // const sizeMult = 2;

    //Animation.play: same signature as drawTexturePro but with an Animation instead of texture and source rectangle

    //Animation.play(.Rectangle.init(self.pos.x, self.pos.y, bulletSpriteRect.width * sizeMult, bulletSpriteRect.height * sizeMult), rl.Vector2.init(bulletSpriteRect.width * sizeMult / 2, bulletSpriteRect.height * sizeMult / 2), angle, rl.Color.white);
    //rl.drawTexturePro(texture, bulletSpriteRect, rl.Rectangle.init(self.pos.x, self.pos.y, bulletSpriteRect.width * sizeMult, bulletSpriteRect.height * sizeMult), rl.Vector2.init(bulletSpriteRect.width * sizeMult / 2, bulletSpriteRect.height * sizeMult / 2), angle, rl.Color.white);
    rl.drawCircle(@intFromFloat(self.pos.x), @intFromFloat(self.pos.y), self.radius, self.color);
}

// pub fn setAnimation(_: *Self, name: []const u8) void {
//     currentAnimation = &animations.get(name) orelse return;
// }

// pub fn addAnimation(_: *Self, name: []const u8, _animation: *Animation) void {
//     animations.put(name, _animation);
// }

pub fn deinit(_: *Self) void {
    arena.deinit();
}
