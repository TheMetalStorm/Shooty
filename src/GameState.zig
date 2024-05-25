const Player = @import("Player.zig");
const Enemy = @import("Enemy.zig");
const Bullet = @import("Bullet.zig");
const rl = @import("raylib");
const std = @import("std");
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
pub const arenaAlloc = arena.allocator();
camera: rl.Camera2D,
player: Player,
enemies: std.ArrayList(Enemy),
bullets: std.ArrayList(Bullet),
score: i32 = 0,

const Self = @This();

const screenWidth = 800;
const screenHeight = 450;

pub fn init() Self {
    const _player = Player.init(
        150.0,
        150.0,
        rl.Color.red,
    );
    return Self{
        .player = _player,
        .camera = rl.Camera2D{
            .target = _player.pos,
            .offset = rl.Vector2.init(screenWidth / 2, screenHeight / 2),
            .rotation = 0,
            .zoom = 1,
        },
        .enemies = std.ArrayList(Enemy).init(arenaAlloc),
        .bullets = std.ArrayList(Bullet).init(arenaAlloc),
    };
}

pub fn deinit(self: *Self) void {
    self.player.deinit();
    for (self.bullets.items) |*bullet| {
        bullet.deinit();
    }
    arena.deinit();
}

pub fn update(self: *Self, dt: f32) !void {
    try self.player.update(self, dt);

    for (self.bullets.items) |*bullet| {
        bullet.update(dt);
    }

    if (self.enemies.items.len < 10) {
        //TODO: better logic for enemy spawn position
        const x: f32 = @floatFromInt(rl.getRandomValue(@intFromFloat(self.player.pos.x - screenWidth), @intFromFloat(self.player.pos.x + screenWidth)));
        const y: f32 = @floatFromInt(rl.getRandomValue(@intFromFloat(self.player.pos.y - screenHeight), @intFromFloat(self.player.pos.y + screenHeight)));
        try self.enemies.append(Enemy.init(x, y, rl.Color.green, 3));
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
    self.player.render();

    for (self.bullets.items) |*bullet| {
        bullet.render(dt);
    }

    for (self.enemies.items) |*enemy| {
        enemy.render();
    }
}

pub fn getAlloc() std.mem.Allocator {
    return arenaAlloc;
}
