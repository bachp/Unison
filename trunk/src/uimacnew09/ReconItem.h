/* ReconItem */

#import <Cocoa/Cocoa.h>

@class OCamlValue;

@interface ReconItem : NSObject
{
	ReconItem *parent;
    NSString *path;
    NSString *fullPath;
    BOOL selected;
    NSImage *direction;
    NSString *directionSortString;
    double fileSize;
    double bytesTransferred;
    BOOL resolved;
}
- (BOOL)selected;
- (void)setSelected:(BOOL)x;
- (NSString *)path;
- (NSString *)fullPath;
- (NSString *)left;
- (NSString *)right;
- (NSImage *)direction;
- (NSImage *)fileIcon;
- (long)fileCount;
- (double)fileSize;
- (NSString *)fileSizeString;
- (double)bytesTransferred;
- (NSString *)bytesTransferredString;
- (void)setDirection:(char *)d;
- (void) doAction:(unichar)action;
- (void) doIgnore:(unichar)action;
- (NSString *)progress;
- (NSString *)progressString;
- (void)resetProgress;
- (NSString *)details;
- (NSString *)updateDetails;
- (BOOL)isConflict;
- (BOOL)changedFromDefault;
- (void)revertDirection;
- (BOOL)canDiff;
- (void)showDiffs;
- (NSString *)leftSortKey;
- (NSString *)rightSortKey;
- (NSString *)replicaSortKey:(NSString *)sortString;
- (NSString *)directionSortKey;
- (NSString *)progressSortKey;
- (NSString *)pathSortKey;
- (NSArray *)children;
- (ReconItem *)collapseParentsWithSingleChildren:(BOOL)isRoot;
- (ReconItem *)parent;
- (void)setPath:(NSString *)aPath;
- (void)setFullPath:(NSString *)p;
- (void)setParent:(ReconItem *)p;
- (void)willChange;
@end

@interface LeafReconItem : ReconItem
{
    NSString *left;
    NSString *right;
    NSString *progress;
    NSString *details;
    OCamlValue *ri; // an ocaml Common.reconItem
    long index; // index in Ri list
}
- initWithRiAndIndex:(OCamlValue *)v index:(long)i;
@end

@interface ParentReconItem : ReconItem
{
	NSMutableArray *_children;
	long fileCount;
}
- (void)addChild:(ReconItem *)item nested:(BOOL)useNesting;
- (void)sortUsingDescriptors:(NSArray *)sortDescriptors;
- (BOOL)hasConflictedChildren;
@end
