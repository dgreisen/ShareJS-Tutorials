# import the Connect middleware (http://www.senchalabs.org/connect/)
connect = require('connect')
# import the sharejs server
sharejs = require('share').server	

# create a settings object for our sharejs server
sharejsOpts =
	browserChannel:		# set pluggable transport to BrowserChannel
		cors: "*"
	db: "none"			# no persistence

# create a Connect app
app = connect()
# attach a static file server that serves files from our static directory
app.use(connect['static'](__dirname + "/../static"))
# pass the app to ShareJS so it can create both the Connect and ShareJS servers
server = sharejs.attach(app, sharejsOpts);

# set our server port and start the server
port = 5000
server.listen(port, () -> console.log("Listening on " + port))
