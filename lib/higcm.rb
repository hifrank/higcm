$LOAD_PATH.unshift(File.dirname(__FILE__)) unless $LOAD_PATH.include?(File.dirname(__FILE__))

require 'typhoeus'
require 'higcm/sender'
require 'higcm/handler'

module HiGCM
end
