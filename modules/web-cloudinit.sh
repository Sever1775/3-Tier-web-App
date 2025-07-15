#!/bin/bash

sudo apt update
sudo apt install nginx -y

# Web Tier HTML file
cat <<EOF > /home/azureuser/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>3-Tier App - Web Tier</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Inter', sans-serif;
        }
    </style>
</head>
<body class="bg-gray-100 text-gray-800">

    <div class="container mx-auto mt-10 p-6 max-w-2xl text-center bg-white rounded-lg shadow-xl">
        <h1 class="text-4xl font-bold text-blue-600 mb-4">Web Tier</h1>
        <p class="text-lg mb-6">This is the frontend of our 3-tier application, served from a Web Tier VM.</p>

        <div class="bg-gray-50 p-6 rounded-lg">
            <p class="mb-4">Click the button below to fetch data from the App Tier through the Internal Load Balancer.</p>
            <button id="getDataBtn" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-3 px-6 rounded-lg transition duration-300 ease-in-out transform hover:scale-105">
                Fetch Data from App Tier
            </button>
        </div>

        <div id="result" class="mt-6 p-6 bg-gray-100 rounded-lg text-left hidden">
            <h2 class="text-2xl font-semibold mb-3">Response from App Tier:</h2>
            <pre id="response" class="bg-gray-800 text-white p-4 rounded-md overflow-x-auto"></pre>
        </div>
        
        <div id="error" class="mt-6 p-4 bg-red-100 border border-red-400 text-red-700 rounded-lg hidden">
            <p><strong class="font-bold">Error:</strong> <span id="errorMessage"></span></p>
        </div>
    </div>

    <script>
        const getDataBtn = document.getElementById('getDataBtn');
        const resultDiv = document.getElementById('result');
        const responsePre = document.getElementById('response');
        const errorDiv = document.getElementById('error');
        const errorMessageSpan = document.getElementById('errorMessage');

        // This IP address placeholder is replaced by your Bicep script.
        const appTierUrl = 'http://__APP_TIER_IP_PLACEHOLDER__:3000/api/data';

        getDataBtn.addEventListener('click', async () => {
            // Show loading state
            getDataBtn.textContent = 'Fetching...';
            getDataBtn.disabled = true;
            resultDiv.classList.add('hidden');
            errorDiv.classList.add('hidden');

            try {
                // Fetch data from the app tier
                const response = await fetch(appTierUrl);

                if (!response.ok) {
                    // Throw a more descriptive error to be caught by the catch block
                    throw new Error(`Server responded with a status of ${response.status}`);
                }

                const data = await response.json();

                // Display the result
                responsePre.textContent = JSON.stringify(data, null, 2);
                resultDiv.classList.remove('hidden');

            } catch (error) {
                // Display any errors
                console.error('Fetch error:', error);
                // **THIS IS THE CORRECTED LINE**
                errorMessageSpan.textContent = `Failed to fetch data. Please check network connectivity and NSG rules. Details: ${error.message}`;
                errorDiv.classList.remove('hidden');
            } finally {
                // Reset button state
                getDataBtn.textContent = 'Fetch Data from App Tier';
                getDataBtn.disabled = false;
            }
        });
    </script>

</body>
</html>
EOF

sudo mv /home/azureuser/index.html /var/www/html/index.html
