# Azure 3-Tier Web Application Deployment

This repository contains the infrastructure-as-code (IaC) and application code to deploy a classic 3-tier web application on Microsoft Azure using Bicep and GitHub Actions.

The application demonstrates a secure, scalable, and automated setup with a Web Tier, an Application Tier, and a Database Tier (Azure SQL). This configuration is designed to verify the internal network connectivity and security rules between the tiers.

## Architecture Overview

The infrastructure is designed to be secure and scalable, with clear separation of concerns between the different layers of the application.

1.  **Web Tier**:
    * Consists of a Virtual Machine Scale Set (VMSS) running an **Nginx** web server.
    * Serves a single, static `index.html` page.
    * This tier is the only layer accessible from the public internet, via an Azure Application Gateway.

2.  **Application Tier**:
    * Consists of a VMSS running a Node.js server that contains the core business logic.
    * It is placed in a private subnet and is only accessible from the Web Tier via an **Internal Load Balancer**.
    * It is responsible for connecting to the database to fetch and store data.
    * Outbound internet access for software installation is provided securely by an **Azure NAT Gateway**.

3.  **Database Tier**:
    * An Azure SQL Database instance holds the application's data.
    * It is configured with firewall rules to ensure it is only accessible from the Application Tier.

### Request Flow & Verification

1.  A user accesses the public URL, which points to the **Azure Application Gateway**.
2.  The Application Gateway forwards the HTTP request to a VM in the **Web Tier VMSS**.
3.  Nginx on the Web Tier VM serves the `index.html` page.
4.  The JavaScript in the user's browser attempts to make a `fetch` call directly to the **Internal Load Balancer's private IP address**.
5.  **This call is expected to fail.** A public browser cannot connect to a private IP address inside a secure virtual network.
6.  The definitive test is performed by connecting to the Web Tier VM and using `curl` to simulate the request, proving the internal network path is correctly configured.

---

## Prerequisites

* An Azure subscription.
* An Azure Service Principal with `Contributor` rights on the subscription, configured as a secret in the GitHub repository (`AZURE_CREDENTIALS`).
* The following secrets configured in your GitHub repository for the deployment workflow:
    * `AZURE_SUBSCRIPTION_ID`
    * `VM_USERNAME`
    * `VM_PASSWORD`
    * `SQL_ADMIN_USERNAME`
    * `SQL_ADMIN_PASSWORD`

---

## Repository Structure

├── .github/
│   └── workflows/
│       └── deploy-azure.yml    # GitHub Actions workflow for deployment
├── app/
│   ├── app.js                  # Node.js code for the App Tier
│   └── scripts/
│       └── setup-app-tier.sh   # Setup script for App Tier VMs
├── web/
│   ├── index.html              # Frontend HTML file
│   └── scripts/
│       └── web-cloudinit.sh    # Setup script for Web Tier VMs
├── modules/
│   ├── webtier.bicep           # Bicep module for Web Tier resources
│   └── apptier.bicep           # Bicep module for App Tier resources
└── main.bicep                  # Main Bicep file to deploy all resources

---

## Deployment

This project is deployed automatically using GitHub Actions. A push to the `main` branch will trigger the `deploy-azure.yml` workflow, which performs the following steps:
1.  Logs in to Azure using the provided service principal.
2.  Executes the `main.bicep` file, which deploys or updates all Azure resources.
3.  The Bicep deployment uses `customData` to pass startup scripts to the VMSS instances, which handle:
    * Installing Nginx (Web Tier) or Node.js/PM2 (App Tier).
    * Copying the application code.
    * Installing `npm` dependencies (App Tier).
    * Configuring and starting the services.

---

## How to Verify the Deployment

After a successful deployment, you can verify that each component is working correctly.

### 1. Check the App Tier

1.  In the Azure portal, find one of the VM instances in the `appTierVmss`.
2.  SSH into the instance using the credentials you provided.
3.  Check the status of the application server:
    ```bash
    pm2 status
    ```
    You should see `app-tier-server` with a status of `online`.

### 2. Check the Web Tier & End-to-End Connectivity (Definitive Test)

This is the most important test. It confirms that the Web Tier, App Tier, and DB Tier are all communicating correctly.

1.  SSH into one of the VM instances in the **`webTierVmss`**.
2.  Test the connection from the Web Tier to the App Tier. Replace `10.0.X.X` with your Internal Load Balancer's private IP.
    ```bash
    curl [http://10.0.](http://10.0.)X.X:3000/api/data
    ```
3.  **A successful test will return a JSON object** with the current time and database name. This proves your 3-tier application is fully functional.

### 3. Test in the Browser (Expected to Fail)

1.  Find the public IP address of your Application Gateway.
2.  Open a web browser and navigate to that IP address.
3.  The web page should load. Click the **"Fetch Data"** button.
4.  Open the browser's developer console (F12). You should see a "Failed to fetch" or "Connection timed out" error. This is the **correct and expected behavior** for this secure architecture, as your browser cannot access the private network.
