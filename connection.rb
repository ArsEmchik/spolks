require 'optparse'
require 'socket'
# require 'bindata'

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
  CON_TIMEOUT = 10.freeze

  class SocketTCP < Socket
    def initialize(port, addr)
      super(Socket::AF_INET, Socket::SOCK_STREAM, 0)
      setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
      @sockaddr = Socket.sockaddr_in(port, addr)
    end

    def sock_bind(queue = 10)
      bind(@sockaddr)
      listen(queue)
    end

    def sock_connect
      connect(@sockaddr)
    end

    def self.self_ip
      addr_lists = Socket.ip_address_list
      # addr_lists[1] && addr_lists[1].ip_address.empty? ? addr_lists[0].ip_address : addr_lists[1].ip_address
      # for test using localhost
      addr_lists[0].ip_address
    end
  end
end


