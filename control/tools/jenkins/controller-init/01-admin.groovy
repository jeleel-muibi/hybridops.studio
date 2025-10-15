import jenkins.model.*
import hudson.security.*

// -----------------------------------------------------------------------------
// 01-admin.groovy — creates the initial admin user from JENKINS_ADMIN_PASS
// -----------------------------------------------------------------------------
// Purpose:
//   Creates the initial Jenkins admin user from the environment variable
//   JENKINS_ADMIN_PASS, if no users currently exist.
//   Enforces "logged-in only" access policy.
//
// Notes:
//   - This script runs once at controller initialization.
//   - The password is read from memory only; never written to disk.
//   - Fails fast if the environment variable is missing or empty.
// -----------------------------------------------------------------------------

def j = Jenkins.get()
def realm = new HudsonPrivateSecurityRealm(false)
def existingUsers = realm.getAllUsers()
def envPass = System.getenv("JENKINS_ADMIN_PASS")

if (existingUsers.isEmpty()) {
    if (envPass == null || envPass.trim().isEmpty()) {
        println "[init:01-admin] ERROR — Missing environment variable: JENKINS_ADMIN_PASS"
        System.exit(1)
    }

    def username = "admin"
    realm.createAccount(username, envPass)
    j.setSecurityRealm(realm)

    def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
    strategy.setAllowAnonymousRead(false)
    j.setAuthorizationStrategy(strategy)
    j.save()

    println "[init:01-admin] Created admin user '${username}' from environment variable."
    println "[init:01-admin] Anonymous access disabled. Controller secured."
} else {
    println "[init:01-admin] Admin user already exists — skipping creation."
}
