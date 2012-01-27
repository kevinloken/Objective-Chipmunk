#import "JellyBlob.h"

#import "ChipmunkDebugNode.h"

@interface JellyBlob()
@property(nonatomic, assign) NSSet *chipmunkObjects;
@end


@implementation JellyBlob

@synthesize control = _control, chipmunkObjects = _chipmunkObjects;

-(cpVect)offsetForCircle:(cpFloat)angle
{
    cpVect dir = cpvforangle(angle); 
    return dir;
}

-(cpVect)offsetForSquare:(cpFloat)angle
{
    cpVect unit = cpvzero;
    cpFloat square = 1.0f;
    
    if ( angle >= 0 && angle <= (M_PI/4.0) ) {
        unit = cpv(square,square * tan(angle));
    } else if ( angle > M_PI/4.0 && angle <= M_PI/2.0 ) {
        unit = cpv(square - square*tan(angle - M_PI / 4.0),square);
    } else if ( angle > M_PI / 2.0 && angle <= 3.0 * M_PI / 4.0 ) {
        unit = cpv(0-square*tan(angle-M_PI/2.0),square);
    } else if ( angle > 3.0 * M_PI / 4.0 && angle <= M_PI ) {
        unit = cpv(-square,square - square * tan(angle - 3.0 * M_PI / 4.0));
    } else if ( angle > M_PI && angle <= 5.0 * M_PI / 4.0 ) {
        unit = cpv(-square,-square * tan(angle - M_PI));
    } else if ( angle > 5.0 * M_PI / 4.0 && angle <= 6.0 * M_PI / 4.0 ) {
        unit = cpv(-square + square * tan(angle - 5.0 * M_PI / 4.0), -square);
    } else if ( angle > 6.0 * M_PI / 4.0 && angle <= 7.0 * M_PI / 4.0 ) {
        unit = cpv(square * tan(angle - 6.0 * M_PI / 4.0), -square);
    } else if ( angle > 7.0 * M_PI / 4.0 ) {
        unit = cpv(square, -square + square * tan(angle - 7.0 * M_PI / 4.0));
    }
    
    return unit;
}

#define BLOB_FILENAME @"somefile"

-(id)initWithPos:(cpVect)pos radius:(cpFloat)radius count:(int)count circle:(BOOL)circle;
{
	if((self = [super init])){
        // load skin
        _skin = [ [ [ CCTextureCache sharedTextureCache ] addImage:BLOB_FILENAME ] retain ];

        
		NSMutableSet *set = [NSMutableSet set];
		self.chipmunkObjects = set;
		
		_count = count;
		
		_rate = 5.0;
		_torque = 50000.0;
		
		cpFloat centralMass = 0.5;
		
        if ( circle ) {
            _centralBody = [ChipmunkBody bodyWithMass:centralMass andMoment:cpMomentForCircle(centralMass, 0, radius, cpvzero)];
        } else {
            _centralBody = [ChipmunkBody bodyWithMass:centralMass andMoment:cpMomentForBox(centralMass, radius, radius)];
        }
		[set addObject:_centralBody];
		_centralBody.pos = pos;
		
        ChipmunkShape *centralShape = nil;
        if ( circle ) {
            centralShape = [ChipmunkCircleShape circleWithBody:_centralBody radius:radius offset:cpvzero];            
        } else {
            centralShape = [ChipmunkPolyShape boxWithBody:_centralBody width:radius height:radius];
        }
        
        [set addObject:centralShape];
		centralShape.group = self;
		centralShape.layers = GRABABLE_LAYER;
		
		cpFloat edgeMass = 1.0/count;
		cpFloat edgeDistance = 2.0*radius*cpfsin(M_PI/(cpFloat)count);
		_edgeRadius = edgeDistance/2.0;
		
		cpFloat squishCoef = 0.7;
		cpFloat springStiffness = 3;
		cpFloat springDamping = 1;
		
		NSMutableArray *bodies = [[NSMutableArray alloc] initWithCapacity:count];
		_edgeBodies = bodies;
		
		for(int i=0; i<count; i++){
            cpFloat angle = ((cpFloat)i/(cpFloat)count)*(2.0*M_PI);
            
            cpVect unit;
            cpVect offset;
            
            if ( circle ) {
                unit = [self offsetForCircle:angle];
                offset = cpvmult(unit, radius);
            } else {
                unit = [self offsetForSquare:angle];
                offset = cpvmult(unit, radius/2.0);
            }
            
			ChipmunkBody *body = [ChipmunkBody bodyWithMass:edgeMass andMoment:INFINITY];
			body.pos = cpvadd(pos, offset);
			[bodies addObject:body];
			
			ChipmunkShape *shape = [ChipmunkCircleShape circleWithBody:body radius:_edgeRadius offset:cpvzero];
			[set addObject:shape];
			shape.elasticity = 0;
			shape.friction = 0.7;
			shape.group = self;
			shape.layers = NORMAL_LAYER;
			
			[set addObject:[ChipmunkSlideJoint slideJointWithBodyA:_centralBody bodyB:body anchr1:offset anchr2:cpvzero min:0 max:radius*squishCoef]];
			
            cpVect springOffset;
            if ( circle ) {
                springOffset = cpvmult(unit, radius + _edgeRadius);
            } else {
                springOffset = cpvmult(unit, radius/2.0 + _edgeRadius);
            }
			[set addObject:[ChipmunkDampedSpring dampedSpringWithBodyA:_centralBody bodyB:body anchr1:springOffset anchr2:cpvzero restLength:0 stiffness:springStiffness damping:springDamping]];
		}
		
		[set addObjectsFromArray:bodies];
		
		for(int i=0; i<count; i++){
			ChipmunkBody *a = [bodies objectAtIndex:i];
			ChipmunkBody *b = [bodies objectAtIndex:(i+1)%count];
			[set addObject:[ChipmunkSlideJoint slideJointWithBodyA:a bodyB:b anchr1:cpvzero anchr2:cpvzero min:0 max:edgeDistance]];
		}
		
		_motor = [ChipmunkSimpleMotor simpleMotorWithBodyA:_centralBody bodyB:[ChipmunkBody staticBody] rate:0];
		[set addObject:_motor];
		_motor.maxForce = 0;
	}
	
	return self;
}

-(void)setControl:(cpFloat)value
{
	_motor.maxForce = (value == 0.0 ? 0.0 : _torque);
	_motor.rate = _rate*value;
	
	_control = value;
}


- (void)dealloc
{
	[_centralBody release];
	[_motor release];
	[_edgeBodies release];
	
    // clean up
    [ _skin release ];
    
	self.chipmunkObjects = nil;
	
	[super dealloc];
}

#define BLOB_SEGMENTS 16
#define BLOB_SKIN_SCALE 1.0f

-( void )draw {
	CGPoint segmentPos[ BLOB_SEGMENTS + 2 ];
	CGPoint texturePos[ BLOB_SEGMENTS + 2 ];
	CGPoint textureCenter;
	float angle, baseAngle;
    
	// calculate triangle fan segments
    
	segmentPos[ 0 ] = CGPointZero;
	for ( int count = 0; count < BLOB_SEGMENTS; count ++ ) {
		// get relative position and multiply for scale
        ChipmunkBody* eb = [_edgeBodies objectAtIndex:count];
		segmentPos[ count + 1 ] = ccpMult( ccpSub( eb.pos, _centralBody.pos ), BLOB_SKIN_SCALE );
	}
	segmentPos[ BLOB_SEGMENTS + 1 ] = segmentPos[ 1 ];
    
	// move to absolute position
	for ( int count = 0; count < ( BLOB_SEGMENTS + 2 ); count ++ )
		segmentPos[ count ] = ccpAdd( _centralBody.pos, segmentPos[ count ] );
    
	// remap skin
	// done to be able to control skin rotation independently from blob rotation
    ChipmunkBody* eb = [_edgeBodies objectAtIndex:0];
	baseAngle = 0; // [ UTIL angle:_centralBody.pos b:eb.pos ];
    
	texturePos[ 0 ] = CGPointZero;
	for ( int count = 0; count < BLOB_SEGMENTS; count ++ ) {
		// calculate new angle
		angle						= baseAngle + ( 2 * M_PI / BLOB_SEGMENTS * count );
		// calculate texture position
		texturePos[ count + 1 ].x	= sinf( angle );
		texturePos[ count + 1 ].y	= cosf( angle );
	}
	texturePos[ BLOB_SEGMENTS + 1 ] = texturePos[ 1 ];
    
	// recalculate to texture coordinates
	textureCenter = CGPointMake( 0.5f, 0.5f );
	for ( int count = 0; count < ( BLOB_SEGMENTS + 2 ); count ++ )
		texturePos[ count ] = ccpAdd( ccpMult( texturePos[ count ], 0.5f ), textureCenter );
    
    
	glColor4ub( 255, 255, 255, 255 );
    
	glEnable( GL_TEXTURE_2D );
	glBindTexture( GL_TEXTURE_2D, [ _skin name ] ); 
    
	// glDisableClientState( GL_TEXTURE_COORD_ARRAY );
	glDisableClientState( GL_COLOR_ARRAY );
    
	glTexCoordPointer( 2, GL_FLOAT, 0, texturePos );
    
	glVertexPointer( 2, GL_FLOAT, 0, segmentPos );
    
	glDrawArrays( GL_TRIANGLE_FAN, 0, BLOB_SEGMENTS + 2 );
    
}

@end
