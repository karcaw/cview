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
#include <time.h>
#import <Foundation/Foundation.h>
#import "cview.h"
#include "Wand.h"
#import "DictionaryExtra.h"
#import "config.h"

@implementation GLWorld 
-init {
	displayList = -1;
	imagePrefix=[NSMutableString stringWithString: @"glworld"];
	imageDir=[NSMutableString stringWithString: @"."];
	imageDailyDir = NO;
	imageCycleTime = 0;
	lastImageTime = 0;
	overlay=nil;

	NSLog(@"%@",[self attributeKeys]);
	//[NSClassDescription registerClassDescription: self forClass: [self class]];
	//NSLog(@"%@",[NSClassDescription classDescriptionForClass: [self class]]);
	
	return self;
}


-initWithPList: (id)list {
	NSLog(@"initWithPList: %@",[self class]);
	[self init];
	///\todo error checking or exception handling.
	scene = [[[Scene alloc] initWithPList: [list objectForKey: @"scene"]] retain];
	eye = [[[Eye alloc] initWithPList: [list objectForKey: @"eye"]] retain];
	id ov = [list objectForKey: @"overlay" missing: nil];
	
	if (ov != nil) {
		overlay=[[[Scene alloc] initWithPList: ov] retain];
	}

	imagePrefix = [[NSMutableString stringWithString:[list objectForKey: @"imagePrefix" missing: @"glworld"]] retain];
	imageDir = [[NSMutableString stringWithString: [list objectForKey: @"imageDir" missing: @"."]] retain];
	imageDailyDir = [[list objectForKey: @"imageDailyDir" missing: @"NO"] boolValue];
	imageCycleTime = [[list objectForKey: @"imageCycleTime" missing: @"0"] intValue];

	return self;
}
 
-getPList {
	NSLog(@"getPList: %@",self);
	NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
		[scene getPList],@"scene",
		[eye getPList],@"eye",
		nil];
	
	if (overlay != nil) {
		[plist setObject: [overlay getPList] forKey: @"overlay"];
	}

	[plist setObject: imagePrefix forKey: @"imagePrefix"];
	[plist setObject: imageDir forKey: @"imageDir"];
	[plist setObject: [NSNumber numberWithBool: imageDailyDir] forKey: @"imageDailyDir"];
	[plist setObject: [NSNumber numberWithInt: imageCycleTime] forKey: @"imageCycleTime"];

	return plist;
}

-(NSArray *)attributeKeys {
	//return [NSArray arrayWithObjects: @"eye",@"scene",@"imageDir",@"imagePrefix",@"imageDailyDir",@"imageCycleTime",@"overlay",nil];
	return [NSArray arrayWithObjects: @"eye",@"scene",@"overlay",nil];
}

-(NSDictionary *)tweaksettings {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		@"help='Create Daily Directories for images' min=0 max=1",@"imageDailyDir",
		@"help='Time Interval to Dump Images,0=never dump' min=0 max=86400",@"imageCycleTime",
		@"help='Strafe Speed' label='Strafe Speed' min=0.01 max=200",@"ss",
		@"help='Move Speed' label='Move Speed' min=0.01 max=200",@"sd",
		@"help='Turn Speed in radians' label='Turn Speed' min=0.01 max=6.28 step=0.002 precision=3",@"ts",
		nil];
}

-(void)dealloc {
	NSLog(@"%@ dealloc",[self class]);
	[imagePrefix autorelease];
	[imageDir autorelease];
	[scene autorelease];
	[eye autorelease];
	[overlay autorelease];
	[super dealloc];
	return;
}

-glDraw {
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glLoadIdentity();

	glPushMatrix();
	[eye lookAt];

	if (scene && [scene visible])
		[scene glDraw];
	
	glPopMatrix();
	if (overlay) {
		[self gl2DProlog];
		[overlay glDraw];
		[self gl2DEpilog];
	}

	[self doDumpImage];

	return self;
}

-gl2DProlog {
	int width = glutGet(GLUT_WINDOW_WIDTH);
	int height = glutGet(GLUT_WINDOW_HEIGHT);

//	NSLog(@"Prolog: %dx%d",width,height);
	
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity();
	gluOrtho2D(0, width, 0, height);
	glScalef(1.0, -1.0, 1.0);
	glTranslatef(0.0, -height, 0.0);
	glMatrixMode(GL_MODELVIEW);
	glEnable(GL_BLEND);
	return self;
}

-gl2DEpilog {
	glDisable(GL_BLEND);
	glMatrixMode(GL_PROJECTION);
	glPopMatrix();
	glMatrixMode(GL_MODELVIEW);
	return self;
}

-setScene: ( Scene * ) s {
	[s retain];
	[scene autorelease];
	scene = s;
	return self;
}

-scene {
	return scene;
}

-setOverlay: ( Scene * ) o {
	[o retain];
	[overlay autorelease];
	overlay=o;
	return self;
}

-overlay {
	return overlay;
}

-setEye: ( Eye * ) e {
	[e retain];
	[eye autorelease];
	eye = e;
	return self;
}

-eye {
	return eye;
}

-doDumpImage {
	time_t now = time(NULL);

	if (imageCycleTime > 0 && now-lastImageTime > imageCycleTime) {
		lastImageTime = now;
		[self dumpImage: imagePrefix withBaseDir: imageDir dailySubDirs: imageDailyDir];
	}
	return self;
}

-dumpImage: (NSString *)prefix withBaseDir: (NSString *)dir dailySubDirs:(BOOL)dailies {
	NSString *extra = @"";
	NSString *suffix;
	NSFileManager *fm = [NSFileManager defaultManager];
	NSDate *date = [NSDate date];
 
	if (dailies) {
		BOOL isdir;
		NSString *datestamp = [date descriptionWithCalendarFormat: @"%Y-%m-%d"
			timeZone: [NSTimeZone defaultTimeZone] locale: nil];
		suffix =[date descriptionWithCalendarFormat: @"%H:%M:%S"
			timeZone: [NSTimeZone defaultTimeZone] locale: nil];
		NSString *dailypath = [NSString stringWithFormat: @"%@/%@",dir, datestamp];
		if ([fm fileExistsAtPath: dailypath isDirectory: &isdir]) {
			if (isdir) {
				extra=datestamp;
			}
			else {
				NSLog(@"File Exists where I wanted to make a directory: %@",dailypath);
				return nil;
			}
		}
		else {
			if ([fm createDirectoryAtPath: dailypath attributes: nil]) {
				extra=datestamp;
			}
			else {
				NSLog(@"Error trying to make a directory: %@",dailypath);
				return nil;
			}
		}
	}
	else {
		suffix =[date descriptionWithCalendarFormat: @"%Y-%m-%d-%H:%M:%S"
			timeZone: [NSTimeZone defaultTimeZone] locale: nil];
	}

	NSString *thepath = [NSString stringWithFormat: @"%@/%@/%@%@.png", dir, extra, prefix, suffix];
	NSLog(@"Path:%@",thepath);
	[self dumpImage:thepath];

	return self;
}

//Assume we are in the proper GL context
-dumpImage: (NSString *)filename {
	int width = glutGet(GLUT_WINDOW_WIDTH);
	int height = glutGet(GLUT_WINDOW_HEIGHT);
	NSMutableData *pixels = [NSMutableData dataWithCapacity: width*height*4];

	MagickWand *wand = NewMagickWand();
	MagickSetType(wand,TrueColorType);
	MagickSetSize(wand,width,height);

	glReadPixels(0,0,width,height,GL_RGBA,GL_UNSIGNED_BYTE,[pixels mutableBytes]);
	MagickConstituteImage(wand,width,height,"RGBA",CharPixel,[pixels mutableBytes]);

	MagickFlipImage(wand);
	MagickWriteImage(wand,[filename UTF8String]);

	DestroyMagickWand(wand);
	return self;
}

@end