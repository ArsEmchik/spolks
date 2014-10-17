load '../connection.rb'

opts = Utils::ArgParser.new
opts.parse!

class Client
  def initialize(port, addr)
    @client = Connection::SocketTCP.new(port, addr)
    @client.sock_bind
    @can_send = true
  end

  def send_file(file_path)
    File.open(file_path, File::RDONLY) do |file|
      begin
        loop do
          _, write_buf, = IO.select(nil, [@client], nil, Connection::CON_TIMEOUT)
          break unless write_buf

          if @can_send
            data = file.read(Connection::EXG_SIZE)
            @can_send = false
          end

          if s = write_buf.shift
            break unless data
            @can_send = true if s.send(data, 0) # != 0
          end
        end

      ensure
        @client.close if @client
      end
    end
  end
end

opts = Utils::ArgParser.new
opts.parse!

server = Client.new(opts[:addr], opts[:port] || 2000)
server.send_file(opts[:filepath])
