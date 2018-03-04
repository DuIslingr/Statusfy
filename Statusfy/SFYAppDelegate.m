//
//  SFYAppDelegate.m
//  Statusfy
//
//  Created by Paul Young on 4/16/14.
//  Copyright (c) 2014 Paul Young. All rights reserved.
//

#import "SFYAppDelegate.h"


static NSString * const SFYPlayerStatePreferenceKey = @"ShowPlayerState";
static NSString * const SFYPlayerDockIconPreferenceKey = @"YES";
static int const titleMaxLength = 40;

@interface SFYAppDelegate ()

@property (nonatomic, strong) NSMenu *menu;
@property (nonatomic, strong) NSMenuItem *playPauseMenuItem;
@property (nonatomic, strong) NSMenuItem *trackInfoMenuItem;
@property (nonatomic, strong) NSMenuItem *playerStateMenuItem;
@property (nonatomic, strong) NSMenuItem *dockIconMenuItem;
@property (nonatomic, strong) NSStatusItem *statusItem;
@property NSString *stateAndTrack;

@end

@implementation SFYAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification * __unused)aNotification
{
    //Initialize the variable the getDockIconVisibility method checks
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:SFYPlayerDockIconPreferenceKey];
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.highlightMode = YES;
    
    self.menu = [[NSMenu alloc] initWithTitle:@""];
    
    self.playPauseMenuItem = [[NSMenuItem alloc] initWithTitle:[self determinePlayPauseMenuItemTitle] action:@selector(togglePlayState) keyEquivalent:@""];

    self.trackInfoMenuItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@"" ];

    NSMenuItem *copySpotifyLinkMenuItem = [[NSMenuItem alloc] initWithTitle:@"Copy Spotify link" action:@selector(copySpotifyLinkToClipboard) keyEquivalent:@"" ];

    self.playerStateMenuItem = [[NSMenuItem alloc] initWithTitle:[self determinePlayerStateMenuItemTitle] action:@selector(togglePlayerStateVisibility) keyEquivalent:@""];
    
    self.dockIconMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Hide Dock Icon", nil) action:@selector(toggleDockIconVisibility) keyEquivalent:@""];
    
    [self.menu addItem:self.trackInfoMenuItem];
    [self.menu addItem:[NSMenuItem separatorItem]];
    [self.menu addItem:self.playPauseMenuItem];
    [self.menu addItem:copySpotifyLinkMenuItem];
    [self.menu addItem:[NSMenuItem separatorItem]];
    [self.menu addItem:self.playerStateMenuItem];
    [self.menu addItem:self.dockIconMenuItem];
    [self.menu addItem:[NSMenuItem separatorItem]];
    [self.menu addItemWithTitle:NSLocalizedString(@"Quit", nil) action:@selector(quit) keyEquivalent:@"q"];

    [self.statusItem setMenu:self.menu];
    
    [self setStatusItemTitle];
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(setStatusItemTitle) userInfo:nil repeats:YES];
}

#pragma mark - Setting title text

- (void)setStatusItemTitle
{
    NSString *trackName = [[self executeAppleScript:@"get name of current track"] stringValue];
    NSString *artistName = [[self executeAppleScript:@"get artist of current track"] stringValue];
    NSString *titleText = [NSString stringWithFormat:@"%@ – %@", trackName, artistName];
    NSString *playerState = [self determinePlayerState];

    NSString *stateAndTrack = [NSString stringWithFormat:@"%@%@%@", playerState, trackName, artistName];

    if (trackName && artistName) {
        if (![self.stateAndTrack isEqualToString:stateAndTrack]) {
            self.stateAndTrack = stateAndTrack;
            [self setTrackInfoMenuItem:artistName :trackName];
            [self setPlayPauseMenuItemTitle];
        } else {
            return;
        }

        if (titleText.length > titleMaxLength) {
            titleText = [[titleText substringToIndex:titleMaxLength] stringByAppendingString:@"…"];
        }
        
        if ([self getPlayerStateVisibility]) {
            titleText = [NSString stringWithFormat:@"%@ %@", playerState, titleText];
        }
        
        if (self.statusItem.menu != self.menu) {
            [self.statusItem setMenu:self.menu];
        }

        self.statusItem.image = nil;
        self.statusItem.title = titleText;
    } else {
        NSImage *image = [NSImage imageNamed:@"status_icon"];
        [image setTemplate:true];
        self.statusItem.image = image;
        self.statusItem.title = nil;
        [self showDisabledMenu];
    }
}

- (void)showDisabledMenu
{
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];

    [menu addItemWithTitle:NSLocalizedString(@"Spotify not running", nil) action:nil keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:NSLocalizedString(@"Quit", nil) action:@selector(quit) keyEquivalent:@"q"];

    [self.statusItem setMenu:menu];
}

#pragma mark - Setting title text

- (void)setTrackInfoMenuItem:(NSString *)artistName :(NSString *)trackName
{
    NSString *album = [[self executeAppleScript:@"get album of current track"] stringValue];
    NSString *formatString = [NSString stringWithFormat:@"Track\t%@\nArtist\t%@\nAlbum\t%@", trackName, artistName, album];

    self.trackInfoMenuItem.attributedTitle = [[NSAttributedString alloc] initWithString:formatString];
}

#pragma mark - Executing AppleScript

- (NSAppleEventDescriptor *)executeAppleScript:(NSString *)command
{
    command = [NSString stringWithFormat:@"if application \"Spotify\" is running then tell application \"Spotify\" to %@", command];
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:command];
    NSAppleEventDescriptor *eventDescriptor = [appleScript executeAndReturnError:NULL];
    return eventDescriptor;
}

#pragma mark - Player state

- (BOOL)getPlayerStateVisibility
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:SFYPlayerStatePreferenceKey];
}

- (void)setPlayerStateVisibility:(BOOL)visible
{
    [[NSUserDefaults standardUserDefaults] setBool:visible forKey:SFYPlayerStatePreferenceKey];
    self.stateAndTrack = nil; // Force repaint
}

- (void)togglePlayState
{
    [self executeAppleScript:@"playpause"];
    [self setPlayPauseMenuItemTitle];
}

- (void)setPlayPauseMenuItemTitle
{
    self.playPauseMenuItem.title = [self determinePlayPauseMenuItemTitle];
}

- (void)togglePlayerStateVisibility
{
    [self setPlayerStateVisibility:![self getPlayerStateVisibility]];
    self.playerStateMenuItem.title = [self determinePlayerStateMenuItemTitle];
}

- (NSString *)determinePlayPauseMenuItemTitle
{
    return [[self determinePlayerState] isEqualToString:@"►"] ? NSLocalizedString(@"❚❚ Pause ", nil) : NSLocalizedString(@"► Play", nil);
}

- (NSString *)determinePlayerStateMenuItemTitle
{
    return [self getPlayerStateVisibility] ? NSLocalizedString(@"Hide Player State", nil) : NSLocalizedString(@"Show Player State", nil);
}

- (void)copySpotifyLinkToClipboard
{
    NSString *spotifyId = [[[self executeAppleScript:@"get spotify url of current track"] stringValue] substringFromIndex:14];
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:[NSString stringWithFormat:@"https://open.spotify.com/track/%@", spotifyId] forType:NSPasteboardTypeString];
}

- (NSString *)determinePlayerState
{
    NSString *playerStateText = nil;
    NSString *playerStateConstant = [[self executeAppleScript:@"get player state"] stringValue];
    
    if ([playerStateConstant isEqualToString:@"kPSP"]) {
        playerStateText = NSLocalizedString(@"►", nil);
    }
    else if ([playerStateConstant isEqualToString:@"kPSp"]) {
        playerStateText = NSLocalizedString(@"❚❚", nil);
    }
    else {
        playerStateText = NSLocalizedString(@"◼", nil);
    }
    
    return playerStateText;
}

#pragma mark - Toggle Dock Icon

- (BOOL)getDockIconVisibility
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:SFYPlayerDockIconPreferenceKey];
}

- (void)setDockIconVisibility:(BOOL)visible
{
   [[NSUserDefaults standardUserDefaults] setBool:visible forKey:SFYPlayerDockIconPreferenceKey];
}

- (void)toggleDockIconVisibility
{
    [self setDockIconVisibility:![self getDockIconVisibility]];
    self.dockIconMenuItem.title = [self determineDockIconMenuItemTitle];
    
    if(![self getDockIconVisibility])
    {
        //Apple recommended method to show and hide dock icon
        //hide icon
        [NSApp setActivationPolicy: NSApplicationActivationPolicyAccessory];
    }
    else
    {
        //show icon
        [NSApp setActivationPolicy: NSApplicationActivationPolicyRegular];
    }
}

- (NSString *)determineDockIconMenuItemTitle
{
    return [self getDockIconVisibility] ? NSLocalizedString(@"Hide Dock Icon", nil) : NSLocalizedString(@"Show Dock Icon", nil);
}

#pragma mark - Quit

- (void)quit
{
    [[NSApplication sharedApplication] terminate:self];
}

@end
