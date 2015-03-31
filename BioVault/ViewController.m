//
// ViewController.m
// BioVault
//
// Created by Mike Madsen on 2015/03/26.
// Copyright (c) 2015 Cobi Interactive. All rights reserved.
// http://www.cobiinteractive.com
//

#import "ViewController.h"
#import <LocalAuthentication/LocalAuthentication.h>

@interface ViewController ()

@property (nonatomic, strong) NSString *userInformation;

@property (weak, nonatomic) IBOutlet UITextView *textEditor;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *tryAgainButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setNotificationObservers];
}

- (void)viewDidAppear:(BOOL)animated {
    [self showPerformAuthorizationDialog];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self hideUserInformation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) setNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

-(void) clearNotificationObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)tryAgainButtonPressed:(id)sender {
    [self showPerformAuthorizationDialog];
}

-(void)showPerformAuthorizationDialog {
    
    LAContext *context = [[LAContext alloc] init];
    
    NSError *error = nil;
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        
        [self.spinner startAnimating];
        [self clearNotificationObservers];
        
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                localizedReason:@"Use Touch ID to gain access?"
                          reply:^(BOOL success, NSError *error) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  if (error) {
                                      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                      message:@"There was a problem verifying your identity."
                                                                                     delegate:nil
                                                                            cancelButtonTitle:@"Ok"
                                                                            otherButtonTitles:nil];
                                      [alert show];
                                      [self.spinner stopAnimating];
                                      self.tryAgainButton.hidden = NO;
                                      self.messageLabel.hidden = NO;
                                      
                                      return;
                                  }
                                  
                                  if (success) {
                                      // User authenticated successfully, take appropriate action
                                      [self.spinner stopAnimating];
                                      self.tryAgainButton.hidden = YES;
                                      self.messageLabel.hidden = YES;
                                      [self showUserInformation];
                                      [self setNotificationObservers];
                                  } else {
                                      [self.spinner stopAnimating];
                                      self.tryAgainButton.hidden = NO;
                                      self.messageLabel.hidden = NO;
                                      
                                      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                      message:@"You are not the device owner."
                                                                                     delegate:nil
                                                                            cancelButtonTitle:@"Ok"
                                                                            otherButtonTitles:nil];
                                      [alert show];
                                  }
                              });
                          }];
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Your device cannot authenticate using TouchID."
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
        self.tryAgainButton.hidden = YES;
        self.messageLabel.text = @"Your device cannot authenticate using TouchID.";
    }
}

-(void) hideUserInformation {
    self.userInformation = self.textEditor.text;
    [self writeUserInformationToFile];
    self.textEditor.text = @"";
    [self.textEditor resignFirstResponder];
    
    self.tryAgainButton.hidden = YES;
    self.messageLabel.hidden = YES;
}

-(void) showUserInformation {
    [self readUserInformationFromFile];
    self.textEditor.text = self.userInformation;
    [self.textEditor becomeFirstResponder];
}

-(void) writeUserInformationToFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *fileName = [NSString stringWithFormat:@"%@/userInfo.txt",
                          documentsDirectory];

    [self.userInformation writeToFile:fileName
              atomically:NO
                encoding:NSStringEncodingConversionAllowLossy
                   error:nil];
}

-(void) readUserInformationFromFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *fileName = [NSString stringWithFormat:@"%@/userInfo.txt",
                          documentsDirectory];
    self.userInformation = [[NSString alloc] initWithContentsOfFile:fileName
                                                    usedEncoding:nil
                                                           error:nil];
}

-(void) appWillResignActive:(id) sender {
    NSLog(@"appWillResignActive:");
    [self hideUserInformation];
}

-(void) appWillEnterForeground:(id) sender {
    NSLog(@"appWillEnterForeground:");
    [self showPerformAuthorizationDialog];
}

@end
