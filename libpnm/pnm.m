//
//  pnm.m
//  pnm-quicklook
//
//  Created by Omar Evans on 9/22/14.
//  Copyright (c) 2014 Omar Evans. All rights reserved.
//

#import "pnm.h"

typedef NS_ENUM(NSInteger, PNM_Encoding) {
    ASCII,
    Binary
};

typedef NS_ENUM(NSInteger, PNM_Format) {
    PBM,
    PGM,
    PPM,
    PAM
};

typedef struct _pnm_info {
    PNM_Encoding encoding;
    PNM_Format format;

    unsigned int width;
    unsigned int height;
    unsigned int maxSampleValue;
    unsigned int bitsPerSample;
    unsigned int samplesPerPixel;

    bool hasAlpha;
    bool isPlanar;
} pnm_info;

static NSBitmapImageRep * load_pnm_bitmap_data(NSData * data);
static bool read_int_value(unsigned int *value, const char **readPtr, const char *endPtr);
static bool read_bitmap_data_8bit(unsigned char *bitmapData, pnm_info info, const unsigned char **readPtr, const unsigned char *endPtr);

NSImage * load_pnm_image(NSData *data) {
    NSImage * image = [NSImage new];
    NSBitmapImageRep * bitmapRepresentation = load_pnm_bitmap_data(data);

    if (image) {
        [image addRepresentation:bitmapRepresentation];
        image.size = NSMakeSize(bitmapRepresentation.pixelsWide, bitmapRepresentation.pixelsHigh);
    }

    return image;
}

static NSBitmapImageRep * load_pnm_bitmap_data(NSData * data) {
    if (data.length <= 2) {
        return nil;
    }

    const char * readPtr = data.bytes;
    const char * endPtr = readPtr + data.length;

    pnm_info info;
    memset(&info, 0, sizeof(info));

    NSString * colorSpaceName;

    if (*(readPtr++) != 'P') {
        return nil;
    }

    switch (*(readPtr++)) {
        case '1':
            info.encoding = ASCII;
            info.format = PBM;
            break;
        case '2':
            info.encoding = ASCII;
            info.format = PGM;
            break;
        case '3':
            info.encoding = ASCII;
            info.format = PPM;
            break;
        case '4':
            info.encoding = Binary;
            info.format = PBM;
            break;
        case '5':
            info.encoding = Binary;
            info.format = PGM;
            break;
        case '6':
            info.encoding = Binary;
            info.format = PPM;
            break;
        case '7':
            info.encoding = Binary;
            info.format = PAM;
            break;
        default:
            return nil;
    }

    if (!read_int_value(&info.width, &readPtr, endPtr)) {
        return nil;
    }

    if (!read_int_value(&info.height, &readPtr, endPtr)) {
        return nil;
    }

    if (info.format == PBM) {
        info.maxSampleValue = 1;
    } else if (!read_int_value(&info.maxSampleValue, &readPtr, endPtr)) {
        return nil;
    }

    if (info.maxSampleValue <= 255) {
        info.bitsPerSample = 8;
    } else {
        info.bitsPerSample = 16;
    }

    if (info.format == PBM || info.format == PGM) {
        info.samplesPerPixel = 1;
        colorSpaceName = NSCalibratedWhiteColorSpace;
    } else if (info.format == PPM) {
        info.samplesPerPixel = 3;
        colorSpaceName = NSCalibratedRGBColorSpace;
    }

    info.isPlanar = info.format == PAM;

    NSBitmapImageRep * bitMapRep = [[NSBitmapImageRep alloc]
                                    initWithBitmapDataPlanes:NULL
                                    pixelsWide:info.width
                                    pixelsHigh:info.height
                                    bitsPerSample:info.bitsPerSample
                                    samplesPerPixel:info.samplesPerPixel
                                    hasAlpha:info.hasAlpha
                                    isPlanar:info.isPlanar
                                    colorSpaceName:colorSpaceName
                                    bytesPerRow:0
                                    bitsPerPixel:0];

    unsigned char * bitmapData = bitMapRep.bitmapData;

    if (info.bitsPerSample == 8 && info.encoding == Binary) {
        if (read_bitmap_data_8bit(bitmapData, info, (const unsigned char **)&readPtr, (const unsigned char *)endPtr)) {
            return bitMapRep;
        } else {
            return nil;
        }
    } else {
        return nil;
    }
}

static bool read_bitmap_data_8bit(unsigned char *bitmapData, pnm_info info, const unsigned char **readPtr, const unsigned char *endPtr) {

    int i = 0;
    while (*readPtr != endPtr && i < info.width * info.height * info.samplesPerPixel) {
        *bitmapData = **(unsigned char **)readPtr / (double)info.maxSampleValue * 255;

        ++(*readPtr);
        ++bitmapData;
        ++i;
    }

    return i == info.width * info.height * info.samplesPerPixel;
}

static bool read_int_value(unsigned int *value, const char **readPtr, const char *endPtr) {
    bool readValue = false;
    bool readingComment = false;
    bool readingNumber = false;

    *value = 0;

    while (*readPtr != endPtr && (!readValue || readingComment)) {
        if (readingComment && **readPtr == '\n') {
            readingComment = false;
        } else if (!readingComment) {
            if (isspace(**readPtr)) {
                if (readingNumber) {
                    readingNumber = false;
                    readValue = true;
                }
            } else if (isdigit(**readPtr)) {
                *value = *value * 10 + (**readPtr - '0');
                readingNumber = true;
            } else if (**readPtr == '#') {
                readingComment = true;
            } else {
                return false;
            }
        }

        ++(*readPtr);
    }

    return readValue;
}