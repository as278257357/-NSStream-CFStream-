//
//  ViewController.m
//  NSStreeam&CFStream Client
//
//  Created by EaseMob on 16/5/6.
//  Copyright © 2016年 EaseMob. All rights reserved.
//

#import "ViewController.h"
#import <CoreFoundation/CoreFoundation.h>
#include <sys/socket.h>
#include <netinet/in.h>

#define PORT 9000


@interface ViewController ()<NSStreamDelegate>
{
    int flag; // 操作标志 0 发送 1为接收
}
@property (nonatomic, retain)NSInputStream *inputStream;
@property (nonatomic, retain)NSOutputStream *outputStream;




@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [sendButton addTarget:self action:@selector(sendMessage:) forControlEvents:UIControlEventTouchUpInside];
    sendButton.backgroundColor = [UIColor redColor];
    sendButton.frame = CGRectMake(100, 100, 250, 50);
    [self.view addSubview:sendButton];
    
    UIButton *receiveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    receiveButton.frame = CGRectMake(100, 300, 250, 50);
    receiveButton.backgroundColor = [UIColor blueColor];
    [receiveButton addTarget:self action:@selector(receiveMessage:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:receiveButton];
    
    // Do any additional setup after loading the view, typically from a nib.
}

#pragma 基于NSStream&CFStream实现的客户端

- (void)initNetworkCommunication {
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"172.16.4.23", PORT, &readStream, &writeStream);
    _inputStream = (__bridge_transfer NSInputStream *)readStream;
    _outputStream = (__bridge_transfer NSOutputStream *)writeStream;
    [_inputStream setDelegate:self];
    [_outputStream setDelegate:self];
    [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_inputStream open];
    [_outputStream open];
}

- (void)close {
    [_outputStream close];
    [_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream setDelegate:nil];
    [_inputStream close];
    [_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_inputStream setDelegate:nil];
}


//基于NSStream&CFStream实现的客户端的发送数据
- (void)sendMessage:(id)sender {
    flag = 0;
    [self initNetworkCommunication];
}
//基于NSStream&CFStream实现的客户端的接收数据
- (void)receiveMessage:(id)sender {
    flag = 1;
    [self initNetworkCommunication];
}

#pragma NSStreamDelegate
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    NSString *event;
    switch (eventCode) {
        case NSStreamEventNone:
            event = @"NSStreamEventNone";
            break;
        case NSStreamEventOpenCompleted:
            event = @"NSStreamEventOpenCompleted";
            break;
        case NSStreamEventHasBytesAvailable:
            event = @"NSStreamEventHasBytesAvailable";
            if (flag == 1 && aStream == _inputStream) {
                NSMutableData *input = [[NSMutableData alloc]init];
                uint8_t buffer[1024];
                int len;
                while ([_inputStream hasBytesAvailable]) {
                    len = [_inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        [input appendBytes:buffer length:len];
                    }
                }
                NSString *resultstring = [[NSString alloc]initWithData:input encoding:NSUTF8StringEncoding];
                NSLog(@"接收: %@",resultstring);
                
            }
            break;
        case NSStreamEventHasSpaceAvailable:
            event = @"NSStreamEventHasSpaceAvailable";
            if (flag == 0 && aStream == _outputStream) {
                //输出
                UInt8 buff[] = "Hello Server";
                [_outputStream write:buff maxLength:strlen((const char *)buff +1)];
                [_outputStream close];
            }
            break;
        case NSStreamEventErrorOccurred:
            event = @"NSStreamEventErrorOccurred";
            [self close];
            break;
        case NSStreamEventEndEncountered:
            event = @"NSStreamEventEndEncountered";
            NSLog(@"Error %ld: %@",[[aStream streamError]code],[[aStream streamError]localizedDescription]);
            break;
            
        default:
            [self close];
            event = @"Unkown";
            break;
    }
    NSLog(@"event ------ %@",event);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
