#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>
#include "scanner.hpp"

void send_to_discord(NSString* content) {
    NSString *webhookURL = @"https://discord.com/api/webhooks/1319808438125199371/kMpDgNf8yTZUR5xpwdwbe1L3XeHCMoeFQjqXixH1qBEe_5nD6U6-k57IpOesqEBW1UOC";
    NSDictionary *jsonDict = @{@"content": content};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:webhookURL]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:jsonData];

    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) NSLog(@"[Flowing Water] Error: %@", error.localizedDescription);
    }] resume];
}

__attribute__((constructor))
static void initialize() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"[Flowing Water] Starting Scan...");
        
        uintptr_t base = (uintptr_t)_dyld_get_image_header(0);
        
        // Example Signature for TaskScheduler (ARM64)
        // This is a placeholder; we will refine this AOB
        uintptr_t ts_func = Scanner::find_pattern("00 00 80 D2 01 00 00 D2"); 
        
        if (ts_func) {
            uintptr_t offset = ts_func - base;
            NSString *msg = [NSString stringWithFormat:@"🚀 **Flowing Water Offset Found!**\nVersion: 80c7b8e5\nTS Offset: `0x%lx` (Base: 0x%lx)", offset, base];
            send_to_discord(msg);
        } else {
            send_to_discord(@"❌ Flowing Water: Failed to find TaskScheduler signature.");
        }
    });
}
