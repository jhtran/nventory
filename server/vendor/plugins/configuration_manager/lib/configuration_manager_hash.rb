class ConfigurationManagerHash < Hash
  def method_missing(method, *args)
    if self.keys.include?(method.to_s)
      result = self[method.to_s]
      if result.class == Hash
        result = self[method.to_s] = ConfigurationManagerHash.new_from_hash(result)
      end
      return result
    else
      super
    end
  end
  
  def self.new_from_hash(hash)
    hash.is_a?(Hash) ? ConfigurationManagerHash.new.merge(hash) : {}
  end
end