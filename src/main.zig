const c = @cImport({
    @cInclude("psp2/kernel/processmgr.h");
    @cInclude("psp2/kernel/threadmgr.h");
    @cInclude("debugScreen.h");
});

pub export fn main() c_int {
    _ = c.psvDebugScreenInit();
    _ = c.psvDebugScreenPrintf("[Zig] Hello, world!\n");

    while (true) {
        _ = c.sceKernelDelayThread(5 * 1000000);
    }
    return 0;
}
