require File.join(File.dirname(__FILE__), '..', 'connection.rb')
require 'pathname'
require 'colored'

class Client
  def initialize(port, addr)
    @client = Connection::SocketTCP.new(port, addr)
    @client.sock_connect
    @can_send = true
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
    send_buffer(file_name)
  end

  def send_file_data(file_path)
    File.open(file_path, File::RDONLY) do |file|
      begin
        loop do
          if @can_send
            data = file.read(Connection::EXG_SIZE)
            p 'Finish to send file data' and break unless data
            @can_send = false
          end
          send_buffer(data)
        end

      rescue Exception => e
        p e.message
      ensure
        @client.close if @client
      end
    end
  end

  private

  def send_buffer(data)
    ready_client = get_ready_client

    if ready_client
      @can_send = true if ready_client.send(data, 0) # != 0
    end
  end

  def get_ready_client
    _, ready_client, = IO.select(nil, [@client], nil, Connection::CON_TIMEOUT)

    if ready_client.nil? || ready_client.empty?
      raise 'ERROR! Connection to server is time out!'
    end

    ready_client.first
  end
end

opts = Utils::ArgParser.new
opts.parse!

# server = Client.new(opts[:port] || 2003, opts[:addr] || '192.168.43.18')
server.send_file('big.exe')
