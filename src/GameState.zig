const Player = @import("Player.zig");
const Enemy = @import("Enemy.zig");
const Bullet = @import("Bullet.zig");
const rl = @import("raylib");
const std = @import("std");
const Animation = @import("Animation.zig");

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
pub const arenaAlloc = arena.allocator();
camera: rl.Camera2D,
player: Player,
enemies: std.ArrayList(Enemy),
bullets: std.ArrayList(Bullet),
spritesheets: std.StringHashMap(*rl.Texture2D),
animations: std.StringHashMap(*Animation),

score: i32 = 0,

const Self = @This();

const screenWidth = 800;
const screenHeight = 450;

pub fn init() !Self {
    var ret = Self{ .camera = undefined, .player = undefined, .enemies = undefined, .bullets = undefined, .spritesheets = undefined, .score = 0, .animations = undefined };
    const _player = Player.init(150.0, 150.0, rl.Color.red, &ret);
    var _spritesheets = std.StringHashMap(*rl.Texture2D).init(arenaAlloc);
    var _animations = std.StringHashMap(*Animation).init(arenaAlloc);

    //INFO: Set the spritesheets here
    //TODO: struct SpriteSheetInfo (width, height, spriteW, spriteH) should get saved so we can use it later
    try _spritesheets.put("laser-bolts", try createSpritesheet("src/assets/spritesheets/laser-bolts.png"));
    try _spritesheets.put("explosion", try createSpritesheet("src/assets/spritesheets/explosion.png"));

    //INFO: Set the Animations here
    try _animations.put("bullet_normal", try createAnimation("bullet_normal", _spritesheets.get("laser-bolts").?, 50, &[_]usize{ 0, 1 }, true));
    //TODO: animation switching breaks going from loopable -> non-loopable
    try _animations.put("bullet_die", try createAnimation("bullet_die", _spritesheets.get("explosion").?, 30, &[_]usize{ 0, 1, 2, 3, 4 }, false));

    ret.player = _player;
    ret.camera = rl.Camera2D{
        .target = _player.pos,
        .offset = rl.Vector2.init(screenWidth / 2, screenHeight / 2),
        .rotation = 0,
        .zoom = 1,
    };
    ret.enemies = std.ArrayList(Enemy).init(arenaAlloc);
    ret.bullets = std.ArrayList(Bullet).init(arenaAlloc);
    ret.spritesheets = _spritesheets;
    ret.animations = _animations;
    return ret;
}

fn createSpritesheet(path: [:0]const u8) !*rl.Texture2D {
    const texture = try arenaAlloc.create(rl.Texture2D);
    texture.* = rl.loadTexture(path);
    return texture;
}

fn createAnimation(name: [:0]const u8, texture: *rl.Texture2D, length: f32, spriteIndices: []const usize, loop: bool) !*Animation {
    const bulletAnimPtr = try getAlloc().create(Animation);

    //TODO: pass new struct SpriteSheetInfo so that 2, 2, 16, 16, is not hardcoded
    const bulletAnim = try Animation.init(name, texture, 2, 2, 16, 16, length, spriteIndices, loop);
    bulletAnimPtr.* = bulletAnim;
    return bulletAnimPtr;
}

pub fn deinit(self: *Self) void {
    self.player.deinit();
    for (self.bullets.items) |*bullet| {
        if (bullet.active)
            bullet.deinit();
    }
    arena.deinit();
}

pub fn update(self: *Self, dt: f32) !void {
    try self.player.update(self, dt);

    for (self.bullets.items) |*bullet| {
        if (bullet.active)
            bullet.update(dt);
    }

    if (self.enemies.items.len < 10) {
        //TODO: better logic for enemy spawn position
        const x: f32 = @floatFromInt(rl.getRandomValue(@intFromFloat(self.player.pos.x - screenWidth), @intFromFloat(self.player.pos.x + screenWidth)));
        const y: f32 = @floatFromInt(rl.getRandomValue(@intFromFloat(self.player.pos.y - screenHeight), @intFromFloat(self.player.pos.y + screenHeight)));
        try self.enemies.append(Enemy.init(x, y, rl.Color.green, 1));
    }

    for (self.enemies.items, 0..) |*enemy, index| {
        enemy.update(self, dt);
        enemy.checkCollisions(self, index);
    }

    const lerp = 5;
    self.camera.target.x += (self.player.pos.x - self.camera.target.x) * lerp * dt;
    self.camera.target.y += (self.player.pos.y - self.camera.target.y) * lerp * dt;
}

pub fn render(self: *Self, dt: f32) void {
    for (self.bullets.items) |*bullet| {
        if (bullet.active)
            bullet.render(dt);
    }

    self.player.render();

    for (self.enemies.items) |*enemy| {
        enemy.render();
    }
}

pub fn getAlloc() std.mem.Allocator {
    return arenaAlloc;
}
