//
//  Document.h
//  PNM Viewer
//
//  Created by Omar Evans on 9/23/14.
//  Copyright (c) 2014 Omar Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NetPBMImageDocument : NSDocument

@property NSImage *image;
@property IBOutlet NSImageView *imageView;

@end
