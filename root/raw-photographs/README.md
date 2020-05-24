# root/raw-photographs  

```bash
## Filetree

2020
  /05
    /24
      / {...}
```

## Cameras
- Pentax K20D
- Nikon D7000
- Nikon D600
- Nikon D750
- Canon 80D
## File Formats
- PEF
- DNG
- CR2
- NEF
## ExifTool Commands
```bash
exiftool -recurse -verbose -preserve -extractEmbedded -ext EXT -ignoreMinorErrors -if '' -echo TEXT -groupNames -groupHeadings -common_args SRC_FILE
```

```bash
## Pentax K20D 
exiftool -@ ARGFILE -common_args
```

```bash
-if 
$
```
