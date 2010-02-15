#import <Foundation/Foundation.h>
#import <gl.h>
#import <glut.h>
#import "cview.h"
#import "DataSet.h"
#import "GLDataCenter.h"
#import "DataCenter/AisleOffsets.h"
#import "DataCenterLoader.h"
#import "DictionaryExtra.h"
void drawString3D(float x,float y,float z,void *font,NSString *string,float offset);
extern GLuint g_textureID;
@implementation  GLDataCenter
-init {
    [super init];
    self->csvFilePath = nil;
    self->jobIds = nil;
    self->jobIdIndex = 0;
    [self doInit];
    [Rack setGLTName: nil];
    [Node setGLTName: nil];
    return self;
}
-(NSString*) get_csvFilePath {
    return self->csvFilePath;
}
-doInit {
    self->aisles = [[NSMutableArray alloc] init];
    self->floorArray1 = [AisleOffsets getDataCenterFloorPart1];
    self->floorArray2 = [AisleOffsets getDataCenterFloorPart2];
    self->floorArray3 = [AisleOffsets getDataCenterFloorPart3];
    if(self->csvFilePath != nil) {
        DataCenterLoader *dcl = [[DataCenterLoader alloc] init];
        [dcl LoadGLDataCenter: self];
        [dcl autorelease];
    }
    return self;
}
-(Node*)findNodeObjectByName:(NSString*) _name {
    //NSLog(@"name = %@", _name);
    if(self->aisles == nil)
        return nil;
    NSEnumerator *enumerator = [self->aisles objectEnumerator];
    if(enumerator == nil)
        return nil;
    id element;
    Node *node;
    while((element = [enumerator nextObject]) != nil) {
        node = [element findNodeObjectByName: _name];
        if(node != nil)
            return node;
    }
    return nil;
}
-(NSArray*)getNodesRunningAJobID:(float) jobid {
    int i;
    float *dl;
    NSMutableArray *nodeArray = [[NSMutableArray alloc] init];
    for(i=0;i<[jobIds width];++i) {
        dl = [jobIds dataRow: i];
//        dl[0] should be all we care about here...
        if(jobid == dl[0]) {
            Node *node =  [self findNodeObjectByName: [jobIds columnTick: i]];
            if(node != nil)
                [nodeArray addObject: node];
            //NSLog(@"columtick: %@", [jobIds columnTick: i]);
        }

    }
    [nodeArray autorelease];//auto or regular, not really sure which to use....
    return nodeArray;
}
-doStuff {
    if(jobIds == nil) {
        NSLog(@"jobIds was nil!!!");
        return self;
    }
    float *dr = [jobIds dataRow: jobIdIndex];
    float job = dr[0];

    NSLog(@"(%d) Now displaying jobs from jobid : %f", jobIdIndex, job);
    [self fadeEverythingExceptJobID: job];
    while(job == [jobIds dataRow: jobIdIndex++][0])
        ;
    return self;
}
-(float)getJobIdFromNode:(Node*)n {
    if(n == nil)
        return 0;
    float *row = [jobIds dataRowByString: [n getName]];
    if(row != NULL)
        return row[0];
    //NSLog(@"row was NULL-node: %@", [[n getName] lowercaseString]);
    return 0;
}
-unfadeEverything {
    if(self->aisles == nil)
        return self;
//    [self->aisles makeObjectsPerformSelector: @selector(startUnFading)];
    return self;

}
-fadeEverythingExceptJobID:(float) jobid {
    if(self->aisles == nil)
        return self;
    // first fade everything
    [self->aisles makeObjectsPerformSelector: @selector(startFading)];

    NSArray *arr = [self getNodesRunningAJobID: jobid];
    if(arr == nil)
        return self;
    // then unfade the ones we want
    [arr makeObjectsPerformSelector: @selector(startUnFading)];
    return self;
}
-initWithPList: (id)list {
	NSLog(@"initWithPList: %@",[self class]);
	[super initWithPList: list];
	/// @todo error checking or exception handling.
	Class c;
	DataSet *ds;
	c = NSClassFromString([list objectForKey: @"dataSetClass"]);
	if (c && [c conformsToProtocol: @protocol(PList)] && [c isSubclassOfClass: [DataSet class]]) {
		ds=[c alloc];
		[ds initWithPList: [list objectForKey: @"dataSet"]];
        self->dataSet = ds;
	}
    self->csvFilePath = [[list objectForKey: @"csvFilePath"
            missing: @"data/Chinook Serial numbers.csv"] retain];
    NSLog(@"csvFilePath = %@", self->csvFilePath);
	c = NSClassFromString([list objectForKey: @"dataSetClass"]);
	if (c && [c conformsToProtocol: @protocol(PList)] && [c isSubclassOfClass: [DataSet class]]) {
		ds=[c alloc];
		[ds initWithPList: [list objectForKey: @"jobIDDataSet"]];
        jobIds = [ds retain];
	}
    [self doInit];
    [Node setWebDataSet: (WebDataSet*)self->dataSet];
    return self;
}
-getPList {
	NSLog(@"getPList: %@",self);
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: [super getPList]];
	[dict setObject: [dataSet getPList] forKey: @"dataSet"];
	[dict setObject: [jobIds getPList] forKey: @"jobIDDataSet"];
	[dict setObject: [dataSet class] forKey: @"dataSetClass"];
	return dict;
}
-(void)dealloc {
    [csvFilePath release];
    [super dealloc];
}
-drawOriginAxis {
    glPushMatrix();
    //glLoadIdentity();
    glBegin(GL_LINES);
    //glLineWidth(5.0); // this generates a GL_INVALID_OPERATION, comment out
    glColor3f(1.0,0,0);
    glVertex3f(-10000,0,0);
    glVertex3f(10000,0,0);
    glVertex3f(0,-100000,0);
    glVertex3f(0,10000,0);
    glVertex3f(0,0,-10000);
    glVertex3f(0,0,10000);
    glEnd();
   
    int x = 1000;
    glColor3f(0,0,1);
    drawString3D( x,0,0,GLUT_BITMAP_HELVETICA_12,@"  +X-Axis", 0);
    drawString3D(-x,0,0,GLUT_BITMAP_HELVETICA_12,@"  -X-Axis", 0);
    drawString3D(0, x,0,GLUT_BITMAP_HELVETICA_12,@"  +Y-Axis", 0);
    drawString3D(0,-x,0,GLUT_BITMAP_HELVETICA_12,@"  -Y-Axis", 0);
    drawString3D(0,0, x,GLUT_BITMAP_HELVETICA_12,@"  +Z-Axis", 0);
    drawString3D(0,0,-x,GLUT_BITMAP_HELVETICA_12,@"  -Z-Axis", 0);

    glPopMatrix();
    return self;
}
-drawGrid {
    glBegin(GL_LINES);
    glColor3f(0,0,0);
    int nx = -10, ny = 100;
    int i;
    for(i=nx;i<ny;++i) {
        glVertex3f(-nx*TILE_WIDTH,-1,i*TILE_WIDTH);
        glVertex3f(-ny*TILE_WIDTH,-1,i*TILE_WIDTH);
        glVertex3f(-i*TILE_WIDTH,-1,nx*TILE_WIDTH);
        glVertex3f(-i*TILE_WIDTH,-1,ny*TILE_WIDTH);
   }
    glEnd();
    return self;
}
-addAisle: (Aisle*) aisle {
    // Add the passed rack to our rackArray
    if(self->aisles != nil)
        [self->aisles addObject: aisle];
    return self;
}
-drawFloor {
    //TODO: add stuff here to draw floor tiles
    if(self->floorArray1 == NULL || self->floorArray2 == NULL || self->floorArray3 == NULL)
        return self;
    // No textures for now...
    glDisable(GL_TEXTURE_2D);
    glColor3f(0.5,0.5,0.5);  // grey
    // Draw the rack itself, consisting of 6 sides
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glInterleavedArrays(GL_T2F_V3F, 0, self->floorArray1->verts);
    glDrawArrays(GL_POLYGON, 0, self->floorArray1->vertCount);

    glInterleavedArrays(GL_T2F_V3F, 0, self->floorArray2->verts);
    glDrawArrays(GL_POLYGON, 0, self->floorArray2->vertCount);

    glInterleavedArrays(GL_T2F_V3F, 0, self->floorArray3->verts);
    glDrawArrays(GL_POLYGON, 0, self->floorArray3->vertCount);

    //glCullFace(GL_FRONT);

    return self;
}
-draw {
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,  GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,  GL_NEAREST);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
    //[self drawOriginAxis];
    [self drawFloor];
    //[self drawGrid];
    [self->aisles makeObjectsPerformSelector:@selector(draw)]; // draw the nodes
    //NSLog(@"count: %d", [aisles count]);

    GLenum err = glGetError();
    if(err != GL_NO_ERROR)
        NSLog(@"There was a glError, error number: %x", err);
    return self;
}
-glPickDraw {
    [aisles makeObjectsPerformSelector:@selector(glPickDraw)];
    return self;
}
-glDraw {
    [self draw];
    return self;
/*
    float max = [dataSet getScaledMax];
	
	if (currentMax != max) {
		NSLog(@"New Max: %.2f %.2f",max,currentMax);
		currentMax = max;
		[colorMap autorelease];
		colorMap = [ColorMap mapWithMax: currentMax];
		[colorMap retain];
	}
	glScalef(1.0,1.0,1.0); 
    [self draw];
    //[self drawFloor];
	//[self drawPlane];
	//[self drawData];
	[self drawAxis];
	//[self drawTitles];
    return self;*/
}
-(NSEnumerator*) getEnumerator {
    NSEnumerator *enumerator = [self->aisles objectEnumerator];
    return enumerator;
}

@end