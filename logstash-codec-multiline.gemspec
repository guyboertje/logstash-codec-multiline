Gem::Specification.new do |s|

  s.name            = 'logstash-codec-multiline'
  s.version         = '0.1.3'
  s.licenses        = ['Apache License (2.0)']
  s.summary         = "The multiline codec will collapse multiline messages and merge them into a single event."
  s.description     = "This gem is a logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/plugin install gemname. This gem is not a stand-alone program"
  s.authors         = ["Elasticsearch"]
  s.email           = 'info@elasticsearch.com'
  s.homepage        = "http://www.elasticsearch.org/guide/en/logstash/current/index.html"
  s.require_paths = ["lib"]

  # Files
  s.files = `git ls-files`.split($\)

  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "codec" }

  # Gem dependencies
  s.add_runtime_dependency 'logstash', '>= 1.4.0', '< 2.0.0'

  s.add_runtime_dependency 'logstash-patterns-core'
  s.add_runtime_dependency 'jls-grok', [ '0.11.0' ]

  s.add_development_dependency 'logstash-devutils'
end

