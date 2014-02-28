express = require("express")
http = require("http")
path = require("path")
stylus = require("stylus")
axis = require("axis-css")
jeet = require("jeet")
app = express()

gulp = require("gulp")
plugins = require('gulp-load-plugins')()

express_port = 80
lr_port = 35729
lr = undefined

Array::move = (from, to) ->
	@splice to, 0, @splice(from, 1)[0]
	return

# EXPRESS ///////////////////////////////////////

startExpress = ->
	app.set "port", process.env.PORT or express_port
	app.set "views", path.join(__dirname, "views")
	app.set "view engine", "jade"
	app.use express.favicon()
	app.use express.logger("dev")
	app.use express.json()
	app.use express.urlencoded()
	app.use express.methodOverride()
	app.use app.router
	app.use require("stylus").middleware(
		src: __dirname + "/public/css/"
		dest: __dirname + "/public/css/"
		compile: compile
	)
	app.use express.static(path.join(__dirname, "public"))
	app.use require("connect-livereload")()
	app.listen express_port
	return

compile = (str, path) ->
	stylus(str).set("filename", path)
	.use(axis({implicit:false}))
	.set("compress", true)
	.define "url", stylus.url(
		paths: [__dirname + "/public/img"]
		limit: 10000
	)

app.use express.errorHandler()	if "development" is app.get("env")


# ROUTES ////////////////////////////////////////

app.get "/", (req, res) ->
	res.render "index", app.locals.projects
app.get "/home", (req, res) ->
	res.render "home", app.locals.projects
app.get "/projects", (req, res) ->
	projectOrder = req.param('order', null)
	app.locals.projects.move(0,app.locals.projects[0].order)
	app.locals.projects.move(projectOrder,0)
	res.render "projects", app.locals.projects




# LIVERELOAD ////////////////////////////////////

# Reference to the tinylr
# object to send notifications of file changes
# further down
startLivereload = ->
	lr = require("tiny-lr")()
	lr.listen lr_port
	return

# Notifies livereload of changes detected
# by `gulp.watch()`
notifyLivereload = (event) ->
	gulp.src(event.path,
		read: false
	).pipe require("gulp-livereload")(lr)
	return



# GULP TASKS ////////////////////////////////////

gulp.task 'svg', (event) ->
	gulp.src('./dev/svg/*.svg')
		.pipe(plugins.svgmin())
		.pipe(plugins.rename(
			suffix: ".min"
			))
		.pipe(gulp.dest('./public/svg'))
		.pipe(plugins.notify(message: "SVGs minified"))

gulp.task 'imgs', (event) ->
	# gulp.src('./dev/img/projects/*.png')
	# 	.pipe(plugins.imagemin())
	# 	.pipe(plugins.rename(
	# 		suffix: ".min"
	# 		))
	# 	.pipe(gulp.dest('./public/img/projects'))
	gulp.src(['./dev/img/*.jpg','./dev/img/*.png'])
		.pipe(plugins.imagemin())
		.pipe(plugins.rename(
			suffix: ".min"
			))
		.pipe(gulp.dest('./public/img'))
		.pipe(plugins.notify(message: "Images minified"))

gulp.task 'js', (event) ->
	gulp.src(['./dev/js/vendor/jquery.fixer.js','./dev/js/vendor/waypoints.min.js', './dev/js/vendor/mason.min.js'])
		.pipe(plugins.uglify(
			outSourceMap: false
			mangle: false
			compress: false
			))
		# .pipe(plugins.concat("vendor.js"))
		.pipe(plugins.rename("vendor.js"))
		.pipe(gulp.dest('./dev/js'))
	gulp.src('./dev/coffee/*.coffee')
		.pipe(plugins.coffee('app.js'))
		.pipe(plugins.uglify(
			outSourceMap: false
			compress: false
			mangle: false
			))
		.pipe(gulp.dest('./dev/js'))
gulp.task 'jsmin', (event) ->
	gulp.src(['./dev/js/vendor.js','./dev/js/app.js'])
		.pipe(plugins.concat("app.min.js"))
		.pipe(gulp.dest('./public/js'))
		.pipe(plugins.notify(message: "Scripts task complete"))

# MAIN TASKS ////////////////////////////////////

gulp.task 'io', (event) ->
	gulp.start 'svg', 'imgs'

gulp.task "default", ->
	startExpress()
	startLivereload()
	gulp.watch ['./**/*.jade','./**/*.styl', './**/app.min.js'], notifyLivereload
	gulp.watch ['./dev/coffee/*.coffee','./dev/js/vendor.js','./dev/js/app.js'], ['js', 'jsmin']
	console.log "Express server listening on port " + app.get("port")
	return

gulp.task "app", ->
	startExpress()
	console.log "Express server listening on port " + app.get("port")
	return


# DATA /////////////////////////////////////////

app.locals projects: [
	{
		id: "sa"
		order: 0
		name: "Success Academy"
		url: "successacademies.org"
		commits: "Commits: 226 to 3 Repositories"
		role: "Role: Front-end development"
		agency: "Agency: Makeable"
		lang: "Languages: PHP, CSS, Coffeescript"
		imgs: 5
		desc: "Success Academy is a network of charter schools in New York City that asked Makeable to help them show off their creative instructional approach with a new website. My main responsibilities were the homepage masonry layout, map functionality using Google Maps API, responsive development, and theming WooCommerce. The site is built on Wordpress and uses Sass, Grunt, and\u00a0Coffeescript."
	}
	{
		id: "clear"
		order: 1
		name: "Clear"
		url: "clearme.com"
		role: "Role: QA and production design"
		agency: "Agency: Poke New York"
		lang: "Languages: PHP, CSS, Coffeescript"
		imgs: 1
		desc: "CLEAR makes it easier and faster to get through airport security. Poke New York was asked to redesign and develop a new site using Wordpress to illustrate CLEAR's features. I did responsive development using Sass and Coffeescript as part of a\u00a0team."
	}
	{
		id: "ihny"
		order: 2
		name: "I Heard NY"
		url: "creativetime.org/projects/heard-ny/iheardny/"
		commits: "Commits: 101 to 3 Repositories"
		role: "Role: Front-end development"
		agency: "Agency: Poke New York"
		lang: "Languages: Jade, Stylus, JS, SVG"
		imgs: 3
		desc: "Creative Time commissions ambitious art projects throughout New York City and the world. For Nick Cave's HEARD•NY show at Grand Central Station, Creative Time asked Poke New York to create a social media aggregator for posts tagged \#IHEARDNY from Facebook, Twitter, Vine, Instagram, and Foursquare. Following the show, I developed an interactive thank you piece showing a selection of posts curated by Nick Cave. The social media platform's APIs were used to pull the posts into SVG letters where visitors could explore\u00a0them."
	}
	{
		id: "vse"
		order: 3
		name: "VSE"
		url: "videosushiedit.com"
		commits: "Commits: 297 to 1 Repository"
		role: "Role: Design and development"
		agency: "Agency: None"
		lang: "Languages: PHP, CSS, JS"
		imgs: 2
		desc: "Video Sushi Edit is the portfolio site of video editor Casey O'Donnell. I designed and developed the site with Wordpress and love. Specifically, Casey was concerned with the loading speed the video heavy site. To address this, I used Cloudflare to optimize delivery and accelerate his\u00a0website."
	}
	{
		id: "artnet"
		order: 4
		name: "Artnet"
		url: "artnet.com"
		role: "Role: Design and development"
		agency: "Agency: None"
		lang: "Languages: Jade, Stylus, JS"
		imgs: 2
		desc: "Artnet enables users to buy, sell, and research fine art, design, and decorative art online from the most recognized artists in the world. I planned, designed, and coded all of Artnet's marketing campaigns for over a year and a half and I got pretty damn good at making emails look good in Outlook 2003, I even made the emails\u00a0responsive."
	}
	{
		id: "rms"
		order: 5
		name: "Rafael Macho Studio"
		url: "rafaelmacho.com"
		commits: "Commits: 267 to 1 Repository"
		role: "Role: Development"
		agency: "Agency: Rafael Macho Studio"
		lang: "Languages: PHP, CSS, JS"
		imgs: 3
		desc: "Rafael Macho is a creative director based in California. I developed his Wordpress portfolio and Tumblr blog with my bare hands. Rafael's portfolio uses Grid-A-Licious, a JS library making grids sexier since\u00a0'08."
	}
]