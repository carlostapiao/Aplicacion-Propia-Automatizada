const express = require('express');
const sql = require('mssql');
const path = require('path');
const app = express();

app.use(express.json());
app.set('strict routing', false);

const dbConfig = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER,
    database: process.env.DB_NAME,
    options: {
        encrypt: true,
        trustServerCertificate: true
    }
};

// 1. RUTAS DE API (Prioridad Máxima)
app.get('/tickets', async (req, res) => {
    console.log("Petición recibida en GET /tickets"); // Log para depurar
    try {
        let pool = await sql.connect(dbConfig);
        let result = await pool.request().query('SELECT * FROM Tickets');
        res.json(result.recordset);
    } catch (err) {
        console.error(err);
        res.status(500).send('Error en la base de datos: ' + err.message);
    }
});

app.post('/tickets', async (req, res) => {
    try {
        const { titulo, descripcion } = req.body;
        let pool = await sql.connect(dbConfig);
        await pool.request()
            .input('titulo', sql.VarChar, titulo)
            .input('descripcion', sql.VarChar, descripcion)
            .query('INSERT INTO Tickets (titulo, descripcion) VALUES (@titulo, @descripcion)');
        res.status(201).json({ mensaje: 'Ticket creado con éxito' });
    } catch (err) {
        res.status(500).send('Error al crear ticket: ' + err.message);
    }
});

// 2. ARCHIVOS ESTÁTICOS
// Esto servirá el index.html automáticamente cuando entres a "/"
app.use(express.static(path.join(__dirname, 'public')));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Servidor IT en puerto ${PORT}`);
    // Conexión silenciosa al inicio
    sql.connect(dbConfig).catch(err => console.log('Error SQL inicial:', err));
});