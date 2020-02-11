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
#import <Foundation/Foundation.h>
#import <sys/param.h>  //for max/min
#import "CropDataSet.h"
#import "ValueStore.h"
#import "Defaults.h"

#define IGNORE 	NSLog(@"CropDataSet-%@:%s ignored",name,__FUNCTION__)


@implementation CropDataSet
- initWithName: (NSString *)n dataSet: (DataSet *)ds {
	[super initWithName: n Width: [ds width] Height: [ds height]];

	dataSet = [ds retain];
	left=0;
	right=0;
	bottom=0;
	top=0;

	return self;
}


-initWithPList: (id)list {
	DataSet *ds;
	NSLog(@"initWithPList: %@",[self class]);

	[super initWithPList: list];

	ds = [[ValueStore valueStore] getObject: [list objectForKey: @"valueStoreDataSetKey"]];
	NSLog(@"DataSet from ValueStore: %@",ds);
	dataSet = [ds retain];

	left = [Defaults integerForKey: @"left" Id: self Override: list];
	right = [Defaults integerForKey: @"right" Id: self Override: list];
	top = [Defaults integerForKey: @"top" Id: self Override: list];
	bottom = [Defaults integerForKey: @"bottom" Id: self Override: list];

	return self;
}

-getPList {
	NSLog(@"getPList: %@",self);
	NSMutableDictionary *dict = [super getPList];
	PLIST_SET_IF_NOT_DEFAULT_INT(dict, left);
	PLIST_SET_IF_NOT_DEFAULT_INT(dict, right);
	PLIST_SET_IF_NOT_DEFAULT_INT(dict, top);
	PLIST_SET_IF_NOT_DEFAULT_INT(dict, bottom);
	[dict setObject: [[ValueStore valueStore] getKeyForObject:dataSet] forKey: @"valueStoreDataSetKey"];
	return dict;
}

-(NSArray *)attributeKeys {
	NSArray *new = [NSArray arrayWithObjects: @"left", @"right", @"top", @"bottom",nil];
	return [new arrayByAddingObjectsFromArray: [super attributeKeys]];
}

-(NSDictionary *)tweaksettings {
	return [NSDictionary dictionaryWithObjectsAndKeys:
         @"help='Left side crop' label='Left' min=0 step=1",@"left",
         @"help='Right side crop' label='Right' min=0 step=1",@"right",
         @"help='Top side crop' label='Top' min=0 step=1",@"top",
         @"help='Bottom side crop' label='Bottom' min=0 step=1",@"bottom",
          nil];
}
- setLeft: (int)l {
	if ( l >= 0 && [dataSet width]-right-l > 1)
		left = l;
		width = [dataSet width]-right-left;
		[[NSNotificationCenter defaultCenter] postNotificationName: @"DataSetResize" object: self];
	return self;
}
- setRight: (int)r {
	if (r >= 0 && [dataSet width]-left-r > 1)
		right = r;
		width = [dataSet width]-right-left;
		[[NSNotificationCenter defaultCenter] postNotificationName: @"DataSetResize" object: self];
	return self;
}
- setTop: (int)t {
	if (t >= 0 && [dataSet height]-bottom-t > 1)
		top = t;
		height = [dataSet height]-bottom-top;
		[[NSNotificationCenter defaultCenter] postNotificationName: @"DataSetResize" object: self];
	return self;
}
- setBottom: (int)b {
	if (b >= 0 && [dataSet height]-top-b > 1)
		bottom = b;
		height = [dataSet height]-bottom-top;
		[[NSNotificationCenter defaultCenter] postNotificationName: @"DataSetResize" object: self];
	return self;
}

- (int)left {
	return left;
}
- (int)right {
	return right;
};
- (int)top {
	return top;
}
- (int)bottom {
	return bottom;
};
- (NSString *)rowTick: (int)row {
	return [dataSet rowTick:row+bottom];
}
- (NSString *)columnTick: (int)col {
	return [dataSet columnTick:col+left];
}
- (NSDictionary *)columnMeta: (int)col {
	return [dataSet columnMeta:col+left];
}

- (float *)dataRow: (int)row {
	float *d = (float *)[dataSet data];
	return d+(row+left)*[dataSet height]+bottom;
}

/* call in this section are from dataset, we either
   ignore things, or pass them to the dataset function */
- (float *)data {
	int row;
	[data autorelease];
	data = [[NSMutableData alloc] initWithLength: width*height*sizeof(float)];
	float *src = (float *)[dataSet data]; // source array
	float *dest = (float *)[data mutableBytes];
	for (row = 0; row < width; row++)
		memcpy(dest+row*height,src+(row+left)*[dataSet height]+bottom,height*sizeof(float));
	//FIXME: this should probably be defined
	return dest;
}

- (NSData *)dataObject {
	IGNORE;
	return nil;
}

- shiftData: (int)num{
	IGNORE;
	return self;
};

- (float)getMax {
	return [dataSet getMax];
}

- (float)resetMax {
	return [dataSet resetMax];
}

- lockMax: (int)max {
	IGNORE;
	return self;
}

- (NSString *)getLabel: (float)rate {
	return [dataSet getLabel:rate];
}

- (NSString *)getLabelFormat {
	return [dataSet getLabelFormat];
}

- setLabelFormat: (NSString *)fmt {
	[dataSet setLabelFormat: fmt];
	return self;
};

- setNewData: (NSData *)data {
	IGNORE;
	return self;
}
//- setDescription: (NSString *)description;
//- (NSString *)getDescription;
//- setRate:(NSString *)r;
//- (NSString *)getRate;
//- description;
- (BOOL)dataValid {
	return [dataSet dataValid];
}

/* end section of ignore/pass-on */

-(void)dealloc {
	NSLog(@"dealloc CropDataSet:%@",name);
	[dataSet autorelease];
	[super dealloc];
}


@end /* SinDataSet */
