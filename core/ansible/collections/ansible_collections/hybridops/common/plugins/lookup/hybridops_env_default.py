# file: hybridops_env_default.py
# purpose: Lookup plugin for environment variables with defaults
# Maintainer: HybridOps.Studio
# date: 2025-11-26

import os
from ansible.plugins.lookup import LookupBase
from ansible.errors import AnsibleError


class LookupModule(LookupBase):
    def run(self, terms, variables=None, **kwargs):
        if len(terms) == 0:
            raise AnsibleError("hybridops_env_default requires at least one term (variable name)")

        var_name = str(terms[0])
        default = str(terms[1]) if len(terms) > 1 else ""

        value = os.getenv(var_name, default)
        return [value]
