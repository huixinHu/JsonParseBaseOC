//
//  JsonReader.h
//  JsonParse
//
//  Created by cc on 2018/4/26.
//  Copyright © 2018年 cc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JsonReader : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithString:(NSString *)jsonString;

- (id)parse;
@end
