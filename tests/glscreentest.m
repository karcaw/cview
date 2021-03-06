/*

This file is port of the CVIEW graphics system, which is goverened by the following License

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
#import <gl.h>

#import <glut.h>
#import "cview.h"

@interface MyTest : DrawableObject {
	double size;
}
-(id) initWithSize: (double)s;
-(id) glDraw;
@end

@implementation MyTest
-(id) initWithSize: (double)s {
	[super init];
	size = s;
	return self;
}
-(id) glDraw {
	glColor3f(1.0,0.0,0.0);
	glutWireTeapot(size);
	//NSLog(@"Teapot");
	return self;
}
@end

int main(int argc,char *argv[], char *env[]) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
#ifndef __APPLE__
	//needed for NSLog
	[NSProcessInfo initializeWithArguments: argv count: argc environment: env ];
#endif
	
	GLScreen * g = [[GLScreen alloc] initName: @"GLScreen Test"];
	Scene * scene = [[Scene alloc] initWithObject:
		[[MyTest alloc] initWithSize: 5]
		atX: 0 Y: 0 Z: 0];
	Scene * stext = [[Scene alloc] initWithObject:
		[[GLText alloc] initWithString: @"Test String" 
			andFont: @"LinLibertine_Re.ttf"]
		atX: 0 Y: 0 Z: 0];
	[stext addObject: [[MyTest alloc] initWithSize: 4]
		atX: 0 Y: 0 Z: 0];

	Scene *aligns = [[Scene alloc] init];
	int i,j;
	@try {
	for (i=-1;i<=1;i++)
		for (j=-1;j<=1;j++)
			[aligns addObject: [[GLText alloc] initWithString:
				[NSString stringWithFormat: @"(%d,%d)",i,j] andFont:@"LinLibertine_Re.ttf" ]
			alignHoriz: i Vert: j];
	}
   	@catch (NSException *localException) {
        NSLog(@"Error: %@", localException);
        return -1;
    }


	[[[g addWorld: @"TL" row: 0 col: 0 rowPercent: 50 colPercent:50] 
		setScene: scene] 
		setEye: [[[Eye alloc] init] setX: -10.0 Y: 20.0 Z: -10.0 Hangle:-1.94 Vangle: -2.57]
	];
	[[[g addWorld: @"TR" row: 0 col: 1 rowPercent: 25 colPercent:50]
		setScene: scene] 
		setEye: [[[Eye alloc] init] setX: -10.0 Y: 20.0 Z: 10.0 Hangle:-3.94 Vangle: -2.57]
	];
	[[[g addWorld: @"BL" row: 1 col: 0 rowPercent: 75 colPercent:25]
		setScene: scene] 
		setEye: [[[Eye alloc] init] setX: -10.0 Y: 20.0 Z: 10.0 Hangle:-3.94 Vangle: -2.57]
	];
	[[[[g addWorld: @"BM" row: 1 col: 1 rowPercent: 75 colPercent:50]
		setScene: stext]
		setOverlay: aligns]
		setEye: [[[Eye alloc] init] setX: -144.0 Y: 460.0 Z: 214.0 Hangle:-3.94 Vangle: -2.57]
	];
	[g addWorld: @"BR" row: 1 col: 2 rowPercent: 25 colPercent:25];
	[g addWorld: @"Crazy" row: 5 col: 1 rowPercent: 10 colPercent:1];
	[g dumpScreens];
	[g run];
	[pool release];
	return 0;
}
