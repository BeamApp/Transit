//
//  DetailViewController.m
//  TransitExampleIOS
//
//  Created by Heiko Behrens on 11.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import "DetailViewController.h"
#import "Transit.h"
#import <AudioToolbox/AudioServices.h>
#import <AVFoundation/AVFoundation.h>

@interface DetailViewController (){
    TransitUIWebViewContext *transit;
    AVAudioPlayer* soundExplode;
    AVAudioPlayer* soundShoot;
    AVAudioPlayer* soundMusic;
}

@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation DetailViewController

#pragma mark - Managing the detail item

-(void)stopShootSound {
    [soundShoot stop];
}

-(void)playShootSound {
    if(!soundShoot.playing) {
        soundShoot.currentTime = 0;
        [soundShoot play];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopShootSound) object:nil];
    [self performSelector:@selector(stopShootSound) withObject:nil afterDelay:0.1];
}

-(void)playSoundFromStart:(AVAudioPlayer*)sound {
    if(!sound.playing || sound.currentTime > 1) {
        [sound stop];
        sound.currentTime = 0;
    }
    [sound play];
}

-(void)setupTransit {
    // only sound on mobile version is explosion
    [transit replaceFunctionAt:@"ig.Sound.prototype.play" withFunctionWithBlock:^id(TransitFunction *original, TransitProxy *thisArg, NSArray *arguments) {
        [self playSoundFromStart:soundExplode];
        return @YES;
    }];

    [transit replaceFunctionAt:@"ig.Music.prototype.play" withFunctionWithBlock:^id(TransitFunction *original, TransitProxy *thisArg, NSArray *arguments) {
        [soundMusic play];
        return @YES;
    }];

    // shoot sound is disabled on mobile. Hook into shoot logic to start sound
    [transit replaceFunctionAt:@"EntityPlayer.prototype.shoot" withFunctionWithBlock:^id(TransitFunction *original, TransitProxy *thisArg, NSArray *arguments) {
        [self playShootSound];
        return [transit eval:@"@.apply(@,@)" arguments:@[original, thisArg, arguments]];
    }];
    
    // vibrate
    TransitReplaceFunctionBlock vibrate = ^id(TransitFunction *original, TransitProxy *thisArg, NSArray *arguments) {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        return [transit eval:@"@.apply(@,@)" arguments:@[original, thisArg, arguments]];
    };
    
    [transit replaceFunctionAt:@"EntityEnemyHeart.prototype.kill" withFunctionWithBlock:vibrate];
    [transit replaceFunctionAt:@"EntityPlayer.prototype.kill" withFunctionWithBlock:vibrate];
}

- (void)configureView
{
    transit = [TransitUIWebViewContext contextWithUIWebView:self.webView];
    
    // best hook to patch XType is on first call of window.setTimeout. The game engine calls this once with
    // window.setTimeout(XType.startGame, 1);
    __block BOOL firstCall = YES;
    [transit replaceFunctionAt:@"setTimeout" withFunctionWithBlock:^id(TransitFunction *original, TransitProxy *thisArg, NSArray *arguments) {
        if(firstCall)
            [self setupTransit];
        firstCall = NO;
        return [original callWithThisArg:thisArg arguments:arguments];
    }];
    
    // load unmodified game from web
    NSURL *url = [NSURL URLWithString:@"http://phoboslab.org/xtype/"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

-(AVAudioPlayer*)loadSound:(NSString*)name {
    NSURL *url = [NSBundle.mainBundle URLForResource:name withExtension:@"mp3"];
    AVAudioPlayer* result = [AVAudioPlayer.alloc initWithContentsOfURL:url error:nil];
    [result prepareToPlay];
    return result;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    soundExplode = [self loadSound:@"explosion"];
    soundShoot = [self loadSound:@"plasma-burst"];
    soundMusic = [self loadSound:@"xtype"];
    soundMusic.volume = 0.4;
    soundMusic.numberOfLoops = -1;
    
    [self configureView];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Detail", @"Detail");
    }
    return self;
}
							
#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

@end
