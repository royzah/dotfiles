# GDB config — better defaults for embedded + C/C++ debugging

# Pretty printing
set print pretty on
set print array on
set print array-indexes on
set print object on
set print vtbl on
set print demangle on
set print asm-demangle on

# History
set history save on
set history size 10000
set history filename ~/.gdb_history
set history expansion on

# Don't stop on signals commonly used in embedded
handle SIGPIPE nostop noprint pass
handle SIGUSR1 nostop noprint pass
handle SIGUSR2 nostop noprint pass

# Better output
set pagination off
set confirm off
set verbose off

# Source-level debugging
set listsize 20

# Allow loading .gdbinit from project directories
set auto-load safe-path /

# Colored prompt
set prompt \033[1;34m(gdb) \033[0m

# Useful macros
define xxd
  dump binary memory /tmp/gdb_dump.bin $arg0 $arg0+$arg1
  shell xxd /tmp/gdb_dump.bin
end
document xxd
  Hex dump memory: xxd <address> <length>
end

define reg
  info registers
end

define ctx
  info threads
  bt
end
document ctx
  Show threads and backtrace
end
