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
#import "ObjectTracker.h"
#import "Wand.h"
#import "WebDataSet.h"
#import "debug.h"
#import "PList.h"
#import "cview.h"
#import "CViewScreenDelegate.h"
//#define CLS_DUMP NSClassFromString(@"GSCBufferString")

@interface MainKeyHandler : NSObject {
	id root;
	NSString *pfile;
}
-initWithRoot: (id)r andPFile: (NSString *)pf;
-keyPress: (NSNotification *)notification;
@end

@implementation MainKeyHandler
-initWithRoot: (id)r andPFile: (NSString *)pf{
	root=[r retain];//FIXME check if plist?
	pfile=[pf retain];
	return self;
}
-(void)dealloc {
	[root autorelease];
	[pfile autorelease];
	return [super dealloc];
}

-keyPress: (NSNotification *)notification {
	NSString *err;
	NSLog(@"Toggle: %@",notification);
	if ([[notification name] compare: @"keyPress"]==NSOrderedSame) {
		unsigned char c = [[[notification userInfo] objectForKey: @"key"] unsignedCharValue];
		switch (c) {
			case '~':
				NSLog(@"!key: %c",c);
				id plist = [root getPList];
				
				NSData *nsd = [NSPropertyListSerialization dataFromPropertyList: (NSDictionary *)plist
					format: NSPropertyListOpenStepFormat errorDescription: &err];
				[nsd writeToFile: pfile atomically: YES];
				break;
#ifdef CLS_DUMP
			case '!':
				a=GSDebugAllocationListRecordedObjects(CLS_DUMP);
				i = [a objectEnumerator];
				
				while ((o = [i nextObject])) {
					NSLog(@"%d:%@",[o retainCount],[o description]);
				}
				break;
#endif
			default:
				NSLog(@"key: %c",c);
				break;
		}
	}
	return self;
}
@end
/**@file cview.m
	@ingroup cviewapp
*/

int main(int argc,char *argv[], char *env[]) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	ENABLEDEBUGALLOC;

#ifdef CLS_DUMP
	GSDebugAllocationActiveRecordingObjects(CLS_DUMP);
#endif

	float updateInterval;
	int dumpclasses;
	
	NSString *config;
	NSString *err;

#ifndef __APPLE__
	//needed for NSLog
	[NSProcessInfo initializeWithArguments: argv count: argc environment: env ];
#endif
	/** @objcdef 
		- dataUpdateInterval - time in seconds that the URL reload code will delay between reads
		- dumpclasses - startup a ObjectTracker thread if >0, the number how often in seconds to dump the class counts: file is cview.classes
		- c The PList formatted config file to load 
	*/
	NSUserDefaults *args = [NSUserDefaults standardUserDefaults];
	[args registerDefaults: [NSDictionary dictionaryWithObjectsAndKeys:
			@"chinook.cview", @"c",
			@"30.0",@"dataUpdateInterval",
			@"0",@"dumpclasses",
			nil]];

	config = [args stringForKey: @"c"];
	updateInterval = [args floatForKey: @"dataUpdateInterval"];
	dumpclasses = [args integerForKey: @"dumpclasses"];

	if (dumpclasses > 0) 
		[[[ObjectTracker alloc] initWithFile: @"cview.classes" andInterval: dumpclasses] retain];
	
	MagickWandGenesis();

	NSData *file = [NSData dataWithContentsOfFile: config];
	NSPropertyListFormat fmt;
	id plist = [NSPropertyListSerialization propertyListFromData: file 
				mutabilityOption: NSPropertyListImmutable 
				format: &fmt
				errorDescription: &err
				];
	//NSLog(@"plist: %@ %d %@",plist,fmt,err);
	if (plist==nil) {
		printf("Error loading PList: %s. Exiting\n",[config UTF8String]);
		exit(4);
	}

	GLScreen * g = [[GLScreen alloc] initWithPList:plist];
	CViewScreenDelegate *cvsd = [[CViewScreenDelegate alloc] initWithScreen:g];
	[g setDelegate: cvsd];

	//FIXME get rid of this soon, put it in delegate
	MainKeyHandler *mkh = [[MainKeyHandler alloc] initWithRoot: g andPFile: config];
	[[NSNotificationCenter defaultCenter] addObserver: mkh selector: @selector(keyPress:) name: @"keyPress" object: nil];
	NSLog(@"Setup done");

	plist = [g getPList];
	//NSLog([NSPropertyListSerialization stringFromPropertyList: plist]);
	

	DUMPALLOCLIST(YES);

	[g run];

	MagickWandTerminus();

	[g autorelease];
	[mkh autorelease];
	[pool release];

	return 0;
}