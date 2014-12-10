require File.join(File.dirname(__FILE__), '', 'connection.rb')
require 'colored'

class Server
  def initialize(port, addr)
    puts "Start UDP server".yellow

    @sockets = Connection::SocketUDP.new(port, addr)
    @sockets.sock_bind

    @clients = {}
  end

  def run
    loop do
      ready_sockets, _, _ = IO.select([@sockets], nil, nil, Connection::CON_TIMEOUT)

      unless ready_sockets
        puts 'Connection is timeout!'.red
        break
      end

      ready_sockets.each do |socket|
        data, client_info = socket.recvfrom(Connection::EXG_SIZE)
        addr = client_info.inspect.split(' ')[1]

        unless @clients.keys.include? addr
          file_name = data.rstrip.length > 255 ? 'unknown_name' : data.rstrip
          @clients[addr] = File.new(addr + '_' + file_name, File::CREAT|File::TRUNC|File::WRONLY)
          next
        end

        if data.nil? || data.empty?
          @clients[addr].close
          @clients.delete(addr)
          puts 'received all packets from:'.yellow + addr.red
        else
          @clients[addr].puts(data)
          puts 'get data from: '.green + addr.red
        end
      end
    end
  end
end

opts = Utils::ArgParser.new
opts.parse!

server = Server.new(opts[:port] || 2004, opts[:addr] || '192.168.43.195')
server.run
