// --- App Tier Server (app.js) ---
// This script creates a simple Node.js server that connects to a SQL Server database.
// It is designed to be configured via environment variables for automated deployments.

// --- Prerequisites ---
// 1. Node.js and npm must be installed on the App Tier VMs.
// 2. Run `npm install express mssql cors` in your project directory to install dependencies.
// 3. The following environment variables must be set: DB_USER, DB_PASSWORD, DB_SERVER, DB_DATABASE

const express = require('express');
const sql = require('mssql');
const cors = require('cors'); // Required to allow requests from the Web Tier

const app = express();
const port = 3000;

// --- Database Configuration ---
// Credentials are loaded from environment variables. This is more secure than hardcoding.
// Your Bicep script will be responsible for setting these variables on the VM.
const dbConfig = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER, // e.g., your-sql-server.database.windows.net
    database: process.env.DB_DATABASE,
    options: {
        encrypt: true, // For Azure SQL Database
        trustServerCertificate: false
    }
};

// Check if all required environment variables are set
if (!dbConfig.user || !dbConfig.password || !dbConfig.server || !dbConfig.database) {
    console.error("FATAL ERROR: Database configuration is missing. Ensure DB_USER, DB_PASSWORD, DB_SERVER, and DB_DATABASE environment variables are set.");
    process.exit(1); // Exit the process if configuration is incomplete
}

// Enable CORS to allow the frontend (Web Tier) to make requests to this server
app.use(cors());

// Define the API endpoint that the Web Tier will call
app.get('/api/data', async (req, res) => {
    console.log('Received request for /api/data');
    try {
        // Connect to the database
        console.log(`Attempting to connect to database '${dbConfig.database}' on server '${dbConfig.server}'...`);
        let pool = await sql.connect(dbConfig);
        console.log('Database connection successful.');

        // Execute a simple query
        const result = await pool.request().query("SELECT GETDATE() as currentTime, SUSER_SNAME() as currentUser, DB_NAME() as currentDB;");
        
        console.log('Query executed successfully.');

        // Send the query result back as a JSON response
        res.json({
            success: true,
            message: 'Data successfully retrieved from the database.',
            data: result.recordset[0]
        });

    } catch (err) {
        // Handle errors, such as connection or query failures
        console.error('API Error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to connect to or query the database.',
            error: err.message
        });
    } finally {
        // Close the connection pool
        if (sql.pool) {
            sql.close();
        }
    }
});

// Start the server and listen for incoming requests
app.listen(port, () => {
    console.log(`App Tier server listening at http://localhost:${port}`);
    console.log('Waiting for requests from the Web Tier...');
});
