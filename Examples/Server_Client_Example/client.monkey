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
Class ClientExample Extends App Implements ClientApplication
	' Constant variable(s):
	
	' This address should represent the server you wish to connect to.
	Const ADDRESS:String = "127.0.0.1" ' <-- Local system address.
	
	' This port should represent the port the
	' remote server at 'ADDRESS' is using.
	Const PORT:Int = 27015
	
	' Enable this if you want to use asynchronous sending.
	Const USE_ASYNC_SEND:Bool = True ' False
	
	' Fields:
	
	' This will act as our connection to a remote 'Server'.
	Field Connection:Client
	
	' This will be used to hold the last message we received.
	Field CurrentMessage:String = "Waiting..."
	
	' Constructor(s):
	Method OnCreate:Int()
		' Set the update-rate of the application.
		SetUpdateRate(0) ' 60 ' 30
		
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
				Print("Connecting to the server at: (" + ADDRESS + " : " + PORT + ")")
				
				' Start connecting to a server at 'ADDRESS' on the port described by 'PORT'.
				Connection = New Client(ADDRESS, PORT, Self)
				
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
				Local P:Packet = Connection.AllocatePacket()
					
				' Write the user's message.
				P.WriteLine(Message)
				
				#Rem
					Send asynchronously to the server.
					
					By sending asynchronously, you are giving up all
					control over 'P' (The described 'Packet' object).
					
					Because of this behavior, you should NOT call the
					'Connection' object's 'Free' method on this 'Packet'.
					
					Doing this will result in undefined behavior.
					
					The 'Packet' object passed to 'SendAsync' will
					be automatically released when appropriate.
				#End
				
				Connection.SendAsync(P)
			Else
				' Allocate a packet handle.
				Local P:= Connection.AllocatePacket()
				
				' Write the user's message.
				P.WriteLine(Message)
				
				' Send the packet to the server.
				Connection.Send(P)
				
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
			DrawText("Press F1 to connect to the server.", 8.0, 8.0)
		Else
			If (Connection.IsOpen) Then
				' Tell the user they can send messages.
				DrawText("Press any key to send a message to the server.", 8.0, 8.0)
				
				' Draw the message and related graphics to the screen:
				PushMatrix()
				
				Translate(Float(DeviceWidth() / 2), Float(DeviceHeight() / 2))
				
				Scale(TextScale, TextScale)
				
				DrawText("Message:", 0.0, ((-(FontHeight() / 2))*TextScale), 0.5, 0.5)
				
				DrawText(CurrentMessage, 0.0, 0.0, 0.5, 0.5)
				
				PopMatrix()
			Else
				' Tell the user what's going on:
				PushMatrix()
				
				Translate(Float(DeviceWidth() / 2), Float(DeviceHeight() / 2))
				
				Scale(HalfTextScale, HalfTextScale)
				
				DrawText("Waiting for the client to open...", 0.0, 0.0, 0.5, 0.5)
				
				PopMatrix()
			Endif
		Endif
		
		' Return the default response.
		Return 0
	End
	
	' Callbacks:
	
	' This is called when a new message is received.
	Method OnPacketReceived:Void(Data:Packet, Length:Int, From:NetworkUser)
		Print("Received a message from the server:")
		
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
	
	' The return-value of this method indicates that 'regal.transport' should start receiving.
	Method OnClientBound:Bool(C:Client, Port:Int, Response:Bool)
		' Check if we were able to make a connection:
		If (Not Response) Then
			' We failed to connect, raise a runtime error.
			Error("Unable to connect to the remote host.")
		Endif
		
		' Tell the user the good news.
		Print("Connected to the server at: " + Port)
		
		' Tell 'regal.transport' to start receiving.
		Return True
	End
	
	' This is called when 
	Method OnClientDisconnected:Void(C:Client)
		' Just for good measure, make sure we have a connection first:
		If (Connection = Null) Then
			Return
		Endif
		
		' Check if this is our connection.
		If (C <> Connection) Then
			' This shouldn't ever happen in this example, but it
			' may be useful to check this for safety reasons.
			Print("Unknown 'Client' object detected.")
			
			Return
		Endif
		
		' Close our connection formally.
		Connection.Close(); Connection = Null
		
		' This is where we could tell the user the bad news.
		' If not, this example will go back to its default state.
		'Error("Disconnected from the server: Unable to continue.")
		
		' Tell the user without exiting the program.
		Print("Disconnected from the server.")
		
		Return
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
	New ClientExample()
	
	' Return the default response.
	Return 0
End