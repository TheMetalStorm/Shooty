const Player = @import("Player.zig");
const Enemy = @import("Enemy.zig");
const Bullet = @import("Bullet.zig");
const rl = @import("raylib");
const std = @import("std");

camera: rl.Camera2D,
player: Player,
enemies: std.ArrayList(Enemy),
bullets: std.ArrayList(Bullet),

score: i32 = 0,

wasReset: bool = false,
const Self = @This();
const screenWidth = 800;
const screenHeight = 450;

var levelArena: std.heap.ArenaAllocator = undefined;
var levelAlloc: std.mem.Allocator = undefined;

pub fn init() !Self {
    levelArena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    levelAlloc = levelArena.allocator();

    const _player = try Player.init(&levelAlloc, 150.0, 150.0, rl.Color.red);

    return Self{
        .player = _player,
        .camera = rl.Camera2D{
            .target = _player.pos,
            .offset = rl.Vector2.init(screenWidth / 2, screenHeight / 2),
            .rotation = 0,
            .zoom = 1,
        },
        .enemies = std.ArrayList(Enemy).init(levelAlloc),
        .bullets = std.ArrayList(Bullet).init(levelAlloc),
    };
}

pub fn deinit(_: *Self) void {
    //TODO: maybe useful when we have levels but not for now
    // self.player.deinit();
    // for (self.bullets.items) |*bullet| {
    //     if (bullet.active)
    //         bullet.deinit();
    // }
    // levelArena.deinit();
}

pub fn update(self: *Self, dt: f32) !void {
    if (self.score == 2) {
        try self.resetLevel();
        return;
    }

    try self.player.update(self, dt);

    for (self.bullets.items) |*bullet| {
        if (bullet.active)
            bullet.update(dt);
    }

    if (self.enemies.items.len < 50) {

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

pub fn resetLevel(self: *Self) !void {
    self.wasReset = true;
    self.score = 0;
    levelArena.deinit();

    self.* = try Self.init();
}

pub fn render(self: *Self, dt: f32) !void {
    if (self.wasReset) {
        self.wasReset = false;
        return;
    }
    for (self.bullets.items) |*bullet| {
        if (bullet.active)
            try bullet.render(dt);
    }

    self.player.render(dt);

    for (self.enemies.items) |*enemy| {
        enemy.render();
    }
}
