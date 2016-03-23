Strict

Public

' Preprocessor related:
'#GLFW_USE_MINGW = False

' Make sure to disable this if you want networking functionality
' to behave while the application isn't in focus.
#MOJO_AUTO_SUSPEND_ENABLED = False

' Imports:
Import mojo

Import regal.transport

' Classes:
Class Application Extends App Implements ServerApplication, ClientApplication Final
	' Constant variable(s):
	
	' This will be the hostname used to connect to our 'Host' server.
	Const ADDRESS:String = "127.0.0.1" ' "localhost"
	
	' This will be the remote-port we use to host our server.
	' This is also what we when our clients are connecting.
	Const PORT:= Server.PORT_AUTO ' 5029
	
	' Constructor(s):
	Method OnCreate:Int()
		' Set the application's update-rate.
		SetUpdateRate(0) ' 30
		
		CreateContainers()
		
		OpeningServer = False
		SendFromHost = False
		
		Return 0
	End
	
	Method CreateContainers:Void()
		' Create a container for our clients (Not to be confused with 'NetworkUsers').
		Clients = New List<Client>()
		
		' Create a container of users (Not to be confused with 'Clients').
		Users = New List<NetworkUser>()
		
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
		
		If (KeyHit(KEY_F1)) Then
			' Start our server.
			Host = New Server(PORT, Self) ' Server.PORT_AUTO
			
			OpeningServer = True
		Elseif (Host <> Null And Host.IsOpen) Then
			If (KeyHit(KEY_F2)) Then
				Print("Adding a client...")
				
				AddClient()
			Else
				Local Character:= GetChar()
				
				If (Character > 32) Then
					Local P:= Host.AllocatePacket()
					
					P.WriteString("Key pressed: " + Character + ": '" + String.FromChar(Character) + "'")
					
					If (SendFromHost) Then
						P.WriteLine(" FROM: SERVER")
						
						For Local U:= Eachin Users
							Host.Send(P, U)
						Next
					Else
						P.WriteLine(" FROM: CLIENT")
						
						For Local C:= Eachin Clients
							C.Send(P)
						Next
					Endif
					
					Host.Free(P)
					
					SendFromHost = Not SendFromHost
				Endif
			Endif
		Endif
		
		Return 0
	End
	
	Method OnRender:Int()
		Cls()
		
		If (Host = Null Or Not Host.IsOpen) Then
			If (Not OpeningServer) Then
				DrawText("Press F1 to host a server.", 16.0, 16.0)
			Else
				DrawText("Opening server, please wait...", 16.0, 16.0)
			Endif
		Else
			' Get the height of the current font.
			Local FHeight:= FontHeight()
			Local DW:= Float(DeviceWidth())
			Local DH:= Float(DeviceHeight())
			
			' Debug information:
			PushMatrix()
			
			Translate(16.0, 16.0)
			DrawText("Press keys on your keyboard to send messages. (" + Int(SendFromHost) + ")", 0.0, 0.0)
			Translate(0.0, FHeight)
			DrawText("Press F2 to add a client.", 0.0, 0.0)
			
			PopMatrix()
			
			' Message display:
			PushMatrix()
			
			Translate(DW / 2.0, DH / 2.0)
			Scale(2.5, 2.5)
			
			DrawText("Latest message:", 0.0, -(FHeight * 2.0), 0.5, 0.5)
			DrawText(LatestMessage, 0.0, 0.0, 0.5, 0.5)
			
			PopMatrix()
			
			' Client count:
			PushMatrix()
			
			DrawText("Clients connected: " + Clients.Count(), DW - 16.0, 16.0, 1.0, 0.0)
			
			PopMatrix()
		Endif
		
		Return 0
	End
	
	Method AddClient:Client()
		Local C:= New Client(ADDRESS, Host.Port, Self)
		
		Clients.AddLast(C)
		
		Return C
	End
	
	' Methods (Protected):
	Protected
	
	' These are callbacks defined by 'NetApplication', and are called by 'Server' or 'Client' objects:
	Method CanSwitchParent:Bool(CurrentParent:NetApplication, NewParent:NetApplication)
		Return False ' True
	End
	
	Method OnPacketReceived:Void(Data:Packet, Length:Int, From:NetworkUser)
		Print("Message received. (" + Length + " bytes)")
		
		Local Message:= Data.ReadLine()
		
		If (Message = LatestMessage) Then
			Print("Message is the same as the last one.")
		Else
			Print("Message contents:")
			Print(LatestMessage)
			
			LatestMessage = Message
		Endif
		
		Return
	End
	
	Method OnUnknownPacket:Void(UnknownData:DataBuffer, Offset:Int, Count:Int)
		Print("Unknwon packet data found: " + Offset + ", {" + Count + "}")
		
		Return
	End
	
	' These are callbacks defined by 'ServerApplication', and are called by 'Server' objects:
	
	' This is called when a server is attempting to bind a socket.
	Method OnServerBound:Bool(Host:Server, Port:Int, Response:Bool)
		OpeningServer = False
		
		If (Not Response) Then
			Print("Failed to bound server socket on port " + Port + ".")
			
			Return False
		Endif
		
		Print("Server socket bound on port " + Port + "; everything checks out.")
		
		Print("Attempting to connect a 'Client'...")
		
		AddClient()
		
		' Tell 'Host' to start accepting users.
		Return True
	End
	
	Method OnServerUserAccepted:Bool(Host:Server, User:NetworkUser)
		Users.AddLast(User)
		
		' Always agree to more potential clients.
		Return True
	End
	
	Method OnClientBound:Bool(C:Client, Port:Int, Response:Bool)
		If (Not Response) Then
			Print("Failed to bind client socket on port " + Port + ".")
			
			Return False
		Endif
		
		Print("Client socket connected to port " + Port + ".")
		
		Print("Allowing messages...")
		
		' Tell 'C' to accept messages.
		Return True
	End
	
	Public
	
	' Fields:
	
	' The 'Server' our 'Client' objects will connect to.
	Field Host:Server
	
	' A list of 'Clients' that have established a connection to 'Host'.
	Field Clients:List<Client>
	
	' A list of 'NetworkUsers' connected to 'Host'.
	Field Users:List<NetworkUser>
	
	' This is used to hold the latest message on the screen.
	Field LatestMessage:String
	
	' Booleans / Flags:
	Field OpeningServer:Bool
	Field SendFromHost:Bool
End

' Functions:
Function Main:Int()
	New Application()
	
	' Return the default response.
	Return 0
End