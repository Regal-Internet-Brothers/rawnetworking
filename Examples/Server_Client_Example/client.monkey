Strict

Public

' Preprocessor related:

' Make sure to disable this if you want networking functionality
' to behave while the application isn't in focus.
#MOJO_AUTO_SUSPEND_ENABLED = False

' Imports:
Import mojo

Import brl.asyncevent

Import regal.transport

' Classes:
Class ClientExample Extends App Implements ClientApplication
	' Constant variable(s):
	Const ADDRESS:String = "127.0.0.1"
	Const PORT:Int = 27015
	
	' Fields:
	Field Connection:Client
	
	' Constructor(s):
	Method OnCreate:Int()
		SetUpdateRate(0) ' 60 ' 30
		
		Return 0
	End
	
	' Methods:
	Method OnUpdate:Int()
		UpdateAsyncEvents()
		
		If (Connection = Null) Then
			If (KeyHit(KEY_F1)) Then
				Print("Connecting to the server: (" + ADDRESS + " : " + PORT + ")")
				
				' Start connecting to a server at 'ADDRESS' on the port 'PORT'.
				Connection = New Client(ADDRESS, PORT, Self)
			Endif
		Endif
		
		Return 0
	End
	
	Method OnRender:Int()
		Cls()
		
		If (Connection = Null) Then
			DrawText("Press F1 to connect to the server.", 8.0, 8.0)
		Endif
		
		Return 0
	End
	
	' Callbacks:
	
	' This is called when a new message is received.
	Method OnPacketReceived:Void(Data:Packet, Length:Int, From:NetworkUser)
		Print("Received a message from the server:")
		
		While (Not Data.Eof())
			Print(Data.ReadLine())
		Wend
		
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
	
	Method OnClientDisconnected:Void(C:Client)
		Print("Disconnected from the server.")
		
		' Close our connection formally.
		Connection.Close(); Connection = Null
		
		' This is where we could tell the user the bad news.
		' If not, this example will go back to its default state.
		'Error("Disconnected from the server: Unable to continue.")
		
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
	New ClientExample()
	
	Return 0
End