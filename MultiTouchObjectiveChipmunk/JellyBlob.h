#import <Foundation/Foundation.h>

#define NORMAL_LAYER 1
#define GRABABLE_LAYER 2

#import "ObjectiveChipmunk.h"
#import "cocos2d.h"

@interface JellyBlob : NSObject <ChipmunkObject> {
	int _count;
	cpFloat _edgeRadius;
	
	ChipmunkBody *_centralBody;
	NSArray *_edgeBodies;
	
	ChipmunkSimpleMotor *_motor;
	cpFloat _rate, _torque;
	cpFloat _control;
	
    CCTexture2D* _skin;
    
	NSSet *_chipmunkObjects;
}

@property(nonatomic, assign) cpFloat control;
@property(nonatomic, readonly) NSSet *chipmunkObjects;

-(id)initWithPos:(cpVect)pos radius:(cpFloat)radius count:(int)count circle:(BOOL)circle;

@end
