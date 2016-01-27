Strict

Public

' Imports:
Import mojo

Import regal.rawnetworking

' Classes:
Class Application Extends App Implements IServerApplication Final
	' Constant variable(s):
	
	' This will be the hostname used to connect to our 'Host' server.
	Const ADDRESS:String = "127.0.0.1" ' "localhost"
	
	' This will be the remote-port we use to host our server.
	' This is also what we when our clients are connecting.
	Const PORT:= 5029
	
	' Constructor(s):
	Method OnCreate:Int()
		' Set the application's update-rate.
		SetUpdateRate(0) ' 30
		
		CreateContainers()
		
		' Start our server.
		Host = New Server(PORT, Self) ' PORT_AUTO
		
		Return 0
	End
	
	Method CreateContainers:Void()
		' Create a container for our clients (Not to be confused with 'NetUserHandles').
		Clients = New List<Client>()
		
		' Create a container of users (Not to be confused with 'Clients').
		Users = New List<NetUserHandle>()
		
		Return
	End
	
	' Methods (Public):
	Method OnUpdate:Int()
		#Rem
			Update all asynchronous events.
			(Async networking behavior)
			
			Basically, different threads have different operations being performed.
			
			For example, 'Server' has 'Accept' running thanks to 'AcceptAsync'.
			This blocks execution on the thread running 'Accept', so another thread is made.
			
			Think of threads as functions, which run from A to B, but ran
			on different cores, so they can happen at the same time.
			(Or at least, that's the concept)
		#End
		
		UpdateAsyncEvents()
		
		Return 0
	End
	
	Method OnRender:Int()
		Cls()
		
		DrawText("Hello world.", 16.0, 16.0)
		
		Return 0
	End
	
	' Methods (Protected):
	Protected
	
	' These are callbacks defined by 'IServerApplication', and are called by 'Server' objects:
	
	' This is called when a server is attempting to bind a socket.
	Method OnServerBound:Void(Host:Server, Port:Int, Response:Bool)
		If (Not Response) Then
			Print("Failed to bound server socket on port " + Port + ".")
			
			Return
		Endif
		
		Print("Server socket bound on port " + Port + "; everything checks out.")
		
		Print("Attempting to connect a 'Client'...")
		
		Local C:= New Client(ADDRESS, Port, Self)
		
		Clients.AddLast(C)
		
		Return
	End
	
	Method OnServerUserAccepted:Bool(Host:Server, User:NetUserHandle)
		Users.AddLast(User)
		
		' Always agree to more potential clients.
		Return True
	End
	
	Public
	
	' Fields:
	
	' The 'Server' our 'Client' objects will connect to.
	Field Host:Server
	
	' A list of 'Clients' that have established a connection to 'Host'.
	Field Clients:List<Client>
	
	' A listo of 'NetUserHandles' connected to 'Host'.
	Field Users:List<NetUserHandle>
End