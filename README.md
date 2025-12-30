# BilderalbumGD
Remake of my Bilderalbum in GodotEngine. 
See "Howto use" for a list of functions.

Features:
- To be able to use multiple monitors there is 1 main-window (the viewer) and multiple non-modal windows (browser).
- list item generation with workerthread (generate image-icons)
- browser displays Folder Tree
- dragndrop of items between browser to move files
- create/delete directories in browser
- saving/restore last session
- sqlite-database for image tagging
- search-by-tag based on database

ToDo:
- delete items in browser
- image tagging by AI?

## Howto use

### Viewer
When you run the app the viewer is shown.  
Press "new browser" to open a browser window.  

### Browser
The browser lets you navigate directories similiar to windows explorer. It displays a list off the images found.
You can have multiple browsers and dragndrop images to move them between directories
Click on a list item to display the image in the viewer.  

### Tagger
This window is for assigning tags to the displayed images.  
The information is saved in a database.  

### TagCreator
This window is for creating taggroups and tags.
Taggroup define the colors of a tag while the tag itself just contains some text.
The information is saved in a database.  

### Finder
Here you can filter images by tags.  
Click on a list item to display the image in the viewer.  
