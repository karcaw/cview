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
#import <Foundation/Foundation.h>
#include <math.h>
#import <sys/param.h>  //for max/min
#import "ColorMap.h"



@implementation ColorMap

+mapWithMax: (int)max {
	ColorMap *map = [[ColorMap alloc] initWithMax: max];
	return [map autorelease];
}

-initWithMax: (int)max {
	int i;
	float val;
	float *cm;
	NSLog(@"initWithMax: %d",max);
	theMax = max>32?max:100; //make sure we have enough differences..
	colormap = [[NSMutableData alloc] initWithLength: (theMax+2)*sizeof(float)*3];
	cm = (float *)[colormap mutableBytes];
	//NSLog(@"cm: %p",cm);
	theMax++;
	for (i=0;i<theMax;i++) {
		val = ((float)i/theMax);
		cm[i*3+0] = [self r: val];
		cm[i*3+1] = [self g: val];
		cm[i*3+2] = [self b: val];
		//NSLog(@"CM: %d:%d = (%.2f,%.2f,%.2f)",i,val,cm[i*3+0],cm[i*3+1],cm[i*3+2]);
	}
	cm[theMax*3+0] = 1.0;
	cm[theMax*3+1] = 1.0;
	cm[theMax*3+2] = 1.0;
	//for (i=0;i<=theMax;i++)
	//	NSLog(@"CM: %d = (%.2f,%.2f,%.2f)",i,cm[i*3+0],cm[i*3+1],cm[i*3+2]);
	return self;
}

-(void)dealloc {
	NSLog(@"ColorMap dealloc");
	[colormap autorelease];
	[super dealloc];
	return;
}

-doMapWithPoints: (float *)points thatHasLength: (int)len toColors: (float *)colors {
	float *cm;
	int i;
	int data;
	cm = (float *)[colormap mutableBytes];

	for (i=0;i<len;i++) {
		data = (int)points[i*3+1];

		if (data >= theMax)
			data = theMax;
		if (data < 0)
			data = 0;

		colors[i*3+0] = cm[data*3+0];
		colors[i*3+1] = cm[data*3+1];
		colors[i*3+2] = cm[data*3+2];
		//memcpy(colors+i*3,cm+((int)data[i]),3*sizeof(float));
	}
	return self;
}

-doMapWithData: (float *)data thatHasLength: (int)len toColors: (float *)colors {
	float *cm;
	int i;
	int d;
	cm = (float *)[colormap mutableBytes];

	for (i=0;i<len;i++) {
		d=(int)data[i];
		if (d >= theMax)
			d = theMax;
		if (d < 0)
			d = 0;

		colors[i*3+0] = cm[d*3+0];
		colors[i*3+1] = cm[d*3+1];
		colors[i*3+2] = cm[d*3+2];
		//memcpy(colors+i*3,cm+((int)data[i]),3*sizeof(float));
	}
	return self;
}

-do4DMapWithData: (float *)data thatHasLength: (int)len toColors: (float *)colors {
	float *cm;
	int i;
	int d;
	cm = (float *)[colormap mutableBytes];
	//cm = (float *)[[[NSMutableData alloc] initWithLength: (theMax+2)*sizeof(float)*4] mutableBytes];
	for (i=0;i<len;i++) {
		d=(int)data[i];
		if (d >= theMax)
			d = theMax;
		if (d < 0)
			d = 0;

		colors[i*4+0] = cm[d*3+0];
		colors[i*4+1] = cm[d*3+1];
		colors[i*4+2] = cm[d*3+2];
		colors[i*4+3] = d == 0 ? 0.0 : 1.0;
//		colors[i*4+3] = .1;//d == 0 ? 0.0 : 1.0;
		//memcpy(colors+i*3,cm+((int)data[i]),3*sizeof(float));
	}
	return self;
}

-glMap: (int)val {
	float *cm;
	cm = (float *)[colormap mutableBytes];
	//NSLog(@"cm: %p",cm);
	if (val >= 0 && val <= theMax) {
		//NSLog(@"glMap: %d (%.2f,%.2f,%.2f)",val,cm[val*3+0],cm[val*3+1],cm[val*3+2]);
		glColor3fv(cm+val*3);
	}
	else
		NSLog(@"Invalid Value in glMap: %d",val);
	return self;
}

-(float)r: (float)i {
	return MAX(0,-3.0*powf(i-1.0,2)+1);
}
-(float)g: (float)i {
	return MAX(0,-6.0*powf(i-0.5,2)+1);
}
-(float)b: (float)i {
	return MAX(0,-3.0*powf(i,2)+1);
}
@end

