const std = @import("std");
const rl = @import("raylib");
const Player = @import("Player.zig");
const Enemy = @import("Enemy.zig");
const Bullet = @import("Bullet.zig");
const Animation = @import("Animation.zig");
const GameState = @import("GameState.zig");
const Spritesheet = @import("Spritesheet.zig");
const RessourceManager = @import("RessourceManager.zig");

const screenWidth = 800;
const screenHeight = 450;

pub fn main() !void {
    rl.initWindow(screenWidth, screenHeight, "Shooty");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    try RessourceManager.init("src/assets/");
    try setupRessources();
    var gs = try GameState.init();

    while (!rl.windowShouldClose()) {

        //update
        const dt = rl.getFrameTime();

        try gs.update(dt);

        //render
        rl.beginDrawing();
        gs.camera.begin();

        rl.clearBackground(rl.Color.fromInt(0x052c46ff));
        try gs.render(dt);
        gs.camera.end();
        drawGUI(&gs);
        rl.endDrawing();
    }
    gs.deinit();
    RessourceManager.deinit();
}

fn drawGUI(gs: *GameState) void {
    rl.drawText(rl.textFormat("Score: %02i", .{gs.score}), 20, 20, 20, rl.Color.red);
    rl.drawText(rl.textFormat("Frame Time: %02f", .{rl.getFrameTime()}), 20, 60, 20, rl.Color.red);
    rl.drawText(rl.textFormat("FPS: %.2f", .{1.0 / rl.getFrameTime()}), 20, 80, 20, rl.Color.red);
}

fn setupRessources() !void {
    //INFO: Set the spritesheets heres
    try RessourceManager.loadSpritesheet("spritesheets/ship.png", 5, 2, 16, 24);
    try RessourceManager.loadSpritesheet("spritesheets/laser-bolts.png", 2, 2, 16, 16);
    try RessourceManager.loadSpritesheet("spritesheets/explosion.png", 5, 1, 16, 16);
    try RessourceManager.loadSpritesheet("SpaceShooterAssets/SpaceShooterAssetPack_Characters.png", 5, 10, 8, 8);
    try RessourceManager.loadSpritesheet("SpaceShooterAssets/SpaceShooterAssetPack_BackGrounds.png", 3, 2, 128, 256);

    //INFO: Set the Animations here
    try RessourceManager.loadAnimation("bg_1", "SpaceShooterAssets/SpaceShooterAssetPack_BackGrounds.png", 10, &[_]usize{1}, true);
    try RessourceManager.loadAnimation("ship_normal", "spritesheets/ship.png", 10, &[_]usize{ 2, 7 }, true);
    try RessourceManager.loadAnimation("bullet_normal", "spritesheets/laser-bolts.png", 50, &[_]usize{ 0, 1 }, true);
    try RessourceManager.loadAnimation("bullet_die", "spritesheets/explosion.png", 30, &[_]usize{ 0, 1, 2, 3, 4 }, false);
}
