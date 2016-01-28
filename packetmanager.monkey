Strict

Public

' Imports (Public):
Import packet

' Imports (Private):
Private

Import brl.pool
Import brl.socket
Import brl.databuffer
'Import brl.datastream

Public

' This handles the storage of 'Packet' objects,
' as well as their "transmission states".
Class PacketManager Extends Pool<Packet>
	' Constant variable(s):
	
	' Defaults:
	Const Default_PacketSize:= 1024 ' 4096
	Const Defaulk_PacketPoolSize:= 4 ' 8 ' 16
	
	' Constructor(s):
	Method New(PacketSize:Int=Default_PacketSize, InitialCapacity:Int=Defaulk_PacketPoolSize)
		Construct()
		
		Self.PacketSize = PacketSize
		
		GenerateInitialPackets(InitialCapacity)
	End
	
	Method Construct:Void()
		InTransit = New Stack<Packet>()
		Pool = New Stack<T>()
		
		Return
	End
	
	' Constructor(s) (Protected):
	Protected
	
	Method GenerateInitialPackets:Void(InitialCapacity:Int)
		For Local I:= 1 To InitialCapacity
			Pool.Push(GeneratePacket())
		Next
		
		Return
	End
	
	Public
	
	' Desturctor(s):
	
	' Calling this method is considered unsafe.
	' Use with caution, or not at all.
	Method Discard:Void()
		For Local P:= Eachin InTransit
			Free(FinishTransmission(P))
		Next
		
		InTransit.Clear()
		
		Return
	End
	
	' Methods (Public):
	Method AllocatePacket:Packet()
		If (Pool.IsEmpty) Then
			Return GeneratePacket()
		Endif
		
		Return Pool.Pop()
	End
	
	' This resets a 'Packet', allowing it to be used again via 'Allocate'.
	' If 'P' is 'Null', this will do nothing.
	Method Free:Void(P:Packet)
		If (P = Null) Then
			Return
		Endif
		
		P.Reset()
		
		Pool.Push(P)
		
		Return
	End
	
	' This marks a 'Packet' as currently "in transit".
	' This means the 'Data' property of 'P' is in use by 'brl.socket'.
	Method MarkTransmission:Void(P:Packet)
		InTransit.Push(P)
		
		Return
	End
	
	' This removes the "transmission state" from 'P'.
	' After calling this, it's a good idea to call 'Free' on this 'Packet'.
	' The return-value is 'P' if the operation was successful.
	Method FinishTransmission:Packet(P:Packet)
		InTransit.RemoveEach(P)
		
		Return P
	End
	
	' This calls the main overload with the result of 'GetTransmission'.
	' If the 'CanDiscardData' argument is enabled, 'Buffer' may
	' be freed if we couldn't find an associated 'Packet'.
	' The return-value is the 'Packet' found, if any.
	Method FinishTransmission:Packet(Buffer:DataBuffer, CanDiscardData:Bool)
		Local P:= GetTransmission(Buffer, CanDiscardData)
		
		If (P = Null) Then
			Return Null
		Endif
		
		FinishTransmission(P)
		
		Return P
	End
	
	' This retrieves a 'Packet' that is "in transit", using its 'DataBuffer' as an identifier.
	' If a 'Packet' could not be found, 'Null' is returned.
	Method GetTransmission:Packet(Buffer:DataBuffer, CanDiscard:Bool)
		For Local P:= Eachin InTransit
			If (P.Data = Buffer) Then
				Return P
			Endif
		Next
		
		If (CanDiscard) Then
			Buffer.Discard()
			
			Return Null
		Endif
		
		Return Null
	End
	
	' Macros:
	
	#Rem
		This command relinquishes control over 'P', as well as its storage.
		
		This is useful for ending a controlled pattern,
		like 'AcceptMessagesWith' in the 'NetworkManager' class.
	#End
	
	Method KillTransmission:Bool(S:Socket, P:Packet)
		Return KillTransmission(P)
	End
	
	Method KillTransmission:Bool(P:Packet)
		Local Output:= FinishTransmission(P)
		
		If (Output <> Null) Then
			Free(Output)
			
			Return True
		Endif
		
		' Return the default response.
		Return False
	End
	
	Method KillTransmission:Bool(Data:DataBuffer, CanDiscard:Bool)
		Local P:= FinishTransmission(Data, CanDiscard)
		
		If (P <> Null) Then
			Free(P)
			
			Return True
		Endif
		
		' Return the default response.
		Return False
	End
	
	' Methods (Protected):
	Protected
	
	Method GeneratePacket:Packet()
		Return New Packet(PacketSize)
	End
	
	Public
	
	' Properties (Public):
	
	' This holds handles to 'Packet' objects that are in transit.
	' For details, see 'MarkTransmission' above.
	Method InTransit:Stack<Packet>() Property
		Return Self._InTransit
	End
	
	Method PacketSize:Int() Property
		Return Self._PacketSize
	End
	
	' Properties (Protected):
	Protected
	
	Method InTransit:Void(Input:Stack<Packet>) Property
		Self._InTransit = Input
		
		Return
	End
	
	Method Pool:Stack<Packet>() Property
		Return Self._Pool
	End
	
	Method Pool:Void(Input:Stack<Packet>) Property
		Self._Pool = Input
		
		Return
	End
	
	Method PacketSize:Void(Input:Int) Property
		Self._PacketSize = Input
		
		Return
	End
	
	Public
	
	' Fields (Public):
	' Nothing so far.
	
	' Fields (Protected):
	Protected
	
	Field _InTransit:Stack<Packet>
	Field _Pool:Stack<Packet>
	
	Field _PacketSize:Int
	
	Public
End