/*

This file is port of the CVIEW graphics system, which is goverened by the following License

Copyright © 2020, Battelle Memorial Institute
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
#import "SinDataSet.h"
#import "CropDataSet.h"
#import "cview.h"

int main(int argc,char *argv[], char *env[]) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
#ifndef __APPLE__
	//needed for NSLog
	[NSProcessInfo initializeWithArguments: argv count: argc environment: env ];
#endif
	GimpGradient *ggr;
    NSString *testdata = find_resource_path(@"gimpgradient.ggr");
    if (testdata == nil) {
        NSLog(@"Error Loading Test Gradient");
        exit(1);
    }

    ggr = [[GimpGradient alloc] initWithFile: testdata];
	SinDataSet *ds = [[SinDataSet alloc] initWithName: @"Sin()" Width: 1000 Height: 128 interval: 5.0];
	CropDataSet *ds2 = [[CropDataSet alloc] initWithName: @"Cropped" dataSet: ds];
	[[[[ds2 setLeft: 100] setRight: 0] setTop: 0] setBottom: 10];

	[[ValueStore valueStore] setKey: @"ds" withObject: ds];
	[[ValueStore valueStore] setKey: @"ds2" withObject: ds2];

	GLScreen * g = [[GLScreen alloc] initName: @"GL CropData Test" withWidth: 1920 andHeight: 1080];
	GLGrid *grid = [[[[GLGrid alloc] initWithDataSet: ds andType: G_SURFACE] setXTicks: 50] setYTicks: 16];
    GLGrid *grid2 = [[[[GLGrid alloc] initWithDataSet: ds2] setXTicks: 50] setYTicks: 16];
	[grid setGradient: ggr];
	Scene * scene = [[Scene alloc] initWithObject: grid atX: 0 Y: 0 Z: 0];
    
	[scene addObject: grid2 atX: 0 Y: 0 Z: 200];
    
	Scene *aligns = [[Scene alloc] initWithObject:
			[[[GLText alloc] initWithString: @"One Should be cropped" andFont: @"LinLibertine_Re.ttf"] autorelease]
 		alignHoriz: -1 Vert: 1];

	[[[[g addWorld: @"TL" row: 0 col: 0 rowPercent: 50 colPercent:50]
		setScene: scene]
		setOverlay: aligns]
		setEye: [[[Eye alloc] init] setX: 591 Y: 1437.0 Z: 1291.0 Hangle:-4.8 Vangle: -2.47]
	];
	[g dumpScreens];
	[g run];
    // might want to autorelease these above when they are allocated.
    [g autorelease];
    [ds autorelease];
    [ds2 autorelease];
    [ggr autorelease];
    [aligns autorelease];
    //[grid autorelease];
    [scene autorelease];
	[pool release];
	return 0;
}
