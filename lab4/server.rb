require File.join(File.dirname(__FILE__), '..', 'connection.rb')
require 'colored'

class Server
  def initialize(port, addr)
    @server = Connection::SocketTCP.new(port, addr)
    @server.sock_bind
    puts "Server is running on: ".red + "#{port}".green + " port.".red
  end

  def receive_file
    begin
      client, client_info = @server.accept
      p client_info

      file_name = get_buffer(client).rstrip
      if file_name.nil? || file_name.empty? || file_name.length > Connection::EXG_SIZE
        raise 'ERROR. Error while getting file name!'
      end

      listen_client(client, file_name)

    rescue Exception => e
      p e.message
    ensure
      @server.close and client.close if @server
    end
  end

  private

  def listen_client(client, file_name)
    data_count = 0
    File.open('s' + file_name, File::CREAT|File::TRUNC|File::WRONLY) do |file|
      loop do
        data = get_buffer(client)
        break if data.nil? || data.empty?

        puts 'receive extra data'.green and next if data.include? 'extra'
        puts 'was received: ' + (data_count += data.length).to_s

        file.write(data)
      end
    end
  end

  def get_ready_server(client)
    ready_server, _, urgent_msg = IO.select([client], nil, nil, Connection::CON_TIMEOUT)

    if (ready_server.nil? || ready_server.empty?) && (urgent_msg.nil? || urgent_msg.empty?)
      raise 'ERROR! Connection with client is time out!'
    end

    (urgent_msg && urgent_msg.first) || (ready_server && ready_server.first)
  end


  def get_buffer(client)
    ready_server = get_ready_server(client)
    ready_server.recv(Connection::EXG_SIZE)
  end
end

opts = Utils::ArgParser.new
opts.parse!

server = Server.new(opts[:port] || 2003, opts[:addr] || Connection::SocketTCP.self_ip)
server.receive_file
