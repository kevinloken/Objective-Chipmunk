#import "JellyBlob.h"

#import "ChipmunkDebugNode.h"

@interface JellyBlob()
@property(nonatomic, assign) NSSet *chipmunkObjects;
@end


@implementation JellyBlob

@synthesize control = _control, chipmunkObjects = _chipmunkObjects;
@synthesize centralBody = _centralBody;
@synthesize edgeBodies = _edgeBodies;
@synthesize edgeRadius = _edgeRadius;

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


-(cpFloat)distance:(cpVect)pos
{
    return sqrtf( (pos.x*pos.x) + (pos.y*pos.y));
}

-(cpFloat)angle:(cpVect)pos
{
    // calculate angle between 0,0 and pos
    if ( pos.y == 0.0 ) {
        if (pos.x < 0) {
            return M_PI;
        } else {
            return 0.0;
        }
    }
    
    if ( pos.x == 0.0 ) {
        if (pos.y < 0 ) {
            return 3.0 * M_PI / 2.0;
        } else {
            return M_PI / 2.0;
        }
    }
    
    cpFloat length = [self distance:pos];
    cpFloat cosine = pos.x / length;
    
    if ( pos.y < 0 ) {
        return -acosf(cosine);
    }
    
    return acosf(cosine);
}


-(id)initWithPos:(cpVect)pos count:(int)count vertices:(cpVect*)vertices mass:(cpFloat)mass
{
    self = [super init];
    if ( self != nil ) {
        NSMutableSet* set = [NSMutableSet set];
        self.chipmunkObjects = set;
        
        _count = count;
        _rate = 5.0;
        _torque = 50000.0;
        
        _centralBody = [ChipmunkBody bodyWithMass:mass andMoment:cpMomentForPoly(mass, _count, vertices, cpvzero)];
        [set addObject:_centralBody];
        _centralBody.pos = pos;
        
        ChipmunkShape* centralShape = [ChipmunkPolyShape polyWithBody:_centralBody count:_count verts:vertices offset:cpvzero];
        [set addObject:centralShape];
        centralShape.group = self;
        centralShape.layers = GRABABLE_LAYER;
        
        cpFloat edgeMass = 1.0/count;
		
        cpFloat radius = 0.0f;
        for ( int i = 0; i < count; ++i ) {
            radius += [self distance:vertices[i]];
        }
        radius = radius / (cpFloat)(count);
        
		cpFloat squishCoef = 0.7;
		cpFloat springStiffness = 3;
		cpFloat springDamping = 1;
		
		NSMutableArray *bodies = [[NSMutableArray alloc] initWithCapacity:count];
		_edgeBodies = bodies;

        // this is the spacing of the circles around the edge
        cpFloat edgeDistance = 2.0*radius*cpfsin(M_PI/(cpFloat)count);
        _edgeRadius = edgeDistance/2.0;
		
		for(int i=0; i<count; i++){
            cpFloat angle = [self angle:vertices[i]];
            cpVect unit = cpv(cosf(angle), sinf(angle));
            cpVect offset = cpvmult(unit, radius);

            NSLog(@"poly, vertex %d => (%f,%f) yields angle %f, unit vector (%f,%f) => offset = (%f,%f)", i, vertices[i].x,vertices[i].y, 360.0 * angle / (M_PI * 2.0), unit.x, unit.y, offset.x, offset.y);
            
			ChipmunkBody *body = [ChipmunkBody bodyWithMass:edgeMass andMoment:INFINITY];
			body.pos = cpvadd(pos, offset);
			[bodies addObject:body];
			
			ChipmunkShape *shape = [ChipmunkCircleShape circleWithBody:body radius:_edgeRadius offset:cpvzero];
			[set addObject:shape];
			shape.elasticity = 0;
			shape.friction = 0.7;
			shape.group = self;
			shape.layers = NORMAL_LAYER;
			
            ChipmunkSlideJoint* slide = [ChipmunkSlideJoint slideJointWithBodyA:_centralBody bodyB:body anchr1:offset anchr2:cpvzero min:0 max:radius*squishCoef];
			[set addObject:slide];
			
            cpVect springOffset;
            springOffset = cpvmult(unit, radius + _edgeRadius);
            
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

-(id)initWithPos:(cpVect)pos radius:(cpFloat)radius count:(int)count circle:(BOOL)circle;
{
	if((self = [super init])){
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

    
	self.chipmunkObjects = nil;
	
	[super dealloc];
}


@end
