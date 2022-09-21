
"""

FROM : https://gist.github.com/dpgeorge/4b3fcac61cea3c70328a



"""

import pyb
import time
rtc = pyb.RTC()

rtc.datetime((2000, 1, 1, 1, 0, 0, 0, 0))
#@micropython.viper
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
