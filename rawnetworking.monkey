Strict

Public

#Rem
	NOTES:
		* This module does not require any other 'regal' modules. (Currently)
		This is a purely BRL-only module, meant to showcase proper usage of 'brl.socket' and co.
#End

' Imports:
Import brl.socket
Import brl.databuffer
Import brl.datastream
Import brl.pool

' Constant variable(s):
Const PORT_AUTO:= 0

' Interfaces:
Interface ServerApplication
	' Methods:
	
	' The return-value of this methods indicates if the server should start accepting clients.
	Method OnServerBound:Bool(Host:Server, Port:Int, Response:Bool)
	
	' The return-value indicates if more clients should be accepted.
	Method OnServerClientAccepted:Bool(Host:Server) ' ...
End

Interface ClientApplication
	' Methods:
	'Method OnClientBound:Bool(C:Client, Port:Int, Response:Bool)
End

' Classes:
Class Server Implements IOnBindComplete, IOnAcceptComplete Final
	' Constructor(s):
	
	' This overload automatically calls 'Begin' using 'Port'.
	Method New(Parent:ServerApplication, Port:Int)
		Self.Parent = Parent
		
		Begin(Port)
	End
	
	' This overload does not call 'Begin'.
	Method New(Parent:ServerApplication)
		Self.Parent = Parent
	End
	
	' Destructor(s):
	Method Close:Void()
		' Close our connection.
		Connection.Close()
		
		' Restore default values:
		Connection = Null
		Port = PORT_AUTO
		
		' Restore the correct flags:
		Accepting = False
		
		Return
	End
	
	' Methods (Public):
	Method Begin:Void(RemotePort:Int)
		Local S:= New Socket()
		
		S.BindAsync("", RemotePort, Self)
		
		' Since nothing went wrong initially, set the internal port.
		Port = RemotePort
		
		Return
	End
	
	#Rem
		This is used to begin accepting clients.
		
		The return-value of this method indicates
		if we could start accepting clients again.
		
		If we are already accepting clients, this will return 'False'.
	#End
	
	Method AcceptClients:Bool()
		If (Accepting) Then
			Return False
		Endif
		
		Connection.AcceptAsync(Self)
		
		' Return the default response.
		Return True
	End
	
	' Methods (Protected):
	Protected
	
	Method OnBindComplete:Void(Bound:Bool, Source:Socket)
		' Tell our parent what's going on.
		Local Response:= Parent.OnServerBound(Self, Port, Bound)
		
		If (Not Bound) Then
			Return
		Endif
		
		Self.Connection = Source
		
		' Check if our parent wants us to accept clients initially.
		If (Response) Then
			' They said yes, start accepting clients.
			AcceptClients()
		Endif
	End
	
	Method OnAcceptComplete:Void(Connection:Socket, Source:Socket)
		If (Connection <> Self.Connection) Then
			Return
		Endif
		
		' Ask our parent if we should continue accepting clients (When available).
		If (Parent.OnServerClientAccepted(Self)) Then
			' Our parent said yes, accept more.
			AcceptClients()
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
	
	Method IsOpen:Bool() Property
		Return (Connection <> Null)
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
	
	Public
	
	' Fields (Protected):
	Protected
	
	' This acts as the parent application.
	Field Parent:ServerApplication
	
	' This is the socket we use 
	Field _Connection:Socket
	
	' Meta:
	Field _Port:Int = PORT_AUTO
	
	' Booleans / Flags:
	Field Accepting:Bool = False
	
	Public
End

' Memory management layer:
Class Packet Extends DataStream Final
	' Constructor(s):
	Method New(Size:Int)
		Super.New(New DataBuffer(Size))
	End
	
	Method New(InputData:DataBuffer)
		Super.New(InputData)
	End
	
	' Destructor(s):
	Method Reset:Void()
		Seek(0)
		
		Return
	End
	
	Method Close:Void()
		Data.Discard()
		
		Super.Close()
		
		Return
	End
End

' This handles the storage of 'Packet' objects,
' as well as their "transmission states".
Class PacketManager Extends Pool<Packet> Final
	' Constructor(s):
	Method New(Capacity:Int=4)
		Super.New(Capacity)
		
		Construct()
	End
	
	Method Construct:Void()
		InTransit = New Stack<Packet>()
		
		Return
	End
	
	' Desturctor(s):
	Method Discard:Void()
		InTransit.Clear()
		
		Return
	End
	
	' Methods:
	
	' This resets a 'Packet', allowing it to be used again via 'Allocate'.
	Method Free:Void(P:Packet)
		P.Reset()
		
		Super.Free(P)
	End
	
	' This marks a 'Packet' as currently "in transit".
	' This means the 'Data' property of 'P' is in use by 'brl.socket'.
	Method MarkTransmission:Void(P:Packet)
		InTransit.Push(P)
		
		Return
	End
	
	' This removes the "transmission state" from 'P'.
	' After calling this, it's a good idea to call 'Free' on this 'Packet'.
	Method FinishTransmission:Void(P:Packet)
		InTransit.RemoveEach(P)
		
		Return
	End
	
	' This calls the main overload with the result of 'GetTransmission'.
	' If the 'CanDiscardData' argument is enabled, 'Buffer' may
	' be freed if we couldn't find an associated 'Packet'.
	' The return-value is the 'Packet' found, if any.
	Method FinishTransmission:Packet(Buffer:DataBuffer, CanDiscardData:Bool)
		Local P:= GetTransmission(Buffer)
		
		If (P = Null) Then
			If (CanDiscardData) Then
				Buffer.Discard()
				
				Return
			Endif
		Endif
		
		FinishTransmission(P)
		
		Return P
	End
	
	' This retrieves a 'Packet' that is "in transit", using its 'DataBuffer' as an identifier.
	' If a 'Packet' could not be found, 'Null' is returned.
	Method GetTransmission:Packet(Buffer:DataBuffer)
		For Local P:= Eachin InTransit
			If (P.Data = Buffer) Then
				Return P
			Endif
		Next
		
		Return Null
	End
	
	' Fields:
	
	' This holds handles to 'Packet' objects that are in transit.
	' For details, see 'MarkTransmission' above.
	Field InTransit:Stack<Packet>
End