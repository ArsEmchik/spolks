require File.join(File.dirname(__FILE__), '', 'connection.rb')
require 'pathname'
require 'colored'

class Client
  def initialize(port, addr)
    @addr = addr
    @port = port

    @client = UDPSocket.new
    @client.bind(port, nil)
  end

  def send_file(file_path)
    if File.exist?(file_path)
      send_file_name(file_path)
      send_file_data(file_path)
    else
      puts 'Error, no such file!!'.red
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

    File.open(file_path, File::RDONLY) do |file|
      begin
        loop do
          data = file.read(Connection::EXG_SIZE)

          unless data
            send_buffer('')
            puts 'Finish to send file data'.green and break
          end

          send_buffer(data)
          puts 'was sending: ' + (data_count += data.length).to_s.yellow
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
    _, ready_to_write, = IO.select(nil, [@client], nil, Connection::CON_TIMEOUT)

    if ready_to_write.nil? || ready_to_write.empty?
      raise 'ERROR! Connection with server is lost!'
    end

    ready_to_write.first.send(data, 0, @addr, @port)
  end
end

opts = Utils::ArgParser.new
opts.parse!

server = Client.new(opts[:port] || 2004, opts[:addr] || '127.0.0.1')
server.send_file('labs.pdf')
