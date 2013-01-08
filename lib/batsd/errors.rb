class Batsd
  # Base error for all batsd errors.
  class BaseError < RuntimeError
  end

  # Base error for connection related errors.
  class BaseConnectionError < BaseError
  end

  # Raised when connection to a batsd server cannot be made.
  class CannotConnectError < BaseConnectionError
  end

  # Raised when a new connection times out
  class ConnectionTimeoutError < BaseConnectionError
  end

  # Base error for command related errors.
  class BaseCommandError < BaseError
  end

  # Raised when a command could not be run
  class CommandError < BaseCommandError
  end

  # Raised when a command times out
  class CommandTimeoutError < BaseCommandError
  end

  # Raised when the values returned weren't the same as what was asked for
  class InvalidValuesError < BaseError
  end
end
