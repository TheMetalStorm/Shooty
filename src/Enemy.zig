const rl = @import("raylib");
const rm = @import("raylib-math");
const std = @import("std");
const Bullet = @import("Bullet.zig");
const Player = @import("Player.zig");
const GameState = @import("GameState.zig");

pos: rl.Vector2,
color: rl.Color,
health: u16,
radius: f32 = 15.0,
const speed = 50;

const Self = @This();

pub fn init(_x: f32, _y: f32, _color: rl.Color, _health: u16) Self {
    return Self{ .pos = rl.Vector2.init(_x, _y), .color = _color, .health = _health };
}

pub fn update(self: *Self, gs: *GameState, dt: f32) void {
    const moveTowards = gs.player.pos;
    const direction = rm.vector2Subtract(moveTowards, rl.Vector2{ .x = self.pos.x, .y = self.pos.y });
    const distance = rm.vector2Length(direction);
    if (distance > 1.0) {
        const normalizedDirection = rm.vector2Normalize(direction);
        self.pos.x += normalizedDirection.x * dt * speed;
        self.pos.y += normalizedDirection.y * dt * speed;
    }
}

pub fn checkCollisions(self: *Self, gs: *GameState, enemyIndex: usize) void {
    //bullet collision
    for (gs.bullets.items) |*bullet| {
        if (!bullet.markedDead and rl.checkCollisionCircles(bullet.pos, bullet.radius, self.pos, self.radius)) {
            self.health -= 1;
            if (self.health <= 0) {
                _ = gs.enemies.orderedRemove(enemyIndex);
                gs.score += 1;
            }
            bullet.markedDead = true;
        }
    }
}

pub fn render(self: *Self) void {
    rl.drawCircle(@intFromFloat(self.pos.x), @intFromFloat(self.pos.y), self.radius, self.color);
}
