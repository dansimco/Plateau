#Frontend Loader

##Installation:

  gem install frontendloader

##Usage:

	fel init
  
Creates a config yaml file, where you can name files and variables, and prioritize the loading of certain scripts and styles.

	fel compile
  
- Scans the directory containing FrontendLoader.yml for .less files, .mustache templates and .js scripts. 
- Compiles the .less files down to css.
- Joins the mustache templates into a single javascript object: templates = {}
- Joins javascript files together (including mustache templates) and yui compresses if set in yml.

**IMPORTANT: Requires less.js & node for .less compilation: see & install http://lesscss.org/#-server-side-usage**