
#import <EarlGrey/GREYConstants.h>
#import <EarlGrey/GREYDefines.h>
#import <Foundation/Foundation.h>

@protocol GREYAction;

/**
 *  A interface that exposes UI element actions.
 */
@interface GREYActions : NSObject

// Single Line Comment here
+ (id<GREYAction>)actionForMultipleTapsWithCount:(NSUInteger)count;

/**
 * Multi Line Comment here
 * Awesome
 */
+ (id<GREYAction>)actionForMultipleTapsWithCount:(NSUInteger)count atPoint:(CGPoint)point;

/**
 *  Returns a scroll action that scrolls in a @c direction for an @c amount of points starting from
 *  the given start point specified as percentages. @c xOriginStartPercentage is the x start
 *  position as a percentage of the total width of the scrollable visible area,
 *  @c yOriginStartPercentage is the y start position as a percentage of the total height of the
 *  scrollable visible area. @c xOriginStartPercentage and @c yOriginStartPercentage must be between
 *  0 and 1, exclusive.
 *
 *  @param direction              The direction of the scroll.
 *  @param amount                 The amount scroll in points to inject.
 *  @param xOriginStartPercentage X coordinate of the start point specified as a percentage (0, 1)
 *                                exclusive, of the total width of the scrollable visible area.
 *  @param yOriginStartPercentage Y coordinate of the start point specified as a percentage (0, 1)
 *                                exclusive, of the total height of the scrollable visible area.
 *
 *  @return A GREYAction that scrolls a scroll view in a given @c direction for a given @c amount
 *          starting from the given start points.
 */
+ (id<GREYAction>)actionForScrollInDirection:(GREYDirection)direction
                                      amount:(CGFloat)amount
                      xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                      yOriginStartPercentage:(CGFloat)yOriginStartPercentage;
