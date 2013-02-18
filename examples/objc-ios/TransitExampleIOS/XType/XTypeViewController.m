//
//  XTypeViewController.m
//  TransitExampleIOS
//
//  Created by Heiko Behrens on 11.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import "XTypeViewController.h"
#import "Transit.h"
#import <AudioToolbox/AudioServices.h>
#import <AVFoundation/AVFoundation.h>

@interface XTypeViewController (){
    TransitUIWebViewContext *transit;
}

@property (nonatomic, readonly) AVAudioPlayer* soundShoot;
@property (nonatomic, readonly) AVAudioPlayer* soundExplode;
@property (nonatomic, readonly) AVAudioPlayer* soundMusic;

@end

@implementation XTypeViewController

#pragma mark - Managing the detail item

-(void)stopShootSound {
    [_soundShoot stop];
}

-(void)playShootSound {
    if(!_soundShoot.playing) {
        _soundShoot.currentTime = 0;
        [_soundShoot play];
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

    __weak XTypeViewController* _self = self;

    // only sound on mobile version is explosion
    [transit replaceFunctionAt:@"ig.Sound.prototype.play" withFunctionWithBlock:^id(TransitFunction *original, TransitNativeFunctionCallScope* scope) {
        [_self playSoundFromStart:_self.soundExplode];
        return @YES;
    }];

    [transit replaceFunctionAt:@"ig.Music.prototype.play" withFunctionWithBlock:^id(TransitFunction *original,TransitNativeFunctionCallScope* scope) {
        [_self.soundMusic play];
        return @YES;
    }];

    // shoot sound is disabled on mobile. Hook into shoot logic to start sound
    [transit replaceFunctionAt:@"EntityPlayer.prototype.shoot" withFunctionWithBlock:^id(TransitFunction *original,TransitNativeFunctionCallScope* scope) {
        [_self playShootSound];
        return [scope forwardToFunction:original];
    }];
    
    // vibrate
    TransitReplaceFunctionBlock vibrate = ^id(TransitFunction *original, TransitNativeFunctionCallScope* scope) {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        return [scope forwardToFunction:original];
    };
    
    [transit replaceFunctionAt:@"EntityEnemyHeart.prototype.kill" withFunctionWithBlock:vibrate];
    [transit replaceFunctionAt:@"EntityPlayer.prototype.kill" withFunctionWithBlock:vibrate];
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
    _soundShoot = [self loadSound:@"plasma-burst"];
    _soundExplode = [self loadSound:@"explosion"];
    _soundMusic = [self loadSound:@"xtype"];
    _soundMusic.volume = 0.4;
    _soundMusic.numberOfLoops = -1;


    [self configureView];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"X-Type";
    }
    return self;
}
							
#pragma mark - Split view

- (void)configureView
{
    transit = [TransitUIWebViewContext contextWithUIWebView:self.webView];

    // best hook to patch XType is on first call of window.setTimeout. The game engine calls this once with
    // window.setTimeout(XType.startGame, 1);
    __block BOOL firstCall = YES;
    __weak id _self = self;
    [transit replaceFunctionAt:@"setTimeout" withFunctionWithBlock:^id(TransitFunction *original, TransitNativeFunctionCallScope* scope) {
        if(firstCall)
            [_self setupTransit];
        firstCall = NO;
        return [original callWithThisArg:scope.thisArg arguments:scope.arguments];
    }];

    // load unmodified game from web
    NSURL *url = [NSURL URLWithString:@"http://phoboslab.org/xtype/"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}
@end
