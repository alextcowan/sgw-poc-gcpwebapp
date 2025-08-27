import subprocess
import os
import re

VM_NAME = "apache-internal-vm"
REMOTE_CERT_PATH = "/etc/apache2/ssl/apache.crt"
LOCAL_CERT_NAME = "internal-gcp-ca.pem"

def get_tf_variable(variable_name, file_path="terraform.tfvars"):
    """Reads a variable from a terraform.tfvars file."""
    try:
        with open(file_path, "r") as f:
            for line in f:
                match = re.match(fr'^\s*{variable_name}\s*=\s*"(.*)"\s*$', line)
                if match:
                    return match.group(1)
    except FileNotFoundError:
        print(f"Warning: {file_path} not found. Using default values.")
    return None

# Get the project ID from the environment variables
project_id = os.environ.get("DEVSHELL_PROJECT_ID")
if not project_id:
    print("Error: DEVSHELL_PROJECT_ID environment variable not set.")
    exit(1)

VM_ZONE = get_tf_variable("zone") or "us-central1-a"  # default to us-central1-a if not found

def get_gcloud_path():
    """Finds the path to the gcloud executable."""
    try:
        return subprocess.check_output(["which", "gcloud"]).strip().decode("utf-8")
    except subprocess.CalledProcessError:
        print("Error: gcloud command not found. Please ensure the Google Cloud SDK is installed and in your PATH.")
        exit(1)


def copy_certificate():
    """Copies the self-signed CA certificate from the GCP VM."""
    gcloud_path = get_gcloud_path()
    scp_command = [
        gcloud_path,
        "compute",
        "scp",
        f"--project={project_id}",
        f"--zone={VM_ZONE}",
        f"{VM_NAME}:{REMOTE_CERT_PATH}",
        LOCAL_CERT_NAME,
    ]

    print(f"Executing command: {' '.join(scp_command)}")

    try:
        subprocess.run(scp_command, check=True, capture_output=True, text=True)
        print(f"Successfully copied certificate to {LOCAL_CERT_NAME}")
    except subprocess.CalledProcessError as e:
        print(f"Error copying certificate: {e}")
        print(f"Stderr: {e.stderr}")


if __name__ == "__main__":
    copy_certificate()