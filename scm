To set up a **webhook for a Bitbucket repo containing a “Pipeline Template Catalog”** so that **any change in the repo automatically triggers a reload of the catalog in CloudBees Jenkins**, follow the **detailed steps below**.

---

## 🧠 What Is a Pipeline Template Catalog?

In **CloudBees Jenkins**, Pipeline Template Catalogs are used with **Templating Engine** or **Pipeline Template Plugin** to centrally manage shared pipeline templates (JTE).

These catalogs are typically defined in **Jenkins Configuration as Code (CasC)** or under **“Pipeline Template Catalogs”** in **Manage Jenkins**. When the catalog repo is updated, Jenkins doesn’t automatically reload it unless explicitly told to do so.

To automate reloading the catalog, we use a webhook that triggers a specific Jenkins job to **reload the catalog**.

---

## 🧰 Objective

> **Automatically trigger “Run Catalog import now”** Jenkins job whenever a **commit is pushed** to the Bitbucket repository hosting the **pipeline template catalog**.

---

## 🛠️ Part 1: Jenkins Job Setup

### Step 1: Create a Jenkins Job to Reload the Catalog

If it doesn't already exist, create a Freestyle or Pipeline job in Jenkins named:

Freestyle job:
import jenkins.model.*

def templateCatalogDescriptor = Jenkins.instance.getDescriptor("org.boozallen.plugins.jte.catalog.TemplateCatalog")
if (templateCatalogDescriptor) {
    templateCatalogDescriptor.loadCatalogs()
    println "Pipeline Template Catalogs reloaded successfully."
} else {
    println "Template Catalog Descriptor not found."
}

Pipeline job

```
Run Catalog import now
```

This job should reload the Pipeline Template Catalog(s).

#### 💡 In a Pipeline job:

Use this code to reload all catalogs:

```groovy
pipeline {
    agent any
    stages {
        stage('Reload Pipeline Catalogs') {
            steps {
                script {
                    // Reload all configured pipeline catalogs
                    def templateCatalogDescriptor = Jenkins.instance.getDescriptor("org.boozallen.plugins.jte.catalog.TemplateCatalog")
                    templateCatalogDescriptor?.loadCatalogs()
                    echo "Pipeline Template Catalogs reloaded."
                }
            }
        }
    }
}
```

> 🔐 **Note**: This uses Jenkins internal APIs, so make sure the job runs with appropriate permissions.

---

### Step 2: Enable a Webhook Trigger on the Job

Use the **Generic Webhook Trigger Plugin**:

1. Go to Jenkins > `Run Catalog import now` > **Configure**
2. Under **Build Triggers**, check:

```
☑️ Generic Webhook Trigger
```

Set:

* **Token**: `catalog-import-trigger` (or a custom token)

You'll get a URL like:

```
https://<JENKINS_URL>/generic-webhook-trigger/invoke?token=catalog-import-trigger
```

Copy this URL for Bitbucket.

---

## 🗃️ Part 2: Bitbucket Webhook Setup

### Step 3: Add a Webhook in Bitbucket

1. Go to the **repository** that contains your **Pipeline Template Catalog**.
2. Go to **Settings** > **Webhooks**.
3. Click **“Add Webhook”**.

Fill in:

| Field        | Value                                                                               |
| ------------ | ----------------------------------------------------------------------------------- |
| **Title**    | `Jenkins Catalog Reload`                                                            |
| **URL**      | `https://<JENKINS_URL>/generic-webhook-trigger/invoke?token=catalog-import-trigger` |
| **Triggers** | ✅ Push (and optionally Pull Request Merged)                                         |
| **Active**   | ✅ Yes                                                                               |

Click **Save**.

---

## 🔁 Part 3: Test the Integration

1. Commit a change to the Bitbucket repo (e.g., edit `pipeline_config.groovy` or `template.groovy`).
2. Confirm the webhook fires (Bitbucket shows a 200 response).
3. Jenkins job `Run Catalog import now` should start.
4. Verify in the job logs that catalogs were reloaded successfully.

---

## 🔒 Security Considerations

* Ensure Jenkins endpoint is secured via HTTPS.
* Optionally restrict incoming IPs (Bitbucket IP ranges) using a reverse proxy or firewall.
* Use **shared secret headers** if you want to validate that the trigger comes from Bitbucket (supported by Generic Webhook Plugin).

---

## ✅ Summary of Steps

| Task               | Tool          | Action                                                |
| ------------------ | ------------- | ----------------------------------------------------- |
| Create Jenkins job | Jenkins       | Job named `Run Catalog import now` to reload catalogs |
| Enable webhook     | Jenkins       | Use Generic Webhook Plugin with a unique token        |
| Set webhook        | Bitbucket     | Send push events to Jenkins webhook URL               |
| Test it            | Git/Bitbucket | Push change and observe Jenkins triggering            |

---

If you’d like, I can help you **write a safe pipeline that reloads only specific catalogs**, or configure **CasC for automated catalog registration**. Just let me know!
