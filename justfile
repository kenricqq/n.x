setup:
    lefthook install

update_bun:
    bun update -g

linux:
    # → DisplayPort
    ddcutil -d 1 setvcp xF4 x00D0 --i2c-source-addr=x50 --noverify

    # → HDMI 1
    ddcutil -d 1 setvcp xF4 x0090 --i2c-source-addr=x50 --noverify

    # → HDMI 2
    ddcutil -d 1 setvcp xF4 x0091 --i2c-source-addr=x50 --noverify
