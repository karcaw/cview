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
#import "DataSet.h"
#import "UpdateThread.h"
#import "PList.h"

/**
Extension of the data class to retrieve the data from command attached to a pipe. 

The Data stream Should consist of a delimeter separated set of lines with data in them.

The command is specified with a path tot he command, and an array of arguments

A depth is also needed for how much data should be kept. defautl is 128 data lines

The data is formatted with no column headers, but each line should be proceded by a row id.

Sample output:
@verbatim
13:26:06     35    100    100    100 
13:26:07     35    100    100    100 
13:26:08     33    100    100    100 
13:26:09     36    100    100    100 
13:26:10     32    100    100    100 
13:26:11     35    100    100    100 
13:26:12     34    100    100    100 
13:26:13     34    100    100    100 
13:26:14     34    100    100    100 
@endverbatim
Which came from: colmux -address "cu4n1 cu4n2 cu4n3 cu4n4" -command "-sc -P -i 30" -column 2 -time

@author Evan Felix
@ingroup cviewdata
*/
#define DEFAULT_DEPTH 128

@interface StreamDataSet: DataSet <PList> {
	int columnCount;
	NSString *command;
	NSArray *arguments;
	NSTask *theTask;
	NSFileHandle *theFile;
	NSPipe *thePipe;
	NSMutableData *remainingData;
	NSMutableArray *Yticks;
	BOOL running;
}
-initWithCommand: (NSString *)cmd arguments: (NSArray *)args;
-initWithCommand: (NSString *)cmd arguments: (NSArray *)args depth: (int)d;
-addRow: (NSArray *)arr;
-(NSArray *)getNextLineArray;
-(NSData *)getNextLine;
/** thread run */
-(void)run:(id)args;
@end
