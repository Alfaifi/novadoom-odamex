/*   SDLMain.m - main entry point for our Cocoa-ized SDL app
       Initial Version: Darrell Walisser <dwaliss1@purdue.edu>
       Non-NIB-Code & other changes: Max Horn <max@quendi.de>

    Feel free to customize this file to suit your needs
*/

#import "SDL.h"

/*   SDLMain.m - main entry point for our Cocoa-ized SDL app
Initial Version: Darrell Walisser <dwaliss1@purdue.edu>
Non-NIB-Code & other changes: Max Horn <max@quendi.de>

Feel free to customize this file to suit your needs
*/

#import <Cocoa/Cocoa.h>

@interface SDLMain : NSObject <NSApplicationDelegate>
@end

#import <sys/param.h> /* for MAXPATHLEN */
#import <unistd.h>

/* For some reaon, Apple removed setAppleMenu from the headers in 10.4,
 but the method still is there and works. To avoid warnings, we declare
 it ourselves here. */
@interface NSApplication(SDL_Missing_Methods)
- (void)setAppleMenu:(NSMenu *)menu;
@end

/* Use this flag to determine whether we use SDLMain.nib or not */
#define		SDL_USE_NIB_FILE	0

/* Use this flag to determine whether we use CPS (docking) or not */
#define		SDL_USE_CPS		1
#ifdef SDL_USE_CPS
/* Portions of CPS.h */
typedef struct CPSProcessSerNum
{
	UInt32		lo;
	UInt32		hi;
} CPSProcessSerNum;

extern OSErr	CPSGetCurrentProcess( CPSProcessSerNum *psn);
extern OSErr 	CPSEnableForegroundOperation( CPSProcessSerNum *psn, UInt32 _arg2, UInt32 _arg3, UInt32 _arg4, UInt32 _arg5);
extern OSErr	CPSSetFrontProcess( CPSProcessSerNum *psn);

#endif /* SDL_USE_CPS */

static int    gArgc;
static char  **gArgv;
static bool   gFinderLaunch;
static bool   gCalledAppMainline = false;
static bool   gURLProcessed = false;  /* Set when URL has been parsed in main() */

static NSString *getApplicationName(void)
{
    NSDictionary *dict;
    NSString *appName = 0;

    /* Determine the application name */
    dict = (NSDictionary *)CFBundleGetInfoDictionary(CFBundleGetMainBundle());
    if (dict)
        appName = [dict objectForKey: @"CFBundleName"];

    if (![appName length])
        appName = [[NSProcessInfo processInfo] processName];

    return appName;
}

#if SDL_USE_NIB_FILE
/* A helper category for NSString */
@interface NSString (ReplaceSubString)
- (NSString *)stringByReplacingRange:(NSRange)aRange with:(NSString *)aString;
@end
#endif

/* Custom application class to handle quit properly - renamed to avoid conflict
   with SDL2's own SDLApplication class */
@interface NovaDoomApplication : NSApplication
@end

@implementation NovaDoomApplication
/* Invoked from the Quit menu item */
- (void)terminate:(id)sender
{
    /* Post a SDL_QUIT event */
    SDL_Event event;
    event.type = SDL_QUIT;
    SDL_PushEvent(&event);
}
@end

/* The main class of the application, the application's delegate */
@implementation SDLMain

/*
 * Handle GetURL Apple Events (primary way URLs are delivered on macOS)
 * This is called when the app is launched via a URL scheme like novadoom://
 */
- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];

    if (gCalledAppMainline) {
        /* App already started - we can't modify argv anymore */
        return;
    }

    /* Skip if URL was already processed in main() */
    if (gURLProcessed) {
        return;
    }

    if ([urlString hasPrefix:@"novadoom://"]) {
        /* Parse the URL and add to argv */
        NSString *remainder = [urlString substringFromIndex:[@"novadoom://" length]];

        /* Remove "connect/" prefix if present */
        if ([remainder hasPrefix:@"connect/"]) {
            remainder = [remainder substringFromIndex:[@"connect/" length]];
        }

        /* Split on '?' to separate host:port from query params */
        NSRange queryRange = [remainder rangeOfString:@"?"];
        NSString *hostPort;
        NSString *query = @"";
        if (queryRange.location != NSNotFound) {
            hostPort = [remainder substringToIndex:queryRange.location];
            query = [remainder substringFromIndex:queryRange.location + 1];
        } else {
            hostPort = remainder;
        }

        /* Remove trailing slashes */
        while ([hostPort hasSuffix:@"/"]) {
            hostPort = [hostPort substringToIndex:[hostPort length] - 1];
        }

        if ([hostPort length] > 0) {
            /* Add -connect argument */
            const char *connectArg = "-connect";
            char *arg1 = (char *) SDL_malloc(strlen(connectArg) + 1);
            strcpy(arg1, connectArg);

            const char *hostPortCStr = [hostPort UTF8String];
            char *arg2 = (char *) SDL_malloc(strlen(hostPortCStr) + 1);
            strcpy(arg2, hostPortCStr);

            char **newargv = (char **) realloc(gArgv, sizeof(char *) * (gArgc + 3));
            if (newargv) {
                gArgv = newargv;
                gArgv[gArgc++] = arg1;
                gArgv[gArgc++] = arg2;

                /* Check for password in query string */
                NSRange pwdRange = [query rangeOfString:@"password="];
                if (pwdRange.location != NSNotFound) {
                    NSString *password = [query substringFromIndex:pwdRange.location + [@"password=" length]];
                    NSRange ampRange = [password rangeOfString:@"&"];
                    if (ampRange.location != NSNotFound) {
                        password = [password substringToIndex:ampRange.location];
                    }
                    if ([password length] > 0) {
                        const char *pwdCStr = [password UTF8String];
                        char *arg3 = (char *) SDL_malloc(strlen(pwdCStr) + 1);
                        strcpy(arg3, pwdCStr);
                        newargv = (char **) realloc(gArgv, sizeof(char *) * (gArgc + 2));
                        if (newargv) {
                            gArgv = newargv;
                            gArgv[gArgc++] = arg3;
                        }
                    }
                }

                /* Check for player name in query string */
                NSRange nameRange = [query rangeOfString:@"name="];
                if (nameRange.location != NSNotFound) {
                    NSString *playerName = [query substringFromIndex:nameRange.location + [@"name=" length]];
                    NSRange ampRange = [playerName rangeOfString:@"&"];
                    if (ampRange.location != NSNotFound) {
                        playerName = [playerName substringToIndex:ampRange.location];
                    }
                    if ([playerName length] > 0) {
                        const char *nameCStr = [playerName UTF8String];
                        char *nameArg = (char *) SDL_malloc(strlen("-name") + 1);
                        strcpy(nameArg, "-name");
                        char *nameValArg = (char *) SDL_malloc(strlen(nameCStr) + 1);
                        strcpy(nameValArg, nameCStr);
                        newargv = (char **) realloc(gArgv, sizeof(char *) * (gArgc + 3));
                        if (newargv) {
                            gArgv = newargv;
                            gArgv[gArgc++] = nameArg;
                            gArgv[gArgc++] = nameValArg;
                        }
                    }
                }

                gArgv[gArgc] = NULL;
                gURLProcessed = YES;  /* Mark URL as processed */
            }
        }
    }
}

/* Set the working directory to the .app's parent directory */
- (void) setupWorkingDirectory:(bool)shouldChdir
{
    if (shouldChdir)
    {
        char parentdir[MAXPATHLEN];
		CFURLRef url = CFBundleCopyBundleURL(CFBundleGetMainBundle());
		CFURLRef url2 = CFURLCreateCopyDeletingLastPathComponent(0, url);
		if (CFURLGetFileSystemRepresentation(url2, true, (UInt8 *)parentdir, MAXPATHLEN)) {
	        assert ( chdir (parentdir) == 0 );   /* chdir to the binary app's parent */
		}
		CFRelease(url);
		CFRelease(url2);
	}

}

#if SDL_USE_NIB_FILE

/* Fix menu to contain the real app name instead of "SDL App" */
- (void)fixMenu:(NSMenu *)aMenu withAppName:(NSString *)appName
{
    NSRange aRange;
    NSEnumerator *enumerator;
    NSMenuItem *menuItem;

    aRange = [[aMenu title] rangeOfString:@"SDL App"];
    if (aRange.length != 0)
        [aMenu setTitle: [[aMenu title] stringByReplacingRange:aRange with:appName]];

    enumerator = [[aMenu itemArray] objectEnumerator];
    while ((menuItem = [enumerator nextObject]))
    {
        aRange = [[menuItem title] rangeOfString:@"SDL App"];
        if (aRange.length != 0)
            [menuItem setTitle: [[menuItem title] stringByReplacingRange:aRange with:appName]];
        if ([menuItem hasSubmenu])
            [self fixMenu:[menuItem submenu] withAppName:appName];
    }
    [ aMenu sizeToFit ];
}

#else

static void setApplicationMenu(void)
{
    /* warning: this code is very odd */
    NSMenu *appleMenu;
    NSMenuItem *menuItem;
    NSString *title;
    NSString *appName;

    appName = getApplicationName();
    appleMenu = [[NSMenu alloc] initWithTitle:@""];

    /* Add menu items */
    title = [@"About " stringByAppendingString:appName];
    [appleMenu addItemWithTitle:title action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];

    [appleMenu addItem:[NSMenuItem separatorItem]];

    title = [@"Hide " stringByAppendingString:appName];
    [appleMenu addItemWithTitle:title action:@selector(hide:) keyEquivalent:@"h"];

    menuItem = (NSMenuItem *)[appleMenu addItemWithTitle:@"Hide Others" action:@selector(hideOtherApplications:) keyEquivalent:@"h"];
    [menuItem setKeyEquivalentModifierMask:(NSEventModifierFlagOption|NSEventModifierFlagCommand)];

    [appleMenu addItemWithTitle:@"Show All" action:@selector(unhideAllApplications:) keyEquivalent:@""];

    [appleMenu addItem:[NSMenuItem separatorItem]];

    title = [@"Quit " stringByAppendingString:appName];
    [appleMenu addItemWithTitle:title action:@selector(terminate:) keyEquivalent:@"q"];


    /* Put menu into the menubar */
    menuItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    [menuItem setSubmenu:appleMenu];
    [[NSApp mainMenu] addItem:menuItem];

    /* Tell the application object that this is now the application menu */
    [NSApp setAppleMenu:appleMenu];

    /* Finally give up our references to the objects */
    [appleMenu release];
    [menuItem release];
}

/* Create a window menu */
static void setupWindowMenu(void)
{
    NSMenu      *windowMenu;
    NSMenuItem  *windowMenuItem;
    NSMenuItem  *menuItem;

    windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];

    /* "Minimize" item */
    menuItem = [[NSMenuItem alloc] initWithTitle:@"Minimize" action:@selector(performMiniaturize:) keyEquivalent:@"m"];
    [windowMenu addItem:menuItem];
    [menuItem release];

    /* Put menu into the menubar */
    windowMenuItem = [[NSMenuItem alloc] initWithTitle:@"Window" action:nil keyEquivalent:@""];
    [windowMenuItem setSubmenu:windowMenu];
    [[NSApp mainMenu] addItem:windowMenuItem];

    /* Tell the application object that this is now the window menu */
    [NSApp setWindowsMenu:windowMenu];

    /* Finally give up our references to the objects */
    [windowMenu release];
    [windowMenuItem release];
}

/* Replacement for NSApplicationMain */
static void CustomApplicationMain (int argc, char **argv)
{
    NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
    SDLMain				*sdlMain;

    /* Ensure the application object is initialised */
    [NovaDoomApplication sharedApplication];

    /* Create SDLMain early so we can register it for Apple Events */
    sdlMain = [[SDLMain alloc] init];

    /* Register for GetURL Apple Events (handles novadoom:// URLs) */
    [[NSAppleEventManager sharedAppleEventManager]
        setEventHandler:sdlMain
        andSelector:@selector(handleGetURLEvent:withReplyEvent:)
        forEventClass:kInternetEventClass
        andEventID:kAEGetURL];

#ifdef SDL_USE_CPS
    {
        CPSProcessSerNum PSN;
        /* Tell the dock about us */
        if (!CPSGetCurrentProcess(&PSN))
            if (!CPSEnableForegroundOperation(&PSN,0x03,0x3C,0x2C,0x1103))
                if (!CPSSetFrontProcess(&PSN))
                    [NovaDoomApplication sharedApplication];
    }
#endif /* SDL_USE_CPS */

    /* Set up the menubar */
    [NSApp setMainMenu:[[NSMenu alloc] init]];
    setApplicationMenu();
    setupWindowMenu();

    /* Set SDLMain as the app delegate (already created earlier for Apple Event registration) */
    [NSApp setDelegate:sdlMain];

    /* Start the main event loop */
    [NSApp run];

    [sdlMain release];
    [pool release];
}

#endif


/*
 * Catch document open requests...this lets us notice files when the app
 *  was launched by double-clicking a document, or when a document was
 *  dragged/dropped on the app's icon. You need to have a
 *  CFBundleDocumentsType section in your Info.plist to get this message,
 *  apparently.
 *
 * Files are added to gArgv, so to the app, they'll look like command line
 *  arguments. Previously, apps launched from the finder had nothing but
 *  an argv[0].
 *
 * This message may be received multiple times to open several docs on launch.
 *
 * This message is ignored once the app's mainline has been called.
 */
- (bool)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    const char *temparg;
    size_t arglen;
    char *arg;
    char **newargv;

    if (!gFinderLaunch)  /* MacOS is passing command line args. */
        return false;

    if (gCalledAppMainline)  /* app has started, ignore this document. */
        return false;

    /* Check if this is a novadoom:// URL (passed as a "file") */
    if ([filename hasPrefix:@"novadoom://"]) {
        /* Skip if URL was already processed in main() or via Apple Event */
        if (gURLProcessed) {
            return true;
        }
        /* Parse the URL and convert to -connect argument */
        NSString *remainder = [filename substringFromIndex:[@"novadoom://" length]];

        /* Remove "connect/" prefix if present */
        if ([remainder hasPrefix:@"connect/"]) {
            remainder = [remainder substringFromIndex:[@"connect/" length]];
        }

        /* Split on '?' to separate host:port from query params */
        NSRange queryRange = [remainder rangeOfString:@"?"];
        NSString *hostPort;
        NSString *query = @"";
        if (queryRange.location != NSNotFound) {
            hostPort = [remainder substringToIndex:queryRange.location];
            query = [remainder substringFromIndex:queryRange.location + 1];
        } else {
            hostPort = remainder;
        }

        /* Remove trailing slashes */
        while ([hostPort hasSuffix:@"/"]) {
            hostPort = [hostPort substringToIndex:[hostPort length] - 1];
        }

        if ([hostPort length] > 0) {
            /* Add -connect argument */
            const char *connectArg = "-connect";
            char *arg1 = (char *) SDL_malloc(strlen(connectArg) + 1);
            strcpy(arg1, connectArg);

            const char *hostPortCStr = [hostPort UTF8String];
            char *arg2 = (char *) SDL_malloc(strlen(hostPortCStr) + 1);
            strcpy(arg2, hostPortCStr);

            char **newargv = (char **) realloc(gArgv, sizeof(char *) * (gArgc + 3));
            if (newargv) {
                gArgv = newargv;
                gArgv[gArgc++] = arg1;
                gArgv[gArgc++] = arg2;

                /* Check for password in query string */
                NSRange pwdRange = [query rangeOfString:@"password="];
                if (pwdRange.location != NSNotFound) {
                    NSString *password = [query substringFromIndex:pwdRange.location + [@"password=" length]];
                    NSRange ampRange = [password rangeOfString:@"&"];
                    if (ampRange.location != NSNotFound) {
                        password = [password substringToIndex:ampRange.location];
                    }
                    if ([password length] > 0) {
                        const char *pwdCStr = [password UTF8String];
                        char *arg3 = (char *) SDL_malloc(strlen(pwdCStr) + 1);
                        strcpy(arg3, pwdCStr);
                        newargv = (char **) realloc(gArgv, sizeof(char *) * (gArgc + 2));
                        if (newargv) {
                            gArgv = newargv;
                            gArgv[gArgc++] = arg3;
                        }
                    }
                }

                /* Check for player name in query string */
                NSRange nameRange = [query rangeOfString:@"name="];
                if (nameRange.location != NSNotFound) {
                    NSString *playerName = [query substringFromIndex:nameRange.location + [@"name=" length]];
                    NSRange ampRange = [playerName rangeOfString:@"&"];
                    if (ampRange.location != NSNotFound) {
                        playerName = [playerName substringToIndex:ampRange.location];
                    }
                    if ([playerName length] > 0) {
                        const char *nameCStr = [playerName UTF8String];
                        char *nameArg = (char *) SDL_malloc(strlen("-name") + 1);
                        strcpy(nameArg, "-name");
                        char *nameValArg = (char *) SDL_malloc(strlen(nameCStr) + 1);
                        strcpy(nameValArg, nameCStr);
                        newargv = (char **) realloc(gArgv, sizeof(char *) * (gArgc + 3));
                        if (newargv) {
                            gArgv = newargv;
                            gArgv[gArgc++] = nameArg;
                            gArgv[gArgc++] = nameValArg;
                        }
                    }
                }

                gArgv[gArgc] = NULL;
            }
        }
        return true;
    }

    temparg = [filename UTF8String];
    arglen = SDL_strlen(temparg) + 1;
    arg = (char *) SDL_malloc(arglen);
    if (arg == NULL)
        return false;

    newargv = (char **) realloc(gArgv, sizeof (char *) * (gArgc + 2));
    if (newargv == NULL)
    {
        SDL_free(arg);
        return false;
    }
    gArgv = newargv;

    SDL_strlcpy(arg, temparg, arglen);
    gArgv[gArgc++] = arg;
    gArgv[gArgc] = NULL;
    return true;
}


/*
 * Handle URL scheme events (novadoom://connect/host:port)
 * This is called when clicking a novadoom:// link in the browser
 * Note: On modern macOS, URLs are typically delivered via handleGetURLEvent: instead
 */
- (void)application:(NSApplication *)application openURLs:(NSArray<NSURL *> *)urls
{
    for (NSURL *url in urls) {
        if ([[url scheme] isEqualToString:@"novadoom"]) {
            NSString *urlString = [url absoluteString];

            if (gCalledAppMainline) {
                /* App already started - we can't modify argv anymore */
                /* The SDL_DROPFILE handler in i_video_sdl20.cpp will handle this */
                return;
            }

            /* Parse the URL and add to argv */
            NSString *remainder = [urlString substringFromIndex:[@"novadoom://" length]];

            /* Remove "connect/" prefix if present */
            if ([remainder hasPrefix:@"connect/"]) {
                remainder = [remainder substringFromIndex:[@"connect/" length]];
            }

            /* Split on '?' to separate host:port from query params */
            NSRange queryRange = [remainder rangeOfString:@"?"];
            NSString *hostPort;
            NSString *query = @"";
            if (queryRange.location != NSNotFound) {
                hostPort = [remainder substringToIndex:queryRange.location];
                query = [remainder substringFromIndex:queryRange.location + 1];
            } else {
                hostPort = remainder;
            }

            /* Remove trailing slashes */
            while ([hostPort hasSuffix:@"/"]) {
                hostPort = [hostPort substringToIndex:[hostPort length] - 1];
            }

            if ([hostPort length] > 0) {
                /* Add -connect argument */
                const char *connectArg = "-connect";
                char *arg1 = (char *) SDL_malloc(strlen(connectArg) + 1);
                strcpy(arg1, connectArg);

                const char *hostPortCStr = [hostPort UTF8String];
                char *arg2 = (char *) SDL_malloc(strlen(hostPortCStr) + 1);
                strcpy(arg2, hostPortCStr);

                char **newargv = (char **) realloc(gArgv, sizeof(char *) * (gArgc + 3));
                if (newargv) {
                    gArgv = newargv;
                    gArgv[gArgc++] = arg1;
                    gArgv[gArgc++] = arg2;

                    /* Check for password in query string */
                    NSRange pwdRange = [query rangeOfString:@"password="];
                    if (pwdRange.location != NSNotFound) {
                        NSString *password = [query substringFromIndex:pwdRange.location + [@"password=" length]];
                        NSRange ampRange = [password rangeOfString:@"&"];
                        if (ampRange.location != NSNotFound) {
                            password = [password substringToIndex:ampRange.location];
                        }
                        if ([password length] > 0) {
                            const char *pwdCStr = [password UTF8String];
                            char *arg3 = (char *) SDL_malloc(strlen(pwdCStr) + 1);
                            strcpy(arg3, pwdCStr);
                            newargv = (char **) realloc(gArgv, sizeof(char *) * (gArgc + 2));
                            if (newargv) {
                                gArgv = newargv;
                                gArgv[gArgc++] = arg3;
                            }
                        }
                    }

                    /* Check for player name in query string */
                    NSRange nameRange = [query rangeOfString:@"name="];
                    if (nameRange.location != NSNotFound) {
                        NSString *playerName = [query substringFromIndex:nameRange.location + [@"name=" length]];
                        NSRange ampRange = [playerName rangeOfString:@"&"];
                        if (ampRange.location != NSNotFound) {
                            playerName = [playerName substringToIndex:ampRange.location];
                        }
                        if ([playerName length] > 0) {
                            const char *nameCStr = [playerName UTF8String];
                            char *nameArg = (char *) SDL_malloc(strlen("-name") + 1);
                            strcpy(nameArg, "-name");
                            char *nameValArg = (char *) SDL_malloc(strlen(nameCStr) + 1);
                            strcpy(nameValArg, nameCStr);
                            newargv = (char **) realloc(gArgv, sizeof(char *) * (gArgc + 3));
                            if (newargv) {
                                gArgv = newargv;
                                gArgv[gArgc++] = nameArg;
                                gArgv[gArgc++] = nameValArg;
                            }
                        }
                    }

                    gArgv[gArgc] = NULL;
                }
            }
        }
    }
}

/* Called when the internal event loop has just started running */
- (void) applicationDidFinishLaunching: (NSNotification *) note
{
    int status;

    /* Set the working directory to the .app's parent directory */
    [self setupWorkingDirectory:gFinderLaunch];

#if SDL_USE_NIB_FILE
    /* Set the main menu to contain the real app name instead of "SDL App" */
    [self fixMenu:[NSApp mainMenu] withAppName:getApplicationName()];
#endif

    /*
     * Process any pending Apple Events before proceeding.
     * When launched via URL scheme (novadoom://), macOS sends the URL as an
     * Apple Event. This event may arrive after applicationDidFinishLaunching:
     * is called, causing a race condition where we'd miss the URL.
     *
     * By running the event loop briefly here, we ensure any pending GetURL
     * events are processed before we set gCalledAppMainline and call SDL_main.
     */
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:0.1];
    while ([[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:deadline]) {
        /* Check if we've received a URL - if so, we can proceed */
        if (gURLProcessed) {
            break;
        }
        /* Also check if the deadline has passed */
        if ([deadline timeIntervalSinceNow] <= 0) {
            break;
        }
    }

    /* Hand off to main application code */
    gCalledAppMainline = true;
    status = SDL_main (gArgc, gArgv);

    /* We're done, thank you for playing */
    exit(status);
}
@end


@implementation NSString (ReplaceSubString)

- (NSString *)stringByReplacingRange:(NSRange)aRange with:(NSString *)aString
{
    unsigned int bufferSize;
    unsigned int selfLen = [self length];
    unsigned int aStringLen = [aString length];
    unichar *buffer;
    NSRange localRange;
    NSString *result;

    bufferSize = selfLen + aStringLen - aRange.length;
    buffer = NSAllocateMemoryPages(bufferSize*sizeof(unichar));

    /* Get first part into buffer */
    localRange.location = 0;
    localRange.length = aRange.location;
    [self getCharacters:buffer range:localRange];

    /* Get middle part into buffer */
    localRange.location = 0;
    localRange.length = aStringLen;
    [aString getCharacters:(buffer+aRange.location) range:localRange];

    /* Get last part into buffer */
    localRange.location = aRange.location + aRange.length;
    localRange.length = selfLen - localRange.location;
    [self getCharacters:(buffer+aRange.location+aStringLen) range:localRange];

    /* Build output string */
    result = [NSString stringWithCharacters:buffer length:bufferSize];

    NSDeallocateMemoryPages(buffer, bufferSize);

    return result;
}

@end



#ifdef main
#  undef main
#endif


/* Main entry point to executable - should *not* be SDL_main! */
int main (int argc, char **argv)
{
    /* Copy the arguments into a global variable */
    /* This is passed if we are launched by double-clicking */
    if ( argc >= 2 && strncmp (argv[1], "-psn", 4) == 0 ) {
        gArgv = (char **) SDL_malloc(sizeof (char *) * 2);
        gArgv[0] = argv[0];
        gArgv[1] = NULL;
        gArgc = 1;
        gFinderLaunch = YES;
    } else {
        /* Check if any argument is a novadoom:// URL and parse it */
        int urlArgIndex = -1;
        for (int i = 1; i < argc; i++) {
            if (argv[i] && strncmp(argv[i], "novadoom://", 11) == 0) {
                urlArgIndex = i;
                break;
            }
        }

        if (urlArgIndex >= 0) {
            /* Found a novadoom:// URL - parse it and convert to -connect */
            NSString *urlStr = [NSString stringWithUTF8String:argv[urlArgIndex]];
            NSString *remainder = [urlStr substringFromIndex:[@"novadoom://" length]];

            /* Remove "connect/" prefix if present */
            if ([remainder hasPrefix:@"connect/"]) {
                remainder = [remainder substringFromIndex:[@"connect/" length]];
            }

            /* Split on '?' to separate host:port from query params */
            NSRange queryRange = [remainder rangeOfString:@"?"];
            NSString *hostPort;
            NSString *query = @"";
            if (queryRange.location != NSNotFound) {
                hostPort = [remainder substringToIndex:queryRange.location];
                query = [remainder substringFromIndex:queryRange.location + 1];
            } else {
                hostPort = remainder;
            }

            /* Remove trailing slashes */
            while ([hostPort hasSuffix:@"/"]) {
                hostPort = [hostPort substringToIndex:[hostPort length] - 1];
            }

            if ([hostPort length] > 0) {
                const char *hostPortCStr = [hostPort UTF8String];

                /* Allocate gArgv with room for: program, -connect, host:port, [password], [-name, name], NULL */
                int extraArgs = 2; /* -connect and host:port */

                /* Check for password in query string */
                NSString *password = nil;
                NSRange pwdRange = [query rangeOfString:@"password="];
                if (pwdRange.location != NSNotFound) {
                    password = [query substringFromIndex:pwdRange.location + [@"password=" length]];
                    NSRange ampRange = [password rangeOfString:@"&"];
                    if (ampRange.location != NSNotFound) {
                        password = [password substringToIndex:ampRange.location];
                    }
                    if ([password length] > 0) {
                        extraArgs++; /* Add room for password */
                    } else {
                        password = nil;
                    }
                }

                /* Check for player name in query string */
                NSString *playerName = nil;
                NSRange nameRange = [query rangeOfString:@"name="];
                if (nameRange.location != NSNotFound) {
                    playerName = [query substringFromIndex:nameRange.location + [@"name=" length]];
                    NSRange ampRange = [playerName rangeOfString:@"&"];
                    if (ampRange.location != NSNotFound) {
                        playerName = [playerName substringToIndex:ampRange.location];
                    }
                    if ([playerName length] > 0) {
                        extraArgs += 2; /* Add room for -name and name value */
                    } else {
                        playerName = nil;
                    }
                }

                /* Build new argument list: program name, other args (except URL), -connect, host:port, [password], [-name, name] */
                gArgv = (char **) SDL_malloc(sizeof(char *) * (argc + extraArgs + 1));
                gArgc = 0;

                /* Copy program name */
                gArgv[gArgc++] = argv[0];

                /* Copy other arguments except the URL */
                for (int i = 1; i < argc; i++) {
                    if (i != urlArgIndex) {
                        gArgv[gArgc++] = argv[i];
                    }
                }

                /* Add -connect argument */
                char *connectArg = (char *) SDL_malloc(strlen("-connect") + 1);
                strcpy(connectArg, "-connect");
                gArgv[gArgc++] = connectArg;

                /* Add host:port argument */
                char *hostPortArg = (char *) SDL_malloc(strlen(hostPortCStr) + 1);
                strcpy(hostPortArg, hostPortCStr);
                gArgv[gArgc++] = hostPortArg;

                /* Add password if present */
                if (password) {
                    const char *pwdCStr = [password UTF8String];
                    char *pwdArg = (char *) SDL_malloc(strlen(pwdCStr) + 1);
                    strcpy(pwdArg, pwdCStr);
                    gArgv[gArgc++] = pwdArg;
                }

                /* Add player name if present */
                if (playerName) {
                    const char *nameCStr = [playerName UTF8String];
                    char *nameArg = (char *) SDL_malloc(strlen("-name") + 1);
                    strcpy(nameArg, "-name");
                    gArgv[gArgc++] = nameArg;
                    char *nameValArg = (char *) SDL_malloc(strlen(nameCStr) + 1);
                    strcpy(nameValArg, nameCStr);
                    gArgv[gArgc++] = nameValArg;
                }

                gArgv[gArgc] = NULL;
                gFinderLaunch = YES;  /* Treat as Finder launch to set up working directory correctly */
                gURLProcessed = YES;  /* Mark URL as already processed */
            } else {
                /* Invalid URL, fall back to default behavior */
                gArgc = argc;
                gArgv = (char **) SDL_malloc(sizeof(char *) * (argc + 1));
                for (int i = 0; i <= argc; i++)
                    gArgv[i] = argv[i];
                gFinderLaunch = NO;
            }
        } else {
            /* No URL argument, default behavior */
            int i;
            gArgc = argc;
            gArgv = (char **) SDL_malloc(sizeof (char *) * (argc+1));
            for (i = 0; i <= argc; i++)
                gArgv[i] = argv[i];
            gFinderLaunch = NO;
        }
    }

#if SDL_USE_NIB_FILE
    [NovaDoomApplication poseAsClass:[NSApplication class]];
    NSApplicationMain (argc, argv);
#else
    CustomApplicationMain (argc, argv);
#endif
    return 0;
}

