//
//  HouseSpecificationDataModel.swift
//  AppStore
//
//  Created by Navdeep    on 31/10/24.
//
// MARK: - Enums
enum RoomType: String {
    case bedroom = "Bed Room"
    case kitchen = "Kitchen"
    case bathroom = "Bathroom"
    case livingRoom = "Living Room"
    case dinningRoom = "Dinning Room"
    case studyRoom = "Study Room"
    case entry = "Entry"
}

struct Room {
    let type: RoomType
    var count: Int
    
    init(type: RoomType, count: Int = 0) {
        self.type = type
        self.count = count
    }
}

class HouseSpecifications {
    private(set) var rooms: [Room]
    private(set) var isVastuCompliant: Bool
    private(set) var totalArea: Int
    
    var totalRooms: Int {
        rooms.reduce(0) { $0 + $1.count }
    }
    
    init() {
      
        self.rooms = [
            Room(type: .bedroom),
            Room(type: .kitchen),
            Room(type: .bathroom),
            Room(type: .livingRoom),
            Room(type: .dinningRoom),
            Room(type: .studyRoom),
            Room(type: .entry)
        ]
        
        self.isVastuCompliant = false
        self.totalArea = 0
    }
    
    func updateRoomCount(for type: RoomType, count: Int) {
        if let index = rooms.firstIndex(where: { $0.type == type }) {
            rooms[index] = Room(type: type, count: count)
        }
    }
    
    func updateTotalArea(area: Int) {
        self.totalArea = area
    }
    
    func setVastuCompliance(_ isCompliant: Bool) {
        self.isVastuCompliant = isCompliant
    }
    
    func getRoomCount(for type: RoomType) -> Int {
        return rooms.first { $0.type == type }?.count ?? 0
    }
    
    func validate() -> Bool {
      
        let hasRequiredRooms = getRoomCount(for: .bedroom) > 0 &&
                               getRoomCount(for: .kitchen) > 0 &&
                               getRoomCount(for: .bathroom) > 0
        
        let hasValidArea = totalArea > 0
        
        return hasRequiredRooms && hasValidArea
    }
    
    func toDictionary() -> [String: Any] {
        let roomsDict = rooms.reduce(into: [String: Int]()) { dict, room in
            dict[room.type.rawValue] = room.count
        }
        
        return [
            "rooms": roomsDict,
            "totalArea": totalArea,
            "isVastuCompliant": isVastuCompliant,
            "totalRooms": totalRooms
        ]
    }
}
