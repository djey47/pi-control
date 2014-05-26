# virtual_machine.rb - represents a ESXi managed virtual machine.

class VirtualMachine

  attr_reader :id
  attr_reader :name
  attr_reader :guest_os

  def initialize(id, name, guest_os)
    @id = id
    @name = name
    @guest_os = guest_os
  end

  def to_json(*a)
    {
        :id => @id,
        :name => @name,
        :guest_os => @guest_os
    }.to_json(*a)
  end
end