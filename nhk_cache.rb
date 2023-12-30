require 'singleton'
class NhkCache
  include Singleton
  DEFAULT_TIMEOUT = 30 * 60
  MAX_ENTRIES = 300
  
  def initialize
    @cache = {}
  end
  
  ## Timeout in minutes
  def get_cache(key, timeout=DEFAULT_TIMEOUT, &block)
    val = @cache[key.to_s]
    if val && val['expires_at'] >= Time.now
      $LOGGER.info 'using cache' if defined?($LOGGER)
      @cache[key.to_s]['touched_at'] = Time.now
      val['value']
    else
      $LOGGER.info 'not cache' if defined?($LOGGER)
      new_val = block.call
      set(key, new_val, timeout)
      new_val
    end
  end
  
  def set(key, val, timeout=DEFAULT_TIMEOUT)
    if @cache[key.to_s].nil? && (@cache.keys.count == MAX_ENTRIES)
      prune_oldest
    end
    @cache[key.to_s] = {'value'=>val, 'expires_at'=>(Time.now + timeout), 'touched_at'=>Time.now}
  end
  
  def prune_oldest
    oldest = @cache.keys.min {|key| @cache[key]['touched_at']}
    @cache.delete(oldest)
  end
end
