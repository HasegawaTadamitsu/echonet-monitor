#!/usr/bin/ruby
# coding: utf-8

# coding: utf-8
require 'bindata'
require 'serialport'
require 'timeout'

require "./smart_meter_password.rb"
# this file like ...this
#class SmartMeterPassword
#  ID="000000AAAAAA000000000000000AAAAA"
#  PASSWORD="AAAAAAAAAAAA"
#end
#

#require "socket"
#require "ipaddr"
# require "pry" you need?


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


class PanDesc
  def initialize args_datas
    begin
      datas = args_datas

      data = datas.shift
      @sender =  chaeck_and_raise( data,/^EVENT 20 (?<sender>.+)/)

      data = datas.shift
      #drop this
      chaeck_and_raise( data,/^EPANDESC/) 

      data = datas.shift
      @channel =  chaeck_and_raise data,/^  Channel:(?<channel>.+)/

      data = datas.shift
      @channel_page  =  chaeck_and_raise data,/^  Channel Page:(?<channel_page>.+)/

      data = datas.shift
      @pan_id =  chaeck_and_raise data,/^  Pan ID:(?<pan_id>.+)/
      
      data = datas.shift
      @addr =  chaeck_and_raise data,/^  Addr:(?<addr>.+)/

      data = datas.shift
      @lqi =  chaeck_and_raise data,/^  LQI:(?<lqi>.+)/

      data = datas.shift
      @pair_id =  chaeck_and_raise data,/^  PairID:(?<pair_id>.+)/
      
    rescue => e
      p e 
      raise "bad paddesc format #{args_datas}"
    end
    p @sender
    p @channel
    p @channel_page
    p @pan_id
    p @addr
    p @lqi
    p @pair_id
  end

  private
  def chaeck_and_raise data, matcher
    res = data.match( matcher )
    raise "bad format #{data}" if res == nil
    return res[1]
  end
  
end

class SerialConnect
  
  def initialize tty
    @sp = SerialPort.new(tty, 115200, 8, 1, 0)
  end

  def reset
    send "SKVER"
    p recv_ok
    send "SKAPPVER"
    p recv_ok
    send "SKRESET"
    p recv_ok
  end

  def show_status
    send "SKTABLE 1"
    p recv_ok
    send "SKTABLE 2"
    p recv_ok
    send "SKTABLE 3"
    p recv_ok
    send "SKTABLE E"
    p recv_ok
    send "SKTABLE F"
    p recv_ok
  end

  def send str
    @send_data = str
    @sp.write str + "\r\n"
  end

  def recv_active_event
    recev_data= Array.new
    loop do 
      begin
        Timeout.timeout(30) do
          data = @sp.gets
          recev_data.push data
          if  data.start_with? "EVENT 22"
            return recev_data
          end
        end
      rescue Timeout::Error => e
        return recev_data
      end
    end ## end of loop
  end

  def recv_ok
    recev_data= Array.new
    begin
      Timeout.timeout(5) do 
        loop do
          data = @sp.gets
          recev_data.push data
          if data.start_with? "FAIL ER"
            raise "module return fail error. #{@send_data},#{recev_data}"
          end
          if data.start_with? "OK"
            return recev_data
          end
        end
      end
    rescue Timeout::Error => e
      raise e,"module timeout. #{@send_data},#{recev_data},#{e.message}"
    end
    return false         
  end
end

sc = SerialConnect.new "/dev/ttyUSB0"
sc.reset
sc.show_status

sc.send "SKSREG SFE 1"
p sc.recv_ok

sc.send "SKSETPWD C " + SmartMeterPassword::PASSWORD
p sc.recv_ok

sc.send "SKSETRBID " + SmartMeterPassword::ID
p sc.recv_ok

sc.send "SKSCAN 2 FFFFFFFF 6"
p sc.recv_ok
pan_rows = sc.recv_active_event
a = PanDesc.new pan_rows
