# file: hybridops_filters.py
# purpose: Filter plugin for HybridOps common collection
# Maintainer: HybridOps.Studio
# date: 2025-11-26

from ansible.plugins.filter import FilterBase


class FilterModule(FilterBase):
    def filters(self):
        return {
            "hybridops_env_tag": self.hybridops_env_tag,
        }

    def hybridops_env_tag(self, environment, role):
        env = str(environment).strip() or "unknown"
        r = str(role).strip() or "generic"
        return f"env-{env}_role-{r}"
