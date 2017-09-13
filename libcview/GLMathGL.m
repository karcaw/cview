/*

This file is port of the CVIEW graphics system, which is goverened by the following License

Copyright © 2008-2014, Battelle Memorial Institute
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
#include <math.h>
#import <Foundation/Foundation.h>
#import <gl.h>
#import <glut.h>
#import <mgl2/mgl_cf.h>
#import "cview.h"
#import "DataSet.h"
#import "DictionaryExtra.h"
#import "ValueStore.h"
#import "Defaults.h"
#import "GLMathGL.h"

/**
Data layout for reference:
@verbatim
(0,height)                                                            (width,height)
*=========================================================================*
|                                                                         |
|                                                                         |
|                                                                         |
|                                                                         |
*=========================================================================*
(0,0)                                                                 (width,0)
@endverbatim
*/


@implementation GLMathGL


-init {
	[super init];
	// This lock protects the changing of the dataset.
	dataSetsLock = [[NSRecursiveLock alloc] init];
	dataSets = [[NSMutableArray arrayWithCapacity: 5] retain];
	
	return self;
}

-initWidth: (int)width andHeight: (int)height {
	[self init];
	[self setHeight: height];
	[self setWidth: width];
	tw=width;
	th=height;
	return self;
}

-addDataSetKey: (NSString *)key {
	DataSet *ds = [[ValueStore valueStore] getObject: key];
	[dataSetsLock lock];
	[dataSets addObject: ds];
	NSLog(@"register notify for: %@ %@",self,ds);
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveResizeNotification:) name:@"DataSetResize" object:ds];
	[dataSetsLock unlock];
	if ([ds dataValid])
		[self resetImage];
	
	return self;

}
-(void)receiveResizeNotification: (NSNotification *)notification {
	NSLog(@"GLChartResize notification: %@",notification);
	[self resetImage];
}


-(void)resetImage {
	float *d;
	int i,len,hmax;
	NSEnumerator *list;
  	DataSet *ds;
	HMGL gr;
	float max=0.0;
	hmax=1;

	[dataSetsLock lock];

	len=0;
  	list = [dataSets objectEnumerator];
  	ds = [list nextObject];

	HMDT dsm = mgl_create_data();
	HMDT dsm2 = mgl_create_data();
	mgl_data_set_float(dsm,(float *)[[ds rowTotals] bytes],[ds height],1,1);
	max = MAX(max,[ds getRowMax]);
	hmax = MAX(hmax,[ds height]);
	ds = [list nextObject];
	mgl_data_set_float(dsm2,(float *)[[ds rowTotals] bytes],[ds height],1,1);
	max = MAX(max,[ds getRowMax]);
	hmax = MAX(hmax,[ds height]);
	//mglGraph gr(chartWidth,chartHeight);
	gr = mgl_create_graph(w,h);
  	//gr.FPlot("sin(pi*x)");
  	mgl_set_font_def(gr,"w:rC");
  	mgl_clf_str(gr,"x00000000");
	mgl_box_str(gr,"w",1);
	mgl_label(gr,'x',"Xaxis",-1,"");
	mgl_set_ranges(gr,0,hmax,0,max*1.1,0,0);
	mgl_axis(gr,"x","w","");
	mgl_axis(gr,"y","w","");
	mgl_plot(gr,dsm,"w","");
	mgl_plot(gr,dsm2,"b","");
	//mgl_fplot(gr,"sin(pi*x)","","");

	[dataSetsLock unlock];
	[image autorelease];
	image = [NSMutableData dataWithBytes: mgl_get_rgba(gr) length:w*h*4];
	bound = NO;
	return;
}


-(NSArray *)getDataSetKeys {
	return [dataSets arrayObjectsFromPerformedSelector: @selector(valueStoreKey)];
}

-initWithPList: (id)list {
	NSLog(@"initWithPList: %@",[self class]);
	NSArray *keys;
	[super initWithPList: list];
		
	keys = [list objectForKey: @"valueStoreDataSetKeys"];
	NSLog(@"keys: %@",keys);
	if (keys) {
		NSString *o;
		NSEnumerator *list;
		list = [keys objectEnumerator];
		while ( (o = [list nextObject]) ) {
			NSLog(@"key: %@",o);
			[self addDataSetKey: o];
		}
	}
	return self;
}


-getPList {
	NSLog(@"getPList: %@",self);
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: [super getPList]];
	
	PLIST_SET_IF_NOT_DEFAULT_INT(dict, chartWidth);
	PLIST_SET_IF_NOT_DEFAULT_INT(dict, chartHeight);

	[dict setObject: [dataSets  arrayObjectsFromPerformedSelector: @selector(valueStoreKey)] forKey:@"valueStoreDataSetKeys"];
	
	return dict;
}

-(NSArray *)attributeKeys {
	//isVisible comes from the DrawableObject
	return [NSArray arrayWithObjects: @"isVisible",nil];
}
/*
-(NSDictionary *)tweaksettings {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSString stringWithFormat: @"help='Tick separation in the X axis' min=0 max=%d step=1 precision=0",currentLen],@"ticks",
		@"help='scaling of the descriptive font tile' min=0.1 max=4.0 precision=1 step=0.1",@"fontScale",
		@"min=0 max=1",@"isVisible",
		@"step=0.1",@"dxmult",
		@"step=0.1",@"rmult",
		@"min=0.0 step=0.01 max=1.0",@"fontColorR",
		@"min=0.0 step=0.01 max=1.0",@"fontColorG",
		@"min=0.0 step=0.01 max=1.0",@"fontColorB",
		@"min=0 max=1",@"chartType",
		[NSString stringWithFormat: @"min=2 max=%d",MAX_TICKS],@"axisTicks",
		nil];
}
*/
-(void)dealloc {
	NSLog(@"GLGrid dealloc");
	[dataSetsLock lock];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[dataSets autorelease];
	[dataSetsLock autorelease];
	return [super dealloc];
}


@end
