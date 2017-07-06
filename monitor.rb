# coding: utf-8
require "socket"
require "ipaddr"
require 'bindata'
require "pry"

class HomeAirConditionerClass
  def self.check(eoj)
    eoj.class_group_code == 0x01 and eoj.class_code == 0x30
  end
  def self.print_debug(property)
    ret = []
    property.each do |val|
      epc =val.epc
      case epc
      when 0xb0
        sw_val = val.edt[0]
        str="Operation mode setting 0x#{sw_val.to_hex}:"
        if sw_val == 0x41
          ret << str + "Automatic"
        elsif sw_val == 0x42
          ret << str + "Cooling"
        elsif sw_val == 0x43
          ret << str + "Heating"
        elsif sw_val == 0x44
          ret << str + "Dehumidification"
        elsif sw_val == 0x45
          ret << str +"Air circulator"
        elsif sw_val == 0x40
          ret << str +"Other"
        else
          ret << str + "unkown value"
        end
      when 0xb3
        val = val.edt[0]
        ret << "Set temperature value 0x#{val.to_hex}: #{val}"
      when 0xba
        val = val.edt[0]
        ret << "Measured value of room relative humidity 0x#{val.to_hex}: #{val}"
      when 0xbb
        val = val.edt[0]
        ret << "Measured value of room temperature 0x#{val.to_hex}: #{val}"

      when 0xbe
        val = val.edt[0]
        ret << "Measured outdoor air temperature 0x#{val.to_hex}: #{val}"
      when 0xa0
        val = val.edt[0]
        str = "Air flow rate setting 0x#{val.to_hex}:"
        if val == 0x41
          str +=  "Automatic air flow rate control function use"
        else
          str += "Air flow rate val #{val.chr}"
        end
        ret << str
      when 0xa1
        val = val.edt[0]
        str = "Automatic control of air flow direction setting 0x#{val.to_hex}:"
        if val == 0x41
          str +=  "Automatic"
        elsif val == 0x42
          str +=" non-automatic"
        elsif val == 0x43
          str +=" automatic (vertical)"
        elsif val == 0x44
          str +=" automatic (horizontal)"
        else
          str += "unknown value."
        end
        ret << str
      when 0xa4
        val = val.edt[0]
        str = "Air flow direction (vertical) setting 0x#{val.to_hex}:"
        if val == 0x41
          str +=  "Uppermost"
        elsif val == 0x42
          str +=" lowermost"
        elsif val == 0x43
          str +=" central"
        elsif val == 0x44
          str +=" midpoint between uppermost and central"
        elsif val == 0x45
          str +=" midpoint between lowermost and central"
        else
          str += "unknown value."
        end
        ret << str
      else
        tmp = Array.new
        tmp.push val
        ret << DeviceObjectSuperClass.print_debug( tmp )
      end ## end of case
    end  ## end of property each
    return ret
  end ## end of print_debug
end


class NodeProfileClass
  def self.check(eoj)
    eoj.class_group_code == 0x0e and eoj.class_code == 0xf0
  end
  def self.print_debug(property)
    ret = []
    property.each do |val|
      epc =val.epc
      case epc
      when 0xd5..0xd6
        if val.edt.size  == 0
          count =0
        else
          count = val.edt[0] # 1st byte: Number of notification instances
        end
        if epc == 0xd5
          ret << "epc 0x#{epc.to_hex}:Instance list notification"
        elsif epc == 0xd6
          ret << "epc 0x#{epc.to_hex}:Self-node Instance listS"
        end
        ret << "count #{count}"
        edt_counter = 1
        count.times do 
          eoj= BEOJ.new
          eoj.class_group_code = val.edt[edt_counter]
          eoj.class_code       = val.edt[edt_counter+1]
          eoj.instance_code    = val.edt[edt_counter+2]
          edt_counter += 3
          ret.concat eoj.print_debug
        end # end of times
      else
        tmp = Array.new
        tmp.push val
        ret << DeviceObjectSuperClass.print_debug( tmp )
      end # end of case
    end # end of propety_each
    return ret
  end # end of def 
end

class DeviceObjectSuperClass
  def self.print_debug(property)
    ret = []
    property.each do |val|
      epc =val.epc
      case epc
      when 0x80
        str = "Operation status 0x#{val.edt[0].to_hex}:"
        if    val.edt[0] == 0x30
          ret << str +"ON"
        elsif val.edt[0] == 0x31
          ret << str + "OFF"
        else
          ret << str + " unknown value"
        end
      when 0x81
        ret  << "Installation location <<unprogramming>>"
      when 0x82
        str = "Standard version information :"
        str += "#{val.edt[0].chr} "
        str += "#{val.edt[1].chr} "
        str += "#{val.edt[2].chr} "
        str += "#{val.edt[3].chr}"
        ret << str
      when 0x83
        ret  << "Identification number <<unprogramming>>"
      when 0x84
        ret  << "Measured instantaneous power consumption <<unprogramming>>"
      when 0x85
        val1 = val.edt[0]
        val2 = val.edt[1]
        val3 = val.edt[2]
        val4 = val.edt[3]
        total = (val4  + val3 * 2^8 + val2 * 2^16 + val1 * 2^32) * 0.001
        ret << "Measured cumulative power consumption. 0x#{val1.to_hex} 0x#{val2.to_hex} " +
          "0x#{val3.to_hex} 0x#{val4.to_hex} #{total} kWh"
      when 0x86
        ret  << "Manufacturer’s fault cod<<unprogramming>>"
      when 0x87
        ret  << "Current limit setting <<unprogramming>>"
      when 0x88
        str ="Fault statu:0x#{val.edt[0].to_hex}:"
        if  val.edt[0] == 0x41
          ret << str + " Fult  occurred"
        elsif val.edt[0] == 0x42
          ret << str + "No fault"
        else
          ret << str + "unknown value"
        end
      when 0x89
        ret  << "Fault description <<unprogramming>>"
      when 0x8a
        ret  << "Manufacturer code <<unprogramming>>"
      when 0x8b
        ret  << "Business facility code<<unprogramming>>"
      when 0x8c
        str ="Product code:"
        12.times do |i|
          str += val.edt[i].chr
        end
        ret << str
      when 0x8d
        str ="Product number:"
        12.times do |i|
          str += val.edt[i].chr
        end
        ret << str
      when 0x8e
        ret  << "Production date <unprogramming>>"
      when 0x8f
        str ="Power-saving operation setting :0x#{val.edt[0].to_hex}:"
        if  val.edt[0] == 0x41
          ret << str + " Operating in power-savineg mode "
        elsif val.edt[0] == 0x42
          ret << str + " Operating in normal mode "
        else
          ret << str + "unknown value"
        end
      when 0x90..0x92
        ret << "unkown epc code 0x#{epc.to_hex}"
      when 0x93
        ret << "Remote control setting << undefind>>"
      when 0x94..0x9f
        ret << "unkown epc code 0x#{epc.to_hex}"
      else
        ret << "un programing epc code 0x#{epc.to_hex}"
      end # end of case
    end
    return ret
  end # end of def 
end

class EPCHelper
  def initialize (property,eoj)
    @property = property
    @eoj = eoj
  end

  def print_debug
    if NodeProfileClass.check(@eoj)
      return NodeProfileClass.print_debug(@property)
    elsif HomeAirConditionerClass.check(@eoj)
      return HomeAirConditionerClass.print_debug(@property)
    end
    return nil
  end
end

class PropertyData < BinData::Record
  uint8be  :epc  #Echonet lite  Property count
  uint8be  :pdc  #Property Data count
  array  :edt, :type => :uint8be,  :initial_length => :pdc
  def print_debug
    ret =[]
    ret << "epc:0x#{epc.to_hex}"
    ret << "pdc:0x#{pdc.to_hex}"
    edt.each_with_index do |e,i|
      ret << "edt #{i}:0x#{e.to_hex}"
    end
    return ret
  end
end

class BEOJ < BinData::Record
  uint8be  :class_group_code
  uint8be  :class_code
  uint8be  :instance_code

  def class_group_code_to_str
    case class_group_code
    when 0x00
      return "Sensor-related device class group"
    when 0x01
      return "Air conditioner-related device class group"
    when 0x02
      return "Housing/facility-related device class group"
    when 0x03
      return "Cooking/housework-related device class group"
    when 0x04
      return "Health-related device class group"
    when 0x05
      return "Management/control-related device class group"
    when 0x06
      return "AV-related device class group"
    when 0x07..0x0d
      return "Reserved for future use"
    when 0x0e
      return "Profile class group"
    when 0x0f
      return "User definition class group"
    when 0x10..0xff
      return "Reserved for future use"
    else
      return "unknown or bug"
    end
  end

  def class_code_to_str
    case class_group_code
    when 0x05
      case class_code
      when 0x00..0xfc
        return "Reserved for future use"
      when 0xfd
        return "Switch"
      when 0xfe
        return "Portable terminal"
      when 0xff
        return "Controller"
      else
        return "unknown or bug"
      end        
    when 0x0e
      case class_code
      when 0x00..0xef
        return "Reserved for future use"
      when 0xf0
        return "Node profile"
      when 0xf1..0xff
        return "Reserved for future use"
        else
        return "unknown or bug"
      end        
    end
  end
  def to_str
    return "0x#{class_group_code.to_hex}:" +
           "0x#{class_code.to_hex}:" +
           "0x#{instance_code.to_hex}"
  end
  
  def print_debug
    ret =[]
    ret << "classGroupCode:"
    ret << "  0x#{class_group_code.to_hex}:#{class_group_code_to_str}"
    ret << "classCode:"
    ret << "  0x#{class_code.to_hex}:#{class_code_to_str}"
    ret << "instanceCode:" 
    ret << "  0x#{instance_code.to_hex}"
    return ret
  end
end

class EData < BinData::Record
  beoj  :seoj  #source Echonet lite ObJect 
  beoj  :deoj  #dest   Echonet lite ObJect 
  uint8be  :esv  #Echonet lite SerVice
  uint8be  :opc  #Object Property count
  array  :property, :type => :propertyData,  :initial_length => :opc

  def esv_to_str
    case esv
    when 0x60
      return "Property value write request (no response required):SetI"
    when 0x61
      return "Property value write request (response Crequired):SetC"
    when 0x62
      return "Property value read request:Get"
    when 0x63
      return "Property value notification request:INF_REQ"
    when 0x64..0x6d
      return "Reserved for future use"
    when 0x6e
      return "Property value write & read request:SetGet"
    when 0x6f
      return "Reserved for future use"
    when 0x71
      return "Property value Property value write response:Set_Res"
    when 0x72
      return "roperty value read response:Get_Res"
    when 0x73
      return "Property value notification:INF"
    when 0x74
      return "Property value notification (response required):INFC"
    when 0x75..0x70
      return "Reserved for future use"
    when 0x7A
      return "Property value notification response:INFC_Res"
    when 0x7b..0x7d
      return "Reserved for future use"
    when 0x7e
      return "Property value write & read response:SetGet_Res"
    when 0x7f
      return "Reserved for future use"
    when 0x50
      return "Property value write request response not possible:SetI_SNA"
    when 0x51
      return "Property value write request response not possible:SetC_SNA"
    when 0x52
      return "Property value read request response not possible:Get_SNA"
    when 0x53
      return "Property value notification response notpossible: INF_SNA"
    when 0x54..0x5d
      return "Reserved for future use"
    when 0x5e
      return "Property value write & read request:SetGet_SNA"
    when 0x5f
      return "Reserved for future use"
    else
      return "unknown or bug"
    end
  end
  def print_debug
    ret =[]
    ret << "seoj:"
    seoj.print_debug.each do | val |
      ret << "  #{val}"
    end
    ret << "deoj:"
    deoj.print_debug.each do | val |
      ret <<"  #{val}"
    end
    ret << "esv:0x#{esv.to_hex}:#{esv_to_str}"
    ret << "opc:0x#{opc.to_hex}"
    property.each_with_index do | pr,i |
      ret << "property #{i}"
      pr.print_debug.each do | val |
        ret << "  #{val}"
      end
    end
    return ret
  end
end

class EchoData < BinData::Record
  uint8be  :ehd1 # Echonet lite denbun HeaDer1
  uint8be  :ehd2 # Echonet lite denbun HeaDer2
  uint16be :tid  # Trunsaction ID
  eData    :edata #Echonet lite data

  def print_debug
    ret = []
    ret << "ehd1:0x#{ehd1.to_hex}"
    ret << "ehd2:0x#{ehd2.to_hex}"
    ret << "tid:0x#{tid.to_hex}"
    ret << "edata:"
    edata.print_debug.each do | val |
      ret << " #{val}"
    end
    epc_helper = EPCHelper.new edata.property,edata.seoj
    tmp = epc_helper.print_debug
    return ret.concat tmp  if tmp != nil     

    epc_helper = EPCHelper.new edata.property,edata.deoj
    tmp = epc_helper.print_debug
    return ret.concat tmp  if tmp != nil     

    ret << "unknown epc"
    return ret
  end

  def print_debug_str
    ret = print_debug
    return ret.join "\n"
 end
end


class TestEchoData
  def initialize
    data = [ "10","81","00","04",
             "01","30",             "03",
             "05","FF","01","72","02","9F","11",
             "17","0D","05","01","0B","04","01","01",
             "00","01","01","09","08","01","02","0A",
             "03","9E","0A","09","80","A0","B0","81",
             "A1","93","B3","A4","8F"
           ]
    msg =[]
    msg << data.join
    bin = msg.pack("H*")
    data =EchoData.read bin
    puts data.print_debug_str
    # ["1081000905ff010ef0016201d600"]
    data = ["10","81","00","09",
            "05","FF","01",
            "0e","F0","01",
            "62", #ESV
            "01", #OPC
            "D6", #EPC
            "00"  #PDC = 0
           ]
    msg =[]
    msg << data.join
    bin = msg.pack("H*")
    data =EchoData.read bin
    puts data.print_debug_str
    exit
  end
end

#TestEchoData.new


udps = UDPSocket.open()
udps.bind("0.0.0.0",3610)
mreq = IPAddr.new("224.0.23.0").hton + IPAddr.new("0.0.0.0").hton
udps.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, mreq)

loop do
  msg =  udps.recvmsg
  raw_data = msg[0]
  ip_addr = msg[1]
  data = EchoData.read( raw_data )
  p ip_addr
  puts data.print_debug_str
end

    
