require File.join(File.dirname(__FILE__), '..', 'connection.rb')
require 'pathname'
require 'colored'

class Client
  EXTRA_MSG = 'extra: some string'.freeze

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
      p 'Error, no such file!!'
    end
  end

  private

  def send_file_name(file_path)
    file_name = Pathname.new(file_path).basename.to_s.ljust(Connection::EXG_SIZE)
    raise 'ERROR! File name is too longer' if file_name.length > Connection::EXG_SIZE
    send_buffer(file_name)
  end

  def send_file_data(file_path)
    data_count = 0
    send_extra_data_count = 0
    File.open(file_path, File::RDONLY) do |file|
      begin
        loop do
          if @can_send
            data = file.read(Connection::EXG_SIZE)
            puts 'Finish to send file data' and break unless data
            puts 'was sending: ' + (data_count += data.length).to_s

            send_extra_data_count += 1
            @can_send = false
          end

          if send_extra_data_count == 10
            send_buffer(EXTRA_MSG, Connection::SocketTCP::MSG_OOB)
            puts 'Send extra data'.red
            send_extra_data_count = 0
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

  def send_buffer(data, extra_args = 0)
    ready_client = get_ready_client

    if ready_client
      @can_send = true if ready_client.send(data, extra_args)
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

server = Client.new(opts[:port] || 2003, opts[:addr] || '127.0.0.1')
server.send_file('big.exe')
