require_relative '../lib/iou'
require 'socket'

socket = TCPServer.open('127.0.0.1', 1234)
puts "Listening on  port 1234..."

@ring = IOU::Ring.new

@ring.prep_accept(fd: socket.fileno, multishot: true) do |c|
  setup_connection(c[:result]) if c[:result] > 0
end

def setup_connection(fd)
  buffer +''
  echo_prep_read(fd, buffer)
end

def echo_prep_read(fd, buffer)
  @ring.prep_read(fd: fd, buffer: buffer, buffer_offset: -1) do |c|
    if c[:result] > 0
      echo_lines(fd, buffer)
      echo_prep_read(fd, buffer)
    else
      @ring.prep_close(fd: fd)
    end
  end
end

def echo_lines(fd, buffer)
  sep = $/
  sep_size = sep.bytesize
  
  while true
    idx = buffer.index(sep)
    if idx
      line = buffer.slice!(0, idx + sep_size)
      @ring.prep_write(fd: fd, buffer: line)
    else
      break
    end
  end
end

trap('SIGINT') { exit! }
while true
  @ring.submit
  @ring.process_completions
end
