Strict

Public

' Imports:
Import mojo

Import regal.rawnetworking

' Classes:
Class Application Extends App Implements IServerApplication Final
	' Constant variable(s):
	Const PORT:= 5029
	
	' Constructor(s):
	Method OnCreate:Int()
		SetUpdateRate(0) ' 30
		
		' Create a 'PacketManager' to handle memory for us.
		Packets = New PacketManager()
		
		' Start our server.
		Host = New Server(PORT, Self) ' PORT_AUTO
		
		Return 0
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
		
		Return
	End
	
	Method OnServerClientAccepted:Bool(Host:Server)
		' Always agree to more potential clients.
		Return True
	End
	
	Public
	
	' Fields:
	Field Packets:PacketManager
End