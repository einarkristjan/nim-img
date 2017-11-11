import sdl2
import sdl2.image
import opengl


# --------------------------------------------------------------------------------
# sdl2 setup

discard sdl2.init(INIT_EVERYTHING)

# set oGL version before creating the window
discard glSetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
discard glSetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
discard glSetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

var
  screen_width: cint = 640
  screen_height: cint = 480
  window = createWindow("Modern OpenGL", 100, 100, screen_width, screen_height, SDL_WINDOW_OPENGL)
  context = window.glCreateContext()


# --------------------------------------------------------------------------------
# opengl initialization / settings

loadExtensions()

glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
glEnable(GL_BLEND)

glClearColor(0.93, 0.93, 0.93, 1.0)


# --------------------------------------------------------------------------------
# shaders helper

proc create_shader*(src: string, shader_type: GLenum): GLuint =
  var
    shader_array = allocCStringArray([readFile(src)])
    shader = glCreateShader(shader_type)
    is_compiled: GLint

  glShaderSource(shader, 1, shader_array, nil)
  glCompileShader(shader)
  deallocCStringArray(shader_array)
  glGetShaderiv(shader, GL_COMPILE_STATUS, is_compiled.addr)

  if is_compiled > 0:
    echo src, " compiled successfully."
    return shader

  # output error
  var log_size: GLint
  glGetShaderiv(shader, GL_INFO_LOG_LENGTH, log_size.addr)
  var log_str = cast[ptr GLchar](alloc(log_size))
  glGetShaderInfoLog(shader, log_size.GLsizei, nil, log_str)
  echo src, " wasn't compiled. Reason:\n", $log_str
  dealloc(log_str)


# --------------------------------------------------------------------------------
# shaders

var
  vertex_shader = create_shader("shader.vert", GL_VERTEX_SHADER)
  fragment_shader = create_shader("shader.frag", GL_FRAGMENT_SHADER)
  shader_program = glCreateProgram()

glAttachShader(shader_program, vertex_shader)
glAttachShader(shader_program, fragment_shader)

glLinkProgram(shader_program)
glValidateProgram(shader_program)

glDeleteShader(vertex_shader)
glDeleteShader(fragment_shader)

glUseProgram(shader_program)


# --------------------------------------------------------------------------------
# image (depends on shader program to be ready)

discard image.init()

var
  img = load("image.png")
  texture_id: Gluint
  texture_location = glGetUniformLocation(shader_program, "tex");

glGenTextures(1, texture_id.addr)
glBindTexture(GL_TEXTURE_2D, texture_id)

if texture_id == 0:
  echo "failed to create texture"

# texture settings

glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)

glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.ord, img.w,  img.h, 0, GL_RGBA, GL_UNSIGNED_BYTE, img.pixels);
glBindTexture(GL_TEXTURE_2D, 0);

glActiveTexture(GL_TEXTURE0);
glBindTexture(GL_TEXTURE_2D, texture_id)

# set uniform for shaders

glUniform1i(texture_location, 0)


# --------------------------------------------------------------------------------
# vertex array object

var vao: GLuint
glGenVertexArrays(1, vao.addr)
glBindVertexArray(vao)


# --------------------------------------------------------------------------------
# vertex buffer object

var vbo: GLuint
glGenBuffers(1, vbo.addr)
glBindBuffer(GL_ARRAY_BUFFER, vbo)

var vertex_data: array[36, GLFloat] = [
#  X      Y      Z      R     G     B     A     U      V 
   0.5f,  0.5f,  0.0f,  0.0,  1.0,  1.0,  1.0,  1.0f,  1.0f,
  -0.5f,  0.5f,  0.0f,  1.0,  0.0,  1.0,  0.5,  0.0f,  1.0f,
   0.5f, -0.5f,  0.0f,  1.0,  1.0,  0.0,  1.0,  1.0f,  0.0f,
  -0.5f, -0.5f,  0.0f,  0.0,  0.0,  1.0,  0.5,  0.0f,  0.0f,
]

# set the XYZ for attribute for shaders
glEnableVertexAttribArray(0)
glVertexAttribPointer(0, 3, cGL_FLOAT, GL_FALSE, 9 * sizeof(GLfloat), cast[Glvoid](0 * sizeof(GLfloat)))

# set the RGBA for attribute for shaders
glEnableVertexAttribArray(1)
glVertexAttribPointer(1, 4, cGL_FLOAT, GL_FALSE, 9 * sizeof(GLfloat), cast[Glvoid](3 * sizeof(GLfloat)))

# set the UV for attribute for shaders
glEnableVertexAttribArray(2)
glVertexAttribPointer(2, 2, cGL_FLOAT, GL_FALSE, 9 * sizeof(GLfloat), cast[Glvoid](7 * sizeof(GLfloat)))

# send to gl
glBufferData(GL_ARRAY_BUFFER, vertex_data.sizeof, vertex_data.addr, GL_STATIC_DRAW)


# --------------------------------------------------------------------------------
# index buffer object (sharing vertexes between triangles)

var ibo: Gluint
glGenBuffers(1, ibo.addr)
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo)

var index_data: array[6, GLuint] = [
  0.GLuint, 1.GLuint, 2.GLuint, # first triangle
  2.GLuint, 1.GLuint, 3.GLuint, # second triangle
]

# send to gl
glBufferData(GL_ELEMENT_ARRAY_BUFFER, index_data.sizeof, index_data.addr, GL_STATIC_DRAW)


# --------------------------------------------------------------------------------
# loop

var
  evt = sdl2.defaultEvent
  run_app = true

while run_app:
  while pollEvent(evt):
    if evt.kind == QuitEvent:
      run_app = false
      break

  glClear(GL_COLOR_BUFFER_BIT)

  glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, nil)
  glSwapWindow(window)

destroy window
