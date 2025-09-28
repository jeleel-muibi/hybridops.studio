def choose_cloud(
    azure_remaining, gcp_remaining, min_needed, azure_healthy, gcp_healthy
):
    if azure_healthy and azure_remaining >= min_needed:
        return "azure"
    if gcp_healthy and gcp_remaining >= min_needed:
        return "gcp"
    return "none"  # alert finance / SRE
