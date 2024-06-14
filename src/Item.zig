const std = @import("std");
const rl = @import("raylib");
const rm = @import("raylib-math");
const GameState = @import("GameState.zig");
const Player = @import("Player.zig");
const RessourceManager = @import("RessourceManager.zig");
const AnimationManager = @import("AnimationManager.zig");

pub const ItemType = enum { BOMB, HEALTH, SPEED };

itemType: ItemType = undefined,
pos: rl.Vector2 = undefined,
animManager: *AnimationManager = undefined,
markedCollected: bool = false,
timer: f32 = 0,
var soundEffect: *rl.Sound = undefined;
const bombRadius: f32 = 400;
const bombRadiusLifetime: f32 = 2;
const healthRadius: f32 = 100;
const healthLifetime: f32 = 0.5;

const itemSpriteRect: rl.Rectangle = rl.Rectangle.init(0.0, 0.0, 16, 16);
const sizeMult: f32 = 2.0;
const Self = @This();

pub fn init(_alloc: *std.mem.Allocator, _itemType: ItemType, _pos: rl.Vector2) !Self {
    const _animManager = try AnimationManager.init(_alloc);

    //depending on type assign animation
    switch (_itemType) {
        ItemType.BOMB => {
            soundEffect = try RessourceManager.getSound("bomb");
            try _animManager.registerAnimation("item_bomb", try RessourceManager.getAnimation("item_bomb"));
            try _animManager.setCurrent("item_bomb");
        },
        ItemType.HEALTH => {
            soundEffect = try RessourceManager.getSound("health");
            try _animManager.registerAnimation("item_health", try RessourceManager.getAnimation("item_health"));
            try _animManager.setCurrent("item_health");
        },
        ItemType.SPEED => {
            soundEffect = try RessourceManager.getSound("health");
            try _animManager.registerAnimation("item_speed", try RessourceManager.getAnimation("item_speed"));
            try _animManager.setCurrent("item_speed");
        },
    }

    return Self{ .itemType = _itemType, .pos = _pos, .animManager = _animManager };
}

pub fn update(self: *Self, gs: *GameState, dt: f32) !bool {
    if (self.markedCollected) {
        if (self.timer == 0) rl.playSound(soundEffect.*);
        self.timer += dt;

        switch (self.itemType) {
            ItemType.BOMB => {
                if (self.timer > bombRadiusLifetime) {
                    return false;
                }
                for (gs.enemies.items) |*enemy| {
                    if (rm.vector2Distance(self.pos, enemy.pos) < bombRadius * self.timer / bombRadiusLifetime) {
                        enemy.markedDead = true;
                    }
                }
            },
            ItemType.HEALTH => {
                if (self.timer > healthLifetime) {
                    return false;
                }
            },
            ItemType.SPEED => {
                //handled by player
                return false;
            },
        }
        return true;
    }

    const wP = @as(f32, @floatFromInt(gs.player.animManager.currentAnimation.spritesheet.spriteWidth)) * (Player.sizeMult);
    const hP = @as(f32, @floatFromInt(gs.player.animManager.currentAnimation.spritesheet.spriteHeight)) * (Player.sizeMult);
    const playerRect = rl.Rectangle.init(gs.player.pos.x - wP / 2, gs.player.pos.y - hP / 2, wP, hP);

    const w = itemSpriteRect.width * sizeMult;
    const h = itemSpriteRect.height * sizeMult;
    const itemColRect = rl.Rectangle.init(self.pos.x - w / 2, self.pos.y - h / 2, w, h);

    if (rl.checkCollisionRecs(itemColRect, playerRect)) {
        switch (self.itemType) {
            ItemType.BOMB => {},
            ItemType.HEALTH => {
                gs.player.health += 1;
            },
            ItemType.SPEED => {
                if (gs.player.isFast) {
                    gs.player.isFastTimer = Player.isFastTime;
                } else {
                    gs.player.isFast = true;
                }
            },
        }
        self.markedCollected = true;
    }
    return true;
}

pub fn render(self: *Self, gs: *GameState, dt: f32) !void {
    if (self.markedCollected) {
        switch (self.itemType) {
            ItemType.BOMB => {
                rl.drawCircleGradient(@as(i32, @intFromFloat(self.pos.x)), @as(i32, @intFromFloat(self.pos.y)), rm.clamp(bombRadius * self.timer / bombRadiusLifetime - 20, 0, bombRadius), rl.Color.red, rl.Color.orange);
            },
            ItemType.HEALTH => {
                rl.drawCircleLinesV(gs.player.pos, healthRadius - (healthRadius * self.timer / healthLifetime), rl.Color.sky_blue);
                rl.drawCircleLinesV(gs.player.pos, rm.clamp(healthRadius - 20 - (healthRadius * self.timer / healthLifetime), 0, healthRadius), rl.Color.sky_blue);
                rl.drawCircleLinesV(gs.player.pos, rm.clamp(healthRadius + 20 - (healthRadius * self.timer / healthLifetime), 0, healthRadius), rl.Color.sky_blue);
            },

            ItemType.SPEED => {
                //handled by player
            },
        }
        return;
    }
    if (self.animManager.animations.count() == 0) return;
    const w = itemSpriteRect.width * sizeMult;
    const h = itemSpriteRect.height * sizeMult;

    if (GameState.DEBUG) {
        const itemColRect = rl.Rectangle.init(self.pos.x - w / 2, self.pos.y - h / 2, w, h);
        rl.drawRectangleLinesEx(itemColRect, 4, rl.Color.white);
    }

    self.animManager.playCurrent(rl.Rectangle.init(self.pos.x, self.pos.y, w, h), rl.Vector2.init(w / 2, h / 2), 0, rl.Color.white, dt);
}

pub fn deinit(self: *Self) void {
    self.animManager.deinit();
}
