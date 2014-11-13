/*

This file is part of the CVIEW graphics system, which is goverened by the following License

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
/** 
This class implements the gl drawing code to show a graph of lines above a lower base plane, with X and Y labels, with a z-axix tower showing the height of the data.  The data is provided by a DataSet class.  The coloring of the lines is provided by a self-created ColorMap class.

The class can display 4 types of Grid: Lines, Surfaces, Ribbons and Points.
@author Evan Felix <evan.felix@pnl.gov>, (C) 2008
@ingroup cview3d
*/
#import <Foundation/Foundation.h>
#import "DataSet.h"
#import "ColorMap.h"
#import "DrawableObject.h"
#import "GLText.h"
#import "GimpGradient.h"
#define MAX_TICKS 10

/* dont use an enum here as we want to use certain bits, to define flags inside the numbers 
 Byte - meaning
  1   - Row(0) or column(1)
  2   - Drawing type
*/
typedef unsigned int ChartTypesEnum;
#define C_ROW_LINES  0x00
#define C_COL_LINES  0x01
#define C_ROW_POINTS 0x10
#define C_COL_POINTS 0x11
#define C_COUNT 4
#define IS_LINES(x)  (((x)&0xF0)==0x00)
#define IS_POINTS(x) (((x)&0xF0)==0x10)
#define IS_ROW(x)    (((x)&0x0F)==0x00)
#define IS_COL(x)    (((x)&0x0F)==0x01)

#define C_LINES_STRING @"0"

@interface GLChart: DrawableObject {
	NSMutableArray *dataSets;
	ColorMap *colorMap;
	int ticks;
	int axisTicks;
	double currentTicks[MAX_TICKS];
	int numTicks;
	unsigned long tickMax;
	int currentLen;
	int chartWidth,chartHeight;
	unsigned long currentMax;
	NSMutableData *dataRow;
	NSMutableData *colorRow;
	GLText *descText;
	float fontScale;
	float fontColorR;
	float fontColorG;
	float fontColorB;
	/**a gradient for the color map, a nil value means use the default map.*/
	GimpGradient *ggr;
	ChartTypesEnum chartType;
	/** protect the dataSet member from being changed while we are reading it */
	NSRecursiveLock *dataSetsLock;
	float xbufpercent,ybufpercent;
}
-init;
/** Create GLGrid with a dataset retrieved from the ValueStore, and a given drawing method*/
-initWidth: (int)width andHeight: (int)height andType: (ChartTypesEnum)type;
/** Create GLGrid with a dataset retrieved from the ValueStore */
-initWidth: (int)width andHeight: (int)height;

/** change the dataSet displayed */
-addDataSetKey: (NSString *)key;
-(void)receiveResizeNotification: (NSNotification *)notification;
-(void)resetDrawingArrays;
/** get the current dataset keys */
-(NSArray *)getDataSetKeys;
-setWidth: (int) width;
-setHeight: (int) height;
-(int)width;
-(int)height;
-glDraw;
/** draw the overall grid description text */
-drawTitles;
/** draw the z axis tower with appropriate ticks */
-drawAxis;
/** set the delta between each tick drawing on the X axis*/
-setTicks: (int) delta;
-(int)Ticks;
/** set the scaling of the descriptive text */
-setFontScale:(float)scale;
-(float)fontScale;
/**Set the current type of grid to display*/
-(void)setChartType:(ChartTypesEnum)code;
/**Returns the current Type of Grid being Displayed*/
-(ChartTypesEnum)getChartType;
-drawRowAvgLines;
/** draw the data lines*/
-drawLine: (float *)verts;
/** set the Gradient for color mapping */
-setGradient: (GimpGradient *)gradient;
/** retrieve the current gradient */
-getGradient;
@end
