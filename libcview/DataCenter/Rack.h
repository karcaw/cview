#ifndef RACK_H
#define RACK_H
#import "Locatable.h"
#import "Drawable.h"
#import "DrawableArray.h"
#import "Node.h"
#import "Point.h"
#import "../GLText.h"

/**
  * interface Rack
  * 
  */

@interface Rack : Locatable <Drawable> {
    DrawableArray *nodes;
@private
    BOOL vertsSetUp;
    BOOL wireframe;     // if yes draw the racks as wireframe
    BOOL drawname;
    //int vertCount;
    //Vertex* rackVerts;
    float r,g,b; // color stuff...
    int face; // degress in which the rack is facing
}
//+(VertArray*) rackArray;
+(void) setRackArray: (VertArray*) _rackArray;
+(unsigned int) texture;
+setTexture:(unsigned int)_texture;
+setGLTName:(GLText*) _gltName;
-initWithName:(NSString*)_name;
-draw;
-addNode: (Node*) node;
-setFace: (int) _face;
@end

#endif // RACK_H
