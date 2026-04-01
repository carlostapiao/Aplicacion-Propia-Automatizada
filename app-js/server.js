const express = require('express');
const sql = require('mssql');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static('public'));

// Configuración de conexión usando Variables de Entorno (Seguridad)
const dbConfig = {
    user: process.env.DB_USER || 'sqladmin',
    password: process.env.DB_PASSWORD || 'Password1234!',
    server: process.env.DB_SERVER || 'sqlserver-carlos-lab.database.windows.net',
    database: process.env.DB_NAME || 'ticketsdb',
    options: {
        encrypt: true, // Necesario para Azure
        trustServerCertificate: false
    }
};

// Función para conectar a la DB
async function connectDB() {
    try {
        await sql.connect(dbConfig);
        console.log("Conectado a Azure SQL con éxito");
    } catch (err) {
        console.error("Error de conexión a SQL:", err);
    }
}

// 1. OBTENER TICKETS (GET)
app.get('/api/tickets', async (req, res) => {
    try {
        const result = await sql.query`SELECT * FROM Tickets ORDER BY id DESC`;
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: "Error al leer tickets", message: err.message });
    }
});

// 2. CREAR TICKET (POST)
app.post('/api/tickets', async (req, res) => {
    const { usuario, asunto, prioridad } = req.body;
    try {
        await sql.query`
            INSERT INTO Tickets (usuario, asunto, prioridad, estado)
            VALUES (${usuario}, ${asunto}, ${prioridad}, 'Abierto')
        `;
        res.json({ status: "success", message: "Ticket guardado en SQL" });
    } catch (err) {
        res.status(500).json({ error: "Error al guardar ticket", message: err.message });
    }
});

// Iniciar servidor y conectar DB
app.listen(PORT, () => {
    console.log(`Servidor IT en puerto ${PORT}`);
    connectDB();
});