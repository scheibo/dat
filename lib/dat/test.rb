$:.unshift(File.expand_path('../../dat', __FILE__)) unless $:.include?(File.expand_path('../../dat', __FILE__))
require 'interface'
#p File.expand_path('../../../lib', __FILE__)

i = Dat::Interface.new

i.new_game('kirk')

sleep 1
p i.time('kirk')



