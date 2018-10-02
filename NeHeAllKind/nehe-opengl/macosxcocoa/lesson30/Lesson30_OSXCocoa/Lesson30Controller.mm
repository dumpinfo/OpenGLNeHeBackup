/*
 * Original Windows comment:
 * "Programmer: Dimitrios Christopoulos
 *
 * Windows Frame Code Was Published By Jeff Molofee 2000
 * Code Was Created By David Nikdel For NeHe Productions
 * If You've Found This Code Useful, Please Let Me Know.
 * Visit My Site At nehe.gamedev.net"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson30Controller.mm */

#import "Lesson30Controller.h"

@interface Lesson30Controller (InternalMethods)
- (void) setupRenderTimer;
- (void) updateGLView:(NSTimer *)timer;
- (void) createFailed;
@end

@implementation Lesson30Controller

- (void) awakeFromNib
{  
   [ NSApp setDelegate:self ];   // We want delegate notifications
   renderTimer = nil;
   [ glWindow makeFirstResponder:self ];
   glView = [ [ Lesson30View alloc ] initWithFrame:[ glWindow frame ]
              colorBits:16 depthBits:16 fullscreen:FALSE ];
   if( glView != nil )
   {
      [ glWindow setContentView:glView ];
      [ glWindow makeKeyAndOrderFront:self ];
      [ self setupRenderTimer ];
   }
   else
      [ self createFailed ];
}


/*
 * Setup timer to update the OpenGL view.
 */
- (void) setupRenderTimer
{
   NSTimeInterval timeInterval = 0.005;

   renderTimer = [ [ NSTimer scheduledTimerWithTimeInterval:timeInterval
                             target:self
                             selector:@selector( updateGLView: )
                             userInfo:nil repeats:YES ] retain ];
   [ [ NSRunLoop currentRunLoop ] addTimer:renderTimer
                                  forMode:NSEventTrackingRunLoopMode ];
   [ [ NSRunLoop currentRunLoop ] addTimer:renderTimer
                                  forMode:NSModalPanelRunLoopMode ];
}


/*
 * Called by the rendering timer.
 */
- (void) updateGLView:(NSTimer *)timer
{
   if( glView != nil )
   {
      [ glView advanceSimulation ];
      [ glView drawRect:[ glView frame ] ];
   }
}


/*
 * Handle key presses
 */
- (void) keyDown:(NSEvent *)theEvent
{
   unichar unicodeKey;

   unicodeKey = [ [ theEvent characters ] characterAtIndex:0 ];
   switch( unicodeKey )
   {
      case NSUpArrowFunctionKey:
         [ glView decreaseCameraPos ];
         break;

      case NSDownArrowFunctionKey:
         [ glView increaseCameraPos ];
         break;

      case NSLeftArrowFunctionKey:
         [ glView decreaseCameraRot ];
         break;

      case NSRightArrowFunctionKey:
         [ glView increaseCameraRot ];
         break;

      case '+':
      case '=':
         [ glView increaseTime ];
         break;

      case '-':
         [ glView decreaseTime ];
         break;

      case NSF3FunctionKey:
         [ glView toggleSounds ];
         break;

      case NSF2FunctionKey:
         [ glView toggleHook ];
         break;

      case NSF1FunctionKey:
         [ self setFullScreen:self ];
         break;
   }
}


/*
 * Set full screen.
 */
- (IBAction)setFullScreen:(id)sender
{
   [ glWindow setContentView:nil ];
   if( [ glView isFullScreen ] )
   {
      if( ![ glView setFullScreen:FALSE inFrame:[ glWindow frame ] ] )
         [ self createFailed ];
      else
         [ glWindow setContentView:glView ];
   }
   else
   {
      if( ![ glView setFullScreen:TRUE
                    inFrame:NSMakeRect( 0, 0, 800, 600 ) ] )
         [ self createFailed ];
   }
}


/*
 * Called if we fail to create a valid OpenGL view
 */
- (void) createFailed
{
   NSWindow *infoWindow;

   infoWindow = NSGetCriticalAlertPanel( @"Initialization failed",
                                         @"Failed to initialize OpenGL",
                                         @"OK", nil, nil );
   [ NSApp runModalForWindow:infoWindow ];
   [ infoWindow close ];
   [ NSApp terminate:self ];
}


/*
 * Cleanup
 */
- (void) dealloc
{
   [ glWindow release ];
   [ glView release ];
   if( renderTimer != nil && [ renderTimer isValid ] )
      [ renderTimer invalidate ];
}

@end
