//
//  Dugon.swift
//  sdk
//
//  Created by cong chen on 2025/3/22.
//

public class Dugon{
    private var room:Room

    public init(){
        room = Room()

    }
    
    public func stream(){
        room.stream()
    }

    public func startPreview(player: Player){
        room.playLocal(player:player)
    }
    
    public func connect(){
        room.connect()
    }
}
