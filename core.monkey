Strict

Public

' Imports (Public):
Import packetmanager
Import packet
Import user

' Imports (Private):
Private

Import brl.socket
Import brl.stream
Import brl.databuffer

Public

' Aliases:
Alias ProtocolType = Int ' Byte

' Constant variable(s):
Const TRANSPORT_PROTOCOL_TCP:ProtocolType = 0
Const TRANSPORT_PROTOCOL_UDP:ProtocolType = 1

' Interfaces:
Interface NetApplication
	' Methods:
	Method CanSwitchParent:Bool(CurrentParent:NetApplication, NewParent:NetApplication)
	Method OnPacketReceived:Void(Data:Packet, Length:Int, From:NetworkUser)
	Method OnUnknownPacket:Void(UnknownData:DataBuffer, Offset:Int, Count:Int)
End

' Functions:
Function EndOfPacket:Bool(P:Stream, Length:Int)
	Return (P.Eof() Or (P.Position >= Length))
End

' Classes:

' This class covers common functionality between 'Server' and 'Client'.
Class NetworkManager<ParentType> Extends PacketManager Implements IOnSendComplete, IOnReceiveComplete, IOnSendToComplete, IOnReceiveFromComplete Abstract
	' Constant variable(s):
	Const PORT_AUTO:= 0
	
	' Constructor(s):
	
	' This constructor does not initiate anything.
	Method New(Parent:ParentType, PacketSize:Int=Default_PacketSize, PacketPoolSize:Int=Defaulk_PacketPoolSize)
		Super.New(PacketSize, PacketPoolSize)
		
		Self.Parent = Parent
	End
	
	' Destructor(s):
	
	' Please call-up to this destructor when extending this class.
	Method Close:Void()
		' Close our connection.
		If (Connection <> Null) Then
			Connection.Close()
			
			Connection = Null
		Endif
		
		' Restore default values:
		Port = PORT_AUTO
		
		Return
	End
	
	' Methods (Public):
	
	' Abstract:
	Method Accept:Bool() Abstract
	
	' Implemented:
	
	' These messages send 'P' directly to 'S'.
	' These overloads are protocol specific,
	' and as such, are not future-proof at all:
	
	' The return-value of these methods indicate the underlying
	' 'Socket.Send' and 'Socket.SendTo' methods' results:
	
	Method RawSendPacketTo:Int(S:Socket, P:Packet)
		' Since we're not using asynchronous behavior,
		' we don't need to mark this 'Packet' object.
		Return S.Send(P.Data, P.Offset, P.Position) ' 'P.Length'
	End
	
	Method RawSendPacketToAsync:Void(S:Socket, P:Packet)
		' Mark 'P', so we can take care of it later.
		MarkTransmission(P)
		
		' Send 'P' to 'S' asynchronously.
		S.SendAsync(P.Data, P.Offset, P.Position, Self) ' 'P.Length'
		
		Return
	End
	
	' These overloads are specific to UDP:
	Method RawSendPacketTo:Int(S:Socket, Addr:SocketAddress, P:Packet)
		' Since we're not using asynchronous behavior,
		' we don't need to mark this 'Packet' object.
		Return S.SendTo(P.Data, P.Offset, P.Position, Addr) ' 'P.Length'
	End
	
	Method RawSendPacketToAsync:Void(S:Socket, Addr:SocketAddress, P:Packet)
		' Mark 'P', so we can take care of it later.
		MarkTransmission(P)
		
		' Send 'P' to 'Addr' using 'S' asynchronously.
		S.SendToAsync(P.Data, P.Offset, P.Position, Addr, Self) ' 'P.Length'
		
		Return
	End
	
	' Methods (Protected):
	Protected
	
	' Abstract:
	Method OnDisconnectMessage:Void(Source:Socket) Abstract
	
	' Implemented:
	Method AcceptMessagesWith:Bool(S:Socket)
		Return AcceptMessagesWith(S, AllocatePacket())
	End
	
	' If the 'MarkPacket' argument is set to 'False',
	' this method may provide undefined behavior.
	Method AcceptMessagesWith:Bool(S:Socket, P:Packet, MarkPacket:Bool=True, Addr:SocketAddress=Null)
		If (MarkPacket) Then
			MarkTransmission(P)
		Endif
		
		P.Reset()
		
		Select Protocol
			Case TRANSPORT_PROTOCOL_TCP
				S.ReceiveAsync(P.Data, P.Offset, P.Length, Self)
			Case TRANSPORT_PROTOCOL_UDP
				If (Addr = Null) Then
					Addr = New SocketAddress()
				Endif
				
				S.ReceiveFromAsync(P.Data, P.Offset, P.Length, Addr, Self)
		End Select
		
		' Return the default response.
		Return True
	End
	
	' This represents 'S' using a 'NetworkUser' object.
	Method Represent:NetworkUser(S:Socket, ClosureRights:Bool) ' True
		' Not very efficient, but it works for now.
		Return New NetworkUser(S, S.RemoteAddress, ClosureRights)
	End
	
	Method Represent:NetworkUser(S:Socket, Address:SocketAddress, ClosureRights:Bool) ' True
		' Once again, not very efficient, but it works for now.
		Return New NetworkUser(S, Address, ClosureRights)
	End
	
	' BRL:
	Method OnSendComplete:Void(Data:DataBuffer, Offset:Int, Count:Int, Source:Socket)
		If (Source <> Connection) Then
			Return
		Endif
		
		' Kill the transmission; finish the transmission, and if
		' successful, give the associated 'Packet' object back.
		KillTransmission(Data, False)
		
		Return
	End
	
	Method OnSendToComplete:Void(Data:DataBuffer, Offset:Int, Count:Int, Addr:SocketAddress, Source:Socket)
		If (Source <> Connection) Then
			Return
		Endif
		
		' Kill the transmission; finish the transmission, and if
		' successful, give the associated 'Packet' object back.
		KillTransmission(Data, False)
		
		Return
	End
	
	Method OnReceiveComplete:Void(Data:DataBuffer, Offset:Int, Count:Int, Source:Socket)
		If (IsOpen) Then
			Local P:= GetTransmission(Data, False)
			
			If (P <> Null) Then
				If (Count > 0) Then
					Parent.OnPacketReceived(P, Count, Represent(Source, IsTCPSocket))
					
					' Start receiving again. (Do not mark this packet again)
					AcceptMessagesWith(Source, P, False)
				Else
					OnDisconnectMessage(Source)
				Endif
			Else
				Parent.OnUnknownPacket(Data, Offset, Count)
			Endif
		Else
			' Kill the transmission, and if we don't
			' recognize the enclosed data, throw it out.
			' This behavior may change in the future.
			KillTransmission(Data, True)
		Endif
		
		Return
	End
	
	'Method OnReceiveFromComplete : Void ( data:DataBuffer, offset:Int, count:Int, address:SocketAddress, source:Socket )
	Method OnReceiveFromComplete:Void(Data:DataBuffer, Offset:Int, Count:Int, Addr:SocketAddress, Source:Socket)
		If (IsOpen) Then
			Local P:= GetTransmission(Data, False)
			
			If (P <> Null) Then
				If (Count > 0) Then
					Parent.OnPacketReceived(P, Count, Represent(Source, Addr, False)) ' IsTCPSocket
					
					' Start receiving again. (Do not mark this packet again)
					AcceptMessagesWith(Source, P, False, Addr)
				Else
					OnDisconnectMessage(Source)
				Endif
			Else
				Parent.OnUnknownPacket(Data, Offset, Count)
			Endif
		Else
			' Kill the transmission, and if we don't
			' recognize the enclosed data, throw it out.
			' This behavior may change in the future.
			KillTransmission(Data, True)
		Endif
		
		Return
	End
	
	Public
	
	' Properties (Public):
	Method Port:Int() Property
		Return Self._Port
	End
	
	Method Connection:Socket() Property
		Return Self._Connection
	End
	
	Method Protocol:ProtocolType() Property
		Return Self._Protocol
	End
	
	Method IsOpen:Bool() Property
		Return (Connection <> Null)
	End
	
	Method IsTCPSocket:Bool() Property
		Return (Protocol = TRANSPORT_PROTOCOL_TCP)
	End
	
	Method IsUDPSocket:Bool() Property
		Return (Protocol = TRANSPORT_PROTOCOL_UDP)
	End
	
	' Properties (Protected):
	Protected
	
	Method Port:Void(Input:Int) Property
		Self._Port = Input
		
		Return
	End
	
	Method Connection:Void(Input:Socket) Property
		Self._Connection = Input
		
		Return
	End
	
	Method Protocol:Void(Input:ProtocolType) Property
		Self._Protocol = Input
		
		Return
	End
	
	Public
	
	' Fields (Protected):
	Protected
	
	' This acts as our "parent application".
	Field Parent:ParentType
	
	' Networking-related:
	
	' This is the socket we use most networking operations. (Protocol-specific)
	Field _Connection:Socket
	
	' Meta:
	Field _Port:Int = PORT_AUTO
	
	Field _Protocol:ProtocolType
	
	Public
End