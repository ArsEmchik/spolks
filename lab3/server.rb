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
    File.open(file_name, File::CREAT|File::TRUNC|File::WRONLY) do |file|
      loop do
        data = get_buffer(client)
        break if data.nil? || data.empty?
        file.write(data)
      end
    end
  end

  def get_ready_server(client)
    ready_server, = IO.select([client], nil, nil, Connection::CON_TIMEOUT)

    if ready_server.nil? || ready_server.empty?
      raise 'ERROR! Connection with client is time out!'
    end

    ready_server.first
  end


  def get_buffer(client)
    ready_server = get_ready_server(client)
    ready_server.recv(Connection::EXG_SIZE)
  end
end

opts = Utils::ArgParser.new
opts.parse!

server = Server.new(opts[:port] || 2003, opts[:addr] || '127.0.0.1')
server.receive_file
