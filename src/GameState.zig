const Player = @import("Player.zig");
const Enemy = @import("Enemy.zig");
const Bullet = @import("Bullet.zig");
const rl = @import("raylib");
const std = @import("std");
const AnimationManager = @import("AnimationManager.zig");
const RessourceManager = @import("RessourceManager.zig");
camera: rl.Camera2D,
player: Player,
enemies: std.ArrayList(Enemy),
bullets: std.ArrayList(Bullet),
animManager: *AnimationManager,

score: i32 = 0,

wasReset: bool = false,
const Self = @This();
const screenWidth = 800;
const screenHeight = 450;

var levelArena: std.heap.ArenaAllocator = undefined;
var levelAlloc: std.mem.Allocator = undefined;
const bgSpriteRect: rl.Rectangle = rl.Rectangle.init(0.0, 0.0, 128, 256);
const cameraBounds: rl.Rectangle = rl.Rectangle.init(-screenWidth, -screenHeight, screenWidth * 2, screenHeight * 2);
//TODO: make game infinetly playable by addding more/faster/different enemies as the player progresses
//TODO: maybe items? health packs, ammo, weapons, etc.

//TODO: game over screen when dead -> start at level one
//TODO: make player vulnerable to enemy, blink when hurt and for a few seconds after being hit, invurnable for a few seconds after being hit
//TODO: add sound effects, music
//TODO: ship it

pub fn init() !Self {
    levelArena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    levelAlloc = levelArena.allocator();

    const _player = try Player.init(&levelAlloc, 150.0, 150.0, rl.Color.red, cameraBounds);

    var _animManager = try AnimationManager.init(&levelAlloc);
    try _animManager.registerAnimation("bg_1", try RessourceManager.getAnimation("bg_1"));
    try _animManager.setCurrent("bg_1");

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
        .animManager = _animManager,
    };
}

pub fn deinit(_: *Self) void {
    levelArena.deinit();
}

pub fn update(self: *Self, dt: f32) !void {
    if (self.score == 10) {
        try self.resetLevel();
        return;
    }

    try self.player.update(self, dt);

    for (self.bullets.items) |*bullet| {
        if (bullet.active)
            bullet.update(dt);
    }

    if (self.enemies.items.len < 20) {

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
    if (self.camera.target.x < cameraBounds.x) {
        self.camera.target.x = cameraBounds.x;
    } else if (self.camera.target.x > cameraBounds.width) {
        self.camera.target.x = cameraBounds.width;
    }
    if (self.camera.target.y < cameraBounds.y) {
        self.camera.target.y = cameraBounds.y;
    } else if (self.camera.target.y > cameraBounds.height) {
        self.camera.target.y = cameraBounds.height;
    }
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
    const bgSize = 2;

    //rl.drawTexturePro(self.animManager.currentAnimation.spritesheet.spritesheet.*, bgSpriteRect, rl.Rectangle.init(bgSpriteRect.width, bgSpriteRect.height, bgSpriteRect.width * bgSize, bgSpriteRect.height * bgSize), rl.Vector2.init(0, 0), 0, rl.Color.white);

    for (0..100) |w| {
        for (0..100) |h| {
            rl.drawTexturePro(self.animManager.currentAnimation.spritesheet.spritesheet.*, bgSpriteRect, rl.Rectangle.init(@as(f32, @floatFromInt(w)) * bgSpriteRect.width * bgSize, @as(f32, @floatFromInt(h)) * bgSpriteRect.height * bgSize, bgSpriteRect.width * bgSize, bgSpriteRect.height * bgSize), rl.Vector2.init(0, 0), 0, rl.Color.white);
            rl.drawTexturePro(self.animManager.currentAnimation.spritesheet.spritesheet.*, bgSpriteRect, rl.Rectangle.init(-@as(f32, @floatFromInt(w)) * bgSpriteRect.width * bgSize, -@as(f32, @floatFromInt(h)) * bgSpriteRect.height * bgSize, bgSpriteRect.width * bgSize, bgSpriteRect.height * bgSize), rl.Vector2.init(0, 0), 0, rl.Color.white);
            rl.drawTexturePro(self.animManager.currentAnimation.spritesheet.spritesheet.*, bgSpriteRect, rl.Rectangle.init(@as(f32, @floatFromInt(w)) * bgSpriteRect.width * bgSize, -@as(f32, @floatFromInt(h)) * bgSpriteRect.height * bgSize, bgSpriteRect.width * bgSize, bgSpriteRect.height * bgSize), rl.Vector2.init(0, 0), 0, rl.Color.white);
            rl.drawTexturePro(self.animManager.currentAnimation.spritesheet.spritesheet.*, bgSpriteRect, rl.Rectangle.init(-@as(f32, @floatFromInt(w)) * bgSpriteRect.width * bgSize, @as(f32, @floatFromInt(h)) * bgSpriteRect.height * bgSize, bgSpriteRect.width * bgSize, bgSpriteRect.height * bgSize), rl.Vector2.init(0, 0), 0, rl.Color.white);
        }
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
