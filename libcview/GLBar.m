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
#import <gl.h>
#import <glut.h>
#include <math.h>
#import "cview.h"
#import "DataSet.h"
#import "DictionaryExtra.h"



@implementation  GLBar
//static NSArray *barTypeStrings=nil;  //these are for expansion and not used yet.
static const char *barTypeSelectors[] =	{ 
	"drawSquares",
};

static float bar_quads[72] = {
0.0 , 1.0 , 0.0 , 1.0 , 1.0 , 0.0 , 1.0 , 1.0 , 1.0 , 0.0 , 1.0 , 1.0 , //Top  keep here.
0.0 , 0.0 , 0.0 , 1.0 , 0.0 , 0.0 , 1.0 , 1.0 , 0.0 , 0.0 , 1.0 , 0.0 , //Front Face
0.0 , 0.0 , 1.0 , 0.0 , 1.0 , 1.0 , 1.0 , 1.0 , 1.0 , 1.0 , 0.0 , 1.0 , //Back
//0.0 , 0.0 , 0.0 , 0.0 , 0.0 , 1.0 , 1.0 , 0.0 , 1.0 , 1.0 , 0.0 , 0.0 , //Bottom
0.0 , 0.0 , 0.0 , 0.0 , 1.0 , 0.0 , 0.0 , 1.0 , 1.0 , 0.0 , 0.0 , 1.0 , //Left
1.0 , 0.0 , 0.0 , 1.0 , 0.0 , 1.0 , 1.0 , 1.0 , 1.0 , 1.0 , 1.0 , 0.0 , //Right
};


-init {
	[super init];
	dataSetLock = [[NSRecursiveLock alloc] init];
	currentMax = 0.0;
	fontScale = 1.0;
	fontColorR = 1.0;
	fontColorG = 1.0;
	fontColorB = 1.0;
	highlightColorR = 0.4;
	highlightColorG = 0.4;
	highlightColorB = 0.4;
	xscale=1.0;
	yscale=1.0;
	zscale=1.0;
	dzmult=0.0;
	rmult=1.0;
	axisTicks=6;
	tickMax=1.0;
	currentTicks[0]=0.0;
	currentTicks[1]=1.0;
	numTicks=2;
	baseWidth=50.0;
	baseLength=50.0;
	barWidth=30.0;
	barLength=30.0;
	gridw=0;
	gridl=0;
	usersetwidth=0;
	barType=B_SQUARE;
	descText = [[GLText alloc] initWithString: @"Unset" andFont: @"LinLibertine_Re.ttf"];
	barText = nil;
	return self;
}

-initWithDataSet: (DataSet *)ds andType: (BarTypesEnum)type{
	[self init];
	[self setBarType: type];
	[self setDataSet: ds];
	return self; 	
}

-initWithDataSet: (DataSet *)ds {
	[self init];
	[self setDataSet: ds];
	return self;
}

-setDataSet: (DataSet *)ds {
	int i;
	GLText *txt;
	[dataSetLock lock];	
	[ds retain];
	[dataSet autorelease];
	dataSet = ds;
	[descText setString: [dataSet getDescription]]; //assume description will not change..
	[self setWidth: sqrt([ds width])];
	usersetwidth=NO;
	[dataSetLock unlock];
	
	barText = [[NSMutableArray arrayWithCapacity: [ds width]] retain];
	for (i=0;i<[ds width];i++) {
		txt = [[GLText alloc] initWithString: [ds columnTick: i] andFont: @"LinLibertine_Re.ttf"];
		[txt setRotationOnX: -90.0 Y:0.0 Z:0.0];
		//[txt setColorRed: 0.0 Green: 0.0 Blue: 0.0];
		[barText insertObject: txt atIndex: i];
        [txt autorelease];
	}
	
	return self;
}

-(DataSet *)getDataSet {
	return dataSet;
}
-(float)getWidth {
	return gridw;
}
-setWidth: (float)w {
	gridw = (int)floor(w);
	gridl = [dataSet width]/gridw;
	if (gridw*gridl < [dataSet width])
		gridl++;
	//NSLog(@"Size: %d => %d %d",[dataSet width],gridw,gridl);
	usersetwidth=YES;
	return self;
}
-initWithPList: (id)list {
	NSLog(@"initWithPList: %@",[self class]);
	DataSet *ds;
	int w;
	[super initWithPList: list];
	/// @todo error checking or exception handling.
	fontScale = [[list objectForKey: @"fontScale" missing: @"1.0"] floatValue];
	fontColorR = [[list objectForKey: @"fontColorR" missing: @"1.0"] floatValue];
	fontColorG = [[list objectForKey: @"fontColorG" missing: @"1.0"] floatValue];
	fontColorB = [[list objectForKey: @"fontColorB" missing: @"1.0"] floatValue];
	highlightColorR = [[list objectForKey: @"highlightColorR" missing: @"0.4"] floatValue];
	highlightColorG = [[list objectForKey: @"highlightColorG" missing: @"0.4"] floatValue];
	highlightColorB = [[list objectForKey: @"highlightColorB" missing: @"0.4"] floatValue];
	xscale = [[list objectForKey: @"xscale" missing: @"1.0"] floatValue];
	yscale = [[list objectForKey: @"yscale" missing: @"1.0"] floatValue];
	zscale = [[list objectForKey: @"zscale" missing: @"1.0"] floatValue];
	baseLength = [[list objectForKey: @"baseLength" missing: @"50.0"] floatValue];
	barLength = [[list objectForKey: @"barLength" missing: @"30.0"] floatValue];
	baseWidth = [[list objectForKey: @"baseWidth" missing: @"50.0"] floatValue];
	barWidth = [[list objectForKey: @"barWidth" missing: @"30.0"] floatValue];
	barType = [[list objectForKey: @"barType" missing: B_SQUARE_STRING] intValue];	
	w = [[list objectForKey: @"width" missing: @"-1"] intValue];
	
	Class c;
	c = NSClassFromString([list objectForKey: @"dataSetClass"]);
	NSLog(@"dataSetClass is: %@", c);
	if (c && [c conformsToProtocol: @protocol(PList)] && [c isSubclassOfClass: [DataSet class]]) {;
		ds=[[c alloc] initWithPList: [list objectForKey: @"dataSet"]];
		[self setDataSet: ds];
		if (w > 0) {
			[self setWidth: w];
			usersetwidth = YES;
		}
	}
	return self;
}
 
-getPList {
	NSLog(@"getPList: %@",self);
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: [super getPList]];
	[dict setObject: [dataSet getPList] forKey: @"dataSet"];
	[dict setObject: [dataSet className] forKey: @"dataSetClass"];
	[dict setObject: [NSNumber numberWithFloat: fontScale] forKey: @"fontScale"];
	[dict setObject: [NSNumber numberWithFloat: fontColorR] forKey: @"fontColorR"];
	[dict setObject: [NSNumber numberWithFloat: fontColorG] forKey: @"fontColorG"];
	[dict setObject: [NSNumber numberWithFloat: fontColorB] forKey: @"fontColorB"];
	[dict setObject: [NSNumber numberWithFloat: highlightColorR] forKey: @"highlightColorR"];
	[dict setObject: [NSNumber numberWithFloat: highlightColorG] forKey: @"highlightColorG"];
	[dict setObject: [NSNumber numberWithFloat: highlightColorB] forKey: @"highlightColorB"];
	[dict setObject: [NSNumber numberWithFloat: xscale] forKey: @"xscale"];
	[dict setObject: [NSNumber numberWithFloat: yscale] forKey: @"yscale"];
	[dict setObject: [NSNumber numberWithFloat: zscale] forKey: @"zscale"];
	[dict setObject: [NSNumber numberWithFloat: barWidth] forKey: @"barWidth"];
	[dict setObject: [NSNumber numberWithFloat: baseWidth] forKey: @"baseWidth"];
	[dict setObject: [NSNumber numberWithFloat: barLength] forKey: @"barLength"];
	[dict setObject: [NSNumber numberWithFloat: baseLength] forKey: @"baseLength"];
	[dict setObject: [NSNumber numberWithInt: barType] forKey: @"barType"];
	if (usersetwidth)
		[dict setObject: [NSNumber numberWithInt: gridw] forKey: @"width"];		
	return dict;
}

-(NSArray *)attributeKeys {
	//isVisible comes from the DrawableObject
	return [NSArray arrayWithObjects: @"isVisible",@"fontScale",@"xscale",@"yscale",@"zscale",
									@"dzmult",@"rmult",@"fontColorR",@"fontColorG",@"fontColorB",
									@"barType",@"dataSet",@"baseWidth",@"barWidth",@"baseLength",
									@"highlightColorR",@"highlightColorG",@"highlightColorB",
									@"barLength",@"width",@"axisTicks",nil];
}

-(NSDictionary *)tweaksettings {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		@"min=0.1 step=0.05",@"xscale",
		@"min=0.1 step=0.05",@"yscale",
		@"min=0.1 step=0.05",@"zscale",
		@"help='scaling of the descriptive font tile' min=0.1 max=4.0 precision=1 step=0.1",@"fontScale",
		@"min=0 max=1",@"isVisible",
		@"step=0.1",@"dxmult",
		@"step=0.1",@"rmult",
		@"min=0.0 step=0.01 max=1.0",@"fontColorR",
		@"min=0.0 step=0.01 max=1.0",@"fontColorG",
		@"min=0.0 step=0.01 max=1.0",@"fontColorB",	
		@"min=0.0 step=0.01 max=1.0",@"highlightColorR",
		@"min=0.0 step=0.01 max=1.0",@"highlightColorG",
		@"min=0.0 step=0.01 max=1.0",@"highlightColorB",
		@"min=0 max=3",@"barType",
		@"min=1.0",@"baseWidth",
		@"min=1.0",@"barWidth",
		@"min=1.0",@"baseLength",
		@"min=1.0",@"barLength",
		[NSString stringWithFormat: @"min=1 step=1 max=%d",[dataSet width]],@"width",
		[NSString stringWithFormat: @"min=2 max=%d",MAX_TICKS],@"axisTicks",
		nil];
}

-(void)dealloc {
	NSLog(@"GLBar dealloc");
	[dataSetLock lock];
	[colorMap autorelease];
	[dataSet autorelease];
	[dataSetLock autorelease];
	[barText autorelease];
	return [super dealloc];
}

-glDraw {
	float max = [dataSet getMax];
	
	if (currentMax != max || currentMax==0) {
		NSLog(@"New Max: %.2f %.2f",max,currentMax);
		currentMax = max==0?1:max;
		numTicks = niceticks(0,currentMax,currentTicks,axisTicks);
		tickMax = currentTicks[numTicks-1];
		
		[colorMap autorelease];
		colorMap = [ColorMap mapWithMax: tickMax];
		[colorMap retain];
	}

	glScalef(1.0,1.0,1.0); 
	
	[dataSetLock lock];
	[self drawPlane];
	[self performSelector: sel_registerName(barTypeSelectors[barType]) ];
	[self drawAxis];
	[self drawTitles];
	[dataSetLock unlock];
	
	return self;
}

-drawTitles {
	glPushMatrix();
	glScalef(1.0,1.0,zscale); 
	glTranslatef(0.0,0,gridl*baseLength+15+15*fontScale);
	glRotatef(90,1.0,0.0,0.0);
	
	glScalef(fontScale,fontScale,fontScale/zscale);

	[descText setColorRed: fontColorR Green: fontColorG Blue: fontColorB];
	[descText setString: [dataSet getDescription]]; 
	[descText glDraw];

	glPopMatrix();
	return self;
}

-drawAxis {
	int i;
	float bsize=0.25/xscale;
	float j,step,x,y;

	x=gridw*baseWidth;
	y=0.0;

	glPushMatrix();
	glScalef(xscale,yscale*100.0/tickMax,zscale); 	

	glBegin(GL_LINES);
	step=currentMax/100.0;
	for (j=step;j<tickMax;j+=step) {
		[colorMap glMap: j];
		//glColor3f(1.0,1.0,1.0);
		glVertex3f(x,j-step,y);
		glVertex3f(x,j,y);
	}
	glEnd();
	
	glColor3f(fontColorR,fontColorG,fontColorB);
	glBegin(GL_QUADS);
	for (i=0;i<numTicks;i++) {
		glVertex3f(x-bsize,currentTicks[i],y-bsize);
		glVertex3f(x-bsize,currentTicks[i],y+bsize);
		glVertex3f(x+bsize,currentTicks[i],y+bsize);
		glVertex3f(x+bsize,currentTicks[i],y-bsize);	}
	glEnd();

	for (i=0;i<numTicks;i++)
		drawString3D(x+4.0/xscale,currentTicks[i],y,GLUT_BITMAP_HELVETICA_12,[dataSet getLabel: currentTicks[i]],1.0);

	glPopMatrix();
	return self;
}

-drawPlane {
	float dropit=-1.5;

	glColor3f(0.5,0.0,0.0);
	
	glPolygonOffset(dzmult,rmult);
	glPushMatrix();
	glScalef(xscale,yscale,zscale);
	glBegin(GL_QUADS);

	//glNormal3f(0.0, -1.0, 0.0);
	glVertex3f(0, dropit, 0 );
	glVertex3f(0, dropit, gridl*baseLength );
	glVertex3f(gridw*baseWidth, dropit, gridl*baseLength );
	glVertex3f(gridw*baseWidth, dropit, 0 );
	
	glEnd();

	glPopMatrix();
	return self;
}

-setFontScale:(float)scale {
	fontScale=scale;
	return self;
}
-(float)fontScale {
	return fontScale;
}

-description {
	return [[self class] description];
}

-(NSString*)getName {
	NSString *retval = [super getName];
	if(!name)
		retval = [dataSet description];
	return retval;
}


-(void)setBarType:(BarTypesEnum)code {
	if (code < B_COUNT)
		barType = code;
}

-(BarTypesEnum)getBarType {
	return barType; 
}


-drawSquares {
	int i,j,num,l;
	float val,sw,sl,mw,ml;
	GLText *txt;
	NSDictionary *meta;

	mw=(baseWidth-barWidth)/2.0;
	ml=(baseLength-barLength)/2.0;
	sw=barWidth;
	sl=barLength;

	glEnableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	glPushMatrix();	
	glScalef(xscale,yscale*100.0/tickMax,zscale);

	glVertexPointer(3, GL_FLOAT, 0, bar_quads);

	glPolygonOffset(0.0,0.2);
	num=0;
	for (i=0;i<gridw;i++) {
		for (j=0;j<gridl;j++) {
			glPushMatrix();	

			val = [dataSet dataRow: num][1];
			//NSLog(@"Draw: %f %f,%f",val,i*baseWidth,j*baseLength);
			[colorMap glMap:val];
			//glColor3f(1.0,1.0,1.0);
			glTranslatef(i*baseWidth+mw,0.0,j*baseLength+ml);
			glScalef(sw,val,sl);
			glDrawArrays(GL_QUADS,0,20);
			
			meta = [dataSet columnMeta: num];
			if (meta != nil) {
				NSNumber *high = [meta objectForKey: @"highlight"];
				if ([high intValue]==1) {
					glColor3f(highlightColorR,highlightColorG,highlightColorB);
					glDrawArrays(GL_QUADS,0,4);
				}
			}

			glColor3f(0.0,0.0,0.0);
			for (l=0;l<12;l+=4)
				glDrawArrays(GL_LINE_LOOP,l,4);
			glPopMatrix();
			
			glPushMatrix();	
			glTranslatef(i*baseWidth+mw*1.25,val+0.1,(j)*baseLength+ml+barLength/2);
			txt = [barText objectAtIndex: num];
			[txt setString: [dataSet columnTick:num]];
			[txt bestFitForWidth: barWidth andHeight: barLength];
			[txt glDraw];

			glPopMatrix();
			num++;
			if ( num>=[dataSet width]) {
				i=gridw; //get out
				j=gridl;
			}
		}
	}

	glPopMatrix();
	return self;
}
@end
