require 'timeout'
require 'json'
require 'socket'

class Batsd

	DEFAULTS = {
		:host => "127.0.0.1",
		:port => 8127,
		:timeout => 2000,
		:max_attempts => 2
	}

	def host
      	@options[:host]
    end

    def port
      	@options[:port]
    end

    def timeout
      	@options[:timeout]
    end

    def max_attempts
    	@options[:max_attempts]
    end

    attr_accessor :remote

    def initialize(options = {})
		@options = _parse_options(options)
		connect!
    end

    def ping
        send_command("ping")
    end

    # Get the set of datapoints batsd knows about. Will return an array of
    # strings
    def available
        keys = send_command("available")
        keys.collect do |k|
            if k.match /^timer/
                ["mean", "min", "max", "upper_90", "stddev", "count"].collect{|a| "#{k}:#{a}"}
            else
                k
            end
        end.flatten
    end

    # Get the values for a given <code>metric_name</code> that's contained in the available
    # set of datapoints within the range of <code>start_timestamp</code> to
    # <code>end_timestamp</code>
    def stats(metric_name, start_timestamp, end_timestamp=Time.now, attempt=0)
        results = []
        values = send_command("values #{metric_name} #{start_timestamp.to_i} #{end_timestamp.to_i}")
        if values[metric_name].nil?
            if attempt < MAX_ATTEMPTS
                return values(metric_name, start_timestamp, end_timestamp, attempt+1)
            else
                raise InvalidValuesError
            end
        end
        results = values[metric_name].collect{|v| { timestamp: Time.at(v["timestamp"].to_i), value: v["value"].to_f }  }
        results
    end
   

    protected

    def _parse_options(options)
		defaults = DEFAULTS.dup
		options = options.dup

		defaults.keys.each do |key|
			options[key] ||= defaults[key]
		end

		options
    end

    private

    	# Connect to the remote batsd server over TCP
		def connect!
			Timeout::timeout(5) do
				self.remote = TCPSocket.new(host, port)
			end
			rescue Timeout::Error => e
				raise ConnectionTimeoutError
			rescue
				raise CannotConnectError
		end

		# Send a command to the remote and attempt to parse the response as JSON
        def send_command(command, attempt=0)
            Timeout::timeout(timeout.to_f / 1000.0) do
                connect! unless self.remote
                self.remote.puts command
                @response = self.remote.gets
                unless command == "ping"
                    results = JSON.parse(@response)
                else
                    results = @response.delete("\n")
                end
                results
            end
            rescue TimeoutError => e
                if attempt < max_attempts 
                    query_remote(command, attempt+1)
                else
                    raise CommandTimeoutError
                end
            rescue Exception => e
                if attempt < MAX_ATTEMPTS 
                    query_remote(command, attempt+1)
                else
                    self.remote = nil
                    raise CommandError
                end
        end
end

require 'batsd/version'