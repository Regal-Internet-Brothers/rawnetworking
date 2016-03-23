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
	Method OnClientBound:Bool(C:Client, Port:Int, Response:Bool)
		If (Not Response) Then
			Error("Unable to connect to the remote host.")
		Endif
		
		' Tell 'regal.transport' to start receiving.
		Return True
	End
	
	Method OnPacketReceived:Void(Data:Packet, Length:Int, From:NetworkUser)
		Print("Received a message from the server:")
		
		While (Not Data.Eof())
			Print(Data.ReadLine())
		Wend
		
		Return
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
	New ClientExample()
	
	Return 0
End