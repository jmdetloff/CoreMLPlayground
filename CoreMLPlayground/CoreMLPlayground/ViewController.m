//
//  ViewController.m
//  CoreMLPlayground
//
//  Created by John Detloff on 8/5/22.
//

#import <CoreML/CoreML.h>

#import "ViewController.h"

#import "mobilenetv2.h"
#import "mobilenetv2_flexible.h"
#import "mobilenetv2_enumerated.h"
#include <stdlib.h>

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
    
    UIButton *cpuDemoButton = [[UIButton alloc] initWithFrame:CGRectMake(50, 250, 300, 50)];
    [cpuDemoButton setTitle:@"Load for CPU" forState:UIControlStateNormal];
    [cpuDemoButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    cpuDemoButton.layer.borderColor = [UIColor blackColor].CGColor;
    cpuDemoButton.layer.cornerRadius = 15;
    cpuDemoButton.layer.borderWidth = 2;
    [self.view addSubview:cpuDemoButton];
    
    [cpuDemoButton addTarget:self action:@selector(demoPressedCPUOnly) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *inputDemoButton = [[UIButton alloc] initWithFrame:CGRectMake(50, 400, 300, 50)];
    [inputDemoButton setTitle:@"Benchmark input types" forState:UIControlStateNormal];
    [inputDemoButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    inputDemoButton.layer.borderColor = [UIColor blackColor].CGColor;
    inputDemoButton.layer.cornerRadius = 15;
    inputDemoButton.layer.borderWidth = 2;
    [self.view addSubview:inputDemoButton];
    
    [inputDemoButton addTarget:self action:@selector(demoPressedInputs) forControlEvents:UIControlEventTouchUpInside];
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

- (void)demoPressedInputs {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *shape = @[@(1), @(3), @(224), @(224)];
        
        int testCount = 1000;
        
        CFAbsoluteTime totalTime = 0;
        
        mobilenetv2 *model = [[mobilenetv2 alloc] init];
        for (int i = 0; i < testCount; i++) {
            MLMultiArray *randInput = [[MLMultiArray alloc] initWithShape:shape dataType:MLMultiArrayDataTypeFloat32 error:nil];
            [self rand:randInput];
            mobilenetv2Input *input = [[mobilenetv2Input alloc] initWithX_1:randInput];
            CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
            mobilenetv2Output *output = [model predictionFromFeatures:input error:nil];
            CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
            totalTime += endTime - startTime;
        }
        NSLog(@"*** Model inference time: %f", totalTime / testCount);
        
        totalTime = 0;
        
        mobilenetv2_enumerated *enumeratedModel = [[mobilenetv2_enumerated alloc] init];
        for (int i = 0; i < testCount; i++) {
            MLMultiArray *randInput = [[MLMultiArray alloc] initWithShape:shape dataType:MLMultiArrayDataTypeFloat32 error:nil];
            [self rand:randInput];
            mobilenetv2_enumeratedInput *input = [[mobilenetv2_enumeratedInput alloc] initWithX_1:randInput];
            CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
            mobilenetv2_enumeratedOutput *output = [enumeratedModel predictionFromFeatures:input error:nil];
            CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
            totalTime += endTime - startTime;
        }
        NSLog(@"*** Enumerated Input Model inference time: %f", totalTime / testCount);
        
        totalTime = 0;
        
        mobilenetv2_flexible *flexibleModel = [[mobilenetv2_flexible alloc] init];
        for (int i = 0; i < testCount; i++) {
            MLMultiArray *randInput = [[MLMultiArray alloc] initWithShape:shape dataType:MLMultiArrayDataTypeFloat32 error:nil];
            [self rand:randInput];
            mobilenetv2_flexibleInput *input = [[mobilenetv2_flexibleInput alloc] initWithX_1:randInput];
            CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
            mobilenetv2_flexibleOutput *output = [flexibleModel predictionFromFeatures:input error:nil];
            CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
            totalTime += endTime - startTime;
        }
        NSLog(@"*** Flexible Input Model inference time: %f", totalTime / testCount);
    });
}

- (void)rand:(MLMultiArray *)array
{
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 224; j++) {
            for (int k = 0; k < 224; k++) {
                array[0, i, j, k] = @((double)arc4random() / UINT32_MAX);
            }
        }
    }
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
