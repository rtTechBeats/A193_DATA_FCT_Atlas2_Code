Auto-generated...
version; boardrev; boardid; chipid; blockdevice

ft version
--------
- Command name: `ft version`
- Command to send: `ft version`
```
hw: {{HW_VERSION}}

active
version: {{FW_VERSION}}, bank: 1
```

nvm factory read MLB#
--------
```
nvm factory read MLB#
{{MLBSN}}
```

sys board_rev
--------
```
sys board_rev
board_rev={{REV}}
```

app version
--------
```
app version
{{APPVER}}-dev
```

sensor get tsoc
--------
```
ns ({{NTC2}})
```

sensor get tbst
--------
```
ns ({{NTC0}})
```

sensor get tcmc
--------
```
ns ({{NTC1}})
```

sensor get vsns_vbus
--------
```
ns ({{vsns_vbus}})
```

sensor get vsns_vbst
--------
```
ns ({{vsns_vbst}})
```

i2c scan i2c@c6000
--------
```
10: {{Device1}} -- -- -- -- -- -- -- {{Device2}} -- -- -- -- -- -- --
```

i2c scan i2c@ed000
--------
```
50: -- -- -- -- -- {{Device}} -- -- -- -- -- -- -- -- -- --
```

i2c scan i2c@c7000
--------
```
30: {{Device}} -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
```

i2c scan i2c@c8000
--------
```
60: -- -- -- -- -- -- -- -- -- -- -- {{Device}} -- -- -- --
```

i2c scan i2c@ee000
--------
```
00:             -- -- -- -- {{Device1}} -- -- -- -- -- -- -- 
10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
20: {{Device2}} -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
```

i2c read i2c@c6000 0x18 0x10 1
--------
```
i2c read i2c@c6000 0x18 0x10 1
00000000: {{Read_Data}}                                               |
```

flash read gd25le32e@0 0x00
--------
```
00000000: {{Read_Data}}                                               |
```

gpio get gpio3 11
--------
```
gpio get gpio3 11
{{GPIO}}
```

gpio get gpio2 3
--------
```
gpio get gpio2 3
{{GPIO}}
```

gpio get gpio3 9
--------
```
gpio get gpio3 9
{{GPIO}}
```

gpio get gpio0 8
--------
```
gpio get gpio0 8
{{GPIO}}
```

gpio get gpio1 1
--------
```
gpio get gpio1 1
{{GPIO}}
```

gpio get gpio1 4
--------
```
gpio get gpio1 4
{{GPIO}}
```

gpio get gpio3 10
--------
```
gpio get gpio3 10
{{GPIO}}
```

gpio get gpio0 0
--------
```
gpio get gpio0 0
{{GPIO}}
```

gpio get gpio1 3
--------
```
gpio get gpio1 3
{{GPIO}}
```

gpio get gpio1 16
--------
```
gpio get gpio1 16
{{GPIO}}
```

gpio get gpio1 27
--------
```
gpio get gpio1 27
{{GPIO127}}
```

gpio get gpio0 7
--------
```
gpio get gpio0 7
{{GPIO}}
```

gpio get gpio3 4
--------
```
gpio get gpio3 4
{{GPIO}}
```

gpio get gpio1 26
--------
```
gpio get gpio1 26
{{GPIO}}
```

gpio get gpio2 8
--------
```
gpio get gpio2 8
{{GPIO}}
```

i2c read i2c@c6000 0x18 0x28 6
--------
```
00000000: {{tmp1}} {{tmp2}}                                           |
```

device list
--------
```
- {{gd25}}
  DT node labels: gd25le
```

nvm factory read tNRF
--------
```
{{NRF}}(0x
```

nvm factory read tCMC
--------
```
{{CMC}}(0x
```

nvm factory read tBST
--------
```
{{BST}}(0x
```

nvm factory read tSoC
--------
```
{{SOC}}(0x
```

Future commands to be parsed
----------------------------
