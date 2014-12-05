require File.join(File.dirname(__FILE__), '..', 'connection.rb')
require 'pathname'
require 'colored'

class Client
  include LibSocket
  EXTRA_MSG = 'EXTRA DATA'.ljust(Connection::EXG_SIZE)

  UDP = 'UDP'.freeze
  TCP = 'TCP'.freeze

  def initialize(port, addr, opts = nil)
    begin
      @client = opts ? Connection::SocketUDP.new(port, addr)
      : Connection::SocketTCP.new(port, addr)

      @kind = opts ? UDP : TCP

      @kind == UDP ? @client.sock_bind : @client.sock_connect
    rescue Exception => e
      p e.message and exit
    end
  end

  def send_file(file_path)
    if File.exist?(file_path)
      send_file_name(file_path)
      send_file_data(file_path)
    else
      p 'Error, no such file!!'.red
    end
  end

  private

  def send_file_name(file_path)
    file_name = Pathname.new(file_path).basename.to_s.ljust(Connection::EXG_SIZE)
    raise 'ERROR! File name is too longer' if file_name.length > Connection::EXG_SIZE
    @kind == TCP ? send_buffer_tcp(file_name) : send_buffer_udp(file_name)
  end

  def send_file_data(file_path)
    data_count = 0
    send_extra_data_count = 0

    File.open(file_path, File::RDONLY) do |file|
      begin
        loop do
          data = file.read(Connection::EXG_SIZE)

          unless data
            puts 'Finish to send file data'
            send_buffer('')
            break
          end

          @kind == TCP ? send_buffer_tcp(data) : send_buffer_udp(data)
          puts 'was sending: ' + (data_count += data.length).to_s
        end

      rescue Exception => e
        p e.message
      ensure
        @client.close if @client
      end
    end
  end

  private

  def send_buffer_udp(data, args = 0)
    _, ready_to_write, = IO.select(nil, [@client], nil, Connection::CON_TIMEOUT)

    if ready_to_write.nil? || ready_to_write.empty?
      raise 'ERROR! Connection with server is lost!'
    end

    ready_to_write.first.send(data, 0)
  end

  def send_buffer_tcp(data, args = 0)
    # raise 'ERROR! Connection to server is lost!' unless @client.send(data, 0) # != 0
    raise 'ERROR! Connection to server is lost!' if LibSocket.write(@client, data, Connection::EXG_SIZE, args) == -1
  end
end

opts = Utils::ArgParser.new
opts.parse!

server = Client.new(opts[:port] || 2004, opts[:addr] || '127.0.0.1', 'u') # '192.168.43.227'
server.send_file('test.mp3')
