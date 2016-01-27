Strict

Public

' Imports (Public):
Import packet

' Imports (Private):
Private

Import brl.pool
Import brl.databuffer
'Import brl.datastream

Public

' This handles the storage of 'Packet' objects,
' as well as their "transmission states".
Class PacketManager Extends Pool<Packet> Final
	' Constant variable(s):
	
	' Defaults:
	Const Defaulk_PacketPoolSize:= 4 ' 8 ' 16
	
	' Constructor(s):
	Method New(Capacity:Int=Defaulk_PacketPoolSize)
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
		If (P = Null) Then
			Return
		Endif
		
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