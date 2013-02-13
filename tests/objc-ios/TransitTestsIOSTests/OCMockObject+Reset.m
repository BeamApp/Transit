//
//  OCMockObject+Reset.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 13.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import "OCMockObject+Reset.h"

@implementation OCMockObject (Reset)

-(void)resetMock {
    self->exceptions = nil;
	self->recorders = nil;
	self->expectations = nil;
	self->rejections = nil;;
	self->exceptions = nil;
}

@end
