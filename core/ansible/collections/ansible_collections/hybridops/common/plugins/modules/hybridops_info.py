# file: hybridops_info.py
# purpose: Custom module returning basic HybridOps info
# author: Jeleel Muibi
# date: 2025-11-26

from ansible.module_utils.basic import AnsibleModule
from ansible_collections.hybridops.common.plugins.module_utils.hybridops_common import (
    build_standard_result,
)


DOCUMENTATION = r"""
module: hybridops_info
short_description: Return basic HybridOps environment info
description:
  - Simple example module for the HybridOps common collection.
options:
  environment:
    description: Logical environment name.
    type: str
    required: true
  role:
    description: Logical role for the host or service.
    type: str
    required: false
author:
  - Jeleel Muibi
"""

EXAMPLES = r"""
- name: Get HybridOps info
  hybridops.common.hybridops_info:
    environment: dev
    role: k3s-node
  register: result

- debug:
    var: result
"""

RETURN = r"""
environment:
  description: Environment value supplied.
  type: str
role:
  description: Role value supplied.
  type: str
"""


def main():
    module_args = dict(
        environment=dict(type="str", required=True),
        role=dict(type="str", required=False, default=""),
    )

    module = AnsibleModule(argument_spec=module_args, supports_check_mode=True)

    env = module.params["environment"]
    role = module.params["role"]

    msg = f"HybridOps environment={env}, role={role or 'n/a'}"

    result = build_standard_result(
        changed=False,
        message=msg,
        extra={
            "environment": env,
            "role": role,
        },
    )

    module.exit_json(**result)


if __name__ == "__main__":
    main()
