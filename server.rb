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
        recipients = data["recipients"]
        binding.pry

        if token_address && recipients
          threads = []
          success = []
          failed = []
          recipients.each_slice(3).to_a.each do |recipient_arr|
            small_threads = []
            recipient_arr.each do |recipient|
              small_threads << Thread.new do
                stdin, stdout, stderr, wait_thr = Open3.popen3(
                  'spl-token', 'transfer', token_address, '1', recipient, '--allow-unfunded-recipient', '--fund-recipient')

                log = stdout.read
                err = stderr.read
                puts log
                puts err
                split_with_signature = log.split("Signature: ")
                if split_with_signature.count > 1
                  signature = split_with_signature.last.strip
                  # ws.send({status: 200, signature: signature}.to_json)
                  success << {recipient: recipient, signature: signature}
                elsif err
                  failed << {recipient: recipient, log: err}
                else
                  failed << {recipient: recipient, log: log + err}
                end
              end
            end

            small_threads.each(&:join)
            puts "Completed: #{recipient_arr}"
          end

          ws.send({status: 200, signature: {success: success, failed: failed}}.to_json)
        else
          ws.send("failed")
        end
      end
    }
  end
}
