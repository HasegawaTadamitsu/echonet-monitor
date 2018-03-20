#!/usr/bin/ruby

# coding: utf-8
require 'optparse'
require "socket"
require "ipaddr"
require 'bindata'
require "pry" #you need?


class PropertyData < BinData::Record
  uint8be  :epc  #Echonet lite  Property count
  uint8be  :pdc  #Property Data count
  array  :edt, :type => :uint8be,  :initial_length => :pdc
end

class BEOJ < BinData::Record
  uint8be  :class_group_code
  uint8be  :class_code
  uint8be  :instance_code
  def set_values a,b,c
    self[:class_group_code] = a
    self[:class_code] = b
    self[:instance_code] = c
  end
end

class EData < BinData::Record
  beoj  :seoj  #source Echonet lite ObJect 
  beoj  :deoj  #dest   Echonet lite ObJect 
  uint8be  :esv  #Echonet lite SerVice
  uint8be  :opc  #Object Property count
  array  :property, :type => :propertyData,  :initial_length => :opc

  ESV_Set_I = 0x60
  ESV_Set_C = 0x61
  ESV_INF_REQ = 0x63
  ESV_Set_Get = 0x6e
  
  def set_values a_seoj,a_deoj,a_esv
    self[:seoj] = a_seoj
    self[:deoj] = a_deoj
    self[:esv]  = a_esv
  end
  def add_property a_property
    before_opc = self[:opc]
    self[:property][before_opc] = a_property
    self[:opc] = before_opc + 1
  end
end

class EchonetData < BinData::Record
  uint8be  :ehd1 # Echonet lite denbun HeaDer1
  uint8be  :ehd2 # Echonet lite denbun HeaDer2
  uint16be :tid  # Trunsaction ID
  eData    :edata #Echonet lite data
  def set_val arg_tid, arg_edata
    self[:ehd1] = 0x10
    self[:ehd2] = 0x81
    self[:tid] = arg_tid
    self[:edata] = arg_edata
  end
end



option={}
option[:aircon_no]=0x03 # default EOJ instanceCode. set target instance code.
OptionParser.new do |opt|
  opt.on('-1',     'switch on' ){|v| option[:switch] = true}
  opt.on('-0',     'switch off'){|v| option[:switch] = false}
  opt.parse!(ARGV)
end
if option.count == 1
  puts "error. need any options"
  exit 1
end

seoj = BEOJ.new
seoj.set_values 0x05,0xff,0x01
deoj = BEOJ.new
deoj.set_values 0x01,0x35,0x01

edata = EData.new
edata.set_values seoj,deoj,EData::ESV_Set_I ## HMM! bad  ESV_Set_Get
sw=option[:switch]
if sw != nil 
  property = PropertyData.new
  property[:epc] = 0x80
  property[:pdc] = 0x01
  property[:edt][0] = (sw)? 0x30:0x31
  edata.add_property property
end

echonetdata = EchonetData.new
echonetdata.set_val 0x1111,edata


ip="192.168.33.126"    #change here!!
u = UDPSocket.new()
u.connect(ip,3610)
# p echonetdata.to_hex
u.send(echonetdata.to_binary_s,0)
u.close
