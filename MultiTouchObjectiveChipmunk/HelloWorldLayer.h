#import "cocos2d.h"
#import "ObjectiveChipmunk.h"

@interface HelloWorldLayer : CCLayer
{
	ChipmunkSpace *_space;
	ChipmunkMultiGrab *_multiGrab;
}

+(CCScene *) scene;

@end
