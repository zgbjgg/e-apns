e-apns
======

erlang server for APNS 

for more info about APNS [check this](http://developer.apple.com/library/mac/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingWIthAPS/CommunicatingWIthAPS.html#//apple_ref/doc/uid/TP40008194-CH101-SW1)
building
======

build the project by compiling all source code:


			$ make e-apns
			
configuring
======

configure the config file under priv directory, setting all parameters to valid params:

		- address_apns:		address for APNS server
		- port_apns:		port for APNS server
		- certfile_apns:	certificate file (created from .cer file)
		- keyfile_apns:		key file (created from .p12 file)
		- password_apns:	password for connect to APNS server 
		- timeout_apns:		max time for waiting a valid connection to APNS server

NOTE: files cert and key could be generated with openssl.


using
======

To start the e-apns from an erlang shell just start with the correct path:

			$ erl -pa path/to/e-apns/ebin
			
In the erlang shell start the application:

			> application:start('e-apns').
			I(<0.50.0>) [e-apns] apns initialized
			
NOTE: you must start crypto, public_key and ssl before start e-apns.


connecting to APNS
======

Connecting to APNS is easy, just type:

			> {ok, Resource} = 'e-apns':get_resource_apns().
			{ok,{ok,{sslsocket,new_ssl,<0.??.0>},<0.??.0>}}
			
Resource variable is used to send a message or receive apns messages over ssl socket.

sending message to a device
======

To send a message you need some parameters like:

		- Token (device id)
		- The payload, in this case the structure for the payload is: {Msg, Sound, Badge}
		- Expiry
		- Identifier
		- The Resource (got with get_resource_apns)

Send a message using 'push_apns' function:

			> 'e-apns':push_apns(Resource, 1, 1000, "DeviceId", {"Hello", "alert", "10"}).
			ok
			
this could be send the message "Hello" to the device with id = "DeviceId"

license
======

see LICENSE.txt for more info
