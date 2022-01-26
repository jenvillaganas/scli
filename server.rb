require 'eventmachine'
require 'em-websocket'
require 'pry'
require 'json'
require 'open3'

EM.run {
  EM::WebSocket.run(:host => "0.0.0.0", :port => 8082) do |ws|
    ws.onopen { |handshake|
      puts "WebSocket connection open"
      # Access properties on the EM::WebSocket::Handshake object, e.g.
      # path, query_string, origin, headers

      # Publish message to the client
      ws.send "Hello Client, you connected to #{handshake.path}"
    }

    ws.onclose { puts "Connection closed" }

    ws.onmessage { |msg|
      puts "Recieved message: #{msg}"
      data = JSON.parse(msg)
      event = data["event"]

      case event
      when "spl-transfer"
        token_address = data["token_address"]
        recipient = data["recipient"]

        if token_address && recipient
          stdin, stdout, stderr, wait_thr = Open3.popen3(
            'spl-token', 'transfer', token_address, '1', recipient, '--allow-unfunded-recipient', '--fund-recipient')

          log = stdout.read
          err = stderr.read
          puts log
          puts err
          split_with_signature = log.split("Signature: ")
          if split_with_signature.count > 1
            signature = split_with_signature.last.strip
            ws.send({status: 200, signature: signature}.to_json)
          elsif err
            ws.send({status: 500, err: err}.to_json)
          else
            ws.send({status: 500, log: log + err }.to_json)
          end
        else
          ws.send("failed")
        end
      end
    }
  end
}
