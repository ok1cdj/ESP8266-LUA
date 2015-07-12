-- Measure temperature, humidity and post data to thingspeak.com
-- 2014 OK1CDJ
-- DHT11 code is from esp8266.com
---Sensor DHT11 is conntected to GPIO0
pin = 3
-- GPIO0 = 3 GPIO2 = 4

Humidity = 0
HumidityDec=0
Temperature = 0
TemperatureDec=0
Checksum = 0
ChecksumTest=0


function getTemp()
Humidity = 0
HumidityDec=0
Temperature = 0
TemperatureDec=0
Checksum = 0
ChecksumTest=0

--Data stream acquisition timing is critical. There's
--barely enough speed to work with to make this happen.
--Pre-allocate vars used in loop.

bitStream = {}
for j = 1, 40, 1 do
     bitStream[j]=0
end
bitlength=0

gpio.mode(pin, gpio.OUTPUT)
gpio.write(pin, gpio.LOW)
tmr.delay(20000)
--Use Markus Gritsch trick to speed up read/write on GPIO
gpio_read=gpio.read
gpio_write=gpio.write

gpio.mode(pin, gpio.INPUT)

--bus will always let up eventually, don't bother with timeout
while (gpio_read(pin)==0 ) do end

c=0
while (gpio_read(pin)==1 and c<100) do c=c+1 end

--bus will always let up eventually, don't bother with timeout
while (gpio_read(pin)==0 ) do end

c=0
while (gpio_read(pin)==1 and c<100) do c=c+1 end

--acquisition loop
for j = 1, 40, 1 do
     while (gpio_read(pin)==1 and bitlength<10 ) do
          bitlength=bitlength+1
     end
     bitStream[j]=bitlength
     bitlength=0
     --bus will always let up eventually, don't bother with timeout
     while (gpio_read(pin)==0) do end
end

--DHT data acquired, process.

for i = 1, 8, 1 do
     if (bitStream[i+0] > 2) then
          Humidity = Humidity+2^(8-i)
     end
end
for i = 1, 8, 1 do
     if (bitStream[i+8] > 2) then
          HumidityDec = HumidityDec+2^(8-i)
     end
end
for i = 1, 8, 1 do
     if (bitStream[i+16] > 2) then
          Temperature = Temperature+2^(8-i)
     end
end
for i = 1, 8, 1 do
     if (bitStream[i+24] > 2) then
          TemperatureDec = TemperatureDec+2^(8-i)
     end
end
for i = 1, 8, 1 do
     if (bitStream[i+32] > 2) then
          Checksum = Checksum+2^(8-i)
     end
end
ChecksumTest=(Humidity+HumidityDec+Temperature+TemperatureDec) % 0xFF

print ("Temperature: "..Temperature.."."..TemperatureDec)
print ("Humidity: "..Humidity.."."..HumidityDec)
print ("ChecksumReceived: "..Checksum)
print ("ChecksumTest: "..ChecksumTest)
end

--- Get temp and send data to thingspeak.com
function sendData()
getTemp()
-- conection to thingspeak.com
print("Sending data to thingspeak.com")
conn=net.createConnection(net.TCP, 0) 
conn:on("receive", function(conn, payload) print(payload) end)
-- api.thingspeak.com 184.106.153.149
conn:connect(80,'184.106.153.149') 
conn:send("GET /update?key=XXXXXXXXXX&field1="..Temperature.."."..TemperatureDec.."&field2="..Humidity.."."..HumidityDec.." HTTP/1.1\r\n") 
conn:send("Host: api.thingspeak.com\r\n") 
conn:send("Accept: */*\r\n") 
conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n")
conn:send("\r\n")
conn:on("sent",function(conn)
                      print("Closing connection")
                      conn:close()
                  end)
conn:on("disconnection", function(conn)
                      print("Got disconnection...")
  end)
end
-- send data every X ms to thing speak
tmr.alarm(2, 60000, 1, function() sendData() end )
