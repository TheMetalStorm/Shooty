const rl = @import("raylib");
const rm = @import("raylib-math");
const std = @import("std");
const Bullet = @import("Bullet.zig");
const GameState = @import("GameState.zig");

pos: rl.Vector2,
color: rl.Color,

const shipIdleSpriteRect: rl.Rectangle = rl.Rectangle.init(31.0, 0.0, 16, 24);
const speed = 100.0;
const bulletSpeed = 200.0;
const Self = @This();

var texture: rl.Texture2D = undefined;
var lookDir: rl.Vector2 = undefined;

pub fn getLookDir(_: *Self) rl.Vector2 {
    return lookDir;
}

pub fn init(_x: f32, _y: f32, _color: rl.Color) Self {
    texture = rl.Texture2D.init("src/assets/spritesheets/ship.png");
    return Self{ .pos = rl.Vector2.init(_x, _y), .color = _color };
}

pub fn update(self: *Self, gs: *GameState, dt: f32) !void {
    const dir = rm.vector2Subtract(rl.getScreenToWorld2D(rl.getMousePosition(), gs.camera), rl.Vector2.init(self.pos.x, self.pos.y));
    const dirNorm = rm.vector2Normalize(dir);
    lookDir = dirNorm;

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

    if (rl.isMouseButtonPressed(rl.MouseButton.mouse_button_left)) {
        var spawned = try Bullet.init(self.pos.x, self.pos.y, lookDir, bulletSpeed, rl.Color.blue);
        spawned.setAnimation("normal");
        try gs.bullets.append(spawned);
    }
}

pub fn render(self: *Self) void {
    const viewAngle = @mod(std.math.radiansToDegrees(std.math.atan2(lookDir.y, lookDir.x)) + 360 + 90, 360); // 90 is the offset to make the ship face the mouse
    const sizeMult = 2;
    rl.drawTexturePro(texture, shipIdleSpriteRect, rl.Rectangle.init(self.pos.x, self.pos.y, shipIdleSpriteRect.width * sizeMult, shipIdleSpriteRect.height * sizeMult), rl.Vector2.init(shipIdleSpriteRect.width * sizeMult / 2, shipIdleSpriteRect.height * sizeMult / 2), viewAngle, rl.Color.white);
}

pub fn deinit(_: *Self) void {
    rl.unloadTexture(texture);
}
