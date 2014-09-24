#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#import "NetPBMImageDocument.h"

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    NetPBMImageDocument * document = [NetPBMImageDocument new];

    if (![document readFromURL:(__bridge NSURL *)url ofType:(__bridge NSString *)contentTypeUTI error:nil]) {
        return noErr;
    }

    NSSize previewSize = document.image.size;

    CGContextRef cgContext = QLPreviewRequestCreateContext(preview, *(CGSize *)&previewSize, false, NULL);
    if(cgContext) {
        NSGraphicsContext* context = [NSGraphicsContext graphicsContextWithGraphicsPort:(void *)cgContext flipped:YES];
        if(context) {
            [NSGraphicsContext setCurrentContext:context];
            [document.image drawInRect:NSMakeRect(0.0, 0.0, previewSize.width, previewSize.height)
                              fromRect:NSZeroRect
                             operation:NSCompositeSourceOver
                              fraction:1.0];
        }
        QLPreviewRequestFlushContext(preview, cgContext);
        CFRelease(cgContext);
    }

    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
