#import "TransitAbstractWebViewContext.h"

typedef void (^TransitWebViewContextRequestHandler)(TransitAbstractWebViewContext*,NSURLRequest*);

@interface TransitAbstractWebViewContext()

@property (readonly) BOOL codeInjected;
@property(assign) BOOL proxifyEval;

@property(copy) TransitWebViewContextRequestHandler handleRequestBlock;

- (void)doInvokeNative;
- (id)parseJSON:(NSString *)json;

@end
