__attribute__((constructor))
static void initialize() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // This is a common pattern for "GetTaskScheduler" in ARM64
        // ADRP X8, #page; LDR X8, [X8, #offset]; RET
        const char* ts_sig = "FD 7B BF A9 FD 03 00 91 ?? ?? ?? ?? ?? ?? ?? ?? 08 00 40 F9";
        
        uintptr_t found_addr = Scanner::find_pattern(ts_sig);
        uintptr_t base = (uintptr_t)_dyld_get_image_header(0);

        if (found_addr) {
            uintptr_t offset = found_addr - base;
            NSString *report = [NSString stringWithFormat:@"🎯 **Offset Found!**\n`0x%lx`", offset];
            send_to_discord(report);
        } else {
            send_to_discord(@"⚠️ Pattern not found. Update the signature!");
        }
    });
}
