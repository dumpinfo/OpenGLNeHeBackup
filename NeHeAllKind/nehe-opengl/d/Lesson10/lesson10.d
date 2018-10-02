/************************************************************
*																				*
* This code was made with DedicateD's testgl.d file as a		*
* base, and using their D ports of SDL and OpenGL, their		*
* website is http://int19h.tamb.ru/									*
*																				*
* D language compiler is available for download at				*
* http://www.digitalmars.com/d/dcompiler.html					*
*																				*
* This code was created by Jeff Molofee '99 						*
*																				*
* If you've found this code useful, please let me know.		*
*																				*
* Visit Jeff at http://nehe.gamedev.net/							*
*																				*
* Code modified/ported to D programming language				*
* by Garibaldi Pineda Garcia (ChaNoKiN)							*
* chanok_lobo@hotmail.com												*
* 2004																		*
*																				*
************************************************************/

import SDL;								// Import the SDL modules
import opengl;							// Import the opengl modules
import openglu;
import std.string;					// Import string modules
import std.stream;					// Import stream modules
import std.c.stdio;					// Import the C stdio modules
import std.math;						// Import the math module





bit USE_DEPRECATED_OPENGLBLIT = false;


/* Build Our Vertex Structure */
struct Vertex
{
    float x, y, z; /* 3D Coordinates */
    float u, v;    /* Texture Coordinates */
}

/* Build Our Triangle Structure */
struct Triangle
{
    Vertex vertex[3]; /* Array Of Three Vertices */
}

/* Build Our Sector Structure */
struct Sector
{
    int numTriangles;   /* Number Of Triangles In Sector */
    Triangle[] triangle; /* Pointer To Array Of Triangles */
}

Sector sector1;     /* Our sector */

GLfloat yrot = 0.0f;       /* Camera rotation variable */
GLfloat xpos = 0.0f, zpos = 0.0f; /* Camera pos variable */

GLfloat walkbias = 0.0f, walkbiasangle = 0.0f; /* Head-bobbing variables */
GLfloat lookupdown = 0.0f;

/* Ambient Light Values */
GLfloat LightAmbient[]  = [ 0.5f, 0.5f, 0.5f, 1.0f ];
/* Diffuse Light Values */
GLfloat LightDiffuse[]  = [ 1.0f, 1.0f, 1.0f, 1.0f ];
/* Light Position */
GLfloat LightPosition[] = [ 0.0f, 0.0f, 2.0f, 1.0f ];

/* constant used for converting to radians */
const float piover180 = 0.0174532925f;

bit blend = false;
bit light = false;
GLuint filter;     /* Which Filter To Use */
GLuint texture[3]; /* Storage for 3 textures *


/* function to load in bitmap as a GL texture */
int LoadGLTextures( )
{
    /* Status indicator */
    int Status = false;

    /* Create storage space for the texture */
    SDL_Surface *TextureImage[1]; 

    /* Load The Bitmap, Check For Errors, If Bitmap's Not Found Quit */
    if ( ( TextureImage[0] = SDL_LoadBMP( "data/mud.bmp" ) ) != null )
    {

	    /* Set the status to true */
	    Status = true;

	    /* Create The Texture */
	    glGenTextures( 3, &texture[0] );

	    /* Load in texture 1 */
	    /* Typical Texture Generation Using Data From The Bitmap */
	    glBindTexture( GL_TEXTURE_2D, texture[0] );

	    /* Generate The Texture */
	    glTexImage2D( GL_TEXTURE_2D, 0, 3, TextureImage[0].w,
			  TextureImage[0].h, 0, GL_BGR_EXT,
			  GL_UNSIGNED_BYTE, TextureImage[0].pixels );
	    
	    /* Nearest Filtering */
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
			     GL_NEAREST );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
			     GL_NEAREST );

	    /* Load in texture 2 */
	    /* Typical Texture Generation Using Data From The Bitmap */
	    glBindTexture( GL_TEXTURE_2D, texture[1] );

	    /* Linear Filtering */
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
			     GL_LINEAR );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
			     GL_LINEAR );

	    /* Generate The Texture */
	    glTexImage2D( GL_TEXTURE_2D, 0, 3, TextureImage[0].w,
			  TextureImage[0].h, 0, GL_BGR_EXT,
			  GL_UNSIGNED_BYTE, TextureImage[0].pixels );

	    /* Load in texture 3 */
	    /* Typical Texture Generation Using Data From The Bitmap */
	    glBindTexture( GL_TEXTURE_2D, texture[2] );

	    /* Mipmapped Filtering */
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
			     GL_LINEAR_MIPMAP_NEAREST );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
			     GL_LINEAR );

	    /* Generate The MipMapped Texture ( NEW ) */
	    gluBuild2DMipmaps( GL_TEXTURE_2D, 3, TextureImage[0].w,
			       TextureImage[0].h, GL_BGR_EXT,
			       GL_UNSIGNED_BYTE, TextureImage[0].pixels );
        }

    /* Free up any memory we may have used */
    if ( TextureImage[0] )
	    SDL_FreeSurface( TextureImage[0] );

    return Status;
}

char[] readOneLine(File *f)
{
	 
	 char[] temp;
	 do
	 {
	  temp = f.readLine();
	  if(temp == null) temp = "\n";
	  if(f.eof()) break;
	 }while( temp[0] == '/' || temp[0] == '\n');

    
    return temp;
}

/* Setup Our World */
void SetupWorld( char[] worldFile )
{
    

    int numTriangles;    /* Number of Triangles */

    float x, y, z, u, v; /* 3d and texture coordinates */

    int triLoop;         /* Triangle loop variable */
    int verLoop;         /* Vertex loop variable */

    /* Open Our File */
    File f = new File(worldFile);        /* File To Work With */
   
	 char[] temp;
	 char[][] split_temp;

    /* Grab a line from 'filein' */
    
    temp = readOneLine(&f);
    
    /* Read in number of triangle */
    
	 split_temp = split(temp);						//split the line we read
	 numTriangles = atoi(split_temp[1]);		//converts string to integer
	 printf("Number of Polygons %d\n",numTriangles);

    /* allocate space for our triangles */
    sector1.triangle.length = numTriangles ;
   
    sector1.numTriangles = numTriangles;

    /* Get coords for each triangle */
    for ( triLoop = 0; triLoop < numTriangles; triLoop++ )
	{
	    for ( verLoop = 0; verLoop < 3; verLoop++ )
		{
			 temp = readOneLine(&f);			//read one line
		    split_temp = split(temp);			//split the line we read

		    sector1.triangle[triLoop].vertex[verLoop].x = atof(split_temp[0]);//convert string to float
		    sector1.triangle[triLoop].vertex[verLoop].y = atof(split_temp[1]);//convert string to float
		    sector1.triangle[triLoop].vertex[verLoop].z = atof(split_temp[2]);//convert string to float
		    sector1.triangle[triLoop].vertex[verLoop].u = atof(split_temp[3]);//convert string to float
		    sector1.triangle[triLoop].vertex[verLoop].v = atof(split_temp[4]);//convert string to float
		}
	}

    /* Close Our File */
    f.close();

    return;
}

/* function to handle key press events */
void handleKeyPress( SDL_keysym *keysym )
{
    switch ( keysym.sym )
	 {
	 	case SDLK_b:
	    	/* 'b' key was pressed
	     	* this toggles blending
	     	*/
	   	blend = !blend;
	   	if ( blend )
			{
		   	glEnable( GL_BLEND );
		   	glDisable( GL_DEPTH_TEST );
			}
	    	else
			{
		   	glDisable( GL_BLEND );
		   	glEnable( GL_DEPTH_TEST );
			}
	    	break;
	    	
		case SDLK_f:
		   /* 'f' key was pressed
	   	* this pages through the different filters
		   */
		   filter = ( ++filter ) % 3;
		   break;
		   
		case SDLK_l:
		   /* 'l' key was pressed
		   * this toggles the light
		   */
		  	light = !light;
	  	  	if( !light )
				glDisable( GL_LIGHTING );
	  	   else
				glEnable( GL_LIGHTING );
	  	   break;
	 	
		case SDLK_RIGHT:
	    	/* Right arrow key was pressed
	     	* this effectively turns the camera right, but does it by
	     	* rotating the scene left
	     	*/
	    	yrot -= 1.5f;
	    	break;
		case SDLK_LEFT:
	    	/* Left arrow key was pressed
	     	* this effectively turns the camera left, but does it by
	     	* rotating the scene right
	     	*/
	    	yrot += 1.5f;
	    	break;
		case SDLK_UP:
	    	/* Up arrow key was pressed
	     	* this moves the player forward
	     	*/
	    	/* Move On The X-Plane Based On Player Direction */
	    	xpos -= cast(float)sin( yrot * piover180 ) * 0.05f;
	    	/* Move On The Z-Plane Based On Player Direction */
	    	zpos -= cast(float)cos( yrot * piover180 ) * 0.05f;
	    	if ( walkbiasangle >= 359.0f )
				walkbiasangle = 0.0f;
	    	else
				walkbiasangle+= 10;

	    	/* Causes the player to bounce */
	    	walkbias = cast(float)sin( walkbiasangle * piover180 ) / 20.0f;
	    	break;
		case SDLK_DOWN:
	    	/* Down arrow key was pressed
	     	* this causes the player to move backwards
	     	*/
	    	/* Move On The X-Plane Based On Player Direction */
	    	xpos += cast(float)sin( yrot * piover180 ) * 0.05f;
	    	/* Move On The Z-Plane Based On Player Direction */
	    	zpos += cast(float)cos( yrot * piover180 ) * 0.05f;
	    	if( walkbiasangle <= 1.0f )
         	walkbiasangle = 359.0f;
	    	else
            walkbiasangle -= 10;

	   	walkbias = cast(float)sin( walkbiasangle * piover180 ) / 20.0f;
	    	break;
		    
		case SDLK_g: 		//If ctrl+g then loose/gain grab
			if(keysym.mod & KMOD_CTRL)
			HotKey_ToggleGrab();
			break;
				
		case SDLK_z: 			//if ctrl+z minimize
		   if(keysym.mod & KMOD_CTRL)
			HotKey_Iconify();
			break;
		
		case SDLK_RETURN: 	//if alt+enter toggle fullscreen mode
		   if(keysym.mod & KMOD_ALT)
			HotKey_ToggleFullScreen();
		 	break;

		default:

		   break;
	 }

    return;
}

/*This function changes from windowed to fullscreen
  mode and viceversa*/

void HotKey_ToggleFullScreen()
{
	SDL_Surface *screen;														//Make a surface pointer to screen

	screen = SDL_GetVideoSurface();										//Get current video surface
	if ( SDL_WM_ToggleFullScreen(screen) )								//If the toggle worked
	{
	  printf("Toggled fullscreen mode - now %s\n",					//print current window mode
	  (screen.flags & SDL_FULLSCREEN) ? "fullscrn" : "windowed");
	}
	else
	{
		printf("Unable to toggle fullscreen mode\n");				//else, just tell us we can't do it.
	}
}


/* This function will keep the mouse pointer
	"trapped" inside the GL window
*/
void HotKey_ToggleGrab()
{
	SDL_GrabMode mode;

	printf("Ctrl-G: toggling input grab!\n"); //Print the action taking place
	mode = SDL_WM_GrabInput(SDL_GRAB_QUERY);  //Check wether grab is on
	if ( mode == SDL_GRAB_ON )						//Print previous grab mode status
	{
		printf("Grab was on\n");
	}
	else
	{
		printf("Grab was off\n");
	}
	
	mode = SDL_WM_GrabInput(!mode);				//Change grab mode
	
	if ( mode == SDL_GRAB_ON )						//Print current grab mode status
	{
		printf("Grab is now on\n");
	}
	else
	{
		printf("Grab is now off\n");
	}
}



/* This will iconify or minimize the
	GL window.
*/
void HotKey_Iconify()
{
	printf("Ctrl-Z: iconifying window!\n"); //Print action
	SDL_WM_IconifyWindow();						 //Minimize
}


/*
  Main Event Handling function
*/
int HandleEvent(SDL_Event *event)
{
	int done;									//used to check if we want to quit

	done = 0;									//state that we still want to go on
	switch( event.type )						//Process events
	{
	    case SDL_ACTIVEEVENT:				//did we loose or gained input/mouse
													//focus?
			printf( "app %.*s ", event.active.gain ? "gain" : "lost" );
			if ( event.active.state & SDL_APPACTIVE )
			{
				printf( "active " );
			}
			else if ( event.active.state & SDL_APPMOUSEFOCUS )
				  {
					printf( "mouse " );
				  }
				  else if ( event.active.state & SDL_APPINPUTFOCUS )
				  {
					printf( "input " );
				  }
			printf( "focus\n" );
			break;
		

	    case SDL_KEYDOWN:										//Did we press any key
	      //printf("key '%s' pressed\n", 
			//SDL_GetKeyName(event.key.keysym.sym));			//Print which key was pressed
			if ( event.key.keysym.sym == SDLK_ESCAPE )	//If Escape Key then quit
			{
				done = 1;
			}
			handleKeyPress( &event.key.keysym );
			
			break;	


	    case SDL_QUIT:											//On quit event termnate loop
			done = 1;
			break;
		
		 default:
	}
	return(done);
}

void SDL_GL_Enter2DMode()
{
	SDL_Surface *screen = SDL_GetVideoSurface();				//Get a pointer to video surface

	/* Note, there may be other things you need to change,
	   depending on how you have your OpenGL state set up.
	*/
	glPushAttrib(GL_ENABLE_BIT);									//Save current enables
	glDisable(GL_DEPTH_TEST);										//Disable depth test
	glDisable(GL_CULL_FACE);										//Disable face culling
	glEnable(GL_TEXTURE_2D);										//Enable 2D textures

	glViewport(0, 0, screen.w, screen.h);						//Set viewport 

	glMatrixMode(GL_PROJECTION);									
	glPushMatrix();													//Save projection matrix
	glLoadIdentity();													//And reset it

	glOrtho(0.0, cast(GLdouble)(screen.w), cast(GLdouble)(screen.h), 0.0, 0.0, 1.0);
																			//Set orthographic projection
	glMatrixMode(GL_MODELVIEW);						
	glPushMatrix();													//Save modelview matrix
	glLoadIdentity();													//Reset it

	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);	
}

void SDL_GL_Leave2DMode()
{
	glMatrixMode(GL_MODELVIEW);									//Restore previous modelview matrix
	glPopMatrix();

	glMatrixMode(GL_PROJECTION);									//Restore previous projection matrix
	glPopMatrix();

	glPopAttrib();														//Restore previous enables
}

bool CreateWindowGL(int w, int h, int bpp, Uint32 video_flags)					// This Code Creates Our OpenGL Window
{

	int value;																		//Used as a recipient for some info
	int[3] rgb_size;																//Used to save the number of Red, Green and
	/* Initialize the display */												//Blue bits
	
	switch (bpp)
	{																					//Asing how may bits we want to use
	  
	  case 8:																		//depending of the bits per pixel
		rgb_size[0] = 2;															//passed as an argument to this function.
		rgb_size[1] = 3;
		rgb_size[2] = 3;
		break;
	  
	  case 15:
	  case 16:
		rgb_size[0] = 5;
		rgb_size[1] = 5;
		rgb_size[2] = 5;
		break;
	  
     default:
		rgb_size[0] = 8;
		rgb_size[1] = 8;
		rgb_size[2] = 8;
		break;
		
	}
	
	SDL_GL_SetAttribute( SDL_GL_RED_SIZE, rgb_size[0] );				//Try setting Red size (bits)
	SDL_GL_SetAttribute( SDL_GL_GREEN_SIZE, rgb_size[1] );			//Try setting Green size (bits)
	SDL_GL_SetAttribute( SDL_GL_BLUE_SIZE, rgb_size[2] );				//Try setting Blue size (bits)
	SDL_GL_SetAttribute( SDL_GL_DEPTH_SIZE, 16 );						//Try setting the depth buffer size (bits)
	SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );						//Try setting a double buffer
	
	if ( SDL_SetVideoMode( w, h, bpp, video_flags ) == null ) {		//Try to set the video mode
		printf("Couldn't set GL mode: %s\n", SDL_GetError());			//If it can't print error message
		SDL_Quit();																	//And then quit the app.
		return false;
	}
	//Print the characteristics of our VideoSurface and OpenGL capabilities
	printf("Screen BPP: %d\n", SDL_GetVideoSurface().format.BitsPerPixel);
	printf("\n");
	printf( "Vendor     : %s\n", glGetString( GL_VENDOR ) );
	printf( "Renderer   : %s\n", glGetString( GL_RENDERER ) );
	printf( "Version    : %s\n", glGetString( GL_VERSION ) );
	printf( "Extensions : %s\n", glGetString( GL_EXTENSIONS ) );
	printf("\n");

	//Print the OpenGL attributes, Red, Green and Blue bit sizes
	//Depth buffer size and if we got a double buffer or not
	SDL_GL_GetAttribute( SDL_GL_RED_SIZE, &value );
	printf( "SDL_GL_RED_SIZE: requested %d, got %d\n", rgb_size[0],value);
	SDL_GL_GetAttribute( SDL_GL_GREEN_SIZE, &value );
	printf( "SDL_GL_GREEN_SIZE: requested %d, got %d\n", rgb_size[1],value);
	SDL_GL_GetAttribute( SDL_GL_BLUE_SIZE, &value );
	printf( "SDL_GL_BLUE_SIZE: requested %d, got %d\n", rgb_size[2],value);
	SDL_GL_GetAttribute( SDL_GL_DEPTH_SIZE, &value );
	printf( "SDL_GL_DEPTH_SIZE: requested %d, got %d\n", bpp, value );
	SDL_GL_GetAttribute( SDL_GL_DOUBLEBUFFER, &value );
	printf( "SDL_GL_DOUBLEBUFFER: requested 1, got %d\n", value );
	
	
	
	//All went well, return true
	return true;
}

void ReshapeGL(int width, int height)										// Reshape The Window When It's Moved Or Resized
{
	glViewport(0,0,cast(GLsizei)(width),cast(GLsizei)(height));						// Reset The Current Viewport
	glMatrixMode(GL_PROJECTION);											// Select The Projection Matrix
	glLoadIdentity();														// Reset The Projection Matrix

	gluPerspective(45.0f,(cast(GLfloat)width/cast(GLfloat)height),1.0f,100.0f);	// Calculate The Aspect Ratio Of The Window
	glMatrixMode(GL_MODELVIEW);												// Select The Modelview Matrix
	glLoadIdentity();														// Reset The Modelview Matrix
	
}

bool InitGL()															// Any OpenGL Initialization Code Goes Here
{
	
    /* Load in the texture */
    if ( !LoadGLTextures( ) )
	 	return false;

    /* Enable Texture Mapping */
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

    lookupdown    = 0.0f;
    walkbias      = 0.0f;
    walkbiasangle = 0.0f;
    
    /* Full Brightness, 50% Alpha */
    glColor4f( 1.0f, 1.0f, 1.0f, 0.5f);

    /* Blending Function For Translucency Based On Source Alpha Value */
    glBlendFunc( GL_SRC_ALPHA, GL_ONE );
    
	 return true;												// Return TRUE (Initialization Successful)
}

void Draw3D()
{
	
    /* Floating Point For Temp X, Y, Z, U And V Vertices */
    GLfloat x_m, y_m, z_m, u_m, v_m;
    /* Used For Player Translation On The X Axis */
    GLfloat xtrans = -xpos;
    /* Used For Player Translation On The Z Axis */
    GLfloat ztrans = -zpos;
    /* Used For Bouncing Motion Up And Down */
    GLfloat ytrans = -walkbias - 0.5f;
    /* 360 Degree Angle For Player Direction */
    GLfloat sceneroty = 360.0f - yrot;

    /* Loop variable */
    int loop_m;

    /* Clear The Screen And The Depth Buffer */
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    glLoadIdentity( );

    /* Rotate Up And Down To Look Up And Down */
    glRotatef( lookupdown, 1.0f, 0.0f , 0.0f );
    /* Rotate Depending On Direction Player Is Facing */
    glRotatef( sceneroty, 0.0f, 1.0f , 0.0f );

    /* Translate The Scene Based On Player Position */
    glTranslatef( xtrans, ytrans, ztrans );
    /* Select A Texture Based On filter */
    glBindTexture( GL_TEXTURE_2D, texture[filter] );
        
    /* Process Each Triangle */
    for ( loop_m = 0; loop_m < sector1.numTriangles; loop_m++ )
    {
	    /* Start Drawing Triangles */
	    glBegin(GL_TRIANGLES);
	      /* Normal Pointing Forward */
	      glNormal3f( 0.0f, 0.0f, 1.0f);
	      /* X Vertex Of 1st Point */
	      x_m = sector1.triangle[loop_m].vertex[0].x;
	      /* Y Vertex Of 1st Point */
	      y_m = sector1.triangle[loop_m].vertex[0].y;
	      /* Z Vertex Of 1st Point */
	      z_m = sector1.triangle[loop_m].vertex[0].z;
	      /* U Texture Coord Of 1st Point */
	      u_m = sector1.triangle[loop_m].vertex[0].u;
	      /* V Texture Coord Of 1st Point */
	      v_m = sector1.triangle[loop_m].vertex[0].v;

	      /* Set The TexCoord And Vertice */
	      glTexCoord2f( u_m, v_m );
	      glVertex3f( x_m, y_m, z_m );

	      /* X Vertex Of 2nd Point */
	      x_m = sector1.triangle[loop_m].vertex[1].x;
	      /* Y Vertex Of 2nd Point */
	      y_m = sector1.triangle[loop_m].vertex[1].y;
	      /* Z Vertex Of 2nd Point */
	      z_m = sector1.triangle[loop_m].vertex[1].z;
	      /* U Texture Coord Of 2nd Point */
	      u_m = sector1.triangle[loop_m].vertex[1].u;
	      /* V Texture Coord Of 2nd Point */
	      v_m = sector1.triangle[loop_m].vertex[1].v;

	      /* Set The TexCoord And Vertice */
	      glTexCoord2f( u_m, v_m );
	      glVertex3f( x_m, y_m, z_m );

	      /* X Vertex Of 3rd Point */
	      x_m = sector1.triangle[loop_m].vertex[2].x;
	      /* Y Vertex Of 3rd Point */
	      y_m = sector1.triangle[loop_m].vertex[2].y;
	      /* Z Vertex Of 3rd Point */
	      z_m = sector1.triangle[loop_m].vertex[2].z;
	      /*  Texture Coord Of 3rd Point */
	      u_m = sector1.triangle[loop_m].vertex[2].u;
	      /* V Texture Coord Of 3rd Point */
	      v_m = sector1.triangle[loop_m].vertex[2].v;

	      /* Set The TexCoord And Vertice */
	      glTexCoord2f( u_m, v_m );
	      glVertex3f( x_m, y_m, z_m );
	    glEnd( );
	 }
	 
	 //glFlush();													// Flush The GL Rendering Pipelines
	

}

int main(char[][] argv)
{
	int argc = argv.length;										//Get the argument count
	int i;															//loop variable
	int w = 640;													//window width
	int h = 480;													//window heigth
	int bpp = 16;													//window bits per pixel
	int done = 0;													//variable to check if the app is ging on
	int frames;														//frame counting var
	Uint32 start_time, this_time;								//time storage variables
	Uint32 video_flags;											//video flags
   

	if( SDL_Init( SDL_INIT_VIDEO ) < 0 )					//Try to init SDL
	{
		printf("Couldn't initialize SDL: %s\n",SDL_GetError());
		return ( 1 );												//if we can't then just quit 
	}

	/* See if we need to detect the display depth */
	if ( bpp == 0 )
	{
		if ( SDL_GetVideoInfo().vfmt.BitsPerPixel <= 8 ) {
			bpp = 8;
		} else {
			bpp = 16;  /* More doesn't seem to work */
		}
	}

   /* Enable key repeat */
   if ( ( SDL_EnableKeyRepeat( SDL_DEFAULT_REPEAT_DELAY, SDL_DEFAULT_REPEAT_INTERVAL ) ) )
	{
	  printf("Setting keyboard repeat failed: %s\n", SDL_GetError( ) );
	  return 1;
	}


	/* Set the flags we want to use for setting the video mode */
    video_flags  = SDL_OPENGL;          // Enable OpenGL in SDL
    video_flags |= SDL_GL_DOUBLEBUFFER; // Enable double buffering 
    video_flags |= SDL_HWPALETTE;       // Store the palette in hardware
    video_flags |= SDL_RESIZABLE;       // Enable window resizing

    /* This checks to see if surfaces can be stored in memory */
    if ( SDL_GetVideoInfo().hw_available )
		video_flags |= SDL_HWSURFACE;
    else
		video_flags |= SDL_SWSURFACE;

    /* This checks if hardware blits can be done */
    if ( SDL_GetVideoInfo().blit_hw )
		video_flags |= SDL_HWACCEL;

    /* Sets up OpenGL double buffering */
    SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );
    
	for ( i=1; i < argc; ++i ) {									//If any of our args was "-fullscreen"
		if ( strcmp(argv[1], "-fullscreen") == 0 ) {			//add fullscrren mode to our video flags
			video_flags |= SDL_FULLSCREEN;
		}
	}

   CreateWindowGL(w, h, bpp, video_flags);					//Create our OpenGL Window

	SDL_WM_SetCaption( "NeHe Lesson 10", "Lesson 10" );			//Set the window manager title bar

   ReshapeGL(w,h);													//Set our viewport/perspective
   
   InitGL();															//Set our OpengGL attributes

   /* Read in the data */
   SetupWorld( "data/world.txt" );

	/* Loop until done. */
	start_time = SDL_GetTicks();									//Get our starting time
	frames = 0;															//No frames have been rendered yet
	SDL_Event event;													//SDL event storing variable

	while( !done )
	{	
		/*GLenum gl_error;												//OpenGL error storaging variable
		char* sdl_error;												//SDL error storaging variable
		*/
		Draw3D();														//Draw our 3D Graphics
		SDL_GL_SwapBuffers();										// And Swap The Buffers (We're Double-Buffering, Remember?)
		/*
		gl_error = glGetError( );									//Check for OpenGL error conditions. 

		if( gl_error != GL_NO_ERROR ) {
			printf("testgl: OpenGL error: %d\n", gl_error );//If we got OpenGL errors, print them
		}

		sdl_error = SDL_GetError( );								//Check for SDL error conditions.	

		if( sdl_error[0] != 0 ) {
			printf("testgl: SDL error '%s'\n", sdl_error);	//If we got DLL errors, print 
			SDL_ClearError();											//And deal with them
		}

		
		SDL_Delay( 1 );												//Set a delay, usefull on really fast Computers
		

		*/
		while( SDL_PollEvent( &event ) )						  //Check if there's a pending event.
		{
			done = HandleEvent(&event);						  //Handle them.
		}
		++frames;													  //Increase our frame count
	}

	/* Print out the frames per second */
	this_time = SDL_GetTicks();
	if ( this_time != start_time ) {
		printf("%2.2f FPS\n",
			(cast(float)(frames)/(this_time-start_time))*1000.0);
	}

	/* Destroy our GL context, etc. */
	SDL_Quit( );

	return 0;
}

