//
//  ViewController.m
//  CoreMLPlayground
//
//  Created by John Detloff on 8/5/22.
//

#import <CoreML/CoreML.h>

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *allDemoButton = [[UIButton alloc] initWithFrame:CGRectMake(50, 100, 300, 50)];
    [allDemoButton setTitle:@"Load for All Units" forState:UIControlStateNormal];
    [allDemoButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    allDemoButton.layer.borderColor = [UIColor blackColor].CGColor;
    allDemoButton.layer.cornerRadius = 15;
    allDemoButton.layer.borderWidth = 2;
    [self.view addSubview:allDemoButton];
    
    [allDemoButton addTarget:self action:@selector(demoPressedAllComputeUnits) forControlEvents:UIControlEventTouchUpInside];
    
    
    UIButton *cpuDemoButton = [[UIButton alloc] initWithFrame:CGRectMake(50, 300, 300, 50)];
    [cpuDemoButton setTitle:@"Load for CPU" forState:UIControlStateNormal];
    [cpuDemoButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    cpuDemoButton.layer.borderColor = [UIColor blackColor].CGColor;
    cpuDemoButton.layer.cornerRadius = 15;
    cpuDemoButton.layer.borderWidth = 2;
    [self.view addSubview:cpuDemoButton];
    
    [cpuDemoButton addTarget:self action:@selector(demoPressedCPUOnly) forControlEvents:UIControlEventTouchUpInside];
}

- (void)demoPressedAllComputeUnits {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self _loadModelDemo:MLComputeUnitsAll];
    });
}

- (void)demoPressedCPUOnly {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self _loadModelDemo:MLComputeUnitsCPUOnly];
    });
}


- (void)_loadModelDemo:(MLComputeUnits)computeUnits {
    NSError *error;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *modelName = @"DeepLabV3";
    NSString *modelPath = [documentsDirectory stringByAppendingPathComponent:modelName];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    NSURL *compiledModelURL = [modelURL URLByAppendingPathExtension:@"mlmodelc"];
    
    BOOL alreadyCompiledAndCached = [[NSFileManager defaultManager] fileExistsAtPath:compiledModelURL.path];
    
    if (!alreadyCompiledAndCached) {
        // Download and save model.
        NSString *remotePath = @"https://ml-assets.apple.com/coreml/models/Image/ImageSegmentation/DeepLabV3/DeepLabV3.mlmodel";
        NSURL *remoteURL = [NSURL URLWithString:remotePath];
        NSData *modelData = [NSData dataWithContentsOfURL:remoteURL];
        [modelData writeToFile:modelPath atomically:YES];
        
        // Compile and cache
        NSURL *temporaryURL = [MLModel compileModelAtURL:modelURL error:&error];
        [[NSFileManager defaultManager] moveItemAtURL:temporaryURL toURL:compiledModelURL error:&error];
    }
    
    // Load the MLModel instance from the cached compiled model file
    MLModelConfiguration* config = [[MLModelConfiguration alloc] init];
    config.computeUnits = computeUnits;
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    MLModel *model = [MLModel modelWithContentsOfURL:compiledModelURL configuration:config error:&error];
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
    NSLog(@"*** Model load duration: %f", endTime - startTime);
}

@end
