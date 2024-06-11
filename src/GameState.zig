const Player = @import("Player.zig");
const Enemy = @import("Enemy.zig");
const Bullet = @import("Bullet.zig");
const rl = @import("raylib");
const rm = @import("raylib-math");

const std = @import("std");
const AnimationManager = @import("AnimationManager.zig");
const RessourceManager = @import("RessourceManager.zig");
const Item = @import("Item.zig");
const RndGen = std.rand.DefaultPrng;

camera: rl.Camera2D,
player: Player,
enemies: std.ArrayList(Enemy),
bullets: std.ArrayList(Bullet),
items: std.ArrayList(Item),
animManager: *AnimationManager,
score: usize = 0,
level: usize = 1,
wasReset: bool = false,
mainMenu: bool = true,
isPaused: bool = false,
screenWidth: f32,
screenHeight: f32,
cameraBounds: rl.Rectangle = undefined,
spawnItem: bool = true,
const Self = @This();

var rnd = RndGen.init(0);
var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
var gpa: std.mem.Allocator = undefined;

pub const DEBUG = false;
const bgSpriteRect: rl.Rectangle = rl.Rectangle.init(0.0, 0.0, 128, 256);

//TODO: BUGS: items spawn on outside of screen, limit to level area
//TODO: add sound effects, music
//TODO: ship it

pub fn init(_screenWidth: f32, _screenHeight: f32) !Self {
    gpa = general_purpose_allocator.allocator();

    const _cameraBounds = rl.Rectangle.init(-_screenWidth / 2, -_screenHeight / 2, _screenWidth, _screenHeight);
    const _player = try Player.init(&gpa, 0, 0, rl.Color.red, _cameraBounds);

    var _animManager = try AnimationManager.init(&gpa);
    try _animManager.registerAnimation("bg_1", try RessourceManager.getAnimation("bg_1"));
    try _animManager.setCurrent("bg_1");

    return Self{
        .player = _player,
        .camera = rl.Camera2D{
            .target = _player.pos,
            .offset = rl.Vector2.init(_screenWidth / 2, _screenHeight / 2),
            .rotation = 0,
            .zoom = 1,
        },
        .enemies = std.ArrayList(Enemy).init(gpa),
        .bullets = std.ArrayList(Bullet).init(gpa),
        .items = std.ArrayList(Item).init(gpa),
        .animManager = _animManager,
        .screenWidth = _screenWidth,
        .screenHeight = _screenHeight,
        .cameraBounds = _cameraBounds,
    };
}

pub fn deinit(self: *Self) void {
    self.animManager.deinit();

    for (self.enemies.items) |*enemy| {
        enemy.deinit();
    }
    self.enemies.deinit();

    for (self.bullets.items) |*bullet| {
        bullet.deinit();
    }
    self.bullets.deinit();

    for (self.items.items) |*item| {
        item.deinit();
    }
    self.items.deinit();
}

pub fn update(self: *Self, dt: f32) !void {
    const oldLevel = self.level;
    self.level = 1 + @divFloor(@as(usize, self.score), 20);
    if (oldLevel != self.level) {
        self.spawnItem = true;
    }
    try self.player.update(self, dt);
    try self.updateBullets(dt);
    try self.updateEnemies(dt);
    try self.updateItems(dt);
    self.cameraUpdate(dt);

    if (self.player.health == 0) {
        try self.resetLevel();
        self.mainMenu = true;
    }
}

fn updateItems(self: *Self, dt: f32) !void {
    if (self.spawnItem) {
        self.spawnItem = false;
        const playerX: i32 = @intFromFloat(self.player.pos.x);
        const playerY: i32 = @intFromFloat(self.player.pos.y);
        const camW: i32 = @intFromFloat(self.cameraBounds.width);
        const camH: i32 = @intFromFloat(self.cameraBounds.height);
        const halfCamH = @divFloor(camH, 2);
        const halfCamW = @divFloor(camW, 2);

        const x = rl.getRandomValue(playerX - halfCamW, playerX + halfCamW);
        const y = rl.getRandomValue(playerY - halfCamH, playerY + halfCamH);
        const xF32: f32 = @as(f32, @floatFromInt(x));
        const yF32: f32 = @as(f32, @floatFromInt(y));
        const itemType = rl.getRandomValue(0, 2);
        try self.items.append(try Item.init(&gpa, @enumFromInt(itemType), rl.Vector2.init(xF32, yF32)));
    }

    var itemsToRemove = std.ArrayList(usize).init(gpa);
    defer itemsToRemove.deinit();

    for (self.items.items, 0..) |*item, index| {
        const active = try item.update(self, dt);
        if (!active) {
            try itemsToRemove.append(index);
        }
    }

    std.mem.reverse(usize, itemsToRemove.items);

    for (itemsToRemove.items) |index| {
        var removed = self.items.orderedRemove(index);
        removed.deinit();
    }
}

fn updateBullets(self: *Self, dt: f32) !void {
    var bulletsToRemove = std.ArrayList(usize).init(gpa);
    defer bulletsToRemove.deinit();
    for (self.bullets.items, 0..) |*bullet, index| {
        const active = try bullet.update(dt);
        if (!active) {
            try bulletsToRemove.append(index);
        }
    }

    std.mem.reverse(usize, bulletsToRemove.items);
    for (bulletsToRemove.items) |index| {
        var removed = self.bullets.orderedRemove(index);
        removed.deinit();
    }
}

fn updateEnemies(self: *Self, dt: f32) !void {
    if (self.enemies.items.len < 15 + self.level) {
        const dir = rl.getRandomValue(0, 3);
        var x: i32 = 0;
        var y: i32 = 0;
        const playerX: i32 = @intFromFloat(self.player.pos.x);
        const playerY: i32 = @intFromFloat(self.player.pos.y);
        const camW: i32 = @intFromFloat(self.cameraBounds.width);
        const camH: i32 = @intFromFloat(self.cameraBounds.height);
        const halfCamH = @divFloor(camH, 2);
        const halfCamW = @divFloor(camW, 2);

        switch (dir) {
            //n
            0 => {
                x = rl.getRandomValue(playerX - halfCamW, playerX + halfCamW);
                y = playerY + halfCamH + 100;
            },
            //e
            1 => {
                x = playerX + halfCamW + 100;
                y = rl.getRandomValue(playerY - halfCamH, playerY + halfCamH);
            },
            //s
            2 => {
                x = rl.getRandomValue(playerX - halfCamW, playerX + halfCamW);
                y = playerY - halfCamH - 100;
            },
            //w
            3 => {
                x = playerX - halfCamW - 100;
                y = rl.getRandomValue(playerY - halfCamH, playerY + halfCamH);
            },
            else => {},
        }

        const xF32: f32 = @as(f32, @floatFromInt(x));
        const yF32: f32 = @as(f32, @floatFromInt(y));

        const some_random_num = rl.getRandomValue(0, 10);
        switch (some_random_num) {
            0...5 => {
                try self.enemies.append(try Enemy.init(&gpa, xF32, yF32, 0, self.level));
            },
            6...9 => {
                try self.enemies.append(try Enemy.init(&gpa, xF32, yF32, 1, self.level));
            },
            10 => {
                try self.enemies.append(try Enemy.init(&gpa, xF32, yF32, 2, self.level));
            },
            else => {
                try self.enemies.append(try Enemy.init(&gpa, xF32, yF32, 0, self.level));
            },
        }
    }
    var enemiesToRemove = std.ArrayList(usize).init(gpa);
    defer enemiesToRemove.deinit();
    for (self.enemies.items, 0..) |*enemy, index| {
        const alive = enemy.update(self, dt);
        if (!alive) {
            try enemiesToRemove.append(index);
        }
    }

    std.mem.reverse(usize, enemiesToRemove.items);
    for (enemiesToRemove.items) |index| {
        var removed = self.enemies.orderedRemove(index);
        removed.deinit();
    }
}

fn cameraUpdate(self: *Self, dt: f32) void {
    const lerp = 5;
    self.camera.target.x += (self.player.pos.x - self.camera.target.x) * lerp * dt;
    self.camera.target.y += (self.player.pos.y - self.camera.target.y) * lerp * dt;

    if (self.camera.target.x < self.cameraBounds.x) {
        self.camera.target.x = self.cameraBounds.x;
    } else if (self.camera.target.x > self.cameraBounds.width / 2) {
        self.camera.target.x = self.cameraBounds.width / 2;
    }
    if (self.camera.target.y < self.cameraBounds.y) {
        self.camera.target.y = self.cameraBounds.y;
    } else if (self.camera.target.y > self.cameraBounds.height / 2) {
        self.camera.target.y = self.cameraBounds.height / 2;
    }
}

pub fn resetLevel(self: *Self) !void {
    self.wasReset = true;
    self.score = 0;
    self.deinit();
    self.* = try Self.init(self.screenWidth, self.screenHeight);
}

pub fn render(self: *Self, dt: f32) !void {

    //dont render if the game was reset
    if (self.wasReset) {
        self.wasReset = false;
        return;
    }

    self.renderBG();

    for (self.items.items) |*item| {
        try item.render(self, dt);
    }

    for (self.bullets.items) |*bullet| {
        try bullet.render(dt);
    }

    self.player.render(dt);

    for (self.enemies.items) |*enemy| {
        enemy.render(dt);
    }
}

fn renderBG(self: *Self) void {
    const bgSize = 2;

    for (0..100) |w| {
        for (0..100) |h| {
            rl.drawTexturePro(self.animManager.currentAnimation.spritesheet.spritesheet.*, bgSpriteRect, rl.Rectangle.init(@as(f32, @floatFromInt(w)) * bgSpriteRect.width * bgSize, @as(f32, @floatFromInt(h)) * bgSpriteRect.height * bgSize, bgSpriteRect.width * bgSize, bgSpriteRect.height * bgSize), rl.Vector2.init(0, 0), 0, rl.Color.white);
            rl.drawTexturePro(self.animManager.currentAnimation.spritesheet.spritesheet.*, bgSpriteRect, rl.Rectangle.init(-@as(f32, @floatFromInt(w)) * bgSpriteRect.width * bgSize, -@as(f32, @floatFromInt(h)) * bgSpriteRect.height * bgSize, bgSpriteRect.width * bgSize, bgSpriteRect.height * bgSize), rl.Vector2.init(0, 0), 0, rl.Color.white);
            rl.drawTexturePro(self.animManager.currentAnimation.spritesheet.spritesheet.*, bgSpriteRect, rl.Rectangle.init(@as(f32, @floatFromInt(w)) * bgSpriteRect.width * bgSize, -@as(f32, @floatFromInt(h)) * bgSpriteRect.height * bgSize, bgSpriteRect.width * bgSize, bgSpriteRect.height * bgSize), rl.Vector2.init(0, 0), 0, rl.Color.white);
            rl.drawTexturePro(self.animManager.currentAnimation.spritesheet.spritesheet.*, bgSpriteRect, rl.Rectangle.init(-@as(f32, @floatFromInt(w)) * bgSpriteRect.width * bgSize, @as(f32, @floatFromInt(h)) * bgSpriteRect.height * bgSize, bgSpriteRect.width * bgSize, bgSpriteRect.height * bgSize), rl.Vector2.init(0, 0), 0, rl.Color.white);
        }
    }
}
