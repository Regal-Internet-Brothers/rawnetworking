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
		Print("Received a message from a client (" + From.Address.ToString() + ") {" + Length + "}:")
		
		While (Not Data.Eof())
			Print(Data.ReadLine())
		Wend
		
		Return
	End
	
	' The return-value of this methods indicates if the server should start accepting "clients" ('NetworkUsers').
	Method OnServerBound:Bool(Host:Server, Port:Int, Response:Bool)
		If (Not Response) Then
			Error("Failed to initialize server on port: " + Port)
		Endif
		
		' Tell 'regal.transport' to begin accepting new clients (Users) automatically.
		Return True
	End
	
	' The return-value indicates if more "clients" should be accepted.
	Method OnServerUserAccepted:Bool(Host:Server, User:NetworkUser)
		' Tell 'regal.transport' to continue accepting clients.
		Return True
	End
	
	' Miscellaneous:
	Method CanSwitchParent:Bool(CurrentParent:NetApplication, NewParent:NetApplication)
		Return False
	End
	
	Method OnUnknownPacket:Void(UnknownData:DataBuffer, Offset:Int, Count:Int)
		Return
	End
End 

' Functions:
Function Main:Int()
	New ServerExample()
	
	Return 0
End