//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import "TransitCTBlockDescription.h"

@interface NSInvocation (PrivateHack)
- (void)invokeUsingIMP: (IMP)imp;
@end

@implementation TransitCTBlockDescription

- (id)initWithBlock:(id)block
{
    if (self = [super init]) {
        _block = block;

        struct TransitCTBlockLiteral *blockRef = (__bridge struct TransitCTBlockLiteral *)block;
        _flags = blockRef->flags;
        _size = blockRef->descriptor->size;

        if (_flags & TransitCTBlockDescriptionFlagsHasSignature) {
            void *signatureLocation = blockRef->descriptor;
            signatureLocation += sizeof(unsigned long int);
            signatureLocation += sizeof(unsigned long int);

            if (_flags & TransitCTBlockDescriptionFlagsHasCopyDispose) {
                signatureLocation += sizeof(void(*)(void *dst, void *src));
                signatureLocation += sizeof(void (*)(void *src));
            }

            const char *signature = (*(const char **)signatureLocation);
            _blockSignature = [NSMethodSignature signatureWithObjCTypes:signature];
        }
    }
    return self;
}

@end
