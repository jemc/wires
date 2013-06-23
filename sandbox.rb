require 'wires'


# TODO: allow listening on objects for channels that get resolved with to_s

# TODO: allow listening on Channel(/regexp/) (but not firing to it!)


class ChildEvent < Event
end

# Test Event to Symbol/String comparison functions
%w(== < > <= >=).each do |op|
    [[:event, Event],
     [:child, ChildEvent],
     [:child, Event],
     [:event, ChildEvent]].each do |one, two|
        str = ":#{one} #{op} #{two}\t\t#=>\t"
        result = eval(str)
        puts str+result.to_s
    end
end

Hub.new.kill! # Stop process manually

# case B
# when Class and (B<A)
#     puts 'yay'
# else
#     puts 'meh'
# end

# class FWHub < Hub
# end

# class FWChannel < Channel
#     @@channel_list = Set.new
#     @@hub = FWHub.new
# end

# puts Hub.new
# puts FWHub.new
# puts FWHub.new
# puts Channel.new('a')
# puts FWChannel.new('a')


