const std = @import("std");
const stdout = std.debug;
const sdl = @cImport(@cInclude("C:\\Users\\Public\\Includes\\SDL2\\include\\SDL.h"));
const pSurface = *sdl.SDL_Surface;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

// Main parameters
const refreshrate = 50; // [ms]
const damping = 0.985;
const intensity = 2500.0;

// Benchmark
var SumTime: u64 = 0;
var nFrames: u64 = 0;

// Calculated parameters
var canvasW: u32 = undefined;
var canvasH: u32 = undefined;
var canvasMain: pSurface = undefined;
var canvasGray: pSurface = undefined;
var pixelsGray: [*]u8 = undefined;
var pixelsPrevious: []f32 = undefined;
var pixelsCurrent: []f32 = undefined;

// Randomizer
pub var prng: std.Random.Xoshiro256 = undefined;
pub fn InitRandomizer(prng_target: *std.Random.Xoshiro256) !void {
    var seed: u64 = undefined;
    try std.posix.getrandom(std.mem.asBytes(&seed));
    prng_target.* = std.Random.DefaultPrng.init(seed);
}

fn UpdateCanvas() void {
    var index: usize = canvasW + 1; // start at (1,1)
    for (0..canvasH - 2) |_| {
        for (0..canvasW - 2) |_| {
            const result = damping * (0.5 * (pixelsPrevious[index - 1] + pixelsPrevious[index + 1] + pixelsPrevious[index - canvasW] + pixelsPrevious[index + canvasW]) - pixelsCurrent[index]);
            pixelsCurrent[index] = result;
            pixelsGray[index] = @intFromFloat(@min(255.0, @max(0.0, pixelsCurrent[index])));
            index += 1;
        }
        index += 2; // skip right and left border pixel
    }
    _ = sdl.SDL_BlitSurface(
        canvasGray,
        null,
        canvasMain,
        null,
    );
    const pixelsTemp = pixelsPrevious;
    pixelsPrevious = pixelsCurrent;
    pixelsCurrent = pixelsTemp;
    // add a point at random (avoid borders)
    for (0..4) |_| {
        const x: usize = 1 + prng.random().uintLessThan(usize, canvasW - 2);
        const y: usize = 1 + prng.random().uintLessThan(usize, canvasH - 2);
        pixelsPrevious[y * canvasW + x] = intensity;
    }
}

pub fn main() !void {
    // Init Randomize
    try InitRandomizer(&prng);
    // SDL Initialisation
    if (sdl.SDL_Init(sdl.SDL_INIT_TIMER) != 0) {
        stdout.print("SDL initialisation error: {s}\n", .{sdl.SDL_GetError()});
        return error.sdl_initialisationerror;
    }
    defer sdl.SDL_Quit();
    const window: *sdl.SDL_Window = sdl.SDL_CreateWindow("SDL main window", 0, 0, 1600, 900, sdl.SDL_WINDOW_FULLSCREEN_DESKTOP) orelse {
        stdout.print("SDL window creation failed: {s}\n", .{sdl.SDL_GetError()});
        return error.sdl_windowcreationfailed;
    };
    defer sdl.SDL_DestroyWindow(window);
    sdl.SDL_GetWindowSize(window, @ptrCast(&canvasW), @ptrCast(&canvasH));
    stdout.print("Window dimensions: {}x{}\n", .{ canvasW, canvasH });
    // Create canvasses
    canvasMain = sdl.SDL_GetWindowSurface(window) orelse {
        stdout.print("SDL canvas creation failed: {s}\n", .{sdl.SDL_GetError()});
        return error.sdl_canvascreationfailed;
    };
    if (canvasMain.pitch != canvasMain.w * 4) std.debug.panic("Help", .{});
    canvasGray = sdl.SDL_CreateRGBSurfaceWithFormat(0, @intCast(canvasW), @intCast(canvasH), 8, sdl.SDL_PIXELFORMAT_INDEX8) orelse {
        stdout.print("SDL canvas creation failed: {s}\n", .{sdl.SDL_GetError()});
        return error.sdl_canvascreationfailed;
    };
    defer sdl.SDL_FreeSurface(canvasGray);
    pixelsGray = @as([*]u8, @constCast(@ptrCast(canvasGray.pixels)));
    //GrayScale
    for (0..256) |index| {
        const b: u8 = @intCast(index);
        const entry = sdl.SDL_Color{ .a = 255, .r = b, .g = b, .b = b };
        _ = sdl.SDL_SetPaletteColors(canvasGray.format.*.palette, &entry, b, 1);
    }
    // Calculation buffers
    pixelsPrevious = try allocator.alloc(f32, canvasW * canvasH);
    defer allocator.free(pixelsPrevious);
    pixelsCurrent = try allocator.alloc(f32, canvasW * canvasH);
    defer allocator.free(pixelsCurrent);

    //
    for (0..canvasH * canvasW) |index| {
        pixelsCurrent[index] = 0.0;
        pixelsPrevious[index] = 0.0;
    }

    // Hide mouse
    _ = sdl.SDL_ShowCursor(sdl.SDL_DISABLE);

    // Prepare program loop
    var timer = try std.time.Timer.start();
    var stoploop = false;
    var event: sdl.SDL_Event = undefined;

    //Main loop
    while (!stoploop) {
        // Loop refresh
        timer.reset();
        // Update window
        _ = sdl.SDL_UpdateWindowSurface(window);
        UpdateCanvas();
        // Here come the user interactions
        while (sdl.SDL_PollEvent(&event) != 0) {
            if (event.type == sdl.SDL_KEYDOWN) stoploop = true;
        }
        // Here come the timer instructions to wait for next frame
        const ticktock = timer.read();
        SumTime += ticktock;
        nFrames += 1;
        const lap: u32 = @intCast(ticktock / 1_000_000);
        if (lap < refreshrate) sdl.SDL_Delay(refreshrate - lap);
    }
    std.debug.print("Avg loop time: {} us\n", .{SumTime / nFrames / 1000});
}
