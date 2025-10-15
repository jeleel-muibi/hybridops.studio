import jenkins.model.*
import jenkins.branch.*
import jenkins.plugins.git.*
import org.jenkinsci.plugins.workflow.multibranch.*

// -----------------------------------------------------------------------------
// 03-seed-mbp.groovy — defines the multibranch seed job for ctrl-01
// Defines 'ctrl01-bootstrap' seed job (created on first startup).
// -----------------------------------------------------------------------------

def j = Jenkins.get()
def name = "ctrl01-bootstrap"

if (j.getItem(name) == null) {
    def mbp = new WorkflowMultiBranchProject(j, name)
    def scm = new GitSCMSource("https://github.com/jeleel-muibi/hybridops.studio")
    scm.setTraits([new BranchDiscoveryTrait()])

    mbp.getSourcesList().add(new BranchSource(scm))
    mbp.setDisplayName("HybridOps • ctrl-01 CI/CD Core")
    j.putItem(mbp)

    mbp.save()
    j.save()
    mbp.scheduleBuild2(0)

    println "[init:03-seed] Created seed job '${name}' (HybridOps • ctrl-01 CI/CD Core)"
} else {
    println "[init:03-seed] Seed job '${name}' already exists — skipping."
}
