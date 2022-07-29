//
// @Author: David Kviloria
// @Date:   2017-05-18T16:00:00-05:00
//
package application

import SDL "vendor:sdl2"
import OGL "vendor:OpenGL"

GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 6

Window :: struct {
  ctx      :   ^SDL.Window,
  width    :   i32,
  height   :   i32,
  title    :   cstring,
}

Application :: struct {
  window      :    Window,
  event       :    ^SDL.Event,
  gl_context  :    SDL.GLContext,
}

Init_Window :: proc(w: i32, h: i32, title: cstring) -> Window {

  wind := Window{
    width = w,
    height = h,
    ctx = SDL.CreateWindow(title, SDL.WINDOWPOS_UNDEFINED, SDL.WINDOWPOS_UNDEFINED, w, h, {.OPENGL}),
  }

  return wind
}

Init_Application :: proc(w: i32, h: i32, title: cstring) -> Application {

  app := Application { window = Init_Window(w, h, title), event  = new(SDL.Event), }
  app.gl_context = SDL.GL_CreateContext(app.window.ctx)

	SDL.GL_MakeCurrent(app.window.ctx, app.gl_context)
	OGL.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, SDL.gl_set_proc_address)

  SDL.GL_SetAttribute(.CONTEXT_PROFILE_MASK,  i32(SDL.GLprofile.CORE))
	SDL.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, GL_VERSION_MAJOR)
	SDL.GL_SetAttribute(.CONTEXT_MINOR_VERSION, GL_VERSION_MINOR)

  return app
}

Is_Okay :: proc(app: Application) -> bool {
  return (app.window.ctx != nil && SDL.GetError() != nil)
}

Swap_Buffers:: proc(app: Application) {
  SDL.GL_SwapWindow(app.window.ctx)
}

Pull_Event :: proc(app: Application) -> SDL.bool {
  return SDL.PollEvent(app.event)
}

Get_Event :: proc(app: Application) -> ^SDL.Event {
  return app.event
}

Get_KeyCode :: proc(app: Application) -> SDL.Keycode {
  return Get_Event(app).key.keysym.sym
}

Cleanup_Application :: proc(app: Application) {
  SDL.DestroyWindow(app.window.ctx)
}
