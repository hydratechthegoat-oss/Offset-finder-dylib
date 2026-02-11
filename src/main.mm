#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <stdint.h>
#include <mach-o/dyld.h>
#include <dispatch/dispatch.h> // Fixes the dispatch_after errors
#include "scanner.hpp"         // Ensure this file exists in the same folder

// Forward declaration of the discord function so initialize() can see it
void send_to_discord(NSString* content);

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
    // We wait 10 seconds to ensure the game binary is fully decrypted in RAM
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSLog(@"[Flowing Water] Starting Scan...");
        
        // Update this signature based on the game version
        const char* ts_sig = "FD 7B BF A9 FD 03 00 91 ?? ?? ?? ?? ?? ?? ?? ?? 08 00 40 F9";
        
        uintptr_t found_addr = Scanner::find_pattern(ts_sig);
        uintptr_t base = (uintptr_t)_dyld_get_image_header(0);

        if (found_addr && base) {
            uintptr_t offset = found_addr - base;
            NSString *report = [NSString stringWithFormat:@"🎯 **Flowing Water Offset Found!**\n`0x%lx`", (unsigned long)offset];
            send_to_discord(report);
        } else {
            send_to_discord(@"⚠️ Flowing Water: Pattern not found. Update the signature!");
        }
    });
}
