import SwiftUI
import LocalAuthentication

struct Debt: Identifiable, Codable {
    let id = UUID()
    var name: String
    var amount: Double

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case amount
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(amount, forKey: .amount)
    }
}

struct PasswordItem: Identifiable, Codable {
    let id = UUID()
    var website: String
    var username: String
    var password: String

    enum CodingKeys: String, CodingKey {
        case id
        case website
        case username
        case password
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(website, forKey: .website)
        try container.encode(username, forKey: .username)
        try container.encode(password, forKey: .password)
    }
}


struct ContentView: View {
    @State private var debts: [Debt] = []
    @State private var newDebtName = ""
    @State private var newDebtAmount = ""
    
    @State private var passwords: [PasswordItem] = []
    @State private var newPasswordWebsite = ""
    @State private var newPasswordUsername = ""
    @State private var newPassword = ""
    
    @State private var isAuthenticated = false
    @State private var isAuthenticating = false
    
    
    var totalAmount: Double {
        debts.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Debts Owed to You")) {
                        ForEach(debts.filter { $0.amount > 0 }) { debtItem in
                            Text("\(debtItem.name) owes you $\(String(format: "%.2f", debtItem.amount))")
                        }
                        .onDelete(perform: deleteDebt)
                    }

                    
                    Section(header: Text("Passwords")) {
                        if isAuthenticated {
                            ForEach(passwords) { passwordItem in
                                VStack(alignment: .leading) {
                                    Text("Website: \(passwordItem.website)")
                                    Text("Username: \(passwordItem.username)")
                                    Text("Password: \(passwordItem.password)")
                                }
                            }
                            .onDelete(perform: deletePassword)
                        } else {
                            Text("Authenticate to view passwords")
                                .onTapGesture {
                                    authenticateWithBiometrics()
                                }
                        }
                    }
                }
                
                HStack {
                    TextField("Name", text: $newDebtName).textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    TextField("Amount", text: $newDebtAmount)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .padding(.horizontal)
                    
                    Button(action: addDebt) {
                        Image(systemName: "plus")
                    }
                    .padding(.trailing)
                }
                
                HStack {
                    TextField("Website", text: $newPasswordWebsite)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    TextField("Username", text: $newPasswordUsername)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    SecureField("Password", text: $newPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button(action: addPassword) {
                        Image(systemName: "plus")
                    }
                    .padding(.trailing)
                }
      
                            }
            .navigationTitle("Your R.A.M")
            .onAppear(perform: checkAuthenticationStatus)
        }
    }
    
    private func checkAuthenticationStatus() {
        if isAuthenticated {
            // Already authenticated, show passwords
            return
        }

        if canUseBiometricAuthentication() {
            authenticateWithBiometrics()
        } else {
            // Biometric authentication unavailable, show an alternative method for adding passwords
            print("Biometric authentication unavailable.")
        }
        
        if let savedDebtsData = UserDefaults.standard.data(forKey: "debts") {
            let decoder = JSONDecoder()
            if let savedDebts = try? decoder.decode([Debt].self, from: savedDebtsData) {
                debts = savedDebts
            }
        }
        
        if let savedPasswordsData = UserDefaults.standard.data(forKey: "passwords") {
            let decoder = JSONDecoder()
            if let savedPasswords = try? decoder.decode([PasswordItem].self, from: savedPasswordsData) {
                passwords = savedPasswords
            }
        }
    }

    private func addDebt() {
        guard let amount = Double(newDebtAmount) else { return }
        let newDebt = Debt(name: newDebtName, amount: amount)
        debts.append(newDebt)
        newDebtName = ""
        newDebtAmount = ""
        saveDebts()
    }

    private func deleteDebt(at offsets: IndexSet) {
        debts.remove(atOffsets: offsets)
        saveDebts()
    }

    private func saveDebts() {
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(debts) {
            UserDefaults.standard.set(encodedData, forKey: "debts")
        }
    }

    private func addPassword() {
        if isAuthenticated {
            let newPasswordItem = PasswordItem(website: newPasswordWebsite, username: newPasswordUsername, password: newPassword)
            passwords.append(newPasswordItem)
            newPasswordWebsite = ""
            newPasswordUsername = ""
            newPassword = ""
            savePasswords()
        } else {
            // Show an error or prompt the user to authenticate first
            print("Authentication required to add passwords.")
        }
    }

    private func deletePassword(at offsets: IndexSet) {
        passwords.remove(atOffsets: offsets)
        savePasswords()
    }

    private func savePasswords() {
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(passwords) {
            UserDefaults.standard.set(encodedData, forKey: "passwords")
        }
    }

    
    private func authenticateWithBiometrics() {
        if isAuthenticating {
            return
        }
        isAuthenticating = true

        let context = LAContext()
        var error: NSError?
 
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to access passwords."
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, evaluateError in
                DispatchQueue.main.async {
                    if success {
                        isAuthenticated = true // Set isAuthenticated to true upon successful authentication
                    } else {
                        if let error = evaluateError as NSError? {
                            print("Authentication failed: \(error.localizedDescription)")
                        }
                        isAuthenticated = false
                    }
                    
                    isAuthenticating = false
                }
            }
        } else {
            if let error = error {
                print("Biometric authentication unavailable: \(error.localizedDescription)")
            }
            isAuthenticated = false
            isAuthenticating = false
        }
    }
    
    private func canUseBiometricAuthentication() -> Bool {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return true
        } else {
            if let error = error {
                print("Biometric authentication unavailable: \(error.localizedDescription)")
            } else {
                print("Biometric authentication unavailable.")
            }
            return false
        }
    }
}


 

@main
struct RAMApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}




