
require 'wires'


module UserModule
  $the_altwires_module = Wires::Util.build_alt "::#{self}::AltWires"
  Wires = ::Wires
end


describe "Wires::Util.build_alt", iso:true do
  
  describe "creates a module which" do
    subject       { ::UserModule::AltWires }
    let(:event)   { ::UserModule::AltWires::Event.new }
    let(:channel) { ::UserModule::AltWires::Channel['name'] }
    
    let(:wires_event)   { Wires::Event.new }
    let(:wires_channel) { Wires::Channel['name'] }
    
    # Get a list of constants in Wires, recursive 10 levels deep
    let(:wires_constants) do
      array = [Wires]
      
      10.times do
        ary = []
        array.each do |obj|
          ary += obj.constants.map { |sym| obj.const_get(sym) }
        end
        (array += ary).uniq!
      end
      
      array - [Wires]
    end
    
    it "is the return value of the build_alt method" do
      expect($the_altwires_module).to eq subject
    end
    
    it "contains an alternate version of each Wires singleton" do
      wires_constants.reject{|obj| obj.respond_to? :new}.each do |obj|
        alt_obj = eval obj.to_s.gsub(/^Wires/, subject.to_s)
        expect(alt_obj).to_not equal obj
      end
    end
    
    it "contains an alternate version of Channel with correct references" do
      alt_chan = subject.const_get :Channel
      expect(alt_chan).to_not eq Wires::Channel
      expect(alt_chan.hub)   .to eq subject.const_get :Hub
      expect(alt_chan.router).to eq subject.const_get(:Router).const_get :Default
    end
    
    # it "doesn't crosstalk when Wires::events are fired" do
    #   it_happened = []
      
    #   wires_channel.register :event do |e|
    #     expect(e).to     be_a UserModule::Wires::Event
    #     expect(e).not_to be_a UserModule::AltWires::Event
    #     it_happened << UserModule::Wires
    #   end
      
    #   channel.register :event do |e|
    #     expect(e).not_to be_a UserModule::Wires::Event
    #     expect(e).to     be_a UserModule::AltWires::Event
    #     it_happened << UserModule::AltWires
    #   end
      
    #   wires_channel.fire :event
    #   channel.fire       :event
      
    #   UserModule::Wires::Hub.join_children
    #   UserModule::AltWires::Hub.join_children
      
    #   expect(it_happened.count).to eq 2
    #   expect(it_happened).to include UserModule::Wires
    #   expect(it_happened).to include UserModule::AltWires
    # end
    
    # it "doesn't crosstalk when Wires::events are fired" do
    #   it_happened = []
      
    #   wires_channel.register :event do |e|
    #     expect(e).to     be_a UserModule::Wires::Event
    #     expect(e).not_to be_a UserModule::AltWires::Event
    #     it_happened << UserModule::Wires
    #   end
      
    #   channel.register :event do |e|
    #     expect(e).not_to be_a UserModule::Wires::Event
    #     expect(e).to     be_a UserModule::AltWires::Event
    #     it_happened << UserModule::AltWires
    #   end
      
    #   wires_channel.fire :event
    #   channel.fire       :event
      
    #   UserModule::Wires::Hub.join_children
    #   UserModule::AltWires::Hub.join_children
      
    #   expect(it_happened.count).to eq 2
    #   expect(it_happened).to include UserModule::Wires
    #   expect(it_happened).to include UserModule::AltWires
    # end
  end
  
  # it "can build an alternate version of the Wires module" do
  # pending
  #   UserModule::Wires.constants.reject{|c| c==:Test}.each do |c|
  #     expect(UserModule::Wires.const_get(c)).to_not eq UserModule::AltWires.const_get(c)
  #   end
  # end
  
  # it "doesn't crosstalk when events are fired" do
  # pending
  #   it_happened = []
    
  #   UserModule::Wires.on :event, 'channel' do |e|
  #     expect(e).to     be_a UserModule::Wires::Event
  #     expect(e).not_to be_a UserModule::AltWires::Event
  #     it_happened << UserModule::Wires
  #   end
    
  #   UserModule::AltWires.on :event, 'channel' do |e|
  #     expect(e).not_to be_a UserModule::Wires::Event
  #     expect(e).to     be_a UserModule::AltWires::Event
  #     it_happened << UserModule::AltWires
  #   end
    
  #   UserModule::Wires.fire    :event, 'channel'
  #   UserModule::AltWires.fire :event, 'channel'
    
  #   UserModule::Wires::Hub.join_children
  #   UserModule::AltWires::Hub.join_children
    
  #   expect(it_happened.count).to eq 2
  #   expect(it_happened).to include UserModule::Wires
  #   expect(it_happened).to include UserModule::AltWires
  # end
  
end
