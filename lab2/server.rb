load '../connection.rb'

class Server
  def initialize(port, addr)
    @server = Connection::SocketTCP.new(port, addr)
    @server.sock_bind
    puts "Server is running on: ".red + "#{port}".green + " port.".red
  end

  def receive_file(file_path = 'some_file.txt')
    File.open(file_path, File::CREAT|File::TRUNC|File::WRONLY) do |file|
      listen_client(file)
    end
  end

  private

  def listen_client(file)
    begin
      income, client_info = @server.accept
      p client_info

      loop do
        read_buf, = IO.select([income], nil, nil, Connection::CON_TIMEOUT)
        break unless read_buf

        if s = read_buf.shift
          data = s.recv(Connection::EXG_SIZE)
          break if data.empty?

          file.write(data)
        end
      end
    ensure
      @server.close and income.close if server
    end
  end
end

opts = Utils::ArgParser.new
opts.parse!

server = Server.new(opts[:addr] || 'localhost', opts[:port] || 2000)
server.receive_file
