/**
 * Lesson2.java
 *
 * Author: Jeff Kirby (report from Darren Hodges java port ) 
 * Date: 22/12/2001
 *
 * Port of the NeHe OpenGL Tutorial (Lesson 2: "Your First Polygon")
 * to Java using the GL4Java interface to OpenGL.
 *
 */

   import java.applet.*;
   import java.awt.*;
   import java.awt.event.*;


   public class Lesson extends Applet
   {
      //Our rendering canvas ( Customized GLAnimeCanvas, which can animate itself )
   
      NeHeCanvas canvas = null;
   
   /** void init()  Initialise the applet.  */
      public void init()
      {
         setLayout(new BorderLayout()); // Border layout so that component will use all space
         canvas = new NeHeCanvas(getSize().width, getSize().height); //Create our canvas and add it to the center of the applet
         canvas.requestFocus();        // attempt to get focus to the canvase asap ( don't work to well )
         add("Center", canvas);        // add the canvas to the applet
      }
   
   /** void start() Start the applet. */
      public void start()
      { 
         canvas.start(); /*Start animating the canvas */ 
      }
   
   
   /** void stop() Stop the applet. */
      public void stop()
      {
         canvas.stop();//Stop animating the canvas
      }
   
   
    /** void destroy() Destroy the applet. */
      public void destroy()
      {
         canvas.stop();  //Stop animating the canvas
         canvas.cvsDispose();  //Destroy the canvas
      }
   
   // Main method (This is what gets run when you run as an application) 
      public static void main( String args[] ) {
         Lesson applet = new Lesson();
         applet.setSize(640,480);
         applet.init();
         applet.start();
      
         Frame f = new Frame("NeHe Lesson2 - Your First Polygon");
         f.add(applet);
         f.pack();// make the frame the size of the Applet
         f.setVisible(true);
      
         //GLContext.gljNativeDebug = true; // if you want lots of messages, or want to know what went wrong :)
         //GLContext.gljThreadDebug = false;
         //GLContext.gljClassDebug = true;
      
      
         f.addWindowListener( // Enable the close button just to be nice
                               new WindowAdapter()
                               {
                                  public void windowClosed(WindowEvent e)
                                  {
                                     System.exit(0);
                                  }
                                  public void windowClosing(WindowEvent e)
                                  {
                                     windowClosed(e);
                                  }
                               }
                            );
      
      }
   
   
   }
