require File.join(File.dirname(__FILE__), '..', 'connection.rb')
require 'colored'

class Server
  include LibSocket
  UDP = 'UDP'.freeze
  TCP = 'TCP'.freeze

  def initialize(port, addr, opts = nil)
    if opts
      puts "UDP connection".yellow
      @server = Connection::SocketUDP.new(port, addr)
      @server.sock_bind

      @kind = UDP
    else
      puts "TCP connection".yellow
      @server = Connection::SocketTCP.new(port, addr)
      @server.sock_bind
      @client, client_info = @server.accept
      p client_info

      @kind = TCP
    end

    puts "Server is running on: ".red + "#{port}".green + " port.".red
  end

  def receive_file
    begin
      receive_file_TCP if @kind == TCP
      receive_file_UDP if @kind == UDP

    rescue Exception => e
      p e.message
    ensure
      @server.close and @client.close if @server
    end
  end

  private

  def receive_file_UDP
    file_name = get_buffer_udp(@server).rstrip
    if file_name.nil? || file_name.empty? || file_name.length > Connection::EXG_SIZE
      raise 'ERROR. Error while getting file name!'
    end

    listen_client(@server, file_name)
  end


  def receive_file_TCP
    file_name = get_buffer_tcp(@client).rstrip
    if file_name.nil? || file_name.empty? || file_name.length > Connection::EXG_SIZE
      raise 'ERROR. Error while getting file name!'
    end

    listen_client(@client, file_name)
  end

  def listen_client(client, file_name)
    data_count = 0

    File.open('new_' + file_name, File::CREAT|File::TRUNC|File::WRONLY) do |file|
      loop do
        data = @kind == TCP ?  get_buffer_tcp(client) : get_buffer_udp(client)
        break if data.nil? || data.empty?
        file.write(data)

        puts 'was received: ' + (data_count += data.length).to_s
      end
    end
  end

  def get_buffer_udp(server)
    ready_server, = IO.select([server], nil, nil, Connection::CON_TIMEOUT)

    if ready_server.nil? || ready_server.empty?
      raise 'ERROR! Connection with client is lost!'
    end

    ready_server.first.recv(Connection::EXG_SIZE)
  end

  def get_buffer_tcp(client)
    data = LibSocket.read(client, Connection::EXG_SIZE, Connection::SocketTCP::MSG_OOB)
    puts 'receive extra data'.green unless data.nil?

    data = LibSocket.read(client, Connection::EXG_SIZE)
    raise 'ERROR! Connection to server is lost!' if data == -1
    data
  end
end

opts = Utils::ArgParser.new
opts.parse!

server = Server.new(opts[:port] || 2004, opts[:addr] || '127.0.0.1', 1) # Connection::SocketTCP.self_ip
server.receive_file
