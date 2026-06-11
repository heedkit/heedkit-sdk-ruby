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
