Strict

Public

' Imports (Public):
Import brl.stream

' Imports (Private):
Private

Import brl.databuffer
Import brl.datastream

Public

' Classes:
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
		DebugStop()
		
		Data.Discard()
		
		Super.Close()
		
		Return
	End
End