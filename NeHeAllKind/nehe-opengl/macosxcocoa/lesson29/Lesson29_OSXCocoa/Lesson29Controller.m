/*
 * Original Windows comment:
 * "The OpenGL Basecode Used In This Project Was Created By
 * Jeff Molofee ( NeHe ).  1997-2000.  If You Find This Code
 * Useful, Please Let Me Know.
 *
 * Original Code & Tutorial Text By Andreas L�ffler
 * Excellent Job Andreas!
 *
 * Code Heavily Modified By Rob Fletcher ( rpf1@york.ac.uk )
 * Proper Image Structure, Better Blitter Code, Misc Fixes
 * Thanks Rob!
 *
 * 0% CPU Usage While Minimized Thanks To Jim Strong
 * ( jim@scn.net ).  Thanks Jim!
 *
 * This Code Also Has The ATI Fullscreen Fix!
 *
 * Visit Me At nehe.gamedev.net"
 *
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson29Controller.m */

#import "Lesson29Controller.h"

@interface Lesson29Controller (InternalMethods)
- (void) setupRenderTimer;
- (void) updateGLView:(NSTimer *)timer;
- (void) createFailed;
@end

@implementation Lesson29Controller

- (void) awakeFromNib
{  
   [ NSApp setDelegate:self ];   // We want delegate notifications
   renderTimer = nil;
   [ glWindow makeFirstResponder:self ];
   glView = [ [ Lesson29View alloc ] initWithFrame:[ glWindow frame ]
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
      [ glView drawRect:[ glView frame ] ];
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
      // Handle key presses here
   }
}


/*
 * Set full screen.
 */
- (IBAction) setFullScreen:(id)sender
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
