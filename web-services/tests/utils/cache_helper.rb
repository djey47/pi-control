# cache_helper.rb - makes cache testing easier

require_relative '../../rupees/common/cache.rb'

module CacheHelper

	def self.populate(cache_path)

	    Cache.instance.fetch_disks_else do
	      []
	    end
	    for i in 1..10 do
		    Cache.instance.smart.cache("#{Cache::CACHE_KEY_SMART_PREFIX}#{i}") do
		      []
		    end
		end

		raise Exception("Caches were not populated properly!") if Dir.glob(cache_path).empty?
	end
end