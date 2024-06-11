const rl = @import("raylib");
const rm = @import("raylib-math");
const std = @import("std");
const Bullet = @import("Bullet.zig");
const GameState = @import("GameState.zig");
const Enemy = @import("Enemy.zig");
const AnimationManager = @import("AnimationManager.zig");
const RessourceManager = @import("RessourceManager.zig");

pos: rl.Vector2,
color: rl.Color,
alloc: *std.mem.Allocator,
animManager: *AnimationManager,
levelBounds: rl.Rectangle,
health: usize = 3,
isInvulnerable: bool = false,
wasHitThisFrame: bool = false,
isFast: bool = false,

pub const sizeMult: f32 = 3.0;
const shipIdleSpriteRect: rl.Rectangle = rl.Rectangle.init(0.0, 0.0, 16, 24);
const normalSpeed: f32 = 100.0;
const fastSpeed: f32 = 200.0;
const bulletSpeed: f32 = 200.0;
const Self = @This();

var texture: rl.Texture2D = undefined;
var lookDir: rl.Vector2 = undefined;
var bulletTimer: f32 = 0;
var bulletWaitTime: f32 = 0.5;
var invulnerableTimer: f32 = 0;
var invulnerableTime: f32 = 2;
pub fn getLookDir(_: *Self) rl.Vector2 {
    return lookDir;
}

pub fn init(_alloc: *std.mem.Allocator, _x: f32, _y: f32, _color: rl.Color, _levelBounds: rl.Rectangle) !Self {
    var _animManager = try AnimationManager.init(_alloc);
    try _animManager.registerAnimation("ship_normal", try RessourceManager.getAnimation("ship_normal"));
    try _animManager.setCurrent("ship_normal");
    return Self{ .pos = rl.Vector2.init(_x, _y), .color = _color, .alloc = _alloc, .animManager = _animManager, .levelBounds = _levelBounds };
}

pub fn update(self: *Self, gs: *GameState, dt: f32) !void {
    self.wasHitThisFrame = false;

    self.updateInvulnerability(dt);
    self.updateMovement(dt, gs);
    try self.updateShooting(dt, gs);
}

fn updateShooting(self: *Self, dt: f32, gs: *GameState) !void {
    if (rl.isMouseButtonDown(rl.MouseButton.mouse_button_left)) {
        bulletTimer -= dt;
        if (bulletTimer < 0) {
            var spawned = try Bullet.init(self.alloc, self.pos.x, self.pos.y, lookDir, bulletSpeed, rl.Color.blue);
            try spawned.animManager.setCurrent("bullet_normal");
            try gs.bullets.append(spawned);
            bulletTimer = bulletWaitTime;
        }
    }

    if (rl.isMouseButtonReleased(rl.MouseButton.mouse_button_left)) {
        bulletTimer = -1;
    }
}

fn updateMovement(self: *Self, dt: f32, gs: *GameState) void {
    const dir = rm.vector2Subtract(rl.getScreenToWorld2D(rl.getMousePosition(), gs.camera), rl.Vector2.init(self.pos.x, self.pos.y));
    const dirNorm = rm.vector2Normalize(dir);
    lookDir = dirNorm;
    const speed = if (self.isFast) fastSpeed else normalSpeed;
    if (rl.isKeyDown(rl.KeyboardKey.key_d)) {
        self.pos.x += speed * dt;
    }
    if (rl.isKeyDown(rl.KeyboardKey.key_a)) {
        self.pos.x -= speed * dt;
    }

    if (rl.isKeyDown(rl.KeyboardKey.key_w)) {
        self.pos.y -= speed * dt;
    }
    if (rl.isKeyDown(rl.KeyboardKey.key_s)) {
        self.pos.y += speed * dt;
    }

    std.debug.print("PLAYER: {any}\n", .{self.pos});

    if (self.pos.x < -self.levelBounds.width) {
        self.pos.x = -self.levelBounds.width;
    } else if (self.pos.x > self.levelBounds.width) {
        self.pos.x = self.levelBounds.width;
    }

    if (self.pos.y < -self.levelBounds.height) {
        self.pos.y = -self.levelBounds.height;
    } else if (self.pos.y > self.levelBounds.height) {
        self.pos.y = self.levelBounds.height;
    }
}

fn updateInvulnerability(self: *Self, dt: f32) void {
    if (self.isInvulnerable) {
        invulnerableTimer -= dt;
    }
    if (invulnerableTimer <= 0) {
        self.isInvulnerable = false;
        invulnerableTimer = invulnerableTime;
    }
}

pub fn render(self: *Self, dt: f32) void {
    if (self.animManager.animations.count() == 0) return;
    const w = shipIdleSpriteRect.width * sizeMult;
    const h = shipIdleSpriteRect.height * sizeMult;
    const viewAngle = @mod(std.math.radiansToDegrees(std.math.atan2(lookDir.y, lookDir.x)) + 360 + 90, 360); // 90 is the offset to make the ship face the mouse
    if (self.isInvulnerable) {
        if (@mod(invulnerableTimer, 0.3) < 0.05) {
            self.animManager.playCurrent(rl.Rectangle.init(self.pos.x, self.pos.y, w, h), rl.Vector2.init(w / 2, h / 2), viewAngle, rl.Color.white, dt);
        }
    } else {
        self.animManager.playCurrent(rl.Rectangle.init(self.pos.x, self.pos.y, w, h), rl.Vector2.init(w / 2, h / 2), viewAngle, rl.Color.white, dt);
    }

    const wWithEnemy = shipIdleSpriteRect.width * (sizeMult - Enemy.playerLenience);
    const hWithEnemy = shipIdleSpriteRect.height * (sizeMult - Enemy.playerLenience);

    if (GameState.DEBUG) {
        //normal HB
        const playerCol = rl.Rectangle.init(self.pos.x - w / 2, self.pos.y - h / 2, w, h);
        rl.drawRectangleLinesEx(playerCol, 4, rl.Color.white);

        //HB with enemy
        const playerEnemyCol = rl.Rectangle.init(self.pos.x - wWithEnemy / 2, self.pos.y - hWithEnemy / 2, wWithEnemy, hWithEnemy);
        rl.drawRectangleLinesEx(playerEnemyCol, 4, rl.Color.red);
    }
}

pub fn deinit(_: *Self) void {
    rl.unloadTexture(texture);
}

pub fn getHurt(self: *Self) void {
    if (self.wasHitThisFrame) return;
    self.health -= 1;
    self.isInvulnerable = true;
}
