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
#import "cview.h"
#import "DataSet.h"
#import "DictionaryExtra.h"
#import "ValueStore.h"
#import "Defaults.h"

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


@implementation  GLChart
static NSArray *chartTypeStrings=nil;
static const char *chartTypeSelectors[] =	{
	"drawRowAvgLines",
	"drawColumnLines"
	"drawRowPoints"
	"drawColumnPoints"
};

+(void)initialize {
	chartTypeStrings = [NSArray arrayWithObjects: @"Lines",@"Points",nil];
	return;
}
-init {
	[super init];
	// This lock protects the changing of the dataset.
	dataSetsLock = [[NSRecursiveLock alloc] init];
	dataSets = [[NSMutableArray arrayWithCapacity: 5] retain];
	fontScale = 1.0;
	fontColorR = 1.0;
	fontColorG = 1.0;
	fontColorB = 1.0;
	ticks=[Defaults integerForKey:@"ticks" Id:self];
	axisTicks=6;
	tickMax=1.0;
	currentTicks[0]=0.0;
	currentTicks[1]=1.0;
	numTicks=2;
	xbufpercent=15.0;
	ybufpercent=15.0;
	chartType=G_LINES;
	descText = [[GLText alloc] initWithString: @"Unset" andFont: @"LinLibertine_Re.ttf"];
	return self;
}

-initWidth: (int)width andHeight: (int)height andType: (ChartTypesEnum)type {
	[self init];
	[self setChartType:type];
	[self setHeight: height];
	[self setWidth: width];
	return self;
}

-initWidth: (int)width andHeight: (int)height {
	return [self initWidth: width andHeight: height andType: C_ROW_LINES];
}

-addDataSetKey: (NSString *)key {
	DataSet *ds = [[ValueStore valueStore] getObject: key];
	[dataSetsLock lock];
	[dataSets addObject: ds];
	NSLog(@"register notify for: %@ %@",self,ds);
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveResizeNotification:) name:@"DataSetResize" object:ds];
	[dataSetsLock unlock];
	if ([ds dataValid])
		[self resetDrawingArrays];
	
	return self;

}
-(void)receiveResizeNotification: (NSNotification *)notification {
	NSLog(@"GLChartResize notification: %@",notification);
	[self resetDrawingArrays];
}

-(void)resetDrawingArrays {
	float *d;
	int i,len;
	NSEnumerator *list;
  	DataSet *ds;

	[dataSetsLock lock];

	len=0;
  	list = [dataSets objectEnumerator];
  	ds = [list nextObject];
  
  	if (IS_ROW(chartType))
  		currentLen = [ds height];
  	else if (IS_COL(chartType)) 
  		currentLen = [ds width];

    while ((ds = [list nextObject])) {
  		//verify width is same
  		if (IS_ROW(chartType))
  			len = [ds height];
  		else if (IS_COL(chartType)) 
  			len = [ds width];
  		if (len != currentLen)
  			NSLog(@"Length is different in the datasets: %d != %d",len,currentLen);
  	}
	NSLog(@"Length of data is: %d ",currentLen);

	[colorRow autorelease];
	dataRow = [[NSMutableData alloc] initWithLength: 2*currentLen*sizeof(float)];
	NSLog(@"dataRow: %lu",2*currentLen*sizeof(float));
	colorRow = [[NSMutableData alloc] initWithLength: 4*currentLen*sizeof(float)];
	d = (float *)[dataRow mutableBytes];
	// setup drawable array... (xnum,unknown)
	for (i=0;i<currentLen;i++)
		d[i*2]=i;

	[dataSetsLock unlock];

	return;
}

-(NSArray *)getDataSetKeys {
	return [dataSets arrayObjectsFromPerformedSelector: @selector(valueStoreKey)];
}

-initWithPList: (id)list {
	id o;
	NSLog(@"initWithPList: %@",[self class]);
	NSArray *keys;
	[super initWithPList: list];
	/// @todo error checking or exception handling.
  ticks = [Defaults integerForKey: @"ticks" Id: self Override:list];
	fontScale = [Defaults floatForKey: @"fontScale" Id: self Override: list];
	fontColorR = [Defaults floatForKey: @"fontColorR" Id: self Override: list];
	fontColorG = [Defaults floatForKey: @"fontColorG" Id: self Override: list];
	fontColorB = [Defaults floatForKey: @"fontColorB" Id: self Override: list];
	chartType = [Defaults integerForKey: @"chartType" Id: self Override:list];
  chartHeight = [Defaults integerForKey: @"chartHeight" Id: self Override:list];
  chartWidth = [Defaults integerForKey: @"chartWidth" Id: self Override:list];
		
	o = [list objectForKey: @"gradient" missing: nil];
	if (o!=nil)
		ggr = [[GimpGradient alloc] initWithPList: o];

	keys = [list objectForKey: @"valueStoreDataSetKeys"];
	if (keys) {
		NSString *o;
		NSEnumerator *list;
		list = [keys objectEnumerator];
		while ( (o = [list nextObject]) ) {
			[self addDataSetKey: o];
		}
	}
	return self;
}


-getPList {
	NSLog(@"getPList: %@",self);
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: [super getPList]];
	PLIST_SET_IF_NOT_DEFAULT_INT(dict, ticks);
	PLIST_SET_IF_NOT_DEFAULT_FLT(dict, fontScale);
	PLIST_SET_IF_NOT_DEFAULT_FLT(dict, fontColorR);
	PLIST_SET_IF_NOT_DEFAULT_FLT(dict, fontColorG);
	PLIST_SET_IF_NOT_DEFAULT_FLT(dict, fontColorB);
  PLIST_SET_IF_NOT_DEFAULT_INT(dict, chartType);
  PLIST_SET_IF_NOT_DEFAULT_INT(dict, chartWidth);
  PLIST_SET_IF_NOT_DEFAULT_INT(dict, chartHeight);

	[dict setObject: [dataSets  arrayObjectsFromPerformedSelector: @selector(valueStoreKey)] forKey:@"valueStoreDataSetKeys"];
	if (ggr != nil)
		[dict setObject: [ggr getPList] forKey: @"gradient"];
	return dict;
}

-(NSArray *)attributeKeys {
	//isVisible comes from the DrawableObject
	return [NSArray arrayWithObjects: @"isVisible",@"ticks",@"fontScale",
					@"fontColorR",@"fontColorG",@"fontColorB",@"chartType",@"axisTicks",nil];
}

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

-(void)dealloc {
	NSLog(@"GLGrid dealloc");
	[dataSetsLock lock];
	[colorMap autorelease];
	//[dataRow autorelease];
	//[colorRow autorelease];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[dataSets autorelease];
	[dataSetsLock autorelease];
	[ggr autorelease];
	return [super dealloc];
}

/* This should be called with the dataSet Locked */
-resetColorMap {
	[colorMap autorelease];
	if (ggr == nil)
		colorMap = [ColorMap mapWithMax: tickMax];
	else
		colorMap = [ColorMap mapWithGradient: ggr andMax: tickMax];
	[colorMap retain];
	return self;
}

-glDraw {
	NSEnumerator *list;
  	DataSet *ds;
  	unsigned long max=1;

	[dataSetsLock lock];
	[dataSets makeObjectsPerformSelector:@selector(lock)];

  	list = [dataSets objectEnumerator];
  	ds = [list nextObject];
  	while ((ds = [list nextObject])) {
  		max = MAX(currentMax,[ds getMax]);
  	}
	
	if (currentMax != max || currentMax==0) {
		NSLog(@"New Max: %lu %lu",max,currentMax);
		currentMax = max;
		numTicks = niceticks(0,currentMax,currentTicks,axisTicks);
		tickMax = round(currentTicks[numTicks-1]);
		
		[self resetColorMap];
	}
	
	glScalef(1.0,1.0,1.0);

/*
	[dataSetsLock lock];
	if (currentHeight != [dataSet height] || currentWidth != [dataSet width]) {
		NSLog(@"WARNING: Size mismatch since last time - This should not happen if DataSet Notifications are working on resizes. Attempting to handle cleanly.");
		[self resetDrawingArrays];
	}
*/
	[self performSelector: sel_registerName(chartTypeSelectors[chartType]) ];
	[self drawAxis];
	//[self drawTitles];
	[dataSetsLock unlock];
	[dataSets makeObjectsPerformSelector: @selector(unlock)];
	return self;
}

-drawTitles {
	/*
	glPushMatrix();
	glScalef(1.0,1.0,zscale);
	glTranslatef(0.0,0,[dataSet height]+15+15*fontScale);
	glRotatef(90,1.0,0.0,0.0);

	glScalef(fontScale,fontScale,fontScale/zscale);

	[descText setColorRed: fontColorR Green: fontColorG Blue: fontColorB];
	[descText glDraw];

	glPopMatrix();
*/	return self;
}

-drawAxis {
	int i;
	float bsize=2.0;
	float j,step,x,y;
	DataSet *ds;

	ds = [dataSets objectAtIndex:0];
	x=xbufpercent;  ////  FIGUER out this!!!
	y=ybufpercent;

	glPushMatrix();
	glScalef(chartWidth/100.0,-chartHeight/100.0,1.0);
	glTranslatef(0.0,-100.0,0);

//debug
	glBegin(GL_LINE_LOOP);
	glColor3f(1.0,0.0,0.0);
	glVertex2f(0.0,0.0);
	glColor3f(1.0,1.0,1.0);
	glVertex2f(100.0,0.0);
	glColor3f(0.0,1.0,0.0);
	glVertex2f(100.0,100.0);
	glVertex2f(0.0,100.0);
	glEnd();
//enddebug

	glBegin(GL_LINES);
	step=currentMax/(100.0-ybufpercent);
	for (j=ybufpercent;j<=tickMax;j+=step) {
		[colorMap glMap: j];
		//glColor3f(1.0,1.0,1.0);
		glVertex2f(x,j-step);
		glVertex2f(x,j);
	}
	glEnd();

	glColor3f(fontColorR,fontColorG,fontColorB);
	glBegin(GL_LINES);
	for (i=0;i<numTicks;i++) {
		j=ybufpercent+(100-ybufpercent)*currentTicks[i]/tickMax;
		glVertex2f(x-bsize,j);
		glVertex2f(x,j);
	}
	glVertex2f(x,y);
	glVertex2f(100,y);
	glEnd();

	glColor3f(fontColorR,fontColorG,fontColorB);
	for (i=0;i<numTicks;i++) 
		drawString3D(0.0,ybufpercent+(100-ybufpercent)*currentTicks[i]/tickMax,0,GLUT_BITMAP_HELVETICA_12,[ds getLabel: currentTicks[i]],0.0);

  if (ticks) {
    int dropit=1;
    float delta;
    
    delta=(100-xbufpercent)/currentLen;
    glBegin(GL_LINES);
    for (i = 0;i < currentLen; i += ticks) {
      glVertex2f(xbufpercent+i*delta,ybufpercent);
      glVertex2f(xbufpercent+i*delta,ybufpercent-dropit);
    }
    glEnd();
    
    for (i = 0;i < currentLen; i += ticks) {
      NSString *str = @"...";
      if (IS_ROW(chartType))
        str = [ds rowTick: i];
      else if (IS_COL(chartType))
        str = [ds columnTick: i];
      
      glColor3f(fontColorR,fontColorG,fontColorB);
      drawString3D(xbufpercent+i*delta,ybufpercent - dropit - 2,0,GLUT_BITMAP_HELVETICA_12,str,0);
    }
    
  }
  
	glPopMatrix();

	return self;
}

-setTicks: (int) delta {
	ticks = delta;
	return self;
}
-(int)Ticks {
	return ticks;
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
	//if(!name)
	//	retval = [dataSet description];
	return retval;
}


-(void)setChartType:(ChartTypesEnum)code {
	if (code < C_COUNT)
		chartType = code;
	/**@todo actually switch drawing*/
	[self resetDrawingArrays];
}

-(ChartTypesEnum)getChartType {
	return chartType;
}


-setGradient: (GimpGradient *)gradient {
	[gradient retain];
	[ggr autorelease];
	ggr = gradient;
	//dont change while it may be in use.
	//[dataSet lock];
	//[self resetColorMap];
	//[dataSet unlock];
	return self;
}

-getGradient {
	return ggr;
}
-setWidth: (int) width {
	chartWidth=width;
	return self;
}
-setHeight: (int) height {
	chartHeight=height;
	return self;
}
-(int)width {
	return chartWidth;
}
-(int)height {
	return chartHeight;
}

-drawRowAvgLines {
  NSEnumerator *list;
  DataSet *ds;
  NSData *data;
  float *d;
  float *verts;
  int i;
  float numrows;
  
  verts = [dataRow mutableBytes];
  
  list = [dataSets objectEnumerator];
  while ((ds = [list nextObject])) {
    data = [ds rowTotals];
    numrows = [ds width];
    
    d = (float *)[data bytes];
    for (i=0;i<currentLen;i++)
      verts[i*2+1]=d[i]/numrows;
    NSLog(@"conv: %f => %f",d[0],verts[1]);
    [self drawLine: verts];
  }

  
	return self;
}
-drawLine: (float *)verts; {
	
  
	glEnableClientState(GL_VERTEX_ARRAY);
	//glEnableClientState(GL_COLOR_ARRAY);
	glPushMatrix();
	
  glScalef(chartWidth/100.0,-chartHeight/100.0,1.0);
  glTranslatef(xbufpercent,-(100.0-ybufpercent),0);
  glScalef((100.0-xbufpercent)/currentLen,(100.0-ybufpercent)/100.0,1.0);
  
  
  
	glVertexPointer(2, GL_FLOAT, 0, verts);
	//glColorPointer(4, GL_FLOAT, 0, [colorRow mutableBytes]);

  glColor3f(1.0,1.0,1.0);
  glDrawArrays(GL_LINE_STRIP,0,currentLen);

	glPopMatrix();
	return self;
}

-(void)regenerateIndicies {
		return;
}


-drawPoints {
/*	int i,j,w,h;
	float *dl;
	float *verts;
	verts = [dataRow mutableBytes];
	w=[dataSet width];
	h=[dataSet height];

	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
	glPushMatrix();
	glScalef(xscale,yscale*100.0/tickMax,zscale);

	glVertexPointer(3, GL_FLOAT, 0, verts);
	glColorPointer(4, GL_FLOAT, 0, [colorRow mutableBytes]);

	//Bigger points up close stuff
	glPointSize(150);
#if HAVE_OPENGL_1_4
	float glparm[3];

	glparm[0]=0;
	glPointParameterfv(GL_POINT_SIZE_MIN,glparm);
	glparm[0]=20.0;
	glPointParameterfv(GL_POINT_SIZE_MAX,glparm);
	glparm[0]=0.0;
	glparm[1]=-0.01;
	glparm[2]=0.025;
	glPointParameterfv(GL_POINT_DISTANCE_ATTENUATION, glparm);
#endif
	//end bigger stuff..

	for (i=0;i<w;i++) {
		dl=[dataSet dataRow: i];


		[colorMap doMapWithData: dl thatHasLength: h toColors: [colorRow mutableBytes]];
		//is there a gooder way? FIXME
		for (j=0;j<h;j++) {
			verts[j*3+1] = dl[j];
			verts[j*3+0] = (float)i;
		}
		glDrawArrays(GL_POINTS,0,h);
	}

	glPopMatrix();
*/
	return self;
}
@end
