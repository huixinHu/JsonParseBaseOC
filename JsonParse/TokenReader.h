//
//  TokenReader.h
//  JsonParse
//
//  Created by cc on 2018/4/26.
//  Copyright © 2018年 cc. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM (NSInteger, HXTokenType)   {
    HXTokenBeginObject = 0,      //{
    HXTokenEndObject = 1,        //}
    HXTokenBeginArray = 2,       //[
    HXTokenEndArray = 3,         //]
    HXTokenColon = 4,            //冒号
    HXTokenComma = 5,            //逗号
    HXTokenString = 6,           //string
    HXTokenBoolean = 7,          //true false
    HXTokenNull = 8,             //null
    HXTokenNumber = 9,           //number
    HXTokenEnd = 10              //已完成解析
};

@interface TokenReader : NSObject
- (instancetype)initWithJsonString:(NSString *)json;

- (HXTokenType)readNextToken;
- (NSString *)readString;
- (BOOL)readBoolean;
- (void)readNull;
- (double)readNumber;
@end
