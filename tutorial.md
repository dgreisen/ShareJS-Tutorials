ShareJS Tutorial
================

This tutorial walks you through coding and setting up a very simple ShareJS
website with a single, shared, textarea. ShareJS allows multiple clients to
all edit the same document simultaneously and in real-time. The ShareJS 
server accomplishes this with 
[Operational Transforms](http://en.wikipedia.org/wiki/Operational_transformation).


In order to follow along in this tutorial, you need to have 
[Node 0.6](http://nodejs.org/) or later and
[coffeescript](http://coffeescript.org/)  installed on your computer. A basic
familiarity with both is helpful.


Directory and Dependency Setup
------------------------------

For this simple project, we are going to use node to serve both our static
files and handle ShareJS. For larger or production projects, you will want to
serve your static files from server like NGINX. 

From the command line:

	# create a project directory 
	> mkdir ./sharetut
	> cd ./sharetut

	# all the rest of the commands in this tutorial will be made from 
	# the project directory.

	# create directory for our static files
	> mkdir ./static
	# create directory for our source code and compiled code
	> mkdir ./src ./lib

	# install npm dependencies
	>  npm install share connect browserchannel

	# install redis, which is required by share, but isn't installed by npm
	> cd ./node_modules/share
	> npm install redis
	> cd ../..

Next we create a Cakefile to make our development lives much easier. In
`./Cakefile`:

	{exec} = require 'child_process'

	task 'build', 'Build the .js files', (options) ->
		console.log('Compiling Coffee from src to lib')
		exec "coffee --compile --bare --output lib/ src/", (err, stdout, stderr) ->
			throw err if err
			console.log stdout + stderr

	task 'watch', 'Watch src directory and build the .js files', (options) ->
		console.log('Watching Coffee in src and compiling to lib')
		cp = exec "coffee --watch --bare --output lib/ src/"
		cp.stdout.on "data", (data) -> console.log(data)
		cp.stderr.on "data", (data) -> console.log(data)

Now in our root project directory we can simply type the command 
`cake watch &` and any changes to our src directory will automatically be
compiled into our lib directory.

Set up the Static Server
------------------------

Before we start mucking about with ShareJS, let's set up a simple static node
server. In `./src/index.coffee`:

	# import the Connect middleware (http://www.senchalabs.org/connect/)
	connect = require('connect')
	http = require('http')

	# we are using the new connect 2.7, so we must create an app then create
	# a server from the app:

	# create a Connect application
	app = connect()
	# attach a static file server that serves files from our static directory
	app.use(connect['static'](__dirname + "/../static"))

	# now we create the server:
	server = http.createServer(app)

	# set our server port and start the server
	port = 5000
	server.listen(port, () -> console.log("Listening on " + port))

Next, we create a simple html file for our server to serve. In 
`./static/index.html`:

	<html>
		<head>
			<title>ShareJS Tutorial</title>
		</head>
		<body>
			<h1>ShareJS Tutorial</h1>
			<textarea id='sharetext' ></textarea>
		</body>
	</html>

Now we can start our server and visit the page we just created. If you ran the
command `cake watch` then our server was automatically complide. If you didn't,
then you need to run `cake build` to build to javascript files in `./lib`. From
the command line start our compiled server: `node ./lib/index.js`, then in our
browser go to `127.0.0.1:5000` to see our very basic page.

Add the ShareJS Server
----------------------
Incredibly simple, just add the ShareJS dependency and pass our app into shareJS.
ShareJS will handle creating the server for us.

<pre>
# import the Connect middleware (http://www.senchalabs.org/connect/)
connect = require('connect')

<b># import the ShareJS server
ShareJS = require('share').server	

# create a settings object for our ShareJS server
ShareJSOpts =
	browserChannel:		# set pluggable transport to BrowserChannel
		cors: "*"
	db: "none"			# no persistence</b>

# create a Connect server
app = connect()
# attach a static file server that serves files from our static directory
app.use(connect['static'](__dirname + "/../static"))

<b># pass the app to ShareJS so it can create both the Connect and ShareJS servers
server = ShareJS.attach(app, ShareJSOpts);</b>

# set our server port and start the server
port = 5000
server.listen(port, () -> console.log("Listening on " + port))
</pre>

ShareJS has a pluggable tranport infrastructure. That means that it can communicate
with the client over several different protocols. It also has pluggable persistence.
The `ShareJSOpts` specify a bare-bones ShareJS server that uses the default
BrowserChannel transport and has no database for persistence.



Add ShareJS client to our webpage
---------------------------------
We have to add three javascript files to our html page, the BrowserChannel transport,
the ShareJS client, and a helper function connects the textarea to the ShareJS client.
Then, all we do is start the client, and we're good to go.

The npm modules we installed earlier include the client-side code. So we have to symlink
to them from our static directory. npm installs local modules in `./node_modules` so from
our project root:

	> ln -s ../node_modules/browserchannel/dist/bcsocket.js ./static
	> ln -s ../node_modules/share/webclient/ ./static

We use `..` because even though we are in our project root, the symlink path must be relative
to the final location, in this case, `./static`.

Now in `static/index.html` we add the scripts and start our client.

	<html>
		<head>
			<title>ShareJS Tutorial</title>
			<!-- NEW -->
			<script src="bcsocket.js"></script>				<!-- add transport -->
			<script src="webclient/share.js"></script>		<!-- ShareJS -->
			<script src="webclient/textarea.js"></script>	<!-- helper to attach textarea to ShareJS server -->
			<!-- /NEW -->
		</head>
		<body>
			<h1>ShareJS Tutorial</h1>
			<textarea id='sharetext' ></textarea>
			<!-- NEW -->
			<script>
				// get the textarea element 
				var elem = document.getElementById("sharetext");
				// connect to the server
				var connection = sharejs.open('test', 'text', function(error, doc) {
					// this function is called once the connection is opened
					if (error) {
						console.log("ERROR:", error);
					} else {
						// attach the ShareJS document to the textarea
						doc.attach_textarea(elem);
					}
				});
			</script>
			<!-- /NEW -->
		</body>
	</html>

When we open the ShareJS server, we pass in a document name, a type, and a callback to call
when the connection has opened. In our case, we are opening the "test" document, which is of
type "text". Every client that connects to our ShareJS server and requests the "test" 
document will be able to concurrently edit our document. ShareJS server currently supports
the "text" type and the "json" type. 

As long as no error occurs, the callback function is called with a document object. The "doc"
object emits events whenever another client makes a change, and you can call functions on it
to make changes to it from this client. However, we don't have to deal with any of this
because the `textarea.js` file added the `attach_textarea` function to the doc. This function
adds dom event listeners and document listeners needed to keep everything in sync. I encourage
you to read the source code of this function to get a good idea of how to the internals work.

We're done! Start the node server, and navigate to your index.html in two different web browsers.
When you type in one, you will see the changes in both. 