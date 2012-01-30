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
    
	NSSet *_chipmunkObjects;
}

@property(nonatomic, assign) cpFloat control;
@property(nonatomic, readonly) NSSet *chipmunkObjects;
@property(nonatomic, readonly) NSArray *edgeBodies;
@property(nonatomic, readonly) ChipmunkBody* centralBody;
@property(nonatomic, readonly) cpFloat edgeRadius;

-(id)initWithPos:(cpVect)pos radius:(cpFloat)radius count:(int)count circle:(BOOL)circle;
-(id)initWithPos:(cpVect)pos count:(int)count vertices:(cpVect*)vertices mass:(cpFloat)mass;


@end
