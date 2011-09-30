$:.unshift(File.expand_path('../../lib', __FILE__)) unless $:.include?(File.expand_path('../../lib', __FILE__))
module Dat; end

require 'logic'
require 'dat/version'
require 'dat/dict'
require 'dat/logic'
require 'dat/solver'
require 'dat/game'
require 'dat/games'
require 'dat/interface'
require 'dat/bots'
require 'dat/logger'
require 'dat/loggame'
