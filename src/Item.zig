const std = @import("std");
const rl = @import("raylib");
const GameState = @import("GameState.zig");
const Player = @import("Player.zig");
const RessourceManager = @import("RessourceManager.zig");
const AnimationManager = @import("AnimationManager.zig");

pub const ItemType = enum {
    BOMB,
};

itemType: ItemType = undefined,
pos: rl.Vector2 = undefined,
animManager: *AnimationManager = undefined,
active: bool = true,
//TODO: figure out actual size
const itemSpriteRect: rl.Rectangle = rl.Rectangle.init(0.0, 0.0, 16, 16);
const sizeMult: f32 = 2.0;
const Self = @This();

pub fn init(_alloc: *std.mem.Allocator, _itemType: ItemType, _pos: rl.Vector2) !Self {
    const _animManager = try AnimationManager.init(_alloc);

    //depending on type assign animation
    switch (_itemType) {
        ItemType.BOMB => {
            try _animManager.registerAnimation("item_bomb", try RessourceManager.getAnimation("item_bomb"));
            try _animManager.setCurrent("item_bomb");
        },
    }

    return Self{ .itemType = _itemType, .pos = _pos, .animManager = _animManager };
}

pub fn update(self: *Self, gs: *GameState) !void {
    const wP = @as(f32, @floatFromInt(gs.player.animManager.currentAnimation.spritesheet.spriteWidth)) * (Player.sizeMult);
    const hP = @as(f32, @floatFromInt(gs.player.animManager.currentAnimation.spritesheet.spriteHeight)) * (Player.sizeMult);
    const playerRect = rl.Rectangle.init(gs.player.pos.x - wP / 2, gs.player.pos.y - hP / 2, wP, hP);

    const w = itemSpriteRect.width * sizeMult;
    const h = itemSpriteRect.height * sizeMult;
    const itemColRect = rl.Rectangle.init(self.pos.x - w / 2, self.pos.y - h / 2, w, h);

    if (rl.checkCollisionRecs(itemColRect, playerRect)) {
        switch (self.itemType) {
            ItemType.BOMB => {
                self.active = false;
            },
        }
    }
}

pub fn render(self: *Self, dt: f32) !void {
    if (self.animManager.animations.count() == 0) return;
    const w = itemSpriteRect.width * sizeMult;
    const h = itemSpriteRect.height * sizeMult;

    if (GameState.DEBUG) {
        const itemColRect = rl.Rectangle.init(self.pos.x - w / 2, self.pos.y - h / 2, w, h);
        rl.drawRectangleLinesEx(itemColRect, 4, rl.Color.white);
    }

    self.animManager.playCurrent(rl.Rectangle.init(self.pos.x, self.pos.y, w, h), rl.Vector2.init(w / 2, h / 2), 0, rl.Color.white, dt);
}
