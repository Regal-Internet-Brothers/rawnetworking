Strict

Public

' Preprocessor related:

' Make sure to disable this if you want networking functionality
' to behave while the application isn't in focus.
#MOJO_AUTO_SUSPEND_ENABLED = False

' Disable filtering to make the font clearer.
#MOJO_IMAGE_FILTERING_ENABLED = False

' Imports:
Import mojo

Import brl.asyncevent

Import regal.transport

' Classes:
Class ServerExample Extends App Implements ServerApplication
	' Constant variable(s):
	
	' This port can be anything you want it to be,
	' as long as any clients connect using the same port.
	Const PORT:Int = 27015
	
	' This describes the protocol used to transport data.
	' This must be the same on both the server and clients' ends.
	Const PROTOCOL:= TRANSPORT_PROTOCOL_TCP ' TRANSPORT_PROTOCOL_UDP
	
	' Enable this if you want to use asynchronous sending.
	Const USE_ASYNC_SEND:Bool = True ' False
	
	' Fields:
	
	#Rem
		This will act as our server that we can use to communicate with 'Clients'.
		These 'Clients' are represented by 'NetworkUser' handles, rather than actual 'Client' objects.
		
		Basically, 'Client' objects are used to connect to 'Server' objects, and
		'NetworkUser' objects are used to identify 'Clients' on the server's end.
	#End
	
	Field Connection:Server
	
	' This is what we'll use to keep track of connected clients ('NetworkUsers').
	Field Users:List<NetworkUser>
	
	' This will be used to hold the last message we received.
	Field CurrentMessage:String = "Waiting..."
	
	' Constructor(s):
	Method OnCreate:Int()
		' Set the update-rate of the application.
		SetUpdateRate(0) ' 60 ' 30
		
		' We'll be allocating our container(s) ahead of time.
		Users = New List<NetworkUser>()
		
		' Return the default response.
		Return 0
	End
	
	' Methods:
	Method OnUpdate:Int()
		#Rem
			Update all asynchronous behavior.
			
			This is important, as all asynchronous routines used
			in 'regal.transport' required this to be called periodically.
			
			Several other modules require this as well,
			so it's a good idea to call this function.
			
			This function can be imported via 'brl.asyncevent'.
		#End
		
		UpdateAsyncEvents()
		
		' Check if we've started a connection or not:
		If (Connection = Null) Then
			' Check if the user pressed F1:
			If (KeyHit(KEY_F1)) Then
				Print("Hosting a server on port: " + PORT)
				
				' Attempt to host using the port described by 'PORT' (Found above).
				Connection = New Server(PORT, Self, PROTOCOL)
				
				' From here, we wait until the appropriate callback is activated.
			Endif
		Else
			' Wait until our connection is considered "open" to proceed:
			If (Connection.IsOpen) Then
				' Execute 'WhileConnected' now that we're actually connected.
				WhileConnected()
			Endif
		Endif
		
		' Return the default response.
		Return 0
	End
	
	' This is called from 'OnUpdate' in this example.
	Method WhileConnected:Void()
		' Get the user's keyboard input.
		Local Character:= GetChar()
		
		' Check if it's a valid character:
		If (Character > 32) Then
			Local Message:String
			
			' Generate a string-representation of the user's input.
			Message = String.FromChar(Character)
			
			' Check if we're sending asynchronously:
			If (USE_ASYNC_SEND) Then
				' Enumerate all connected users:
				For Local U:= Eachin Users
					Local P:Packet = Connection.AllocatePacket()
					
					' Write the user's message.
					P.WriteLine(Message)
					
					#Rem
						Send asynchronously to the user.
						
						By sending asynchronously, you are giving up all
						control over 'P' (The described 'Packet' object).
						
						Because of this behavior, you should NOT call the
						'Connection' object's 'Free' method on this 'Packet'.
						
						Doing this will result in undefined behavior.
						
						The 'Packet' object passed to 'SendAsync' will
						be automatically released when appropriate.
					#End
					
					Connection.SendAsync(P, U)
				Next
			Else
				' Allocate a packet handle.
				Local P:= Connection.AllocatePacket()
				
				' Write the user's message.
				P.WriteLine(Message)
				
				' Enumerate all connected users:
				For Local U:= Eachin Users
					' Send our packet-data to each user.
					Connection.Send(P, U)
				Next
				
				' Release our packet handle, so the
				' object may be reused in the future.
				Connection.Free(P)
			Endif
		Endif
		
		Return
	End
	
	Method OnRender:Int()
		' Constant variable(s):
		
		' Thes will be used to draw text appropriately:
		Const TextScale:Float = 4.0
		Const HalfTextScale:= (TextScale / 2.0)
		
		' Clear the screen.
		Cls()
		
		If (Connection = Null) Then
			' Tell the player to press F1 to continue.
			DrawText("Press F1 to host a server (" + PORT + ")", 8.0, 8.0)
		Else
			If (Connection.IsOpen) Then
				' Tell the user they can send messages.
				DrawText("Press any key to send a message to connected users.", 8.0, 8.0)
				
				' Draw the message and related graphics to the screen:
				PushMatrix()
				
				Translate(Float(DeviceWidth() / 2), Float(DeviceHeight() / 2))
				
				Scale(TextScale, TextScale)
				
				DrawText("Message:", 0.0, ((-(FontHeight() / 2))*TextScale), 0.5, 0.5)
				
				DrawText(CurrentMessage, 0.0, 0.0, 0.5, 0.5)
				
				PopMatrix()
				
				DrawText("Connected users: " + Users.Count(), 8.0, DeviceHeight()-8.0, 0.0, 0.5)
			Else
				' Tell the user what's going on:
				PushMatrix()
				
				Translate(Float(DeviceWidth() / 2), Float(DeviceHeight() / 2))
				
				Scale(HalfTextScale, HalfTextScale)
				
				DrawText("Waiting for the server to open...", 0.0, 0.0, 0.5, 0.5)
				
				PopMatrix()
			Endif
		Endif
		
		' Return the default response.
		Return 0
	End
	
	' Callbacks:
	
	' This is called when a new message is received.
	Method OnPacketReceived:Void(Data:Packet, Length:Int, From:NetworkUser)
		If (Connection.Protocol = TRANSPORT_PROTOCOL_UDP) Then
			Local Response:Bool = False
			
			For Local U:= Eachin Users
				If (U.Equals(From)) Then
					Response = True
					
					Exit
				Endif
			Next
			
			If (Not Response) Then
				OnServerUserAccepted(Connection, From)
			Endif
		Endif
		
		Print("Received a message from a client (" + From.Address.ToString() + ") {" + Length + "}:")
		
		If (Not EndOfPacket(Data, Length)) Then
			' Read the first line.
			CurrentMessage = Data.ReadLine()
			
			Print("Message: " + CurrentMessage)
			
			' Check if there's anything left:
			If (Not EndOfPacket(Data, Length)) Then
				Print("")
				Print("Extra lines:")
				
				' Any other lines will be output to the console:
				While (Not EndOfPacket(Data, Length))
					Print(Data.ReadLine())
				Wend
			Endif
		Endif
		
		Return
	End
	
	' This is called when a "user" disconnects from a 'Server'.
	Method OnDisconnection:Void(Host:Server, User:NetworkUser)
		Print("User disconnected: " + User.Address.ToString())
		
		For Local LocalHandle:= Eachin Users
			If (User.Equals(LocalHandle)) Then
				Users.RemoveEach(LocalHandle)
				
				LocalHandle.Free()
				
				Exit
			Endif
		Next
		
		Return
	End
	
	' The return-value of this methods indicates if the server should start accepting "clients" ('NetworkUsers').
	Method OnServerBound:Bool(Host:Server, Port:Int, Response:Bool)
		' Check if we failed:
		If (Not Response) Then
			' We failed, raise a runtime error.
			Error("Failed to initialize server on port: " + Port)
			
			' The return-value means nothing if the server wasn't bound,
			' but returning 'False' is still ideal for future debugging purposes.
			Return False
		Endif
		
		' Tell the user the good news.
		Print("Server successfully bound to port: " + Port)
		
		' Tell 'regal.transport' to begin accepting new clients (Users) automatically.
		Return True
	End
	
	' The return-value indicates if more "clients" should be accepted.
	Method OnServerUserAccepted:Bool(Host:Server, User:NetworkUser)
		' This is used to notify you about incoming clients (Users).
		Users.AddLast(User)
		
		Print("Accepted a new user: " + User.Address.ToString())
		
		' Tell 'regal.transport' to continue accepting clients.
		Return True
	End
	
	' Miscellaneous:
	Method CanSwitchParent:Bool(CurrentParent:NetApplication, NewParent:NetApplication)
		' This is called to confirm that 'NewParent' is a suitable replacement for this object.
		' This is currently a placeholder, and as such has no bearing on any current behavior.
		
		' Deny any kind of ownership change.
		Return False
	End
	
	Method OnUnknownPacket:Void(UnknownData:DataBuffer, Offset:Int, Count:Int)
		' This is used for unidentified packets.
		' In general, this isn't going to be called
		' unless you're messing with raw sockets.
		
		Return
	End
End 

' Functions:
Function Main:Int()
	' Start the application.
	New ServerExample()
	
	' Return the default response.
	Return 0
End