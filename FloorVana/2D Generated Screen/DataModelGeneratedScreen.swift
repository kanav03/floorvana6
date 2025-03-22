

class DataModelGeneratedScreen {
    
    static let shared = DataModelGeneratedScreen()
    
  
    private var projects: [Project] = []
    
    private init() {}
    
    
    func addProject(_ project: Project) {
        projects.append(project)
    }
    
   
    func getProjects() -> [Project] {
        return projects
    }
    
    func getProject(at index: Int) -> Project? {
        guard index >= 0 && index < projects.count else { return nil }
        return projects[index]
    }
}

struct Project {
    var specifications: [String: Any]
    var imageName: String
}
