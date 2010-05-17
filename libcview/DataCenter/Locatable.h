/*

This file is part of the CVIEW graphics system, which is goverened by the following License

Copyright © 2008,2009, Battelle Memorial Institute
All rights reserved.

1.	Battelle Memorial Institute (hereinafter Battelle) hereby grants permission
	to any person or entity lawfully obtaining a copy of this software and
	associated documentation files (hereinafter “the Software”) to redistribute
	and use the Software in source and binary forms, with or without
	modification.  Such person or entity may use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and may permit
	others to do so, subject to the following conditions:

	•	Redistributions of source code must retain the above copyright
		notice, this list of conditions and the following disclaimers. 
	•	Redistributions in binary form must reproduce the above copyright
		notice, this list of conditions and the following disclaimer in the
		documentation and/or other materials provided with the distribution.
	•	Other than as used herein, neither the name Battelle Memorial
		Institute or Battelle may be used in any form whatsoever without the
		express written consent of Battelle.  
	•	Redistributions of the software in any form, and publications based
		on work performed using the software should include the following
		citation as a reference:

			(A portion of) The research was performed using EMSL, a
			national scientific user facility sponsored by the
			Department of Energy's Office of Biological and
			Environmental Research and located at Pacific Northwest
			National Laboratory.

2.	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL BATTELLE OR CONTRIBUTORS BE LIABLE FOR ANY
	DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
	ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
	THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

3.	The Software was produced by Battelle under Contract No. DE-AC05-76RL01830
	with the Department of Energy.  The U.S. Government is granted for itself
	and others acting on its behalf a nonexclusive, paid-up, irrevocable
	worldwide license in this data to reproduce, prepare derivative works,
	distribute copies to the public, perform publicly and display publicly, and
	to permit others to do so.  The specific term of the license can be
	identified by inquiry made to Battelle or DOE.  Neither the United States
	nor the United States Department of Energy, nor any of their employees,
	makes any warranty, express or implied, or assumes any legal liability or
	responsibility for the accuracy, completeness or usefulness of any data,
	apparatus, product or process disclosed, or represents that its use would
	not infringe privately owned rights.  

*/
#ifndef LOCATABLE_H
#define LOCATABLE_H
#import "Vector.h"
/**
    @author Brock Erwin

  * interface Locatable
  * simple class that holds a Location object
  */
#import <Foundation/NSObject.h>
#import "Point.h"
#import "Identifiable.h"
#import "Drawable.h"
#import "Pickable.h"
@interface Locatable : Identifiable <Drawable, Pickable> {
    Vector *location;
    Vector *rotation;
    NSString *name;
    float width;
    float height;
    float depth;
    // Used if you want to draw a box at a given location and rotation with a given width, height, and depth
    // in this case call -draw; or you can call -glPickDraw to use that box for picking purposes
    NSData *boundingBox;
    NSData *wireframeBox;
}
+(void)drawGLQuad: (Point) p1 andP2: (Point) p2
            andP3: (Point) p3 andP4: (Point) p4;
-setName: (NSString *) name;
-(NSString*) name;
-setLocation: (Vector*) _location;
-(Vector*) location;
-setRotation: (Vector*) _rotation;
-(Vector*) rotation;
-setWidth: (float) _width;
-setHeight: (float) _height;
-setDepth: (float) _depth;
-(float)width;
-(float)height;
-(float)depth;
/**
    Draws a opengl box (6 sided) at given location, rotation, width, depth, height
  */
-drawBox;
-draw;
-drawWireframe;
/**
    Easy way to do rotations and translations if you inherit this class.
    Simply call: setLocation with your current location AND
                 setRotation with your appropriate rotation
        Then you can call setupForDraw and based on location and rotation
        it will make gl calls to translate and rotate the current matrix

    Make sure you call cleanUpAfterDraw once done drawing stuff
  */
-setupForDraw;
-cleanUpAfterDraw;
/**
    called when picking objects in the scene (does not render)
    @return An array of objects that were picked
 */
-glPickDraw;
@end

#endif // LOCATABLE_H
