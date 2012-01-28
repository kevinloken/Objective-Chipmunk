//
//  JellyBlobVisual.m
//  MultiTouchObjectiveChipmunk
//
//  Created by Kevin Loken on 12-01-27.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "JellyBlobVisual.h"
#import "JellyBlob.h"


@implementation JellyBlobVisual

#define BLOB_FILENAME @"Gradient.png"

-(id)initWithJelly:(JellyBlob*)jelly
{
    self = [super init];
    if ( self != nil ) {
        // load skin
        _jelly = jelly;
        // _skin = [ [ [ CCTextureCache sharedTextureCache ] addImage:BLOB_FILENAME ] retain ];
        
        UIImage* image = [[UIImage imageNamed:BLOB_FILENAME] retain];
        _skin = [[[CCTexture2D alloc] initWithImage:image] retain];
    }
    return self;
}

-(void)dealloc
{
    // clean up
    [ _skin release ];
    
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
        ChipmunkBody* eb = [_jelly.edgeBodies objectAtIndex:count];
		segmentPos[ count + 1 ] = ccpMult( ccpSub( eb.pos, _jelly.centralBody.pos ), BLOB_SKIN_SCALE );
	}
	segmentPos[ BLOB_SEGMENTS + 1 ] = segmentPos[ 1 ];
    
	// move to absolute position
	for ( int count = 0; count < ( BLOB_SEGMENTS + 2 ); count ++ )
		segmentPos[ count ] = ccpAdd( _jelly.centralBody.pos, segmentPos[ count ] );
    
	// remap skin
	// done to be able to control skin rotation independently from blob rotation
    ChipmunkBody* eb = [_jelly.edgeBodies objectAtIndex:0];
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
