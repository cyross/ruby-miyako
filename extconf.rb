require 'mkmf'

if /mswin32/ =~ CONFIG["arch"]
  have_library("SDL")
else
  sdl_config = with_config('sdl-config', 'sdl-config')
  
  $CFLAGS += ' ' + `#{sdl_config} --cflags`.chomp
  $LOCAL_LIBS += ' ' + `#{sdl_config} --libs`.chomp
  
  if /-Dmain=SDL_main/ =~ $CFLAGS then
    def try_func(func, libs, headers = nil, &b)
      headers = cpp_include(headers)
      try_link(<<"SRC", libs, &b) or try_link(<<"SRC", libs, &b)
#{headers}
/*top*/
int main(int argc,char** argv) { return 0; }
int t() { #{func}(); return 0; }
SRC
#{COMMON_HEADERS}
#{headers}
/*top*/
int main(int argc,char** argv) { return 0; }
int t() { void ((*volatile p)()); p = (void ((*)()))#{func}; return 0; }
SRC
    end
  end
end

if enable_config("static-libs",false) then
  have_library("SDL")
  have_library("freetype")
end

if have_library("SDL_ttf","TTF_Init") then
  $CFLAGS+= " -D HAVE_SDL_TTF "
end

create_makefile('miyako_no_katana')
