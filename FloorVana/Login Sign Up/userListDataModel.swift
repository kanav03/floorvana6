import Foundation

struct Users: Codable {
    let Username: String
    let Password: String
}

var users = [
    Users(Username: "Rudra02", Password: "1234"),
    Users(Username: "Kanav09", Password: "1234"),
    Users(Username: "navdeeplakhlan0000@gmail.com", Password: "1234"),
    Users(Username: "Murugan", Password: "1234")
]

var currentUser: Users? {
    get {
        if let username = UserDefaults.standard.string(forKey: "loggedInUser") {
            return users.first(where: { $0.Username == username })
        }
        return nil
    }
    set {
        if let user = newValue {
            UserDefaults.standard.set(user.Username, forKey: "loggedInUser")
        } else {
            UserDefaults.standard.removeObject(forKey: "loggedInUser")
        }
    }
}

func addUser(username: String, password: String) {
   
    if users.first(where: { $0.Username == username }) != nil {
        print("User already exists.")
        return
    }

   
    let newUser = Users(Username: username, Password: password)
    users.append(newUser)

  
    saveToPersistence()
}


func saveToPersistence() {
    let encoder = JSONEncoder()
    do {
        let data = try encoder.encode(users)
        UserDefaults.standard.set(data, forKey: "userList")
        print("Users successfully saved to UserDefaults.")
    } catch {
        print("Failed to encode user data: \(error.localizedDescription)")
    }
}


func loadFromPersistence() {
    if let data = UserDefaults.standard.data(forKey: "userList") {
        let decoder = JSONDecoder()
        do {
            users = try decoder.decode([Users].self, from: data)
            print("User data loaded successfully.")
        } catch {
            print("Failed to decode user data: \(error.localizedDescription)")
        }
    }
}
