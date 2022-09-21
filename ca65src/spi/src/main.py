
"""

FROM : https://gist.github.com/dpgeorge/4b3fcac61cea3c70328a


This implements a simple SPI slave.  It will run on PYBv1.0 and PYBv1.1.
The SPI slave logic is done in software and can cope with an SPI clock
frequency up to 125kHz.
There is no CS line, only SCLK, MOSI, MISO.
Clock format must be mode=0, which is polarity=CPOL=0, phase=CPHA=0 (clock
is low when idle and high when active, and data is sampled on first, rising
edge of clock).
Incoming commands must be exactly 2 bytes long.  The bytes should both
be integer characters (ie '0' through '9').  The first number will be
doubled, and returned by the slave as the second byte.  The second number
indicates which LED to toggle on the pyboard (between 1 and 4 inclusive).
The return data is 2 bytes long, the first byte is the character 'X' and
the second byte is the integer character corresponding to twice the
number sent by the master in the first byte.
For example, sending b'34' will return b'X6' and will toggle LED number 4
(the blue one).





"""

import pyb
import time
rtc = pyb.RTC()
rtc.datetime((2000, 1, 1, 6, 0, 4, 0, 0))
@micropython.viper
def bit_bang_spi(sclk, mosi, miso) -> int:
    #out_val = int(ord('X'))
    
    time_long = int(time.time())
    
    time_hi = (time_long >> 8) & 0xFF
    time_lo = (time_long & 0xFF)
    
    out_val = time_hi
    
    in_val = 0
    for i in range(8):
        # prepare output value
        miso(out_val & 0x80)
        out_val <<= 1
        # wait for sclk to go high
        while sclk():
            pass
        # read input value
        in_val = (in_val << 1) | int(mosi())
        # wait for sclk to go low
        while not sclk():
            pass
        

    
    out_val = time_lo
    #out_val = (in_val)     
    in_val = 0
    for i in range(8):
        # prepare output value
        miso(out_val & 0x80)
        out_val <<= 1
        # wait for sclk to go high
        while sclk():
            pass
        # read input value
        in_val = (in_val << 1) | int(mosi())
        # wait for sclk to go low
        while not sclk():
            pass
        
    
   
    return in_val

def main():
    #print('slave')
    leds = [pyb.LED(i + 1) for i in range(4)]
    for led in leds:
        led.on()
        pyb.delay(150)
        led.off()
    sclk = pyb.Pin('X6', pyb.Pin.IN)
    miso = pyb.Pin('X7', pyb.Pin.OUT_PP)
    mosi = pyb.Pin('X8', pyb.Pin.IN)
    
    while True:
        #print('start', sclk(), miso(), mosi())
        in_val = bit_bang_spi(sclk, mosi, miso)
        try:
            leds[(in_val -1) % 4].toggle()
        except IndexError:
            pass
        #print(chr(in_val), in_val, bin(in_val))

if __name__ == '__main__':
    main()
