//
// Created by behrens on 18.02.13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "ShareJSViewController.h"
#import "Transit.h"

@implementation ShareJSViewController {
    TransitContext *_transit;
    id _doc;
    __weak IBOutlet UITextView *textView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"ShareJS";
    [self setupTransit];
}

-(void)handleDeltas:(NSArray*)deltas {
    for(NSDictionary *delta in deltas) {
        int pos = [delta[@"p"] intValue];
        int len = 0;
        NSString *text = @"";

        if(delta[@"i"]) {
            text = delta[@"i"];
        }
        if(delta[@"d"]) {
            len = [delta[@"d"] length];
        }

        NSRange selectedRange = textView.selectedRange;

        UITextPosition *start = [textView positionFromPosition:textView.beginningOfDocument offset:pos];
        UITextPosition *end = [textView positionFromPosition:start offset:len];
        UITextRange *range = [textView textRangeFromPosition:start toPosition:end];
        [textView replaceRange:range withText:text];

        // quick'n dirty selection preservation
        int deltaLen = text.length - len;
        if(MAX(0, pos+deltaLen) <= selectedRange.location) {
            selectedRange.location += deltaLen;
        }
        textView.selectedRange = selectedRange;

    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // API of ShareJS requires separate insert and delete commands
    if(range.length>0)
        [_doc callMember:@"del" arg:@(range.location) arg:@(range.length)];
    if(text.length>0)
        [_doc callMember:@"insert" arg:@(range.location) arg:text];
    return YES;
}

-(void)checkForOpen:(id)doc {
    NSString* state = doc[@"state"];
    if([state isEqualToString:@"opening"]) {
        [self performSelector:@selector(checkForOpen:) withObject:doc afterDelay:0.5];
        return;
    }

    _doc = doc;

    // prepare textview for editing
    textView.text = [_doc callMember:@"getText"];
    textView.editable = YES;

    __weak id _self = self;
    // attach to change event
    TransitFunction *func = [_transit functionWithGenericBlock:^id(TransitNativeFunctionCallScope *callScope) {
        [_self handleDeltas:callScope.arguments[0]];
        return nil;
    }];

    // js: doc.on('remoteop, function)
    // could have been written as
    // [_transit eval:@"@.on('remoteop', @)" val:doc val:func];
    [_doc callMember:@"on" arg:@"remoteop" arg:func];
}

-(void)setupTransit {
    UIWebView *webView = UIWebView.new;
    
    _transit = [TransitUIWebViewContext contextWithUIWebView:webView];

    __weak id _self = self;
    _transit.readyHandler = ^(TransitContext* transit) {
            TransitFunction *func = [transit functionWithGenericBlock:^id(TransitNativeFunctionCallScope *callScope) {
                id doc = callScope.arguments[1];

                // to bad at this point the document is not open, yet
                // seems we have to poll for it's state
                [_self checkForOpen: doc];
                return nil;
            }];

        // exactly what's written at http://sharejs.org as code example
        [transit eval:@"sharejs.open('blag', 'text', @)" val:func];
    };

    NSURL *url = [[NSURL alloc] initWithString:@"http://sharejs.org"];
    [webView loadRequest:[NSURLRequest requestWithURL:url]];


}

@end