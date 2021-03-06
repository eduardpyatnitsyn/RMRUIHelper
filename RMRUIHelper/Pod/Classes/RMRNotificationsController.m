//
//  RMRNotificationsController.m
//  RMRUIHelper
//
//  Created by Roman Churkin on 16/02/15.
//  Copyright (c) 2014 Redmadrobot. All rights reserved.
//

#import "RMRNotificationsController.h"

#import "RMRPassthroughViewController.h"
#import "RMRPassthroughWindow.h"


@interface RMRNotificationsController ()

#pragma mark - Properties

@property (nonatomic, strong) UIWindow *modalWindow;

@property (nonatomic, strong) UIViewController *modalViewController;

@property (nonatomic, strong) UIView<RMRModalView> *currentView;

@property (nonatomic, strong) NSMutableArray *viewStack;

@end


@implementation RMRNotificationsController

static RMRNotificationsController *sharedNotificationsController;


#pragma mark - Initialization

+ (void)initialize
{
    sharedNotificationsController = [[RMRNotificationsController alloc] init];
    sharedNotificationsController.viewStack = [NSMutableArray array];
}


#pragma mark - Accessors / Mutators

- (UIViewController *)modalViewController
{
    if (_modalViewController) return _modalViewController;

    UIViewController *modalViewController = [RMRPassthroughViewController new];
    _modalViewController = modalViewController;

    return _modalViewController;
}

- (UIWindow *)modalWindow
{
    if (_modalWindow) return _modalWindow;

    CGRect frame = [self mainAppWindow].bounds;

    UIWindow *window = [[RMRPassthroughWindow alloc] initWithFrame:frame];
    window.rootViewController = self.modalViewController;
    window.windowLevel = UIWindowLevelStatusBar + 1;
    window.hidden = YES;

    _modalWindow = window;
    return _modalWindow;
}


#pragma mark - Private helpers

- (UIWindow *)mainAppWindow { return [[[UIApplication sharedApplication] delegate] window]; }

- (void)hideCurrentViewCompletion:(void(^)())completion
{
    UIView <RMRModalView> *currentView = self.currentView;

    void (^animations)() = ^{ [currentView animationHide]; };
    void (^animationCompletion)(BOOL) = ^(BOOL finished) {
        self.modalWindow.hidden = YES;
        self.currentView = nil;
        if (completion) completion();
    };

    if ([currentView respondsToSelector:@selector(customHideAnimation:completion:)]) {
        [currentView customHideAnimation:animations
                              completion:animationCompletion];
    } else {
        [UIView animateWithDuration:.45
                              delay:0.
             usingSpringWithDamping:.7f
              initialSpringVelocity:.1f
                            options:0
                         animations:animations
                         completion:animationCompletion];
    }
}

- (void)showView:(UIView<RMRModalView> *)view
{
    self.currentView = view;

    [self prepareAppearenceForView:view];

    self.modalWindow.hidden = NO;

    [view prepareForAnimation];

    void (^animations)() = ^{ [view animationAppear]; };

    if ([view respondsToSelector:@selector(customShowAnimation:)]) {
        [view customShowAnimation:animations];
    } else {
        [UIView animateWithDuration:.25
                              delay:0.05
             usingSpringWithDamping:.8f
              initialSpringVelocity:.1f
                            options:0
                         animations:animations
                         completion:nil];
    }
}

- (void)prepareAppearenceForView:(UIView<RMRModalView> *)view
{
    UIView *modalView = self.modalViewController.view;
    modalView.translatesAutoresizingMaskIntoConstraints = NO;
    [modalView addSubview:view];

    [view configureLayoutForContainer:modalView];

    [modalView layoutIfNeeded];
}


#pragma mark - Public

+ (instancetype)sharedController { return sharedNotificationsController; }

- (void)presentView:(UIView<RMRModalView> *)modalView
{
    if ([self.viewStack.lastObject isEqual:modalView])
        return;

    modalView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.viewStack addObject:modalView];

    if (self.currentView) [self hideCurrentViewCompletion:^{ [self showView:modalView]; }];
    else [self showView:modalView];
}

- (void)dismissView:(UIView *)modalView completion:(void(^)())completion
{
    void (^final)() = ^{
        [self.viewStack removeObject:modalView];
        [modalView removeFromSuperview];
        if (completion) completion();
        if ([self.viewStack count] > 0) [self presentView:[self.viewStack lastObject]];
    };

    if (self.currentView == modalView) [self hideCurrentViewCompletion:^{ final(); }];
    else final();
}

- (UIView *)viewOnScreen { return self.currentView; }

@end
