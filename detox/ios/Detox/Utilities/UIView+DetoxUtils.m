//
//  UIView+DetoxUtils.m
//  Detox
//
//  Created by Leo Natan (Wix) on 4/27/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "UIView+DetoxUtils.h"
#import "DTXAppleInternals.h"
#import "UIWindow+DetoxUtils.h"
#import "UISlider+DetoxUtils.h"
#import "UIImage+DetoxUtils.h"

@interface DTXTouchVisualizerWindow : UIWindow @end

//#ifdef DEBUG
//#define _DTXPopulateError(errOut) { NSLog(@"🤦‍♂️ %@", errOut); if(error) { *error = (errOut); } }
//#else
#define _DTXPopulateError(errOut) if(error) { *error = (errOut); }
//#endif

DTX_ALWAYS_INLINE
static id DTXJSONSafeNSNumberOrString(double d)
{
	return isnan(d) ? @"NaN" : @(d);
}

DTX_ALWAYS_INLINE
static NSDictionary* DTXInsetsToDictionary(UIEdgeInsets insets)
{
	return @{@"top": DTXJSONSafeNSNumberOrString(insets.top), @"bottom": DTXJSONSafeNSNumberOrString(insets.bottom), @"left": DTXJSONSafeNSNumberOrString(insets.left), @"right": DTXJSONSafeNSNumberOrString(insets.right)};
}

DTX_ALWAYS_INLINE
static NSDictionary* DTXRectToDictionary(CGRect rect)
{
	return @{@"x": DTXJSONSafeNSNumberOrString(rect.origin.x), @"y": DTXJSONSafeNSNumberOrString(rect.origin.y), @"width": DTXJSONSafeNSNumberOrString(rect.size.width), @"height": DTXJSONSafeNSNumberOrString(rect.size.height)};
}

DTX_ALWAYS_INLINE
static NSDictionary* DTXPointToDictionary(CGPoint point)
{
	return @{@"x": DTXJSONSafeNSNumberOrString(point.x), @"y": DTXJSONSafeNSNumberOrString(point.y)};
}

DTX_ALWAYS_INLINE
static NSString* DTXPointToString(CGPoint point)
{
	return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:DTXPointToDictionary(point) options:0 error:NULL] encoding:NSUTF8StringEncoding];
}

@import ObjectiveC;

BOOL __DTXDoulbeEqualToDouble(double a, double b)
{
	double difference = fabs(a * .00001);
	return fabs(a - b) <= difference;
}

BOOL __DTXPointEqualToPoint(CGPoint a, CGPoint b)
{
	return __DTXDoulbeEqualToDouble(floor(a.x), floor(b.x)) && __DTXDoulbeEqualToDouble(floor(a.y), floor(b.y));
}

@implementation UIView (DetoxUtils)

- (void)dtx_assertVisible
{
	[self _dtx_assertVisibleAtPoint:self.dtx_accessibilityActivationPointInViewCoordinateSpace isAtActivationPoint:YES];
}

- (void)dtx_assertHittable
{
	[self _dtx_assertHittableAtPoint:self.dtx_accessibilityActivationPointInViewCoordinateSpace isAtActivationPoint:YES];
}

- (void)dtx_assertVisibleAtPoint:(CGPoint)point
{
	[self _dtx_assertVisibleAtPoint:point isAtActivationPoint:NO];
}

- (void)dtx_assertHittableAtPoint:(CGPoint)point
{
	[self _dtx_assertHittableAtPoint:point isAtActivationPoint:NO];
}

- (void)_dtx_assertVisibleAtPoint:(CGPoint)point isAtActivationPoint:(BOOL)isAtActivationPoint
{
	NSError* error;
	BOOL assert = [self dtx_isVisibleAtPoint:point error:&error];
	
	DTXViewAssert(assert == YES, self.dtx_viewDebugAttributes, @"%@", error.localizedDescription);
}

- (void)_dtx_assertHittableAtPoint:(CGPoint)point isAtActivationPoint:(BOOL)isAtActivationPoint
{
	NSError* error;
	BOOL assert = [self dtx_isHittableAtPoint:point error:&error];
	
	DTXViewAssert(assert == YES, self.dtx_viewDebugAttributes, @"%@", error.localizedDescription);
}

- (NSString *)dtx_shortDescription
{
	return [NSString stringWithFormat:@"<%@: %p>", self.class, self];
}

- (CGRect)dtx_accessibilityFrame
{
	CGRect accessibilityFrame = self.accessibilityFrame;
	if(CGRectEqualToRect(accessibilityFrame, CGRectZero))
	{
		accessibilityFrame = [self.window.screen.coordinateSpace convertRect:self.bounds fromCoordinateSpace:self.coordinateSpace];
	}
	return accessibilityFrame;
}

- (CGRect)dtx_safeAreaBounds
{
	return UIEdgeInsetsInsetRect(self.bounds, self.safeAreaInsets);
}

- (CGPoint)dtx_accessibilityActivationPoint
{
	CGPoint activationPoint = self.accessibilityActivationPoint;
	if(CGPointEqualToPoint(activationPoint, CGPointZero))
	{
		activationPoint = [self.coordinateSpace convertPoint:CGPointMake(CGRectGetMidX(self.dtx_safeAreaBounds), CGRectGetMidY(self.dtx_safeAreaBounds)) toCoordinateSpace:self.window.screen.coordinateSpace];
	}
	return activationPoint;
}

- (CGPoint)dtx_accessibilityActivationPointInViewCoordinateSpace
{
	return [self.window.screen.coordinateSpace convertPoint:self.dtx_accessibilityActivationPoint toCoordinateSpace:self.coordinateSpace];
}

- (UIView *)dtx_hitTest:(CGPoint)point withEvent:(UIEvent *)event lookingFor:(UIView*)lookingFor
{
	return [self hitTest:point withEvent:event];
}

- (UIView *)dtx_hitVisTest:(CGPoint)point withEvent:(UIEvent *)event lookingFor:(UIView*)lookingFor
{
	return [self dtx_visTest:point withEvent:event lookingFor:lookingFor maxSize:CGSizeMake(1, 1)];
}

- (UIView*)dtx_visTest:(CGPoint)point withEvent:(UIEvent *)event lookingFor:(UIView*)lookingFor
{
	return [self dtx_visTest:point withEvent:event lookingFor:lookingFor maxSize:CGSizeMake(44, 44)];
}

- (UIView*)dtx_visTest:(CGPoint)point withEvent:(UIEvent *)event lookingFor:(UIView*)lookingFor maxSize:(CGSize)maxSize
{
	if(self.isHiddenOrHasHiddenAncestor == YES)
	{
		return nil;
	}

	if(self.alpha == 0.0)
	{
		return nil;
	}
	
	if(self.clipsToBounds == YES && [self pointInside:point withEvent:event] == NO)
	{
		return nil;
	}

	if(self == lookingFor)
	{
		//Take a shortcut here, because we found ourselves
		return self;
	}

	UIView* rv;

	//Front-most views get priority
	for (__kindof UIView * _Nonnull obj in self.subviews.reverseObjectEnumerator) {
		CGPoint localPoint = [self convertPoint:point toView:obj];

		UIView* candidate = [obj dtx_visTest:localPoint withEvent:event lookingFor:lookingFor maxSize:maxSize];

		if(candidate == nil)
		{
			continue;
		}

		rv = candidate;
		break;
	}
	
	if(rv == nil && CGRectGetWidth(self.bounds) > 0 && CGRectGetHeight(self.bounds) > 0)
	{
		//Check the candidate view for transparency
		UIImage* img = [self dtx_imageAroundPoint:point maxSize:CGSizeMake(MIN(lookingFor.bounds.size.width, maxSize.width), MIN(lookingFor.bounds.size.height, maxSize.height))];
		if([img dtx_isTransparentEnoughWithThreshold:0.5] == NO)
		{
#if DEBUG
//			[self.window dtx_saveSnapshotToDesktopWithPoint:[self.window convertPoint:point fromView:self]];
//			[img dtx_saveToDesktop];
#endif
			//If a view is not transparent around the hit point, take it as the visible view.
			rv = self;
		}
	}

	return rv;
}

- (BOOL)dtx_isVisible
{
	return [self dtx_isVisibleAtPoint:self.dtx_accessibilityActivationPointInViewCoordinateSpace];
}

- (BOOL)dtx_isHittable
{
	return [self dtx_isHittableAtPoint:self.dtx_accessibilityActivationPointInViewCoordinateSpace];
}

- (BOOL)dtx_isVisibleAtPoint:(CGPoint)point
{
	return [self dtx_isVisibleAtPoint:point error:NULL];
}

- (BOOL)dtx_isVisibleAtPoint:(CGPoint)point error:(NSError* __strong *)error
{
	return [self _dtx_someTestAtPoint:point testSelector:@selector(dtx_visTest:withEvent:lookingFor:) error:error];
}

- (BOOL)dtx_isHittableAtPoint:(CGPoint)point
{
	return [self dtx_isHittableAtPoint:point error:NULL];
}

- (BOOL)dtx_isHittableAtPoint:(CGPoint)point error:(NSError* __strong *)error
{
	return [self _dtx_someTestAtPoint:point testSelector:@selector(dtx_hitVisTest:withEvent:lookingFor:) error:error];
}

- (BOOL)dtx_isActuallyHittableAtPoint:(CGPoint)point error:(NSError* __strong *)error
{
	if([self isKindOfClass:NSClassFromString(@"UISegmentLabel")] || [self isKindOfClass:NSClassFromString(@"UISegment")])
	{
		UISegmentedControl* segmentControl = (id)self;
		while(segmentControl != nil && [segmentControl isKindOfClass:UISegmentedControl.class] == NO)
		{
			segmentControl = (id)segmentControl.superview;
		}

		return [segmentControl dtx_isHittableAtPoint:[segmentControl convertPoint:point fromView:self] error:error];
	}
	
	if([self isKindOfClass:NSClassFromString(@"UIButtonLabel")])
	{
		UIView* button = (id)self;
		while(button != nil && [button isKindOfClass:UIButton.class] == NO)
		{
			button = (id)button.superview;
		}
		
		if([button isKindOfClass:NSClassFromString(@"_UIModernBarButton")] && button.userInteractionEnabled == NO && [button.superview isKindOfClass:NSClassFromString(@"_UIButtonBarButton")])
		{
			button = (id)button.superview;
		}
		
		return [button dtx_isHittableAtPoint:[button convertPoint:point fromView:self] error:error];
	}
	
	if([self isKindOfClass:UILabel.class] && [self.dtx_containingViewController isKindOfClass:UIAlertController.class])
	{		
		return YES;
	}
	
	return [self _dtx_someTestAtPoint:point testSelector:@selector(dtx_hitTest:withEvent:lookingFor:) error:error];
}

#define APPLY_PREFIX(...) [NSString stringWithFormat:@"%@ %@", prefix, __VA_ARGS__]

- (BOOL)_dtx_someTestAtPoint:(CGPoint)point testSelector:(SEL)selector error:(NSError* __strong *)error
{
	BOOL isHit = (selector == @selector(dtx_hitTest:withEvent:lookingFor:));
	NSString* prefix = [NSString stringWithFormat:@"View “%@” is not %@ at point “%@”;", self.dtx_shortDescription, isHit ? @"hittable" : @"visible", DTXPointToString(point)];
	
	if(UIApplication.sharedApplication._isSpringBoardShowingAnAlert)
	{
		_DTXPopulateError([NSError errorWithDomain:@"DetoxErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey: APPLY_PREFIX(@"System alert is shown on screen")}]);
		
		return NO;
	}
	
	if(self.window == nil || self.window.screen == nil)
	{
		_DTXPopulateError([NSError errorWithDomain:@"DetoxErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey: APPLY_PREFIX(@"Either window or screen are nil")}]);
		
		return NO;
	}
	
	if(@available(iOS 13.0, *))
	{
		if(self.window.windowScene == nil)
		{
			_DTXPopulateError([NSError errorWithDomain:@"DetoxErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey: APPLY_PREFIX(@"Window scene is nil")}]);
			return NO;
		}
	}
	
	//Point in window coordinate space
	UIScreen* screen = self.window.screen;
	CGPoint screenActivationPoint = [self convertPoint:point toCoordinateSpace:screen.coordinateSpace];
	CGPoint windowActivationPoint = [self.window convertPoint:point fromView:self];
	
	if(CGRectContainsPoint(self.window.bounds, windowActivationPoint) == NO)
	{
		NSError* err = [NSError errorWithDomain:@"DetoxErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey: APPLY_PREFIX([NSString stringWithFormat:@"Point “%@” is outside of window bounds", DTXPointToString(windowActivationPoint)])}];
		_DTXPopulateError(err);
		
		return NO;
	}
	
	if(CGRectGetWidth(self.dtx_safeAreaBounds) == 0 || CGRectGetHeight(self.dtx_safeAreaBounds) == 0)
	{
		_DTXPopulateError([NSError errorWithDomain:@"DetoxErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey: APPLY_PREFIX(@"View safe area bounds are empty")}]);
		
		return NO;
	}
	
	if([self isHiddenOrHasHiddenAncestor] == YES)
	{
		_DTXPopulateError([NSError errorWithDomain:@"DetoxErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey: APPLY_PREFIX(@"View is hidden or has hidden ancestor")}]);
		
		return NO;
	}
	
	__block BOOL rv = NO;

	if(isHit && self.userInteractionEnabled == NO)
	{
		_DTXPopulateError([NSError errorWithDomain:@"DetoxErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey: APPLY_PREFIX(@"View has user interaction disabled (userInteractionEnabled == NO)")}]);

		return NO;
	}
	
	id (*testFunc)(id, SEL, CGPoint, id, id) = (void*)objc_msgSend;
	
	id scene = nil;
	if(@available(iOS 13.0, *))
	{
		scene = self.window.windowScene;
	}
	
	[UIWindow dtx_enumerateWindowsInScene:scene usingBlock:^(UIWindow * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if(obj.screen != screen)
		{
			//Irrelevant window, ignore
			return;
		}
		
		if([obj isKindOfClass:DTXTouchVisualizerWindow.class])
		{
			return;
		}
		
		CGPoint currentWindowActivationPoint = [screen.coordinateSpace convertPoint:screenActivationPoint toCoordinateSpace:obj.coordinateSpace];
		
		if(self.window != obj && isHit == NO)
		{
			UIImage* windowImage = [obj dtx_imageAroundPoint:currentWindowActivationPoint maxSize:self.window.bounds.size];
//			[UIImagePNGRepresentation(windowImage) writeToFile:[NSString stringWithFormat:@"/Users/lnatan/Desktop/%@.png", NSStringFromClass(obj.class)] atomically:YES];
			if([windowImage dtx_isTransparentEnoughWithThreshold:0.5] == NO)
			{
#if DEBUG
//				[windowImage dtx_saveToDesktop];
#endif
				
				NSError* err = [NSError errorWithDomain:@"DetoxErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey: APPLY_PREFIX([NSString stringWithFormat:@"Window “%@” is above the tested view's window and its transparency around point “%@” is below the tested threshold (0.5)", obj.dtx_shortDescription, DTXPointToString(currentWindowActivationPoint)])}];
				_DTXPopulateError(err);
				
				//The window is not transparent at the hit point, stop
				rv = NO;
				*stop = YES;
				return;
			}
			else
			{
				//The window is transparent at the hit point, continue to next window
				return;
			}
		}
		
		UIView* visibleView = testFunc(obj, selector, currentWindowActivationPoint, nil, self);
		
		if(self.window != obj && isHit == YES)
		{
			if(visibleView != nil)
			{
				NSError* err = [NSError errorWithDomain:@"DetoxErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey: APPLY_PREFIX([NSString stringWithFormat:@"Another view “%@” is hittable in window “%@” at window point “%@”", visibleView.dtx_shortDescription, obj.dtx_shortDescription, DTXPointToString(currentWindowActivationPoint)])}];
				_DTXPopulateError(err);
				
				//We've hit a view in another window
				rv = NO;
				*stop = YES;
			}
			return;
		}
		
		NSAssert(self.window == obj, @"Detox logic failure!");
		*stop = YES;
		
		if(visibleView == self || [visibleView isDescendantOfView:self])
		{
			rv = YES;
		}
		else
		{
			rv = NO;
			NSString* str = isHit ? @"hittable" : @"visible";
			
			if(visibleView == nil)
			{
				NSError* err = [NSError errorWithDomain:@"DetoxErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey: APPLY_PREFIX([NSString stringWithFormat:@"No view is %@ at window point “%@”", str, DTXPointToString(windowActivationPoint)])}];
				_DTXPopulateError(err);
			}
			else
			{
				NSError* err;
				if(isHit)
				{
					err = [NSError errorWithDomain:@"DetoxErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey: APPLY_PREFIX([NSString stringWithFormat:@"Another view “%@” is hittable at window point “%@”", visibleView.dtx_shortDescription, DTXPointToString(currentWindowActivationPoint)])}];
				}
				else
				{
					err = [NSError errorWithDomain:@"DetoxErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey: APPLY_PREFIX([NSString stringWithFormat:@"View “%@” is above the tested view “%@”'s screen position and its transparency around window point “%@” is below the tested threshold (0.5)", visibleView.dtx_shortDescription, self.dtx_shortDescription, DTXPointToString(currentWindowActivationPoint)])}];
				}
				_DTXPopulateError(err);
			}
			
			return;
		}
	}];
	
	return rv;
}

- (UIImage*)dtx_imageAroundPoint:(CGPoint)point maxSize:(CGSize)maxSize
{
	static const CGFloat maxDimension = 44;
	CGFloat width = ceil(MIN(maxDimension, maxSize.width));
	CGFloat height = ceil(MIN(maxDimension, maxSize.height));
	CGFloat x = point.x - width / 2.0;
	CGFloat y = point.y - height / 2.0;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
	if (colorSpace == NULL)
	{
		return nil;
	}
	dtx_defer {
		CGColorSpaceRelease(colorSpace);
	};
	
	CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, width * 4, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
	if(context == NULL)
	{
		return nil;
	}
	dtx_defer {
		CGContextRelease(context);
	};
	
	UIGraphicsPushContext(context);
	
	CGContextTranslateCTM(context, -x, -y);
	
	[self.layer.presentationLayer renderInContext:context];
	
	UIGraphicsPopContext();
	
	CGImageRef imageRef = CGBitmapContextCreateImage(context);
	dtx_defer {
		CGImageRelease(imageRef);
	};
	
	UIImage* image = [UIImage imageWithCGImage:imageRef];
	
	return image;
}

- (NSDictionary<NSString *,id> *)dtx_attributes
{
	NSMutableDictionary* rv = [NSMutableDictionary new];
	
	NSDictionary* results = [self dictionaryWithValuesForKeys:@[@"text", @"accessibilityLabel", @"accessibilityIdentifier", @"accessibilityValue", @"placeholder"]];
	[results enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
		if([obj isKindOfClass:NSNull.class])
		{
			return;
		}
		
		if([key isEqualToString:@"accessibilityLabel"])
		{
			rv[@"label"] = obj;
		}
		else if([key isEqualToString:@"accessibilityValue"])
		{
			rv[@"value"] = obj;
		}
		else if([key isEqualToString:@"accessibilityIdentifier"])
		{
			rv[@"identifier"] = obj;
		}
		else
		{
			rv[key] = obj;
		}
	}];
	
	BOOL enabled = self.userInteractionEnabled;
	if([self isKindOfClass:UIControl.class])
	{
		enabled = enabled && [[self valueForKey:@"enabled"] boolValue];
	}
	rv[@"enabled"] = enabled ? @YES : @NO;
	
	rv[@"frame"] = DTXRectToDictionary(self.dtx_accessibilityFrame);
	rv[@"elementFrame"] = DTXRectToDictionary(self.frame);
	rv[@"elementBounds"] = DTXRectToDictionary(self.bounds);
	rv[@"safeAreaInsets"] = DTXInsetsToDictionary(self.safeAreaInsets);
	rv[@"elementSafeBounds"] = DTXRectToDictionary(self.dtx_safeAreaBounds);
	
	CGPoint accessibilityActivationPointInViewCoordinateSpace = self.dtx_accessibilityActivationPointInViewCoordinateSpace;
	rv[@"activationPoint"] = DTXPointToDictionary(accessibilityActivationPointInViewCoordinateSpace);
	rv[@"normalizedActivationPoint"] = DTXPointToDictionary(CGPointMake(CGRectGetWidth(self.bounds) == 0 ? 0 : accessibilityActivationPointInViewCoordinateSpace.x / CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) == 0 ? 0 : accessibilityActivationPointInViewCoordinateSpace.y / CGRectGetHeight(self.bounds)));
	
	rv[@"hittable"] = self.dtx_isHittable ? @YES : @NO;
	rv[@"visible"] = self.dtx_isVisible ? @YES : @NO;
	
	if([self isKindOfClass:UISlider.class])
	{
		rv[@"normalizedSliderPosition"] = @([(UISlider*)self dtx_normalizedSliderPosition]);
	}
	
	if([self isKindOfClass:UIDatePicker.class])
	{
		UIDatePicker* dp = (id)self;
		rv[@"date"] = [NSISO8601DateFormatter stringFromDate:dp.date timeZone:dp.timeZone ?: NSTimeZone.systemTimeZone formatOptions:NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithDashSeparatorInDate | NSISO8601DateFormatWithColonSeparatorInTime | NSISO8601DateFormatWithColonSeparatorInTimeZone];
		NSDateComponents* dc = [dp.calendar componentsInTimeZone:dp.timeZone ?: NSTimeZone.systemTimeZone fromDate:dp.date];
		
		NSMutableDictionary* dateComponents = [NSMutableDictionary new];
		dateComponents[@"era"] = @(dc.era);
		dateComponents[@"year"] = @(dc.year);
		dateComponents[@"month"] = @(dc.month);
		dateComponents[@"day"] = @(dc.day);
		dateComponents[@"hour"] = @(dc.hour);
		dateComponents[@"minute"] = @(dc.minute);
		dateComponents[@"second"] = @(dc.second);
		dateComponents[@"weekday"] = @(dc.weekday);
		dateComponents[@"weekdayOrdinal"] = @(dc.weekdayOrdinal);
		dateComponents[@"quarter"] = @(dc.quarter);
		dateComponents[@"weekOfMonth"] = @(dc.weekOfMonth);
		dateComponents[@"weekOfYear"] = @(dc.weekOfYear);
		dateComponents[@"leapMonth"] = @(dc.leapMonth);
		
		rv[@"dateComponents"] = dateComponents;
	}
	
	return rv;
}

- (NSDictionary<NSString *,id> *)dtx_viewDebugAttributes
{
	NSMutableDictionary* rv = [NSMutableDictionary new];
	
	if(self.window != nil)
	{
		rv[@"viewHierarchy"] = self.window.recursiveDescription;
	}
	
	rv[@"elementAttributes"] = [self dtx_attributes];
	rv[@"viewDescription"] = self.description;
	
	return rv;
}

- (UIViewController *)dtx_containingViewController
{
	UIViewController* rv = (id)self.nextResponder;
	while(rv != nil && [rv isKindOfClass:UIViewController.class] == NO)
	{
		rv = (id)rv.nextResponder;
	}
	
	return rv;
}

#if DEBUG
- (void)dtx_saveSnapshotToDesktop
{
	[self _dtx_saveSnapshotToDesktopWithPointPtr:NULL];
}

- (void)dtx_saveSnapshotToDesktopWithPoint:(CGPoint)point
{
	[self _dtx_saveSnapshotToDesktopWithPointPtr:&point];
}

- (void)_dtx_saveSnapshotToDesktopWithPointPtr:(CGPoint*)pointPtrOrNULL
{
	UIWindow* windowToUse = [self isKindOfClass:UIWindow.class] ? (id)self : self.window;
	UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, windowToUse.screen.scale);
	[self drawViewHierarchyInRect:self.bounds afterScreenUpdates:NO];
	
	if(pointPtrOrNULL != NULL)
	{
		CGContextRef ctx = UIGraphicsGetCurrentContext();
		[UIColor.systemRedColor setFill];
		CGContextFillRect(ctx, CGRectMake(pointPtrOrNULL->x, pointPtrOrNULL->y, 1, 1));
	}
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	[image dtx_saveToDesktop];
}
#endif

@end
