# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "ffi"

module TinyPing
  extend FFI::Library
  ffi_lib '/opt/lib/libtinyping.so'
  attach_function :init, [:int, :int], :int
  attach_function :ping, [:string], :long_long
  attach_function :deinit, [], :void
end

# Pings listed hosts.
class LogStash::Inputs::Ping < LogStash::Inputs::Base
  config_name "ping"
  milestone 1

  # Hosts list
  config :host, :validate => :array, :required => true

  # Pinging loop interval in seconds
  config :interval, :validate => :number, :default => 60

  # Ping timeout in seconds
  config :timeout, :validate => :number, :default => 2

  # Ping packet time-to-live
  config :ttl, :validate => :number, :default => 255

  public
  def register    
    raise if TinyPing.init(@ttl, @timeout) < 0
  end # def register

  def run(queue) 
    # wait for initialization to complete
    # -1 means socket is not ready
    tries = 5
    initialised = (TinyPing.ping("google.com") != -1)
    while not initialised and tries >= 0
      tries -= 1
      sleep 3
      initialised = (TinyPing.ping("google.com") != -1)
    end
    raise unless initialised

    while true
      begin
        # This is fully sequential,
        # no additional threads are spawned
        @host.each do |host|
          event=LogStash::Event.new
          event["type"] = "ping"
          event["host"] = host
          res = TinyPing.ping(host)
          if res >= 0
            event["pingable"] = true
            event["ping_time"] = res / 1000.0
          else
            event["pingable"] = false
            event["ping_err"] = case res
              when -4 then "Cannot resolve hostname"
              when -5 then "Sending echo request failed"
              when -6 then "Destination unreachable"
              when -7 then "Timeout"
              else         "Unknown error"
            end
          end
          queue << event
        end
        sleep @interval
      rescue LogStash::ShutdownSignal
        break
      end
    end # while true
    finished
  end # def run

  public
  def teardown
    TinyPing.deinit
    @logger.debug("ping shutting down.")
    finished
  end # def teardown

end # class LogStash::Inputs::Ping
