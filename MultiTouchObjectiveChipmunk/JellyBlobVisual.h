//
//  JellyBlobVisual.h
//  MultiTouchObjectiveChipmunk
//
//  Created by Kevin Loken on 12-01-27.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "JellyBlob.h"

@interface JellyBlobVisual : CCNode {
    CCTexture2D* _skin;
    JellyBlob* _jelly;
}

-(id)initWithJelly:(JellyBlob*)jelly;

@end
