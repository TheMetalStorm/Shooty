const rl = @import("raylib");
const rm = @import("raylib-math");
const std = @import("std");
const Bullet = @import("Bullet.zig");
const Player = @import("Player.zig");
const GameState = @import("GameState.zig");
const AnimationManager = @import("AnimationManager.zig");
const RessourceManager = @import("RessourceManager.zig");

markedDead: bool = false,
active: bool = true,

pos: rl.Vector2,
type: usize,
health: u8,
alloc: *std.mem.Allocator,
animManager: *AnimationManager,
speed: usize,

const enemySpriteRect: rl.Rectangle = rl.Rectangle.init(0.0, 0.0, 16, 16);

const Self = @This();

pub fn init(
    _alloc: *std.mem.Allocator,
    _x: f32,
    _y: f32,
    _type: usize,
) !Self {
    var _animManager = try AnimationManager.init(_alloc);

    var _health: u8 = 1;
    var _speed: usize = 40;

    switch (_type) {
        0 => {
            try _animManager.registerAnimation("enemy_small", try RessourceManager.getAnimation("enemy_small"));
            try _animManager.setCurrent("enemy_small");
        },
        1 => {
            try _animManager.registerAnimation("enemy_medium", try RessourceManager.getAnimation("enemy_medium"));
            try _animManager.setCurrent("enemy_medium");
            _health = 2;
            _speed = 30;
        },
        2 => {
            try _animManager.registerAnimation("enemy_big", try RessourceManager.getAnimation("enemy_big"));
            try _animManager.setCurrent("enemy_big");
            _health = 3;
            _speed = 20;
        },
        else => {
            try _animManager.registerAnimation("enemy_small", try RessourceManager.getAnimation("enemy_small"));
            try _animManager.setCurrent("enemy_small");
        },
    }

    return Self{ .pos = rl.Vector2.init(_x, _y), .type = _type, .health = _health, .speed = _speed, .alloc = _alloc, .animManager = _animManager };
}

pub fn update(self: *Self, gs: *GameState, dt: f32) void {
    if (self.markedDead) {
        self.active = false;
        return;
    }

    const moveTowards = gs.player.pos;
    const direction = rm.vector2Subtract(moveTowards, rl.Vector2{ .x = self.pos.x, .y = self.pos.y });
    const distance = rm.vector2Length(direction);
    if (distance > 1.0) {
        const normalizedDirection = rm.vector2Normalize(direction);
        self.pos.x += normalizedDirection.x * dt * @as(f32, @floatFromInt(self.speed));
        self.pos.y += normalizedDirection.y * dt * @as(f32, @floatFromInt(self.speed));
    }
    self.checkCollisions(gs);
}

pub fn checkCollisions(self: *Self, gs: *GameState) void {
    const w = @as(f32, @floatFromInt(self.animManager.currentAnimation.spritesheet.spriteWidth));
    const h = @as(f32, @floatFromInt(self.animManager.currentAnimation.spritesheet.spriteHeight));
    const enemyRect = rl.Rectangle.init(self.pos.x - w / 2, self.pos.y - h / 2, w, h);

    //bullet collision
    for (gs.bullets.items) |*bullet| {
        if (!bullet.markedDead and rl.checkCollisionCircleRec(bullet.pos, bullet.radius, enemyRect)) {
            self.health -= 1;
            if (self.health <= 0) {
                self.markedDead = true;
                gs.score += 1;
            }
            bullet.markedDead = true;
        }
    }

    //player collision
    //TODO: BUG: sometimes the player gets hit multiple times in one frame
    if (!gs.player.isInvulnerable) {
        const wP = @as(f32, @floatFromInt(gs.player.animManager.currentAnimation.spritesheet.spriteWidth));
        const hP = @as(f32, @floatFromInt(gs.player.animManager.currentAnimation.spritesheet.spriteHeight));
        const playerRect = rl.Rectangle.init(gs.player.pos.x - wP / 2, gs.player.pos.y - hP / 2, w, h);

        if (rl.checkCollisionRecs(enemyRect, playerRect)) {
            gs.player.getHurt();
        }
    }
}

pub fn render(self: *Self, dt: f32) void {
    const sizeMult: f32 = @as(f32, @floatFromInt(self.type + 2));
    self.animManager.playCurrent(rl.Rectangle.init(self.pos.x, self.pos.y, enemySpriteRect.width * sizeMult, enemySpriteRect.height * sizeMult), rl.Vector2.init(enemySpriteRect.width * sizeMult / 2, enemySpriteRect.height * sizeMult / 2), 0, rl.Color.white, dt);
}
