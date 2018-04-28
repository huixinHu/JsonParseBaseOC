//
//  main.m
//  JsonParse
//
//  Created by cc on 2018/4/26.
//  Copyright © 2018年 cc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TokenReader.h"
#import "JsonReader.h"

void test() {
    
    NSString * filepath = @"/Users/cc/Desktop/JsonParse/JsonParse/data";
    for (int i = 0; i < 24; i ++) {
        NSString * name = [NSString stringWithFormat:@"%d.txt", i];
        NSString *path = [filepath stringByAppendingPathComponent:name];
        NSString *jsonString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        
        @try {
            NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            id cocoaParseValue = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            
            JsonReader *reader = [[JsonReader alloc] initWithString:jsonString];
            id parseValue = [reader parse];
            
            if (![parseValue isEqual:cocoaParseValue]) {
                NSLog(@"%@", jsonString);
            }
        }
        @catch (NSException *exp) {
            NSLog(@"%@", jsonString);
        }
    }
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        test();
        
//        NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingSortedKeys error:nil];
//        NSString *ss = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
//        NSLog(@"%@", obj);

//        //字典
//        NSString *jsonstr = @"{\"name\" : \"huhuixin\\\" test\"}";
//        JsonReader *reader = [[JsonReader alloc] initWithString:jsonstr];
//        NSLog(@"%@", [reader parse]);
//
//        //数组
//        NSString *str1 = @"[123,true, false, null, \"hello\"]";
//        reader = [[JsonReader alloc] initWithString:str1];
//        NSLog(@"%@", [reader parse]);
//
//        //数组嵌套数组
//        NSString *str2 = @"[true, false, null, \"hello\", [\"\", \"\\\\\", \"\\/\", \"\\b\", \"\\f\", \"\\n\", \"\\r\", \"\\t\", \"\\u4f60\\u597d\"]]";
//        reader = [[JsonReader alloc] initWithString:str2];
//        NSLog(@"%@", [reader parse]);
//
//        //数组嵌套字典
//        NSString *str3 = @"[true, {\"name\" : \"huhuixin\\\" test\"}]";
//        reader = [[JsonReader alloc] initWithString:str3];
//        NSLog(@"%@", [reader parse]);
//
//        //字典嵌套数组
//        NSString *str4 = @"{\"name\" : [true, false, null, \"hello\"]}";
//        reader = [[JsonReader alloc] initWithString:str4];
//        NSLog(@"%@", [reader parse]);
//
//        //字典嵌套字典
//        NSString *str5 = @"{\"name\" : {\"name\" : \"huhuixin\\\" test\"}}";
//        reader = [[JsonReader alloc] initWithString:str5];
//        NSLog(@"%@", [reader parse]);
//
//        //数字
//        NSString *str6 = @"[-12, 34, 2.34, 0.11, 1e2, 2E-3, 1.23E45]";
//        reader = [[JsonReader alloc] initWithString:str6];
//        NSLog(@"%@", [reader parse]);
    }
    return 0;
}

