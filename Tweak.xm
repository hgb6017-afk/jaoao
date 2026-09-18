
#import <Foundation/Foundation.h>
#import <netdb.h>
#import <string.h>

static NSString * const kLicenseHost = @"licenses.mewit.vn";
static NSString * const kDisableMarker = @"/var/tmp/mewremote_offline.disable";
static NSString * const kLogPath = @"/var/tmp/mewremote_offline.log";

static BOOL MROEnabled(void) {
    return ![[NSFileManager defaultManager] fileExistsAtPath:kDisableMarker];
}

static BOOL MROIsLicenseHost(NSString *host) {
    if (!host.length) return NO;
    NSString *h = host.lowercaseString;
    return [h isEqualToString:kLicenseHost] || [h hasSuffix:[@"." stringByAppendingString:kLicenseHost]];
}

static void MROLog(NSString *message) {
    @autoreleasepool {
        NSString *proc = [NSProcessInfo processInfo].processName ?: @"?";
        NSString *line = [NSString stringWithFormat:@"%@ [%@] %@\n",
                          [NSDate date], proc, message ?: @""];
        NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];

        if (![[NSFileManager defaultManager] fileExistsAtPath:kLogPath]) {
            [data writeToFile:kLogPath atomically:YES];
            return;
        }

        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:kLogPath];
        if (fh) {
            @try {
                [fh seekToEndOfFile];
                [fh writeData:data];
                [fh closeFile];
            } @catch (__unused NSException *e) {}
        }
    }
}

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *data,
                                                        NSURLResponse *response,
                                                        NSError *error))completionHandler {
    if (MROEnabled() && MROIsLicenseHost(request.URL.host)) {
        NSURLComponents *c = [NSURLComponents componentsWithURL:request.URL
                                        resolvingAgainstBaseURL:NO];
        if (c) {
            c.host = @"127.0.0.1";
            c.port = @9; // discard port -> immediate local connection failure
            NSURL *blockedURL = c.URL;

            if (blockedURL) {
                NSMutableURLRequest *r = [request mutableCopy];
                r.URL = blockedURL;
                MROLog([NSString stringWithFormat:
                    @"Blocked license revalidation: %@ -> %@",
                    request.URL.absoluteString ?: @"?", blockedURL.absoluteString ?: @"?"]);
                return %orig(r, completionHandler);
            }
        }
    }

    return %orig;
}

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url
                        completionHandler:(void (^)(NSData *data,
                                                    NSURLResponse *response,
                                                    NSError *error))completionHandler {
    if (MROEnabled() && MROIsLicenseHost(url.host)) {
        NSURLComponents *c = [NSURLComponents componentsWithURL:url
                                        resolvingAgainstBaseURL:NO];
        if (c) {
            c.host = @"127.0.0.1";
            c.port = @9;
            NSURL *blockedURL = c.URL;
            if (blockedURL) {
                MROLog([NSString stringWithFormat:
                    @"Blocked license URL: %@ -> %@",
                    url.absoluteString ?: @"?", blockedURL.absoluteString ?: @"?"]);
                return %orig(blockedURL, completionHandler);
            }
        }
    }

    return %orig;
}

%end

// DNS fallback for code paths that resolve the licensing hostname directly.
%hookf(int, getaddrinfo, const char *node, const char *service,
       const struct addrinfo *hints, struct addrinfo **res) {
    if (MROEnabled() && node && strcasecmp(node, "licenses.mewit.vn") == 0) {
        MROLog(@"Blocked getaddrinfo(licenses.mewit.vn)");
        return EAI_NONAME;
    }
    return %orig(node, service, hints, res);
}

%ctor {
    @autoreleasepool {
        MROLog(MROEnabled()
               ? @"MewRemote Offline Helper loaded (offline fallback ON)"
               : @"MewRemote Offline Helper loaded (disabled by marker)");
    }
}
