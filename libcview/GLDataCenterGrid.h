/**
	Draw a 3 dimensional view of the data center showing each rack
    in it's corresponding location

	@author Brock Erwin
	@ingroup cview3d
*/
#import "GLGrid.h"
#import "DataCenter/Drawable.h"
#import "Foundation/NSEnumerator.h"
#import "DataCenter/Isle.h"
#import "DataCenter/Point.h"
@interface GLDataCenterGrid: GLGrid <Drawable> {
    DrawableArray *isles;
@private
    WebDataSet *jobIds;
    VertArray *floorArray1;
    VertArray *floorArray2;
    VertArray *floorArray3;
    NSString *csvFilePath;
    int jobIdIndex;
}
-(NSString*) get_csvFilePath;
-init;
-doInit;
-(DrawableArray*)getNodesRunningAJobID:(float) jobid;
/// Makes all nodes fade except for nodes with the passed jobid
-fadeEverythingExceptJobID:(float) jobid;
-doStuff;
-draw;
/// Draws the floor tiles
-drawFloor;
-(NSEnumerator*)getEnumerator;
-addIsle: (Isle*) isle;
@end
