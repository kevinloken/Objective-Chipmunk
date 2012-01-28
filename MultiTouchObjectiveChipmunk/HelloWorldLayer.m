#import "HelloWorldLayer.h"

#import "ChipmunkDebugNode.h"
#import "JellyBlob.h"
#import "JellyBlobVisual.h"

@implementation HelloWorldLayer

+(CCScene *)scene
{
	CCScene *scene = [CCScene node];
	HelloWorldLayer *layer = [HelloWorldLayer node];
	[scene addChild: layer];
	
	return scene;
}

-(id)init
{
	if((self=[super init])){
		self.isTouchEnabled = YES;
		
		_space = [[ChipmunkSpace alloc] init];
		_space.gravity = cpv(0, -200);
		
		CGRect rect = CGRectMake(0, 0, 480, 320);
		[_space addBounds:rect thickness:5 elasticity:1 friction:1 layers:CP_ALL_LAYERS group:CP_NO_GROUP collisionType:nil];
		
		_multiGrab = [[ChipmunkMultiGrab alloc] initForSpace:_space withSmoothing:cpfpow(0.8, 60.0) withGrabForce:20000];
		
		ChipmunkDebugNode *debugNode = [ChipmunkDebugNode debugNodeForSpace:_space];
		[self addChild:debugNode];
		
		{ // Add a box
			cpFloat mass = 5;
			cpFloat width = 200;
			cpFloat height = 60;
			
			ChipmunkBody *body = [_space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForBox(mass, width, height)]];
			body.pos = cpv(150, 160);
			
			ChipmunkShape *shape = [_space add:[ChipmunkPolyShape boxWithBody:body width:width height:height]];
			shape.friction = 0.7;
		}
		
		{ // Add a circle
			cpFloat mass = 1;
			cpFloat radius = 50;
			
			ChipmunkBody *body = [_space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForCircle(mass, 0, radius, cpvzero)]];
			body.pos = cpv(400, 160);
			
			ChipmunkShape *shape = [_space add:[ChipmunkCircleShape circleWithBody:body radius:radius offset:cpvzero]];
			shape.friction = 0.7;
		}
        
        { // Add a blob
            JellyBlob* circle = [[JellyBlob alloc] initWithPos:cpv(52,160) radius:50 count:16 circle:YES];
            [_space add:circle];
            
            JellyBlobVisual* visual = [[[JellyBlobVisual alloc] initWithJelly:circle] autorelease];
            [self addChild:visual];
            
            JellyBlob* square = [[JellyBlob alloc] initWithPos:cpv(300,160) radius:50 count:16 circle:NO];
            [_space add:square];
        }
		
        self.isAccelerometerEnabled = YES;
        [[UIAccelerometer sharedAccelerometer] setUpdateInterval:1.0f/30.0f];
        
		[self scheduleUpdate];
	}
	
	return self;
}

-(void)dealloc
{	
	[_space release];
	[_multiGrab release];
	
    [[UIAccelerometer sharedAccelerometer] setDelegate:nil];
    
	[super dealloc];
}

-(void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
    const float kFilterFactor = 0.05f;
    static float prevX=0, prevY=0;
    
    float accelX = acceleration.x * kFilterFactor + (1- kFilterFactor)*prevX;
    float accelY = acceleration.y * kFilterFactor + (1- kFilterFactor)*prevY;
    prevX = accelX;
    prevY = accelY;
    cpVect v = cpv( -accelY, accelX);
    [_space setGravity: cpvmult(v, 2000)];
}

-(void)update:(cpFloat)dt
{
    for ( int i = 0; i < 4; ++i ) {
        [_space step:dt/4.0];    
    }
	
}

static cpVect
TouchLocation(UITouch *touch)
{
	return [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
	for(UITouch *touch in touches) [_multiGrab beginLocation:TouchLocation(touch)];
}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
	for(UITouch *touch in touches) [_multiGrab updateLocation:TouchLocation(touch)];
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
{
	for(UITouch *touch in touches) [_multiGrab endLocation:TouchLocation(touch)];
}

@end
