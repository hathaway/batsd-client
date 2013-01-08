require 'timeout'
require 'json'
require 'socket'

##
# A batsd client for querying data from a batsd server.
class Batsd

	##
	# The default option values.
	DEFAULTS = {
		:host => "127.0.0.1",
		:port => 8127,
		:timeout => 2000,
		:max_attempts => 2
	}

	##
	# The hostname of the batsd server.
	def host
      	@options[:host]
    end

    ##
    # The port the batsd server is running on.
    def port
      	@options[:port]
    end

    ##
    # The timeout in milliseconds to use for the TCP connection.
    def timeout
      	@options[:timeout]
    end

    ##
    # The maxiumum number of attempts to make when querying for data. 
    # If an error is encountered, it will try this many total times before throwing an exception.
    def max_attempts
    	@options[:max_attempts]
    end

    attr_accessor :remote

    def initialize(options = {})
		@options = _parse_options(options)
		connect!
    end

    ##
    # Send the 'ping' command to the server.
	#
	# @return [String] The response received from the server.
    def ping
        send_command("ping")
    end

    # Queries for the available keys in the batsd server.
	#
	# @return [Array] An array of string keys.
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

    ##
    # Get the stats for a given <code>metric_name</code> that's contained in the available
    # set of datapoints within the range of <code>start_timestamp</code> to
    # <code>end_timestamp</code>
	#
	# @param [String] metric_name
	# 	The key for the metric you are querying for.
	#
	# @param [Time] start_timestamp
	# 	The start of the time range of the query.
	#
	# @param [Time] end_timestamp
	# 	The end of the time range of the query. Defaults to the current time.
	#
	# @param [Integer] attempts
	# 	The number of attempts that have been made for this query. Defaults to 0.
	#
	# @return [Array] An array of hashes. Each hash contains the <code>:timestamp</code>
	# 	and <code>:value</code> of the data point.
    def stats(metric_name, start_timestamp, end_timestamp=Time.now, attempt=0)
        results = []
        values = send_command("values #{metric_name} #{start_timestamp.to_i} #{end_timestamp.to_i}")
        if values[metric_name].nil?
            if attempt < max_attempts
                return values(metric_name, start_timestamp, end_timestamp, attempt+1)
            else
                raise InvalidValuesError
            end
        end
        results = values[metric_name].collect{|v| { timestamp: Time.at(v["timestamp"].to_i), value: v["value"].to_f }  }
        results
    end

    ##
    # Get only the values of the stats for a given <code>metric_name</code> 
    # that's contained in the available set of datapoints within the range 
    # of <code>start_timestamp</code> to <code>end_timestamp</code>
	#
	# @param [String] metric_name
	# 	The key for the metric you are querying for.
	#
	# @param [Time] start_timestamp
	# 	The start of the time range of the query.
	#
	# @param [Time] end_timestamp
	# 	The end of the time range of the query. Defaults to the current time.
	#
	# @return [Array] An array of floating point numbers.
    def values(metric_name, start_timestamp, end_timestamp=Time.now)
    	stats(metric_name, start_timestamp, end_timestamp).map{|s| s[:value]}
    end

    ##
    # Get only the timestamps of the stats for a given <code>metric_name</code> 
    # that's contained in the available set of datapoints within the range 
    # of <code>start_timestamp</code> to <code>end_timestamp</code>
	#
	# @param [String] metric_name
	# 	The key for the metric you are querying for.
	#
	# @param [Time] start_timestamp
	# 	The start of the time range of the query.
	#
	# @param [Time] end_timestamp
	# 	The end of the time range of the query. Defaults to the current time.
	#
	# @return [Array] An array of Time objects.
    def timestamps(metric_name, start_timestamp, end_timestamp=Time.now)
    	stats(metric_name, start_timestamp, end_timestamp).map{|s| s[:timestamp]}
    end
   

    protected

    ##
    # Parse the options provided in the constructor. Use the defaults for
    # any options not provided.
    def _parse_options(options)
		defaults = DEFAULTS.dup
		options = options.dup

		defaults.keys.each do |key|
			options[key] ||= defaults[key]
		end

		options
    end

    private

    	##
    	# Connect to the remote batsd server over TCP.
		def connect!
			Timeout::timeout(5) do
				self.remote = TCPSocket.new(host, port)
			end
			rescue Timeout::Error => e
				raise ConnectionTimeoutError
			rescue
				raise CannotConnectError
		end

		##
		# Disconnect from the remote batsd server.
		def disconnect
			self.remote.close
		end

		##
		# Reconnect to the batsd server.
		def reconnect!
			disconnect
			connect!
		end

		##
		# Send a command to the remote and attempt to parse the response as JSON
		#
		# @param [String] command
		# 	The command to send to the server.
		#
		# @return [Array, String] The response received from the server. Unless it is 
		# 	the ping command, the JSON response is parsed into an array.
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
                    send_command(command, attempt+1)
                else
                    raise CommandTimeoutError
                end
            rescue Exception => e
                if attempt < max_attempts 
                    send_command(command, attempt+1)
                else
                    self.remote = nil
                    raise CommandError
                end
        end
end

require 'batsd/version'
require 'batsd/errors'