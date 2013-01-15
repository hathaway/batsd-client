batsd-ruby
==========

A Ruby client for [batsd](https://github.com/noahhl/batsd), a ruby-based alternative to statsd for aggregating and storing statistics.

# Installation

A simple gem installation.

	gem install batsd

Or you can include it in your Gemfile:

	gem "batsd"

# Getting Started

You can connect to Batsd by instantiating the Batsd class:

	client = Batsd.new

This assumes Batsd was started with a default configuration, and it listening on `localhost`, port `8127`. If you need to connect to a remote server or a different port, pass in the appropriate options:

	client = Batsd.new(:host => "10.0.0.1", :port => 8127)

The options and defaults are:
	
	:host => "127.0.0.1"
	:port => 8127
	:timeout => 2000 #milliseconds
	:max_attempts => 2

Now you can grab the list of available keys:

	keys = client.available

To pull the stats for a key:

	start_timestamp = Time.now - (60*60) # 1 hour ago
	end_timestamp = Time.now
	stats = client.stats("metric_name", start_timestamp, end_timestamp)

Each stat is returned as a hash with a `:timestamp` and `:value`. To pull only the timestamps or values for a range:

	start_timestamp = Time.now - (60*60) # 1 hour ago
	end_timestamp = Time.now
	values = client.values("metric_name", start_timestamp, end_timestamp)
	timestamps = client.timestamps("metric_name", start_timestamp, end_timestamp)

# Contributing

[Fork the project](https://github.com/hathaway/batsd-client) and send pull requests.