/* Author: Victor Gonzalez Jr
 * Created on Oct 11, 2003
 *
 * Port of the NeHe OpenGL Tutorial (Lesson 3: Adding Color)
 * to Java using the IBM's SWT OpenGL plugin.
 * 
 * The tutorial is written to match the NeHe HTML lesson as closely as
 * possible. Code and comments should be nearly identical. With the exception
 * of a few Java specific comments and OpenGL commands starting with 'GL.' 
 * 
 * Visit nehe.gamedev.net for more lessons.
 */
package org.nehe.lesson3;

import org.eclipse.swt.SWT;
import org.eclipse.swt.events.*;
import org.eclipse.swt.graphics.*;
import org.eclipse.swt.opengl.*;
import org.eclipse.swt.widgets.*;

public class NeHeCanvas
    implements Runnable
{
    private Canvas _canvas;     // Canvas used by a GLContext for drawing
    private GLContext _context; // Permanent rendering context
    
    /** This is the constructor, where event listeners and OpenGL are
      * initialized.
      * 
      * @param parent the composite from which to create a canvas
      */
    public NeHeCanvas(Composite parent) {
        _canvas = new Canvas(parent, SWT.NONE); // New instance of a canvas
        _canvas.setSize(parent.getSize());      // Set canvas size to window
        /* Use anonymous class to listen for window/canvas size changes */
        _canvas.addControlListener(new ControlListener () {
            public void controlMoved(ControlEvent e) {}
            public void controlResized(ControlEvent e) {
                NeHeCanvas.this.controlResized(e);
            }
        });
        
        initGL(); // Initialize OpenGL
    }
    
    /** This method is specified by the Runnable interface and it is used here
      * to draw to the OpenGL canvas every 10 milliseconds.
      */
    public void run() {
        /* Check to see if it is safe to continue to draw */
        if (!_canvas.isDisposed() && _canvas.getShell() != null) {
            drawGLScene(); // Draw the scene
            _context.swapBuffers(); // Swap buffers (Double buffering)
            _canvas.getDisplay().timerExec(10, this); // Call run() again in 10ms
        } else {
            /* It is no longer safe to draw, so dispose OS resources */
            _context.dispose();
        }
    }
    
    private final void controlResized(ControlEvent e) {
        resizeGLScene(); // Resize the GL viewport
    }
    
    private final void drawGLScene() {
        /* Clear The Screen And The Depth Buffer */
        GL.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);
        GL.glLoadIdentity(); // Reset the current modelview matrix
        /* Move left 1.5 units and into the screen 6.0 */
        GL.glTranslatef(-1.5f, 0.0f, -6.0f);
        
        GL.glBegin(GL.GL_TRIANGLES);       // Drawing using triangles
        GL.glColor3f(1.0f, 0.0f, 0.0f);    // Set the color to red
        GL.glVertex3f(0.0f, 1.0f, 0.0f);   // Top
        GL.glColor3f(0.0f, 1.0f, 0.0f);    // Set the color to green
        GL.glVertex3f(-1.0f, -1.0f, 0.0f); // Bottom left
        GL.glColor3f(0.0f, 0.0f, 1.0f);    // Set the color to blue
        GL.glVertex3f(1.0f, -1.0f, 0.0f);  // Bottom right
        GL.glEnd();                        // Finish drawing the triangle
        
        GL.glTranslatef(3.0f, 0.0f, 0.0f); // Move right 3 units
        GL.glColor3f(0.5f, 0.5f, 1.0f);    // Set the color to blue one time only
        GL.glBegin(GL.GL_QUADS);           // Draw a quad
        GL.glVertex3f(-1.0f, 1.0f, 0.0f);  // Top left
        GL.glVertex3f(1.0f, 1.0f, 0.0f);   // Top right
        GL.glVertex3f(1.0f, -1.0f, 0.0f);  // Bottom right
        GL.glVertex3f(-1.0f, -1.0f, 0.0f); // Bottom left
        GL.glEnd();                        // Done drawing the quad
    }
    
    private final void initGL() {
        _context = new GLContext(_canvas);    // Create rendering context
        _context.setCurrent(true);            // Activate the rendering context
        resizeGLScene();                      // Initialize the GL viewport
        
        GL.glShadeModel(GL.GL_SMOOTH);           // Enables Smooth Shading
        GL.glClearColor(0.0f, 0.0f, 0.0f, 0.0f); // Black Background
        GL.glClearDepth(1.0f);                   // Depth Buffer Setup
        GL.glEnable(GL.GL_DEPTH_TEST);           // Enables Depth Testing
        GL.glDepthFunc(GL.GL_LEQUAL);            // The Type Of Depth Test To Do
        
        /* Really Nice Perspective Calculations */
        GL.glHint(GL.GL_PERSPECTIVE_CORRECTION_HINT, GL.GL_NICEST);  
    }
    
    private final void resizeGLScene() {
        Rectangle rect = _canvas.getClientArea(); // Get the size of the canvas
        int width = rect.width;                   // Store the canvas width
        int height = rect.height;                 // Store the canvas height
        height = Math.max(height, 1);             // Prevent a divide by zero
        GL.glViewport(0, 0, width, height);  // Reset The Current Viewport
        GL.glMatrixMode(GL.GL_PROJECTION);   // select the projection matrix
        GL.glLoadIdentity();                 // reset the projection matrix
        /* Calculate The Aspect Ratio Of The Window */
        float aspect = (float) width / (float) height;
        GLU.gluPerspective(45.0f, aspect, 0.5f, 400.0f);
        GL.glMatrixMode(GL.GL_MODELVIEW);    // select the modelview matrix
        GL.glLoadIdentity();                 // reset the modelview matrix
    }
}