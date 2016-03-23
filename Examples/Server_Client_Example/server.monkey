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
Class ServerExample Extends App Implements ServerApplication
	' Constant variable(s):
	Const PORT:Int = 27015
	
	' Fields:
	Field Connection:Server
	
	Field Users:List<NetworkUser>
	
	' Constructor(s):
	Method OnCreate:Int()
		SetUpdateRate(0) ' 60 ' 30
		
		Users = New List<NetworkUser>()
		
		Return 0
	End
	
	' Methods:
	Method OnUpdate:Int()
		UpdateAsyncEvents()
		
		If (Connection = Null) Then
			If (KeyHit(KEY_F1)) Then
				' Attempt to host using the port described by 'PORT'.
				Connection = New Server(PORT, Self)
			Endif
		Endif
		
		Return 0
	End
	
	Method OnRender:Int()
		Cls()
		
		If (Connection = Null) Then
			DrawText("Press F1 to host the server (" + PORT + ")", 8.0, 8.0)
		Endif
		
		Return 0
	End
	
	' Callbacks:
	Method OnPacketReceived:Void(Data:Packet, Length:Int, From:NetworkUser)
		If (Length <= 0) Then
			Print("Client disconnected: " + From.Address.ToString())
			
			For Local U:= Eachin Users
				If (From.Equals(U)) Then
					Users.RemoveEach(U)
					
					Exit
				Endif
			Next
			
			Return
		Endif
		
		Print("Received a message from a client (" + From.Address.ToString() + ") {" + Length + "}:")
		
		While (Not Data.Eof())
			Print(Data.ReadLine())
		Wend
		
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
	New ServerExample()
	
	Return 0
End