import jenkins.model.*
import hudson.security.csrf.DefaultCrumbIssuer

// -----------------------------------------------------------------------------
// 02-security.groovy — Jenkins controller security baseline
// Enables CSRF, limits executors, sets fixed agent port, and clears CSP.
// Runs once at controller startup (Day-1).
// -----------------------------------------------------------------------------

def j = Jenkins.get()

j.setCrumbIssuer(new DefaultCrumbIssuer(true))          // enable CSRF
j.setNumExecutors(2)                                   // limit controller executors
System.setProperty("jenkins.model.Jenkins.slaveAgentPort", "50000") // fixed inbound port
System.setProperty("hudson.model.DirectoryBrowserSupport.CSP", "")  // relax CSP
j.save()

println "[init:02-security] baseline applied (CSRF, executors=2, port=50000, CSP cleared)"
