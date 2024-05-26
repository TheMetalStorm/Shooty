const Player = @import("Player.zig");
const Enemy = @import("Enemy.zig");
const Bullet = @import("Bullet.zig");
const rl = @import("raylib");
const std = @import("std");
const Animation = @import("Animation.zig");
const Spritesheet = @import("Spritesheet.zig");

var levelArena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
pub const levelAlloc = levelArena.allocator();
camera: rl.Camera2D,
player: Player,
enemies: std.ArrayList(Enemy),
bullets: std.ArrayList(Bullet),
spritesheets: std.StringHashMap(*Spritesheet),
animations: std.StringHashMap(*Animation),
score: i32 = 0,

const Self = @This();
const screenWidth = 800;
const screenHeight = 450;

pub fn init(_alloc: std.mem.Allocator) !Self {
    var ret = Self{ .camera = undefined, .player = undefined, .enemies = undefined, .bullets = undefined, .spritesheets = undefined, .score = 0, .animations = undefined };
    const _player = Player.init(150.0, 150.0, rl.Color.red, &ret);
    var _spritesheets = std.StringHashMap(*Spritesheet).init(_alloc);
    var _animations = std.StringHashMap(*Animation).init(_alloc);

    //INFO: Set the spritesheets here
    try _spritesheets.put("laser-bolts", try createSpritesheet(_alloc, "src/assets/spritesheets/laser-bolts.png", 2, 2, 16, 16));
    try _spritesheets.put("explosion", try createSpritesheet(_alloc, "src/assets/spritesheets/explosion.png", 5, 1, 16, 16));

    //INFO: Set the Animations here
    try _animations.put("bullet_normal", try createAnimation(_alloc, "bullet_normal", _spritesheets.get("laser-bolts").?, 50, &[_]usize{ 0, 1 }, true));
    //TODO: animation switching breaks going from loopable -> non-loopable
    try _animations.put("bullet_die", try createAnimation(_alloc, "bullet_die", _spritesheets.get("explosion").?, 30, &[_]usize{ 0, 1, 2, 3, 4 }, false));

    ret.player = _player;
    ret.camera = rl.Camera2D{
        .target = _player.pos,
        .offset = rl.Vector2.init(screenWidth / 2, screenHeight / 2),
        .rotation = 0,
        .zoom = 1,
    };
    ret.enemies = std.ArrayList(Enemy).init(levelAlloc);
    ret.bullets = std.ArrayList(Bullet).init(levelAlloc);
    ret.spritesheets = _spritesheets;
    ret.animations = _animations;

    return ret;
}

fn createSpritesheet(alloc: std.mem.Allocator, path: [:0]const u8, numW: usize, numH: usize, spriteWidth: usize, spriteHeight: usize) !*Spritesheet {
    const spritesheetPtr = try alloc.create(Spritesheet);
    spritesheetPtr.* = try Spritesheet.init(alloc, path, numW, numH, spriteWidth, spriteHeight);
    return spritesheetPtr;
}

fn createAnimation(alloc: std.mem.Allocator, name: [:0]const u8, spritesheet: *Spritesheet, length: f32, spriteIndices: []const usize, loop: bool) !*Animation {
    const animPtr = try alloc.create(Animation);
    animPtr.* = try Animation.init(alloc, name, spritesheet, length, spriteIndices, loop);
    return animPtr;
}

pub fn deinit(self: *Self) void {
    self.player.deinit();
    for (self.bullets.items) |*bullet| {
        if (bullet.active)
            bullet.deinit();
    }
    levelArena.deinit();
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

pub fn render(self: *Self, dt: f32) !void {
    for (self.bullets.items) |*bullet| {
        if (bullet.active)
            try bullet.render(dt);
    }

    self.player.render();

    for (self.enemies.items) |*enemy| {
        enemy.render();
    }
}

pub fn getAlloc() std.mem.Allocator {
    return levelAlloc;
}
