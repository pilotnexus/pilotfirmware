@rem build the veri project

"C:\Program Files\altera\12.1sp1\quartus\bin\quartus_map.exe" cpld
"C:\Program Files\altera\12.1sp1\quartus\bin\quartus_fit" cpld
"C:\Program Files\altera\12.1sp1\quartus\bin\quartus_asm" cpld

@echo Done.
