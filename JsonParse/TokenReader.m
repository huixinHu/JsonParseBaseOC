//
//  TokenReader.m
//  JsonParse
//
//  Created by cc on 2018/4/26.
//  Copyright © 2018年 cc. All rights reserved.
//

#import "TokenReader.h"
typedef NS_ENUM (NSInteger, HXReadNumberStatus)   {
    HXNumberIntPart = 1,
    HXNumberFracPart = 2,
    HXNumberExpPart = 3,
    HXNumberFinish = 4,
};

@interface TokenReader()
@property (nonatomic, copy) NSString *buffer;
@end

@implementation TokenReader
{
    int pos;//当前位置
    NSInteger size;
}

- (instancetype)initWithJsonString:(NSString *)json {
    if (self = [super init]) {
        self.buffer = json;
        pos = 0;
        size = json.length;
    }
    return self;
}

- (BOOL)isReadToEnd {
    return !(pos < size);
}

//获取当前字符，pos向后移一位
- (char)readCurrentCharaAndMove {
    NSAssert(pos < size, @"访问越界");
    char c = [self.buffer characterAtIndex:pos];
    pos++;
    return c;
}

//获取当前字符，pos不移动
- (char)readCurrentChar {
    NSAssert(pos < size, @"访问越界");
    return [self.buffer characterAtIndex:pos];
}

- (void)moveToNext {
    pos++;
}

//读取下个token
- (HXTokenType)readNextToken {
    //Whitespace can be inserted between any pair of tokens.
    char c = ' ';
    //剔除空格
    while (1) {
        if ([self isReadToEnd]) return HXTokenEnd;
        c = [self readCurrentChar];
        if (c == ' ' || c == '\t' || c == '\r' || c == '\n') [self readCurrentCharaAndMove];
        else break;
    }

    switch (c) {
        case '{':
            [self readCurrentCharaAndMove];
            return HXTokenBeginObject;
        case '}':
            [self readCurrentCharaAndMove];
            return HXTokenEndObject;
        case '[':
            [self readCurrentCharaAndMove];
            return HXTokenBeginArray;
        case ']':
            [self readCurrentCharaAndMove];
            return HXTokenEndArray;
        case ':':
            [self readCurrentCharaAndMove];
            return HXTokenColon;
        case ',':
            [self readCurrentCharaAndMove];
            return HXTokenComma;
        case '\"':
            [self readCurrentCharaAndMove];
            return HXTokenString;
        case 't':
        case 'f':
            return HXTokenBoolean;
        case 'n':
            [self readCurrentCharaAndMove];
            return HXTokenNull;
        case '-':
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
            return HXTokenNumber;
        default:
            [NSException raise:@"stringFormatError" format:@"%@,非法字符", NSStringFromSelector(_cmd)];
            return HXTokenEnd;
    }
}

- (NSString *)readString {
    NSMutableString * rs = [NSMutableString stringWithCapacity:0];
    while (![self isReadToEnd]) {
        char c = [self readCurrentCharaAndMove];
        //遇到转义字符
        if (c == '\\') {
            char next = [self readCurrentCharaAndMove];
            switch (next) {
                case '\"':
                    [rs appendString:[NSString stringWithFormat:@"%c", '\"']];
                    break;
                case '\\':
                    [rs appendString:[NSString stringWithFormat:@"%c", '\\']];
                    break;
                case '/':
                    [rs appendString:[NSString stringWithFormat:@"%c", '/']];
                    break;
                case 'b':
                    [rs appendString:[NSString stringWithFormat:@"%c", '\b']];
                    break;
                case 'f':
                    [rs appendString:[NSString stringWithFormat:@"%c", '\f']];
                    break;
                case 'n':
                    [rs appendString:[NSString stringWithFormat:@"%c", '\n']];
                    break;
                case 'r':
                    [rs appendString:[NSString stringWithFormat:@"%c", '\r']];
                    break;
                case 't':
                    [rs appendString:[NSString stringWithFormat:@"%c", '\t']];
                    break;
                //unicode编码
                case 'u':{
                    NSMutableString *unicodeStr = [NSMutableString stringWithCapacity:0];
                    [unicodeStr appendString:@"\\u"];
                    
                    for (int i = 0; i < 4; i++) {
                        char uch = [self readCurrentCharaAndMove];
                        if ([self isHex:uch]) {
                            [unicodeStr appendString:[NSString stringWithFormat:@"%c", uch]];
                        }
                    }
                    NSString *s = [self replaceUnicode:unicodeStr];
                    [rs appendString:s];
                }
                    break;
                default:
                    [NSException raise:@"stringFormatError" format:@"%@,无效转义", NSStringFromSelector(_cmd)];
                    break;
            }
            
        }
        //遇到最后一个"，字符串结束
        else if (c== '\"') break;
        //不允许有换行
        else if (c == '\r' || c == '\n') {
            [NSException raise:@"stringFormatError" format:@"%@,传入的 JSON 字符串不允许换行", NSStringFromSelector(_cmd)];
        }
        else [rs appendString:[NSString stringWithFormat:@"%c", c]];
    }
    return rs;
}

- (NSString *)replaceUnicode:(NSString *)unicodeStr {
    
    NSString *tempStr1 = [unicodeStr stringByReplacingOccurrencesOfString:@"\\u"withString:@"\\U"];
    NSString *tempStr2 = [tempStr1 stringByReplacingOccurrencesOfString:@"\""withString:@"\\\""];
    NSString *tempStr3 = [[@"\""stringByAppendingString:tempStr2]stringByAppendingString:@"\""];
    NSData *tempData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
    NSString* returnStr = [NSPropertyListSerialization propertyListFromData:tempData
                                                           mutabilityOption:NSPropertyListImmutable
                                                                     format:NULL
                                                           errorDescription:NULL];
    
    return [returnStr stringByReplacingOccurrencesOfString:@"\\r\\n"withString:@"\n"];
    
}

- (BOOL)isTrans {
    char c = [self readCurrentCharaAndMove];
    return (c == '\"' || c == '\\' || c == '/' || c == 'b' || c == 'f' || c == 'n' || c == 'r' || c == 't');
}

- (BOOL)isHex:(char)c {
    return ((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F'));
}

- (BOOL)readBoolean {
    char c = [self readCurrentCharaAndMove];
    NSString *expectedStr = @"";
    if (c == 't') expectedStr = @"rue";
    else if (c == 'f') expectedStr = @"alse";
    else [NSException raise:@"stringFormatError" format:@"%@,非法字符", NSStringFromSelector(_cmd)];
    for (int i = 0; i < expectedStr.length; i++) {
        char ch = [self readCurrentCharaAndMove];
        if ([expectedStr characterAtIndex:i] != ch) [NSException raise:@"stringFormatError" format:@"%@,非法字符", NSStringFromSelector(_cmd)];
    }
    return c == 't';
}

- (void)readNull {
    if (!([self readCurrentCharaAndMove] == 'u' && [self readCurrentCharaAndMove] == 'l' && [self readCurrentCharaAndMove] == 'l')) {
        [NSException raise:@"stringFormatError" format:@"%@,非法字符", NSStringFromSelector(_cmd)];
    }
}

- (double)readNumber {
    int intpart = 0;
    double fracPart = 0.0;
    int expPart = 0;
    BOOL hasIntPart = false;
    BOOL hasFracPart = false;
    BOOL hasExpPart = false;
    int fracLength = 0;
    
    char c = [self readCurrentChar];
    BOOL isNeg = c == '-';
    if (isNeg) [self moveToNext];
    
    BOOL isExpPartNeg = false;
    
    HXReadNumberStatus numberStatus = HXNumberIntPart;
    
    while (![self isReadToEnd]) {
        c = [self readCurrentChar];
        switch (numberStatus) {
            case HXNumberIntPart:
                if (c >= '0' && c <= '9') {
                    hasIntPart = true;
                    if (intpart > INT_MAX/10) [NSException raise:@"stringFormatError" format:@"%@,整数部分超过int的范围", NSStringFromSelector(_cmd)];
                    intpart = intpart * 10 + (c - '0');
                    [self moveToNext];
                }
                else if (c == '.') {
                    if (!hasIntPart) [NSException raise:@"stringFormatError" format:@"%@,不能以'.xxx'格式表示数字", NSStringFromSelector(_cmd)];
                    [self moveToNext];
                    numberStatus = HXNumberFracPart;
                }
                else if (c == 'e' || c == 'E') {
                    if (!hasIntPart) [NSException raise:@"stringFormatError" format:@"%@,不能以'exxx'格式表示数字", NSStringFromSelector(_cmd)];
                    [self moveToNext];
                    numberStatus = HXNumberExpPart;
                    
                    char sign = [self readCurrentChar];
                    if (sign == '-' || sign == '+') {
                        isExpPartNeg = sign == '-';
                        [self moveToNext];
                    }
                }
                else {
                    if (!hasIntPart) [NSException raise:@"stringFormatError" format:@"%@,非法字符", NSStringFromSelector(_cmd)];
                    numberStatus = HXNumberFinish;
                }
                break;
            case HXNumberFracPart:
                if (c >= '0' && c <= '9') {
                    hasFracPart = true;
                    fracLength++;
                    if (fracLength > 16) [NSException raise:@"stringFormatError" format:@"%@,小数部分长度超过16位", NSStringFromSelector(_cmd)];
                    fracPart = fracPart + (c == '0' ? 0 : (c - '0') / pow(10, fracLength));
                    [self moveToNext];
                }
                else if (c == 'e' || c == 'E') {
                    if (!hasFracPart) [NSException raise:@"stringFormatError" format:@"%@,不能以'xxx.exxx'格式表示数字", NSStringFromSelector(_cmd)];
                    [self moveToNext];
                    numberStatus = HXNumberExpPart;
                    
                    char sign = [self readCurrentChar];
                    if (sign == '-' || sign == '+') {
                        isExpPartNeg = sign == '-';
                        [self moveToNext];
                    }
                }
                else {
                    if (!hasFracPart) [NSException raise:@"stringFormatError" format:@"%@,非法字符", NSStringFromSelector(_cmd)];
                    numberStatus = HXNumberFinish;
                }
                break;
            case HXNumberExpPart:
                if (c >= '0' && c <= '9') {
                    hasExpPart = true;
                    expPart = expPart * 10 + (c - '0');
                    [self moveToNext];
                }
                else {
                    if (!hasExpPart) [NSException raise:@"stringFormatError" format:@"%@,非法字符", NSStringFromSelector(_cmd)];
                    numberStatus = HXNumberFinish;
                }
                break;
            case HXNumberFinish:{
                if (!hasIntPart) [NSException raise:@"stringFormatError" format:@"%@,缺少整数部分", NSStringFromSelector(_cmd)];
                double res = 0.0;
                
                res = isNeg ? -intpart : intpart;
                if (!hasExpPart && !hasFracPart) return res;
                
                if (hasFracPart) res = isNeg ? - (intpart + fracPart): intpart + fracPart;
                if (hasExpPart) {
                    expPart = isExpPartNeg ? -expPart : expPart;
                    res = res * pow(10, expPart);
                }
                //判断一下结果越界
                return res;
            }
                break;
            default:
                break;
        }
    }
    return intpart;
}

@end
