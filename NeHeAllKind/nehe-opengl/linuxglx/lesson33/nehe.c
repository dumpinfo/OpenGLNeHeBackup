/*
 * Nehe Lesson 33 Code (ported to Linux//GLX by Patrick Schubert 2003
 * with help from the lesson 1 basecode for Linux/GLX by Mihael Vrbanec)
 */

#include "nehe.h"
#include <GL/glx.h>
#include <GL/gl.h>
#include <X11/extensions/xf86vmode.h>
#include <X11/keysym.h>
#include <stdio.h>
#include <time.h>

typedef struct
{
    Display *dpy;
    int screen;
    Window win;
    GLXContext ctx;
    XSetWindowAttributes attr;
    Bool fs;
    XF86VidModeModeInfo deskMode;
    int x, y;
    unsigned int width, height;
    unsigned int depth;
} GLWindow;

static GLWindow GLWin;

extern void drawGLScene(void);
extern BOOL LoadGLTextures(void);

static void initGL(void);
static void resizeGLScene(void);
static void swapBuffers(void);

/* Create our window */
void createGLWindow(const char* title,int width,int height,int bits,int fullscreen)
{
	int attrListSgl[] = { GLX_RGBA, GLX_RED_SIZE, 4,
							GLX_GREEN_SIZE, 4,
							GLX_BLUE_SIZE, 4,
							GLX_DEPTH_SIZE, 16,
							None};

	int attrListDbl[] = { GLX_RGBA, GLX_DOUBLEBUFFER,
							GLX_RED_SIZE, 4,
							GLX_GREEN_SIZE, 4,
							GLX_BLUE_SIZE, 4,
							GLX_DEPTH_SIZE, 16,
							None};

	XVisualInfo *vi;
	Colormap cmap;
	int dpyWidth, dpyHeight;
	int i;
	int vidModeMajorVersion, vidModeMinorVersion;
	XF86VidModeModeInfo **modes;
	int modeNum;
	int bestMode;
	Atom wmDelete;
	Window winDummy;
	unsigned int borderDummy;

	GLWin.fs = fullscreen;
	bestMode = 0;

	GLWin.dpy = XOpenDisplay(0);
	GLWin.screen = DefaultScreen(GLWin.dpy);
	XF86VidModeQueryVersion(GLWin.dpy, &vidModeMajorVersion,
							&vidModeMinorVersion);

	XF86VidModeGetAllModeLines(GLWin.dpy, GLWin.screen, &modeNum, &modes);

	GLWin.deskMode = *modes[0];

	for (i = 0; i < modeNum; i++)
	{
		if ((modes[i]->hdisplay == width) && (modes[i]->vdisplay == height))
		{
			bestMode = i;
		}
	}

	vi = glXChooseVisual(GLWin.dpy, GLWin.screen, attrListDbl);
	if(NULL == vi)
	{
		vi = glXChooseVisual(GLWin.dpy, GLWin.screen, attrListSgl);
		printf("Singlebuffered : true\n");
	}
	else
	{
		printf("Doublebuffered : true\n");
	}

	GLWin.ctx = glXCreateContext(GLWin.dpy, vi, 0, GL_TRUE);

	cmap = XCreateColormap(GLWin.dpy, RootWindow(GLWin.dpy, vi->screen),vi->visual, AllocNone);
	GLWin.attr.colormap = cmap;
	GLWin.attr.border_pixel = 0;

	if(GLWin.fs)
	{
		XF86VidModeSwitchToMode(GLWin.dpy, GLWin.screen, modes[bestMode]);
		XF86VidModeSetViewPort(GLWin.dpy, GLWin.screen, 0, 0);
		dpyWidth = modes[bestMode]->hdisplay;
		dpyHeight = modes[bestMode]->vdisplay;
		XFree(modes);
		GLWin.attr.override_redirect = True;
		GLWin.attr.event_mask = ExposureMask | KeyPressMask | ButtonPressMask |
								StructureNotifyMask;
		GLWin.win = XCreateWindow(GLWin.dpy, RootWindow(GLWin.dpy, vi->screen),
								0, 0, dpyWidth, dpyHeight, 0, vi->depth, InputOutput, vi->visual,
								CWBorderPixel | CWColormap | CWEventMask | CWOverrideRedirect,
								&GLWin.attr);
		XWarpPointer(GLWin.dpy, None, GLWin.win, 0, 0, 0, 0, 0, 0);
		XMapRaised(GLWin.dpy, GLWin.win);
		XGrabKeyboard(GLWin.dpy, GLWin.win, True, GrabModeAsync,GrabModeAsync, CurrentTime);
		XGrabPointer(GLWin.dpy, GLWin.win, True, ButtonPressMask,
		GrabModeAsync, GrabModeAsync, GLWin.win, None, CurrentTime);
	}
	else
	{
		GLWin.attr.event_mask = ExposureMask | KeyPressMask | ButtonPressMask |
								StructureNotifyMask;
		GLWin.win = XCreateWindow(GLWin.dpy, RootWindow(GLWin.dpy, vi->screen),
								  0, 0, width, height, 0, vi->depth, InputOutput, vi->visual,
								  CWBorderPixel | CWColormap | CWEventMask, &GLWin.attr);
		wmDelete = XInternAtom(GLWin.dpy, "WM_DELETE_WINDOW", True);
		XSetWMProtocols(GLWin.dpy, GLWin.win, &wmDelete, 1);
		XSetStandardProperties(GLWin.dpy, GLWin.win, title,
		title, None, NULL, 0, NULL);
		XMapRaised(GLWin.dpy, GLWin.win);
	}

	glXMakeCurrent(GLWin.dpy, GLWin.win, GLWin.ctx);
	XGetGeometry(GLWin.dpy, GLWin.win, &winDummy, &GLWin.x, &GLWin.y,
				&GLWin.width, &GLWin.height, &borderDummy, &GLWin.depth);

	printf("Direct Rendering: %s\n",glXIsDirect(GLWin.dpy, GLWin.ctx) ? "true" : "false");

	printf("Running in %s mode\n",GLWin.fs ? "fullscreen" : "window");

	initGL();
}

/* Release our window */
void killGLWindow(void)
{
	if(GLWin.ctx)
	{
		if(!glXMakeCurrent(GLWin.dpy, None, NULL))
		{
			printf("Error releasing drawing context : killGLWindow\n");
		}
		glXDestroyContext(GLWin.dpy, GLWin.ctx);
		GLWin.ctx = NULL;
	}

	if(GLWin.fs)
	{
		XF86VidModeSwitchToMode(GLWin.dpy, GLWin.screen, &GLWin.deskMode);
		XF86VidModeSetViewPort(GLWin.dpy, GLWin.screen, 0, 0);
	}
	XCloseDisplay(GLWin.dpy);
}

/* Our event loop */
void run(void)
{
	XEvent event;

	int running = 1;
	while(running)
	{
		while(XPending(GLWin.dpy) > 0)
		{
			XNextEvent(GLWin.dpy, &event);
			switch(event.type)
			{
				case Expose:
					if (event.xexpose.count != 0)
						break;
					break;
				case ConfigureNotify:
					if ((event.xconfigure.width != GLWin.width) ||
						(event.xconfigure.height != GLWin.height))
					{
						GLWin.width = event.xconfigure.width;
						GLWin.height = event.xconfigure.height;
						resizeGLScene();
					}
					break;
				case KeyPress:
					switch(XLookupKeysym(&event.xkey,0))
					{
					case XK_Escape:									/* Quit application */
						running = 0;
						break;
					case XK_F1:										/* Switch fullscreen<->window mode */
						killGLWindow();
						createGLWindow("NeHe's Lesson 33",640,480,24,!GLWin.fs);
						break;
					}
					break;
				case ClientMessage:
					if (*XGetAtomName(GLWin.dpy, event.xclient.message_type) == *"WM_PROTOCOLS")
					{
						running = 0;
					}
					break;
				default:
					break;
			}
		}
		drawGLScene();
		swapBuffers();
	}
}

/* Setup basic Opengl stuff */
static void initGL(void)
{
	if(!LoadGLTextures())
	{
		printf("Error loading textures\n");
	}

	glShadeModel(GL_SMOOTH);
	glEnable(GL_TEXTURE_2D);
	glClearColor(0.0f, 0.0f, 0.0f, 0.5f);
	glClearDepth(1.0f);
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LEQUAL);
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
	resizeGLScene();
	glFlush();
}

/* Resize,set viewport,frustum */
static void resizeGLScene(void)
{
	float width,height;
	if(GLWin.height == 0)
		GLWin.height = 1;
	if(GLWin.width == 0)
		GLWin.width = 1;
	glViewport(0,0,GLWin.width,GLWin.height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	width = 0.5f;
	height = 0.5f * ((float)(GLWin.height)/GLWin.width);
	glFrustum(-width,width,-height,height,1.0f,100.0f);
	glMatrixMode(GL_MODELVIEW);
}

/* Swap Buffers */
static void swapBuffers(void)
{
	glXSwapBuffers(GLWin.dpy, GLWin.win);
}





