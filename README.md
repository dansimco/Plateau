#Plateau!

A database-less publishing engine which takes markdown copy (or straight html) and mustache templates and builds a flat-file html website & blog with rss, sitemap.xml tagging, custom metadata and per-post/page css & javascript. No serverside infrastructure required other than serving of flat html files, though publishing via git is recommended for speed. 

Install:

	gem install plateau

Create a project in current folder:
  	
   	plateau init

Build into rendered html:

  	plateau build
  
Builds a static html website in ./site using content from ./content and the theme specified in plateau.yml