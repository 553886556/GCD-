//
//  ViewController.m
//  GCD
//
//  Created by wangyapu on 2018/4/10.
//  Copyright © 2018年 taoke. All rights reserved.
//

#import "ViewController.h"
#import "SecondViewController.h"
static NSString *CellReuseIdentifier = @"CellReuseIdentifier";
@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *nameArr;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initTableView];
}

/*
 同步派发 + 串行队列
 不会开启新的线程,在当前线程执行任务
*/
- (void)syncSerial {
    NSLog(@"当前线程----%@", [NSThread currentThread]);
    NSLog(@"syncSerial----begin");
    dispatch_queue_t serialQueue = dispatch_queue_create("com.gcd.serial1", DISPATCH_QUEUE_SERIAL);
    dispatch_sync(serialQueue, ^{
       // 追加任务1
        for (int i = 0; i < 3; i++) {
            [NSThread sleepForTimeInterval:1];
            NSLog(@"1----%@", [NSThread currentThread]);
        }
    });
    dispatch_sync(serialQueue, ^{
       // 追加任务2
        for (int i = 0; i < 3; i++) {
            [NSThread sleepForTimeInterval:1];
            NSLog(@"2----%@", [NSThread currentThread]);
        }
    });
    
    dispatch_sync(serialQueue, ^{
       //追加任务3
        for (int i = 0; i < 3; i++) {
            [NSThread sleepForTimeInterval:1];
            NSLog(@"3----%@", [NSThread currentThread]);
        }
    });
    
    NSLog(@"------end-------当前线程------%@", [NSThread currentThread]);
    
}

/**
 同步派发 + 并发队列
 不会开启新的线程 并发队列里面的任务 在执行的时候不能添加任务 只能在队列里面任务 执行结束后才能添加
 */
- (void)syncConcurrent
{
    NSLog(@"当前线程----%@", [NSThread currentThread]);
    NSLog(@"syncConcurrent----begin");
    dispatch_queue_t concurrentQueue = dispatch_queue_create("com.gcd.concurrentQueue1", DISPATCH_QUEUE_CONCURRENT);
    dispatch_sync(concurrentQueue, ^{
        [NSThread sleepForTimeInterval:2];
        NSLog(@"执行第一个任务-----当前线程%@", [NSThread currentThread]);
    });
    dispatch_sync(concurrentQueue, ^{
        [NSThread sleepForTimeInterval:2];
        NSLog(@"执行第二个任务-----当前线程%@", [NSThread currentThread]);
    });
    dispatch_sync(concurrentQueue, ^{
        [NSThread sleepForTimeInterval:2];
        NSLog(@"执行第三个任务-----当前线程%@", [NSThread currentThread]);
    });
    NSLog(@"syncConcurrent----end");
}

/**
 异步派发 + 串行队列
 任务会立即添加 不会等串行队列里的任务执行完之后再添加 但是执行顺序还是 先进先出 任务被拿出来执行
 开启了新的线程
 */
- (void)asyncSrrial
{
    NSLog(@"当前线程-------%@", [NSThread currentThread]);
    dispatch_queue_t serialQueue = dispatch_queue_create("com.gcd.serialQueue2", DISPATCH_QUEUE_SERIAL);
    for (int i = 0; i < 10; i++) {
        dispatch_async(serialQueue, ^{
            NSLog(@"当前时间:%@ 正在线程:%@ 执行第%d个任务", [[NSDate date] description], [NSThread currentThread], i);
            [NSThread sleepForTimeInterval:1];
        });
    }
}
/**
 异步派发 + 并发队列
 会开启新的线程 任务的添加不用等待 任务的执行同时进行
 */
- (void)asyncConcurrent
{
    NSLog(@"当前线程-------%@", [NSThread currentThread]);
    dispatch_queue_t concurrentQueue = dispatch_queue_create("com.gcd.concurrentQueue2", DISPATCH_QUEUE_CONCURRENT);
    for (int i = 0; i < 10; i++) {
        dispatch_async(concurrentQueue, ^{
            NSLog(@"当前时间:%@ 正在线程:%@ 执行第%d个任务", [[NSDate date] description], [NSThread currentThread], i);
            [NSThread sleepForTimeInterval:1];
        });
    }
}

/**
 同步派发 + mainQueue
 会造成死锁
 原因: 我们在主线程中执行 syncMain 方法, 相当于把 syncMain 任务加入到了主线程队列中,而任务的添加就要等待主线程处理完 syncMain 才能添加 , 就会造成死锁
 */
- (void)syncMain
{
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_sync(mainQueue, ^{
        NSLog(@"可以进入");
    });
}


/**
 异步派发 + mainQueue
 不会开启新的线程 执行完一个任务 再执行下一个
 */
- (void)asyncMainQueue
{
    NSLog(@"当前线程-------%@", [ NSThread currentThread]);
    for (int i = 0; i < 10; i++) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"当前时间:%@ 正在线程:%@ 执行第%d个任务", [[NSDate date] description], [NSThread currentThread], i);
            [NSThread sleepForTimeInterval:1];
        });
    }
}

/**
 线程间的通信
 */
- (void)communication
{
    SecondViewController *secondVC = [[SecondViewController alloc] init];
    [self.navigationController pushViewController:secondVC animated:YES];
}

/**
 dispatch_barrier_async 栅栏
 我们有时需要异步执行两组操作,而第一组操作执行完之后,才能执行第二组操作。
 我们需要一个栅栏一样的方法将两组异步执行的操作组合分割起来,这里的操作组可以包含一个或多个任务
 需要用到 dispatch_barrier_async 方法在两个操作间形成栅栏
 
 dispatch_barrier_async
 dispatch_barrier_sync
 都会等待 barrier 里面的任务执行之后再执行下面的任务
 
 dispatch_barrier_sync 需要等待自己的任务(barrier)结束之后,才会继续将 barrier 后面的任务加入到 Queue
 dispatch_barrier_async 将自己的任务 (barrier)插入到 Queue 之后,不会等待自己的任务结束, 它会继续 barrier把后面的任务加入到 Queue
 */
- (void)dispatchSyncBarrier
{
    dispatch_queue_t concurrentQueue = dispatch_queue_create("com.gcd.concurrentQueue3", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(concurrentQueue, ^{
        // 添加任务1
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"1----%@", [NSThread currentThread]);
        }
    });
    dispatch_async(concurrentQueue, ^{
        // 添加任务2
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"2----%@", [NSThread currentThread]);
        }
    });
    dispatch_barrier_sync(concurrentQueue, ^{
        // 添加任务 barrier
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"barrier----%@", [NSThread currentThread]);
        }
    });
    dispatch_async(concurrentQueue, ^{
        // 添加任务3
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"3-----%@", [NSThread currentThread]);
        }
    });
    
    dispatch_async(concurrentQueue, ^{
        // 添加任务4
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"4-----%@", [NSThread currentThread]);
        }
    });
    
}
- (void)dispatchAsyncBarrier
{
    dispatch_queue_t concurrentQueue = dispatch_queue_create("com.gcd.concurrentQueue4", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(concurrentQueue, ^{
        // 添加任务1
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"1----%@", [NSThread currentThread]);
        }
    });
    dispatch_async(concurrentQueue, ^{
        // 添加任务2
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"2----%@", [NSThread currentThread]);
        }
    });
    
    dispatch_barrier_async(concurrentQueue, ^{
       // 添加任务 barrier
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"barrier----%@", [NSThread currentThread]);
        }
    });
    
    dispatch_async(concurrentQueue, ^{
       // 添加任务3
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"3-----%@", [NSThread currentThread]);
        }
    });
    
    dispatch_async(concurrentQueue, ^{
        // 添加任务4
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"4-----%@", [NSThread currentThread]);
        }
    });
}

/**
 延迟执行方法 dispatch_after
 dispatch_after 函数并不是指定时间之后才开始执行处理,而是在指定时间之后将任务追加到主队列
 
 */
- (void)dispatchAfter
{
    NSLog(@"当前线程-----%@", [NSThread currentThread]);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
          NSLog(@"after---%@",[NSThread currentThread]);  // 打印当前线程
    });
}

/**
 dispatch_once 执行一次
 */
- (void)dispatchOnce
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"只会执行一次");
    });
}

/**
 dispatch_group
 
 void dispatch_group_async(dispatch_group_t group,dispatch_queue_t queue,dispatch_block_t block);
 将block(任务)提交到指定的队列,并且将这次任务关联到指定的 group,block 将异步执行
 
 void dispatch_group_notify(dispatch_group_t group,dispatch_queue_t queue,dispatch_block_t block);
 当 group 的任务都完成以后执行.这句代码要加到所有任务完成或者超时之后返回,返回值0代表任务完成,非0代表超时
 
 直接使用下面三个操作改为真实的网络请求操作后,这个简单做法会变得无效,因为网路请求需要时间,而线程的执行不会等待请求完毕完成后才真正算作完成,只是负责将请求发出
 线程就认为自己的任务算完成了,当三个请求都发送出去的时候就会执行 notify 中的任务,但是请求结果返回的时间是不一定的,也就导致了界面刷新了,请求才返回,无效这样
 */
- (void)groupNotify
{
    NSLog(@"当前线程------%@", [NSThread currentThread]);
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       //追加任务1
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"1-----%@", [NSThread currentThread]);
        }
    });
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       // 追加任务2
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"2------%@", [NSThread currentThread]);
        }
    });
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
       // 等前面的异步任务1, 任务2都执行完毕后,回到主线程执行下边任务
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"3------%@", [NSThread currentThread]);
        }
        NSLog(@"group------end");
    });
}

/**
 dispatch_group_wait
 暂停当前线程(阻塞当前线程), 等待指定的 group 中的任务执行完之后,才会向下继续执行
 参数 timeout 是超时时间
 不要在主线程上使用
 */
- (void)groupWait
{
    NSLog(@"当前线程----%@", [NSThread currentThread]);
    NSLog(@"group-----begin");
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       // 追加任务1
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"1-------%@", [NSThread currentThread]);
        }
    });
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"2--------%@", [NSThread currentThread]);
        }
    });
    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"任务全部执行结束了");
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_group_wait(group,  dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));
        NSLog(@"天青色等烟雨");
    });
}

/**
 void dispatch_group_enter(dispatch_group_t)
 用这个方法追加一个任务加到 group,执行一次,相当于 group 中 未执行完毕任务数+1
 用来替代 dispatch_group_async 注意 只能和 dispatch_group_enter 配合使用
 
 void dispatch_group_leave, 标志着一个任务离开了 group,执行一次,相当于 group 中未执行完毕任务数-1
 
 当 group 中未执行完毕任务数为0的时候,才会使 dispatch_group_wait接触阻塞, 以及执行追加到 dispatch_group_notify 中的任务
 */
- (void)groupEnterAndLeave
{
    NSLog(@"当前线程------%@", [NSThread currentThread]);
    NSLog(@"group begin");
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_enter(group);
    dispatch_async(globalQueue, ^{
       // 追加任务1
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"1-----%@", [NSThread currentThread]);
        }
        dispatch_group_leave(group);
    });
    
    dispatch_group_enter(group);
    dispatch_async(globalQueue, ^{
       // 追加任务2
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"2-----%@", [NSThread currentThread]);
        }
        dispatch_group_leave(group);
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
       // 等前面的异步操作都执行完毕后,回到主线程
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"3-----%@", [NSThread currentThread]);
        }
        NSLog(@"group end");
    });
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    NSLog(@"group end end");
}

/**
 GCD 信号量
 dispatch_semaphore_create(long value)
 这个函数是创建一个 dispatch_semaphore_t 类型的信号量,并且创建的时候需要指定信号量的大小
 
 dispatch_semaphore_wait(dispatch_seamphore_t dsema, dispatch_time_t timeout);
 等待信号量,如果信号量是0, 那么该函数就会一直等待, 也就是不返回(相当于阻塞了当前线程),直到该函数等待的信号量的值大于等于1,该函数对信号量的值减1操作,然后返回
 
 dispatch_semaphore_signal(dispatch_semaphore_t deem)
 发送信号量,该函数会对信号量的值进行加1操作
 
 一般情况下,发送信号与等待信号是成对出现的

 用信号量机制使得异步线程完成同步操作
 并发队列的任务,由异步线程的执行顺序是不确定的,两个任务分别又两个线程执行,很难控制哪个任务先执行,哪个任务后执行
 但是有时候确实有这个样需求,两个任务虽然是异步的答案是仍需要同步执行(登录 + 请求首页数据),这时候就可以使用 GCD 信号量
 
 信号量实际开发主要用于:
 1.保证线程同步,将异步执行的任务转化为同步执行
 2.保证线程安全,为线程加锁
 */
- (void)semaphoreSync {
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(globalQueue, ^{
       // 追加任务1
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"1--------%@", [NSThread currentThread]);
        }
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    dispatch_async(globalQueue, ^{
       // 追加任务2
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"2--------%@", [NSThread currentThread]);
        }
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    dispatch_async(globalQueue, ^{
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"3------%@", [NSThread currentThread]);
        }
    });
}
- (void)semaphoreAndAsyncGroup
{
    dispatch_queue_t globalQueue = dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
}
#pragma-mark 初始化 TableView
- (void)initTableView
{
    self.nameArr = @[@"sync + 串行队列", @"sync + 并发队列", @"async + 串行队列", @"async + 并发队列", @"sync + 主队列", @"async + 主队列", @"线程间的通信", @"dispatch_barrier_async", @"dispatch_barrier_sync", @"dispatch_after", @"dispatch_once", @"groupNotify", @"groupWait", @"groupEnterAndLeave", @"semaphoreSync"].mutableCopy;
    [self.view addSubview:self.tableView];
    self.tableView.frame = self.view.bounds;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.nameArr.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellReuseIdentifier];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = self.nameArr[indexPath.row];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            [self syncSerial];
            break;
        case 1:
            [self syncConcurrent];
            break;
        case 2:
            [self asyncSrrial];
            break;
        case 3:
            [self asyncConcurrent];
            break;
        case 4:
            [self syncMain];
            break;
        case 5:
            [self asyncMainQueue];
            break;
        case 6:
            [self communication];
            break;
        case 7:
            [self dispatchAsyncBarrier];
            break;
        case 8:
            [self dispatchSyncBarrier];
            break;
        case 9:
            [self dispatchAfter];
            break;
        case 10:
            [self dispatchOnce];
            break;
        case 11:
            [self groupNotify];
            break;
        case 12:
            [self groupWait];
            break;
        case 13:
            [self groupEnterAndLeave];
            break;
        case 14:
            [self semaphoreSync];
            break;
        default:
            break;
    }
}

- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellReuseIdentifier];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.tableFooterView = [UIView new];
    }
    return _tableView;
}
@end
