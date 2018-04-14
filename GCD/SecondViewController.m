//
//  SecondViewController.m
//  GCD
//
//  Created by wangyapu on 2018/4/11.
//  Copyright © 2018年 taoke. All rights reserved.
//

#import "SecondViewController.h"
@interface SecondViewController ()
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.imageView = [[UIImageView alloc] init];
    self.imageView.backgroundColor = [UIColor orangeColor];
    self.imageView.frame = (CGRect){0, 100, 200, 200};
    [self.view addSubview:self.imageView];
    // 创建子线程下载图片 然后回到主线程更新 UI
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *url = [NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1523450071517&di=4275f9b89267399c408dc11e953d0bec&imgtype=0&src=http%3A%2F%2Fc.hiphotos.baidu.com%2Fimage%2Fpic%2Fitem%2F9358d109b3de9c822bb66df56081800a18d843fd.jpg"];
        NSData *imageData = [NSData dataWithContentsOfURL:url];
        UIImage *image = [UIImage imageWithData:imageData];
        NSLog(@"当前线程是: %@", [NSThread currentThread]);
        // 回到主线程 刷新 UI
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = image;
        });
    });
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
