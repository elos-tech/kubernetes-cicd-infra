#!groovy

def source_git_repo      = 'https://github.com/elos-tech/kubernetes-cicd-infra.git'
def name_prefix          = 'cicd-'
def prefix_label         = 'PREFIX' // Helper variable for prefix substitution with double sed-ed templates.
def jenkins_namespace    = "${name_prefix}jenkins"
def components_namespace = "${name_prefix}components"
def app_dev_namespace    = "${name_prefix}tasks-dev"
def app_prod_namespace   = "${name_prefix}tasks-prod"

node {
  stage('Cleanup') {
    delete_namespace(components_namespace)
    delete_namespace(app_dev_namespace)
    delete_namespace(app_prod_namespace)
  }

  stage('Checkout Source') {
    git source_git_repo
  }
  
  stage('Create Components namespace') {
    create_from_template 'default', "templates/components-namespace.yaml _${prefix_label}_ $name_prefix"
  }
  
  stage('Create Nexus') {
    create_from_template components_namespace, "templates/nexus.yaml _${prefix_label}_ $name_prefix"
  }
  
  stage('Create Sonarqube') {
    create_from_template components_namespace, """templates/postgresql-persistent.yaml \
      _${prefix_label}_ ${name_prefix}sonar- \
      _POSTGRES_DB_ sonar \
      _POSTGRES_USER_ sonar \
      _POSTGRES_PASSWORD_ sonar \
      _DATABASE_SERVICE_NAME_ postgresql-sonarqube
    """
    
    create_from_template components_namespace, "templates/sonarqube.yaml _${prefix_label}_ ${name_prefix}"
  }
  
  stage('Create DEV namespace') {
    create_from_template components_namespace, "templates/tasks-dev-namespace.yaml _${prefix_label}_ $name_prefix"
  }
  
  stage('Create PROD namespace') {
    create_from_template components_namespace, "templates/tasks-prod-namespace.yaml _${prefix_label}_ $name_prefix"
  }
}

def delete_namespace(namespace_name) {
  sh """
    kubectl delete namespace $namespace_name || echo
  """
}

def create_from_template(namespace, request) {
  sh """
    TMP_DIR=\$(mktemp -d)

    function create_from_template {
      FILE=\$1; shift

      if [ ! -f "\$FILE" ]; then
        echo "ERROR: File '\$FILE' doesn't exist!"
        exit 1
      fi

      set -x
      cp \$FILE "\${TMP_DIR}/\$(basename \$FILE)"

      while (( "\$#" )); do
        #echo "Replacing parameter: \$1 -> \$2"
        sed -i 's@'\$1'@'\$2'@g' "\${TMP_DIR}/\$(basename \$FILE)"
        shift
        shift
      done

      kubectl --namespace $namespace create -f "\${TMP_DIR}/\$(basename \$FILE)"
      set +x
    }
    
    create_from_template $request

    rm -rf \$TMP_DIR
  """
}

def wait_for_deployment_ready(namespace, deployment) {
}

def deployment_is_ready(namespace, deployment) {
  sh "[ 1 -eq \$(kubectl --namespace $namespace get deployment $deployment --no-headers | awk '{ print \$5}') ]"
}
