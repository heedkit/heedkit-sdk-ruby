# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "socket"
require "heedkit"

# Minimal one-shot HTTP server for exercising the client without WebMock.
def with_stub_server(status: "200 OK", body: "{}")
  server = TCPServer.new("127.0.0.1", 0)
  port = server.addr[1]
  thread = Thread.new do
    socket = server.accept
    # Drain the request headers.
    while (line = socket.gets) && line.strip != ""; end
    socket.write("HTTP/1.1 #{status}\r\nContent-Type: application/json\r\nContent-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}")
    socket.close
  end
  yield "http://127.0.0.1:#{port}"
ensure
  thread&.join
  server&.close
end

# Like with_stub_server, but parses and returns the request (method/path/headers/body)
# so wire-level behavior (identity headers, signed payloads) can be asserted.
def with_capturing_server(body: "{}")
  server = TCPServer.new("127.0.0.1", 0)
  port = server.addr[1]
  captured = {}
  thread = Thread.new do
    socket = server.accept
    request_line = socket.gets
    captured[:method], captured[:path], = request_line.split(" ")
    headers = {}
    while (line = socket.gets) && line.strip != ""
      k, v = line.split(":", 2)
      headers[k.strip.downcase] = v.strip
    end
    captured[:headers] = headers
    length = headers["content-length"].to_i
    captured[:body] = length.positive? ? socket.read(length) : ""
    socket.write("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}")
    socket.close
  rescue IOError
    # Server closed before a request arrived (the yield raised) — die quietly.
  end
  yield "http://127.0.0.1:#{port}"
  captured
ensure
  # Close first: unblocks a thread still parked in accept, so join can't hang.
  server&.close
  thread&.join(2)
end
