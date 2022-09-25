# PictureFS Proposal Version 4.1

- Rename "Projects" to "Moments" or/ "Events"
- Originals to be stored in "Media" or/ "Archive" or/ "Originals"
- PictureFS
  - **/2022-Media**
    - /2022-01-27
      - /iPhone 12 Pro Max
  - **/2022-Moments**
    - /(2022-01-27) Dan's Birthday
      - A0_Originals
        - Original Media with original filenames
      - C0_Master
      - C9_Deliverables
- Moments and Memories can be stored independently of the original media files
- Files in moments can be archived in Media as well as being available for 
  catalogs
- System needs some kind of central database
  - SQLite DB?
  - Manifest?
  - README files in top-level folders?
- TODO: Add File to specify PictureFS version in-use
- TODO: Create Inbox Folder

## Goals:
- Make it easier to offload files and projects, by hand if necessary
- Require shorter path names and fewer nested folders
- Have a way to know where everything is and if it's being stored in the 
  right place