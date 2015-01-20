//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

//
//  TransitCTBlock* has originally been developed by
//  Copyright (c) 2012 olettere
//
//  Find the code at
//  https://github.com/ebf/CTObjectiveCRuntimeAdditions
//

enum {
    TransitCTBlockDescriptionFlagsHasCopyDispose = (1 << 25),
    TransitCTBlockDescriptionFlagsHasCtor = (1 << 26), // helpers have C++ code
    TransitCTBlockDescriptionFlagsIsGlobal = (1 << 28),
    TransitCTBlockDescriptionFlagsHasStret = (1 << 29), // IFF BLOCK_HAS_SIGNATURE
    TransitCTBlockDescriptionFlagsHasSignature = (1 << 30)
};

typedef int TransitCTBlockDescriptionFlags;

struct TransitCTBlockLiteral {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct block_descriptor {
        unsigned long int reserved;	// NULL
        unsigned long int size;         // sizeof(struct Block_literal_1)
        // optional helper functions
        void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
        void (*dispose_helper)(void *src);             // IFF (1<<25)
        // required ABI.2010.3.16
        const char *signature;                         // IFF (1<<30)
    } *descriptor;
    // imported variables
};

@interface TransitCTBlockDescription : NSObject

@property (nonatomic, readonly) TransitCTBlockDescriptionFlags flags;
@property (nonatomic, readonly) NSMethodSignature *blockSignature;
@property (nonatomic, readonly) unsigned long int size;
@property (nonatomic, readonly) id block;

- (id)initWithBlock:(id)block;

@end
