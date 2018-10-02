/*
 * This code was created by Jeff Molofee '99
 * (ported to Linux/SDL by Ti Leggett '01)
 * (converted to lesson23 by Arkadi Shishlov '03)
 *
 * If you've found this code useful, please let me know.
 *
 * Visit Jeff at http://nehe.gamedev.net/
 *
 * or for port-specific comments, questions, bugreports etc.
 * email to arkadi@it.lv
 */

#include <stdio.h>
#include <stdlib.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include "SDL.h"

/* screen width, height, and bit depth */
#define SCREEN_WIDTH  640
#define SCREEN_HEIGHT 480
#define SCREEN_BPP     16

/* Set up some booleans */
#define TRUE  1
#define FALSE 0

/* Number of textures to load */
#define NUM_TEXTURES 6

/* This is our SDL surface */
SDL_Surface *surface;

/* Whether or not lighting is on */
int light = FALSE;

GLfloat xrot;      /* X Rotation            */
GLfloat yrot;      /* Y Rotation            */
GLfloat xspeed;    /* X Rotation Speed      */
GLfloat yspeed;    /* Y Rotation Speed      */
GLfloat z = -5.0f; /* Depth Into The Screen */

/* Ambient Light Values */
GLfloat LightAmbient[]  = { 0.5f, 0.5f, 0.5f, 1.0f };
/* Diffuse Light Values */
GLfloat LightDiffuse[]  = { 1.0f, 1.0f, 1.0f, 1.0f };
/* Light Position */
GLfloat LightPosition[] = { 0.0f, 0.0f, 2.0f, 1.0f };

GLUquadricObj *quadratic;     /* Storage For Our Quadratic Objects */
GLuint object = 3;            /* Which Object To Draw              */

GLuint filter = 0;            /* Which Filter To Use               */
GLuint texture[NUM_TEXTURES]; /* Storage for 3 textures            */


/* function to release/destroy our resources and restoring the old desktop */
void Quit( int returnCode )
{

    /* Clean up our quadratic */
    gluDeleteQuadric( quadratic );

    /* Clean up our textures */
    glDeleteTextures( NUM_TEXTURES, &texture[0] );

    /* clean up the window */
    SDL_Quit( );

    /* and exit appropriately */
    exit( returnCode );
}

/* function to load in bitmap as a GL texture */
int LoadGLTextures( )
{

    /* Status indicator */
    int Status = FALSE;

    int loop;

    /* Create storage space for the texture */
    SDL_Surface *TextureImage[2];

    /* Load The Bitmap, Check For Errors, If Bitmap's Not Found Quit */
    if ( ( TextureImage[0] = SDL_LoadBMP( "data/bg.bmp" ) ) &&
         ( TextureImage[1] = SDL_LoadBMP( "data/reflect.bmp" ) ) )
    {

        /* Set the status to true */
        Status = TRUE;

        /* Create The Texture */
        glGenTextures( NUM_TEXTURES, &texture[0] );
        for( loop = 0; loop <= 1; loop++ )
        {
            /* Create Nearest Filtered Texture */
            glBindTexture( GL_TEXTURE_2D, texture[loop] ); /* Gen Tex 0 And 1 */
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,GL_NEAREST );
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,GL_NEAREST );
            glTexImage2D( GL_TEXTURE_2D, 0, 3, TextureImage[loop]->w, TextureImage[loop]->h,
                0, GL_BGR, GL_UNSIGNED_BYTE, TextureImage[loop]->pixels );

            /* Create Linear Filtered Texture */
            glBindTexture( GL_TEXTURE_2D, texture[loop+2] ); /* Gen Tex 2 And 3 */
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
            glTexImage2D( GL_TEXTURE_2D, 0, 3, TextureImage[loop]->w, TextureImage[loop]->h,
                0, GL_BGR, GL_UNSIGNED_BYTE, TextureImage[loop]->pixels );

            /* Create MipMapped Texture */
            glBindTexture( GL_TEXTURE_2D, texture[loop+4] ); /* Gen Tex 4 and 5 */
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST );
            gluBuild2DMipmaps( GL_TEXTURE_2D, 3, TextureImage[loop]->w, TextureImage[loop]->h,
                GL_BGR, GL_UNSIGNED_BYTE, TextureImage[loop]->pixels );
        }
    }
    /* Free up any memory we may have used */
    for( loop = 0; loop <= 1; loop++ )
    {
        if ( TextureImage[loop] )
            SDL_FreeSurface( TextureImage[loop] );
    }

    return Status;
}

/* function to reset our viewport after a window resize */
int resizeWindow( int width, int height )
{
    /* Height / width ration */
    GLfloat ratio;

    /* Protect against a divide by zero */
    if ( height == 0 )
	height = 1;

    ratio = ( GLfloat )width / ( GLfloat )height;

    /* Setup our viewport. */
    glViewport( 0, 0, ( GLint )width, ( GLint )height );

    /* change to the projection matrix and set our viewing volume. */
    glMatrixMode( GL_PROJECTION );
    glLoadIdentity( );

    /* Set our perspective */
    gluPerspective( 45.0f, ratio, 0.1f, 100.0f );

    /* Make sure we're chaning the model view and not the projection */
    glMatrixMode( GL_MODELVIEW );

    /* Reset The View */
    glLoadIdentity( );

    return( TRUE );
}

/* function to handle key press events */
void handleKeyPress( SDL_keysym *keysym )
{
    switch ( keysym->sym )
	{
	case SDLK_ESCAPE:
	    /* ESC key was pressed */
	    Quit( 0 );
	    break;
	case SDLK_f:
	    /* 'f' key was pressed
	     * this pages through the different filters
	     */
	    filter = ( filter + 1 ) % 3;
	    break;
	case SDLK_l:
	    /* 'l' key was pressed
	     * this toggles the light
	     */
	    light = !light;
	    if ( !light )
		glDisable( GL_LIGHTING );
	    else
		glEnable( GL_LIGHTING );
	    break;
	case SDLK_SPACE:
	    /* Spacebar was pressed
	     * this pages through the objects
	     */
	    object = ( object + 1 ) % 4;
	    break;
	case SDLK_PAGEUP:
	    /* PageUp key was pressed
	     * this zooms into the scene
	     */
	    z -= 0.02f;
	    break;
	case SDLK_PAGEDOWN:
	    /* PageDown key was pressed
	     * this zooms out of the scene
	     */
	    z += 0.02f;
	    break;
	case SDLK_UP:
	    /* Up arrow key was pressed
	     * this affects the x rotation
	     */
	    xspeed -= 0.01f;
	    break;
	case SDLK_DOWN:
	    /* Down arrow key was pressed
	     * this affects the x rotation
	     */
	    xspeed += 0.01f;
	    break;
	case SDLK_RIGHT:
	    /* Right arrow key was pressed
	     * this affects the y rotation
	     */
	    yspeed += 0.01f;
	    break;
	case SDLK_LEFT:
	    /* Left arrow key was pressed
	     * this affects the y rotation
	     */
	    yspeed -= 0.01f;
	    break;
	case SDLK_F1:
	    /* 'f' key was pressed
	     * this toggles fullscreen mode
	     */
	    SDL_WM_ToggleFullScreen( surface );
	    break;
	default:
	    break;
	}

    return;
}

/* general OpenGL initialization function */
int initGL( GLvoid )
{

    /* Load in the texture */
    if ( !LoadGLTextures( ) )
	return FALSE;

    /* Enable Texture Mapping ( NEW ) */
    glEnable( GL_TEXTURE_2D );

    /* Enable smooth shading */
    glShadeModel( GL_SMOOTH );

    /* Set the background black */
    glClearColor( 0.0f, 0.0f, 0.0f, 0.0f );

    /* Depth buffer setup */
    glClearDepth( 1.0f );

    /* Enables Depth Testing */
    glEnable( GL_DEPTH_TEST );

    /* The Type Of Depth Test To Do */
    glDepthFunc( GL_LEQUAL );

    /* Really Nice Perspective Calculations */
    glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );

    /* Setup The Ambient Light */
    glLightfv( GL_LIGHT1, GL_AMBIENT, LightAmbient );

    /* Setup The Diffuse Light */
    glLightfv( GL_LIGHT1, GL_DIFFUSE, LightDiffuse );

    /* Position The Light */
    glLightfv( GL_LIGHT1, GL_POSITION, LightPosition );

    /* Enable Light One */
    glEnable( GL_LIGHT1 );

    /* Set The Texture Generation Mode For S To Sphere Mapping */
    glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);
    /* Set The Texture Generation Mode For T To Sphere Mapping */
    glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);

    /* Create A Pointer To The Quadric Object */
    quadratic = gluNewQuadric( );
    /* Create Smooth Normals */
    gluQuadricNormals( quadratic, GLU_SMOOTH );
    /* Create Texture Coords */
    gluQuadricTexture( quadratic, GL_TRUE );

    return( TRUE );
}

GLvoid drawGLCube( GLvoid )
{
    /* Start Drawing Quads */
    glBegin( GL_QUADS );
      /* Front Face */
      glNormal3f( 0.0f, 0.0f, 0.5f );
      glTexCoord2f( 1.0f, 0.0f ); glVertex3f( -1.0f, -1.0f,  1.0f );
      glTexCoord2f( 0.0f, 0.0f ); glVertex3f(  1.0f, -1.0f,  1.0f );
      glTexCoord2f( 0.0f, 1.0f ); glVertex3f(  1.0f,  1.0f,  1.0f );
      glTexCoord2f( 1.0f, 1.0f ); glVertex3f( -1.0f,  1.0f,  1.0f );

      /* Back Face */
      glNormal3f( 0.0f, 0.0f, -0.5f);
      glTexCoord2f( 0.0f, 0.0f ); glVertex3f( -1.0f, -1.0f, -1.0f );
      glTexCoord2f( 0.0f, 1.0f ); glVertex3f( -1.0f,  1.0f, -1.0f );
      glTexCoord2f( 1.0f, 1.0f ); glVertex3f(  1.0f,  1.0f, -1.0f );
      glTexCoord2f( 1.0f, 0.0f ); glVertex3f(  1.0f, -1.0f, -1.0f );

      /* Top Face */
      glNormal3f( 0.0f, 0.5f, 0.0f );
      glTexCoord2f( 1.0f, 1.0f ); glVertex3f( -1.0f,  1.0f, -1.0f );
      glTexCoord2f( 1.0f, 0.0f ); glVertex3f( -1.0f,  1.0f,  1.0f );
      glTexCoord2f( 0.0f, 0.0f ); glVertex3f(  1.0f,  1.0f,  1.0f );
      glTexCoord2f( 0.0f, 1.0f ); glVertex3f(  1.0f,  1.0f, -1.0f );

      /* Bottom Face */
      glNormal3f( 0.0f, -0.5f, 0.0f );
      glTexCoord2f( 0.0f, 1.0f ); glVertex3f( -1.0f, -1.0f, -1.0f );
      glTexCoord2f( 1.0f, 1.0f ); glVertex3f(  1.0f, -1.0f, -1.0f );
      glTexCoord2f( 1.0f, 0.0f ); glVertex3f(  1.0f, -1.0f,  1.0f );
      glTexCoord2f( 0.0f, 0.0f ); glVertex3f( -1.0f, -1.0f,  1.0f );

      /* Right face */
      glNormal3f( 0.5f, 0.0f, 0.0f);
      glTexCoord2f( 0.0f, 0.0f ); glVertex3f( 1.0f, -1.0f, -1.0f );
      glTexCoord2f( 0.0f, 1.0f ); glVertex3f( 1.0f,  1.0f, -1.0f );
      glTexCoord2f( 1.0f, 1.0f ); glVertex3f( 1.0f,  1.0f,  1.0f );
      glTexCoord2f( 1.0f, 0.0f ); glVertex3f( 1.0f, -1.0f,  1.0f );

      /* Left Face*/
      glNormal3f( -0.5f, 0.0f, 0.0f );
      glTexCoord2f( 1.0f, 0.0f ); glVertex3f( -1.0f, -1.0f, -1.0f );
      glTexCoord2f( 0.0f, 0.0f ); glVertex3f( -1.0f, -1.0f,  1.0f );
      glTexCoord2f( 0.0f, 1.0f ); glVertex3f( -1.0f,  1.0f,  1.0f );
      glTexCoord2f( 1.0f, 1.0f ); glVertex3f( -1.0f,  1.0f, -1.0f );
    glEnd();

    return;
}

/* Here goes our drawing code */
int drawGLScene( GLvoid )
{
    /* These are to calculate our fps */
    static GLint T0     = 0;
    static GLint Frames = 0;

    /* Clear The Screen And The Depth Buffer */
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    /* Reset the view */
    glLoadIdentity( );

    /* Translate Into/Out Of The Screen By z */
    glTranslatef( 0.0f, 0.0f, z );

    /* Enable Texture Coord Generation For S */
    glEnable(GL_TEXTURE_GEN_S);
    /* Enable Texture Coord Generation For T */
    glEnable(GL_TEXTURE_GEN_T);

    /* Select A Texture Based On filter */
    glBindTexture( GL_TEXTURE_2D, texture[filter*2 + 1] );

    glPushMatrix();

    glRotatef( xrot, 1.0f, 0.0f, 0.0f); /* Rotate On The X Axis By xrot */
    glRotatef( yrot, 0.0f, 1.0f, 0.0f); /* Rotate On The Y Axis By yrot */

    /* Determine what object to draw */
    switch( object )
	{
	case 0:
	    /* Draw our cube */
	    drawGLCube( );
	    break;
	case 1:
	    /* Draw a cylinder */
	    glTranslatef( 0.0f, 0.0f, -1.5f );
	    gluCylinder( quadratic, 1.0f, 1.0f, 3.0f, 32, 32 );
	    break;
	case 2:
	    /* Draw a sphere */
	    gluSphere( quadratic, 1.3f, 32, 32 );
	    break;
	case 3:
	    /* Draw a cone */
	    glTranslatef( 0.0f, 0.0f, -1.5f );
	    gluCylinder( quadratic, 1.0f, 0.0f, 3.0f, 32, 32 );
	    break;
	};

    glPopMatrix();

    /* Disable Texture Coord Generation For S */
    glDisable( GL_TEXTURE_GEN_S );
    /* Disable Texture Coord Generation For T */
    glDisable( GL_TEXTURE_GEN_T );

    /* This Will Select The BG Texture */
    glBindTexture( GL_TEXTURE_2D, texture[filter*2] );
    glPushMatrix();
        glTranslatef( 0.0f, 0.0f, -29.0f );
        glBegin( GL_QUADS );
            glNormal3f( 0.0f, 0.0f, 1.0f);
            glTexCoord2f( 0.0f, 0.0f ); glVertex3f( -13.3f, -10.0f,  10.0f );
            glTexCoord2f( 1.0f, 0.0f ); glVertex3f(  13.3f, -10.0f,  10.0f );
            glTexCoord2f( 1.0f, 1.0f ); glVertex3f(  13.3f,  10.0f,  10.0f );
            glTexCoord2f( 0.0f, 1.0f ); glVertex3f( -13.3f,  10.0f,  10.0f );
        glEnd();
    glPopMatrix();

    /* Draw it to the screen */
    SDL_GL_SwapBuffers( );

    /* Gather our frames per second */
    Frames++;
    {
	GLint t = SDL_GetTicks();
	if (t - T0 >= 5000) {
	    GLfloat seconds = (t - T0) / 1000.0;
	    GLfloat fps = Frames / seconds;
	    printf("%d frames in %g seconds = %g FPS\n", Frames, seconds, fps);
	    T0 = t;
	    Frames = 0;
	}
    }

    xrot += xspeed; /* Add xspeed To xrot */
    yrot += yspeed; /* Add yspeed To yrot */

    return( TRUE );
}

int main( int argc, char **argv )
{
    /* Flags to pass to SDL_SetVideoMode */
    int videoFlags;
    /* main loop variable */
    int done = FALSE;
    /* used to collect events */
    SDL_Event event;
    /* this holds some info about our display */
    const SDL_VideoInfo *videoInfo;
    /* whether or not the window is active */
    int isActive = TRUE;

    /* initialize SDL */
    if ( SDL_Init( SDL_INIT_VIDEO ) < 0 )
	{
	    fprintf( stderr, "Video initialization failed: %s\n",
		     SDL_GetError( ) );
	    Quit( 1 );
	}

    /* Fetch the video info */
    videoInfo = SDL_GetVideoInfo( );

    if ( !videoInfo )
	{
	    fprintf( stderr, "Video query failed: %s\n",
		     SDL_GetError( ) );
	    Quit( 1 );
	}

    /* the flags to pass to SDL_SetVideoMode                            */
    videoFlags  = SDL_OPENGL;          /* Enable OpenGL in SDL          */
    videoFlags |= SDL_GL_DOUBLEBUFFER; /* Enable double buffering       */
    videoFlags |= SDL_HWPALETTE;       /* Store the palette in hardware */
    videoFlags |= SDL_RESIZABLE;       /* Enable window resizing        */

    /* This checks to see if surfaces can be stored in memory */
    if ( videoInfo->hw_available )
	videoFlags |= SDL_HWSURFACE;
    else
	videoFlags |= SDL_SWSURFACE;

    /* This checks if hardware blits can be done */
    if ( videoInfo->blit_hw )
	videoFlags |= SDL_HWACCEL;

    /* Sets up OpenGL double buffering */
    SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );

    /* get a SDL surface */
    surface = SDL_SetVideoMode( SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_BPP,
				videoFlags );

    /* Verify there is a surface */
    if ( !surface )
	{
	    fprintf( stderr,  "Video mode set failed: %s\n", SDL_GetError( ) );
	    Quit( 1 );
	}

    /* Enable key repeat */
    if ( ( SDL_EnableKeyRepeat( 100, SDL_DEFAULT_REPEAT_INTERVAL ) ) )
	{
	    fprintf( stderr, "Setting keyboard repeat failed: %s\n",
		     SDL_GetError( ) );
	    Quit( 1 );
	}

    /* initialize OpenGL */
    if ( initGL( ) == FALSE )
	{
	    fprintf( stderr, "Could not initialize OpenGL.\n" );
	    Quit( 1 );
	}

    /* resize the initial window */
    resizeWindow( SCREEN_WIDTH, SCREEN_HEIGHT );

    /* wait for events */
    while ( !done )
	{
	    /* handle the events in the queue */

	    while ( SDL_PollEvent( &event ) )
		{
		    switch( event.type )
			{
			case SDL_ACTIVEEVENT:
			    /* Something's happend with our focus
			     * If we lost focus or we are iconified, we
			     * shouldn't draw the screen
			     */
			    if ( event.active.gain == 0 )
				isActive = FALSE;
			    else
				isActive = TRUE;
			    break;			    
			case SDL_VIDEORESIZE:
			    /* handle resize event */
			    surface = SDL_SetVideoMode( event.resize.w,
							event.resize.h,
							16, videoFlags );
			    if ( !surface )
				{
				    fprintf( stderr, "Could not get a surface after resize: %s\n", SDL_GetError( ) );
				    Quit( 1 );
				}
			    resizeWindow( event.resize.w, event.resize.h );
			    break;
			case SDL_KEYDOWN:
			    /* handle key presses */
			    handleKeyPress( &event.key.keysym );
			    break;
			case SDL_QUIT:
			    /* handle quit requests */
			    done = TRUE;
			    break;
			default:
			    break;
			}
		}

	    /* draw the scene */
	    if ( isActive )
		drawGLScene( );
	}

    /* clean ourselves up and exit */
    Quit( 0 );

    /* Should never get here */
    return( 0 );
}
