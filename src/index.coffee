# import the Connect middleware (http://www.senchalabs.org/connect/)
connect = require('connect')
# import the sharejs server
sharejs = require('share').server	

# create a settings object for our sharejs server
sharejsOpts =
	browserChannel:		# set pluggable transport to BrowserChannel
		cors: "*"
	db: "none"			# no persistence

# create a Connect server
server = connect.createServer()
# attach a static file server that serves files from our static directory
server.use(connect['static'](__dirname + "/../static"))
# create a sharejs server and bind to Connect server
sharejs.attach(server, sharejsOpts);

# set our server port and start the server
port = 5000
server.listen(port, () -> console.log("Listening on " + port))
