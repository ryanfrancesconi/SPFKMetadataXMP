// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/SPFKMetadataXMP

#ifndef XMPWrapper_h
#define XMPWrapper_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XMPWrapper : NSObject

+ (nullable NSString *)parse:(NSString *)path;

+ (void)write:(nonnull NSString *)xmlString
       toPath:(nonnull NSString *)toPath;

@end

NS_ASSUME_NONNULL_END

#endif /* XMPWrapper_h */
