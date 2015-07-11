BEWARE: This is all work in progress.

UNDER CONSTRUCTION

This directory contains tools to create the offline help of the wiki.

Downloading the wiki:

Compile wikiget.lpi

Download all pages and images:
./wikiget --allmissing

Download changes of last 2 days
./wikiget --recent=2 --deletenotusedpages --deletenotusedimages

Note: you can stop/kill the tool at any time and run it again. It will download
only the missing files.
See ./wikiget -h for all options.


Creating XHTML pages:
./wikiconvert --format=xhtml --css=html/wiki.css 'wikixml/*.xml'


Creating HTML pages:
./wikiconvert --format=html --css=html/wiki.css 'wikixml/*.xml'


Creating chm:
./wikiconvert --format=chm --css=chm/wiki.css wikixml/Lazarus_Documentation.g400.xml 'wikixml/*.xml'


ToDos
ToDos wiki parser: see wikiparser.pas

ToDos iphtml:
-too big space between paragraphs
-jump to anchor after loading, Note: before first paint the areas are all 0,0,0,0
-background for pre
-backslashes in text are not shown
-slow on some pages (e.g. lazarus_documentation)

