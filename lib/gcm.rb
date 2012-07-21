$LOAD_PATH.unshift(File.dirname(__FILE__)) unless $LOAD_PATH.include?(File.dirname(__FILE__))

require 'typhoeus'
require 'gcm/sender'
require 'gcm/handler'

module GCM
end
