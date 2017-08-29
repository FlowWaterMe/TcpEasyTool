//
//  AppDelegate.m
//  Tcp_client
//
//  Created by Intelligent on 16/12/5.
//  Copyright © 2016年 com.Intelligent. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (strong) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}
-(void)awakeFromNib
{
    if (m_socket) {           //判断套接字是否断开
        [m_socket close];
        [m_socket release];
        m_socket=nil;
    }
    
    m_socket=[[IASocketConnection alloc] initWithHost:[[Hostname stringValue]UTF8String] Port:(UInt32)[Portname integerValue]];  // 初始化套接字
    [m_socket setDelegate:self];         //  设置代理类  用于回调函数的消息接受
    [m_socket open:10.0];   // 打开套接字
//        [(AppDelegate*)[_window delegate] SaveSocketConfigLocalCellIP:[m_tfIP stringValue] LocalCellPort:[m_tfPort intValue] PLCIP:nil];
    

}

-(void)closeSocket
{
    if (m_socket)
    {
        [m_socket close];
        [m_socket release];
        m_socket = nil;
    }
}
-(IBAction)btconnect:(id)sender   // 手动连接tcp 套接字
{
    if (m_socket) {
        [m_socket close];
        [m_socket release];
        m_socket=nil;
    }
    m_socket=[[IASocketConnection alloc] initWithHost:[[Hostname stringValue]UTF8String] Port:(UInt32)[Portname integerValue]];
    [m_socket setDelegate:self];
    [m_socket open:10.0];

}
-(void)close           //  关闭套接字
{
    [m_socket close];
    [m_socket release];
    m_socket=nil;
}
-(IBAction)btsend:(id)sender       //  作为客户端发送消息
{
    NSString * str = [Sendmsg stringValue];
    const char * cmd = [str cStringUsingEncoding:NSASCIIStringEncoding];  // nsstring 转化 成 const char *
    if (![self isOpen]) {
        [self close];
        [self btconnect:nil];
    }
    if(strlen(cmd)>0)
    {
        int tmp = (int)strlen(cmd);      //发送的指令长度
        memset(sendbuffer, 0, SENDBUFFER_SIZE);  //  设置发送缓存区的大小
        [m_socket ClearInputBuffter];// 清空套接字缓存
        memcpy(sendbuffer, &tmp, sizeof(int));    //拷贝地址到发送缓存区 memcpy函数的功能是从源src所指的内存地址的起始位置开始拷贝n个字节到目标dest所指的内存地址的起始位置中。
        memcpy(sendbuffer+sizeof(int), cmd, tmp);
        
        NSInteger ret=-2;
        ret=[m_socket write:sendbuffer maxLength:sizeof(int)+tmp];
        [self performSelectorOnMainThread:@selector(insertTexttoView:) withObject:[NSString stringWithCString:cmd encoding:NSASCIIStringEncoding] waitUntilDone:YES];
    }
    else
    {
        NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"cmd Error%s\r",cmd] defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"please input again"];
        [alert runModal];
    }

    [self RecvMsg:1000];      //  接受服务端发送的消息
    
}
-(IBAction)btclear:(id)sender
{
    [Sendmsg setStringValue:@""];
    [Recvmsg setString:@""];
}
-(BOOL)isOpen
{
    if (m_socket==nil) {
        return NO;
    }
    return [m_socket isOpen];
}
-(long)RecvMsg:(unsigned int)wait_seconds
{
    if (![self isOpen]) {
        return -8;
    }
    unsigned int len=0;
    BOOL ret=NO;
    memset(loadcellMsg, 0, REVBUFFER_SIZE);
    
    ret=[m_socket read:(char*)&len Lenght:sizeof(unsigned int) Timeout:wait_seconds];
    
    if(!ret)
    {
        return -1;
    }
    if (len>(sizeof(loadcellMsg)-4))
    {
        return -2;
    }
    ret=[m_socket read:(char*)loadcellMsg Lenght:len Timeout:1000];
    [self performSelectorOnMainThread:@selector(insertTexttoView:) withObject:[NSString stringWithCString:loadcellMsg encoding:NSASCIIStringEncoding]waitUntilDone:YES];
    if (ret) {
        loadcellMsg[len]='\0';
        return len;
    }
    return -3;
}

-(void)insertTexttoView:(NSString*)text
{
    NSDateFormatter * fmt = [[NSDateFormatter alloc]init];
    [fmt setDateFormat:@"yyyy-MM-dd_hh-mm-ss"];
    NSString * date = [fmt stringFromDate:[NSDate date]];
    NSAttributedString * theString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:--->>>>>%@\r",date,text]];
    [[Recvmsg textStorage] appendAttributedString: theString];
    NSUInteger length = [[Recvmsg textStorage] length];
    NSRange theRange = NSMakeRange(length, 0);
    [Recvmsg scrollRangeToVisible:theRange];
    [theString release];
    [fmt release];
}
-(void)ShowMsg:(NSString*)msg
{
    [self performSelectorOnMainThread:@selector(fnErrMsg:) withObject:msg waitUntilDone:NO];
}

-(void)fnErrMsg:(id)par
{
    NSAlert *alert = [[[NSAlert alloc]init] autorelease];
    [alert setMessageText:@"SocketError"];
    [alert setInformativeText:par];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert runModal];
}
-(void)SocketStatus:(NSNumber*)number
{
//    if ([number boolValue]) {
//        [self setState:1];
//    }else
//    {
//        [self setState:0];
//    }
}
- (void)dataready:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSInteger actuallyRead;
    NSInputStream *instream = (NSInputStream*)aStream;
    actuallyRead = [instream read:(uint8_t *)m_tmpbuffer maxLength:sizeof(m_tmpbuffer)];
    if(actuallyRead<1)
    {
        NSLog(@"read data error(data lenght=%ld)",actuallyRead);
        return;
    }
    if (actuallyRead>8) {
        for (long i =0 ; i<actuallyRead-8; i++) {
            m_tmpbuffer[i] = m_tmpbuffer[i+8];
        }
        for (long i =(actuallyRead-8) ; i<=actuallyRead; i++) {
            m_tmpbuffer[i]='\0';
        }
    }
    @synchronized(m_Socketinputdata)
    {
        [m_Socketinputdata setLength:0];
        [m_Socketinputdata appendBytes:m_tmpbuffer length:actuallyRead];
    }
    NSString * readString = [NSString stringWithFormat:@"%s",(char*)m_tmpbuffer];
    NSString * readStringOut = [NSString stringWithFormat:@"Receive<--%s",(char*)m_tmpbuffer];
        [self performSelectorOnMainThread:@selector(insertTexttoView:) withObject:readString waitUntilDone:YES];
//    if (Recvmsg)
//    {
//        [Recvmsg insertTexttoView:readStringOut];
//    }
//    if (isCallbackDelegate)
//    {
//        [delegate ReceiveDataCallback:readString];
//    }
//    else
//    {
//        NSLog(@"receive data,please add 'ReceiveDataCallback' function");
//    }
}

- (void)streamerror:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch ([aStream streamStatus]) {
        case NSStreamStatusNotOpen:
            [self ShowMsg:@"connect error"];
            [self performSelectorOnMainThread:@selector(SocketStatus:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:YES];
            break;
        case NSStreamStatusOpening:
            [self ShowMsg:@"connecting to server, please wait a minute"];
            break;
        case NSStreamStatusOpen:
            break;
        case NSStreamStatusReading:
            [self ShowMsg:@"local cell busy"];
            break;
        case NSStreamStatusWriting:
            [self ShowMsg:@"local cell busy"];
            break;
        case NSStreamStatusAtEnd:
            [self closeSocket];
            [self ShowMsg:@"Server stop"];
            [self performSelectorOnMainThread:@selector(SocketStatus:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:YES];
            break;
        case NSStreamStatusClosed:
            [self closeSocket];
            [self ShowMsg:@"Server close"];
            [self performSelectorOnMainThread:@selector(SocketStatus:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:YES];
            break;
        case NSStreamStatusError:
            [self closeSocket];
            [self ShowMsg:@"Server error"];
            [self performSelectorOnMainThread:@selector(SocketStatus:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:YES];
            break;
        default:
            break;
    }
}

- (void)ConnectTimeout:(NSTimer *)timer Socket:(IASocketConnection*)socket
{
    [self closeSocket];
    [self performSelectorOnMainThread:@selector(SocketStatus:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:YES];
    [self ShowMsg:@"connect to server timeout"];
}

- (void)opencompleted:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    [self performSelectorOnMainThread:@selector(SocketStatus:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:YES];
}


@end
