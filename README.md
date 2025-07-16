# Azure 3-Tier Web Application Deployment

This repository contains the infrastructure-as-code (IaC) and application code to deploy a classic 3-tier web application on Microsoft Azure using Bicep and GitHub Actions.

The application demonstrates a secure, scalable, and automated setup with a Web Tier, an Application Tier, and a Database Tier (Azure SQL).

## Architecture Overview

The infrastructure is designed to be secure and scalable, with clear separation of concerns between the different layers of the application.

1.  **Web Tier**:
    * Consists of a Virtual Machine Scale Set (VMSS) running a Node.js server with Nginx as a reverse proxy.
    * Acts as a server-side proxy, receiving requests from users' browsers.
    * Serves the static frontend content (HTML, CSS, JavaScript).
    * Forwards dynamic data requests to the private App Tier.
    * This tier is the only layer accessible from the public internet, via an Azure Application Gateway.

2.  **Application Tier**:
    * Consists of a VMSS running a Node.js server that contains the core business logic.
    * It is placed in a private subnet and is only accessible from the Web Tier via an **Internal Load Balancer**.
    * It is responsible for connecting to the database to fetch and store data.
    * Outbound internet access for software installation is provided securely by an **Azure NAT Gateway**.

3.  **Database Tier**:
    * An Azure SQL Database instance holds the application's data.
    * It is placed in a private subnet (or configured with firewall rules) to ensure it is only accessible from the Application Tier.

### Request Flow

1.  A user accesses the public URL, which points to the **Azure Application Gateway**.
2.  The Application Gateway forwards the HTTP request to a VM in the **Web Tier VMSS**.
3.  Nginx on the Web Tier VM serves the `index.html` page.
4.  The user clicks the "Fetch Data" button, which triggers a JavaScript `fetch` call to a local API endpoint on the Web Tier (e.g., `/api/data`).
5.  The Node.js proxy server on the Web Tier receives this request.
6.  The Web Tier server makes a new, internal request to the **Internal Load Balancer's** private IP address.
7.  The ILB forwards the request to a healthy VM in the **App Tier VMSS**.
8.  The Node.js server on the App Tier receives the request, connects to the **Azure SQL Database**, and runs a query.
9.  The data is returned through the chain: DB Tier -> App Tier -> Web Tier -> User's Browser.

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

```md
├── .github/
│   └── workflows/
│       └── deploy-azure.yml    # GitHub Actions workflow for deployment
├── app/
│   ├── app.js                  # Node.js code for the App Tier
│   └── setup-app-tier.sh       # Setup script for App Tier VMs
│       
├── web/
│   └── web-cloudinit.sh    # Setup script for Web Tier VMs
│   
├── modules/
│   ├── appgw.bicep           # Bicep module for Application Gateway
│   ├── apptier.bicep           # Bicep module for App Tier VMs
│   ├── bastion.bicep           # Bicep module for Bastion host 
│   ├── dbtier.bicep           # Bicep module for Database Tier resources
│   ├── loadbalancer.bicep           # Bicep module for Internal Load Balancer
│   ├── network.bicep           # Bicep module for Network(VNET,Subnet) resources   
│   └── webtier.bicep    # Setup script for Web Tier VMs
└── main.bicep                  # Main Bicep file to deploy all resources
```

---

## Deployment

This project is deployed automatically using GitHub Actions. A push to the `main` branch will trigger the `deploy-azure.yml` workflow, which performs the following steps:

1.  Logs in to Azure using the provided service principal.
2.  Executes the `main.bicep` file, which deploys or updates all Azure resources.
3.  The Bicep deployment uses `customData` to pass startup scripts to the VMSS instances, which handle:
    * Installing Nginx, Node.js, and PM2.
    * Copying the application code.
    * Installing `npm` dependencies.
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
4.  Check the application logs:
    ```bash
    pm2 logs app-tier-server
    ```
    You should see the message "Waiting for requests from the Web Tier...".

### 2. Check the Web Tier

1.  SSH into one of the VM instances in the `webTierVmss`.
2.  Check the status of the proxy server:
    ```bash
    pm2 status
    ```
    You should see `web-tier-proxy` with a status of `online`.
3.  Test the connection from the Web Tier to the App Tier. Replace `10.0.X.X` with your Internal Load Balancer's private IP.
    ```bash
    curl [http://10.0.](http://10.0.)X.X:3000/api/data
    ```
    This command should return a JSON object with data from the database, confirming all three tiers are connected.

### 3. Test in the Browser

1.  Find the public IP address of your Application Gateway.
2.  Open a web browser and navigate to that IP address.
3.  The web page should load. Click the **"Fetch Data"** button.
4.  The "Response from App Tier" section should appear and be populated with the JSON data from the database.