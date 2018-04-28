//
//  JsonReader.m
//  JsonParse
//
//  Created by cc on 2018/4/26.
//  Copyright © 2018年 cc. All rights reserved.
//

#import "JsonReader.h"
#import "TokenReader.h"

typedef NS_ENUM (NSInteger, HXNextPraseStatus)   {
    HXNextStatusBeginObject = 0x0001,   //{
    HXNextStatusEndObject = 0x0002,     //}
    HXNextStatusObjectKey = 0x0004,     //string
    HXNextStatusObjectValue = 0x0008,   //string number object array bool null
    HXNextStatusBeginArray = 0x0010,    //[
    HXNextStatusEndArray = 0x0020,      //]
    HXNextStatusArrayValue = 0x0040,    //string number object array bool null
    HXNextStatusColon = 0x0080,         //:
    HXNextStatusComma = 0x0100,         //,
    HXNextStatusValue = 0x0200,         //string number object array bool null
    HXNextStatusFinish = 0x0040,
};

typedef NS_ENUM (NSInteger, HXItemType)   {
    HXItemObject = 1,
    HXItemObjectKey = 2,
    HXItemArray = 3,
    HXItemValue = 4,
};

@interface StackItem: NSObject
@property (nonatomic, assign) HXItemType type;
@property (nonatomic, strong) id object;
@end

@implementation StackItem
- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (instancetype)initWithType:(HXItemType)type Object:(id) obj {
    if (self = [super init]) {
        self.type = type;
        self.object = obj;
    }
    return self;
}


@end

@interface JsonReader()
@property (nonatomic, strong) TokenReader *reader;
@property (nonatomic, strong) NSMutableArray<StackItem *> *stack;//数据存储栈
@end

@implementation JsonReader
{
    HXNextPraseStatus nextStatus;
}

- (instancetype)initWithString:(NSString *)jsonString {
    if (self = [super init]) {
        self.reader = [[TokenReader alloc] initWithJsonString:jsonString];
    }
    return self;
}

- (id)parse {
    nextStatus = HXNextStatusBeginObject | HXNextStatusBeginArray | HXNextStatusValue;
    while (1) {
        HXTokenType currentToken = [self.reader readNextToken];
        switch (currentToken) {
            case HXTokenBeginObject:
                if ([self isExpectedStatus:HXNextStatusBeginObject]) {
                    nextStatus = HXNextStatusEndObject | HXNextStatusObjectKey;
                    [self.stack addObject:[[StackItem alloc]initWithType:HXItemObject Object:[NSMutableDictionary dictionary]]];
                }
                else [NSException raise:@"parseError" format:@"未知字符'{'"];
                break;
            case HXTokenEndObject:
                if ([self isExpectedStatus:HXNextStatusEndObject]) {
                    StackItem *obj = self.stack.lastObject;//获取栈顶元素
                    [self.stack removeLastObject];//出栈
                    if (self.stack.count == 0) {
                        [self.stack addObject:obj];
                        nextStatus = HXNextStatusFinish;
                        break;
                    }
                    
                    StackItem *curLastObject = self.stack.lastObject;//当前栈顶元素
                    HXItemType type = curLastObject.type;//当前栈顶元素类型
                    //array-object
                    if (type == HXItemArray) {
                        [curLastObject.object addObject:obj.object];
                        nextStatus = HXNextStatusComma | HXNextStatusEndArray;
                    }
                    //object-object
                    else if (type == HXItemObjectKey) {
                        NSString *key = curLastObject.object;
                        [self.stack removeLastObject];
                        NSMutableDictionary *dict = (NSMutableDictionary *)self.stack.lastObject.object;
                        [dict setObject:obj.object forKey:key];
                        nextStatus = HXNextStatusComma | HXNextStatusEndObject;
                    }
                }
                else [NSException raise:@"parseError" format:@"未知字符'}'"];
                break;
            case HXTokenBeginArray:
                if ([self isExpectedStatus:HXNextStatusBeginArray]) {
                    [self.stack addObject:[[StackItem alloc]initWithType:HXItemArray Object:[NSMutableArray array]]];
                    nextStatus = HXNextStatusEndArray | HXNextStatusArrayValue | HXNextStatusBeginArray | HXNextStatusBeginObject;
                }
                else [NSException raise:@"parseError" format:@"未知字符'['"];
                break;
            case HXTokenEndArray:
                if ([self isExpectedStatus:HXNextStatusEndArray]) {
                    StackItem *obj = self.stack.lastObject;
                    [self.stack removeLastObject];
                    if (self.stack.count == 0) {
                        [self.stack addObject:obj];
                        nextStatus = HXNextStatusFinish;
                        break;
                    }
                    
                    StackItem *curObj = self.stack.lastObject;
                    HXItemType type = curObj.type;
                    //array-array
                    if (type == HXItemArray) {
                        [curObj.object addObject:obj.object];
                        nextStatus = HXNextStatusComma | HXNextStatusEndArray;
                    }
                    //object-array
                    else if (type == HXItemObjectKey) {
                        NSString *key = curObj.object;
                        [self.stack removeLastObject];
                        NSMutableDictionary *dict = (NSMutableDictionary *)self.stack.lastObject.object;
                        [dict setObject:obj.object forKey:key];
                        nextStatus = HXNextStatusComma | HXNextStatusEndObject;
                    }
                }
                else [NSException raise:@"parseError" format:@"未知字符']'"];
                break;
            case HXTokenColon:
                if ([self isExpectedStatus:HXNextStatusColon]) {
                    nextStatus = HXNextStatusObjectValue | HXNextStatusBeginObject | HXNextStatusBeginArray;
                }
                else [NSException raise:@"parseError" format:@"未知字符':'"];
                break;
            case HXTokenComma:
                if ([self isExpectedStatus:HXNextStatusComma]) {
                    if ([self isExpectedStatus:HXNextStatusEndArray]) {
                        nextStatus = HXNextStatusBeginArray | HXNextStatusBeginObject | HXNextStatusArrayValue;
                    }
                    else if ([self isExpectedStatus:HXNextStatusEndObject]) {
                        nextStatus = HXNextStatusObjectKey;
                    }
                }
                else [NSException raise:@"parseError" format:@"未知字符','"];
                break;
            case HXTokenString:{
                NSString *str = [self.reader readString];
                if ([self isExpectedStatus:HXNextStatusObjectKey]) {
                    [self.stack addObject:[[StackItem alloc]initWithType:HXItemObjectKey Object:str]];
                    nextStatus = HXNextStatusColon;
                }
                else if ([self isExpectedStatus:HXNextStatusObjectValue]) {
                    StackItem *obj = self.stack.lastObject;
                    if (obj.type == HXItemObjectKey) {
                        NSString *key = obj.object;
                        [self.stack removeLastObject];
                        NSMutableDictionary *dict = (NSMutableDictionary *)self.stack.lastObject.object;
                        [dict setObject:str forKey:key];
                        nextStatus = HXNextStatusComma | HXNextStatusEndObject;
                    }
                }
                else if ([self isExpectedStatus:HXNextStatusArrayValue]) {
                    [self.stack.lastObject.object addObject:str];
                    nextStatus = HXNextStatusComma | HXNextStatusEndArray;
                }
                else if ([self isExpectedStatus:HXNextStatusValue]) {
                    [self.stack addObject:[[StackItem alloc]initWithType:HXItemValue Object:str]];
                    nextStatus = HXNextStatusFinish;
                }
                else [NSException raise:@"parseError" format:@"未知字符'\"'"];
                break;
            }
            case HXTokenBoolean:{
                BOOL b = [self.reader readBoolean];
                if ([self isExpectedStatus:HXNextStatusObjectValue]) {
                    StackItem *obj = self.stack.lastObject;
                    if (obj.type == HXItemObjectKey) {
                        NSString *key = obj.object;
                        [self.stack removeLastObject];
                        NSMutableDictionary *dict = (NSMutableDictionary *)self.stack.lastObject.object;
                        [dict setObject:[NSNumber numberWithBool:b] forKey:key];
                        nextStatus = HXNextStatusComma | HXNextStatusEndObject;
                    }
                }
                else if ([self isExpectedStatus:HXNextStatusArrayValue]) {
                    [self.stack.lastObject.object addObject:[NSNumber numberWithBool:b]];
                    nextStatus = HXNextStatusComma | HXNextStatusEndArray;
                }
                else if ([self isExpectedStatus:HXNextStatusValue]) {
                    [self.stack addObject:[[StackItem alloc]initWithType:HXItemValue Object:[NSNumber numberWithBool:b]]];
                    nextStatus = HXNextStatusFinish;
                }
                else [NSException raise:@"parseError" format:@"未知bool类型解析"];
            }
                break;
            case HXTokenNull:
            {
                [self.reader readNull];
                if ([self isExpectedStatus:HXNextStatusObjectValue]) {
                    StackItem *obj = self.stack.lastObject;
                    if (obj.type == HXItemObjectKey) {
                        NSString *key = obj.object;
                        [self.stack removeLastObject];
                        NSMutableDictionary *dict = (NSMutableDictionary *)self.stack.lastObject.object;
                        [dict setObject:[NSNull null] forKey:key];
                        nextStatus = HXNextStatusComma | HXNextStatusEndObject;
                    }
                }
                else if ([self isExpectedStatus:HXNextStatusArrayValue]) {
                    [self.stack.lastObject.object addObject:[NSNull null]];
                    nextStatus = HXNextStatusComma | HXNextStatusEndArray;
                }
                else if ([self isExpectedStatus:HXNextStatusValue]) {
                    [self.stack addObject:[[StackItem alloc]initWithType:HXItemValue Object:[NSNull null]]];
                    nextStatus = HXNextStatusFinish;
                }
                else [NSException raise:@"parseError" format:@"未知null类型解析"];
            }
                break;
            case HXTokenNumber:
            {
                double num = [self.reader readNumber];
                if ([self isExpectedStatus:HXNextStatusObjectValue]) {
                    StackItem *obj = self.stack.lastObject;
                    if (obj.type == HXItemObjectKey) {
                        NSString *key = obj.object;
                        [self.stack removeLastObject];
                        NSMutableDictionary *dict = (NSMutableDictionary *)self.stack.lastObject.object;
                        [dict setObject:[NSNumber numberWithDouble:num] forKey:key];
                        nextStatus = HXNextStatusComma | HXNextStatusEndObject;
                    }
                }
                else if ([self isExpectedStatus:HXNextStatusArrayValue]) {
                    [self.stack.lastObject.object addObject:[NSNumber numberWithDouble:num]];
                    nextStatus = HXNextStatusComma | HXNextStatusEndArray;
                }
                else if ([self isExpectedStatus:HXNextStatusValue]) {
                    [self.stack addObject:[[StackItem alloc]initWithType:HXItemValue Object:[NSNumber numberWithDouble:num]]];
                    nextStatus = HXNextStatusFinish;
                }
                else [NSException raise:@"parseError" format:@"未知数字类型解析"];
            }
                break;
            case HXTokenEnd:
                if ([self isExpectedStatus:HXNextStatusFinish]) {
                    StackItem *obj = self.stack.lastObject;
                    [self.stack removeLastObject];
                    if (self.stack.count == 0) {
                        return obj.object;
                    }
                }
                else [NSException raise:@"parseError" format:@"结尾未知错误"];
                break;
            default:
                break;
        }
    }
}

- (BOOL)isExpectedStatus:(HXNextPraseStatus)curStatus {
    return (curStatus & nextStatus) > 0;
}

- (NSMutableArray *)stack {
    if (_stack == nil) {
        _stack = [NSMutableArray arrayWithCapacity:0];
    }
    return _stack;
}
@end
