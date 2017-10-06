//
//  SourceEditorCommand.m
//  RunWhenSave
//
//  Created by wangchao on 2017/10/6.
//  Copyright © 2017年 ibestv. All rights reserved.
//

#import "SourceEditorCommand.h"
@import Foundation;
@import XcodeKit;

@implementation SourceEditorCommand

#define STRING(fmt,...) [NSString stringWithFormat : fmt,##__VA_ARGS__]
- (NSString*)format:(NSString*)filePath /* arguments:(NSArray*)arguments*/ {
    NSString *commandPath = [[NSBundle mainBundle] pathForResource:@"uncrustify" ofType:nil];
    NSString *configPath  = [[NSBundle mainBundle] pathForResource:@"uncrustify.cfg" ofType:nil];
    NSPipe   *errorPipe   = [[NSPipe alloc] init];
    NSPipe   *outputPipe  = [[NSPipe alloc] init];

    NSString *fullCommnad = [NSString stringWithFormat:@"-c %@ --no-backup %@", configPath, filePath];

    ///uncrustify -c "./uncrustify.cfg" --no-backup "$1"
    NSTask *task = [[NSTask alloc] init];
    task.standardError  = errorPipe;
    task.standardOutput = outputPipe;
    task.launchPath     = commandPath;
    task.arguments      = @[(@"-c"),
                            (configPath),
                            (@"--no-backup"),
                            filePath];//@[@"-c ", configPath, @" --no-backup ", filePath];
   #if 0
        NSPipe       *inputPipe = [[NSPipe alloc] init];
        task.standardInput = inputPipe;
        NSFileHandle *stdinHandle = inputPipe.fileHandleForWriting;

        NSData       *data = [content dataUsingEncoding:NSUTF8StringEncoding];
        if (data.length > 0) {
            [stdinHandle writeData:data];
            [stdinHandle closeFile];
        }
   #endif // if 0
    [task launch];
    [task waitUntilExit];

    NSData   *errorData = [errorPipe.fileHandleForReading readDataToEndOfFile];
    NSString *errorText = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", errorText);
    //NSData   *outputData = [outputPipe.fileHandleForReading readDataToEndOfFile];
    //NSString *resultText = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    NSError  *error  = nil;
    NSString *result = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    return result;
}

- (void)performCommandWithInvocation:(XCSourceEditorCommandInvocation*)invocation completionHandler:(void (^)(NSError*_Nullable nilOrError))completionHandler {
//    static let swiftSource = UTI(value: "public.swift-source")
//    static let cHeader = UTI(value: "public.c-header")
//    static let objCSource = UTI(value: "public.objective-c-source")
//    static let playground = UTI(value: "com.apple.dt.playground")
//    static let playgroundPage = UTI(value: "com.apple.dt.playgroundpage")
//    static let storyboard = UTI(value: "com.apple.InterfaceBuilder3.Storyboard.XIB")
//    static let xib = UTI(value: "com.apple.InterfaceBuilder3.Cocoa.XIB")
//    static let markdown = UTI(value: "net.daringfireball.markdown")
//    static let xml = UTI(value: "public.xml")
//    static let json = UTI(value: "public.json")
//    static let plist = UTI(value: "com.apple.xml-property-list")
//    static let entitlement = UTI(value: "com.apple.xcode.entitlements-property-list")

    NSString *UTI = invocation.buffer.contentUTI;
    if ([invocation.commandIdentifier isEqualToString:@"preference"]) {
        completionHandler(nil);
        return;
    } else {
        NSString *tempFolder = NSHomeDirectory();
        NSLog(@"%@", tempFolder);
        NSString *tempPath = [tempFolder stringByAppendingPathComponent:@"uncrustify-derive"];
        NSError  *error    = nil;
        [tempPath writeToFile:[tempFolder stringByAppendingPathComponent:@"log.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            completionHandler(error);
            return;
        }

        if ([UTI isEqualToString:@"public.c-header"]) {
            tempPath = [tempPath stringByAppendingPathComponent:@"temp.h"];
        } else if ([UTI isEqualToString:@"public.objective-c-source"]) {
            tempPath = [tempPath stringByAppendingPathComponent:@"temp.m"];
        } else if ([UTI isEqualToString:@"public.swift-source"]) {
        } else {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"unsupport file type. %@",UTI]};
            NSError      *error    = [NSError errorWithDomain:@"com.wangchao.xcodeplugin" code:1 userInfo:userInfo];
            completionHandler(error);
            return;
        }


        NSLog(@"%@", invocation);

        NSString *content = invocation.buffer.completeBuffer;
        [content writeToFile:tempPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            completionHandler(error);
            return;
        }
        NSString *result = [self format:tempPath];
        invocation.buffer.completeBuffer = result?:content;
    }
    completionHandler(nil);
}

@end
