//
//  AppDelegate.h
//  Tcp_client
//
//  Created by Intelligent on 16/12/5.
//  Copyright © 2016年 com.Intelligent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IASocketConnection.h"
#import <iostream>
#define SENDBUFFER_SIZE 255
#define REVBUFFER_SIZE 255
@interface AppDelegate : NSObject<NSStreamDelegate,IASocketConnection>
{
    char sendbuffer[SENDBUFFER_SIZE];
    char loadcellMsg[REVBUFFER_SIZE];
    uint8_t m_tmpbuffer[1024];
    NSMutableData *m_Socketinputdata;
    id delegate;
    BOOL isControltDelegate;
    BOOL isSendDataDelegate;
    BOOL isCallbackDelegate;
    @private
    IBOutlet NSTextField * Hostname;
    IBOutlet NSTextField * Portname;
    IBOutlet NSTextField * Sendmsg;
    IBOutlet NSTextView * Recvmsg;
    IBOutlet NSButton * Butsend;
    IBOutlet NSButton * Butclear;
    IBOutlet NSWindow * window;
    IASocketConnection * m_socket;
    
}
-(IBAction)btconnect:(id)sender;
-(IBAction)btsend:(id)sender;
-(IBAction)btclear:(id)sender;
-(void)ShowMsg:(NSString*)msg;
-(long)RecvMsg:(unsigned int)wait_seconds;
-(void)fnErrMsg:(id)par;
@end

