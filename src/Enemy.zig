const rl = @import("raylib");
const rm = @import("raylib-math");
const std = @import("std");
const Bullet = @import("Bullet.zig");
const Player = @import("Player.zig");
const GameState = @import("GameState.zig");
const AnimationManager = @import("AnimationManager.zig");
const RessourceManager = @import("RessourceManager.zig");

markedDead: bool = false,

pos: rl.Vector2,
type: usize,
health: i16,
alloc: *std.mem.Allocator,
animManager: *AnimationManager,
speed: usize,
wasHitThisFrame: bool = false,
const enemySpriteRect: rl.Rectangle = rl.Rectangle.init(0.0, 0.0, 16, 16);
const sizeMult: f32 = 4.0;
pub const playerLenience: f32 = 2;
const Self = @This();

pub fn init(
    _alloc: *std.mem.Allocator,
    _x: f32,
    _y: f32,
    _type: usize,
    _curLevel: usize,
) !Self {
    var _animManager = try AnimationManager.init(_alloc);

    var _health: u8 = 1;
    //clamp to player speed - lenience
    var enemyBaseSpeed: f32 = 40;
    switch (_type) {
        0 => {
            try _animManager.registerAnimation("enemy_small", try RessourceManager.getAnimation("enemy_small"));
            try _animManager.setCurrent("enemy_small");
        },
        1 => {
            try _animManager.registerAnimation("enemy_medium", try RessourceManager.getAnimation("enemy_medium"));
            try _animManager.setCurrent("enemy_medium");
            _health = 2;
            enemyBaseSpeed = 30;
        },
        2 => {
            try _animManager.registerAnimation("enemy_big", try RessourceManager.getAnimation("enemy_big"));
            try _animManager.setCurrent("enemy_big");
            _health = 3;
            enemyBaseSpeed = 20;
        },
        else => {
            try _animManager.registerAnimation("enemy_small", try RessourceManager.getAnimation("enemy_small"));
            try _animManager.setCurrent("enemy_small");
        },
    }

    var _speed: usize = @intFromFloat(rm.clamp(enemyBaseSpeed + @as(f32, @floatFromInt(_curLevel)) * 3, 0, 100 - 10));
    const a = rl.getRandomValue(0, 2);
    if (a == 0) _speed += @as(usize, @intFromFloat(enemyBaseSpeed));
    return Self{ .pos = rl.Vector2.init(_x, _y), .type = _type, .health = _health, .speed = _speed, .alloc = _alloc, .animManager = _animManager };
}

pub fn update(self: *Self, gs: *GameState, dt: f32) bool {
    self.wasHitThisFrame = false;
    if (self.markedDead) {
        gs.score += 1;
        const deathSound = try RessourceManager.getSound("enemy_dead");
        rl.playSound(deathSound.*);
        return false;
    }

    self.moveTowardsPlayer(gs, dt);
    self.checkCollisions(gs);
    return true;
}

fn moveTowardsPlayer(self: *Self, gs: *GameState, dt: f32) void {
    const moveTowards = gs.player.pos;
    const direction = rm.vector2Subtract(moveTowards, rl.Vector2{ .x = self.pos.x, .y = self.pos.y });
    const distance = rm.vector2Length(direction);
    if (distance > 1.0) {
        const normalizedDirection = rm.vector2Normalize(direction);
        self.pos.x += normalizedDirection.x * dt * @as(f32, @floatFromInt(self.speed));
        self.pos.y += normalizedDirection.y * dt * @as(f32, @floatFromInt(self.speed));
    }
}

fn checkCollisions(self: *Self, gs: *GameState) void {
    const w = enemySpriteRect.width * (@as(f32, @floatFromInt(self.type)) + sizeMult);
    const h = enemySpriteRect.height * (@as(f32, @floatFromInt(self.type)) + sizeMult);
    const enemyColRect = rl.Rectangle.init(self.pos.x - w / 2, self.pos.y - h / 2, w, h);

    if (!self.wasHitThisFrame) {
        for (gs.bullets.items) |*bullet| {
            if (!bullet.markedDead and rl.checkCollisionCircleRec(bullet.pos, bullet.radius, enemyColRect)) {
                self.health -= 1;
                if (self.health <= 0) {
                    self.markedDead = true;
                }
                bullet.markedDead = true;
                self.wasHitThisFrame = true;
            }
        }
    }

    const wP = @as(f32, @floatFromInt(gs.player.animManager.currentAnimation.spritesheet.spriteWidth)) * (Player.sizeMult - playerLenience);
    const hP = @as(f32, @floatFromInt(gs.player.animManager.currentAnimation.spritesheet.spriteHeight)) * (Player.sizeMult - playerLenience);
    const playerRect = rl.Rectangle.init(gs.player.pos.x - wP / 2, gs.player.pos.y - hP / 2, wP, hP);

    //player collision
    if (gs.player.isInvulnerable) return;
    if (gs.player.isFast) {
        if (rl.checkCollisionRecs(enemyColRect, playerRect)) {
            self.markedDead = true;
        }
    } else {
        if (rl.checkCollisionRecs(enemyColRect, playerRect)) {
            gs.player.getHurt();
        }
    }
}

pub fn render(self: *Self, dt: f32) void {
    if (self.animManager.animations.count() == 0) return;

    const size: f32 = @as(f32, @floatFromInt(self.type)) + sizeMult;
    const w = enemySpriteRect.width * size;
    const h = enemySpriteRect.height * size;

    self.animManager.playCurrent(rl.Rectangle.init(self.pos.x, self.pos.y, w, h), rl.Vector2.init(w / 2, h / 2), 0, rl.Color.white, dt);

    if (GameState.DEBUG) {
        const enemyForPlayerColRect = rl.Rectangle.init(self.pos.x - w / 2, self.pos.y - h / 2, w, h);
        rl.drawRectangleLinesEx(enemyForPlayerColRect, 4, rl.Color.white);
    }
}

pub fn deinit(self: *Self) void {
    self.animManager.deinit();
}
