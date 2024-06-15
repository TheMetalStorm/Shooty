const std = @import("std");
const rl = @import("raylib");
const Player = @import("Player.zig");
const Enemy = @import("Enemy.zig");
const Bullet = @import("Bullet.zig");

const Item = @import("Item.zig");
const Animation = @import("Animation.zig");
const AnimationManager = @import("AnimationManager.zig");
const GameState = @import("GameState.zig");
const Spritesheet = @import("Spritesheet.zig");
const RessourceManager = @import("RessourceManager.zig");
const c = @cImport({
    @cInclude("raylib.h");
});

var ressourceArena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var ressourceAlloc = ressourceArena.allocator();
var menuItemSpeedAnimManager: *AnimationManager = undefined;
var menuItemHealthAnimManager: *AnimationManager = undefined;
var menuItemBombAnimManager: *AnimationManager = undefined;
var menuPlayerAnimManager: *AnimationManager = undefined;
const itemSpriteRect: rl.Rectangle = rl.Rectangle.init(0.0, 0.0, 16, 16);
const shipIdleSpriteRect: rl.Rectangle = rl.Rectangle.init(0.0, 0.0, 16, 24);

const screenWidth = 1600;
const screenHeight = 900;

pub fn run() !void {
    rl.initWindow(screenWidth, screenHeight, "Shooty");
    defer rl.closeWindow();
    rl.initAudioDevice();
    defer rl.closeAudioDevice();
    rl.setTargetFPS(60);

    const wd = rl.getWorkingDirectory();
    const assetsDir = "/assets/";
    const fullAssetDir = try std.fmt.allocPrint(ressourceAlloc, "{s}{s}", .{ wd, assetsDir });

    try RessourceManager.init(fullAssetDir, ressourceAlloc);
    try setupRessources();

    var gs = try GameState.init(@as(f32, @floatFromInt(screenWidth)), @as(f32, @floatFromInt(screenHeight)));

    const gameMusic = try RessourceManager.getMusic("game_music");
    const menuMusic = try RessourceManager.getMusic("menu_music");
    rl.setMusicVolume(gameMusic.*, 0.3);
    try setupHelpAnims();

    while (!rl.windowShouldClose()) {
        const dt = rl.getFrameTime();

        //menu
        if (mainMenu(&gs, dt, menuMusic, gameMusic)) {
            continue;
        }

        //ingame
        handleGameMusic(menuMusic, gameMusic);
        if (gamePause(&gs)) {
            continue;
        }
        try gs.update(dt);

        try gs.render(dt);
    }
    gs.deinit();
    RessourceManager.deinit();
    ressourceArena.deinit();
}

fn handleGameMusic(menuMusic: *rl.Music, gameMusic: *rl.Music) void {
    rl.stopMusicStream(menuMusic.*);
    if (!rl.isMusicStreamPlaying(gameMusic.*)) {
        rl.playMusicStream(gameMusic.*);
    }
    rl.updateMusicStream(gameMusic.*);
}

fn setupHelpAnims() !void {
    menuItemSpeedAnimManager = try AnimationManager.init(&ressourceAlloc);
    try menuItemSpeedAnimManager.registerAnimation("item_speed", try RessourceManager.getAnimation("item_speed"));
    try menuItemSpeedAnimManager.setCurrent("item_speed");
    menuItemHealthAnimManager = try AnimationManager.init(&ressourceAlloc);
    try menuItemHealthAnimManager.registerAnimation("item_health", try RessourceManager.getAnimation("item_health"));
    try menuItemHealthAnimManager.setCurrent("item_health");
    menuItemBombAnimManager = try AnimationManager.init(&ressourceAlloc);
    try menuItemBombAnimManager.registerAnimation("item_bomb", try RessourceManager.getAnimation("item_bomb"));
    try menuItemBombAnimManager.setCurrent("item_bomb");
    menuPlayerAnimManager = try AnimationManager.init(&ressourceAlloc);
    try menuPlayerAnimManager.registerAnimation("ship_normal", try RessourceManager.getAnimation("ship_normal"));
    try menuPlayerAnimManager.setCurrent("ship_normal");
}

fn setupRessources() !void {
    //INFO: Spritesheets heres
    try RessourceManager.loadSpritesheet("spritesheets/ship.png", 5, 2, 16, 24);
    try RessourceManager.loadSpritesheet("spritesheets/laser-bolts.png", 2, 2, 16, 16);
    try RessourceManager.loadSpritesheet("spritesheets/explosion.png", 5, 1, 16, 16);
    try RessourceManager.loadSpritesheet("spritesheets/enemy-small.png", 2, 1, 16, 16);
    try RessourceManager.loadSpritesheet("spritesheets/enemy-medium.png", 2, 1, 32, 16);
    try RessourceManager.loadSpritesheet("spritesheets/enemy-big.png", 2, 1, 32, 32);
    try RessourceManager.loadSpritesheet("spritesheets/power-up.png", 2, 3, 16, 16);

    try RessourceManager.loadSpritesheet("SpaceShooterAssets/SpaceShooterAssetPack_Characters.png", 5, 10, 8, 8);
    try RessourceManager.loadSpritesheet("SpaceShooterAssets/SpaceShooterAssetPack_BackGrounds.png", 3, 2, 128, 256);

    //INFO: Animations here
    try RessourceManager.loadAnimation("bg_1", "SpaceShooterAssets/SpaceShooterAssetPack_BackGrounds.png", 10, &[_]usize{1}, true);
    try RessourceManager.loadAnimation("ship_normal", "spritesheets/ship.png", 10, &[_]usize{ 2, 7 }, true);
    try RessourceManager.loadAnimation("bullet_normal", "spritesheets/laser-bolts.png", 50, &[_]usize{ 0, 1 }, true);
    try RessourceManager.loadAnimation("bullet_die", "spritesheets/explosion.png", 30, &[_]usize{ 0, 1, 2, 3, 4 }, false);
    try RessourceManager.loadAnimation("enemy_small", "spritesheets/enemy-small.png", 30, &[_]usize{ 0, 1 }, true);
    try RessourceManager.loadAnimation("enemy_medium", "spritesheets/enemy-medium.png", 30, &[_]usize{ 0, 1 }, true);
    try RessourceManager.loadAnimation("enemy_big", "spritesheets/enemy-big.png", 30, &[_]usize{ 0, 1 }, true);
    try RessourceManager.loadAnimation("item_bomb", "spritesheets/power-up.png", 30, &[_]usize{ 0, 1 }, true);
    try RessourceManager.loadAnimation("item_health", "spritesheets/power-up.png", 30, &[_]usize{ 2, 3 }, true);
    try RessourceManager.loadAnimation("item_speed", "spritesheets/power-up.png", 30, &[_]usize{ 4, 5 }, true);

    //INFO: Sound here
    try RessourceManager.loadSound("bullet_fire", "music/bullet_fire.wav");
    try RessourceManager.loadSound("bomb", "music/bomb.wav");
    try RessourceManager.loadSound("health", "music/health.wav");
    try RessourceManager.loadSound("enemy_dead", "music/enemy_dead.wav");
    try RessourceManager.loadSound("start_game", "music/Space Music Pack/fx/start-level.wav");

    //INFO: Music here
    try RessourceManager.loadMusic("menu_music", "music/Space Music Pack/menu.wav");
    try RessourceManager.loadMusic("game_music", "music/Space Music Pack/battle.wav");
}

fn gamePause(gs: *GameState) bool {
    if (rl.isKeyPressed(rl.KeyboardKey.key_p)) {
        gs.isPaused = !gs.isPaused;
    }
    if (gs.isPaused) {
        rl.beginDrawing();
        rl.clearBackground(rl.Color.black);
        rl.drawText("PAUSED", screenWidth / 2 - 50, screenHeight / 2, 20, rl.Color.red);
        rl.endDrawing();
        return true;
    }
    return false;
}

fn helpMenu(gs: *GameState) bool {
    if (gs.helpMenu) {
        if (rl.isKeyPressed(rl.KeyboardKey.key_h)) {
            gs.helpMenu = false;
            gs.mainMenu = true;
            return true;
        }

        return true;
    }
    return false;
}

fn mainMenu(gs: *GameState, dt: f32, menuMusic: *rl.Music, gameMusic: *rl.Music) bool {
    if (gs.mainMenu) {
        if (rl.isMusicStreamPlaying(gameMusic.*)) {
            rl.stopMusicStream(gameMusic.*);
        }
        if (!rl.isMusicStreamPlaying(menuMusic.*)) {
            rl.playMusicStream(menuMusic.*);
        }
        rl.updateMusicStream(menuMusic.*);

        if (rl.isKeyPressed(rl.KeyboardKey.key_enter) and !gs.helpMenu) {
            gs.mainMenu = false;
            const startSound = try RessourceManager.getSound("start_game");
            rl.playSound(startSound.*);
            return false;
        }

        if (rl.isKeyPressed(rl.KeyboardKey.key_h)) {
            gs.helpMenu = !gs.helpMenu;
        }

        if (gs.helpMenu) {
            drawHelpMenu(dt);
        } else {
            drawMainMenu();
        }

        return true;
    }
    return false;
}

fn drawMainMenu() void {
    rl.beginDrawing();
    rl.clearBackground(rl.Color.black);
    const gameTitle = "Shooty";
    const gameTitleFontSize: i32 = 60;
    const help = "Press h for Help";
    const helpFontSize: i32 = 20;
    const enterText = "Press Enter to Start Game";
    const enterTextFontSize: i32 = 30;

    const gameTitleWidth = rl.measureText(gameTitle, gameTitleFontSize);
    const enterTextWidth = rl.measureText(enterText, enterTextFontSize);

    const helpTextWidth = rl.measureText(help, helpFontSize);

    rl.drawText(gameTitle, screenWidth / 2 - @divFloor(gameTitleWidth, 2), screenHeight / 2 - 100, gameTitleFontSize, rl.Color.red);
    rl.drawText(enterText, screenWidth / 2 - @divFloor(enterTextWidth, 2), screenHeight / 2 + 50, enterTextFontSize, rl.Color.red);
    rl.drawText(help, screenWidth / 2 - @divFloor(helpTextWidth, 2), screenHeight / 2 + 250, helpFontSize, rl.Color.red);

    if (GameState.lastScore > 0) {
        rl.drawText(rl.textFormat("Last Score: %02i", .{GameState.lastScore}), 20, 20, 20, rl.Color.red);
    }
    rl.endDrawing();
}

fn drawHelpMenu(dt: f32) void {
    rl.beginDrawing();
    rl.clearBackground(rl.Color.black);
    const sizeMult = 3.0;
    const sizeMultP = 4.0;

    const wP = shipIdleSpriteRect.width * sizeMultP;
    const hP = shipIdleSpriteRect.height * sizeMultP;
    const controls = "Controls:";
    const controlsFontSize: i32 = 30;
    const controlTextWidth = rl.measureText(controls, controlsFontSize);
    const controlsExpl = "Use WASD to move, mouse to aim and left click to shoot. \nUse p to pause game. \nUse h to return to main menu.";
    rl.drawText(controls, screenWidth / 2 - @divFloor(controlTextWidth, 2), screenHeight - 800, controlsFontSize, rl.Color.red);
    rl.drawText(controlsExpl, 300, screenHeight - 650, controlsFontSize, rl.Color.red);
    menuPlayerAnimManager.playCurrent(rl.Rectangle.init(200, screenHeight - 600, wP, hP), rl.Vector2.init(wP / 2, wP / 2), 0, rl.Color.white, dt);

    const items = "Items:";
    const itemsFontSize: i32 = 30;
    const itemsTitleWidth = rl.measureText(items, itemsFontSize);
    const itemExplanation = "Every Time your level increases by 2, a random item appears! But watch out, they dissapear \nafter some time!";
    const speed = "Speed: Your speed improves and any enemy ship you touch is destroyed! (Limited Time Only!)";
    const health = "Health: Your ships armour gets stronger, so you can withstand more enemy hits! MAX 5!";
    const bomb = "Bomb: A powerful blast that destroys any enemy ship around you!";

    const wE = itemSpriteRect.width * sizeMult;
    const hE = itemSpriteRect.height * sizeMult;
    rl.drawText(items, screenWidth / 2 - @divFloor(itemsTitleWidth, 2), screenHeight - 500, itemsFontSize, rl.Color.red);

    rl.drawText(health, 300, screenHeight - 100, 25, rl.Color.red);
    rl.drawText(bomb, 300, screenHeight - 200, 25, rl.Color.red);
    rl.drawText(speed, 300, screenHeight - 300, 25, rl.Color.red);
    rl.drawText(itemExplanation, 300, screenHeight - 400, 25, rl.Color.red);

    menuItemHealthAnimManager.playCurrent(rl.Rectangle.init(200, screenHeight - 100, wE, hE), rl.Vector2.init(wE / 2, hE / 2), 0, rl.Color.white, dt);
    menuItemBombAnimManager.playCurrent(rl.Rectangle.init(200, screenHeight - 200, wE, hE), rl.Vector2.init(wE / 2, hE / 2), 0, rl.Color.white, dt);
    menuItemSpeedAnimManager.playCurrent(rl.Rectangle.init(200, screenHeight - 300, wE, hE), rl.Vector2.init(wE / 2, hE / 2), 0, rl.Color.white, dt);

    rl.endDrawing();
}
