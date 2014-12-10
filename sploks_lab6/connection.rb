require 'optparse'
require 'socket'

module Utils
  class ArgParser
    def initialize
      @options = {}

      @optparse = OptionParser.new do |opts|

        opts.on(/^([0-9]{1,3}\.){3}[0-9]{1,3}$/) do |ip|
          @options[:addr] = ip
        end

        opts.on(/^[0-9]+$/) do |port|
          @options[:port] = port
        end

        @options[:filepath] = nil
        opts.on(/.+/) do |filepath|
          @options[:filepath] = filepath
        end
      end
    end

    def parse!
      @optparse.parse!
    end

    def [](label)
      @options[label]
    end
  end
end

module Connection
  EXG_SIZE = 1024.freeze
  CON_TIMEOUT = 20.freeze


  class SocketUDP < Socket
    def initialize(port, addr)
      super(Socket::AF_INET, Socket::SOCK_DGRAM, 0)
      setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true) # SO_REUSEADDR
      @sockaddr = Socket.sockaddr_in(port, addr)
    end

    def sock_bind
      bind(@sockaddr)
    end

    def sock_connect
      connect(@sockaddr)
    end
  end
end
