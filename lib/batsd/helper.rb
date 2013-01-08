class Batsd
	class Helper
		def self.sum(values)
	    	values.map{|x| x[:value]}.inject(:+)
	    end

	    def self.mean(values)
	    	count = values.count
	    	total = self.sum(values)
	    	total / count
	    end

	    def self.min(values)
	    end

	    def self.max(values)
	    end

	    def self.stddev(values)
	    end

	end
end